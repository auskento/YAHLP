# Unraid Deployment Guide

Complete guide for deploying YAHLP on Unraid.

## Table of Contents
1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Storage](#storage)
4. [Services](#services)
5. [Troubleshooting](#troubleshooting)

---

## Installation

### Method 1: Using Templates (Recommended)

#### Step 1: Add Repository
1. In Unraid WebUI, go to **Docker** tab
2. Click **"Add Container"** button
3. Click **"Template repositories"**
4. Add URL: `https://raw.githubusercontent.com/auskento/YAHLP/main/unraid/`
5. Click **"Save"**
6. Refresh Docker tab

#### Step 2: Create Container
1. Click **"Add Container"** 
2. Search for **"YAHLP"**
3. Choose template:
   - **yahlp-simple** - Basic setup with common services
   - **yahlp-full** - Complete configuration with all options
4. Click **"Show more"** to see all fields
5. Fill in required fields (see [Configuration](#configuration) below)
6. Click **"Apply"**

#### Step 3: Wait for First Run
- Container builds and starts
- First run takes 3-5 minutes (certificate generation, dashboard build)
- Monitor in Docker tab

#### Step 4: Access Dashboard
```
https://yourdomain.com
```
or
```
https://192.168.x.x  (for private mode)
```

### Method 2: Manual Docker Run

In **Unraid Terminal** (Tools → Terminal):

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

---

## Configuration

### Required Fields

| Field | Value | Example |
|-------|-------|---------|
| **Name** | Container name | `yahlp` |
| **Repository** | Docker image | `auskento/yahlp` |
| **Console** | Shell | `/bin/bash` |

### Deployment Settings

#### For Public Access (Internet)

| Setting | Value |
|---------|-------|
| **ACCESS_MODE** | `public` |
| **DOMAIN** | Your domain | `media.example.com` |
| **EMAIL** | For cert notifications | `admin@example.com` |
| **IP** | Leave empty |

#### For Private Access (Internal Network)

| Setting | Value |
|---------|-------|
| **ACCESS_MODE** | `private` |
| **DOMAIN** | Leave empty |
| **EMAIL** | Leave empty |
| **IP** | Your Unraid IP | `192.168.1.100` |

### Dashboard Customization

| Setting | Value | Default |
|---------|-------|---------|
| **DASHBOARD_NAME** | Display name | `YAHLP Dashboard` |
| **DASHBOARD_COLOR** | Hex color | `#00A99D` |
| **DASHBOARD_STYLE** | Layout option | `modern` |
| **DASHBOARD_ORDER** | Service code order | `JEL,PLX,EMB,SON,RAD,LID,WHI,QBI,TRA,SAB,GET,DEL,HYD,PRO,SEE,BAZ,TAU,MNT` |
| **DASHBOARD_LANDING** | Default service | Empty (show grid) |

See [DASHBOARD-CUSTOMIZATION.md](DASHBOARD-CUSTOMIZATION.md) for options.

### Authentication

| Setting | Value | Type |
|---------|-------|------|
| **AUTHTYPE** | `none`, `basic`, `google`, `entra` | none |
| **BASIC_AUTH_CREDENTIALS** | `user:pass` format | (if basic auth) |
| **GOOGLE_CLIENT_ID** | From Google Cloud | (if OAuth) |
| **GOOGLE_CLIENT_SECRET** | From Google Cloud | (if OAuth) |
| **GOOGLE_REDIRECT_URI** | `https://yourdomain.com` | (if OAuth) |

See [AUTHENTICATION.md](AUTHENTICATION.md) for detailed setup.

---

## Storage

### Required Volumes

**In template, configure:**

| Path | Purpose | Unraid Path |
|------|---------|-------------|
| `/etc/yahlp` | Configuration, certificates & templates | `/mnt/user/appdata/yahlp` |

### Folder Structure

All YAHLP data is stored in a single folder:

```
/mnt/user/appdata/yahlp/
├── yahlp.json5              # Configuration file
├── sites.json5              # Custom sites (optional)
├── certs/                   # SSL certificates (auto-created for public mode)
│   └── live/                # Let's Encrypt certificates (auto-renewed)
├── templates/               # Custom layouts (auto-created on first start)
│   └── README.md            # Instructions (auto-copied on first start)
└── logs/                    # Apache access/error logs (auto-created)
    └── sites/               # Per-site logs
```

**Note:** All subfolders are automatically created when needed:
- `certs/` only appears in public mode (ACCESS_MODE=public)
- `templates/` and `README.md` are created on first start
- `logs/` is created automatically for logging

### Create Directories (If Manual)

In Unraid Terminal:

```bash
mkdir -p /mnt/user/appdata/yahlp
chmod 755 /mnt/user/appdata/yahlp
```

This single folder will contain all YAHLP data (configuration, certificates, and templates).

### Backup

YAHLP stores everything in `/mnt/user/appdata/yahlp/`. Back it up regularly:

```bash
# In terminal - create full backup
cp -r /mnt/user/appdata/yahlp /mnt/user/backups/yahlp-backup-$(date +%Y%m%d)

# Or create compressed backup
tar -czf /mnt/user/backups/yahlp-backup-$(date +%Y%m%d).tar.gz \
  /mnt/user/appdata/yahlp
```

This single folder contains:
- Configuration (`yahlp.json5`, `sites.json5`)
- SSL certificates (`certs/`)
- Custom layouts (`templates/`)
- Access logs (`logs/`)

---

## Services

### Enabling Services

In container settings, set for each service you want:

```
SERVICENAME_ENABLED=true
SERVICENAME_URL=http://servicename:port
```

### Example: Complete Setup

```
SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989

RADARR_ENABLED=true
RADARR_URL=http://radarr:7878

JELLYFIN_ENABLED=true
JELLYFIN_URL=http://jellyfin:8096

QBITTORRENT_ENABLED=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=your-api-key

BAZARR_ENABLED=true
BAZARR_URL=http://bazarr:6767
```

### See Also

Complete service reference: [SERVICES.md](SERVICES.md)

---

## Port Mapping

YAHLP requires ports 80 and 443.

### Setting in Unraid

In container settings:

| Container Port | Host Port | Protocol |
|---|---|---|
| 80 | 80 | TCP |
| 443 | 443 | TCP |

**Warning:** Unraid can only map one container per port. If another app uses 80/443, change one of them:
- Unraid WebUI: Usually port 80 → redirect
- YAHLP: Use different ports like 8080 → 80 mapping

Recommended: Use alternative ports in Unraid for other services.

---

## Networking

### Docker Network

YAHLP container needs to reach other service containers.

**Best practice:**
1. Place YAHLP and services on same **custom Docker network**
2. In template, verify network is set to the right bridge
3. Service names resolve within network: `http://sonarr:8989`

**If services on same host:**
- Use Docker DNS names: `http://sonarr:8989`
- Not `http://192.168.x.x:8989` or `http://localhost:8989`

### Network Settings

In container config:

| Setting | Value |
|---------|-------|
| **Network** | Custom bridge (or default) |
| **IP/Hostname** | Use service names |

---

## Updates

### Update YAHLP Image

1. **In Docker tab:**
   - Right-click YAHLP container
   - Click **"Force Update"**
   - Wait for new image to download

2. **Restart container:**
   - Container will restart automatically
   - First run takes 2-3 minutes

### Preserve Configuration

Configuration is saved in volumes:
- `/mnt/user/appdata/yahlp/` - Persists across updates
- Environment variables - Re-enter in template if changed

### Backup Before Update

```bash
cp -r /mnt/user/appdata/yahlp /mnt/user/backups/yahlp-before-update
```

---

## Troubleshooting

### Container Won't Start

**Check logs:**
1. Docker tab → YAHLP container
2. Click **"Logs"** tab
3. Look for error messages

**Common issues:**

**Port in use:**
```
bind: address already in use :80
```
- Another container using port 80
- Change YAHLP port or disable other container

**Volume permission error:**
```
Permission denied: /etc/letsencrypt
```
- Fix: `chmod -R 755 /mnt/user/appdata/yahlp`

### Services Not Connecting

**Check:**
1. Service containers running: Docker tab → verify other containers are "Up"
2. Service URL is correct: `http://servicename:port` (not IP address)
3. Both on same Docker network

**Test:**
1. Go to container → **Console**
2. Run: `curl http://sonarr:8989`
3. If it works, connection is fine

### Certificate Issues

**Certificate not generating (public mode):**
1. Domain must resolve to Unraid IP: `nslookup yourdomain.com`
2. Ports 80/443 must be open to internet
3. Wait 5 minutes on first run
4. Check logs for errors

**Fix:**
1. Verify domain in Unraid: Nslookup it
2. Verify ports open: Use [canyouseeme.org](https://canyouseeme.org)
3. Restart container
4. Wait 5 minutes

### Performance Issues

**Dashboard loads slow:**
1. Disable unused services: `SERVICE_ENABLED=false`
2. Restart container
3. Use simpler layout: `DASHBOARD_STYLE=minimal`

**Services slow to respond:**
1. Check service container isn't overloaded
2. Check Unraid system resources (Tools → System)
3. Restart slow service

---

## Advanced

### Custom Configuration Files

YAHLP generates configuration files. To customize:

1. **SSH to Unraid** (or use terminal)
2. **Edit files:**
   ```bash
   # Main config
   nano /mnt/user/appdata/yahlp/config/yahlp.json5
   
   # Custom sites
   nano /mnt/user/appdata/yahlp/config/sites.json5
   ```
3. **Restart container** for changes to apply

### Mounting Additional Paths

To give YAHLP access to other directories:

1. In container settings
2. Click **"Add another Path, Port, Variable, Label or Device"**
3. Select **"Path"**
4. Set container path and host path
5. Click **"Apply"**

Example: Mount media directory:
```
Container Path: /media
Host Path: /mnt/user/media
Access Mode: ro (read-only)
```

### Logs Location

Apache logs saved in:
```
/mnt/user/appdata/yahlp/logs/
```

Access via SSH or Unraid terminal:
```bash
tail -f /mnt/user/appdata/yahlp/logs/error.log
tail -f /mnt/user/appdata/yahlp/logs/access.log
```

---

## See Also

- [INSTALLATION.md](INSTALLATION.md) - General setup guide
- [CONFIGURATION.md](CONFIGURATION.md) - All settings reference
- [SERVICES.md](SERVICES.md) - Service setup guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
