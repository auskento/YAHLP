# YAHLP - Yet Another HomeLab Portal

![YAHLP Logo](yahlp.png)

A production-ready reverse proxy and dashboard for managing 19 homelab services with automatic HTTPS, flexible authentication, and customizable layouts. YAHLP sits between your browser and your services, providing unified access, health monitoring, and a beautiful interface across any device.

## What YAHLP Does

**Unified Access** — One dashboard for all your homelab services. No more remembering IP addresses and ports.

**Security** — Automatic HTTPS via Let's Encrypt, centralized authentication (Basic Auth, OAuth2 with Entra/Google), and request validation. Credentials stored securely, never transmitted to services unnecessarily.

**Beautiful UI** — 5 responsive layouts (classic, modern, sleek, minimal, mobile) that auto-detect your device and scale perfectly. Switch layouts anytime without server restart.

**Zero Downtime Management** — Real-time service health checks, customizable service ordering, and theme switching without page reloads. Add or remove services without restarting the proxy.

**Flexible Deployment** — Run on private networks (HTTP) or expose to the internet (automatic HTTPS). Scale to any number of services.

## Architecture

YAHLP runs as a single Docker container with:
- **Apache 2.4** reverse proxy (handles routing, SSL/TLS, authentication)
- **Node.js** API server (service discovery, health checks, token caching)
- **Static dashboard** (HTML/CSS/JS, works offline once loaded)

Services communicate directly to YAHLP; YAHLP proxies requests to your backend services on the internal Docker network or local network. See [Architecture](docs/architecture.md) for system design details.

## Deployment Modes

**Private Network** — Run on your internal network with HTTP or self-signed HTTPS. Good for homelab on a single LAN.

**Public (Internet-Facing)** — Register a domain, enable automatic HTTPS via Let's Encrypt, and expose to the internet with OAuth2 or Basic Auth. Production-grade security.

See [Deployment Guide](docs/installation.md) for mode selection and tradeoffs.

## 📦 Supported Services (19 Total)

| Category | Count | Examples |
|----------|-------|----------|
| **Usenet** | 3 | SABnzbd, NZBGet, NZBHydra |
| **Torrents** | 3 | Transmission, qBittorrent, Deluge |
| **Search & Automation** | 6 | Prowlarr, Jackett, Sonarr, Radarr, Lidarr, Whisparr |
| **Infrastructure** | 4 | Seerr, Bazarr, Tautulli, Maintainerr |
| **Media Servers** | 3 | Jellyfin, Emby, Plex |

Each service is optionally enabled/disabled via configuration. Only enabled services appear in the dashboard.

## Authentication Methods

- **No Auth** — Public dashboard (private network only)
- **Basic Auth** — Username/password (simple, requires HTTPS)
- **Entra ID / Azure AD** — OAuth2 via Microsoft (enterprise)
- **Google OAuth** — OAuth2 via Google (personal)

Authentication happens at the proxy level. Once authenticated, services receive requests without re-authentication. See [Authentication Guide](docs/authentication.md).

## Configuration

YAHLP requires a single mounted config folder (`/etc/yahlp`) for everything:
- Configuration files (`yahlp.json5`, `sites.json5`)
- SSL certificates (automatically managed in public mode)
- Custom dashboard templates
- Apache access/error logs

**Docker mount:** `-v ./config:/etc/yahlp` ← Only volume needed

YAHLP supports flexible configuration through two methods:

**JSON5 Config File** — `yahlp.json5` with comments, reusable across deployments  
**Environment Variables** — Set per-deployment, override JSON5 settings, secrets-friendly

Environment variables take precedence, allowing:
- Base config in `yahlp.json5` (reusable template)
- Per-deployment secrets in `.env` (kept private)
- Local overrides on container startup

Example: Define all service URLs in `yahlp.json5`, override `SONARR_API_KEY` via `.env` for security.

See [Configuration Guide](docs/configuration.md) for all options and examples.

## Getting Started

Start with the [Installation Guide](docs/installation.md) for detailed setup instructions for Docker or Unraid.

## 📚 Documentation

### Setup
- [**Installation**](docs/installation.md) — Docker setup for private or public deployments, Unraid-specific guide
- [**Configuration**](docs/configuration.md) — All settings: services, auth, dashboards, SSL
- [**Services**](docs/services.md) — How to connect and configure each of the 19 services
- [**Authentication**](docs/authentication.md) — Auth methods: Basic, OAuth (Entra/Google), setup guides

### Using & Managing
- [**Dashboard Customization**](docs/dashboard-customization.md) — Layouts, themes, service ordering, custom CSS
- [**Troubleshooting**](docs/troubleshooting.md) — Common issues, error messages, solutions
- [**Upgrading**](docs/upgrading.md) — Version updates, breaking changes, rollback procedures
- [**Backup & Restore**](docs/backup-restore.md) — Data persistence, disaster recovery, test procedures
- [**Unraid Deployment**](docs/unraid.md) — Unraid-specific installation and configuration

### Advanced
- [**Architecture**](docs/architecture.md) — System design, component overview, data flow
- [**Security**](docs/security.md) — Best practices, threat model, hardening checklist, incident response
- [**Development**](docs/development.md) — Contributing guide, project structure, adding services

## Why YAHLP?

**Single Proxy** — Instead of exposing each service individually to the internet or maintaining complex DNS/firewall rules, YAHLP proxies all traffic through one secure entry point.

**Time Saver** — No more logging into 5 different services to manage your homelab. Dashboard loads them all at once.

**Beginner Friendly** — Start with private network deployment (simple, no SSL), upgrade to internet-facing later (automatic HTTPS, OAuth).

**Flexible** — 5 layouts to choose from, enable/disable services without restart, customize service order, auto-auth to some services.

**Safe** — All credentials stored locally, never shared unnecessarily. Optional OAuth2 means no password storage at all.

## How It Works

1. **Request comes in** → Browser connects to YAHLP proxy
2. **Authentication** → Proxy validates you're authorized (Basic Auth, OAuth, or none)
3. **Proxy routes** → Request forwarded to appropriate backend service
4. **Response returned** → Service response relayed back to browser
5. **Dashboard monitors** → Health checks run in background, status shown in UI

All services run on internal Docker network or local LAN. Direct access is optional (can be disabled).

## System Requirements

**Minimum:**
- 512 MB RAM (lighter for small homelabs)
- 100 MB disk (plus space for logs and certificates)
- Docker & Docker Compose installed

**Recommended:**
- 1+ GB RAM (for health checks on 10+ services)
- 500 MB disk
- Internal network (LAN only) OR registered domain with open ports 80/443

**Scaling:**
- Supports 10+ services without issues
- Adding more services increases RAM usage slightly
- Each layout CSS file is ~20 KB

See [Installation Guide](docs/installation.md) for detailed requirements by deployment mode.

## Common Questions

**How do I add a new service?**  
Enable it in configuration (env or JSON5), provide the service URL and API key. YAHLP auto-discovers and displays it on restart. See [Services Guide](docs/services.md).

**Can I run it on the internet?**  
Yes. Public mode handles HTTPS via Let's Encrypt and OAuth2 authentication. See [Installation](docs/installation.md) for public deployment.

**What if a service goes down?**  
Dashboard shows real-time health status (🟢 online / 🔴 offline). Unreachable services display as offline but don't break the dashboard.

**Can I customize the dashboard?**  
Yes. Choose between 5 built-in layouts, customize service ordering, create custom CSS. See [Dashboard Customization](docs/dashboard-customization.md).

**Is my data backed up?**  
YAHLP stores certificates, configuration, and logs in Docker volumes. You must back these up yourself. See [Backup & Restore](docs/backup-restore.md).

**What authentication methods are supported?**  
Basic Auth (username/password), Entra ID (Azure AD), Google OAuth, or no auth (private networks only). See [Authentication Guide](docs/authentication.md).

## Next Steps

1. **New to YAHLP?** Start with [Installation Guide](docs/installation.md)
2. **Already installed?** See [Configuration](docs/configuration.md) to enable services
3. **Want to customize?** Check [Dashboard Customization](docs/dashboard-customization.md)
4. **Having issues?** Browse [Troubleshooting Guide](docs/troubleshooting.md)
5. **Interested in contributing?** See [Development Guide](docs/development.md)

## Support & Feedback

- **Report Issues:** [GitHub Issues](https://github.com/auskento/YAHLP/issues)
- **Security Issues:** Please email instead of using GitHub Issues
- **Feature Requests:** GitHub Issues with `[FEATURE]` tag
- **Documentation Questions:** Check the [Docs](docs/) folder first

## License

MIT License - See LICENSE file for details

---

Made for homelabbers. Made simple. Made right.
