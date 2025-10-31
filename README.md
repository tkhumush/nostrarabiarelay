# Nostr Arabia Relay

A whitelisted Nostr relay powered by [strfry](https://github.com/hoytech/strfry) with [noteguard](https://github.com/damus-io/noteguard) plugin for access control, plus [blossom-server](https://github.com/hzrd149/blossom-server) for media/blob storage.

## Features

- High-performance Nostr relay using strfry
- Whitelist-based access control via noteguard
- Media/blob storage server via blossom-server
- Containerized deployment with Docker
- Automated CI/CD pipeline with GitHub Actions
- Easy configuration management

## Quick Start

### Prerequisites

- Docker with Compose plugin (v2)
- Git

### Local Development

1. Clone this repository:
```bash
git clone <your-repo-url>
cd nostrarabiarelay
```

2. Configure your whitelist by editing `noteguard.toml`:
```toml
[filters.whitelist]
pubkeys = [
    "your-npub-in-hex-format-here",
    "another-npub-in-hex-format"
]
```

> **Note**: Npubs need to be converted to hex format. You can use tools like [nostr.band](https://nostr.band/) or the `nak` CLI to convert npub to hex.

3. (Optional) Update relay information in `strfry.conf`:
```
relay {
    info {
        name = "Your Relay Name"
        description = "Your relay description"
        pubkey = "your-admin-pubkey-hex"
        contact = "your-contact-info"
    }
}
```

4. Build and run:
```bash
docker compose up -d
```

5. Check logs:
```bash
docker compose logs -f
```

Your services will be available at:
- **Production (with SSL)**: `wss://relay.nostrarabia.com` and `https://media.nostrarabia.com`
- **Local development**: `ws://localhost:7777` (relay) and `http://localhost:3000` (media)

### Testing Your Relay

Use a Nostr client or the WebSocket testing tool to connect to your relay:

```bash
# Test with websocat (if installed)
echo '["REQ","test-sub",{"limit":1}]' | websocat ws://localhost:7777
```

## Configuration

### Adding Whitelisted Users

To add users who can post to your relay:

1. Get their npub (Nostr public key)
2. Convert to hex format (64 characters)
3. Add to `noteguard.toml`:

```toml
[filters.whitelist]
pubkeys = [
    "16c21558762108afc34e4ff19e4ed51d9a48f79e0c34531efc423d21ab435e93"
]
```

4. Restart the relay:
```bash
docker compose restart
```

### Relay Settings

Modify `strfry.conf` to customize:
- Database size (`dbParams.mapsize`)
- Port and binding (`relay.bind` and `relay.port`)
- Event size limits
- Rate limiting
- Compression settings

### Noteguard Filters

Beyond whitelisting, noteguard supports:

- **Rate limiting**: Limit notes per minute/hour
- **Kind filtering**: Allow only specific event types
- **Content filtering**: Block specific words

See `noteguard.toml` for examples (currently commented out).

### Blossom Server Configuration

The blossom-server provides media and blob storage for Nostr. Configure it via `blossom.yml`:

**Key settings:**

1. **Admin Dashboard** (accessible at `http://localhost:3000`):
```yaml
dashboard:
  enabled: true
  username: admin
  password: "${BLOSSOM_ADMIN_PASSWORD}"
```

Set the `BLOSSOM_ADMIN_PASSWORD` environment variable or it will be auto-generated on startup.

2. **Storage Backend**:
```yaml
storage:
  backend: local  # or "s3" for cloud storage
  local:
    dir: ./data/blobs
```

3. **Upload Settings**:
```yaml
upload:
  enabled: true
  requireAuth: true  # Require Nostr authentication to upload
```

4. **Media Processing**:
```yaml
media:
  enabled: true
  image:
    quality: 85
    outputFormat: "webp"
    maxWidth: 1920
    maxHeight: 1080
  video:
    quality: 85
    maxHeight: 1080
    format: "mp4"
```

5. **Retention Rules** (automatic cleanup):
```yaml
storage:
  rules:
    - type: text/*
      expiration: 1 month
    - type: "image/*"
      expiration: 2 weeks
    - type: "video/*"
      expiration: 1 week
```

**Environment Variables:**
- `BLOSSOM_ADMIN_PASSWORD`: Admin dashboard password (recommended to set via GitHub secrets for deployment)

### Caddy Reverse Proxy with Automatic HTTPS

The deployment uses **Caddy** as a reverse proxy with **fully automatic HTTPS** - no manual SSL certificate management needed!

**Domains configured:**
- `nostrarabia.com` - Main landing page
- `relay.nostrarabia.com` - Nostr relay with WebSocket support
- `media.nostrarabia.com` - Blossom media server

**Features:**
- ✨ **Automatic HTTPS** - Caddy obtains and renews SSL certificates automatically
- 🔄 **Auto-renewal** - Certificates renew automatically before expiration
- 🚀 **HTTP/3 support** - Latest HTTP protocol for better performance
- 🔒 **Security headers** - Built-in best practices
- 📡 **WebSocket support** - Native support for Nostr relay
- 📤 **Large file uploads** - Configured for media server (100MB limit)

**How it works:**

Caddy automatically:
1. Obtains SSL certificates from Let's Encrypt on first start
2. Redirects HTTP to HTTPS
3. Renews certificates before they expire
4. Configures optimal TLS settings

**Important:** Ensure your DNS A records point to your server IP and ports 80/443 are accessible:
- `nostrarabia.com` → Your server IP
- `relay.nostrarabia.com` → Your server IP
- `media.nostrarabia.com` → Your server IP

## Deployment

### GitHub Actions CI/CD

This repository includes automated CI/CD via GitHub Actions:

1. **Automatic builds**: Every push to `main` builds a Docker image
2. **Container Registry**: Images are pushed to GitHub Container Registry
3. **Versioning**: Automatic tagging with git SHA and branch name
4. **Optimized deployment**: Only pulls the nostr-relay image (changes frequently); base images are cached

### Setting Up Deployment

To enable automatic deployment to your server:

1. Add GitHub secrets:
   - `DEPLOY_HOST`: Your server IP/hostname
   - `DEPLOY_USER`: SSH username
   - `DEPLOY_SSH_KEY`: SSH private key
   - `BLOSSOM_ADMIN_PASSWORD`: Password for blossom admin dashboard (optional)

2. Uncomment the `deploy` job in `.github/workflows/deploy.yml`

3. Ensure port 80 is accessible for SSL certificate generation

4. Push to main branch to trigger deployment

### Manual Deployment

On your server:

```bash
# Clone the repository
git clone https://github.com/your-username/nostrarabiarelay.git
cd nostrarabiarelay

# Pull the latest nostr-relay image
docker compose pull nostr-relay

# Start all services - Caddy will automatically obtain SSL certificates
docker compose up -d

# That's it! Caddy handles everything automatically.
# Wait 30-60 seconds for SSL certificates to be obtained on first run.
```

**First deployment:** Caddy will automatically obtain SSL certificates from Let's Encrypt. This takes 30-60 seconds.

**Subsequent deployments:** Caddy reuses existing certificates instantly.

### Production Considerations

**1. SSL Certificates:**
- Caddy handles SSL completely automatically
- Certificates renew automatically before expiration
- Zero manual certificate management required

**2. Persistent Storage & Backups:**
```bash
# Backup relay database
docker compose exec nostr-relay tar czf /backup/strfry-db-$(date +%Y%m%d).tar.gz /app/strfry-db

# Backup blossom media
docker compose exec blossom-server tar czf /backup/blossom-data-$(date +%Y%m%d).tar.gz /app/data

# Backup SSL certificates (Caddy data volume)
docker run --rm -v nostr-relay_caddy-data:/data -v $(pwd):/backup alpine tar czf /backup/caddy-data-$(date +%Y%m%d).tar.gz -C /data .
```

**3. Monitoring:**
- Health checks are configured for all services
- Check service status: `docker compose ps`
- View logs: `docker compose logs -f [service-name]`

**4. Firewall Configuration:**
```bash
# Allow HTTP/HTTPS only (nginx handles routing)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Block direct access to backend services
# Services only accessible through nginx proxy
```

**5. Environment Variables:**
- Set `BLOSSOM_ADMIN_PASSWORD` via GitHub secrets or `.env` file
- Never commit secrets to the repository

**6. DNS Configuration:**
Ensure your DNS A records are correctly configured:
```
nostrarabia.com       → 172.105.154.238
relay.nostrarabia.com → 172.105.154.238
media.nostrarabia.com  → 172.105.154.238
```

## Converting Npub to Hex

### Using nak CLI

```bash
# Install nak
go install github.com/fiatjaf/nak@latest

# Convert npub to hex
nak decode npub1...
```

### Using online tools

- [nostr.band](https://nostr.band/)
- [Nostr.guru](https://nostr.guru/)

## Monitoring

View real-time logs:
```bash
# Relay logs
docker compose logs -f nostr-relay

# Blossom server logs
docker compose logs -f blossom-server

# All services
docker compose logs -f
```

Check relay info (NIP-11):
```bash
# Production
curl https://relay.nostrarabia.com -H "Accept: application/nostr+json"

# Local
curl http://localhost:7777 -H "Accept: application/nostr+json"
```

Access blossom admin dashboard:
```
Production: https://media.nostrarabia.com
Local: http://localhost:3000
```
Login with username `admin` and the password set in `BLOSSOM_ADMIN_PASSWORD`

Check Caddy status and configuration:
```bash
# View Caddy logs
docker compose logs -f caddy

# Verify Caddyfile syntax
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# Reload Caddy configuration
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

SSL certificate status (automatic with Caddy):
```bash
# View Caddy certificates
docker compose exec caddy caddy list-modules | grep tls

# Caddy automatically renews certificates - no manual action needed
```

## Troubleshooting

### Relay won't start

Check logs:
```bash
docker compose logs nostr-relay
```

### Events being rejected

1. Verify npub is in hex format (64 characters)
2. Check noteguard.toml configuration
3. Review logs for rejection reasons

### Database issues

If you need to reset the database:
```bash
docker compose down -v
docker compose up -d
```

### SSL/HTTPS issues

**Caddy fails to obtain certificates:**
1. Verify DNS records are correctly pointed to your server
2. Wait a few minutes for DNS propagation
3. Check if ports 80 and 443 are accessible from the internet
4. Review Caddy logs: `docker compose logs caddy`
5. Ensure no other service is using ports 80/443

**502 Bad Gateway:**
1. Check if backend services are running: `docker compose ps`
2. Check backend service logs for errors
3. Verify Caddyfile configuration: `docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile`

**Caddy advantages over nginx/certbot:**
- No manual certificate generation needed
- No health check issues
- Simpler configuration
- Automatic renewal without cron jobs
- Built-in HTTP/3 support

## Architecture

```
┌─────────────────┐
│  Nostr Client   │
└────────┬────────┘
         │ WSS/HTTPS
         │
         ▼
┌─────────────────────────────────────────────────┐
│              Internet (DNS)                     │
│  nostrarabia.com / strfry / media subdomains    │
└────────────────────┬────────────────────────────┘
                     │ Port 80/443
                     ▼
         ┌───────────────────────┐
         │    Nginx Proxy        │
         │   + Let's Encrypt     │
         │   (SSL/TLS Handler)   │
         └───────┬───────────┬───┘
                 │           │
    :7777 (WS)   │           │   :3000 (HTTP)
                 ▼           ▼
    ┌────────────────┐  ┌──────────────────┐
    │  strfry relay  │  │  blossom-server  │
    │                │  │                  │
    │ ┌───────────┐  │  │ ┌──────────────┐ │
    │ │noteguard  │  │  │ │ Media Store  │ │
    │ │(whitelist)│  │  │ │   (blobs)    │ │
    │ └───────────┘  │  │ └──────────────┘ │
    │                │  │                  │
    │ ┌───────────┐  │  │ ┌──────────────┐ │
    │ │   LMDB    │  │  │ │    SQLite    │ │
    │ │ (database)│  │  │ │  (metadata)  │ │
    │ └───────────┘  │  │ └──────────────┘ │
    └────────────────┘  └──────────────────┘
         │                      │
         └──────────┬───────────┘
                    │
            ┌───────▼───────┐
            │ Docker Network│
            │ (nostr-network)│
            └───────────────┘

All services run in Docker containers with:
- Automatic restarts
- Health checks
- Persistent volumes
- Isolated networking
```

## Resources

- [Strfry Documentation](https://github.com/hoytech/strfry)
- [Noteguard Repository](https://github.com/damus-io/noteguard)
- [Blossom Server](https://github.com/hzrd149/blossom-server)
- [Blossom Protocol Specification](https://github.com/hzrd149/blossom)
- [Nostr Protocol](https://github.com/nostr-protocol/nostr)
- [NIPs (Nostr Implementation Possibilities)](https://github.com/nostr-protocol/nips)

## License

This configuration is provided as-is. Please refer to the individual licenses of strfry and noteguard for their respective terms.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## Support

For issues specific to:
- Strfry: [strfry issues](https://github.com/hoytech/strfry/issues)
- Noteguard: [noteguard issues](https://github.com/damus-io/noteguard/issues)
- Blossom Server: [blossom-server issues](https://github.com/hzrd149/blossom-server/issues)
- This setup: Open an issue in this repository


## Deployment Status
Last deployed: Tue Oct 28 22:42:48 EDT 2025
# Docker Compose installed - ready for deployment
