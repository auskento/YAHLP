# YAHLP Configuration Guide

## Overview

YAHLP uses JSON5 configuration files to manage all settings. JSON5 is an extension of JSON that allows comments, making configuration more maintainable.

**Configuration files are the primary source** — environment variables can override any value.

## Configuration Files

### yahlp.json5 (Main Configuration)

This is the primary configuration file for YAHLP. It defines:
- Dashboard UI settings
- API service URLs and credentials
- Service enable/disable flags
- Service-specific options (icon URLs, domain names, etc.)
- Authentication methods
- Access mode (private/localhost or public/domain-based)

**Location in Docker:** `/etc/yahlp/yahlp.json5`

**Mount in Docker Compose:**
```yaml
volumes:
  - ./yahlp.json5:/etc/yahlp/yahlp.json5:ro
```

### sites.json5 (Quick Links)

This file defines the quick link sites displayed in the dashboard sidebar.

**Location in Docker:** `/etc/yahlp/sites.json5`

**Mount in Docker Compose:**
```yaml
volumes:
  - ./sites.json5:/etc/yahlp/sites.json5:ro
```

## Configuration Structure

### Dashboard Settings

```json5
{
  dashboard: {
    name: 'My Dashboard',                 // Display name
    icon_url: 'https://...',              // Logo/icon URL
    color: '#00A99D',                     // Primary color (hex)
    theme: 'dark',                        // 'dark' or 'light'
    style: 'classic',                     // Layout style (see below)
    landing: 'dashboard',                 // 'dashboard' or 'welcome'
    order: [
      'JEL', 'SON', 'RAD',    // Service display order (3-letter codes)
      'SEE', 'QBI', 'DEL',
    ],
  },
}
```

**Dashboard Order:**
The `order` array controls the sequence services appear on the dashboard. Only enabled services will be displayed. Use 3-letter service codes to specify the order.

**Service Codes:**
```
JEL = Jellyfin          PLX = Plex              EMB = Emby
SON = Sonarr            RAD = Radarr            LID = Lidarr            WHI = Whisparr
QBI = qBittorrent       TRA = Transmission
SAB = SABnzbd           GET = NZBGet            DEL = Deluge
HYD = NZBHydra          PRO = Prowlarr          SEE = Seerr
BAZ = Bazarr            TAU = Tautulli          MNT = Maintainerr
```

**Available Styles:**
- `classic` — Sidebar with services and quick links
- `modern` — Right sidebar with modern design
- `sleek` — Sleek right-sidebar with subtle styling
- `minimal` — Minimal interface
- `neon` — Neon/cyberpunk with glowing effects
- `focus` — Icon-only minimalist view
- Custom templates: `vixens`, `storm`, `storm-violet`, or custom names

### Access Configuration

**Private Mode (Localhost Only):**
```json5
{
  access: {
    mode: 'private',                // Accessible only locally on HTTP
  },
}
```

**Public Mode (Domain with HTTPS):**
```json5
{
  access: {
    mode: 'public',                 // Domain-based with HTTPS via Let's Encrypt
    domain: 'dashboard.example.com', // Required for public mode
    email: 'admin@example.com',     // Required for Let's Encrypt registration
  },
}
```

When mode is 'public':
- SSL certificate is automatically provisioned via Let's Encrypt
- Email is used for certificate registration and renewal notifications

### Authentication

**No Authentication (Default):**
```json5
{
  auth: {
    type: 'none',
  },
}
```

**Basic Authentication:**
```json5
{
  auth: {
    type: 'basic',
    basic_credentials: 'username:password',
  },
}
```

**Google OAuth:**
```json5
{
  auth: {
    type: 'google',
  },
  google: {
    client_id: '...',
    client_secret: '...',
    redirect_uri: 'http://localhost:3000/auth/callback',
  },
}
```

**Entra/Azure AD:**
```json5
{
  auth: {
    type: 'entra',
  },
  entra: {
    client_id: '...',
    client_secret: '...',
    redirect_uri: 'http://localhost:3000/auth/callback',
    provider_metadata_url: 'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration',
    crypto_passphrase: 'your-secret',
  },
}
```

## Service Configuration

Each service has these common fields:
- `enabled` — boolean to enable/disable the service
- `url` — Service URL
- `icon_url` — Icon displayed in dashboard
- Other fields depend on service type (api_key, username, password, etc.)

### Service-Specific Configuration

#### Media Servers

**Jellyfin:**
```json5
{
  jellyfin: {
    enabled: true,
    url: 'http://jellyfin.local:8096',
    api_key: 'your-api-key',
    icon_url: 'https://jellyfin.org/images/logo.svg',
  },
}
```

**Plex** (requires domain_name and redirect_uri):
```json5
{
  plex: {
    enabled: true,
    url: 'http://plex.local:32400',
    api_key: 'your-api-key',
    icon_url: 'https://plex.tv/favicon.ico',
    domain_name: 'plex.example.com',
    redirect_uri: 'http://localhost:3000/auth/plex/callback',
  },
}
```

**Emby** (requires domain_name and redirect_uri):
```json5
{
  emby: {
    enabled: true,
    url: 'http://emby.local:8096',
    api_key: 'your-api-key',
    icon_url: 'https://emby.media/favicon.ico',
    domain_name: 'emby.example.com',
    redirect_uri: 'http://localhost:3000/auth/emby/callback',
  },
}
```

#### PVR Services

PVR services support an optional `landing` option to set the default page/path when opening:

**Sonarr:**
```json5
{
  sonarr: {
    enabled: true,
    url: 'http://sonarr.local:8989',
    api_key: 'your-api-key',
    icon_url: 'https://sonarr.tv/favicon.ico',
    landing: 'calendar', // Opens to /calendar by default, not /
  },
}
```

**Examples:**
- Sonarr: `'calendar'` → opens to `sonarr/calendar`
- Radarr: `'movies'` or `'history'` → opens to that path
- Lidarr: `'albums'` or `'wanted'` → opens to that path
- Whisparr: Similar path options as Sonarr

**Radarr, Lidarr, Whisparr** — Same structure as Sonarr with optional `landing` path.

#### Download Clients

**qBittorrent** (requires username + password):
```json5
{
  qbittorrent: {
    enabled: true,
    url: 'http://qbittorrent.local:8080',
    username: 'admin',
    password: 'password',
    icon_url: 'https://qbittorrent.org/favicon.ico',
  },
}
```

**Transmission** (URL only, no authentication):
```json5
{
  transmission: {
    enabled: true,
    url: 'http://transmission.local:6969',
    icon_url: 'https://transmissionbt.com/favicon.ico',
  },
}
```

**NZBGet** (requires username + password):
```json5
{
  nzbget: {
    enabled: true,
    url: 'http://nzbget.local:6789',
    username: 'nzbget',
    password: 'tegbzn6789',
    icon_url: 'https://nzbget.net/favicon.ico',
  },
}
```

**Deluge** (requires password):
```json5
{
  deluge: {
    enabled: true,
    url: 'http://deluge.local:8112',
    password: 'password',
    icon_url: 'https://deluge-torrent.org/favicon.ico',
  },
}
```

**SABnzbd, NZBHydra, Prowlarr, Seerr, Bazarr, Tautulli, Maintainerr** — All require API key.

#### Seerr (requires domain_name and redirect_uri):
```json5
{
  seerr: {
    enabled: true,
    url: 'http://seerr.local:5055',
    api_key: 'your-api-key',
    icon_url: 'https://seerr.dev/favicon.ico',
    domain_name: 'seerr.example.com',
    redirect_uri: 'http://localhost:3000/auth/seerr/callback',
  },
}
```

## Quick Links

There are two types of quick link sites:

### 1. Built-in Sites (Torrent & Usenet)

Built-in sites are pre-configured torrent and usenet providers. Enable them via `DASHBOARD_SITES` environment variable:

**Available Torrent Sites:** TPB, FIL, HDB, IPT, 1337, YTS, LAT, NYA, PTP
**Available Usenet Sites:** DOG, DRS, NLF, NFW, NGK, PLA, TAB

Example: `DASHBOARD_SITES=TPB,DOG,NLF` enables The Pirate Bay, DOGnzb, and nzb.life

### 2. Custom Sites (sites.json5)

Define custom quick link sites in `sites.json5`. Each site has an `enabled` flag:

```json5
{
  sites: [
    {
      name: 'Google',
      url: 'https://google.com',
      icon: 'https://www.google.com/favicon.ico',
      enabled: true,
    },
    {
      name: 'GitHub',
      url: 'https://github.com',
      icon: 'https://github.githubassets.com/favicon.ico',
      enabled: true,
    },
  ],
}
```

**Display Order:**
1. If `DASHBOARD_SITES` is set: show those built-in sites first
2. Then show custom sites from sites.json5 where `enabled: true`
3. If `DASHBOARD_SITES` is empty: only show custom sites from sites.json5

## Configuration Priority

Configuration values are resolved in this order (highest to lowest priority):

1. **Environment variables** — Override everything
2. **yahlp.json5** — Primary configuration file
3. **Defaults** — Hardcoded in application

### Using Environment Variables for Overrides

You can override any configuration value using environment variables:

```bash
# Convert JSON5 path to SCREAMING_SNAKE_CASE
dashboard.name           → DASHBOARD_NAME
dashboard.theme          → DASHBOARD_THEME
access.mode              → ACCESS_MODE
access.domain            → ACCESS_DOMAIN
access.email             → ACCESS_EMAIL
auth.type                → AUTH_TYPE
services.jellyfin.url    → JELLYFIN_URL
services.jellyfin.api_key → JELLYFIN_API_KEY
services.plex.domain_name → PLEX_DOMAIN_NAME
services.sonarr.landing  → SONARR_LANDING
```

### Complete Environment Variable Reference

**Dashboard:**
- `DASHBOARD_NAME` — Dashboard name
- `DASHBOARD_ICON_URL` — Logo URL
- `DASHBOARD_COLOR` — Primary color
- `DASHBOARD_THEME` — 'dark' or 'light'
- `DASHBOARD_STYLE` — Layout style
- `DASHBOARD_LANDING` — 'dashboard' or 'welcome'
- `DASHBOARD_ORDER` — Service order (comma-separated 3-letter codes: JEL,SON,RAD,SEE,...)
- `DASHBOARD_SITES` — Enable built-in torrent/usenet sites (comma-separated codes: TPB,DOG,NLF,...)

**Access:**
- `ACCESS_MODE` — 'private' or 'public'
- `ACCESS_DOMAIN` — Domain name (public mode)
- `ACCESS_EMAIL` — Email (public mode, Let's Encrypt)

**Authentication:**
- `AUTH_TYPE` — 'none', 'basic', 'google', or 'entra'

**Services (by service name):**
- `{SERVICE}_ENABLED` — true/false to enable/disable
- `{SERVICE}_URL` — Service URL
- `{SERVICE}_ICON_URL` — Icon URL
- `{SERVICE}_API_KEY` — API key (if applicable)
- `{SERVICE}_USERNAME` — Username (qBittorrent, NZBGet)
- `{SERVICE}_PASSWORD` — Password (qBittorrent, Deluge, NZBGet)
- `{SERVICE}_DOMAIN_NAME` — Domain name (Plex, Emby, Seerr)
- `{SERVICE}_REDIRECT_URI` — Redirect URI (Plex, Emby, Seerr)
- `{SERVICE}_LANDING` — Default page/path to open (Sonarr, Radarr, Lidarr, Whisparr)

## Docker Deployment

### Example 1: Private Mode (Localhost)

**yahlp.json5:**
```json5
{
  dashboard: { name: 'Home Media', theme: 'dark', style: 'classic' },
  access: { mode: 'private' },
  services: {
    jellyfin: { enabled: true, url: 'http://jellyfin.local:8096', api_key: 'key', icon_url: '...' },
    sonarr: { enabled: true, url: 'http://sonarr.local:8989', api_key: 'key', icon_url: '...', landing: false },
  },
}
```

**Docker Compose:**
```yaml
services:
  yahlp:
    image: yahlp
    ports:
      - "3000:3000"
    volumes:
      - ./yahlp.json5:/etc/yahlp/yahlp.json5:ro
      - ./sites.json5:/etc/yahlp/sites.json5:ro
```

### Example 2: Public Mode with Domain

**yahlp.json5:**
```json5
{
  dashboard: { name: 'Media Dashboard', theme: 'dark', style: 'modern' },
  access: {
    mode: 'public',
    domain: 'dashboard.example.com',
    email: 'admin@example.com',
  },
  services: {
    jellyfin: { enabled: true, url: 'http://jellyfin.internal:8096', api_key: 'key', icon_url: '...' },
  },
}
```

**Docker Compose:**
```yaml
services:
  yahlp:
    image: yahlp
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./yahlp.json5:/etc/yahlp/yahlp.json5:ro
      - ./sites.json5:/etc/yahlp/sites.json5:ro
      - ./letsencrypt:/etc/letsencrypt  # Persist SSL certificates
```

### Example 3: Environment Variable Overrides

**Docker Compose:**
```yaml
services:
  yahlp:
    image: yahlp
    ports:
      - "3000:3000"
    volumes:
      - ./yahlp.json5:/etc/yahlp/yahlp.json5:ro
    environment:
      # Override specific values
      - JELLYFIN_URL=http://jellyfin-prod:8096
      - JELLYFIN_API_KEY=${JELLYFIN_KEY}
      - SONARR_ENABLED=true
      - DASHBOARD_THEME=light
```

## Custom Templates

Place custom templates in a directory and mount it:

```yaml
volumes:
  - ./custom-templates:/var/www/html/templates:ro
```

Examples included:
- `layout-vixens.css` — Navy, Crimson, Jade theme
- `layout-storm.css` — Melbourne Storm inspired
- `layout-neon.css` — Neon/cyberpunk theme

## Notes

- JSON5 allows comments with `//` and `/* */`
- Strings must be quoted
- Trailing commas are allowed
- Configuration is read at startup; changes require restart
- Set `enabled: false` to hide a service without removing its config
- Icon URLs should point to accessible endpoints (use full URLs)
