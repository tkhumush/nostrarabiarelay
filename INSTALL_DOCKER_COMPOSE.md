# Install Docker Compose on Server

SSH into your server and run these commands:

## Option 1: Install Docker Compose v2 (Recommended)

```bash
# Update package list
sudo apt update

# Install Docker Compose plugin
sudo apt install -y docker-compose-plugin

# Verify installation
docker compose version
```

## Option 2: Install Docker Compose v1 (Standalone)

```bash
# Download docker-compose binary
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version
```

## Quick One-Liner (Option 2)

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose && sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose && docker-compose --version
```

## After Installation

Test that it works:
```bash
docker-compose --version
# Should show: docker-compose version X.X.X
```

Then trigger a new deployment by pushing to GitHub, or run manually:
```bash
cd /home/nostrarabia/nostr-relay
git pull origin main
docker-compose pull
docker-compose up -d
```
