#!/bin/bash

# ============================================
# GENERADOR DE CERTIFICADOS SSL
# Para desarrollo local con HTTPS
# ============================================

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[SSL] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[ADVERTENCIA] $1${NC}"
}

log "🔐 Generando certificados SSL para desarrollo local..."

# Crear directorio SSL si no existe
mkdir -p ssl

# Generar clave privada
log "🔑 Generando clave privada..."
openssl genrsa -out ssl/private.key 2048

# Generar certificado autofirmado
log "📜 Generando certificado autofirmado..."

# Crear archivo de configuración para el certificado
cat > ssl/cert.conf << EOF
[req]
default_bits = 2048
prompt = no
distinguished_name = dn
req_extensions = v3_req

[dn]
C=ES
ST=Murcia
L=Murcia
O=Desarrollo Local
OU=IT Department
CN=localhost

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
DNS.3 = 127.0.0.1
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Generar certificado
openssl req -new -x509 -key ssl/private.key -out ssl/cert.pem -days 365 -config ssl/cert.conf -extensions v3_req

# Configurar permisos
chmod 600 ssl/private.key
chmod 644 ssl/cert.pem

log "✅ Certificados SSL generados correctamente"

info "📁 Archivos generados:"
info "  • Clave privada: ssl/private.key"
info "  • Certificado: ssl/cert.pem"

warn "⚠️  Para habilitar HTTPS:"
echo "1. Descomenta la configuración SSL en config/nginx/ssl.conf"
echo "2. Reinicia Nginx: docker compose restart nginx"
echo "3. Accede a: https://localhost:8443"
echo "4. Acepta el certificado autofirmado en tu navegador"

info "🔒 Estos certificados son solo para desarrollo local"
info "    Para producción usa Let's Encrypt o certificados válidos"

# Limpiar archivo temporal
rm ssl/cert.conf

log "🎉 Proceso completado"