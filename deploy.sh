#!/bin/bash
# ─── Deploy PIC1 a servidor Ubuntu ───────────────────────────────
KEY="$HOME/Downloads/rango-optimo-key.pem"
SERVER="ubuntu@13.223.205.113"
PORT=8080

set -e
echo "🚀 Iniciando deploy..."

# 1. Subir el archivo HTML
echo "📤 Subiendo pic1.html..."
scp -i "$KEY" -o StrictHostKeyChecking=no pic1.html $SERVER:/tmp/pic1.html

# 2. Configurar servidor remotamente
echo "⚙️  Configurando nginx..."
ssh -i "$KEY" -o StrictHostKeyChecking=no $SERVER << REMOTE
  # Crear directorio
  sudo mkdir -p /var/www/pic1

  # Mover archivo
  sudo mv /tmp/pic1.html /var/www/pic1/index.html
  sudo chown -R www-data:www-data /var/www/pic1

  # Crear config nginx
  sudo tee /etc/nginx/sites-available/pic1 > /dev/null << 'NGINX'
server {
    listen $PORT;
    server_name _;

    root /var/www/pic1;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Cache para assets estáticos
    gzip on;
    gzip_types text/html text/css application/javascript;
}
NGINX

  # Activar sitio
  sudo ln -sf /etc/nginx/sites-available/pic1 /etc/nginx/sites-enabled/pic1

  # Verificar config y recargar
  sudo nginx -t && sudo systemctl reload nginx

  echo "✅ Deploy completado"
REMOTE

echo ""
echo "✅ Listo. Abre en tu navegador:"
echo "   http://13.223.205.113:$PORT"
echo ""
echo "⚠️  Si no carga, abre el puerto $PORT en el Security Group de AWS:"
echo "   EC2 → Security Groups → Inbound Rules → Add Rule → Custom TCP → $PORT → 0.0.0.0/0"
