# YAHLP - Yet Another HomeLab Portal

A production-ready reverse proxy and dashboard for managing 18 homelab services with automatic HTTPS, flexible authentication, and customizable layouts.

## ✨ Key Features

- **🔒 HTTPS by Default** - Automatic certificate generation and renewal via Let's Encrypt
- **🔐 Flexible Authentication** - Basic auth, Entra ID, Google OAuth, or public access
- **🎨 Beautiful Dashboards** - 5 responsive layouts (classic, modern, sleek, minimal, mobile)
- **⚡ Service Health Monitoring** - Real-time status checks for all proxied services
- **🎛️ Customizable** - Service ordering, custom dashboards, multiple layout options
- **📱 Mobile Friendly** - Auto-switches to mobile layout on small screens
- **🔌 18 Services Supported** - Content, search, usenet, torrents, and media servers
- **🌐 Built-in Sites** - Quick links to torrent and usenet tracking sites
- **⚙️ Zero-Config** - Smart defaults, minimal setup required

## 📦 Supported Services (18 Total)

| Category | Services |
|----------|----------|
| **Content** | Sonarr (SON), Radarr (RAD), Lidarr (LID), Whisparr (WHI) |
| **Search** | Seerr (SEE), Prowlarr (PRO), Bazarr (BAZ) |
| **Usenet** | SABnzbd (SAB), NZBGet (GET), NZBHydra (HYD) |
| **Torrents** | Transmission (TRA), qBittorrent (QBI), Deluge (DEL) |
| **Media** | Jellyfin (JEL), Emby (EMB), Plex (PLX), Tautulli (TAU), Maintainerr (MNT) |

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- For public access: registered domain + ports 80/443 open
- For private access: internal IP address

### 1. Clone Repository
```bash
git clone https://github.com/auskento/YAHLP.git
cd YAHLP
```

### 2. Configure Environment
```bash
# Copy example configuration
cp .env.example .env

# Edit with your settings
nano .env
```

### 3. Deploy
```bash
docker-compose build
docker-compose up -d
```

### 4. Access Dashboard
- **Public:** `https://yourdomain.com`
- **Private:** `https://192.168.x.x` (your internal IP)

## 📚 Documentation Index

| Document | Purpose |
|----------|---------|
| [INSTALLATION.md](INSTALLATION.md) | Detailed setup guide for Docker & Unraid |
| [CONFIGURATION.md](CONFIGURATION.md) | All environment variables explained |
| [SERVICES.md](SERVICES.md) | Setting up each of the 18 services |
| [AUTHENTICATION.md](AUTHENTICATION.md) | Auth method configuration (basic, OAuth, etc) |
| [DASHBOARD-CUSTOMIZATION.md](DASHBOARD-CUSTOMIZATION.md) | Layouts, themes, service ordering |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions |
| [UNRAID.md](UNRAID.md) | Unraid-specific deployment guide |

## 🔧 Common Setup Examples

### Minimal Media Setup
```bash
ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989

ENABLE_RADARR=true
RADARR_URL=http://radarr:7878

ENABLE_JELLYFIN=true
JELLYFIN_URL=http://jellyfin:8096

ENABLE_QBITTORRENT=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=your-api-key
```

### With Basic Authentication
```bash
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=user:password
# Additional services...
```

### Single Layout (Locked)
```bash
DASHBOARD_STYLE=modern:only
# This builds only modern layout and hides the layout switcher
```

### Multiple Layout Options
```bash
DASHBOARD_STYLE=modern,sleek
# Shows only modern and sleek in the slider, modern is default
```

## 🎨 Dashboard Layouts

- **Classic** - Sidebar with service menu on left
- **Modern** - API-inspired with sidebar + right panel
- **Sleek** - Compact gradient design
- **Minimal** - Single-column ultra-simple
- **Mobile** - Auto-loaded on small screens

See [DASHBOARD-CUSTOMIZATION.md](DASHBOARD-CUSTOMIZATION.md) for details.

## 🐳 Docker Compose

```yaml
version: '3'
services:
  yahlp:
    build: .
    ports:
      - "80:80"
      - "443:443"
    environment:
      DOMAIN: example.com
      EMAIL: admin@example.com
      ACCESS_MODE: public
      DASHBOARD_STYLE: modern
      ENABLE_SONARR: "true"
      SONARR_URL: http://sonarr:8989
      # ... more services
    volumes:
      - ./appdata:/etc/letsencrypt
      - ./config:/etc/yahlp
    networks:
      - homelab

networks:
  homelab:
    external: true  # or create new: external: false
```

## 🔒 Deployment Modes

### Public Mode
- Domain-based access
- Automatic HTTPS via Let's Encrypt
- Requires ports 80/443 open
- Supports OAuth (Entra ID, Google)

### Private Mode
- IP-based access (internal network only)
- HTTP by default
- No Let's Encrypt setup
- Basic auth recommended

## 🛠️ Ports

| Port | Purpose |
|------|---------|
| 80 | HTTP (auto-redirects to HTTPS in public mode) |
| 443 | HTTPS |

## 📝 Configuration Files

Generated at runtime:
- `/etc/letsencrypt/` - SSL certificates
- `/etc/yahlp/yahlp.json5` - Main configuration
- `/etc/yahlp/sites.json5` - Custom sites
- `/var/www/html/*.html` - Dashboard files
- `/etc/apache2/sites-available/reverse-proxy.conf` - Reverse proxy config

## 🚨 Troubleshooting

**Service shows 502 Bad Gateway?**
1. Check service is running: `docker-compose ps sonarr`
2. Verify URL in .env is correct
3. Check logs: `docker-compose logs yahlp`

**Certificate issues?**
1. Ensure domain resolves to your IP
2. Check ports 80/443 are open
3. Verify EMAIL is valid

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more solutions.

## 📖 Full Documentation

Start with [INSTALLATION.md](INSTALLATION.md) for detailed setup, then refer to specific guides as needed.

## 🐛 Support

- GitHub Issues: [github.com/auskento/YAHLP/issues](https://github.com/auskento/YAHLP/issues)
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) first

## 📄 License

MIT License - See LICENSE file

---

**Ready to get started?** → [INSTALLATION.md](INSTALLATION.md)
