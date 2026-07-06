# Configuration Reference

Complete list of all environment variables and settings for YAHLP.

## Table of Contents
1. [Deployment](#deployment)
2. [Dashboard](#dashboard)
3. [Authentication](#authentication)
4. [Services](#services)
5. [Advanced](#advanced)

---

## Deployment

### ACCESS_MODE
- **Type:** `public` or `private`
- **Default:** `public`
- **Description:** Deployment mode
  - `public` - Internet-accessible, requires domain
  - `private` - Internal network only, uses internal IP

### DOMAIN
- **Type:** String (domain name)
- **Default:** Empty
- **Required for:** Public mode
- **Example:** `example.com` or `media.example.com`
- **Note:** Must have valid DNS pointing to your IP

### EMAIL
- **Type:** String (email address)
- **Default:** Empty
- **Required for:** Public mode (Let's Encrypt)
- **Example:** `admin@example.com`
- **Note:** Receives certificate renewal notifications

### IP
- **Type:** String (IPv4 address)
- **Default:** Empty
- **Required for:** Private mode
- **Example:** `192.168.1.100`
- **Note:** Internal network IP address

---

## Dashboard

### DASHBOARD_NAME
- **Type:** String
- **Default:** `YAHLP Dashboard`
- **Description:** Display name shown in header/browser tab
- **Example:** `My Media Server` or `HomeLab Portal`

### DASHBOARD_COLOR
- **Type:** Hex color code
- **Default:** `#00A99D`
- **Format:** `#RRGGBB`
- **Examples:** 
  - `#FF6B6B` - Red
  - `#4ECDC4` - Teal
  - `#95E1D3` - Mint
  - `#FFD93D` - Yellow

### DASHBOARD_STYLE
- **Type:** String (layout configuration)
- **Default:** `classic`
- **Options:**

| Format | Behavior | Example |
|--------|----------|---------|
| Single style | Build all, use as default | `modern` |
| Comma-separated | Build only those, show all in slider | `modern,sleek` |
| Style with `:only` | Build single, lock layout, hide slider | `modern:only` |

**Available Layouts:**
- `classic` - Sidebar with menu on left
- `modern` - API-inspired, sidebar + right panel
- `sleek` - Compact gradient design
- `minimal` - Single-column ultra-simple

**Examples:**
```bash
DASHBOARD_STYLE=modern           # All layouts, modern default
DASHBOARD_STYLE=modern,sleek     # Only modern/sleek in slider
DASHBOARD_STYLE=modern:only      # Lock to modern, hide switcher
```

### DASHBOARD_ORDER
- **Type:** Comma-separated 3-letter service codes
- **Default:** `JEL,PLX,EMB,SON,RAD,LID,WHI,QBI,TRA,SAB,GET,DEL,HYD,PRO,SEE,BAZ,TAU,MNT`
- **Description:** Order services appear in dashboard
- **Service codes:** JEL (Jellyfin), PLX (Plex), EMB (Emby), SON (Sonarr), RAD (Radarr), LID (Lidarr), WHI (Whisparr), QBI (qBittorrent), TRA (Transmission), SAB (SABnzbd), GET (NZBGet), DEL (Deluge), HYD (NZBHydra), PRO (Prowlarr), SEE (Seerr), BAZ (Bazarr), TAU (Tautulli), MNT (Maintainerr)
- **Examples:**
  ```bash
  DASHBOARD_ORDER=JEL,PLX,SON,RAD,QBI
  DASHBOARD_ORDER=TRA,QBI,SAB,GET,SON,RAD
  ```

### DASHBOARD_LANDING
- **Type:** String (service path)
- **Default:** Empty (shows service grid)
- **Description:** Default page when accessing dashboard
- **Examples:**
  ```bash
  DASHBOARD_LANDING=sonarr/calendar
  DASHBOARD_LANDING=radarr
  DASHBOARD_LANDING=jellyfin
  ```

### DASHBOARD_SITES
- **Type:** Comma-separated site codes
- **Default:** Empty
- **Description:** Built-in torrent/usenet sites to show
- **Available codes:**
  - **Torrent:** `TPB`, `FIL`, `HDB`, `IPT`, `1337`, `YTS`, `LAT`, `NYA`, `PTP`
  - **Usenet:** `DOG`, `DRS`, `NLF`, `NFW`, `NGK`, `PLA`, `TAB`
- **Example:**
  ```bash
  DASHBOARD_SITES=TPB,DOG,DRS,YTS
  ```

---

## Authentication

### AUTHTYPE
- **Type:** `none`, `basic`, `entra`, or `google`
- **Default:** `none`
- **Description:** Authentication method

| Type | Setup | Best For |
|------|-------|----------|
| `none` | No setup | Home network, trusted users |
| `basic` | Username/password | Simple authentication |
| `entra` | Microsoft Azure AD | Enterprise networks |
| `google` | Google OAuth 2.0 | Personal/small team |

### BASIC_AUTH_CREDENTIALS
- **Type:** String
- **Required for:** `AUTHTYPE=basic`
- **Format:** `username:password` or `user1:pass1\|user2:pass2`
- **Examples:**
  ```bash
  BASIC_AUTH_CREDENTIALS=admin:secretpassword
  BASIC_AUTH_CREDENTIALS=alice:pass123|bob:pass456|charlie:pass789
  ```

### ENTRA_CLIENT_ID
- **Type:** String (UUID)
- **Required for:** `AUTHTYPE=entra`
- **Description:** Azure application ID
- **Where to get:** Azure Portal → App registrations

### ENTRA_CLIENT_SECRET
- **Type:** String
- **Required for:** `AUTHTYPE=entra`
- **Description:** Azure application secret
- **Where to get:** Azure Portal → Client credentials

### ENTRA_REDIRECT_URI
- **Type:** URL
- **Required for:** `AUTHTYPE=entra`
- **Format:** `https://yourdomain.com/auth/oauth2/callback`

### ENTRA_PROVIDER_METADATA_URL
- **Type:** URL
- **Required for:** `AUTHTYPE=entra`
- **Format:** `https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration`

### GOOGLE_CLIENT_ID
- **Type:** String
- **Required for:** `AUTHTYPE=google`
- **Description:** Google OAuth 2.0 Client ID
- **Where to get:** Google Cloud Console

### GOOGLE_CLIENT_SECRET
- **Type:** String
- **Required for:** `AUTHTYPE=google`
- **Description:** Google OAuth 2.0 Client Secret
- **Where to get:** Google Cloud Console

### GOOGLE_REDIRECT_URI
- **Type:** URL
- **Required for:** `AUTHTYPE=google`
- **Format:** `https://yourdomain.com` (must match Google Console)

See [AUTHENTICATION.md](AUTHENTICATION.md) for detailed setup.

---

## Services

Each service has:
- **ENABLE_{SERVICE}** - Enable/disable the service
- **{SERVICE}_URL** - Internal URL to service
- **{SERVICE}_API_KEY** - API key (if needed)
- **{SERVICE}_USERNAME** / **{SERVICE}_PASSWORD** - Credentials (if needed)

### Content Services

#### Sonarr (SON)
```bash
ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989
SONARR_API_KEY=your-api-key  # Optional
SONARR_LANDING=sonarr/calendar  # Optional
```

#### Radarr (RAD)
```bash
ENABLE_RADARR=true
RADARR_URL=http://radarr:7878
RADARR_API_KEY=your-api-key  # Optional
RADARR_LANDING=radarr  # Optional
```

#### Lidarr (LID)
```bash
ENABLE_LIDARR=true
LIDARR_URL=http://lidarr:8686
LIDARR_API_KEY=your-api-key  # Optional
```

#### Whisparr (WHI)
```bash
ENABLE_WHISPARR=true
WHISPARR_URL=http://whisparr:6969
WHISPARR_API_KEY=your-api-key  # Optional
```

### Search Services

#### Seerr (SEE)
```bash
ENABLE_SEERR=true
SEERR_URL=http://seerr:5055
SEERR_API_KEY=your-api-key  # Optional
SEERR_DOMAIN=seerr.example.com  # For public subdomain
```

#### Prowlarr (PRO)
```bash
ENABLE_PROWLARR=true
PROWLARR_URL=http://prowlarr:9696
PROWLARR_API_KEY=your-api-key  # Optional
```

#### Bazarr (BAZ)
```bash
ENABLE_BAZARR=true
BAZARR_URL=http://bazarr:6767
BAZARR_API_KEY=your-api-key  # Optional
```

### Usenet Services

#### SABnzbd (SAB)
```bash
ENABLE_SABNZBD=true
SABNZBD_URL=http://sabnzbd:8080
SABNZBD_API_KEY=your-api-key  # Optional
```

#### NZBGet (GET)
```bash
ENABLE_NZBGET=true
NZBGET_URL=http://nzbget:6789
NZBGET_API_KEY=your-api-key  # Optional
```

#### NZBHydra (HYD)
```bash
ENABLE_NZBHYDRA=true
NZBHYDRA_URL=http://nzbhydra:5076
NZBHYDRA_API_KEY=your-api-key  # Optional
```

### Torrent Services

#### Transmission (TRA)
```bash
ENABLE_TRANSMISSION=true
TRANSMISSION_URL=http://transmission:6969
# No auth by default
```

#### qBittorrent (QBI)
```bash
ENABLE_QBITTORRENT=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=your-api-key  # Required
```

#### Deluge (DEL)
```bash
ENABLE_DELUGE=true
DELUGE_URL=http://deluge:8112
DELUGE_PASSWORD=your-password  # Required
```

### Media Services

#### Jellyfin (JEL)
```bash
ENABLE_JELLYFIN=true
JELLYFIN_URL=http://jellyfin:8096
JELLYFIN_API_KEY=your-api-key  # Optional
```

#### Emby (EMB)
```bash
ENABLE_EMBY=true
EMBY_URL=http://emby:8096
EMBY_API_KEY=your-api-key  # Optional
EMBY_DOMAIN=emby.example.com  # For public subdomain
```

#### Plex (PLX)
```bash
ENABLE_PLEX=true
PLEX_URL=http://plex:32400
PLEX_API_KEY=your-api-key  # Optional
PLEX_DOMAIN=plex.example.com  # For public subdomain
```

#### Tautulli (TAU)
```bash
ENABLE_TAUTULLI=true
TAUTULLI_URL=http://tautulli:8181
TAUTULLI_API_KEY=your-api-key  # Optional
```

#### Maintainerr (MNT)
```bash
ENABLE_MAINTAINERR=true
MAINTAINERR_URL=http://maintainerr:6246
MAINTAINERR_API_KEY=your-api-key  # Optional
```

See [SERVICES.md](SERVICES.md) for detailed service setup.

---

## Advanced

### TEST
- **Type:** `true` or `false`
- **Default:** `false`
- **Description:** Use Let's Encrypt staging (dry-run mode)
- **Use Case:** Testing without hitting rate limits

### PUID / PGID
- **Type:** Integer (user/group IDs)
- **Default:** `99` / `100`
- **Description:** Docker user IDs for volume permissions
- **Note:** Only change if you have custom Unraid user setup

### TZ
- **Type:** Timezone string
- **Default:** `UTC`
- **Examples:** `America/New_York`, `Europe/London`, `Asia/Tokyo`
- **Reference:** [List of timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

---

## Configuration Priority

YAHLP uses three-tier configuration (highest to lowest priority):

1. **Environment Variables** (passed to Docker)
2. **yahlp.json5** (config file in `/etc/yahlp/`)
3. **Defaults** (built-in)

Example: If both env var and JSON5 set a value, env var wins.

---

## Complete Example

```bash
# Deployment
ACCESS_MODE=public
DOMAIN=media.example.com
EMAIL=admin@example.com

# Dashboard
DASHBOARD_NAME="My Media Server"
DASHBOARD_COLOR="#FF6B6B"
DASHBOARD_STYLE=modern,sleek
DASHBOARD_ORDER=JEL,PLX,SON,RAD,QBI,SAB
DASHBOARD_LANDING=jellyfin

# Services
ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989

ENABLE_RADARR=true
RADARR_URL=http://radarr:7878

ENABLE_JELLYFIN=true
JELLYFIN_URL=http://jellyfin:8096

ENABLE_QBITTORRENT=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=abc123def456

# Authentication
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=user:password123

# Sites
DASHBOARD_SITES=TPB,YTS,DOG,DRS
```

See individual service docs for complete examples.
