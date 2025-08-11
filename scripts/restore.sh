#!/bin/bash

# ============================================
# SCRIPT DE RESTAURACIÓN AUTOMÁTICA
# Para backups de WordPress con PostgreSQL
# ============================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de logging
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

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              🔄 RESTAURADOR DE WORDPRESS                     ║
║                                                              ║
║        Restaura backups completos de WordPress              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar parámetros
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Uso: $0 <archivo_backup.tar.gz> [opciones]${NC}"
    echo ""
    echo "Opciones:"
    echo "  --db-only          Restaurar solo la base de datos"
    echo "  --files-only       Restaurar solo los archivos"
    echo "  --no-restart       No reiniciar servicios automáticamente"
    echo "  --force           No pedir confirmación"
    echo ""
    echo "Backups disponibles:"
    ls -la backups/wordpress_backup_complete_*.tar.gz 2>/dev/null | tail -5 || echo "  No se encontraron backups"
    exit 1
fi

BACKUP_FILE="$1"
DB_ONLY=false
FILES_ONLY=false
NO_RESTART=false
FORCE=false

# Procesar opciones
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --db-only)
            DB_ONLY=true
            shift
            ;;
        --files-only)
            FILES_ONLY=true
            shift
            ;;
        --no-restart)
            NO_RESTART=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            warn "Opción desconocida: $1"
            shift
            ;;
    esac
done

# Verificar que el archivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    if [ -f "backups/$BACKUP_FILE" ]; then
        BACKUP_FILE="backups/$BACKUP_FILE"
    else
        error "Archivo de backup no encontrado: $BACKUP_FILE"
    fi
fi

log "📁 Archivo de backup: $BACKUP_FILE"

# Verificar integridad del backup
log "🔍 Verificando integridad del backup..."
if ! tar -tzf "$BACKUP_FILE" >/dev/null 2>&1; then
    error "El archivo de backup está corrupto o no es válido"
fi

log "✅ Backup válido"

# Mostrar advertencia
if [ "$FORCE" != true ]; then
    echo -e "${RED}"
    cat << "EOF"
⚠️  ADVERTENCIA: ESTA OPERACIÓN ES DESTRUCTIVA ⚠️

Esta restauración:
• ELIMINARÁ todos los datos actuales de WordPress
• REEMPLAZARÁ la base de datos actual
• SOBRESCRIBIRÁ todos los archivos
• REINICIARÁ todos los servicios

¿Estás seguro de que quieres continuar?
EOF
    echo -e "${NC}"
    
    read -p "Escribe 'SI' para continuar: " confirm
    if [ "$confirm" != "SI" ]; then
        info "Restauración cancelada"
        exit 0
    fi
fi

# Crear directorio temporal
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

log "📦 Extrayendo backup..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Buscar el directorio del backup
BACKUP_DIR=$(find "$TEMP_DIR" -name "backup_*" -type d | head -n 1)

if [ ! -d "$BACKUP_DIR" ]; then
    error "No se encontró el directorio de backup en el archivo"
fi

log "✅ Backup extraído en: $BACKUP_DIR"

# Mostrar información del backup
if [ -f "$BACKUP_DIR/backup_info.txt" ]; then
    echo -e "${BLUE}"
    echo "==================== INFORMACIÓN DEL BACKUP ===================="
    head -20 "$BACKUP_DIR/backup_info.txt"
    echo "=================================================================="
    echo -e "${NC}"
fi

# Obtener configuración actual
PROJECT_NAME=$(grep "COMPOSE_PROJECT_NAME=" .env | cut -d '=' -f2 2>/dev/null || echo "wordpress")
DB_NAME=$(grep "POSTGRES_DB=" .env | cut -d '=' -f2)
DB_USER=$(grep "POSTGRES_USER=" .env | cut -d '=' -f2)

# ============================================
# DETENER SERVICIOS
# ============================================

if [ "$NO_RESTART" != true ]; then
    log "⏹️  Deteniendo servicios..."
    docker compose down
    
    # Esperar a que se detengan completamente
    sleep 5
fi

# ============================================
# RESTAURAR BASE DE DATOS
# ============================================

if [ "$FILES_ONLY" != true ]; then
    log "🗄️  Restaurando base de datos PostgreSQL..."
    
    # Iniciar solo PostgreSQL para la restauración
    docker compose up -d postgres
    
    # Esperar a que PostgreSQL esté listo
    log "⏳ Esperando PostgreSQL..."
    sleep 10
    
    # Verificar conexión
    timeout=60
    while ! docker compose exec postgres pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; do
        if [ $timeout -le 0 ]; then
            error "Timeout esperando PostgreSQL"
        fi
        echo -n "."
        sleep 2
        timeout=$((timeout-2))
    done
    echo
    
    # Buscar archivo de backup de base de datos
    DB_DUMP_FILE=$(find "$BACKUP_DIR" -name "database_*.dump" | head -n 1)
    DB_SQL_FILE=$(find "$BACKUP_DIR" -name "database_*.sql" | head -n 1)
    
    if [ -f "$DB_DUMP_FILE" ]; then
        log "📊 Restaurando desde archivo .dump..."
        
        # Restaurar usando pg_restore
        docker compose exec -T postgres pg_restore \
            -U "$DB_USER" \
            -d "$DB_NAME" \
            --clean \
            --if-exists \
            --verbose \
            < "$DB_DUMP_FILE" || warn "Algunos errores durante la restauración de la DB (normal en primera instalación)"
            
    elif [ -f "$DB_SQL_FILE" ]; then
        log "📊 Restaurando desde archivo .sql..."
        
        # Restaurar usando psql
        docker compose exec -T postgres psql \
            -U "$DB_USER" \
            -d "$DB_NAME" \
            < "$DB_SQL_FILE" || warn "Algunos errores durante la restauración de la DB (normal en primera instalación)"
    else
        warn "No se encontró archivo de backup de base de datos"
    fi
    
    log "✅ Base de datos restaurada"
fi

# ============================================
# RESTAURAR ARCHIVOS WORDPRESS
# ============================================

if [ "$DB_ONLY" != true ]; then
    log "📁 Restaurando archivos de WordPress..."
    
    # Crear backup de seguridad de archivos actuales
    if [ -d "wordpress" ]; then
        log "💾 Creando backup de seguridad de archivos actuales..."
        mv wordpress "wordpress_backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi
    
    # Buscar archivo de archivos WordPress
    WP_FILES=$(find "$BACKUP_DIR" -name "wordpress_files_*.tar.gz" | head -n 1)
    
    if [ -f "$WP_FILES" ]; then
        log "📂 Restaurando archivos WordPress..."
        mkdir -p wordpress
        tar -xzf "$WP_FILES" -C wordpress/
        
        # Configurar permisos
        USER_ID=$(id -u)
        GROUP_ID=$(id -g)
        chown -R $USER_ID:$GROUP_ID wordpress/
        find wordpress/ -type d -exec chmod 755 {} \;
        find wordpress/ -type f -exec chmod 644 {} \;
        chmod -R 777 wordpress/uploads
        
        log "✅ Archivos WordPress restaurados"
    else
        warn "No se encontró archivo de backup de WordPress"
    fi
    
    # Restaurar configuraciones si están disponibles
    CONFIG_FILE=$(find "$BACKUP_DIR" -name "config_*.tar.gz" | head -n 1)
    if [ -f "$CONFIG_FILE" ]; then
        log "⚙️  Restaurando configuraciones..."
        tar -xzf "$CONFIG_FILE" --overwrite 2>/dev/null || warn "Algunas configuraciones no se pudieron restaurar"
        log "✅ Configuraciones restauradas"
    fi
    
    # Restaurar volumen de WordPress core si existe
    WP_CORE_FILE=$(find "$BACKUP_DIR" -name "wordpress_core_*.tar.gz" | head -n 1)
    if [ -f "$WP_CORE_FILE" ]; then
        log "🐳 Restaurando volumen WordPress core..."
        
        # Crear volumen si no existe
        docker volume create "${PROJECT_NAME}_wordpress_core" >/dev/null 2>&1 || true
        
        # Restaurar contenido del volumen
        docker run --rm \
            -v "${PROJECT_NAME}_wordpress_core":/target \
            -v "$BACKUP_DIR":/backup:ro \
            alpine:latest \
            sh -c "cd /target && tar -xzf /backup/$(basename "$WP_CORE_FILE")" \
            2>/dev/null || warn "No se pudo restaurar el volumen wordpress_core"
            
        log "✅ Volumen WordPress core restaurado"
    fi
fi

# ============================================
# REINICIAR SERVICIOS
# ============================================

if [ "$NO_RESTART" != true ]; then
    log "🚀 Iniciando todos los servicios..."
    docker compose up -d
    
    # Esperar a que los servicios estén listos
    log "⏳ Esperando servicios..."
    sleep 20
    
    # Verificar que WordPress está funcionando
    WORDPRESS_PORT=$(grep "WORDPRESS_PORT=" .env | cut -d '=' -f2)
    
    timeout=60
    while ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:$WORDPRESS_PORT" | grep -q "200\|301\|302"; do
        if [ $timeout -le 0 ]; then
            warn "WordPress no respondió en el tiempo esperado, pero la restauración puede haber sido exitosa"
            break
        fi
        echo -n "."
        sleep 5
        timeout=$((timeout-5))
    done
    echo
    
    log "✅ Servicios iniciados"
fi

# ============================================
# LIMPIAR CACHE Y OPTIMIZAR
# ============================================

if [ "$DB_ONLY" != true ] && [ "$NO_RESTART" != true ]; then
    log "🧹 Limpiando cache y optimizando..."
    
    # Limpiar cache de Redis si está disponible
    docker compose exec redis redis-cli FLUSHALL >/dev/null 2>&1 || true
    
    # Actualizar permalinks en WordPress
    docker compose exec wpcli wp rewrite flush --hard >/dev/null 2>&1 || true
    
    # Verificar y reparar base de datos
    docker compose exec wpcli wp db check >/dev/null 2>&1 || true
    docker compose exec wpcli wp db repair >/dev/null 2>&1 || true
    
    log "✅ Optimización completada"
fi

# ============================================
# RESUMEN FINAL
# ============================================

echo -e "${GREEN}"
cat << "EOF"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                 ✅ RESTAURACIÓN COMPLETADA                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

EOF
echo -e "${NC}"

WORDPRESS_PORT=$(grep "WORDPRESS_PORT=" .env | cut -d '=' -f2)
ADMINER_PORT=$(grep "ADMINER_PORT=" .env | cut -d '=' -f2)

info "🌐 WordPress: http://localhost:$WORDPRESS_PORT"
info "🗄️  Adminer: http://localhost:$ADMINER_PORT"

echo -e "${BLUE}🔧 Comandos útiles post-restauración:${NC}"
echo -e "  • Ver logs: ${YELLOW}docker compose logs -f${NC}"
echo -e "  • Verificar servicios: ${YELLOW}docker compose ps${NC}"
echo -e "  • Acceder WP-CLI: ${YELLOW}docker compose exec wpcli wp --info${NC}"

log "🎉 Restauración completada exitosamente"

# Limpiar directorio temporal
rm -rf "$TEMP_DIR" 2>/dev/null || true