# YAHLP Icon Configuration Guide

This guide explains how to configure custom icons in YAHLP, including dashboard logos, service icons, and site favicons.

## Folder Structure

When YAHLP starts, it creates the following directories in `/etc/yahlp/`:

```
/etc/yahlp/
├── service_icons/      # Custom service icons
├── site_icons/         # Custom site favicons
├── yahlp.json5         # Configuration file
└── certs/              # SSL certificates (auto-managed)
```

## Dashboard Icon (Logo)

### Configuration

Set via environment variable `DASHBOARD_ICON_URL`:

```bash
DASHBOARD_ICON_URL=https://example.com/logo.png
```

### Options

1. **External URL** (recommended)
   ```bash
   DASHBOARD_ICON_URL=https://cdn.example.com/yahlp-logo.png
   ```
   - Must be publicly accessible from the dashboard
   - Supports PNG, JPG, SVG formats
   - Recommended size: 32x32 or 64x64 pixels

2. **Data URI** (embedded)
   ```bash
   DASHBOARD_ICON_URL=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==
   ```
   - Icon encoded as base64 data URI
   - No external request needed
   - Faster loading, self-contained

3. **Empty (default)**
   ```bash
   DASHBOARD_ICON_URL=
   ```
   - Uses built-in YAHLP logo
   - No configuration needed

## Service Icons

### Location

Place custom service icons in `/etc/yahlp/service_icons/`

### Setup

1. Mount the service_icons folder from your host:
   ```yaml
   volumes:
     - /path/to/service_icons:/etc/yahlp/service_icons:ro
   ```

2. Add icon files to your host directory:
   ```
   /path/to/service_icons/
   ├── sonarr.png
   ├── radarr.png
   ├── plex.png
   └── emby.png
   ```

### Filename Format

Use lowercase service names with image extensions:
- `sonarr.png` → Sonarr service icon
- `radarr.jpg` → Radarr service icon
- `jellyfin.svg` → Jellyfin service icon

### Built-in Icons

YAHLP includes default icons for all 19 services:
- All services have built-in PNG icons
- Custom icons override built-in ones
- Icons are loaded from `/etc/yahlp/service_icons/` first, then fallback to built-in

### Icon Specifications

- **Format**: PNG, JPG, or SVG recommended
- **Size**: 32x32 to 128x128 pixels (responsive)
- **Aspect Ratio**: Square (1:1) preferred
- **Color**: Color icons work best (transparent backgrounds supported)

## Site Favicons

### Automatic Fetching

YAHLP automatically fetches favicons for enabled torrent/usenet sites:

1. On first run, `generate-sites-config.sh` fetches favicons
2. Uses Google's favicon API: `https://www.google.com/s2/favicons?sz=64&domain=`
3. Caches fetched favicons in `/var/log/apache2/sites/`
4. Falls back to built-in cached favicons if fetch fails

### Manual Favicons

To use manual favicons:

1. Place favicon files in `/etc/yahlp/site_icons/`
2. Filename format: `{SITE_CODE}.favicon.ico`
3. Size: 64x64 pixels (will be resized if ImageMagick available)

Example:
```
/etc/yahlp/site_icons/
├── tpb.favicon.ico     # The Pirate Bay favicon
├── dog.favicon.ico     # DogNZB favicon
└── drs.favicon.ico     # DrunkenSlug favicon
```

### Site Codes

Use these codes in `/etc/yahlp/site_icons/` filenames:

**Torrent Sites**: TPB, FIL, HDB, IPT, 1337, YTS, LAT, NYA, PTP
**Usenet Sites**: DOG, DRS, NLF, NFW, NGK, PLA, TAB

Example:
- TPB favicon: `tpb.favicon.ico`
- DogNZB favicon: `dog.favicon.ico`

## Configuration Example

Docker Compose with custom icons:

```yaml
services:
  yahlp:
    image: auskento/yahlp:latest
    environment:
      - DOMAIN=yourdomain.com
      - DASHBOARD_ICON_URL=https://cdn.example.com/my-logo.png
      - DASHBOARD_SITES=TPB,DRS,NLF  # Enable torrent/usenet sites
    volumes:
      - /path/to/yahlp/config:/etc/yahlp
      - /path/to/service_icons:/etc/yahlp/service_icons:ro
      - /path/to/site_icons:/etc/yahlp/site_icons:ro
```

## Troubleshooting

### Dashboard Logo Not Showing

- Check `DASHBOARD_ICON_URL` is set correctly
- Verify URL is accessible from the container
- Check browser console for 404 errors
- Ensure image format is supported (PNG, JPG, SVG)

### Service Icons Not Showing

- Verify files are in `/etc/yahlp/service_icons/`
- Check filenames match service names (lowercase)
- Ensure file permissions allow reading (644 or 755)
- Clear browser cache and reload

### Site Favicons Not Fetching

- Check internet connectivity from container
- Verify `DASHBOARD_SITES` environment variable is set
- Review startup logs for favicon fetch errors
- Manually place favicon files if automatic fetch fails
- Ensure ImageMagick is installed for favicon resizing

## Performance Notes

- External icon URLs add HTTP requests on dashboard load
- Data URI icons are fastest (no external request)
- Built-in icons are pre-cached and fastest
- Custom service icons from volume mount are cached by browser

## Icon Limits

- Dashboard icon: One URL (external, data URI, or built-in)
- Service icons: Custom folder location, fallback to built-in
- Site favicons: Auto-fetch + manual override support

## Updating Icons

To update icons without container restart:

1. **Dashboard icon**: Change `DASHBOARD_ICON_URL` and reload browser
2. **Service icons**: Update files in `/etc/yahlp/service_icons/` and reload browser (clear cache)
3. **Site favicons**: Update files in `/etc/yahlp/site_icons/` and reload browser
