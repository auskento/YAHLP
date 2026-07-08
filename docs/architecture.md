# Architecture

## System Overview

YAHLP is a containerized reverse proxy and dashboard system built on Apache 2.4 with Node.js API proxy. It provides unified access to homelab services with flexible authentication and customizable UI layouts.

```
┌─────────────────────────────────────────────────────────────┐
│                   Client (Browser)                          │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  Docker Container (YAHLP)                   │
├─────────────────────────────────────────────────────────────┤
│                    Apache 2.4 (Port 80/443)                 │
│  ┌─────────────────────────────────────────────────────────┐
│  │ • SSL/TLS termination (Let's Encrypt)                  │
│  │ • OAuth2 authentication (Entra/Google)                 │
│  │ • Basic auth support                                   │
│  │ • Request routing and rate limiting                    │
│  └─────────────────────────────────────────────────────────┘
│                           │
│       ┌───────────────────┼───────────────────┐
│       ▼                   ▼                   ▼
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐
│  │   Static    │  │ HTML/CSS/JS  │  │ API Proxy    │
│  │   Content   │  │  (Dashboard) │  │ (Node.js)    │
│  │   Files    │  │              │  │ (Port 3000)  │
│  └─────────────┘  └──────────────┘  └──────────────┘
└─────────────────────────────────────────────────────────────┘
                           │
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
      ┌──────────┐  ┌──────────┐  ┌──────────────┐
      │ Sonarr   │  │ Jellyfin │  │ qBittorrent  │
      │ Radarr   │  │ Plex     │  │ Transmission │
      │ Lidarr   │  │ Emby     │  │ Deluge       │
      │ Whisparr │  │ Seerr    │  │ SABnzbd      │
      │ Prowlarr │  │ Tautulli │  │ NZBGet       │
      │ Jackett  │  └──────────┘  │ NZBHydra     │
      │ Bazarr   │                └──────────────┘
      └──────────┘
      (Downstream Services)
```

## Key Components

### 1. Apache Reverse Proxy
- **Ports:** 80 (HTTP), 443 (HTTPS)
- **SSL/TLS:** Automatic Let's Encrypt certificate generation and renewal
- **Authentication:** 
  - Basic HTTP Auth
  - OAuth2 (Entra ID / Azure AD)
  - OAuth2 (Google)
  - No authentication (public)
- **Routing:** Forwards requests to appropriate services based on URI path

### 2. Node.js API Proxy (Port 3000)
- Service status checking
- API request proxying with authentication headers
- Configuration loading (JSON5 format)
- Token caching for Jellyfin auto-auth

### 3. Dashboard UI (Static Files)
- **Layouts:**
  - Classic: Horizontal top bar
  - Modern: Left sidebar + main content
  - Sleek: Compact left sidebar
  - Minimal: Single column
  - Mobile: Responsive mobile layout
- **Technologies:** HTML5, CSS3, Vanilla JavaScript
- **Features:**
  - Real-time service health monitoring
  - Responsive design
  - Theme switcher (light/dark)
  - Custom site/link management

### 4. Configuration System
- **Primary:** `yahlp.json5` (JSON5 format with comments)
- **Fallback:** Environment variables
- **Scope:** Dashboard, services, authentication, access mode

## Data Flow

### Dashboard Load
1. Client requests `https://domain.com/`
2. Apache checks authentication
3. If authenticated, serves `/html/index.html`
4. Browser loads CSS layout (classic/modern/sleek/minimal/mobile)
5. JavaScript initializes dashboard and fetches service list from Node API
6. API responds with service configuration and availability

### Service Access
1. User clicks service in dashboard
2. JavaScript opens service URL in iframe or new window
3. Apache intercepts request, validates auth
4. Proxies to backend service URL
5. Service responds, Apache relays back to client

### API Proxy (Port 3000)
1. Node.js loads configuration with priority:
   - Base: `yahlp.json5` (shared config)
   - Override: Environment variables (per-deployment)
   - Final: Merged config used by YAHLP
2. Provides `/api/services` endpoint for dashboard
3. Handles health checks for all services
4. Manages Jellyfin token caching

**Configuration Priority:**
```
yahlp.json5 (shared in git)
        ↓
Environment variables (local overrides)
        ↓
Final Configuration (what Node.js uses)
```

This allows shared base configs with per-deployment secrets.

## Authentication Modes

### Public (No Auth)
- Direct access to dashboard
- Optional behind WAF/firewall

### Private (Basic Auth)
- HTTP Basic Authentication
- Credentials stored in Apache `.htpasswd`
- Username and password required

### OAuth (Entra/Azure AD)
- Redirect to Microsoft login
- OAuth2 flow with Apache module
- User email/domain validation

### OAuth (Google)
- Redirect to Google login
- OAuth2 flow
- User email validation

## Service Integration

Each service has a configuration entry with:
- **URL:** Backend service address (Docker network or IP)
- **API Key:** For API access (stored securely)
- **Auth Type:** How the service authenticates
  - `header`: API key in `X-Api-Key` header
  - `query`: API key in query parameter
  - `basic`: Basic auth credentials
  - Custom auth per service

## Deployment Modes

### Public Deployment
- Domain-based access
- Let's Encrypt auto-certificate
- Ports 80/443 must be open
- DNS must resolve to container IP

### Private Deployment
- IP-based access (internal network)
- HTTP (no SSL) or self-signed HTTPS
- Only accessible from internal network
- No Let's Encrypt setup needed

## Security Architecture

1. **SSL/TLS Termination:** Apache handles all HTTPS
2. **Authentication:** Centralized at Apache level
3. **Authorization:** Per-service in backend
4. **API Security:** Authentication required for `/api/*` endpoints
5. **CORS:** Configured per deployment mode
6. **Docker Network:** Services isolated from external access

## Volume Mounts

| Container Path | Purpose | Persistent |
|---|---|---|
| `/etc/letsencrypt/` | SSL certificates | Yes |
| `/etc/yahlp/` | Configuration files | Yes |
| `/templates/` | Custom CSS layouts | Yes |
| `/var/log/apache2/` | Access/error logs | Yes |

## Performance Considerations

- **Caching:** Jellyfin auth tokens cached 1 hour
- **Health Checks:** Lightweight HTTP checks to service endpoints
- **Resource Limits:** Configure in docker-compose based on your services
- **Logging:** Apache logs all requests, can be analyzed for troubleshooting

## Future Architecture Improvements

- WebSocket support for streaming services
- GraphQL API for advanced queries
- Service-level rate limiting
- Advanced caching strategies
- Horizontal scaling support

---

**See also:** [Development](development.md) | [Security](security.md) | [Configuration](configuration.md)
