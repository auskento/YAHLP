# YAHLP Release Notes

## Version 2.0 - Production Release

### Overview

YAHLP 2.0 represents a major milestone: a production-ready reverse proxy and dashboard for homelab environments. This release includes comprehensive configuration system redesign, extensibility features, complete documentation, and enterprise-grade security.

---

## Major Features

### 1. Unified Configuration System
- **Three-Tier Precedence**: Environment variables override JSON5 file override defaults
- **Auto-Generated yahlp.json5**: Automatic configuration file creation on first run
- **Flexible Setup**: Configure via environment variables, JSON5 file, or both
- **Auto-Generated Redirect URIs**: OAuth redirect URIs automatically derived from domain configuration
- **No Manual Redirect Setup**: Single DOMAIN setting generates all OAuth redirect URIs

### 2. 19 Supported Services
Complete support for popular homelab applications:
- **Usenet**: SABnzbd, NZBGet, NZBHydra
- **Torrents**: Transmission, qBittorrent, Deluge
- **Search & Automation**: Prowlarr, Jackett, Sonarr, Radarr, Lidarr, Whisparr
- **Utilities**: Seerr, Bazarr, Tautulli, Maintainerr
- **Media Servers**: Jellyfin, Emby, Plex

### 3. Custom Services via VirtualHost Files
**NEW**: Add any custom service (Keeper Automator, Overseerr, proprietary tools) without modifying core code:
- Create VirtualHost configuration files with "vhost" in filename
- Automatic SSL certificate generation and renewal via Let's Encrypt
- Flexible authentication per-service (bypass OIDC, basic auth, OAuth)
- IP-based access control
- Security headers configuration
- Complete documentation in `docs/custom-services.md`

### 4. Flexible Authentication
Choose your authentication method:
- **None**: For trusted private networks
- **Basic Auth**: Simple username/password (requires HTTPS)
- **Google OAuth 2.0**: Personal/small team deployments
- **Microsoft Entra ID**: Enterprise Azure AD integration
- **Per-Service**: Different auth methods for different services

### 5. Beautiful Dashboard Layouts
5 responsive layouts to choose from:
- **Classic**: Horizontal top navigation
- **Modern**: Vertical sidebar, API-style design
- **Sleek**: Compact with gradient accents
- **Minimal**: Ultra-minimal single column
- **Mobile**: Auto-detected for small screens
- **Theme Switching**: Change between layouts without restart
- **Customizable**: Custom templates and CSS

### 6. Deployment Flexibility
- **Private Network**: HTTP on internal LAN
- **Public/Internet-Facing**: Automatic HTTPS via Let's Encrypt
- **Docker & Unraid**: Native container support
- **Single Volume**: `/etc/yahlp` consolidates all configuration, certificates, and logs

### 7. Real-Time Service Monitoring
- Health checks for all proxied services
- Status indicators on dashboard
- Service availability monitoring
- Real-time queue/status information for supported services

### 8. Icon System
- Custom service icons via `/etc/yahlp/service_icons` folder
- Torrent/usenet site favicons with automatic fetching
- Built-in icons for all 19 services
- SVG and PNG format support

### 9. Security Features
- Automatic HTTPS via Let's Encrypt with certificate renewal
- OAuth 2.0 support (Google, Entra ID)
- Centralized authentication at reverse proxy level
- Request validation and filtering
- Sensitive file protection (blocks .env, .git, .json5 from web access)
- Modern SSL/TLS configuration
- Support for non-root container execution (PUID/PGID)

### 10. Configuration Options
- Service enable/disable without restart
- Service ordering and grouping
- Custom dashboard name and colors
- Dashboard icon configuration
- Service landing pages
- Torrent/usenet site quick links
- Custom SSL cipher suites
- Apache log level configuration

---

## Configuration System

### Environment Variables (Sample)
```bash
# Deployment
ACCESS_MODE=public
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com

# Dashboard
DASHBOARD_NAME="My HomeLab"
DASHBOARD_COLOR=#0ea5e9
DASHBOARD_WINDOWS=popout

# Authentication
AUTHTYPE=google
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-secret

# Services
SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989
SONARR_API_KEY=your-api-key
```

### JSON5 Configuration (yahlp.json5)
Auto-generated on first run with complete template including:
- Service configurations
- API keys and passwords (kept separate from environment)
- OAuth redirect URIs
- Custom dashboard settings
- Icon URLs
- Landing page configuration

---

## Deployment Modes

### Private Network (HTTP)
- Access via internal IP: `http://192.168.1.100`
- No SSL certificates needed
- Basic Auth or no authentication
- Best for trusted home networks

### Public/Internet-Facing (HTTPS)
- Register a domain pointing to your server
- Automatic SSL via Let's Encrypt
- OAuth 2.0 authentication (Google or Entra)
- Production-grade security
- Certificate automatic renewal

---

## Documentation

Comprehensive documentation included:
- **Installation Guide** — Docker and Unraid setup
- **Configuration Reference** — All settings and options
- **Services Guide** — Setup for each of 19 services
- **Authentication** — OAuth and basic auth setup
- **Custom Services** — Add services via VirtualHost files
- **Dashboard Customization** — Layouts, themes, service ordering
- **Security** — Best practices, threat model, hardening
- **Troubleshooting** — Common issues and solutions
- **Architecture** — System design and component overview
- **Backup & Restore** — Data persistence and recovery
- **Upgrading** — Version updates and migration
- **Development** — Contributing guide and project structure

---

## System Requirements

### Minimum
- 512 MB RAM
- 100 MB disk space
- Docker & Docker Compose

### Recommended
- 1+ GB RAM (for 10+ services)
- 500 MB disk space
- Internal network (LAN) or registered domain with open ports 80/443

---

## Breaking Changes from Previous Versions

None — this is the first stable 2.0 release. Beta users should review `docs/upgrading.md` for any migration steps.

---

## Migration from Beta Releases

If upgrading from b.2.0.x releases:
1. Update container image
2. Existing configuration persists in `/etc/yahlp`
3. Review new custom-services feature in docs
4. No manual configuration changes required

---

## Future Roadmap

Potential future enhancements (not included in 2.0):
- In-dashboard service configuration editor
- Advanced authentication (LDAP, SAML)
- Service-to-service authentication tunneling
- Web UI for vhost management
- Multi-user dashboard customization
- Custom service health check patterns

---

## Support & Contributing

- **GitHub Issues**: Report bugs at https://github.com/auskento/YAHLP/issues
- **Discussions**: Community help at https://github.com/auskento/YAHLP/discussions
- **Contributing**: See `docs/development.md` for contribution guidelines

---

## License

MIT License - See LICENSE file for details

---

## Changelog Highlights (Beta → Stable)

### New in 2.0
- Custom services via VirtualHost files (NEW!)
- Comprehensive documentation suite
- Website with feature showcase
- Icon configuration guide
- Real-world examples and tutorials

### Fixes & Improvements
- Verbose logging cleanup for cleaner startup
- Apache default site conflict resolution
- OIDC cookie domain handling for custom vhosts
- Staging certificate cleanup when switching to production
- Improved certificate bootstrap for custom domains

### Configuration Enhancements
- DASHBOARD_WINDOWS setting (popout vs newtab)
- Better service icon handling
- Improved error logging and diagnostics

---

**Release Date**: 2026-07-16
**Version**: 2.0
**License**: MIT
