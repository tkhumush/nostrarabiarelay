#!/bin/bash

# SSL Certificate Initialization Script for Nostr Arabia
# This script obtains Let's Encrypt SSL certificates for the domains

set -e

# Configuration
DOMAINS=("nostrarabia.com" "relay.nostrarabia.com" "media.nostrarabia.com")
EMAIL="admin@nostrarabia.com"  # Change this to your email
STAGING=0  # Set to 1 for testing with Let's Encrypt staging server

echo "==================================="
echo "SSL Certificate Initialization"
echo "==================================="
echo ""

# Check if certificates already exist
echo "Checking for existing certificates..."
CERT_EXISTS=$(docker-compose run --rm --entrypoint "certbot" certbot certificates 2>&1 | grep -c "Certificate Name: nostrarabia.com" || echo "0")

if [ "$CERT_EXISTS" != "0" ]; then
    echo "✓ Certificates already exist. Skipping initialization."
    exit 0
fi

echo "No certificates found. Starting first-time SSL setup..."
echo ""

# Step 1: Temporarily use HTTP-only nginx configs
echo "Step 1: Setting up temporary HTTP-only configuration..."
mkdir -p ./nginx/conf.d-backup
cp -r ./nginx/conf.d/* ./nginx/conf.d-backup/
rm -f ./nginx/conf.d/*.conf
cp ./nginx/conf.d-http-only/* ./nginx/conf.d/
echo "✓ HTTP-only configs activated"
echo ""

# Step 2: Start nginx with HTTP-only config
echo "Step 2: Starting nginx for certificate generation..."
docker-compose up -d nginx
echo "Waiting for nginx to be ready..."
sleep 10
echo "✓ Nginx started"
echo ""

# Step 3: Generate certificates
STAGING_ARG=""
if [ $STAGING != "0" ]; then
    STAGING_ARG="--staging"
    echo "Using Let's Encrypt STAGING server (for testing)"
fi

echo "Step 3: Generating SSL certificates..."
echo "This usually takes less than a minute..."
echo ""

docker-compose run --rm --entrypoint "certbot" certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    $STAGING_ARG \
    -d nostrarabia.com \
    -d relay.nostrarabia.com \
    -d media.nostrarabia.com

echo ""
echo "✓ Certificates generated successfully"
echo ""

# Step 4: Restore HTTPS nginx configs
echo "Step 4: Activating HTTPS configuration..."
rm -f ./nginx/conf.d/*.conf
cp ./nginx/conf.d-backup/* ./nginx/conf.d/
rm -rf ./nginx/conf.d-backup
echo "✓ HTTPS configs activated"
echo ""

# Step 5: Restart nginx with HTTPS
echo "Step 5: Restarting nginx with HTTPS..."
docker-compose restart nginx
sleep 5
echo "✓ Nginx restarted with HTTPS"
echo ""

echo "==================================="
echo "SSL Setup Complete!"
echo "==================================="
echo ""
echo "Your services are now secured with HTTPS:"
for domain in "${DOMAINS[@]}"; do
    echo "  ✓ https://$domain"
done
echo ""
echo "Certificates will auto-renew every 90 days."
echo ""
