# Dynamic HTML Dashboard Menu

## Overview

The HTML dashboard menu is **automatically generated based on which services you enable** in `docker-compose.yml`.

- **No manual HTML editing needed** - Just toggle services on/off
- **Menu updates automatically** - Each restart regenerates the menu
- **Only enabled services appear** - Keeps interface clean
- **Dynamic service discovery** - New services can be easily added

## How It Works

### 1. Template System
- **Master template**: `html/master.template` — shared markup/JS used by every layout
- **Layout CSS files**: `html/styles/layout-*.css` (e.g. `layout-classic.css`, `layout-modern.css`, `layout-sleek.css`, `layout-minimal.css`, `layout-mobile.css`) — each discovered CSS file becomes a selectable dashboard style
- **Generator script**: `generate-html-menu.sh`
- **Output files**: one HTML page per discovered layout (`/var/www/html/classic.html`, `modern.html`, `sleek.html`, `minimal.html`, `mobile.html`, plus any custom layouts), and `index.html` (auto-generated, don't edit!)

### 2. Generation Process

At container startup:

```
docker-entrypoint.sh runs
    ↓
docker-entrypoint.sh calls generate-html-menu.sh
    ↓
Script reads ENABLE_* environment variables and builds a services array
    ↓
Script scans html/styles for layout-*.css files
    ↓
Script substitutes the services array + sites array into master.template
    ↓
One HTML page is generated per discovered layout, plus index.html (default: DASH_STYLE)
    ↓
Apache serves the custom dashboard (DASH_STYLE.html via DirectoryIndex)
```

### 3. Service Menu Items

Each enabled service gets:
- **Icon** — bundled PNG (`/icons/<service>.png`), a custom override (`/icons/<service>-custom.<ext>`), or one downloaded via `ICON_URL_<SERVICE>`
- **Service name and description** — pulled from the service's metadata in `generate-html-menu.sh`
- **Link target** — the service's subpath (e.g. `/sonarr/`), a subdomain (Emby/Plex/Seerr when `*_DOMAIN` is set), or a direct backend URL; some open as an in-page panel, others as a popup window (external/subdomain links, and qBittorrent, always pop up)
- **Responsive layout** — a dedicated `mobile` layout is always generated in addition to the desktop styles

## Enabling/Disabling Services

### Edit docker-compose.yml

```yaml
environment:
  # Services will appear in menu if set to "true"
  ENABLE_SONARR: "true"       # ✓ Will appear
  ENABLE_RADARR: "true"       # ✓ Will appear
  ENABLE_WHISPARR: "false"    # ✗ Will NOT appear
  ENABLE_JELLYFIN: "true"     # ✓ Will appear
  ENABLE_PLEX: "false"        # ✗ Will NOT appear
```

### Restart Container

```bash
# Menu will be regenerated automatically
docker-compose restart apache-reverse-proxy
```

### Check Logs

```bash
# Verify menu was generated
docker-compose logs apache-reverse-proxy | grep -i "dashboard"
```

Example output:
```
Generating dashboard menu based on enabled services...
Generating dashboards for DASH_STYLE=modern...
✓ Dashboards generated with 5 enabled service(s)
```

## Services Supported

All 18 services, grouped by category (matches `DASHBOARD_ORDER` default grouping):

| Service | Enable Variable | Category |
|---------|---|---|
| SABnzbd | ENABLE_SABNZBD | USENET |
| NZBGet | ENABLE_NZBGET | USENET |
| NZBHydra | ENABLE_NZBHYDRA | USENET |
| Deluge | ENABLE_DELUGE | TORRENTS |
| Transmission | ENABLE_TRANSMISSION | TORRENTS |
| qBittorrent | ENABLE_QBITTORRENT | TORRENTS |
| Sonarr | ENABLE_SONARR | CONTENT |
| Radarr | ENABLE_RADARR | CONTENT |
| Lidarr | ENABLE_LIDARR | CONTENT |
| Whisparr | ENABLE_WHISPARR | CONTENT |
| Seerr | ENABLE_SEERR | SEARCH |
| Prowlarr | ENABLE_PROWLARR | SEARCH |
| Bazarr | ENABLE_BAZARR | SEARCH |
| Emby | ENABLE_EMBY | MEDIA |
| Plex | ENABLE_PLEX | MEDIA |
| Jellyfin | ENABLE_JELLYFIN | MEDIA |
| Tautulli | ENABLE_TAUTULLI | MEDIA |
| Maintainerr | ENABLE_MAINTAINERR | MEDIA |

## Quick Examples

### Minimal Setup (Just TV & Movies)
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
# All others: "false"
```
Menu shows: 2 icons

### Complete Media Server
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_PROWLARR: "true"
ENABLE_SEERR: "true"
ENABLE_JELLYFIN: "true"
ENABLE_QBITTORRENT: "true"
ENABLE_TAUTULLI: "true"
```
Menu shows: 7 service icons

### Only Torrents
```yaml
ENABLE_TRANSMISSION: "true"
ENABLE_QBITTORRENT: "true"
# All others: "false"
```
Menu shows: 2 torrent icons only

## Workflow

### Change Enabled Services

1. **Edit docker-compose.yml**
   ```bash
   vim docker-compose.yml
   # Toggle ENABLE_* variables
   ```

2. **Restart container**
   ```bash
   docker-compose restart apache-reverse-proxy
   ```

3. **Menu regenerates automatically**
   - Script runs on startup
   - Reads enabled services
   - Generates new index.html
   - Apache serves updated dashboard

4. **Verify changes**
   - Visit `https://yourdomain.com`
   - Check if menu icons match your settings

## Service Menu Colors

Each service has a unique accent color (used for its icon border/highlight), defined per-service in the `SERVICES` array in `generate-html-menu.sh`:

```
SABnzbd       - #f5c20f
NZBGet        - #3da7e0
NZBHydra      - #3e9c7d
Deluge        - #3aa3e0
Transmission  - #343434
qBittorrent   - #3683b6
Sonarr        - #3aa0e0
Radarr        - #febc2e
Lidarr        - #2ecd6f
Whisparr      - #ef7e30
Seerr         - #00a4dc
Prowlarr      - #e8810e
Bazarr        - #e91e63
Emby          - #9146FF
Plex          - #e5a00d
Jellyfin      - #00a4dc
Tautulli      - #4a9eff
Maintainerr   - #1e90ff
```

## Customization

### Change Service Colors

Edit `generate-html-menu.sh` and modify the `SERVICES` array (format: `category|name|desc|icon|href|accent`):

```bash
[SONARR]="CONTENT|Sonarr|TV shows|/icons/sonarr.png|@@SONARR_LANDING@@|#FF0000"  # Change accent to #FF0000 (red)
```

Then restart:
```bash
docker-compose restart apache-reverse-proxy
```

### Change Menu Height / Icon Size / Overall Layout

Layout appearance (header height, icon size, spacing, etc.) is controlled by the per-style CSS files in `html/styles/layout-*.css` (or custom CSS dropped into the mounted `/templates` directory), not by editing `master.template` directly. Edit the relevant `layout-*.css` file and restart to regenerate.

## Files

| File | Purpose |
|------|---------|
| `html/master.template` | Shared dashboard markup/JS used by every layout |
| `html/styles/layout-*.css` | Per-style CSS (classic, modern, sleek, minimal, mobile, or custom) |
| `generate-html-menu.sh` | Generator script (reads env vars, builds services/sites arrays, renders each layout) |
| `/var/www/html/<style>.html` | Generated output per layout (auto-created) |
| `docker-entrypoint.sh` | Calls the generator at startup |
| `Dockerfile` | Copies scripts and templates into the image |

## Troubleshooting

### Menu Not Updating After Changing Services

**Problem**: Changed ENABLE_* but menu shows old services

**Solution**:
```bash
# Force restart
docker-compose restart apache-reverse-proxy

# Check generation log
docker-compose logs apache-reverse-proxy | grep -i "dashboard\|generating"
```

### Service Icon in Menu But Service Returns 502

**Problem**: Clicked service icon, got "502 Bad Gateway"

**Causes**:
1. Service container not running
2. Service name mismatch in config
3. Service port incorrect
4. Service container not on same Docker network

**Fix**:
```bash
# Verify service is running
docker ps | grep sonarr

# Check Apache logs for details
docker-compose logs apache-reverse-proxy -f
```

### Menu Shows Wrong Service Colors

**Solution**: Edit colors in `generate-html-menu.sh` SERVICES array, then restart.

### Text is Hard to Read on Small Screens

A dedicated `mobile` layout (`html/styles/layout-mobile.css`) is always generated for small screens — try switching to it in the dashboard's style switcher. If you need further tweaks, edit `layout-mobile.css` (or the relevant `layout-*.css`) directly and restart to regenerate:
```css
@media (max-width: 768px) {
    .menu-item .label {
        display: block;  /* Show labels on mobile */
        font-size: 0.7em;
    }
}
```

## Performance

- **Generation time**: <100ms per layout
- **File size**: ~5-10KB per generated HTML page
- **Browser load**: <1 second
- **No impact on proxy performance**

## Security

✅ Server-side generation (safe)  
✅ Service paths validated  
✅ Icons are bundled PNGs or downloaded/resized server-side (no external scripts loaded client-side)  
✅ HTTPS enforced (public mode)  
✅ No sensitive data exposed  

## Advanced: Add Custom Service

To add a new service to the system:

### 1. Edit generate-html-menu.sh

Add an entry to the `SERVICES` array (format: `category|name|desc|icon|href|accent`) and to `SERVICE_ORDER` / `SERVICE_CODE_MAP` if you want it addressable via `DASHBOARD_ORDER`:
```bash
[MYSERVICE]="CONTENT|My Service|My Service Description|/icons/myservice.png|/myservice/|#FF00FF"
```

### 2. Create Service Config

Create `apache-conf/services/myservice.conf`:
```apache
<Location /myservice>
    ProxyPass http://myservice:9999/
    ProxyPassReverse http://myservice:9999/
    ProxyConnectTimeout 30
    ProxyTimeout 300
</Location>
```

### 3. Wire Up generate-config.sh

Add `ENABLE_MYSERVICE` handling to `generate-config.sh` (a `process_service_config` call and a `generate_include` call) and add the corresponding `@@INCLUDE_MYSERVICE@@` placeholder to `reverse-proxy.conf.template`.

### 4. Update Environment

Add to docker-compose.yml:
```yaml
ENABLE_MYSERVICE: "true"
```

### 5. Rebuild

```bash
docker-compose build
docker-compose up -d
```

Menu will automatically include the new service!

---

**The dashboard menu is fully dynamic and automatically reflects your configuration!** 🎨

