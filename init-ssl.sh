#!/bin/bash

# SSL Certificate Initialization Script for Nostr Arabia
# This script obtains Let's Encrypt SSL certificates for the domains

set -e

# Configuration
DOMAINS=("nostrarabia.com" "strfry.nostrarabia.com" "media.nostrarabia.com")
EMAIL="admin@nostrarabia.com"  # Change this to your email
STAGING=0  # Set to 1 for testing with Let's Encrypt staging server

echo "==================================="
echo "SSL Certificate Initialization"
echo "==================================="
echo ""

# Check if certificates already exist
if [ -d "./certbot/conf/live/nostrarabia.com" ]; then
    echo "Certificates already exist. Skipping initialization."
    echo "If you want to re-initialize, delete the ./certbot directory and run this script again."
    exit 0
fi

echo "Creating directories for certbot..."
mkdir -p ./certbot/conf
mkdir -p ./certbot/www

echo ""
echo "Creating temporary nginx configuration..."

# Create temporary nginx config that doesn't require SSL
cat > ./nginx/conf.d/temp.conf << 'EOF'
# Temporary configuration for certificate generation
server {
    listen 80;
    server_name nostrarabia.com www.nostrarabia.com strfry.nostrarabia.com media.nostrarabia.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 200 'Certificate generation in progress...';
        add_header Content-Type text/plain;
    }
}
EOF

# Backup original configs
echo "Backing up original nginx configs..."
mkdir -p ./nginx/conf.d/backup
for file in ./nginx/conf.d/*.conf; do
    if [ "$(basename "$file")" != "temp.conf" ]; then
        mv "$file" ./nginx/conf.d/backup/ 2>/dev/null || true
    fi
done

echo ""
echo "Starting temporary nginx container..."
docker-compose up -d nginx

echo ""
echo "Waiting for nginx to be ready..."
sleep 5

# Determine if we're using staging
STAGING_ARG=""
if [ $STAGING != "0" ]; then
    STAGING_ARG="--staging"
    echo "Using Let's Encrypt STAGING server (for testing)"
fi

echo ""
echo "Obtaining SSL certificates..."
echo "This may take a few moments..."
echo ""

# Obtain certificates for all domains
for domain in "${DOMAINS[@]}"; do
    echo "Obtaining certificate for: $domain"
    docker-compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        $STAGING_ARG \
        -d "$domain"
    echo ""
done

echo "Stopping temporary nginx..."
docker-compose down

echo ""
echo "Restoring original nginx configs..."
rm -f ./nginx/conf.d/temp.conf
mv ./nginx/conf.d/backup/* ./nginx/conf.d/ 2>/dev/null || true
rmdir ./nginx/conf.d/backup 2>/dev/null || true

echo ""
echo "==================================="
echo "SSL Initialization Complete!"
echo "==================================="
echo ""
echo "Certificates have been obtained for:"
for domain in "${DOMAINS[@]}"; do
    echo "  - $domain"
done
echo ""
echo "Now you can start the full stack with:"
echo "  docker-compose up -d"
echo ""
