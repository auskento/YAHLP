# YAHLP v1.0.0 - Initial Release

**Yet Another HomeLab Portal** - A comprehensive reverse proxy and unified media server dashboard for homelab environments.

## 🎉 What's New

YAHLP v1.0.0 is the initial stable release, providing a complete solution for managing and accessing multiple homelab services through a single, elegant interface.

## ✨ Key Features

### Dashboard & Interface
- **4 Dashboard Styles**: Classic, Modern, Sleek, Minimal (fully responsive)
- **Dark/Light Theme Toggle**: Persistent user preferences with theme switching
- **Mobile Optimization**: Dedicated mobile layout for smaller screens
- **Customizable Landing Page**: Set a default service to display on dashboard load
- **Service Icons**: Auto-generated or custom service icons with favicon caching

### Supported Services (17 Total)
- **Content Management**: Sonarr (TV), Radarr (Movies), Whisparr (Adult), Lidarr (Music)
- **Search & Discovery**: Prowlarr (Indexers), Seerr (Requests), Bazarr (Subtitles)
- **Usenet Downloads**: SABnzbd, NZBGet, NZBHydra
- **Torrent Downloads**: Transmission, qBittorrent, Deluge
- **Media Streaming**: Jellyfin, Emby, Plex, Tautulli (Analytics)

### Torrent & Usenet Sites
- **16 Pre-configured Sites**: Quick links to popular torrent and usenet indexers
- **Torrent Sites** (9): TPB, FileList, HDBits, IP Torrents, 1337x, YTS, LimeTorrents, Nyaa, PassThePopcorn
- **Usenet Sites** (7): DOGnzb, DrunkenSlug, nzb.life, NZBFinder, NZBgeek, nzbplanet, Tabula Rasa
- **Favicon Caching**: Pre-cached site icons for instant loading
- **User-Editable Config**: Modify sites.json in the persistent volume

### Authentication
- **Multiple Methods**: None, HTTP Basic Auth, Google OAuth2, Microsoft Entra ID (Azure AD)
- **Flexible Deployment**: Choose auth based on your security needs
- **Enterprise Support**: Entra ID support for organization-managed deployments

### Deployment Modes
- **Private Mode**: HTTP-only for internal networks (no SSL setup needed)
- **Public Mode**: HTTPS via Let's Encrypt with automatic certificate management
- **Subdomain Routing**: Route services to custom subdomains (e.g., `emby.yourdomain.com`)

### Advanced Features
- **Minimal Defaults**: All services disabled by default—enable only what you need
- **Environment Variables**: 60+ configuration options for complete customization
- **YAHLP Engine**: High-performance reverse proxy routing and load balancing
- **Docker Native**: Full Docker support with proper volume mounting

## 🚀 Getting Started

### Quick Start (Private Mode)
1. In Unraid, go to **Docker** → **Add Container**
2. Select template: **yahlp-private-basic.xml**
3. Configure:
   - Container IP address
   - Basic auth credentials
   - Enable services you want
   - Set backend service URLs
4. Click **Apply** and wait for container startup

### For Public Access
1. Use **yahlp-public-basic.xml**, **yahlp-public-google.xml**, or **yahlp-public-entra.xml**
2. Configure domain, email, and authentication method
3. Set up port forwarding (80, 443)
4. Enable services and configure backend URLs

### Full Documentation
- **Main Repository**: https://github.com/auskento/yahlp
- **Templates Repository**: https://github.com/auskento/yahlp-templates
- **Unraid Setup Guide**: See UNRAID-SETUP.md in main repository

## 📦 Available Templates

| Template | Mode | Auth | Use Case |
|----------|------|------|----------|
| yahlp-private-basic.xml | Private (HTTP) | Basic | Internal networks, testing |
| yahlp-public-basic.xml | Public (HTTPS) | Basic | External access with passwords |
| yahlp-public-google.xml | Public (HTTPS) | Google OAuth | Google account protection |
| yahlp-public-entra.xml | Public (HTTPS) | Entra ID | Enterprise/Microsoft 365 |
| yahlp.xml | Flexible | All Options | Advanced/custom configurations |

## 🐳 Docker Image

**Registry**: GitHub Container Registry (GHCR)
**Image**: `ghcr.io/auskento/yahlp:latest`
**Size**: ~500MB (optimized Alpine-based image)

## 🔧 Configuration Highlights

### Services
- Enable/disable any of 17 services independently
- Custom backend URLs for each service
- Optional service-specific domains for public deployments
- Custom service icons or auto-generated defaults

### Sites
- Pre-configured with 16 popular torrent/usenet sites
- User-editable `sites.json` for customization
- Favicon caching for consistent look
- Easy enable/disable via `SITES_ENABLED` variable

### Dashboard
- Customizable title and icon
- Theme selection (dark/light)
- Style selection (classic/modern/sleek/minimal)
- Category display order configuration
- Optional landing page default

### Authentication
- No auth (for internal/trusted networks)
- HTTP Basic Auth (simple password protection)
- Google OAuth2 (requires Google Cloud Console setup)
- Entra ID OAuth2 (requires Azure AD application)

## ⚙️ System Requirements

### Minimum
- 512MB RAM
- 100MB disk space (excluding service data)
- Docker-capable system (Unraid recommended)

### Recommended
- 1GB+ RAM (for reverse proxy with 5+ services)
- SSD storage
- Multi-core processor

## 🔒 Security Notes

### Private Mode
- HTTP only—suitable for trusted internal networks only
- Basic Auth credentials transmitted in Base64 encoding
- Use VPN for external access instead of exposing directly

### Public Mode with Basic Auth
- HTTPS encryption via Let's Encrypt
- Basic Auth is less secure than OAuth—consider OAuth2 methods
- Keep domain certificates updated

### Public Mode with OAuth
- OAuth2 provides better security than passwords
- Google OAuth requires Google Cloud Console setup
- Entra ID ideal for organizations with Microsoft 365

## 📝 Known Limitations

- **Health Checks Removed**: Browser CORS policies prevent health checks to private IPs; health status must be monitored separately
- **Single Domain**: Primary access via single domain (subdomains optional for specific services)
- **No Load Balancing**: Single reverse proxy instance (can be scaled with additional containers)

## 🐛 Bug Reports & Feature Requests

Please report issues and request features at:
- **GitHub Issues**: https://github.com/auskento/yahlp/issues

## 📄 License

YAHLP is released under the MIT License. See LICENSE file for details.

## 🙏 Credits

YAHLP combines Apache reverse proxy technology with a modern web dashboard to provide a unified interface for homelab management. Thanks to the open-source community for the underlying technologies.

---

## Installation Links

- **Unraid Community Apps**: Coming soon
- **Docker Hub**: `auskento/yahlp` (via yahlp-templates)
- **GHCR**: `ghcr.io/auskento/yahlp:latest`
- **GitHub**: https://github.com/auskento/yahlp

---

**Happy Homelabbing! 🏠**
