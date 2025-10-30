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

- Docker and Docker Compose
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
docker-compose up -d
```

5. Check logs:
```bash
docker-compose logs -f
```

Your relay will be available at:
- Relay WebSocket: `ws://localhost:7777`
- Blossom Server: `http://localhost:3000`

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
docker-compose restart
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

## Deployment

### GitHub Actions CI/CD

This repository includes automated CI/CD via GitHub Actions:

1. **Automatic builds**: Every push to `main` builds a Docker image
2. **Container Registry**: Images are pushed to GitHub Container Registry
3. **Versioning**: Automatic tagging with git SHA and branch name

### Setting Up Deployment

To enable automatic deployment to your server:

1. Add GitHub secrets:
   - `DEPLOY_HOST`: Your server IP/hostname
   - `DEPLOY_USER`: SSH username
   - `DEPLOY_SSH_KEY`: SSH private key
   - `BLOSSOM_ADMIN_PASSWORD`: Password for blossom admin dashboard (optional)

2. Uncomment the `deploy` job in `.github/workflows/deploy.yml`

3. Update the deployment path in the workflow

4. Push to main branch to trigger deployment

### Manual Deployment

On your server:

```bash
# Pull the latest image
docker pull ghcr.io/your-username/nostrarabiarelay:latest

# Run with docker-compose
docker-compose up -d
```

### Production Considerations

For production deployments:

1. **Reverse Proxy**: Use nginx or Caddy for SSL/TLS:
```nginx
# Nostr Relay
server {
    listen 443 ssl;
    server_name relay.yourdomain.com;

    location / {
        proxy_pass http://localhost:7777;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# Blossom Server
server {
    listen 443 ssl;
    server_name cdn.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Increase timeouts for large file uploads
        client_max_body_size 100M;
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
}
```

2. **Persistent Storage**: Ensure the database volume is backed up:
```bash
docker-compose exec nostr-relay tar czf /backup/strfry-db-$(date +%Y%m%d).tar.gz /app/strfry-db
```

3. **Monitoring**: Set up health checks and monitoring for uptime

4. **Firewall**: Only expose necessary ports (443/80 for web if using reverse proxy, or 7777 for relay and 3000 for blossom if not)

5. **Environment Variables**: Set `BLOSSOM_ADMIN_PASSWORD` in your server environment or docker-compose for production security

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
docker-compose logs -f nostr-relay

# Blossom server logs
docker-compose logs -f blossom-server

# All services
docker-compose logs -f
```

Check relay info (NIP-11):
```bash
curl http://localhost:7777 -H "Accept: application/nostr+json"
```

Access blossom admin dashboard:
```
http://localhost:3000
```
Login with username `admin` and the password set in `BLOSSOM_ADMIN_PASSWORD`

## Troubleshooting

### Relay won't start

Check logs:
```bash
docker-compose logs nostr-relay
```

### Events being rejected

1. Verify npub is in hex format (64 characters)
2. Check noteguard.toml configuration
3. Review logs for rejection reasons

### Database issues

If you need to reset the database:
```bash
docker-compose down -v
docker-compose up -d
```

## Architecture

```
┌─────────────────┐
│  Nostr Client   │
└────────┬────────┘
         │ WebSocket/HTTP
         ▼
┌─────────────────────────────────────────┐
│          Reverse Proxy (Optional)       │
│         nginx/Caddy - SSL/TLS           │
└──────────┬─────────────────┬────────────┘
           │                 │
           │ :7777           │ :3000
           ▼                 ▼
┌────────────────┐  ┌──────────────────┐
│  strfry relay  │  │  blossom-server  │
│                │  │                  │
│ ┌───────────┐  │  │ ┌──────────────┐ │
│ │noteguard  │  │  │ │ Media Store  │ │
│ └───────────┘  │  │ │   (blobs)    │ │
│                │  │ └──────────────┘ │
│ ┌───────────┐  │  │                  │
│ │   LMDB    │  │  │ ┌──────────────┐ │
│ │ (events)  │  │  │ │    SQLite    │ │
│ └───────────┘  │  │ │  (metadata)  │ │
└────────────────┘  │ └──────────────┘ │
                    └──────────────────┘
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
