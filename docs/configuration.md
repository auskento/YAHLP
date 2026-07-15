# Configuration Reference

Complete list of all environment variables and settings for YAHLP.

## Table of Contents
1. [Configuration Methods](#configuration-methods)
2. [Deployment](#deployment)
3. [Dashboard](#dashboard)
4. [Authentication](#authentication)
5. [Services](#services)
6. [Advanced](#advanced)

---

## Configuration Methods

YAHLP supports two complementary configuration approaches:

### JSON5 Config File (`yahlp.json5`)
- **Location:** `/etc/yahlp/yahlp.json5` (mounted in container)
- **Format:** JSON5 (JSON with comments, trailing commas)
- **Use Cases:**
  - Reusable configuration template
  - Well-documented with comments
  - Shared across multiple deployments
  - Complex nested settings
- **Example:**
  ```json5
  {
    // This is the base configuration template
    dashboard: { name: 'My HomeLab' },
    services: {
      sonarr: { url: 'http://sonarr:8989', api_key: '...' }
    }
  }
  ```

### Environment Variables
- **Naming:** `UPPERCASE_WITH_UNDERSCORES`
- **Set via:** `.env` file, docker-compose.yml, Kubernetes secrets, etc.
- **Use Cases:**
  - Per-deployment secrets (API keys, passwords)
  - Local overrides for specific environments
  - Secrets management (kept private, separate from config files)
  - Docker/Kubernetes native approach
- **Example:**
  ```bash
  SONARR_API_KEY=actual-secret-key
  JELLYFIN_PASSWORD=production-password
  ```

### Priority & Overrides

Environment variables **override** JSON5 settings:

```
JSON5 Config (lowest priority)
        ↓
Environment Variables (highest priority)
        ↓
Final Configuration (what YAHLP uses)
```

**Example:**
```json5
// yahlp.json5 (shared team config)
{
  sonarr: {
    url: 'http://sonarr:8989',
    api_key: 'default-or-placeholder',
    enabled: true
  }
}
```

```bash
# .env (local deployment, not in git)
SONARR_API_KEY=my-actual-secret-key
SONARR_URL=http://sonarr-prod:8989
```

**Result:** SONARR_URL and SONARR_API_KEY come from .env, enabled stays from JSON5.

### Recommended Setup

**For multiple deployments (dev/staging/prod):**
1. Keep `yahlp.json5` with template/shared configuration
2. Each deployment has its own `.env` file (stored securely)
3. Environment variables override sensitive data
4. Config is portable and reusable

**Example deployment structure:**
```
yahlp.json5                    # Shared template
.env.development               # Dev environment (keep private)
.env.staging                   # Staging environment (keep private)
.env.production                # Prod environment (keep private)
```

**For Docker deployments:**
1. `yahlp.json5` as base configuration
2. `docker-compose.yml` or `docker run -e VAR=value` sets overrides
3. Secrets stored in Docker secrets, not in compose file
4. Each host/environment has separate `.env`

**For Kubernetes:**
1. ConfigMap for `yahlp.json5`
2. Secrets for sensitive environment variables
3. Environment variables override ConfigMap values

---

---

## Deployment

Controls how YAHLP is accessed and secured.

### ACCESS_MODE
- **Type:** `public` or `private`
- **Default:** `public`
- **Description:** Deployment environment
  - `public` - Internet-facing with automatic SSL/TLS certificates via Let's Encrypt
  - `private` - Local network only, HTTP only, no SSL required
- **When to use:**
  - Public: Accessing from outside your home network, need HTTPS
  - Private: HomeLab/LAN only, all users are trusted
- **Implications:**
  - Public requires valid domain + email
  - Private requires internal IP address
  - Private mode only supports no auth or basic auth

### DOMAIN
- **Type:** String (fully qualified domain name)
- **Default:** Empty
- **Required:** Yes (for `ACCESS_MODE=public`)
- **Examples:**
  - `media.example.com` - Subdomain
  - `yahlp.example.com` - Service subdomain
  - `example.com` - Root domain
- **Setup:**
  - Must have valid DNS A/AAAA records pointing to your server IP
  - Test DNS resolution: `nslookup yourdomain.com`
  - Ensure port 80 is accessible for Let's Encrypt validation

### EMAIL
- **Type:** String (email address)
- **Default:** Empty
- **Required:** Yes (for `ACCESS_MODE=public`)
- **Examples:** `admin@example.com`, `webmaster@company.com`
- **Purpose:**
  - Let's Encrypt uses this for certificate renewal notifications
  - Receives expiry warnings (certificates valid 90 days)
  - Required to register with Let's Encrypt
- **Note:** Address is only used by Let's Encrypt, not stored or shared

### IP
- **Type:** String (IPv4 address)
- **Default:** Empty
- **Required:** Yes (for `ACCESS_MODE=private`)
- **Examples:** `192.168.1.100`, `10.0.0.50`
- **Setup:**
  - Use your server's static LAN IP address
  - Find IP: Run `ipconfig` (Windows) or `ifconfig` (Linux)
  - Ensure IP is stable or use DHCP reservation
  - All devices must be on same network or use VPN

### DASHBOARD_TEST
- **Type:** `true` or `false`
- **Default:** `false`
- **Description:** Use Let's Encrypt staging server (test mode)
- **When to use:**
  - `true` - Testing SSL setup, avoids rate limits (doesn't issue valid certs)
  - `false` - Production use, issues valid certificates
- **Warning:** Staging certificates won't be trusted by browsers
- **Best practice:** Set to `true` initially to test, then `false` after confirming setup

---

## Dashboard

Customize the dashboard appearance and behavior.

### DASHBOARD_NAME
- **Type:** String (any text)
- **Default:** `YAHLP`
- **Description:** Display name shown in header and browser tab
- **Examples:**
  - `My Media Server`
  - `HomeLab Dashboard`
  - `Family Portal`
  - `Media Center`
- **Best practice:** Keep under 20 characters for mobile display

### DASHBOARD_COLOR
- **Type:** Hex color code
- **Default:** `#1a1a1a` (dark gray)
- **Format:** `#RRGGBB` (6 hex digits)
- **Palette suggestions:**
  - `#FF6B6B` - Red/Coral
  - `#4ECDC4` - Teal/Cyan
  - `#95E1D3` - Mint Green
  - `#FFD93D` - Golden Yellow
  - `#A8E6CF` - Light Green
  - `#FFB3BA` - Light Pink
- **Usage:** Menu background and accent highlights
- **Tool:** Use https://htmlcolorcodes.com to pick colors

### DASHBOARD_STYLE
- **Type:** String (layout configuration)
- **Default:** `modern`
- **Description:** Dashboard layout theme with optional theme switcher
- **Format modes:**
  - Single layout: `DASHBOARD_STYLE=modern` → Uses that layout, can switch themes in UI
  - Multiple layouts: `DASHBOARD_STYLE=modern,sleek` → Only build/show those layouts
  - Locked layout: `DASHBOARD_STYLE=modern:only` → Fixed layout, no theme switcher
- **Available layouts:**
  - `classic` - Horizontal top navigation, services in grid
  - `modern` - Vertical left sidebar, API-style design
  - `sleek` - Left sidebar, compact with gradient accents
  - `minimal` - Left sidebar, ultra-minimal single column
  - Custom layouts from `/etc/yahlp/templates/` (see [Dashboard Customization](dashboard-customization.md))
- **Common configurations:**
  - `DASHBOARD_STYLE=modern` - Default, all layouts available, modern first
  - `DASHBOARD_STYLE=modern,sleek,minimal` - Only these three in theme switcher
  - `DASHBOARD_STYLE=classic:only` - Lock to classic, no switching
- **Performance tip:** Specifying layouts reduces build time
- **Note:** Theme switcher appears in dashboard UI settings when multiple layouts configured

### DASHBOARD_THEME
- **Type:** `dark` or `light`
- **Default:** `dark`
- **Description:** Color scheme for dashboard
- **Usage:** Applies globally to all layouts
- **Note:** Can be changed in dashboard UI if multiple layouts available

### DASHBOARD_ORDER
- **Type:** Comma-separated service codes with optional layout controls
- **Default:** `SAB,GET,HYD,TRA,QBI,DEL,PRO,JAC,SON,RAD,LID,WHI,SEE,BAZ,TAU,MNT,JEL,PLX,EMB`
- **Description:** Controls service display order and grouping on dashboard
- **Service codes (3-letter abbreviations):**
  - **Usenet:** SAB (SABnzbd), GET (NZBGet), HYD (NZBHydra)
  - **Torrents:** TRA (Transmission), QBI (qBittorrent), DEL (Deluge)
  - **Indexers:** PRO (Prowlarr), JAC (Jackett)
  - **Content:** SON (Sonarr), RAD (Radarr), LID (Lidarr), WHI (Whisparr)
  - **Requests:** SEE (Seerr)
  - **Media:** JEL (Jellyfin), PLX (Plex), EMB (Emby)
  - **Tools:** BAZ (Bazarr), TAU (Tautulli), MNT (Maintainerr)
- **Layout controls:**
  - `SEP` - Invisible spacing gap between items
  - `VIS` - Visible horizontal separator line
  - `LBL:Name` - Section header label (e.g., `LBL:Download Clients`)
- **Common configurations:**
  ```bash
  # Simple order
  DASHBOARD_ORDER=QBI,TRA,SAB,SON,RAD,JEL,PLX
  
  # Organized with sections
  DASHBOARD_ORDER=LBL:Downloads,QBI,TRA,SAB,SEP,LBL:Content,SON,RAD,LID,SEP,LBL:Media,JEL,PLX,EMB
  
  # With visible dividers
  DASHBOARD_ORDER=JEL,PLX,VIS,SON,RAD,VIS,QBI,TRA,SAB
  ```
- **Note:** Only enabled services appear; disabled services are hidden regardless of order
- **Tip:** Use `LBL:` and `SEP` to organize for mobile-friendly layout

### DASHBOARD_LANDING
- **Type:** String (service name with optional path)
- **Default:** Empty (shows service grid)
- **Description:** Default page when dashboard loads
- **Format:**
  - Empty: Shows all enabled services in grid view
  - Service name: `DASHBOARD_LANDING=jellyfin` → Opens Jellyfin directly
  - Service + path: `DASHBOARD_LANDING=radarr/calendar` → Opens Radarr calendar view
- **Common examples:**
  ```bash
  DASHBOARD_LANDING=jellyfin        # Load Jellyfin media player
  DASHBOARD_LANDING=sonarr/series   # Load Sonarr TV shows
  DASHBOARD_LANDING=radarr/movies   # Load Radarr movies
  DASHBOARD_LANDING=seerr           # Load Seerr requests page
  ```
- **When to use:**
  - Set to favorite service for quick access
  - Use service paths for specific views within that service
- **Note:** Service must be enabled to work as landing page

### DASHBOARD_WINDOWS
- **Type:** `popout` or `newtab`
- **Default:** `popout`
- **Description:** How service links open from dashboard
- **Behavior:**
  - `popout` - Opens in separate popup window (default)
  - `newtab` - Opens in new browser tab
- **Use cases:**
  - `popout` - Keep dashboard visible while browsing services
  - `newtab` - Cleaner browser tab management
- **Examples:**
  ```bash
  DASHBOARD_WINDOWS=popout  # Service links open in popup windows
  DASHBOARD_WINDOWS=newtab  # Service links open in new tabs
  ```

### DASHBOARD_SITES
- **Type:** Comma-separated site codes
- **Default:** Empty (only custom sites from sites.json5)
- **Description:** Built-in torrent and usenet search sites to enable
- **Torrent sites:** TPB, FIL, HDB, IPT, 1337, YTS, LAT, NYA, PTP
- **Usenet sites:** DOG, DRS, NLF, NFW, NGK, PLA, TAB
- **Common configurations:**
  ```bash
  # Torrent sites
  DASHBOARD_SITES=TPB,1337,YTS,NLF
  
  # Usenet + torrent mix
  DASHBOARD_SITES=DOG,DRS,TPB,YTS
  
  # Single site
  DASHBOARD_SITES=TPB
  ```
- **Note:** Custom sites from sites.json5 always appear regardless
- **Security:** Only enable sites you trust; evaluate each site's safety

### DASHBOARD_TEST
- **Type:** `true` or `false`
- **Default:** `false`
- **Description:** Use Let's Encrypt staging (dry-run mode)
- **Use Case:** Testing without hitting rate limits
- **Note:** Set to `true` during testing, `false` for production certificates

---

## Authentication

Controls who can access the dashboard.

### AUTHTYPE
- **Type:** `none`, `basic`, `entra`, or `google`
- **Default:** `none`
- **Description:** Authentication method for dashboard access
- **Options:**

| Method | Best For | Complexity | Setup Time |
|--------|----------|-----------|-----------|
| `none` | Trusted home networks only | Simple | None |
| `basic` | Small team, simple password | Low | <5 minutes |
| `google` | Personal/small team | Medium | 10-15 minutes |
| `entra` | Enterprise, Azure AD | High | 20-30 minutes |

- **Recommendations:**
  - `none` - Only if behind VPN or on isolated LAN
  - `basic` - Quick setup for password protection
  - `google` - Best for personal use with family
  - `entra` - Enterprise/organization environments
- **Important:** Private mode only supports `none` or `basic`

### BASIC_AUTH_CREDENTIALS
- **Type:** String (username:password pairs)
- **Required:** Yes (for `AUTHTYPE=basic`)
- **Format:** `username:password` or `user1:pass1|user2:pass2` (pipe-separated)
- **Limitations:**
  - Passwords stored in plain text in environment/config
  - Use strong passwords (basic auth transmits credentials in Base64, not encrypted)
  - Max 10 users recommended
- **Single user example:**
  ```bash
  BASIC_AUTH_CREDENTIALS=admin:SecurePassword123!
  ```
- **Multiple users example:**
  ```bash
  BASIC_AUTH_CREDENTIALS=alice:password123|bob:password456|charlie:password789
  ```
- **Best practices:**
  - Use different passwords for each user
  - Store credentials in `.env` file (never in version control)
  - Use over HTTPS only (public mode provides this)

### ENTRA_CLIENT_ID
- **Type:** String (UUID format)
- **Required:** Yes (for `AUTHTYPE=entra`)
- **Description:** Azure Entra ID (formerly Azure AD) application client ID
- **Where to find:**
  1. Go to Azure Portal (https://portal.azure.com)
  2. Navigate to Azure Active Directory → App registrations
  3. Find your YAHLP app registration
  4. Copy the "Application (client) ID"
- **Format:** `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **Example:** `550e8400-e29b-41d4-a716-446655440000`

### ENTRA_CLIENT_SECRET
- **Type:** String
- **Required:** Yes (for `AUTHTYPE=entra`)
- **Description:** Client secret for Azure Entra ID authentication
- **Where to find:**
  1. Azure Portal → App registrations → Your app
  2. Go to "Certificates & secrets"
  3. Under "Client secrets", click "New client secret"
  4. Copy the secret value immediately (expires after 24 hours display)
- **Security:** Keep this secret, don't commit to git
- **Expiration:** Set long expiration (12-24 months) and create reminders to rotate

### ENTRA_PROVIDER_METADATA_URL
- **Type:** URL (OpenID Connect metadata endpoint)
- **Required:** Yes (for `AUTHTYPE=entra`)
- **Format:** `https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration`
- **Options:**
  - **Specific tenant:** Use your Azure AD tenant ID
  - **Multi-tenant:** Use `common` for any Azure AD organization
- **Examples:**
  ```bash
  # Multi-tenant (anyone with Azure AD)
  ENTRA_PROVIDER_METADATA_URL=https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration
  
  # Specific tenant
  ENTRA_PROVIDER_METADATA_URL=https://login.microsoftonline.com/550e8400-e29b-41d4-a716-446655440000/v2.0/.well-known/openid-configuration
  ```

### ENTRA_CRYPTO_PASSPHRASE
- **Type:** String (base64-encoded passphrase)
- **Required:** No (auto-generated if empty)
- **Default:** Auto-generated on first run
- **Description:** Encrypts session cookies for OAuth security
- **When to set:**
  - Leave empty for security (auto-generated each restart)
  - Set this value only if sessions must persist across container restarts
  - Required for load-balancing scenarios
- **Generate custom:** `openssl rand -base64 24`
- **Example:**
  ```bash
  ENTRA_CRYPTO_PASSPHRASE=abc123def456ghi789jkl012mnopqrstuv=
  ```

### GOOGLE_CLIENT_ID
- **Type:** String
- **Required:** Yes (for `AUTHTYPE=google`)
- **Description:** Google OAuth 2.0 Client ID
- **Where to find:**
  1. Go to Google Cloud Console (https://console.cloud.google.com)
  2. Create project or select existing
  3. Enable "Google+ API"
  4. Create OAuth 2.0 credentials (Web application)
  5. Add authorized redirect URI: `https://DOMAIN/oauth2callback`
  6. Copy the "Client ID"
- **Format:** `xxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com`

### GOOGLE_CLIENT_SECRET
- **Type:** String
- **Required:** Yes (for `AUTHTYPE=google`)
- **Description:** Google OAuth 2.0 Client Secret
- **Where to find:**
  1. Google Cloud Console → APIs & Services → Credentials
  2. Find your OAuth 2.0 Client ID
  3. Download JSON or copy "Client secret"
- **Security:** Keep secret, don't commit to git
- **Note:** Generate new secret if compromised

### Redirect URIs (Auto-generated)
These URIs are automatically created and registered:
- **Main dashboard:** `https://DOMAIN/oauth2callback`
- **Seerr subdomain:** `https://SEERR_DOMAIN/oauth2callback` (if configured)
- **Emby subdomain:** `https://EMBY_DOMAIN/oauth2callback` (if configured)
- **Plex subdomain:** `https://PLEX_DOMAIN/oauth2callback` (if configured)

For detailed OAuth setup instructions, see [AUTHENTICATION.md](AUTHENTICATION.md).

---

## Services

Configuration pattern for each service:

### Service Configuration Variables
Each service uses this naming pattern:
- **{SERVICE}_ENABLED** - `true` or `false` to show/hide service
- **{SERVICE}_URL** - Backend service URL
- **{SERVICE}_API_KEY** - API authentication (if needed)
- **{SERVICE}_USERNAME** / **{SERVICE}_PASSWORD** - Basic auth (if needed)

### URL Format Examples
```bash
# Docker container on same network
SERVICE_URL=http://servicename:port

# Local IP address
SERVICE_URL=http://192.168.1.100:port

# External/cloud service
SERVICE_URL=http://external.example.com:port

# With custom path
SERVICE_URL=http://192.168.1.100:port/app

# HTTPS (self-signed certs)
SERVICE_URL=https://servicename:port
```

### Common Configuration Scenarios

**Docker Compose (same network):**
```bash
SONARR_URL=http://sonarr:8989
RADARR_URL=http://radarr:7878
JELLYFIN_URL=http://jellyfin:8096
```

**LAN IPs (separate network):**
```bash
SONARR_URL=http://192.168.1.100:8989
RADARR_URL=http://192.168.1.101:7878
JELLYFIN_URL=http://192.168.1.102:8096
```

**Mixed setup:**
```bash
# Docker services
SONARR_URL=http://sonarr:8989
RADARR_URL=http://radarr:7878

# External services
PLEX_URL=http://192.168.1.50:32400
JELLYFIN_URL=https://media.example.com
```

### Custom Service Icons

Place custom icons in the config directory:
```bash
config/service_icons/servicename.png    # PNG format
config/service_icons/servicename.svg    # SVG format (preferred)
```

**Icon loading behavior:**
1. SVG takes priority if both exist (scales to any size)
2. Falls back to PNG if SVG not found
3. Built-in icons copied to `/etc/yahlp/service_icons/` on first run
4. Replace by overwriting files with custom versions

### Indexer/Search Services

#### Prowlarr (PRO)
```bash
PROWLARR_ENABLED=true
PROWLARR_URL=http://prowlarr:9696
PROWLARR_API_KEY=your-api-key
```

#### Jackett (JAC)
```bash
JACKETT_ENABLED=true
JACKETT_URL=http://jackett:9117
JACKETT_API_KEY=your-api-key
```

### Content Managers

#### Sonarr (SON)
```bash
SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989
SONARR_API_KEY=your-api-key
SONARR_LANDING=sonarr/series  # Optional: default page view
```

#### Radarr (RAD)
```bash
RADARR_ENABLED=true
RADARR_URL=http://radarr:7878
RADARR_API_KEY=your-api-key
RADARR_LANDING=radarr/movies  # Optional: default page view
```

#### Lidarr (LID)
```bash
LIDARR_ENABLED=true
LIDARR_URL=http://lidarr:8686
LIDARR_API_KEY=your-api-key
```

#### Whisparr (WHI)
```bash
WHISPARR_ENABLED=true
WHISPARR_URL=http://whisparr:6969
WHISPARR_API_KEY=your-api-key
```

### Request/Utility Services

#### Seerr (SEE)
```bash
SEERR_ENABLED=true
SEERR_URL=http://seerr:5055
SEERR_API_KEY=your-api-key
```

#### Bazarr (BAZ)
```bash
BAZARR_ENABLED=true
BAZARR_URL=http://bazarr:6767
BAZARR_API_KEY=your-api-key
```

#### Tautulli (TAU)
```bash
TAUTULLI_ENABLED=true
TAUTULLI_URL=http://tautulli:8181
TAUTULLI_API_KEY=your-api-key
```

#### Maintainerr (MNT)
```bash
MAINTAINERR_ENABLED=true
MAINTAINERR_URL=http://maintainerr:6246
MAINTAINERR_API_KEY=your-api-key
```

### Usenet Clients

#### SABnzbd (SAB)
```bash
SABNZBD_ENABLED=true
SABNZBD_URL=http://sabnzbd:8080
SABNZBD_API_KEY=your-api-key
```

#### NZBGet (GET)
```bash
NZBGET_ENABLED=true
NZBGET_URL=http://nzbget:6789
NZBGET_USERNAME=username
NZBGET_PASSWORD=password
```

#### NZBHydra (HYD)
```bash
NZBHYDRA_ENABLED=true
NZBHYDRA_URL=http://nzbhydra:5076
NZBHYDRA_API_KEY=your-api-key
```

### Torrent Clients

#### Transmission (TRA)
```bash
TRANSMISSION_ENABLED=true
TRANSMISSION_URL=http://transmission:9091
TRANSMISSION_PASSWORD=password  # Optional if set in app
```

#### qBittorrent (QBI)
```bash
QBITTORRENT_ENABLED=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=your-api-key  # Required for remote access
```

#### Deluge (DEL)
```bash
DELUGE_ENABLED=true
DELUGE_URL=http://deluge:8112
DELUGE_PASSWORD=your-password  # Required
```

### Media Servers

#### Jellyfin (JEL)
```bash
JELLYFIN_ENABLED=true
JELLYFIN_URL=http://jellyfin:8096
JELLYFIN_API_KEY=your-api-key
JELLYFIN_USERNAME=username  # Optional for remote access
JELLYFIN_PASSWORD=password  # Optional for remote access
```

#### Emby (EMB)
```bash
EMBY_ENABLED=true
EMBY_URL=http://emby:8096
EMBY_API_KEY=your-api-key
EMBY_DOMAIN=emby.example.com  # Optional: create subdomain with own SSL
```

#### Plex (PLX)
```bash
PLEX_ENABLED=true
PLEX_URL=http://plex:32400
PLEX_API_KEY=your-api-key
PLEX_DOMAIN=plex.example.com  # Optional: create subdomain with own SSL
```

See [SERVICES.md](SERVICES.md) for detailed service setup and troubleshooting.

---

## Advanced

### PUID / PGID
- **Type:** Integer (Unix user/group IDs)
- **Default:** `0` / `0` (root)
- **Description:** Docker container process user IDs for file ownership
- **When to change:**
  - Default (0:0) works for most setups
  - Change if mounting volumes with specific user restrictions
  - Unraid users: Set to match your Unraid user
- **Common values:**
  - Unraid: `99:100` (default Unraid user:group)
  - Linux: `1000:1000` (first non-root user)
  - Find IDs: Run `id` command on host system
- **Example:**
  ```bash
  PUID=1000
  PGID=1000
  ```
- **Impact:** Affects which system user owns created/modified files
- **Troubleshooting:** If permissions denied errors occur, check PUID/PGID match mounted volumes

### TZ
- **Type:** Timezone string (IANA timezone database)
- **Default:** `UTC`
- **Description:** Timezone for application timestamps and logs
- **Common examples:**
  - `America/New_York` - Eastern Time
  - `America/Los_Angeles` - Pacific Time
  - `America/Chicago` - Central Time
  - `Europe/London` - GMT/BST
  - `Europe/Paris` - CET/CEST
  - `Asia/Tokyo` - JST
  - `Australia/Sydney` - AEDT
  - `UTC` - Coordinated Universal Time
- **Format:** `Continent/City` or `UTC`
- **Find your timezone:** [IANA Timezone Database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
- **Example:**
  ```bash
  TZ=America/New_York
  ```
- **Note:** Affects scheduled task times in content managers (Sonarr, Radarr, etc)

---

## Best Practices & Troubleshooting

### Security Recommendations

1. **Secrets Management:**
   - Store API keys and passwords in `.env` file (not in git)
   - Use `.gitignore` to prevent accidental commits
   - Use strong, unique passwords for auth credentials

2. **HTTPS in Public Mode:**
   - Always use `ACCESS_MODE=public` for internet exposure
   - Keep `DASHBOARD_TEST=false` for valid certificates
   - Test with `DASHBOARD_TEST=true` first to avoid rate limits

3. **Authentication:**
   - Use OAuth (Google/Entra) for internet-facing deployments
   - Never expose dashboard without authentication
   - Keep credentials secure, don't share in logs/screenshots

4. **Service URLs:**
   - Use internal network for Docker/LAN services
   - Don't expose external service URLs to untrusted networks
   - Validate certificate chains for HTTPS services

### Common Configuration Issues

**Services not appearing:**
- Check `{SERVICE}_ENABLED=true`
- Verify `{SERVICE}_URL` is accessible from YAHLP
- Test connectivity: `curl {SERVICE_URL}`
- Check dashboard logs: `docker logs yahlp`

**Authentication problems:**
- Basic auth: Verify format `username:password` with proper encoding
- OAuth: Confirm redirect URI matches exactly
- Check browser console for errors (F12 Dev Tools)

**URL connectivity errors:**
- Docker: Verify service on same network: `docker network ls`
- LAN: Check IP address/port: `telnet 192.168.1.100 8989`
- HTTPS: Allow self-signed certificates if needed
- Firewall: Ensure ports aren't blocked between containers/hosts

**Dashboard style not applying:**
- Multiple styles: Check `DASHBOARD_STYLE` has comma-separated values
- Clear browser cache (Ctrl+Shift+Del)
- Restart container after style changes

### Validation Checklist

Before deploying:
- [ ] Domain resolves to correct IP (test: `nslookup DOMAIN`)
- [ ] All service URLs tested and accessible
- [ ] API keys/passwords stored in `.env` (not in git)
- [ ] DASHBOARD_TEST set appropriately (true for testing, false for production)
- [ ] AUTHTYPE and credentials configured if needed
- [ ] PUID/PGID match your system (especially if using volumes)
- [ ] TZ set to your timezone
- [ ] All enabled services have required credentials

---

## Configuration Priority

YAHLP uses three-tier configuration (highest to lowest priority):

1. **Environment Variables** (passed to Docker)
2. **yahlp.json5** (config file in `/etc/yahlp/`)
3. **Defaults** (built-in)

Example: If both env var and JSON5 set a value, env var wins.

---

## Common Configuration Examples

### Example 1: Docker Compose (LAN Only)

```bash
# Private LAN deployment with Docker Compose
ACCESS_MODE=private
IP=192.168.1.100

# Dashboard
DASHBOARD_NAME="HomeLab"
DASHBOARD_STYLE=modern:only
DASHBOARD_ORDER=LBL:Downloads,QBI,TRA,SAB,SEP,LBL:Content,SON,RAD,SEP,LBL:Media,JEL,PLX
DASHBOARD_LANDING=jellyfin

# Basic auth for privacy
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=admin:homelab123|user:password456

# Services on same Docker network
QBITTORRENT_ENABLED=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=qbi-key-here

TRANSMISSION_ENABLED=true
TRANSMISSION_URL=http://transmission:9091

SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989
SONARR_API_KEY=sonarr-key-here

RADARR_ENABLED=true
RADARR_URL=http://radarr:7878
RADARR_API_KEY=radarr-key-here

JELLYFIN_ENABLED=true
JELLYFIN_URL=http://jellyfin:8096

PLEX_ENABLED=true
PLEX_URL=http://plex:32400

# Settings
PUID=99
PGID=100
TZ=America/New_York
```

### Example 2: Public Internet Access with Google OAuth

```bash
# Internet-facing with automatic SSL and Google OAuth
ACCESS_MODE=public
DOMAIN=media.example.com
EMAIL=admin@example.com
DASHBOARD_TEST=false

# Dashboard
DASHBOARD_NAME="Media Portal"
DASHBOARD_COLOR="#4ECDC4"
DASHBOARD_STYLE=modern,sleek,minimal
DASHBOARD_ORDER=LBL:Media,JEL,PLX,VIS,LBL:Requests,SEE,VIS,LBL:Content,SON,RAD,LID,VIS,LBL:Tools,BAZ,TAU
DASHBOARD_LANDING=jellyfin

# Google OAuth authentication
AUTHTYPE=google
GOOGLE_CLIENT_ID=xxxxxxxxxxxx-yyyyyyyyyyyyyyyy.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Core services (Docker)
JELLYFIN_ENABLED=true
JELLYFIN_URL=http://jellyfin:8096

PLEX_ENABLED=true
PLEX_URL=http://plex:32400
PLEX_DOMAIN=plex.example.com

# Content managers
SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989
SONARR_API_KEY=sonarr-api-key

RADARR_ENABLED=true
RADARR_URL=http://radarr:7878
RADARR_API_KEY=radarr-api-key

LIDARR_ENABLED=true
LIDARR_URL=http://lidarr:8686
LIDARR_API_KEY=lidarr-api-key

# Requests
SEERR_ENABLED=true
SEERR_URL=http://seerr:5055
SEERR_API_KEY=seerr-api-key
SEERR_DOMAIN=seerr.example.com

# Tools
BAZARR_ENABLED=true
BAZARR_URL=http://bazarr:6767
BAZARR_API_KEY=bazarr-api-key

TAUTULLI_ENABLED=true
TAUTULLI_URL=http://tautulli:8181
TAUTULLI_API_KEY=tautulli-api-key

# Not using: Torrents/Usenet
TZ=UTC
```

### Example 3: Mixed Services (Docker + External LAN)

```bash
# Docker services + external LAN applications
ACCESS_MODE=public
DOMAIN=myserver.example.com
EMAIL=webadmin@example.com

# Services on Docker network
SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989
SONARR_API_KEY=docker-sonarr-key

RADARR_ENABLED=true
RADARR_URL=http://radarr:7878
RADARR_API_KEY=docker-radarr-key

# External services on LAN
JELLYFIN_ENABLED=true
JELLYFIN_URL=http://192.168.1.50:8096

TRANSMISSION_ENABLED=true
TRANSMISSION_URL=http://192.168.1.51:9091

PROWLARR_ENABLED=true
PROWLARR_URL=http://192.168.1.52:9696
PROWLARR_API_KEY=prowlarr-key

# Basic auth + custom dashboard
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=owner:password123|family:password456

DASHBOARD_NAME="Family Media"
DASHBOARD_STYLE=modern:only
DASHBOARD_SITES=YTS,TPB,DOG
```

For service-specific setup details, see [SERVICES.md](SERVICES.md).
