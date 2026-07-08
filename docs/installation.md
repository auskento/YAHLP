# Installation Guide

Complete setup instructions for YAHLP on Docker and Unraid.

## Configuration Approach

YAHLP uses two complementary configuration methods:

**JSON5 Config** (`yahlp.json5`) — Shared base configuration, version-controlled  
**Environment Variables** — Per-deployment overrides, secrets-safe

Environment variables override JSON5 settings, allowing:
- Shared config in `yahlp.json5` for your team/git repository
- Secrets and local settings in `.env` (git-ignored)
- Same image deployed to different environments with different configs

**Example:**
- `yahlp.json5` in git: `sonarr: { url: 'http://sonarr:8989' }`
- `.env` local: `SONARR_API_KEY=secret-key-not-in-git`
- Result: Base config shared, secrets protected

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
- Git (to clone repository)
- For public access: registered domain + open ports 80/443
- For private access: internal network access + internal IP

### Step 1: Clone Repository
```bash
git clone https://github.com/auskento/YAHLP.git
cd YAHLP
```

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
ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989

ENABLE_RADARR=true
RADARR_URL=http://radarr:7878

ENABLE_JELLYFIN=true
JELLYFIN_URL=http://jellyfin:8096

ENABLE_QBITTORRENT=true
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
      # SSL certificates (Let's Encrypt)
      - ./appdata/letsencrypt:/etc/letsencrypt
      
      # Configuration files
      - ./appdata/yahlp:/etc/yahlp
      
      # Custom layouts (CSS templates)
      - ./appdata/templates:/templates
      
      # Apache logs
      - ./appdata/logs:/var/log/apache2
      
    environment:
      DOMAIN: yourdomain.com
      EMAIL: admin@yourdomain.com
      # ... more settings
```

**What each volume stores:**
- `/etc/letsencrypt` - SSL certificates (renewed automatically)
- `/etc/yahlp` - Configuration: `yamlp.json5`, `sites.json5`, generated configs
- `/templates` - Custom dashboard layouts (CSS files)
- `/var/log/apache2` - Apache access/error logs

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
  -v ./appdata/letsencrypt:/etc/letsencrypt \
  -v ./appdata/yahlp:/etc/yahlp \
  -v ./appdata/templates:/templates \
  -v ./appdata/logs:/var/log/apache2 \
  -e DOMAIN=yourdomain.com \
  -e EMAIL=admin@yourdomain.com \
  -e ACCESS_MODE=public \
  -e ENABLE_SONARR=true \
  -e SONARR_URL=http://sonarr:8989 \
  auskento/yahlp
```

**Create volume directories first:**
```bash
mkdir -p appdata/letsencrypt appdata/yahlp appdata/templates appdata/logs
```

### With Docker Network
```bash
# Create network
docker network create homelab

# Create volume directories
mkdir -p appdata/letsencrypt appdata/yahlp appdata/templates appdata/logs

# Run YAHLP
docker run -d \
  --name yahlp \
  --network homelab \
  -p 80:80 \
  -p 443:443 \
  -v ./appdata/letsencrypt:/etc/letsencrypt \
  -v ./appdata/yahlp:/etc/yahlp \
  -v ./appdata/templates:/templates \
  -v ./appdata/logs:/var/log/apache2 \
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
   - Set `ENABLE_SERVICENAME=true` for each service
   - Set corresponding `SERVICENAME_URL`
   - Add authentication details if needed

4. **Configure Storage**
   - Map `/etc/letsencrypt` to appdata location
   - Map `/etc/yahlp` to config location

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
     -v /mnt/user/appdata/yahlp:/etc/letsencrypt \
     -v /mnt/user/appdata/yahlp/config:/etc/yahlp \
     auskento/yahlp
   ```

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
