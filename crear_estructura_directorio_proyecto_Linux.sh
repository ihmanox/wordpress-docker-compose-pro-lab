#!/bin/bash

ROOT="wordpress-docker-compose-pro-lab"

# Crear carpeta raíz
mkdir -p "$ROOT"

# Crear archivos en la raíz
touch "$ROOT/docker-compose.yml"
touch "$ROOT/.env"
touch "$ROOT/install.sh"
touch "$ROOT/backup.sh"
touch "$ROOT/restore.sh"
touch "$ROOT/generate-ssl.sh"

# Crear subdirectorios de WordPress
mkdir -p "$ROOT/wordpress/themes"
mkdir -p "$ROOT/wordpress/plugins"
mkdir -p "$ROOT/wordpress/uploads"
mkdir -p "$ROOT/wordpress/mu-plugins"

# Crear subdirectorios de configuración
mkdir -p "$ROOT/config/nginx"
mkdir -p "$ROOT/config/php"

# Crear carpetas adicionales
mkdir -p "$ROOT/backups"
mkdir -p "$ROOT/logs"
mkdir -p "$ROOT/ssl"
