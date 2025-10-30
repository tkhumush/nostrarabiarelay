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

# Check if certificates already exist by trying to list them
CERT_EXISTS=$(docker-compose run --rm certbot certificates 2>&1 | grep -c "Certificate Name: nostrarabia.com" || echo "0")

if [ "$CERT_EXISTS" != "0" ]; then
    echo "Certificates already exist. Skipping initialization."
    echo "If you want to re-initialize, delete the certbot volumes and run this script again."
    echo "Run: docker-compose down -v"
    exit 0
fi

echo "Creating directories for ACME challenge..."
mkdir -p ./certbot-www

echo ""
echo "Creating temporary nginx configuration..."

# Create temporary nginx config that doesn't require SSL
cat > ./nginx/conf.d/temp.conf << 'EOF'
# Temporary configuration for certificate generation
server {
    listen 80 default_server;
    server_name _;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 200 'Certificate generation in progress...\n';
        add_header Content-Type text/plain;
    }
}
EOF

# Backup original configs
echo "Backing up original nginx configs..."
mkdir -p ./nginx/conf.d/backup
for file in ./nginx/conf.d/*.conf; do
    filename=$(basename "$file")
    if [ "$filename" != "temp.conf" ]; then
        mv "$file" "./nginx/conf.d/backup/" 2>/dev/null || true
    fi
done

echo ""
echo "Starting nginx with temporary configuration..."
docker-compose up -d nginx

echo ""
echo "Waiting for nginx to be ready..."
sleep 10

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

# Obtain certificates for all domains in one certificate (with SANs)
echo "Obtaining certificate for all domains..."
DOMAIN_ARGS=""
for domain in "${DOMAINS[@]}"; do
    DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done

docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    $STAGING_ARG \
    $DOMAIN_ARGS

echo ""
echo "Stopping temporary nginx..."
docker-compose stop nginx
docker-compose rm -f nginx

echo ""
echo "Restoring original nginx configs..."
rm -f ./nginx/conf.d/temp.conf
mv ./nginx/conf.d/backup/* ./nginx/conf.d/ 2>/dev/null || true
rmdir ./nginx/conf.d/backup 2>/dev/null || true

# Clean up temporary directory
rm -rf ./certbot-www

echo ""
echo "==================================="
echo "SSL Initialization Complete!"
echo "==================================="
echo ""
echo "Certificate obtained for:"
for domain in "${DOMAINS[@]}"; do
    echo "  - $domain"
done
echo ""
echo "Now you can start the full stack with:"
echo "  docker-compose up -d"
echo ""
