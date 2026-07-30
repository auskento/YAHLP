# Dashboard Configuration Guide

Complete reference for configuring YAHLP's service panel, including service ordering, window behaviors, and appearance.

---

## Environment Variables

### Display Settings

#### `DASHBOARD_NAME`
The title displayed at the top of the dashboard.

```bash
DASHBOARD_NAME="My HomeLab"
```
**Default**: `YAHLP`

#### `DASHBOARD_COLOR`
Primary accent color for buttons, borders, and highlights. Use hex color codes.

```bash
DASHBOARD_COLOR="#0ea5e9"
```
**Default**: `#0ea5e9` (blue)

#### `DASHBOARD_WINDOWS`
Default window behavior for custom services: `popout` (opens in overlay) or `newtab` (opens in new tab).

```bash
DASHBOARD_WINDOWS=popout
```
**Default**: `popout`
**Note**: Per-service `#DASHBOARD_WINDOW` settings in `.conf` files override this global setting.

#### `DEBUG`
Enable verbose logging for dashboard generation, service discovery, and configuration parsing.

```bash
DEBUG=true
```
**Default**: `false`

Shows:
- Service file discovery in `/etc/yahlp/additional-conf/`
- Per-service configuration extraction (#APPNAME, #DASHBOARD_WINDOW)
- Menu generation details
- Icon resolution and format conversions
- Sample exports and Apache configuration details

---

### Service Management

#### `DASHBOARD_ORDER`
Comma-separated list of service codes to customize dashboard order. Services not listed appear at the end.

```bash
DASHBOARD_ORDER=sonarr,radarr,lidarr,prowlarr,tda,kee
```

**Supported Codes**:
- **Usenet**: `sab` (SABnzbd), `nzbget`, `nzbh` (NZBHydra)
- **Torrents**: `trans` (Transmission), `qbit` (qBittorrent), `deluge`
- **Search**: `prowl` (Prowlarr), `jack` (Jackett)
- **Automation**: `sonarr`, `radarr`, `lidarr`, `whisp` (Whisparr)
- **Utilities**: `bazarr`, `seerr`, `taut` (Tautulli), `maint` (Maintainerr)
- **Media**: `jf` (Jellyfin), `emby`, `plex`
- **Custom**: Any 3-letter code matching custom service files

**Default**: Services listed in order of appearance in code

#### `SONARR_ENABLED`, `RADARR_ENABLED`, etc.
Enable or disable individual services. Uses environment variable naming: `{SERVICECODE}_ENABLED`

```bash
SONARR_ENABLED=true
RADARR_ENABLED=false
TRANSMISSION_ENABLED=true
```

**Default**: `true` (services enabled if configured)

---

## Per-Service Configuration (Custom Services)

Custom services use comment-based configuration in `.conf` files. See [CUSTOM_SERVICES.md](CUSTOM_SERVICES.md) for full details.

### `#APPNAME`
Display name for the service on the dashboard.

```apache
# #APPNAME=Tdarr
```

**Rules**:
- If omitted, uses capitalized service code (e.g., `tda` → `Tda`)
- Can contain spaces: `# #APPNAME=My Custom App`
- Displayed as-is on dashboard

**Example**:
```apache
# Tdarr transfer tracker
# #APPNAME=Tdarr
```

### `#DASHBOARD_WINDOW`
Window behavior for this service: `popout` or `newtab`. Overrides global `DASHBOARD_WINDOWS`.

```apache
# #DASHBOARD_WINDOW=newtab
```

**Default**: `popout` (if not specified)

**Behavior**:
- `popout`: Opens service in an overlay modal on top of dashboard
- `newtab`: Opens service in a new browser tab

**Example**:
```apache
# #APPNAME=Overseerr
# #DASHBOARD_WINDOW=newtab
```

---

## Service Panel Appearance

### Icons

Each service on the dashboard displays an icon. Icon resolution is automatic:

**Built-in Services**:
- Stored in `/etc/yahlp/sites-icons/`
- Includes PNG and SVG formats
- Automatically converted to SVG when displayed (cached as data URIs)

**Custom Services**:
- Stored in `/config/additional-conf/` with `.conf` files
- Synced to `/etc/yahlp/service_icons/` on startup
- PNG format recommended; SVG supported
- Referenced as `/icons/{servicecode}.png` on dashboard

**Icon Resolution**:
- Optimal size: 64×64px (larger automatically scaled down)
- Supports both PNG and SVG formats
- Fallback to generic icon if file not found

### Service Cards

Each service appears as a clickable card on the dashboard with:

```
┌─────────────────────┐
│  [Icon] Service     │
│         Name        │
└─────────────────────┘
```

**Card Elements**:
- **Icon**: Left-aligned 48×48px display
- **Service Name**: From `#APPNAME` or service code
- **Click Action**: Opens service URL or href
- **Popup Behavior**: Determined by `DASHBOARD_WINDOWS` or per-service `#DASHBOARD_WINDOW`

---

## Complete Configuration Example

### Environment Variables

```bash
# Display
DASHBOARD_NAME="Marcus's Lab"
DASHBOARD_COLOR="#6366f1"
DASHBOARD_WINDOWS=popout
DEBUG=false

# Service Enablement
SONARR_ENABLED=true
RADARR_ENABLED=true
PROWLARR_ENABLED=true
TRANSMISSION_ENABLED=true
NZBGET_ENABLED=false

# Service Order
DASHBOARD_ORDER=sonarr,radarr,lidarr,prowlarr,transmission,tda,kee,seerr
```

### Custom Service Config (`tda.conf`)

```apache
# Tdarr Transfer Tracker
# #APPNAME=Tdarr
# #DASHBOARD_WINDOW=popout

<Location /tdarr/>
    ProxyPass http://tdarr:8265/
    ProxyPassReverse http://tdarr:8265/
    ProxyPreserveHost On
</Location>
```

### File Structure

```
/config/additional-conf/
├── tda.conf
├── tda.png
├── kee.conf
└── kee.png
```

**Result on Dashboard**:
1. Sonarr
2. Radarr
3. Lidarr
4. Prowlarr
5. Transmission
6. Tdarr (custom, PNG icon, opens in popout)
7. Keeper Automator (custom, PNG icon, opens in popout)
8. Seerr

---

## Dynamic Service Discovery

YAHLP automatically discovers services based on configuration:

1. **Built-in Services**: Detected from environment variables and `yamlp.json5`
   - Example: `SONARR_URL` and `SONARR_API_KEY` enable Sonarr
   - Service is added to dashboard if enabled

2. **Custom Services**: Discovered from `/etc/yahlp/additional-conf/`
   - Files matching `XYZ.conf` (where X, Y, Z are letters)
   - Settings extracted from file comments: `#APPNAME=`, `#DASHBOARD_WINDOW=`
   - Icon synced from `XYZ.png` in same folder
   - Href extracted from `<Location>` directive

3. **VirtualHost Services**: Ignored in dashboard menu
   - Files with "vhost" in filename are treated as independent services
   - Not added to dashboard; served independently by Apache

---

## Ordering Behavior

### Explicit Ordering

Specify exact order with `DASHBOARD_ORDER`:

```bash
DASHBOARD_ORDER=sonarr,radarr,prowlarr,tda
```

**Result**: Sonarr, Radarr, Prowlarr, Tdarr (in that order), then any other enabled services.

### Implicit Ordering

If `DASHBOARD_ORDER` is not set:

1. **Built-in Services** appear in code order
2. **Custom Services** (from `/etc/yahlp/additional-conf/`) appear after built-in services
3. **All Services** are filtered by enablement status (skip if `_ENABLED=false`)

### Dynamic Service Detection

Services not explicitly listed in `DASHBOARD_ORDER` are added to the end:

```bash
DASHBOARD_ORDER=sonarr,radarr
# Adds: tda, kee (alphabetically in code order)
# Result: sonarr, radarr, ... tda, kee
```

---

## Responsive Dashboard

The dashboard adapts to screen size:

- **Desktop** (> 768px): Grid layout with multiple columns
- **Tablet** (768px): 2-3 column grid
- **Mobile** (< 576px): Single column layout

Icons and text scale automatically. Service order remains consistent across all breakpoints.

---

## Troubleshooting

### Service Not Appearing

**Check**:
1. Service is enabled: `SONARR_ENABLED=true`
2. Service is configured: URL and API key (or equivalent) provided
3. For custom services: File in `/config/additional-conf/` without "example" in name

**Debug**:
```bash
DEBUG=true
```
Restart and check logs for service discovery details.

### Icon Not Displaying

1. Verify file exists: `/config/additional-conf/tda.png`
2. File size and format: PNG recommended, 64×64px or larger
3. Filename matches `.conf` file: `tda.png` for `tda.conf`
4. Restart container to sync icons to `/etc/yahlp/service_icons/`

### Service Opens Wrong URL

1. Check `#DASHBOARD_WINDOW` setting in `.conf` file
2. Verify `<Location>` path matches service route
3. Ensure backend service is running and reachable at ProxyPass URL

### Wrong Service Order

1. Verify `DASHBOARD_ORDER` syntax: comma-separated, no spaces
2. Check service codes are correct (3-letter codes or custom service file names)
3. Services not in list appear at end

---

## Advanced: Cascading Configuration

Service configuration follows a strict precedence:

1. **Per-Service Settings**: `#APPNAME=`, `#DASHBOARD_WINDOW=` in `.conf` files (highest)
2. **Global Settings**: `DASHBOARD_WINDOWS` environment variable
3. **Built-in Defaults**: Code defaults for services (lowest)

**Example**:
```bash
# Global default: all services in popout
DASHBOARD_WINDOWS=popout

# Custom service config overrides global:
# #DASHBOARD_WINDOW=newtab  # This service uses newtab instead
```

---

## Related Documentation

- [CUSTOM_SERVICES.md](CUSTOM_SERVICES.md) — Adding custom services
- [MODULAR_APPS.md](MODULAR_APPS.md) — Framework overview
- `docs/configuration.md` — Full configuration reference
