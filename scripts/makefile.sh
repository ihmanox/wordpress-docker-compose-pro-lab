# ============================================
# MAKEFILE PARA WORDPRESS DOCKER
# Comandos simplificados para desarrollo
# ============================================

.PHONY: help install up down restart logs backup restore clean ssl status

# Configuración por defecto
BACKUP_FILE ?= $(shell ls -t backups/wordpress_backup_complete_*.tar.gz 2>/dev/null | head -n1)

# Colores para ayuda
YELLOW := \033[33m
GREEN := \033[32m
BLUE := \033[34m
RESET := \033[0m

## Mostrar ayuda
help:
	@echo "$(BLUE)🚀 WordPress Docker - Comandos Disponibles$(RESET)"
	@echo ""
	@echo "$(GREEN)📦 INSTALACIÓN Y GESTIÓN:$(RESET)"
	@echo "  $(YELLOW)make install$(RESET)     - Instalar WordPress completo (un comando)"
	@echo "  $(YELLOW)make up$(RESET)          - Iniciar todos los servicios"
	@echo "  $(YELLOW)make down$(RESET)        - Detener todos los servicios"
	@echo "  $(YELLOW)make restart$(RESET)     - Reiniciar todos los servicios"
	@echo "  $(YELLOW)make rebuild$(RESET)     - Reconstruir y actualizar contenedores"
	@echo ""
	@echo "$(GREEN)📊 MONITOREO:$(RESET)"
	@echo "  $(YELLOW)make status$(RESET)      - Ver estado de servicios"
	@echo "  $(YELLOW)make logs$(RESET)        - Ver logs en tiempo real"
	@echo "  $(YELLOW)make logs-nginx$(RESET)  - Ver logs de Nginx"
	@echo "  $(YELLOW)make logs-wp$(RESET)     - Ver logs de WordPress"
	@echo "  $(YELLOW)make logs-db$(RESET)     - Ver logs de PostgreSQL"
	@echo ""
	@echo "$(GREEN)💾 BACKUP Y RESTAURACIÓN:$(RESET)"
	@echo "  $(YELLOW)make backup$(RESET)      - Crear backup completo"
	@echo "  $(YELLOW)make restore$(RESET)     - Restaurar último backup"
	@echo "  $(YELLOW)make restore FILE=backup.tar.gz$(RESET) - Restaurar backup específico"
	@echo ""
	@echo "$(GREEN)🔐 SSL Y SEGURIDAD:$(RESET)"
	@echo "  $(YELLOW)make ssl$(RESET)         - Generar certificados SSL para desarrollo"
	@echo "  $(YELLOW)make ssl-enable$(RESET)  - Habilitar HTTPS en Nginx"
	@echo ""
	@echo "$(GREEN)🧹 MANTENIMIENTO:$(RESET)"
	@echo "  $(YELLOW)make clean$(RESET)       - Limpiar sistema Docker"
	@echo "  $(YELLOW)make clean-all$(RESET)   - Limpiar todo (incluyendo volúmenes)"
	@echo "  $(YELLOW)make update$(RESET)      - Actualizar todas las imágenes"
	@echo ""
	@echo "$(GREEN)🛠️  DESARROLLO:$(RESET)"
	@echo "  $(YELLOW)make wp-cli$(RESET)      - Acceder a WP-CLI interactivo"
	@echo "  $(YELLOW)make db-cli$(RESET)      - Acceder a PostgreSQL CLI"
	@echo "  $(YELLOW)make redis-cli$(RESET)   - Acceder a Redis CLI"
	@echo "  $(YELLOW)make shell$(RESET)       - Shell en contenedor WordPress"
	@echo ""
	@echo "$(GREEN)🌐 ACCESOS RÁPIDOS:$(RESET)"
	@echo "  $(YELLOW)make open$(RESET)        - Abrir WordPress en navegador"
	@echo "  $(YELLOW)make open-admin$(RESET)  - Abrir WordPress Admin en navegador"
	@echo "  $(YELLOW)make open-db$(RESET)     - Abrir Adminer en navegador"

## Instalación completa con un comando
install:
	@echo "🚀 Instalando WordPress con Docker..."
	@chmod +x install.sh
	@./install.sh

## Iniciar servicios
up:
	@echo "🐳 Iniciando servicios Docker..."
	@docker compose up -d

## Detener servicios
down:
	@echo "🛑 Deteniendo servicios Docker..."
	@docker compose down

## Reiniciar servicios
restart:
	@echo "🔄 Reiniciando servicios..."
	@docker compose restart

## Reconstruir contenedores
rebuild:
	@echo "🏗️  Reconstruyendo contenedores..."
	@docker compose down
	@docker compose pull
	@docker compose up -d --build

## Ver estado de servicios
status:
	@echo "📊 Estado de servicios:"
	@docker compose ps
	@echo ""
	@echo "💾 Uso de recursos:"
	@docker stats --no-stream

## Ver logs en tiempo real
logs:
	@echo "📄 Logs en tiempo real (Ctrl+C para salir):"
	@docker compose logs -f

## Logs específicos de Nginx
logs-nginx:
	@echo "📄 Logs de Nginx:"
	@docker compose logs -f nginx

## Logs específicos de WordPress
logs-wp:
	@echo "📄 Logs de WordPress/PHP:"
	@docker compose logs -f wordpress

## Logs específicos de PostgreSQL
logs-db:
	@echo "📄 Logs de PostgreSQL:"
	@docker compose logs -f postgres

## Crear backup completo
backup:
	@echo "💾 Creando backup..."
	@chmod +x backup.sh
	@./backup.sh

## Restaurar último backup
restore:
	@echo "🔄 Restaurando último backup..."
	@chmod +x restore.sh
	@if [ -n "$(BACKUP_FILE)" ]; then \
		./restore.sh "$(BACKUP_FILE)"; \
	else \
		echo "❌ No se encontraron backups. Crea uno con 'make backup'"; \
	fi

## Restaurar backup específico
restore-file:
	@echo "🔄 Restaurando backup específico..."
	@chmod +x restore.sh
	@if [ -n "$(FILE)" ]; then \
		./restore.sh "$(FILE)"; \
	else \
		echo "❌ Especifica el archivo: make restore-file FILE=backup.tar.gz"; \
	fi

## Generar certificados SSL
ssl:
	@echo "🔐 Generando certificados SSL..."
	@chmod +x generate-ssl.sh
	@./generate-ssl.sh

## Habilitar HTTPS en Nginx
ssl-enable:
	@echo "🔒 Habilitando HTTPS en Nginx..."
	@if [ ! -f "ssl/cert.pem" ]; then \
		echo "⚠️  Certificados SSL no encontrados. Ejecuta 'make ssl' primero."; \
		exit 1; \
	fi
	@sed -i 's/^# server {/server {/' config/nginx/ssl.conf
	@sed -i 's/^#     /    /' config/nginx/ssl.conf
	@sed -i 's/^# }/}/' config/nginx/ssl.conf
	@docker compose restart nginx
	@echo "✅ HTTPS habilitado. Accede a: https://localhost:8443"

## Limpiar sistema Docker
clean:
	@echo "🧹 Limpiando sistema Docker..."
	@docker system prune -f
	@docker image prune -f

## Limpiar todo incluyendo volúmenes
clean-all:
	@echo "🧹 Limpieza completa del sistema Docker..."
	@docker compose down -v
	@docker system prune -a -f --volumes
	@echo "⚠️  Se han eliminado todos los volúmenes. Los datos se han perdido."

## Actualizar imágenes
update:
	@echo "📦 Actualizando imágenes Docker..."
	@docker compose pull
	@docker compose up -d --build

## Acceso a WP-CLI
wp-cli:
	@echo "🎯 Accediendo a WP-CLI..."
	@docker compose exec wpcli bash

## Acceso a PostgreSQL CLI
db-cli:
	@echo "🗄️  Accediendo a PostgreSQL..."
	@docker compose exec postgres psql -U $(shell grep POSTGRES_USER .env | cut -d'=' -f2) -d $(shell grep POSTGRES_DB .env | cut -d'=' -f2)

## Acceso a Redis CLI
redis-cli:
	@echo "🔴 Accediendo a Redis CLI..."
	@docker compose exec redis redis-cli

## Shell en WordPress
shell:
	@echo "🐚 Accediendo al shell de WordPress..."
	@docker compose exec wordpress bash

## Abrir WordPress en navegador
open:
	@echo "🌐 Abriendo WordPress..."
	@if command -v xdg-open > /dev/null; then \
		xdg-open "http://localhost:$(shell grep WORDPRESS_PORT .env | cut -d'=' -f2)"; \
	elif command -v open > /dev/null; then \
		open "http://localhost:$(shell grep WORDPRESS_PORT .env | cut -d'=' -f2)"; \
	else \
		echo "Accede manualmente a: http://localhost:$(shell grep WORDPRESS_PORT .env | cut -d'=' -f2)"; \
	fi

## Abrir WordPress Admin
open-admin:
	@echo "👨‍💼 Abriendo WordPress Admin..."
	@if command -v xdg-open > /dev/null; then \
		xdg-open "http://localhost:$(shell grep WORDPRESS_PORT .env | cut -d'=' -f2)/wp-admin"; \
	elif command -v open > /dev/null; then \
		open "http://localhost:$(shell grep WORDPRESS_PORT .env | cut -d'=' -f2)/wp-admin"; \
	else \
		echo "Accede manualmente a: http://localhost:$(shell grep WORDPRESS_PORT .env | cut -d'=' -f2)/wp-admin"; \
	fi

## Abrir Adminer
open-db:
	@echo "🗄️  Abriendo Adminer..."
	@if command -v xdg-open > /dev/null; then \
		xdg-open "http://localhost:$(shell grep ADMINER_PORT .env | cut -d'=' -f2)"; \
	elif command -v open > /dev/null; then \
		open "http://localhost:$(shell grep ADMINER_PORT .env | cut -d'=' -f2)"; \
	else \
		echo "Accede manualmente a: http://localhost:$(shell grep ADMINER_PORT .env | cut -d'=' -f2)"; \
	fi

## Comando por defecto
.DEFAULT_GOAL := help