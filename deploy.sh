#!/bin/bash

# VEYL Production Deployment Script
# Target Host: veyl.kkdes.co.ke

set -e # Exit immediately if any command returns a non-zero exit code

echo "=========================================================="
echo "      Starting VEYL Production Deployment Setup           "
echo "=========================================================="

# 1. Verify Docker & Docker Compose Installation
if ! [ -x "$(command -v docker)" ]; then
    echo "Docker is not installed! Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
else
    echo "[√] Docker is installed."
fi

if ! [ -x "$(command -v docker-compose)" ] && ! docker compose version &>/dev/null; then
    echo "Docker Compose is not installed! Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "[√] Docker Compose is installed."
fi

# 2. Setup Production Environment Variables
echo "Configuring production environment variables..."
cat <<EOT > backend/.env
DATABASE_URL="postgresql://veyl_admin:VeylSecurePass2026@postgres:5432/veyl_db?schema=public"
REDIS_URL="redis://redis:6379"
JWT_SECRET="VeylProdSecretJWTKey2026SecureLongString"
JWT_REFRESH_SECRET="VeylProdSecretJWTRefreshKey2026SecureLongString"
PORT=3000
EOT

# 3. Build and Start Docker Containers
echo "Building and launching Docker containers..."
docker compose down --remove-orphans || true
docker compose build --no-cache
docker compose up -d

# 4. Sync Database Schema using Prisma
echo "Waiting for PostgreSQL database to warm up..."
sleep 5
echo "Running Prisma Database Sync..."
docker compose exec -T backend npx prisma db push

# 5. Clean up unused images
echo "Pruning unused Docker assets..."
docker image prune -f

# 6. Configure Apache Reverse Proxy (Optional Host Setup)
if [ -d "/etc/apache2" ]; then
    echo "Apache web server detected on host. Configuring reverse proxy..."
    sudo a2enmod proxy || true
    sudo a2enmod proxy_http || true
    sudo a2enmod proxy_wstunnel || true
    sudo a2enmod rewrite || true
    sudo a2enmod ssl || true
    
    sudo cp veyl-apache.conf /etc/apache2/sites-available/veyl.conf
    sudo a2ensite veyl.conf || true
    sudo systemctl restart apache2 || true
    echo "[√] Apache reverse proxy configured and restarted!"
else
    echo "Apache directory (/etc/apache2) not found on host. Skipping auto-proxy setup."
    echo "Manually copy 'veyl-apache.conf' to your configuration if needed."
fi

echo "=========================================================="
echo "          VEYL Deployment Completed Successfully!         "
echo "=========================================================="
echo "API Endpoint & Web Client served at: http://localhost:3000"
echo "Check logs using: docker compose logs -f"
echo "Verify status using: docker compose ps"
echo "=========================================================="
