# Apache Reverse Proxy for Media Servers

A modular, production-ready Docker/Apache reverse proxy system for self-hosted media servers with automatic SSL (Let's Encrypt), dynamic service configuration, and office authentication.

**15 services included:** Sonarr, Radarr, Whisparr, Lidarr, Readarr, Prowlarr, Overseerr, Jellyfin, Emby, Plex, Tautulli, Transmission, qBittorrent, SABnzbd, and Deluge.

![License](https://img.shields.io/badge/license-MIT-green)
![Services](https://img.shields.io/badge/services-15-blue)
![Docker](https://img.shields.io/badge/docker-ready-success)

---

## ✨ Features

✅ **Automatic HTTPS** — Let's Encrypt with auto-renewal  
✅ **15 Pre-configured Services** — Enable/disable via environment variables  
✅ **Dynamic Menu System** — Auto-generated HTML dashboard  
✅ **Custom Icons** — Auto-download and resize from URLs  
✅ **Office 365 Authentication** — Azure AD/OpenID Connect built-in  
✅ **Modular Architecture** — Add services without touching core configs  
✅ **WebSocket Support** — Works with real-time services  
✅ **Unraid Native** — Docker template included  

---

## 🚀 Quick Start

### 1. Clone/Download

```bash
git clone https://github.com/YOUR_USERNAME/apache-reverse-proxy.git
cd apache-reverse-proxy
```

### 2. Configure

```bash
cp .env.example .env
# Edit .env with your domain and enable services
nano .env
```

### 3. Deploy

```bash
docker-compose up -d
```

### 4. Access

```
https://yourdomain.com/
```

---

## 📋 Services Included

| Category | Services |
|----------|----------|
| **Automation** | Sonarr, Radarr, Whisparr, Lidarr, Readarr, Prowlarr |
| **Management** | Overseerr |
| **Streaming** | Jellyfin, Emby, Plex |
| **Monitoring** | Tautulli |
| **Downloads** | Transmission, qBittorrent, SABnzbd, Deluge |

---

## 📁 Project Structure

```
.
├── Dockerfile              # Container image
├── docker-compose.yml      # Full stack definition
├── .env.example            # Environment template
├── docker-entrypoint.sh    # Startup orchestration
│
├── scripts/
│   ├── generate-config.sh      # Apache config generation
│   ├── generate-html-menu.sh   # Dynamic menu creation
│   ├── download-icons.sh       # Icon auto-download
│
├── apache-conf/
│   ├── reverse-proxy.conf.template    # Main Apache template
│   ├── ssl-config.conf                # TLS settings
│   ├── oauth2-office365.conf          # Azure AD config
│   └── services/
│       ├── sonarr.conf
│       ├── radarr.conf
│       ├── sabnzbd.conf
│       └── ... (13 total)
│
├── html/
│   ├── index.html.template    # Dashboard template
│   ├── error-pages/           # Custom error pages
│   └── icons/                 # Service icons (auto-populated)
│
├── docs/
│   ├── QUICKSTART.md          # Get started in 5 minutes
│   ├── SERVICES.md            # Service descriptions
│   ├── OFFICE365-AUTH.md      # Azure AD setup
│   ├── TROUBLESHOOTING.md     # Problem solving
│   └── ...
│
├── unraid/
│   └── apache-reverse-proxy.xml   # Unraid template
│
├── LICENSE                    # MIT License
├── .gitignore
└── README.md                  # Full documentation
```

---

## 🔧 Configuration

### Enable Services

Edit `.env`:

```env
DOMAIN=media.example.com
EMAIL=admin@example.com

# Enable services you want
ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_JELLYFIN=true
ENABLE_QBITTORRENT=true
ENABLE_SABNZBD=true
```

### Add Custom Icons

Place PNG files in `html/icons/`:

```bash
cp my-sonarr-icon.png html/icons/sonarr.png
docker-compose restart apache-reverse-proxy
```

### Enable Office 365 Auth

```env
ENABLE_AUTH_OFFICE365=true
OAUTH2_CLIENT_ID=your-app-id
OAUTH2_CLIENT_SECRET=your-secret
OAUTH2_REDIRECT_URI=https://yourdomain.com/oauth2callback
OAUTH2_ALLOWED_DOMAINS=example.com
```

---

## 📖 Documentation

- **[Quick Start Guide](./docs/QUICKSTART.md)** — Get running in 5 minutes
- **[Full Documentation](./docs/README.md)** — Complete reference
- **[Service Configuration](./docs/SERVICES.md)** — All 15 services explained
- **[Office 365 Auth Setup](./docs/OFFICE365-AUTH.md)** — Azure AD integration
- **[Troubleshooting](./docs/TROUBLESHOOTING.md)** — Common issues & solutions
- **[Unraid Installation](./docs/UNRAID-SETUP.md)** — Native Unraid support
- **[Custom Icons](./docs/ICONS.md)** — Personalize your dashboard

---

## 🔐 Authentication

Currently supported:

- ✅ Office 365 / Azure AD (OpenID Connect)

Coming soon:

- Authelia (self-hosted SSO)
- Basic Auth (htpasswd)
- LDAP / Active Directory
- Generic OAuth2 (Google, GitHub)
- Keycloak

---

## 💻 System Requirements

- Docker & Docker Compose
- 2GB+ RAM
- 20GB+ storage (for certificates, logs, icons)
- Domain name with DNS control
- Port 80/443 available

---

## 🛠️ How It Works

1. **Container starts** → Runs `docker-entrypoint.sh`
2. **Config generation** → Reads environment variables, generates Apache configs
3. **Icon download** → Fetches and resizes icons from URLs
4. **Menu creation** → Generates dynamic HTML dashboard
5. **SSL setup** → Acquires Let's Encrypt certificate
6. **Apache launch** → Starts reverse proxy
7. **Cron setup** → Schedules daily certificate renewal

---

## 📝 Examples

### Minimal Setup (Just TV & Movies)

```yaml
version: '3.8'
services:
  apache-reverse-proxy:
    image: apache-reverse-proxy:latest
    container_name: apache-reverse-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      DOMAIN: media.example.com
      EMAIL: admin@example.com
      ENABLE_SONARR: "true"
      ENABLE_RADARR: "true"
      ENABLE_QBITTORRENT: "true"
```

### Complete Media Server

```yaml
environment:
  # Automation
  ENABLE_SONARR: "true"
  ENABLE_RADARR: "true"
  ENABLE_PROWLARR: "true"
  ENABLE_OVERSEERR: "true"
  
  # Streaming
  ENABLE_JELLYFIN: "true"
  
  # Downloads
  ENABLE_QBITTORRENT: "true"
  ENABLE_SABNZBD: "true"
  
  # Monitoring
  ENABLE_TAUTULLI: "true"
```

---

## 🐳 Docker Compose

Full example with all services:

```bash
docker-compose up -d
docker-compose logs -f apache-reverse-proxy
docker-compose ps
```

---

## 🔄 Updating

```bash
# Pull latest code
git pull

# Rebuild image
docker-compose build

# Restart container
docker-compose up -d
```

---

## 🐛 Troubleshooting

**502 Bad Gateway?**
```bash
docker-compose logs apache-reverse-proxy | grep "Connection refused"
```

**SSL Certificate issues?**
```bash
docker-compose exec apache-reverse-proxy certbot renew --dry-run
```

**Services not showing in menu?**
```bash
docker-compose restart apache-reverse-proxy
docker-compose logs apache-reverse-proxy | grep "Icon Status"
```

See [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for more.

---

## 📊 Project Statistics

- **15** services pre-configured
- **13** Apache service configs
- **6** automation (*arr) services
- **4** download clients
- **3** streaming platforms
- **100% modular** — no monolithic configs

---

## 🤝 Contributing

Contributions welcome! Areas for improvement:

- [ ] Authelia integration
- [ ] LDAP authentication
- [ ] Additional services (Sickgear, Mylar, etc.)
- [ ] Web-based configuration UI
- [ ] Service health checks
- [ ] Rate limiting
- [ ] Request logging dashboard

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](./LICENSE) file.

---

## 🙋 Support

- 📖 Check [docs/](./docs/) for comprehensive guides
- 🐛 Open an issue for bugs
- 💡 Open a discussion for questions
- 📝 See [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for common problems

---

## 🎯 Roadmap

- [x] Core reverse proxy functionality
- [x] Let's Encrypt SSL
- [x] 15 services pre-configured
- [x] Office 365 authentication
- [x] Dynamic icon system
- [ ] Authelia support
- [ ] LDAP integration
- [ ] Web UI for configuration
- [ ] Service health monitoring
- [ ] Rate limiting per service

---

## ⭐ Show Your Support

If this project helped you, please give it a star! ⭐

---

**Made with ❤️ for the self-hosted community**

[⬆ back to top](#apache-reverse-proxy-for-media-servers)
