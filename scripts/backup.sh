#!/bin/bash

# ============================================
# SCRIPT DE BACKUP AUTOMÁTICO PARA WORDPRESS
# Optimizado para PostgreSQL y Docker
# ============================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_NAME=$(grep "COMPOSE_PROJECT_NAME=" .env | cut -d '=' -f2 || echo "wordpress")

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[ADVERTENCIA] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar que Docker Compose esté funcionando
if ! docker compose ps >/dev/null 2>&1; then
    error "Docker Compose no está ejecutándose. Ejecuta: docker compose up -d"
fi

log "🗄️  Iniciando backup de WordPress..."

# Crear directorio específico para este backup
BACKUP_PATH="$BACKUP_DIR/backup_$DATE"
mkdir -p "$BACKUP_PATH"

# ============================================
# BACKUP DE BASE DE DATOS
# ============================================

log "📊 Creando backup de PostgreSQL..."

# Obtener configuración de la base de datos desde .env
DB_NAME=$(grep "POSTGRES_DB=" .env | cut -d '=' -f2)
DB_USER=$(grep "POSTGRES_USER=" .env | cut -d '=' -f2)
DB_PASS=$(grep "POSTGRES_PASSWORD=" .env | cut -d '=' -f2)

# Crear backup de la base de datos
docker compose exec -T postgres pg_dump \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --verbose \
    --clean \
    --if-exists \
    --create \
    --format=custom \
    > "$BACKUP_PATH/database_$DATE.dump"

# Crear también un backup en SQL plano
docker compose exec -T postgres pg_dump \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --verbose \
    --clean \
    --if-exists \
    --create \
    > "$BACKUP_PATH/database_$DATE.sql"

log "✅ Backup de base de datos completado"

# ============================================
# BACKUP DE ARCHIVOS WORDPRESS
# ============================================

log "📁 Creando backup de archivos WordPress..."

# Backup de wp-content personalizado
if [ -d "wordpress" ]; then
    tar -czf "$BACKUP_PATH/wordpress_files_$DATE.tar.gz" \
        -C wordpress \
        --exclude='*.log' \
        --exclude='cache' \
        --exclude='*.tmp' \
        .
    log "✅ Backup de archivos WordPress completado"
else
    warn "Directorio wordpress/ no encontrado, saltando backup de archivos"
fi

# Backup de configuraciones
log "⚙️  Creando backup de configuraciones..."

tar -czf "$BACKUP_PATH/config_$DATE.tar.gz" \
    config/ \
    docker-compose.yml \
    .env \
    --exclude='*.log' \
    2>/dev/null || warn "Algunos archivos de configuración no se pudieron respaldar"

log "✅ Backup de configuraciones completado"

# ============================================
# BACKUP DE VOLÚMENES DOCKER
# ============================================

log "🐳 Creando backup de volúmenes Docker..."

# Backup del volumen de WordPress core
docker run --rm \
    -v "${PROJECT_NAME}_wordpress_core":/source:ro \
    -v "$(pwd)/$BACKUP_PATH":/backup \
    alpine:latest \
    tar -czf /backup/wordpress_core_$DATE.tar.gz -C /source . \
    2>/dev/null || warn "No se pudo respaldar el volumen wordpress_core"

log "✅ Backup de volúmenes completado"

# ============================================
# CREAR INFORMACIÓN DEL BACKUP
# ============================================

log "📋 Creando información del backup..."

cat > "$BACKUP_PATH/backup_info.txt" << EOF
===========================================
INFORMACIÓN DEL BACKUP
===========================================

Fecha: $(date)
Proyecto: $PROJECT_NAME
Versión Docker Compose: $(docker compose version --short)

===========================================
CONTENIDO DEL BACKUP
===========================================

1. Base de datos PostgreSQL:
   - database_${DATE}.dump (formato custom)
   - database_${DATE}.sql (formato SQL)

2. Archivos WordPress:
   - wordpress_files_${DATE}.tar.gz

3. Configuraciones:
   - config_${DATE}.tar.gz

4. Volúmenes Docker:
   - wordpress_core_${DATE}.tar.gz

===========================================
INSTRUCCIONES DE RESTAURACIÓN
===========================================

Para restaurar este backup:

1. Restaurar base de datos:
   docker compose exec -T postgres pg_restore \\
     -U $DB_USER -d $DB_NAME \\
     --clean --if-exists \\
     < database_${DATE}.dump

2. Restaurar archivos:
   tar -xzf wordpress_files_${DATE}.tar.gz -C wordpress/

3. Restaurar configuraciones:
   tar -xzf config_${DATE}.tar.gz

4. Reiniciar servicios:
   docker compose down && docker compose up -d

===========================================
EOF

# ============================================
# COMPRIMIR BACKUP COMPLETO
# ============================================

log "🗜️  Comprimiendo backup completo..."

cd "$BACKUP_DIR"
tar -czf "wordpress_backup_complete_$DATE.tar.gz" "backup_$DATE/"

# Verificar el tamaño del backup
BACKUP_SIZE=$(du -h "wordpress_backup_complete_$DATE.tar.gz" | cut -f1)

log "✅ Backup completo creado: wordpress_backup_complete_$DATE.tar.gz ($BACKUP_SIZE)"

# ============================================
# LIMPIEZA DE BACKUPS ANTIGUOS
# ============================================

log "🧹 Limpiando backups antiguos..."

# Mantener solo los últimos 5 backups
find "$BACKUP_DIR" -name "wordpress_backup_complete_*.tar.gz" -type f | \
    sort -r | \
    tail -n +6 | \
    xargs -r rm -f

# Limpiar directorios de backup descomprimidos antiguos
find "$BACKUP_DIR" -name "backup_*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

log "✅ Limpieza completada"

# ============================================
# VERIFICACIÓN DEL BACKUP
# ============================================

log "🔍 Verificando integridad del backup..."

# Verificar que el archivo se creó correctamente
if [ -f "$BACKUP_DIR/wordpress_backup_complete_$DATE.tar.gz" ]; then
    # Verificar que el archivo no está corrupto
    if tar -tzf "$BACKUP_DIR/wordpress_backup_complete_$DATE.tar.gz" >/dev/null 2>&1; then
        log "✅ Backup verificado correctamente"
    else
        error "❌ El archivo de backup está corrupto"
    fi
else
    error "❌ No se pudo crear el archivo de backup"
fi

# ============================================
# RESUMEN FINAL
# ============================================

echo -e "${GREEN}"
cat << "EOF"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                    ✅ BACKUP COMPLETADO                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

EOF
echo -e "${NC}"

info "📁 Archivo de backup: $BACKUP_DIR/wordpress_backup_complete_$DATE.tar.gz"
info "📏 Tamaño del backup: $BACKUP_SIZE"
info "📋 Información detallada en: $BACKUP_PATH/backup_info.txt"

echo -e "${BLUE}🔧 Para restaurar este backup:${NC}"
echo -e "  ${YELLOW}./restore.sh wordpress_backup_complete_$DATE.tar.gz${NC}"

log "🎉 Backup completado exitosamente"