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

## Subdomain Routing

YAHLP supports two routing architectures for accessing services:

### Public Mode (Subdomain Routing)
In public deployments, certain services use **subdomains** rather than URL paths. This is required for OAuth to work correctly, as OAuth redirect URIs must exactly match the domain/subdomain registered with the OAuth provider.

**Services that support subdomain routing:**
- **Plex** (`PLEX_DOMAIN=plex.yourdomain.com`) - Uses OAuth with Plex account
- **Emby** (`EMBY_DOMAIN=emby.yourdomain.com`) - Uses OAuth redirect URI
- **Seerr** (`SEERR_DOMAIN=seerr.yourdomain.com`) - Uses OAuth (if configured)
- **Jackett** (`JACKETT_DOMAIN=jackett.yourdomain.com`) - Public API mode

**Example Configuration:**
```bash
# Public mode with subdomains
ACCESS_MODE=public
DOMAIN=yourdomain.com
PLEX_DOMAIN=plex.yourdomain.com
PLEX_ENABLED=true
PLEX_URL=http://plex:32400

EMBY_DOMAIN=emby.yourdomain.com
EMBY_ENABLED=true
EMBY_URL=http://emby:8096

SEERR_DOMAIN=seerr.yourdomain.com
SEERR_ENABLED=true
SEERR_URL=http://seerr:5055
```

**DNS Configuration Required:**
```
yourdomain.com        -> your.ip.address
plex.yourdomain.com   -> your.ip.address
emby.yourdomain.com   -> your.ip.address
seerr.yourdomain.com  -> your.ip.address
jackett.yourdomain.com -> your.ip.address
*.yourdomain.com      -> your.ip.address (wildcard, optional)
```

**Why Subdomains for OAuth:**
OAuth2 providers (Plex, Emby, etc.) require registered redirect URIs. The URI must match exactly:
- Registered: `https://plex.yourdomain.com/oauth2callback`
- Callback from Plex: `https://plex.yourdomain.com/oauth2callback`
- If using path-based: `https://yourdomain.com/plex/oauth2callback` - **Would NOT match**

### Private Mode (Folder-Based Routing)
In private deployments, services are accessed via URL paths on a single domain/IP:
- `http://192.168.1.100/jellyfin`
- `http://192.168.1.100/plex`
- `http://192.168.1.100/sonarr`

**Services supporting folder routing:**
- Most services work with folder routing
- OAuth services (Plex, Emby, Seerr) require special configuration via subdomains

**Example Configuration:**
```bash
# Private mode with folder paths
ACCESS_MODE=private
IP=192.168.1.100
JELLYFIN_ENABLED=true
JELLYFIN_URL=http://jellyfin:8096
SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989
# Note: Plex/Emby can use folder paths but OAuth won't work without subdomains
```

## Deployment Modes

### Public Deployment
- Domain-based access
- Let's Encrypt auto-certificate
- Ports 80/443 must be open
- DNS must resolve to container IP
- Use subdomains for OAuth services (Plex, Emby, Seerr)

### Private Deployment
- IP-based access (internal network)
- HTTP (no SSL) or self-signed HTTPS
- Only accessible from internal network
- No Let's Encrypt setup needed
- Use folder-based routing for most services
- OAuth services may not work (subdomains not applicable internally)

## Dynamic Apache Configuration Generation

YAHLP uses a template-based system to dynamically generate Apache VirtualHost configurations at container startup. This eliminates the need for static configuration files and allows flexible service enable/disable without rebuilding.

### Generation Process

1. **Startup Phase:**
   - Container starts with template files in `/apache-conf/`
   - Configuration loader reads `yahlp.json5` and environment variables
   - Enabled services are identified from configuration

2. **Template Processing:**
   - Master template: `apache-conf/reverse-proxy.conf.template`
   - Service templates: `apache-conf/services/{service}.conf`
   - Environment variables and service URLs are substituted into templates

3. **Dynamic VirtualHost Creation:**
   - For each enabled service:
     - Service URL is read from configuration
     - ProxyPass directives are generated with that URL
     - Authentication and header rewriting rules are applied
     - SSL configuration is injected (public mode)
   
4. **Apache Configuration Reload:**
   - Generated configuration is validated with `apache2ctl configtest`
   - If valid, Apache is restarted or configuration is reloaded
   - Services become immediately accessible

### Benefits of Dynamic Generation

- **No Manual Configuration Files:** Services appear/disappear based on `{SERVICE}_ENABLED` flags
- **Configuration as Code:** All settings from `yahlp.json5` and environment variables
- **Supports Multiple Deployment Modes:** Same codebase works for public/private modes
- **Simplifies Updates:** Service additions don't require code changes or rebuilds
- **Flexible Routing:** Subdomain or path-based routing configured automatically

### Configuration Substitution Variables

The template system replaces variables like:
- `@@DOMAIN@@` - Primary domain (yourdomain.com)
- `@@SERVICE_URL@@` - Backend service URL (http://sonarr:8989)
- `@@SERVICE_ENABLED@@` - Whether service is enabled
- `@@AUTH_TYPE@@` - Authentication method (basic, entra, google, none)
- `@@SSL_PROTOCOLS@@` - Allowed TLS versions
- `@@EMAIL@@` - Let's Encrypt email (public mode)

### Example: Sonarr Dynamic Configuration

**Input (from environment or yahlp.json5):**
```bash
SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989
DOMAIN=yourdomain.com
ACCESS_MODE=public
```

**Generated Apache Config:**
```apache
ProxyPass /sonarr http://sonarr:8989/sonarr retry=0 connectiontimeout=5
ProxyPassReverse /sonarr http://sonarr:8989/sonarr

<Location /sonarr>
  RequestHeader set X-Forwarded-Proto "https"
  Require valid-user  # Or Require all granted (depending on AUTH_TYPE)
</Location>
```

### Service Templates

Individual service configuration files allow for service-specific handling:
- Custom request/response header rewriting
- Service-specific proxy timeouts
- Location-specific authentication rules
- Content substitution for API paths

Templates are processed in order, allowing layered configuration:

```
1. Master template (reverse-proxy.conf.template)
   - Global settings, SSL configuration
   
2. Service templates (services/*.conf)
   - Sonarr: ProxyPass, header rules, substitutions
   - Radarr: ProxyPass, header rules, substitutions
   - ... (for each enabled service)
   
3. Authentication templates (auth-*.conf)
   - Basic auth, OAuth, none rules applied
```

## Apache Three-Layer Architecture

YAHLP uses a sophisticated three-layer Apache architecture to handle routing, authentication, and service proxying. This design allows flexible authentication while supporting both folder-based and subdomain routing.

### Layer 1: Service Routing (Translation Phase)
**File:** `apache-conf/reverse-proxy.conf.template` (lines 125-146)
**Phase:** Applied during Apache's translation phase (before authentication checks)

This layer contains pure routing directives with no authentication logic:
- **ProxyPass directives** - Route external paths to internal services
- **ProxyPassReverse** - Rewrite response headers to maintain correct URIs

**Example (Service Level):**
```apache
# Layer 1: Simple routing, no auth at this stage
ProxyPass /jellyfin "http://jellyfin:8096/jellyfin"
ProxyPassReverse /jellyfin "http://jellyfin:8096/jellyfin"

ProxyPass /sonarr "http://sonarr:8989/sonarr"
ProxyPassReverse /sonarr "http://sonarr:8989/sonarr"
```

**Key Points:**
- Routing happens in alphabetical order by directive
- No headers set at this layer (applied in Layer 2)
- Service includes are included with `@@INCLUDE_SERVICE@@` placeholders
- Processed before authentication, so routing works for all requests

### Layer 2: Headers and Location Rewriting (Per-Location)
**File:** Individual service configuration files like `apache-conf/services/seerr.conf`
**Phase:** Applied within `<Location>` blocks (after routing, before auth)

This layer handles protocol translation and path rewriting using Apache headers:
- **RequestHeader** - Add headers to backend requests (X-Real-IP, X-Forwarded-Proto, etc.)
- **Header edit location** - Rewrite Location headers in responses
- **Substitute** - Content rewriting for JSON/HTML/JS API responses

**Example (Seerr with Path Substitution):**
```apache
<Location /seerr>
    ProxyPass http://seerr:5055 retry=0
    ProxyPassReverse http://seerr:5055
    
    # Layer 2a: Add headers to backend
    RequestHeader set X-Real-IP %{REMOTE_ADDR}s
    RequestHeader set X-Forwarded-Proto "%{REQUEST_SCHEME}e"
    
    # Layer 2b: Rewrite outbound Location headers
    Header edit location ^/login https://yourdomain.com/seerr/login
    Header edit location ^/setup https://yourdomain.com/seerr/setup
    
    # Layer 2c: Rewrite content (API URLs in JSON/HTML/JS)
    Substitute "s|href=\"|href=\"/seerr|inq"
    Substitute "s|/api/|/seerr/api/|inq"
</Location>
```

**Why Location Rewriting Matters:**
When Seerr's backend sends `Location: /login` in a redirect, the client would go to `/login` (root). Layer 2 rewrites this to `/seerr/login` (correct path).

**Content Substitution Examples:**
- HTML: `href="/login"` → `href="/seerr/login"`
- JSON: `"/api/users"` → `"/seerr/api/users"`
- Next.js: `/_next/` → `/_next/` (prefixed to maintain routing)

### Layer 3: Authentication Enforcement
**File:** `apache-conf/auth-basic.conf` or `apache-conf/auth-entra-protect.conf`
**Phase:** Applied at request handling time (after routing and headers)

This layer enforces authentication rules for protected paths:
- **AuthType** - Specify auth method (Basic, OpenID Connect)
- **Require** - Specify who can access (all, valid-user, by IP, by claim)
- **Exemptions** - Public endpoints (health checks, static files)

**Example (Basic Auth):**
```apache
# Layer 3a: Protect HTML files (dashboard)
<Directory /var/www/html>
    AuthType Basic
    AuthName "YAHLP"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Directory>

# Layer 3b: Protect all service paths
<LocationMatch "^/(api|jellyfin|sonarr|radarr)(/|$)">
    AuthType Basic
    AuthName "YAHLP"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</LocationMatch>

# Layer 3c: Exempt static assets from auth
<Location ~ "\.(css|js|ico|png|jpg)$">
    Require all granted
</Location>

# Layer 3d: Exempt health checks
<Location /health>
    Require all granted
</Location>
```

**Authentication Flow:**
1. Request comes in: `GET /sonarr/system/status`
2. **Layer 1** matches and routes to `http://sonarr:8989/sonarr/system/status`
3. **Layer 2** adds headers, backend responds
4. **Layer 3** checks: Is `/sonarr` in protected paths? Yes. Is user authenticated? Check htpasswd.
5. If auth passes, Layer 1 routing already happened, response is relayed back

### Three-Layer Interaction Example

Request: User accesses `https://yourdomain.com/seerr/dashboard`

```
┌─────────────────────────────────────────────────────┐
│ REQUEST: GET /seerr/dashboard HTTP/1.1             │
└──────────────────────┬────────────────────────────────┘
                       │
                       ▼
         ┌─────────────────────────────────────┐
         │ LAYER 1: ROUTING (Translation)     │
         │ Match: ProxyPass /seerr             │
         │ Action: Route to http://seerr:5055 │
         └──────────────────┬──────────────────┘
                            │
                            ▼
         ┌──────────────────────────────────────┐
         │ LAYER 2: HEADERS & REWRITING         │
         │ Add: X-Forwarded-Proto: https        │
         │ Add: X-Real-IP: 203.0.113.1          │
         │ Rewrite outbound Location headers    │
         │ Substitute response content          │
         └──────────────────┬───────────────────┘
                            │
                            ▼
         ┌──────────────────────────────────────┐
         │ LAYER 3: AUTHENTICATION              │
         │ Check: /seerr in protected paths?    │
         │ Action: Verify Basic Auth            │
         │ Result: Valid user or 401 Unauthorized
         └──────────────────┬───────────────────┘
                            │
                    ┌───────┴──────────┐
                    │ Auth Pass        │ Auth Fail
                    ▼                  ▼
        ┌──────────────────┐    ┌──────────────┐
        │ Proxy response   │    │ 401 Error    │
        │ back to client   │    │ Send to user │
        └──────────────────┘    └──────────────┘
```

### Configuration File Structure

The three-layer architecture is implemented across these files:

**Layer 1 - Routing:**
- `apache-conf/reverse-proxy.conf.template` - Main routing directives
- `apache-conf/services/*.conf` - Individual service ProxyPass directives

**Layer 2 - Headers:**
- `apache-conf/services/*.conf` - Header edit, RequestHeader, Substitute
- `apache-conf/ssl-config.conf` - SSL/security headers

**Layer 3 - Auth:**
- `apache-conf/auth-basic.conf` - Basic authentication rules
- `apache-conf/auth-entra-protect.conf` - Azure AD/Entra authentication
- `apache-conf/auth-google-protect.conf` - Google OAuth authentication

## Security Architecture

1. **SSL/TLS Termination:** Apache handles all HTTPS
2. **Authentication:** Centralized at Apache Level 3
3. **Authorization:** Per-service in backend and Apache rules
4. **API Security:** Authentication required for `/api/*` endpoints (Layer 3)
5. **CORS:** Configured per deployment mode
6. **Docker Network:** Services isolated from external access
7. **Layered Security:** Defense in depth with routing, header translation, and auth

## Volume Mounts

| Container Path | Purpose | Persistent |
|---|---|---|
| `/etc/letsencrypt/` | SSL certificates | Yes |
| `/etc/yahlp/` | Configuration files | Yes |
| `/templates/` | Custom CSS layouts | Yes |
| `/var/log/apache2/` | Access/error logs | Yes |

## Health Check Endpoints

YAHLP provides comprehensive health check endpoints for all services via the Node.js API proxy (port 3000). These endpoints are used by the dashboard to display service status and availability.

### Generic Health Check Endpoint

All services support a generic health check at `/api/{service}/health`:

```bash
# Generic health check format
GET /api/{service}/health

# Response on success (HTTP 200)
{
  "status": "ok",
  "version": "4.0.1",
  // Additional service-specific fields
}

# Response on failure (HTTP 500)
{
  "error": "Connection refused"
}
```

### Service-Specific Endpoints

**Supported Services for Generic /health:**
- `sonarr` - `/api/sonarr/health`
- `radarr` - `/api/radarr/health`
- `lidarr` - `/api/lidarr/health`
- `whisparr` - `/api/whisparr/health`
- `jellyfin` - `/api/jellyfin/health`
- `emby` - `/api/emby/health`
- `plex` - `/api/plex/health`
- `tautulli` - `/api/tautulli/health`
- `maintainerr` - `/api/maintainerr/health`
- `transmission` - `/api/transmission/health`
- `qbittorrent` - `/api/qbittorrent/health`
- `sabnzbd` - `/api/sabnzbd/health`
- `deluge` - `/api/deluge/health`
- `nzbget` - `/api/nzbget/health`
- `jackett` - `/api/jackett/health`
- `bazarr` - `/api/bazarr/health`

**Service-Specific Custom Endpoints:**

| Service | Endpoint | Response Fields | Requires |
|---------|----------|-----------------|----------|
| **Plex** | `/api/plex/server` | `identifier`, `friendlyName`, `version` | Plex token |
| **Seerr** | `/api/seerr/status` | `version`, `commitTag`, `initialized` | Seerr API key |
| **Tautulli** | `/api/tautulli/status` | `topUser`, `users`, `libraries` | Tautulli API key |
| **Bazarr** | `/api/bazarr/status` | `health`, `episodes_wanted_count` | Bazarr API key |
| **Prowlarr** | `/api/prowlarr/health` | Array of health entries | Prowlarr API key |
| **Jackett** | `/api/jackett/health` | `status`, `results` (count) | Jackett API key |
| **NZBHydra** | `/api/nzbhydra` | Empty object `{}` if online | NZBHydra API key |

### Health Check Example Responses

**Sonarr/Radarr/Lidarr Health:**
```json
[
  {
    "source": "SystemTasks",
    "type": "notice",
    "message": "System completed failed backup",
    "wikiUrl": "https://wiki.servarr.com/sonarr/system#backup"
  }
]
```

**Plex Server:**
```json
{
  "identifier": "abc123def456",
  "friendlyName": "My Plex Server",
  "version": "1.32.5.7237",
  "size": "32100",
  "scrobbleServers": "https://scrobble.plex.tv"
}
```

**Seerr Status:**
```json
{
  "version": "0.1.1",
  "commitTag": "develop-abc123",
  "initialized": true,
  "totalRequests": 42,
  "totalMediaItems": 150
}
```

**Tautulli Status:**
```json
{
  "topUser": "Alice",
  "users": 3,
  "libraries": 5
}
```

### Caching Behavior

All health check responses are cached with a 30-second TTL (time-to-live):
- First request fetches live data from service
- Subsequent requests within 30 seconds return cached data
- After 30 seconds, next request fetches fresh data

This reduces load on backend services while keeping dashboard updates relatively current.

### Accessing Health Checks

**Via Dashboard:**
The dashboard automatically calls these endpoints to display service status cards.

**Directly via API:**
```bash
# Check a service health
curl "https://yourdomain.com/api/sonarr/health" \
  -u "username:password"  # If using Basic Auth

# Check without authentication (if health checks are exempted)
curl "https://yourdomain.com/api/sonarr/health"
```

**Via Docker:**
```bash
docker exec -it yahlp curl "http://localhost:3000/api/jellyfin/health"
```

### Health Check Configuration

Health check endpoints are:
- **Always available** at `/api/{service}/health`
- **Automatically exempted** from authentication in Layer 3
- **Never cached** at Apache level (only 30-second in-process cache)
- **Public endpoints** for monitoring systems to use

Example monitoring integration:
```bash
#!/bin/bash
# Nagios/Icinga health check script
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://yourdomain.com/api/sonarr/health)
if [ "$STATUS_CODE" -eq 200 ]; then
  echo "Sonarr OK"
  exit 0
else
  echo "Sonarr DOWN (HTTP $STATUS_CODE)"
  exit 2
fi
```

## Performance Considerations

- **Caching:** Health checks cached 30 seconds, Jellyfin auth tokens cached 1 hour
- **Health Checks:** Lightweight HTTP checks to service endpoints (exempt from auth)
- **Resource Limits:** Configure in docker-compose based on your services
- **Logging:** Apache logs all requests, can be analyzed for troubleshooting
- **API Port:** Node.js proxy runs on port 3000 internally, not exposed externally

## Future Architecture Improvements

- WebSocket support for streaming services
- GraphQL API for advanced queries
- Service-level rate limiting
- Advanced caching strategies
- Horizontal scaling support

---

**See also:** [Development](development.md) | [Security](security.md) | [Configuration](configuration.md)
