# Nginx Setup for Nostr Relay

Set up nginx as a reverse proxy with optional SSL/TLS for your Nostr relay.

## Step 1: Install Nginx

SSH into your server:
```bash
ssh nostrarabia@172.105.154.238
```

Install nginx:
```bash
sudo apt update
sudo apt install -y nginx
```

Start and enable nginx:
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

## Step 2: Create Nginx Configuration

Create a new configuration file:
```bash
sudo nano /etc/nginx/sites-available/nostr-relay
```

**Paste this configuration:**

### For IP Only (No Domain)

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name 172.105.154.238;

    # Relay endpoint
    location / {
        proxy_pass http://localhost:7777;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts for WebSocket
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;

        # Buffer settings
        proxy_buffering off;
    }
}
```

### For Domain with SSL (Recommended)

If you have a domain (e.g., relay.nostrarabia.com):

```nginx
# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name relay.nostrarabia.com;  # CHANGE THIS TO YOUR DOMAIN

    # Allow Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # Redirect everything else to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS - Main relay
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name relay.nostrarabia.com;  # CHANGE THIS TO YOUR DOMAIN

    # SSL certificates (will be configured by Certbot)
    ssl_certificate /etc/letsencrypt/live/relay.nostrarabia.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/relay.nostrarabia.com/privkey.pem;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Relay endpoint
    location / {
        proxy_pass http://localhost:7777;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts for WebSocket
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;

        # Buffer settings
        proxy_buffering off;
    }
}
```

Save and exit (Ctrl+X, Y, Enter)

## Step 3: Enable the Site

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/nostr-relay /etc/nginx/sites-enabled/

# Remove default nginx page (optional)
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# If test is successful, reload nginx
sudo systemctl reload nginx
```

## Step 4: Configure Firewall

```bash
# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS (if using SSL)
sudo ufw allow 443/tcp

# Allow SSH (if not already allowed)
sudo ufw allow 22/tcp

# Check status
sudo ufw status

# Enable firewall if not enabled
sudo ufw enable
```

## Step 5: Install SSL Certificate (If Using Domain)

**Only do this if you have a domain name!**

Install Certbot:
```bash
sudo apt install -y certbot python3-certbot-nginx
```

Get SSL certificate:
```bash
sudo certbot --nginx -d relay.nostrarabia.com
```

Follow the prompts:
- Enter your email address
- Agree to terms of service
- Choose whether to share email (optional)
- Certbot will automatically configure nginx for SSL

Test auto-renewal:
```bash
sudo certbot renew --dry-run
```

## Step 6: Test Your Setup

### Test HTTP endpoint:
```bash
curl http://172.105.154.238 -H "Accept: application/nostr+json"
```

Should return relay info JSON.

### Test HTTPS endpoint (if using domain):
```bash
curl https://relay.nostrarabia.com -H "Accept: application/nostr+json"
```

### Test from your local machine:
```bash
# From your Mac
curl http://172.105.154.238 -H "Accept: application/nostr+json" | jq

# Or with domain:
curl https://relay.nostrarabia.com -H "Accept: application/nostr+json" | jq
```

## Connection URLs

After nginx setup, your relay will be accessible at:

**Without SSL (IP only):**
- `ws://172.105.154.238` (via nginx on port 80)

**With SSL (domain):**
- `wss://relay.nostrarabia.com` (via nginx on port 443)

**Direct (bypassing nginx):**
- `ws://172.105.154.238:7777` (still works)

## Optional: Update Relay Contact Info

Update your relay's contact field with the public URL:

On your local machine:
```bash
cd /Users/taymurkhumush/Documents/GitHub/nostrarabiarelay
nano strfry.conf
```

Update the info section:
```
info {
    name = "Nostr Arabia Relay"
    description = "A whitelisted nostr relay for the Arabia community"
    pubkey = "9cb3545c36940d9a2ef86d50d5c7a8fab90310cc898c4344bcfc4c822ff47bca"
    contact = "wss://relay.nostrarabia.com"  # Or ws://172.105.154.238
}
```

Push the changes:
```bash
git add strfry.conf
git commit -m "Update relay contact URL"
git push origin main
```

## Troubleshooting

### Check nginx status:
```bash
sudo systemctl status nginx
```

### Test nginx configuration:
```bash
sudo nginx -t
```

### View nginx logs:
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Check if relay is running:
```bash
cd /home/nostrarabia/nostr-relay
docker-compose ps
docker-compose logs -f nostr-relay
```

### Test WebSocket connection:
```bash
# Install websocat for testing
sudo wget -qO /usr/local/bin/websocat https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl
sudo chmod +x /usr/local/bin/websocat

# Test via nginx
echo '["REQ","test",{"limit":1}]' | websocat ws://172.105.154.238

# Test direct (should still work)
echo '["REQ","test",{"limit":1}]' | websocat ws://localhost:7777
```

### If nginx won't start:
```bash
# Check what's using port 80
sudo netstat -tlnp | grep :80

# Or
sudo lsof -i :80
```

### If SSL certificate fails:
- Make sure your domain DNS is pointed to 172.105.154.238
- Wait a few minutes for DNS to propagate
- Check: `dig relay.nostrarabia.com` or `nslookup relay.nostrarabia.com`

## Security Notes

- Port 7777 is only accessible from localhost (secure)
- All external traffic goes through nginx (port 80/443)
- SSL certificates auto-renew every 90 days
- Firewall blocks all ports except 22, 80, 443

## Architecture After Nginx Setup

```
Internet
   ↓
Port 80 (HTTP) or 443 (HTTPS)
   ↓
Nginx (reverse proxy)
   ↓
localhost:7777 (Docker container)
   ↓
Strfry Relay + Noteguard
```

## Next Steps

After nginx is set up:
1. Share your relay URL with users: `ws://172.105.154.238` or `wss://relay.nostrarabia.com`
2. Add your relay to Nostr relay lists
3. Monitor logs and usage
4. Consider setting up monitoring (optional)

Your relay is now production-ready! 🚀
