#!/bin/bash

# ============================================
# INSTALADOR AUTOMÁTICO DE WORDPRESS + DOCKER
# Para servidores Linux y WSL
# ============================================

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Función para logging
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

# Banner de inicio
echo -e "${PURPLE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        🚀 INSTALADOR WORDPRESS + DOCKER + POSTGRESQL        ║
║                                                              ║
║           Optimizado para Linux y WSL                       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar si se ejecuta como root (no recomendado)
if [ "$EUID" -eq 0 ]; then
    warn "No ejecutes este script como root. Usa tu usuario normal."
    read -p "¿Continuar de todas formas? (y/N): " continue_as_root
    if [[ ! $continue_as_root =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Verificar dependencias
log "Verificando dependencias del sistema..."

# Verificar Docker
if ! command -v docker &> /dev/null; then
    error "Docker no está instalado. Instálalo desde: https://docs.docker.com/engine/install/"
fi

# Verificar Docker Compose
if ! docker compose version &> /dev/null; then
    error "Docker Compose no está disponible. Asegúrate de tener Docker versión 20.10.13+ o instala docker-compose-plugin"
fi

# Verificar que Docker daemon esté corriendo
if ! docker info &> /dev/null; then
    error "Docker daemon no está ejecutándose. Inicia Docker con: sudo systemctl start docker"
fi

# Verificar permisos de Docker
if ! docker ps &> /dev/null; then
    error "Tu usuario no tiene permisos para usar Docker. Ejecuta: sudo usermod -aG docker \$USER && newgrp docker"
fi

log "✅ Todas las dependencias están instaladas correctamente"

# Obtener información del usuario actual
USER_ID=$(id -u)
GROUP_ID=$(id -g)
CURRENT_USER=$(whoami)

info "Usuario actual: $CURRENT_USER (UID: $USER_ID, GID: $GROUP_ID)"

# Verificar y crear archivo .env
if [ ! -f .env ]; then
    warn "Archivo .env no encontrado. Creando uno desde .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        error "No se encontró .env ni .env.example. Descarga todos los archivos del repositorio."
    fi
fi

# Actualizar PUID y PGID en .env automáticamente
log "Configurando permisos de usuario en .env..."
sed -i "s/PUID=.*/PUID=$USER_ID/" .env
sed -i "s/PGID=.*/PGID=$GROUP_ID/" .env

# Verificar configuración crítica en .env
log "Verificando configuración en .env..."

# Verificar que las contraseñas no sean las por defecto
if grep -q "SecurePassword123" .env || grep -q "AdminSecurePass456" .env; then
    warn "¡Estás usando contraseñas por defecto!"
    echo -e "${YELLOW}Por seguridad, deberías cambiar las contraseñas en el archivo .env${NC}"
    read -p "¿Continuar de todas formas? (y/N): " continue_default_pass
    if [[ ! $continue_default_pass =~ ^[Yy]$ ]]; then
        info "Edita el archivo .env y ejecuta este script nuevamente."
        exit 1
    fi
fi

# Verificar puertos disponibles
log "Verificando disponibilidad de puertos..."

WORDPRESS_PORT=$(grep "WORDPRESS_PORT=" .env | cut -d '=' -f2)
ADMINER_PORT=$(grep "ADMINER_PORT=" .env | cut -d '=' -f2)

check_port() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        error "El puerto $port ya está en uso. Cambia el puerto en el archivo .env"
    fi
}

check_port $WORDPRESS_PORT
check_port $ADMINER_PORT

log "✅ Puertos disponibles"

# Crear estructura de directorios
log "Creando estructura de directorios..."

# Directorios principales
mkdir -p wordpress/{themes,plugins,uploads,mu-plugins,languages}
mkdir -p config/{nginx,php}
mkdir -p logs/{nginx,php}
mkdir -p backups
mkdir -p ssl

# Configurar permisos correctos
log "Configurando permisos de directorios..."

# Permisos para WordPress
chown -R $USER_ID:$GROUP_ID wordpress/
find wordpress/ -type d -exec chmod 755 {} \;
find wordpress/ -type f -exec chmod 644 {} \;
chmod -R 777 wordpress/uploads  # Necesario para subida de archivos

# Permisos para logs
chown -R $USER_ID:$GROUP_ID logs/
chmod -R 755 logs/

# Permisos para backups
chown -R $USER_ID:$GROUP_ID backups/
chmod -R 755 backups/

log "✅ Estructura de directorios creada"

# Verificar archivos de configuración
log "Verificando archivos de configuración..."

required_configs=(
    "config/nginx/nginx.conf"
    "config/nginx/default.conf"
    "config/php/custom.ini"
    "config/php/php-fpm.conf"
)

for config in "${required_configs[@]}"; do
    if [ ! -f "$config" ]; then
        error "Archivo de configuración faltante: $config. Descarga todos los archivos del repositorio."
    fi
done

log "✅ Archivos de configuración encontrados"

# Detener contenedores existentes si están ejecutándose
log "Deteniendo contenedores existentes..."
docker compose down 2>/dev/null || true

# Limpiar imágenes huérfanas
log "Limpiando imágenes Docker no utilizadas..."
docker system prune -f >/dev/null 2>&1 || true

# Descargar imágenes Docker
log "Descargando imágenes Docker (esto puede tomar varios minutos)..."
docker compose pull

# Construir y levantar servicios
log "Iniciando servicios Docker..."
docker compose up -d --build

# Esperar a que los servicios estén listos
log "Esperando a que los servicios inicializen..."

wait_for_service() {
    local service=$1
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker compose ps $service | grep -q "healthy\|running"; then
            log "✅ $service está listo"
            return 0
        fi
        
        echo -n "."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    error "Timeout esperando a que $service esté listo"
}

echo -n "Esperando PostgreSQL"
wait_for_service postgres
echo

echo -n "Esperando WordPress"
wait_for_service wordpress
echo

echo -n "Esperando Nginx"
wait_for_service nginx
echo

# Instalar WordPress si no está instalado
log "Configurando WordPress inicial..."

# Esperar un poco más para asegurar que WordPress esté completamente listo
sleep 10

# Verificar si WordPress ya está instalado
if docker compose exec -T wpcli wp core is-installed 2>/dev/null; then
    info "WordPress ya está instalado"
else
    log "Instalando WordPress..."
    
    # Obtener configuraciones desde .env
    WP_ADMIN_USER=$(grep "WP_ADMIN_USER=" .env | cut -d '=' -f2)
    WP_ADMIN_PASSWORD=$(grep "WP_ADMIN_PASSWORD=" .env | cut -d '=' -f2)
    WP_ADMIN_EMAIL=$(grep "WP_ADMIN_EMAIL=" .env | cut -d '=' -f2)
    WP_SITE_TITLE=$(grep "WP_SITE_TITLE=" .env | cut -d '=' -f2)
    WP_SITE_URL=$(grep "WP_SITE_URL=" .env | cut -d '=' -f2)
    
    # Instalar WordPress
    docker compose exec -T wpcli wp core install \
        --url="$WP_SITE_URL" \
        --title="$WP_SITE_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email
    
    log "✅ WordPress instalado correctamente"
fi

# Configurar permalinks
log "Configurando permalinks..."
docker compose exec -T wpcli wp rewrite structure '/%postname%/' --hard

# Instalar plugins útiles para desarrollo
log "Instalando plugins de desarrollo..."
docker compose exec -T wpcli wp plugin install query-monitor --activate 2>/dev/null || true
docker compose exec -T wpcli wp plugin install redis-cache --activate 2>/dev/null || true

# Configurar Redis cache
log "Configurando cache Redis..."
docker compose exec -T wpcli wp redis enable 2>/dev/null || true

# Crear directorio de ejemplo para temas
if [ ! -f "wordpress/themes/mi-tema-personalizado/style.css" ]; then
    log "Creando tema de ejemplo..."
    mkdir -p wordpress/themes/mi-tema-personalizado
    
    cat > wordpress/themes/mi-tema-personalizado/style.css << EOF
/*
Theme Name: Mi Tema Personalizado
Description: Tema de ejemplo para desarrollo
Version: 1.0
Author: Tu Nombre
*/

body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    background-color: #f4f4f4;
}

.container {
    max-width: 800px;
    margin: 0 auto;
    background: white;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 0 10px rgba(0,0,0,0.1);
}
EOF

    cat > wordpress/themes/mi-tema-personalizado/index.php << 'EOF'
<?php
/**
 * Tema personalizado de ejemplo
 */

get_header(); ?>

<div class="container">
    <h1>¡Bienvenido a tu tema personalizado!</h1>
    <p>Este es un tema de ejemplo. Puedes modificarlo desde: <code>wordpress/themes/mi-tema-personalizado/</code></p>
    
    <?php if (have_posts()) : ?>
        <?php while (have_posts()) : the_post(); ?>
            <article>
                <h2><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
                <div><?php the_content(); ?></div>
                <hr>
            </article>
        <?php endwhile; ?>
    <?php else : ?>
        <p>No hay contenido disponible.</p>
    <?php endif; ?>
</div>

<?php get_footer(); ?>
EOF

    log "✅ Tema de ejemplo creado"
fi

# Mostrar información final
echo -e "${GREEN}"
cat << "EOF"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                    🎉 ¡INSTALACIÓN COMPLETA!                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

EOF
echo -e "${NC}"

echo -e "${BLUE}📱 ACCEDE A TUS SERVICIOS:${NC}"
echo -e "  • WordPress: ${GREEN}http://localhost:$WORDPRESS_PORT${NC}"
echo -e "  • Adminer (DB): ${GREEN}http://localhost:$ADMINER_PORT${NC}"
echo ""

echo -e "${BLUE}🔐 CREDENCIALES:${NC}"
echo -e "  • Usuario WP: ${YELLOW}$WP_ADMIN_USER${NC}"
echo -e "  • Password WP: ${YELLOW}$WP_ADMIN_PASSWORD${NC}"
echo ""

echo -e "${BLUE}📂 DIRECTORIOS DE DESARROLLO:${NC}"
echo -e "  • Temas: ${YELLOW}./wordpress/themes/${NC}"
echo -e "  • Plugins: ${YELLOW}./wordpress/plugins/${NC}"
echo -e "  • Uploads: ${YELLOW}./wordpress/uploads/${NC}"
echo ""

echo -e "${BLUE}🔧 COMANDOS ÚTILES:${NC}"
echo -e "  • Ver logs: ${YELLOW}docker compose logs -f${NC}"
echo -e "  • Reiniciar: ${YELLOW}docker compose restart${NC}"
echo -e "  • Detener: ${YELLOW}docker compose down${NC}"
echo -e "  • WP-CLI: ${YELLOW}docker compose exec wpcli wp [comando]${NC}"
echo ""

echo -e "${BLUE}💾 BACKUP AUTOMÁTICO:${NC}"
echo -e "  • Los backups se guardan en: ${YELLOW}./backups/${NC}"
echo -e "  • Crear backup: ${YELLOW}./backup.sh${NC}"
echo ""

echo -e "${GREEN}¡Disfruta desarrollando con WordPress! 🚀${NC}"

# Opcional: Abrir navegador automáticamente (solo si está disponible)
if command -v xdg-open > /dev/null; then
    read -p "¿Abrir WordPress en el navegador? (y/N): " open_browser
    if [[ $open_browser =~ ^[Yy]$ ]]; then
        xdg-open "http://localhost:$WORDPRESS_PORT" 2>/dev/null &
    fi
fi