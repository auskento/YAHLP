# Environment Variables Reference

Complete reference guide for all environment variables supported by YAHLP.

## Deployment Mode

### ACCESS_MODE
- **Type:** String (public or private)
- **Default:** `public`
- **Description:** Deployment mode that determines certificate generation and feature availability
- **Options:**
  - `public`: Internet-facing deployment with Let's Encrypt HTTPS (requires DOMAIN and EMAIL)
  - `private`: Internal-only, HTTP-only deployment without certificates (requires IP instead; DOMAIN/EMAIL are cleared and unused)
- **Note:** In private mode, only `none` or `basic` authentication types are supported

## Required Variables (Public Mode Only)

For `ACCESS_MODE=public`, these **must** be set:

### DOMAIN
- **Type:** String
- **Example:** `yourdomain.com`
- **Description:** Your domain name for Let's Encrypt SSL certificate
- **Default:** `example.com`
- **Note:** Must be a valid registered domain with DNS pointing to your server
- **Required for:** `ACCESS_MODE=public` only

### EMAIL
- **Type:** String
- **Example:** `admin@example.com`
- **Description:** Email address for Let's Encrypt certificate notifications
- **Default:** `admin@example.com`
- **Note:** You'll receive renewal notifications at this email
- **Required for:** `ACCESS_MODE=public` only

## Required Variables (Private Mode Only)

### IP
- **Type:** String
- **Example:** `192.168.9.244`
- **Description:** The LAN IP address of the host, used to rewrite service backend URLs (e.g. `https://example.com` placeholders become `http://<IP>`) since no certificate/domain is used in private mode
- **Required for:** `ACCESS_MODE=private` only (the container exits with an error at startup if not provided)

### TEST
- **Type:** Boolean (`true` or `false`)
- **Default:** `false`
- **Description:** When `true`, passes `--dry-run` to Certbot so no real Let's Encrypt certificate is issued (useful for testing the public-mode flow without hitting rate limits)

---

## Optional Settings

### Timezone
- **Variable:** `TZ`
- **Type:** String
- **Default:** `Australia/Melbourne`
- **Example:** `Australia/Sydney`, `UTC`, `US/Eastern`
- **Description:** Container timezone for logs and cron jobs

### SSL/Security
- **Variable:** `SSL_PROTOCOLS`
- **Type:** String
- **Default:** `all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1`
- **Description:** Allowed SSL/TLS versions

- **Variable:** `SSL_CIPHERS`
- **Type:** String
- **Default:** `HIGH:!aNULL:!MD5`
- **Description:** Allowed SSL cipher suites

### Dashboard Customization
- **Variable:** `DASH_STYLE`
- **Type:** String (classic, modern, sleek, minimal, or mobile)
- **Default:** `modern`
- **Description:** Dashboard visual style used as the default (`index.html` / Apache `DirectoryIndex`). All layouts are generated as separate pages (`/classic.html`, `/modern.html`, `/sleek.html`, `/minimal.html`, `/mobile.html`) with a style switcher in the UI so users can freely swap between them.
- **Options:**
  - `classic`: Original sidebar menu layout
  - `modern`: Full-featured layout (recommended)
  - `sleek`: Compact sidebar with gradient styling
  - `minimal`: Minimal single-column design
  - `mobile`: Layout optimized for small screens (always generated regardless of setting)
- **Advanced forms:**
  - `classic:only` — build and lock the dashboard to a single style; disables the in-page style switcher
  - `classic,modern,sleek` — comma-separated list builds only those styles and shows only them in the switcher (the first one listed becomes the default)
- **Note:** Basic authentication (`AUTHTYPE=basic`) forces `DASH_STYLE=classic` automatically, since the other layouts require session management that basic auth doesn't provide.

- **Variable:** `DASHBOARD_THEME`
- **Type:** String (dark or light)
- **Default:** `dark`
- **Description:** Color theme applied to the dashboard UI

- **Variable:** `DASHBOARD_NAME`
- **Type:** String
- **Default:** `YAHLP`
- **Description:** Display name shown in dashboard header and page title
- **Example:** `My Homelab`, `Family Media`, `Media Center`

- **Variable:** `DASHBOARD_COLOR`
- **Type:** String (6-digit hex code)
- **Default:** `#1a1a1a`
- **Description:** Menu/dashboard background color. Only applies to the built-in layouts (classic/modern/sleek/minimal/mobile); custom user-supplied layouts render their own colors and are left at their CSS default.

- **Variable:** `DASHBOARD_ICON_URL`
- **Type:** URL
- **Default:** Empty (uses bundled `/icons/yahlp.png`, or a custom `/icons/dashboard-custom.*` file if present)
- **Description:** Optional URL to download a custom dashboard header icon. Downloaded and resized like the per-service `ICON_URL_*` variables.
- **Examples:** `https://example.com/logo.png`
- **Note:** Place custom icon files directly in the icons directory using the `dashboard-custom.<ext>` naming convention as an alternative to a download URL.

- **Variable:** `DASHBOARD_LANDING`
- **Type:** String (service path or empty)
- **Default:** Empty (shows welcome screen)
- **Description:** Default page to load in the dashboard on startup. If the first path segment matches `sonarr`, `radarr`, `lidarr`, or `whisparr`, it also seeds that service's own `*_LANDING` variable (see below) as a convenience default.
- **Examples:** `sonarr/calendar`, `radarr`, `plex/web`

- **Variable:** `SONARR_LANDING` / `RADARR_LANDING` / `LIDARR_LANDING` / `WHISPARR_LANDING`
- **Type:** String (path, or empty)
- **Default:** Empty (falls back to the service's own root, e.g. `/sonarr/`, and to `DASHBOARD_LANDING` if that matches the service)
- **Description:** Overrides the dashboard menu icon's link target for that specific service, letting it deep-link to a subpage (e.g. `/sonarr/series` instead of `/sonarr/`)
- **Note:** Values are normalized to always start and end with `/`

- **Variable:** `DASHBOARD_ORDER`
- **Type:** String (comma-separated 3-letter service codes, plus optional separator tokens)
- **Default:** `SAB,GET,HYD,TRA,QBI,DEL,SON,RAD,LID,WHI,PRO,SEE,BAZ,JEL,EMB,PLX,TAU,MNT`
- **Description:** Order in which to display services on the dashboard
- **Special tokens:**
  - `SEP` — invisible gap separator
  - `VIS` — visible line separator
  - `LBL:Some Label` — labeled separator / section header
- **Examples:** 
  - `SAB,GET,HYD,TRA,QBI,DEL,SON,RAD,LID,WHI,PRO,SEE,BAZ,JEL,EMB,PLX,TAU,MNT` (default order)
  - `JEL,EMB,PLX,TAU,MNT,SON,RAD,LID,WHI,PRO,SEE,BAZ,SAB,GET,HYD,TRA,QBI,DEL` (media servers first)
  - `SAB,GET,HYD,TRA,QBI,DEL` (only download clients)
  - `LBL:Downloads,SAB,GET,HYD,VIS,LBL:Media,JEL,EMB,PLX` (with section headers and a visible separator)
- **Note:** Use 3-letter codes (see Service Codes Reference below). Codes must be comma-separated with no extra spaces. Only enabled services are displayed; unrecognized codes are silently skipped.

- **Variable:** `SITES_ENABLED`
- **Type:** String (comma-separated 3-letter site codes)
- **Default:** Empty (sites disabled)
- **Description:** Quick-link shortcuts for torrent and usenet indexer sites
- **Available Torrent Sites:** TPB, FIL, HDB, IPT, 1337, YTS, LAT, NYA, PTP
- **Available Usenet Sites:** DOG, DRS, NLF, NFW, NGK, PLA, TAB
- **Examples:**
  - `SITES_ENABLED=TPB,FIL,HDB,DOG,DRS` (5 popular sites)
  - `SITES_ENABLED=TPB,FIL,HDB,IPT,1337,YTS,LAT,NYA,PTP,DOG,DRS,NLF` (all sites)
  - `SITES_ENABLED=` (disabled)
- **Note:** See **[SITES-CONFIGURATION.md](SITES-CONFIGURATION.md)** for complete site documentation and setup

### Authentication
- **Variable:** `AUTHTYPE`
- **Type:** String (none, basic, entra, or google)
- **Default:** `none`
- **Description:** Authentication method for dashboard access
- **Options:**
  - `none`: No authentication required
  - `basic`: Simple username/password authentication (forces `DASH_STYLE=classic`)
  - `entra`: Microsoft Entra ID (Azure AD) OAuth
  - `google`: Google OAuth2
- **Note:** In private deployments (`ACCESS_MODE=private`), only `none` and `basic` are supported

---

## Service Configuration (18 Services)

### Service Codes Reference

All services use 3-letter codes for dashboard configuration. The `DASHBOARD_ORDER` variable accepts these codes:

| Code | Service |
|------|---------|
| SAB | SABnzbd |
| GET | NZBGet |
| HYD | NZBHydra |
| TRA | Transmission |
| QBI | qBittorrent |
| DEL | Deluge |
| SON | Sonarr |
| RAD | Radarr |
| LID | Lidarr |
| WHI | Whisparr |
| PRO | Prowlarr |
| SEE | Seerr |
| BAZ | Bazarr |
| JEL | Jellyfin |
| EMB | Emby |
| PLX | Plex |
| TAU | Tautulli |
| MNT | Maintainerr |

### Enable/Disable Services

For each service, use `ENABLE_*` variables:

```
ENABLE_SONARR=true/false        # SON
ENABLE_RADARR=true/false        # RAD
ENABLE_LIDARR=true/false        # LID
ENABLE_WHISPARR=true/false      # WHI
ENABLE_PROWLARR=true/false      # PRO
ENABLE_SEERR=true/false         # SEE
ENABLE_BAZARR=true/false        # BAZ
ENABLE_SABNZBD=true/false       # SAB
ENABLE_NZBGET=true/false        # GET
ENABLE_NZBHYDRA=true/false      # HYD
ENABLE_TRANSMISSION=true/false  # TRA
ENABLE_QBITTORRENT=true/false   # QBI
ENABLE_DELUGE=true/false        # DEL
ENABLE_JELLYFIN=true/false      # JEL
ENABLE_EMBY=true/false          # EMB
ENABLE_PLEX=true/false          # PLX
ENABLE_TAUTULLI=true/false      # TAU
ENABLE_MAINTAINERR=true/false   # MNT
```

**Type:** Boolean (`true` or `false`)  
**Default:** `false` (all disabled by default)  
**Description:** Enable the service to make it accessible through the proxy

---

### Service Backend URLs

For each enabled service, specify the backend address:

```
SONARR_URL=http://sonarr:8989
RADARR_URL=http://radarr:7878
LIDARR_URL=http://lidarr:8686
WHISPARR_URL=http://whisparr:6969
PROWLARR_URL=http://prowlarr:9696
SEERR_URL=http://seerr:5055
BAZARR_URL=http://bazarr:6767
SABNZBD_URL=http://sabnzbd:8080
NZBGET_URL=http://nzbget:6789
NZBHYDRA_URL=http://nzbhydra:5076
TRANSMISSION_URL=http://transmission:9091
QBITTORRENT_URL=http://qbittorrent:8080
DELUGE_URL=http://deluge:8112
JELLYFIN_URL=http://jellyfin:8096
EMBY_URL=http://emby:8096
PLEX_URL=http://plex:32400
TAUTULLI_URL=http://tautulli:8181
MAINTAINERR_URL=http://maintainerr:6246
```

**Type:** URL  
**Default:** Docker container name URLs (e.g., `http://sonarr:8989`)  
**Examples:**
- Local IP: `http://192.168.1.100:8989`
- Hostname: `http://sonarr.local:8989`
- Docker container: `http://sonarr:8989`

#### NZBGet Credentials

NZBGet has no URL-base setting, so YAHLP authenticates to it on the backend's behalf:

```
NZBGET_USER=""
NZBGET_PASS=""
```

If both are set, YAHLP injects a base64-encoded HTTP Basic `Authorization` header into the proxied request to NZBGet automatically.

#### Subdomain Services (Emby, Plex, Seerr)

Emby, Plex, and Seerr can optionally be served on their own subdomain (with their own Let's Encrypt certificate) instead of a subpath. This only applies in `ACCESS_MODE=public`:

```
EMBY_DOMAIN=emby.yourdomain.com
EMBY_REDIRECT_URI=https://emby.yourdomain.com/oauth2callback
PLEX_DOMAIN=plex.yourdomain.com
PLEX_REDIRECT_URI=https://plex.yourdomain.com/oauth2callback
SEERR_DOMAIN=seerr.yourdomain.com
SEERR_REDIRECT_URI=https://seerr.yourdomain.com/oauth2callback
```

- If `*_DOMAIN` is set (and `ACCESS_MODE=public`), the dashboard menu links to `https://<domain>/` and a dedicated Apache VirtualHost with its own certificate is generated for Emby/Plex.
- If `*_DOMAIN` is not set, the dashboard falls back to the plain `*_URL` value.
- In `ACCESS_MODE=private`, Emby/Plex always use `*_URL` directly regardless of `*_DOMAIN`.
- `*_REDIRECT_URI` is only needed when using `entra` or `google` OAuth with a subdomain, so that service gets its own OAuth callback separate from the main dashboard's.

---

### Service Icon URLs

Customize icons for each service:

```
ICON_URL_SONARR=
ICON_URL_RADARR=
ICON_URL_LIDARR=
ICON_URL_WHISPARR=
ICON_URL_PROWLARR=
ICON_URL_SEERR=
ICON_URL_BAZARR=
ICON_URL_SABNZBD=
ICON_URL_NZBGET=
ICON_URL_NZBHYDRA=
ICON_URL_TRANSMISSION=
ICON_URL_QBITTORRENT=
ICON_URL_DELUGE=
ICON_URL_JELLYFIN=
ICON_URL_EMBY=
ICON_URL_PLEX=
ICON_URL_TAUTULLI=
ICON_URL_MAINTAINERR=
```

**Type:** URL  
**Default:** Empty (uses bundled icons)  
**Examples:**
- `https://example.com/my-sonarr-icon.png`
- `https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png`

**Smart System:**
1. If custom URL provided → Downloads and resizes it to 100x100, saved as `<service>-custom.<ext>`
2. If custom URL fails to download → Falls back to the bundled default icon
3. If no custom URL → Uses the bundled default icon

See **[ICONS.md](ICONS.md)** for full details on the icon resolution and download mechanics.

---

## Google OAuth Configuration

### Important: Redirect URI Matching
The `GOOGLE_REDIRECT_URI` **must exactly match** the authorized redirect URI configured in your Google Cloud Console OAuth 2.0 credentials. If they don't match, you'll get an `Error 400: redirect_uri_mismatch`.

**Steps:**
1. Go to Google Cloud Console → Credentials → Your OAuth 2.0 Client ID
2. Find "Authorized redirect URIs" section
3. Note the exact URI (with any path included)
4. Set `GOOGLE_REDIRECT_URI` to match that exactly

**Examples:**
- If Google has: `https://example.com` → Use `GOOGLE_REDIRECT_URI=https://example.com`
- If Google has: `https://example.com/oauth2callback` → Use `GOOGLE_REDIRECT_URI=https://example.com/oauth2callback`

---

## Microsoft Entra ID (Azure AD) Authentication (Optional)

Set `AUTHTYPE=entra` to enable. There is no separate enable flag.

### Configuration
- **Variable:** `ENTRA_CLIENT_ID`
- **Type:** String
- **Description:** Entra ID (Azure AD) Application Client ID
- **Required if:** `AUTHTYPE=entra`

- **Variable:** `ENTRA_CLIENT_SECRET`
- **Type:** String
- **Description:** Entra ID (Azure AD) Application Client Secret
- **Required if:** `AUTHTYPE=entra`
- **Security:** Keep this secret!

- **Variable:** `ENTRA_PROVIDER_METADATA_URL`
- **Type:** URL
- **Description:** OpenID Connect discovery/metadata URL for your Entra tenant
- **Required if:** `AUTHTYPE=entra`

- **Variable:** `ENTRA_REDIRECT_URI`
- **Type:** URL
- **Default:** `https://yourdomain.com/auth/oauth2/callback`
- **Description:** OAuth2 callback URL (must match the redirect URI registered in Entra ID)

- **Variable:** `ENTRA_CRYPTO_PASSPHRASE`
- **Type:** String
- **Default:** Auto-generated at startup if empty
- **Description:** Session encryption passphrase (for security)

---

## Complete Example Configuration

### docker-compose.yml (Public Deployment)
```yaml
environment:
  # Deployment mode
  ACCESS_MODE: public
  
  # Required for Let's Encrypt HTTPS (public mode only)
  DOMAIN: yourdomain.com
  EMAIL: admin@yourdomain.com
  
  # Optional - Timezone and dashboard customization
  TZ: Australia/Melbourne
  DASH_STYLE: modern
  DASHBOARD_NAME: My Homelab
  DASHBOARD_ICON_URL: ""
  DASHBOARD_LANDING: sonarr/calendar
  
  # Authentication (note: basic auth forces DASH_STYLE=classic)
  AUTHTYPE: basic
  BASIC_AUTH_CREDENTIALS: "user1:password1|user2:password2"
  
  # Enable services you want
  ENABLE_SONARR: "true"
  ENABLE_RADARR: "true"
  ENABLE_JELLYFIN: "true"
  ENABLE_PLEX: "false"
  
  # Set backend URLs for enabled services
  SONARR_URL: http://sonarr:8989
  RADARR_URL: http://radarr:7878
  JELLYFIN_URL: http://jellyfin:8096
  
  # Optional custom icons (leave empty to use defaults)
  ICON_URL_SONARR: ""
  ICON_URL_RADARR: https://example.com/my-radarr-icon.png
  ICON_URL_JELLYFIN: ""
```

### docker-compose.yml (Private/Internal Deployment)
```yaml
environment:
  # Deployment mode - private disables certificate generation
  ACCESS_MODE: private
  
  # IP is required in private mode (used to rewrite backend URLs)
  IP: 192.168.9.244
  
  # Dashboard customization
  TZ: Australia/Melbourne
  DASH_STYLE: modern
  DASHBOARD_NAME: Family Media
  DASHBOARD_ICON_URL: ""
  DASHBOARD_LANDING: ""
  
  # Authentication - only none or basic allowed in private mode
  AUTHTYPE: basic
  BASIC_AUTH_CREDENTIALS: "user1:password1"
  
  # Services enabled (same as public mode)
  ENABLE_SONARR: "true"
  SONARR_URL: http://sonarr:8989
  ENABLE_RADARR: "true"
  RADARR_URL: http://radarr:7878
```

### .env File
```bash
# Deployment mode (public or private)
ACCESS_MODE=public

# Required for public deployments
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com

# Timezone
TZ=Australia/Melbourne

# Dashboard customization
DASH_STYLE=modern
DASHBOARD_NAME=My Homelab
DASHBOARD_ICON_URL=
DASHBOARD_LANDING=sonarr/calendar

# Authentication
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=user1:password1|user2:password2

# Services
ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989

ENABLE_RADARR=true
RADARR_URL=http://radarr:7878

# Icons (optional)
ICON_URL_SONARR=
ICON_URL_RADARR=https://example.com/radarr.png
```

---

## Environment Variable Validation

The entrypoint script validates at startup and exits with an error if:
- ✅ `ACCESS_MODE` is not `public` or `private`
- ✅ `IP` is missing when `ACCESS_MODE=private`
- ✅ `AUTHTYPE` is something other than `none`/`basic` when `ACCESS_MODE=private`
- ✅ `BASIC_AUTH_CREDENTIALS` is missing (or malformed) when `AUTHTYPE=basic`
- ✅ `ENTRA_CLIENT_ID` / `ENTRA_CLIENT_SECRET` / `ENTRA_PROVIDER_METADATA_URL` are missing when `AUTHTYPE=entra`
- ✅ `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` / `GOOGLE_REDIRECT_URI` are missing when `AUTHTYPE=google`

If validation fails, check the container logs:
```bash
docker-compose logs apache-reverse-proxy
```

---

## Setting Variables

### Method 1: docker-compose.yml
Edit the `environment:` section directly

### Method 2: .env File
Create a `.env` file in the project directory:
```bash
cp .env.example .env
# Edit .env with your values
```

### Method 3: Command Line
```bash
docker run \
  -e DOMAIN=yourdomain.com \
  -e EMAIL=admin@yourdomain.com \
  -e ENABLE_SONARR=true \
  auskento/apache-reverse-proxy:latest
```

### Method 4: Unraid Template
Fill in the form fields in Unraid UI (variables are passed automatically)

---

## Troubleshooting

### Variables Not Being Used
1. Check that you've restarted the container
2. Verify variables are in the correct `environment:` section
3. Check container logs: `docker-compose logs apache-reverse-proxy`
4. Look for `Domain: yourdomain.com` in startup output

### Wrong Domain Still Being Used
- Ensure `DOMAIN` is set to your actual domain
- Remove old containers: `docker-compose down`
- Rebuild: `docker-compose up -d`

### Services Not Proxying
- Check `ENABLE_*` variable is set to `true`
- Check `*_URL` variable is correct
- Verify backend service is running and accessible
- Check logs for errors

---

**For more YAHLP, see TROUBLESHOOTING.md**


