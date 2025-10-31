# Deployment Setup Instructions

Follow these steps to enable automated deployment from GitHub to your server.

## Step 1: Configure Your Server (172.105.154.238)

SSH into your server as `nostrarabia`:

```bash
ssh nostrarabia@172.105.154.238
```

### 1.1 Add GitHub Actions SSH Public Key

```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the public key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWqxwkUn0gRyZiUMm836layH8mu8FMx+UrsCFL4aWN8 github-actions-deploy" >> ~/.ssh/authorized_keys

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys
```

### 1.2 Install Docker and Docker Compose (if not already installed)

```bash
# Update package index
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker nostrarabia

# Log out and back in for group changes to take effect
exit
```

SSH back in:
```bash
ssh nostrarabia@172.105.154.238
```

Verify Docker is working:
```bash
docker --version
docker compose version
```

### 1.3 Install Git (if not already installed)

```bash
sudo apt install -y git
```

## Step 2: Configure GitHub Secrets

Go to your repository secrets page:
https://github.com/tkhumush/nostrarabiarelay/settings/secrets/actions

Click **"New repository secret"** and add these three secrets:

### Secret 1: DEPLOY_SSH_KEY
- **Name**: `DEPLOY_SSH_KEY`
- **Value**: Copy the entire private key from `DEPLOYMENT_KEYS.txt`, including these lines:
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACDFqscJFJ9IEcmYlDJvN+pWsh/JrvBTMflK7AhS+GljfAAAAJgMi7FBDIux
QQAAAAtzc2gtZWQyNTUxOQAAACDFqscJFJ9IEcmYlDJvN+pWsh/JrvBTMflK7AhS+GljfA
AAAECokCLeywUbP4AjBQXMTxjmtwqVKAS8hc5fSlf7dmQTHMWqxwkUn0gRyZiUMm836lay
H8mu8FMx+UrsCFL4aWN8AAAAFWdpdGh1Yi1hY3Rpb25zLWRlcGxveQ==
-----END OPENSSH PRIVATE KEY-----
```

### Secret 2: DEPLOY_HOST
- **Name**: `DEPLOY_HOST`
- **Value**: `172.105.154.238`

### Secret 3: DEPLOY_USER
- **Name**: `DEPLOY_USER`
- **Value**: `nostrarabia`

## Step 3: Enable GitHub Actions

1. Go to your repository: https://github.com/tkhumush/nostrarabiarelay
2. Click on **"Actions"** tab
3. If prompted, click **"I understand my workflows, go ahead and enable them"**

## Step 4: Test the Deployment

### Option 1: Trigger deployment by pushing a change

Make a small change and push:
```bash
cd /Users/taymurkhumush/Documents/GitHub/nostrarabiarelay
echo "# Test deployment" >> README.md
git add README.md
git commit -m "Test automated deployment"
git push origin main
```

### Option 2: Manually trigger from GitHub

1. Go to: https://github.com/tkhumush/nostrarabiarelay/actions
2. Click on the latest workflow run
3. Watch the progress

## Step 5: Verify Deployment

After the workflow completes, SSH into your server and check:

```bash
ssh nostrarabia@172.105.154.238

# Check if relay is running
cd /home/nostrarabia/nostr-relay
docker compose ps

# Check logs
docker compose logs -f nostr-relay

# Test the relay
curl http://localhost:7777 -H "Accept: application/nostr+json"
```

## Step 6: Configure Firewall (Optional but Recommended)

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow relay port
sudo ufw allow 7777/tcp

# Enable firewall
sudo ufw enable
```

## Step 7: Set Up Domain and SSL (Production)

For production, you'll want to:

1. Point a domain to your server IP (172.105.154.238)
2. Install Caddy or nginx for SSL/TLS
3. Configure reverse proxy to relay on port 7777

Example with Caddy:
```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

Create `/etc/caddy/Caddyfile`:
```
relay.yourdomain.com {
    reverse_proxy localhost:7777
}
```

Restart Caddy:
```bash
sudo systemctl restart caddy
```

## Troubleshooting

### Workflow fails at SSH step
- Make sure the public key is added to server's `~/.ssh/authorized_keys`
- Check that GitHub secrets are correct

### Docker commands fail
- Make sure user is in docker group: `groups nostrarabia`
- If not, run: `sudo usermod -aG docker nostrarabia` and log out/in

### Relay won't start
- Check logs: `docker compose logs nostr-relay`
- Check config: `cat strfry.conf`
- Make sure port 7777 is not in use: `sudo netstat -tlnp | grep 7777`

## Next Steps

Once deployed, your relay will be accessible at:
- Local: `ws://172.105.154.238:7777`
- With domain: `wss://relay.yourdomain.com`

Every push to the `main` branch will automatically:
1. Build a new Docker image
2. Push it to GitHub Container Registry
3. Deploy it to your server
4. Restart the relay

Your relay is now fully automated!
