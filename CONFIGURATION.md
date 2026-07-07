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
- `classic` - Topbar with services listed horizontally
- `modern` - Left sidebar, API-inspired design
- `sleek` - Left sidebar, compact gradient design
- `minimal` - Left sidebar, ultra-simple single-column
- Plus any **custom layouts** from `/templates` folder (see below)

**Examples:**
```bash
DASHBOARD_STYLE=modern           # All layouts, modern default
DASHBOARD_STYLE=modern,sleek     # Only modern/sleek in slider
DASHBOARD_STYLE=modern:only      # Lock to modern, hide switcher
DASHBOARD_STYLE=modern,custom1   # Built-in modern + custom1 layout
```

### DASHBOARD_ORDER
- **Type:** Comma-separated 3-letter service codes with optional separators
- **Default:** `SAB,GET,HYD,TRA,QBI,DEL,PRO,JAC,SON,RAD,LID,WHI,SEE,BAZ,TAU,MNT,JEL,PLX,EMB`
- **Description:** Order services appear in dashboard
- **Service codes:** SAB (SABnzbd), GET (NZBGet), HYD (NZBHydra), TRA (Transmission), QBI (qBittorrent), DEL (Deluge), PRO (Prowlarr), JAC (Jackett), SON (Sonarr), RAD (Radarr), LID (Lidarr), WHI (Whisparr), SEE (Seerr), BAZ (Bazarr), TAU (Tautulli), MNT (Maintainerr), JEL (Jellyfin), PLX (Plex), EMB (Emby)
- **Special codes:**
  - `SEP` - Invisible separator/spacing gap
  - `VIS` - Visible separator line
  - `LBL:SectionName` - Labeled section header (e.g., `LBL:Media Servers`)
- **Examples:**
  ```bash
  DASHBOARD_ORDER=JEL,PLX,SON,RAD,QBI
  DASHBOARD_ORDER=LBL:Media,JEL,PLX,SEP,LBL:Content,SON,RAD,SEP,LBL:Downloads,QBI,TRA,SAB
  DASHBOARD_ORDER=JEL,PLX,VIS,SON,RAD,VIS,QBI,TRA,SAB
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

### ENTRA_CRYPTO_PASSPHRASE
- **Type:** String (base64 passphrase)
- **Required for:** `AUTHTYPE=entra`
- **Default:** Auto-generated on first run
- **Description:** Encrypts session cookies for OAuth2 sessions
- **When to set:**
  - Leave empty for auto-generation (recommended)
  - Set if you need persistent passphrase across container restarts
- **Generate:** `openssl rand -base64 24`
- **Example:**
  ```bash
  ENTRA_CRYPTO_PASSPHRASE=abc123def456ghi789jkl012mnopqrstuv=
  ```

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

### Search Services

#### Prowlarr (PRO)
```bash
ENABLE_PROWLARR=true
PROWLARR_URL=http://prowlarr:9696
PROWLARR_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_PROWLARR=  # Optional custom icon URL
```

#### Jackett (JAC)
```bash
ENABLE_JACKETT=true
JACKETT_URL=http://jackett:9117
JACKETT_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_JACKETT=  # Optional custom icon URL
```

#### Sonarr (SON)
```bash
ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989
SONARR_API_KEY=your-api-key  # Optional
SONARR_LANDING=sonarr/calendar  # Optional
SERVICE_ICON_URL_SONARR=  # Optional custom icon URL
```

#### Radarr (RAD)
```bash
ENABLE_RADARR=true
RADARR_URL=http://radarr:7878
RADARR_API_KEY=your-api-key  # Optional
RADARR_LANDING=radarr  # Optional
SERVICE_ICON_URL_RADARR=  # Optional custom icon URL
```

#### Lidarr (LID)
```bash
ENABLE_LIDARR=true
LIDARR_URL=http://lidarr:8686
LIDARR_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_LIDARR=  # Optional custom icon URL
```

#### Whisparr (WHI)
```bash
ENABLE_WHISPARR=true
WHISPARR_URL=http://whisparr:6969
WHISPARR_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_WHISPARR=  # Optional custom icon URL
```

### Infrastructure Services

#### Seerr (SEE)
```bash
ENABLE_SEERR=true
SEERR_URL=http://seerr:5055
SEERR_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_SEERR=  # Optional custom icon URL
```

#### Bazarr (BAZ)
```bash
ENABLE_BAZARR=true
BAZARR_URL=http://bazarr:6767
BAZARR_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_BAZARR=  # Optional custom icon URL
```

#### Tautulli (TAU)
```bash
ENABLE_TAUTULLI=true
TAUTULLI_URL=http://tautulli:8181
TAUTULLI_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_TAUTULLI=  # Optional custom icon URL
```

#### Maintainerr (MNT)
```bash
ENABLE_MAINTAINERR=true
MAINTAINERR_URL=http://maintainerr:6246
MAINTAINERR_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_MAINTAINERR=  # Optional custom icon URL
```

### Usenet Services

#### SABnzbd (SAB)
```bash
ENABLE_SABNZBD=true
SABNZBD_URL=http://sabnzbd:8080
SABNZBD_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_SABNZBD=  # Optional custom icon URL
```

#### NZBGet (GET)
```bash
ENABLE_NZBGET=true
NZBGET_URL=http://nzbget:6789
NZBGET_USERNAME=your-username  # Optional
NZBGET_PASSWORD=your-password  # Optional
SERVICE_ICON_URL_NZBGET=  # Optional custom icon URL
```

#### NZBHydra (HYD)
```bash
ENABLE_NZBHYDRA=true
NZBHYDRA_URL=http://nzbhydra:5076
NZBHYDRA_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_NZBHYDRA=  # Optional custom icon URL
```

### Torrent Services

#### Transmission (TRA)
```bash
ENABLE_TRANSMISSION=true
TRANSMISSION_URL=http://transmission:6969
SERVICE_ICON_URL_TRANSMISSION=  # Optional custom icon URL
# No auth by default
```

#### qBittorrent (QBI)
```bash
ENABLE_QBITTORRENT=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=your-api-key  # Required
SERVICE_ICON_URL_QBITTORRENT=  # Optional custom icon URL
```

#### Deluge (DEL)
```bash
ENABLE_DELUGE=true
DELUGE_URL=http://deluge:8112
DELUGE_PASSWORD=your-password  # Required
SERVICE_ICON_URL_DELUGE=  # Optional custom icon URL
```

### Media Services

#### Jellyfin (JEL)
```bash
ENABLE_JELLYFIN=true
JELLYFIN_URL=http://jellyfin:8096
JELLYFIN_API_KEY=your-api-key  # Optional
SERVICE_ICON_URL_JELLYFIN=  # Optional custom icon URL
```

#### Emby (EMB)
```bash
ENABLE_EMBY=true
EMBY_URL=http://emby:8096
EMBY_API_KEY=your-api-key  # Optional
EMBY_DOMAIN=emby.example.com  # For public subdomain
EMBY_REDIRECT_URI=https://emby.example.com/oauth2callback  # For Google/Entra OAuth
SERVICE_ICON_URL_EMBY=  # Optional custom icon URL
```

#### Plex (PLX)
```bash
ENABLE_PLEX=true
PLEX_URL=http://plex:32400
PLEX_API_KEY=your-api-key  # Optional
PLEX_DOMAIN=plex.example.com  # For public subdomain
PLEX_REDIRECT_URI=https://plex.example.com/oauth2callback  # For Google/Entra OAuth
SERVICE_ICON_URL_PLEX=  # Optional custom icon URL
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
DASHBOARD_ORDER=SAB,QBI,PRO,JAC,SON,RAD,JEL,PLX
DASHBOARD_LANDING=jellyfin

# Services (Usenet)
ENABLE_SABNZBD=true
SABNZBD_URL=http://sabnzbd:8080
SABNZBD_API_KEY=abc123def456

# Services (Torrents)
ENABLE_QBITTORRENT=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=xyz789abc123

# Services (Search)
ENABLE_PROWLARR=true
PROWLARR_URL=http://prowlarr:9696
PROWLARR_API_KEY=prowlarr-key-123

ENABLE_JACKETT=true
JACKETT_URL=http://jackett:9117
JACKETT_API_KEY=jackett-key-456

ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989
SONARR_API_KEY=sonarr-key-789

ENABLE_RADARR=true
RADARR_URL=http://radarr:7878
RADARR_API_KEY=radarr-key-012

# Services (Media)
ENABLE_JELLYFIN=true
JELLYFIN_URL=http://jellyfin:8096

ENABLE_PLEX=true
PLEX_URL=http://plex:32400

# Authentication
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=user:password123

# Sites
DASHBOARD_SITES=TPB,YTS,DOG,DRS
```

See individual service docs for complete examples.
