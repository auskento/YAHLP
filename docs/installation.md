# Installation Guide

Complete setup instructions for YAHLP on Docker and Unraid.

## Configuration Approach

YAHLP uses two complementary configuration methods:

**JSON5 Config** (`yahlp.json5`) — Base configuration template, reusable  
**Environment Variables** — Per-deployment overrides, secrets-safe

Environment variables override JSON5 settings, allowing:
- Reusable base config in `yahlp.json5`
- Deployment-specific secrets in `.env` (kept private)
- Same image deployed to different environments with different configs

**Example:**
- `yahlp.json5`: `sonarr: { url: 'http://sonarr:8989' }`
- `.env` local: `SONARR_API_KEY=your-actual-secret-key`
- Result: Base config reused, secrets protected

See [Configuration Guide](configuration.md) for complete details and setup patterns.

## Table of Contents
1. [Docker Compose (Recommended)](#docker-compose)
2. [Docker CLI](#docker-cli)
3. [Unraid](#unraid)
4. [Post-Installation](#post-installation)

---

## Docker Compose

### Prerequisites
- Docker and Docker Compose installed
- **Config folder mounted to `/etc/yahlp`** (required for all deployments)
  - Stores configuration, certificates, and templates
  - Created automatically if you use docker-compose.yml
- For public access: registered domain + open ports 80/443 + email for Let's Encrypt
- For private access: internal network access + internal IP

### Step 1: Get YAHLP

Download YAHLP from GitHub:
```bash
git clone https://github.com/auskento/YAHLP.git
cd YAHLP
```

Or download the latest release manually from https://github.com/auskento/YAHLP/releases

### Step 2: Create Environment File
```bash
cp .env.example .env
nano .env  # or your preferred editor
```

### Step 3: Configure for Your Setup

**For Public Access (HTTPS):**
```bash
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com
ACCESS_MODE=public
IP=                          # Leave empty
```

**For Private Access (Internal):**
```bash
DOMAIN=                      # Leave empty
EMAIL=                       # Leave empty
ACCESS_MODE=private
IP=192.168.1.100            # Your internal IP
```

### Step 4: Enable Services
Edit `.env` and set services you want:
```bash
SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989

RADARR_ENABLED=true
RADARR_URL=http://radarr:7878

JELLYFIN_ENABLED=true
JELLYFIN_URL=http://jellyfin:8096

QBITTORRENT_ENABLED=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=your-api-key-here
```

See [SERVICES.md](SERVICES.md) for complete service list and URLs.

### Step 5: Build and Start
```bash
# Build the image (first time only)
docker-compose build

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f yahlp

# Stop
docker-compose down
```

### Step 6: Configure Persistent Storage (Volumes)

**Important:** To preserve data across container restarts, map these folders to external storage:

```yaml
version: '3'
services:
  yahlp:
    build: .
    ports:
      - "80:80"
      - "443:443"
    volumes:
      # Single config folder for everything (required for all deployments)
      - ./config:/etc/yahlp
      
    environment:
      DOMAIN: yourdomain.com
      EMAIL: admin@yourdomain.com
      # ... more settings
```

**What the config folder stores:**
- `yahlp.json5` - Configuration file
- `sites.json5` - Custom sites configuration
- `certs/` - SSL certificates (Let's Encrypt, renewed automatically)
- `templates/` - Custom dashboard layouts (auto-created on first start)
  - `templates/README.md` - Template instructions (auto-copied)
- `logs/` - Apache access/error logs (auto-created)
  - `logs/sites/` - Per-site logs

### Step 7: Verify Installation
```bash
# Check container is running
docker-compose ps

# Test connectivity
docker-compose exec yahlp curl http://localhost/health

# Check Apache configuration
docker-compose exec yahlp apache2ctl configtest
```

---

## Docker CLI

If not using Docker Compose:

### Basic Run Command
```bash
docker run -d \
  --name yahlp \
  -p 80:80 \
  -p 443:443 \
  -v ./config:/etc/yahlp \
  -e DOMAIN=yourdomain.com \
  -e EMAIL=admin@yourdomain.com \
  -e ACCESS_MODE=public \
  -e SONARR_ENABLED=true \
  -e SONARR_URL=http://sonarr:8989 \
  auskento/yahlp
```
**Note:** Single volume mount to `/etc/yahlp` for all persistent data (config, certificates, logs, icons)

**Create config folder first:**
```bash
mkdir -p config
```

### With Docker Network
```bash
# Create network
docker network create homelab

# Create config folder
mkdir -p config

# Run YAHLP
docker run -d \
  --name yahlp \
  --network homelab \
  -p 80:80 \
  -p 443:443 \
  -v ./config:/etc/yahlp \
  -e DOMAIN=yourdomain.com \
  -e EMAIL=admin@yourdomain.com \
  -e ACCESS_MODE=public \
  auskento/yahlp

# Run other services on same network
docker run -d \
  --name sonarr \
  --network homelab \
  -p 8989:8989 \
  linuxserver/sonarr
```

### View Logs
```bash
docker logs -f yahlp
```

### Stop
```bash
docker stop yahlp
docker rm yahlp
```

---

## Unraid

### Using Unraid Templates

YAHLP provides two templates for easy Unraid installation:

1. **yahlp-simple.xml** - Simplified template with common services
2. **yahlp-full.xml** - Complete template with all configuration options

### Installation Steps

1. **Add Template Repository**
   - In Unraid, go to Docker tab
   - Click "Add Container"
   - Select "Template repositories"
   - Add: `https://raw.githubusercontent.com/auskento/YAHLP/main/unraid/`

2. **Create Container**
   - Search for "YAHLP"
   - Choose simple or full template
   - Fill in required fields:
     - **DOMAIN**: Your domain (public mode) or leave blank (private mode)
     - **ACCESS_MODE**: public or private
     - **IP**: Internal IP (private mode only)

3. **Enable Services**
   - Set `SERVICENAME_ENABLED=true` for each service
   - Set corresponding `SERVICENAME_URL`
   - Add authentication details if needed

4. **Configure Storage**
   - Map `/etc/yahlp` to config location (single mount for everything: certificates, config, logs, icons)
   - This single volume stores:
     - `yahlp.json5` - Configuration file
     - `certs/` - SSL certificates (auto-managed)
     - `service_icons/` - Custom service icons
     - `site_icons/` - Custom site icons
     - `logs/` - Apache logs

5. **Apply and Start**
   - Click "Apply"
   - Container will start and build on first run

### Manual Unraid Setup

If not using template:

1. **Open Unraid Terminal**
2. **Run Docker Command**
   ```bash
   docker run -d \
     --name=yahlp \
     -p 80:80 \
     -p 443:443 \
     -e DOMAIN=yourdomain.com \
     -e EMAIL=admin@yourdomain.com \
     -e ACCESS_MODE=public \
     -v /mnt/user/appdata/yahlp:/etc/yahlp \
     auskento/yahlp
   ```
   **Important:** Only one volume mount needed for `/etc/yahlp` - it contains certificates, config, logs, and icon folders

3. **Monitor Logs**
   - Unraid dashboard: Docker tab → yahlp container → Logs

---

## Post-Installation

### 1. Initial Access

**First time access may take 2-5 minutes** while:
- Apache starts
- Let's Encrypt certificate is generated (public mode)
- Dashboard is built

Check logs during this time:
```bash
docker-compose logs -f yahlp
```

### 2. Verify Health Check
```bash
# Check if services are detected as configured
curl http://localhost/health

# Should return JSON showing service status
```

### 3. Test Service Access
```bash
# Access main dashboard
https://yourdomain.com  # or https://IP for private mode

# Test individual service
https://yourdomain.com/sonarr
https://yourdomain.com/radarr
```

### 4. Configure Additional Services

After initial setup, you can:
- Add more services by editing `.env` and restarting
- Customize dashboard layout with `DASHBOARD_STYLE`
- Change service order with `DASHBOARD_ORDER`
- Set authentication method with `AUTHTYPE`

See [CONFIGURATION.md](CONFIGURATION.md) for all options.

### 5. Configure Authentication (Optional)

**Basic Authentication:**
```bash
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=user:password
docker-compose up -d  # Restart to apply
```

**Google OAuth:**
```bash
AUTHTYPE=google
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REDIRECT_URI=https://yourdomain.com
docker-compose up -d
```

See [AUTHENTICATION.md](AUTHENTICATION.md) for detailed setup.

---

## Troubleshooting Installation

### Container Won't Start
```bash
# Check logs
docker-compose logs yahlp

# Check if ports are available
netstat -tlnp | grep :80
netstat -tlnp | grep :443

# Try removing and recreating
docker-compose down
docker-compose up -d
```

### Certificate Generation Failed
1. Verify domain resolves to your IP: `nslookup yourdomain.com`
2. Verify ports 80/443 are open
3. Check EMAIL is valid in .env
4. Look for errors in logs: `docker-compose logs yahlp | grep -i error`

### Services Showing Offline
1. Verify service URL in .env is correct
2. Check service is running: `docker-compose ps servicename`
3. Test connectivity: `docker-compose exec yahlp curl http://servicename:port`
4. Check firewall between YAHLP and service

### Can't Access Dashboard
- **Public mode:** Wait 2-5 minutes for setup, verify domain DNS, check port 443 access
- **Private mode:** Verify internal IP is correct, check on same network
- **Check logs:** `docker-compose logs yahlp`

More help in [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## Next Steps

1. **Configure Services** → [SERVICES.md](SERVICES.md)
2. **Set Authentication** → [AUTHENTICATION.md](AUTHENTICATION.md)
3. **Customize Dashboard** → [DASHBOARD-CUSTOMIZATION.md](DASHBOARD-CUSTOMIZATION.md)
4. **All Settings** → [CONFIGURATION.md](CONFIGURATION.md)
