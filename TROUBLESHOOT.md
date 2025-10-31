# Troubleshooting Steps

Run these commands on your server to diagnose the nginx issue.

## SSH into Server
```bash
ssh nostrarabia@172.105.154.238
```

## Check Nginx Status
```bash
# Is nginx running?
sudo systemctl status nginx

# If not running, start it:
sudo systemctl start nginx
```

## Check Nginx Configuration
```bash
# Test configuration
sudo nginx -t

# View the config file
cat /etc/nginx/sites-available/nostr-relay

# Check what's enabled
ls -la /etc/nginx/sites-enabled/
```

## Check Nginx Logs
```bash
sudo tail -50 /var/log/nginx/error.log
sudo tail -50 /var/log/nginx/access.log
```

## Check DNS Resolution
```bash
# From the server, check if domain resolves
dig relay.nostrarabia.com
ping -c 3 relay.nostrarabia.com
```

## Check Firewall
```bash
sudo ufw status
```

## Check Ports
```bash
# What's listening on port 80?
sudo netstat -tlnp | grep :80

# What's listening on port 443?
sudo netstat -tlnp | grep :443

# What's listening on port 7777?
sudo netstat -tlnp | grep :7777
```

## Check Docker Relay
```bash
cd /home/nostrarabia/nostr-relay
docker compose ps
docker compose logs --tail=50 nostr-relay

# Test direct connection to relay
curl http://localhost:7777 -H "Accept: application/nostr+json"
```

## Manual Nginx Fix (if needed)

If nginx config is wrong, fix it manually:

```bash
# Edit the config
sudo nano /etc/nginx/sites-available/nostr-relay

# Reload nginx
sudo nginx -t && sudo systemctl reload nginx
```

## Check Certbot/SSL
```bash
# Check if certificate exists
sudo ls -la /etc/letsencrypt/live/

# Check certbot logs
sudo tail -50 /var/log/letsencrypt/letsencrypt.log
```

## Quick Test Commands

```bash
# Test from server (should work)
curl http://localhost:7777 -H "Accept: application/nostr+json"

# Test nginx on port 80 (should work if nginx is running)
curl http://localhost -H "Accept: application/nostr+json"

# Test from local machine
curl http://172.105.154.238:7777 -H "Accept: application/nostr+json"
```
