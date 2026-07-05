# Adding Custom App Icons

## Overview

The dashboard supports **custom icons for each service**. You can use:
- Official app logos
- Fan-made icons
- Custom designs
- Or auto-generated colored placeholders (default)

## How It Works

For each service, the menu generator (`get_service_icon_path()` in `generate-html-menu.sh`) checks for an icon in this order:

1. **Custom override** - `html/icons/<service>-custom.<ext>` (any extension — png, jpg, svg, webp, gif, etc. all work, whichever is present is used)
2. **Bundled default** - `html/icons/<service>.png` (ships with the container for all 18 services)
3. **Fallback** - Auto-generated colored placeholder if neither exists

If a custom override exists, it's used. Otherwise the bundled default PNG is used. If somehow neither exists, a colored placeholder is generated.

## Quick Start: Add Icons

### Step 1: Find Icons

Download icons for your services (see sources below).

### Step 2: Place Icons

Put icons in the `html/icons/` directory, named `<service>-custom.<ext>` so they take priority over the bundled defaults:

```
html/icons/
├── sonarr-custom.png       # Override for Sonarr
├── radarr-custom.png       # Override for Radarr
├── jellyfin-custom.png     # Override for Jellyfin
├── prowlarr-custom.png     # Override for Prowlarr
├── bazarr-custom.png       # Override for Bazarr
├── radarr-custom.jpg       # JPG also works
└── plex-custom.svg         # SVG also works
```

### Step 3: Rebuild

The shipped `docker-compose.yml` builds the image from this repo (`build: .`) and does **not** bind-mount `html/` into the container, so editing `html/icons/` on the host requires a rebuild — a plain restart will not pick up the new file:

```bash
docker-compose up --build -d
```

(If you've added your own bind mount for `./html:/var/www/html` — see Method 3 below — a `docker-compose restart` is enough instead.)

Icons are now displayed in the menu!

## Icon Naming Convention

Each service has a specific filename pattern. Use **lowercase** service names with the `-custom` suffix; any file extension is accepted:

| Service | Icon Filename |
|---------|---|
| Sonarr | `sonarr-custom.png` (or `.jpg`, `.svg`, etc.) |
| Radarr | `radarr-custom.png` |
| Whisparr | `whisparr-custom.png` |
| Lidarr | `lidarr-custom.png` |
| Prowlarr | `prowlarr-custom.png` |
| Seerr | `seerr-custom.png` |
| Bazarr | `bazarr-custom.png` |
| Jellyfin | `jellyfin-custom.png` |
| Emby | `emby-custom.png` |
| Plex | `plex-custom.png` |
| Tautulli | `tautulli-custom.png` |
| Maintainerr | `maintainerr-custom.png` |
| SABnzbd | `sabnzbd-custom.png` |
| NZBGet | `nzbget-custom.png` |
| NZBHydra | `nzbhydra-custom.png` |
| Transmission | `transmission-custom.png` |
| qBittorrent | `qbittorrent-custom.png` |
| Deluge | `deluge-custom.png` |
| Dashboard logo | `dashboard-custom.png` |

The bundled default icons (used when no `-custom` override is present) live at `html/icons/<service>.png` — e.g. `html/icons/sonarr.png`, `html/icons/radarr.png`, etc.

## Icon Sources

### Official/Recommended

**Sonarr** - https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png  
**Radarr** - https://github.com/Radarr/Radarr/raw/develop/Logo/256.png  
**Jellyfin** - https://github.com/jellyfin/jellyfin/raw/master/Logo.png  
**Plex** - https://www.plex.tv/ (brand guidelines)  
**Transmission** - https://transmissionbt.com/ (download page)  
**qBittorrent** - https://www.qbittorrent.org/ (logo page)  

### Community Packs

**Linuxserver Logos** - https://github.com/linuxserver/docker-templates/tree/master/linuxserver.io/img/  
Great collection of service logos in 256x256 PNG format.

**Unraid Community Apps** - https://github.com/selfhosted/unraid-community-apps/tree/master/source/community/  
Unraid app icons (many are excellent quality).

**Docker Hub Logos** - Search for "[service name] docker" on Docker Hub, usually has logos in README.

### Create Your Own

**Tools for custom icons:**
- Figma (free) - https://figma.com
- Inkscape (free) - https://inkscape.org
- Photoshop - https://adobe.com
- GIMP (free) - https://gimp.org
- Canva (free) - https://canva.com

## Icon Specifications

### Recommended Size
- **256x256 pixels** - Works well at any scale
- **Minimum: 64x64** - Will look pixelated if smaller
- **Maximum: 512x512** - No need to be larger

### Recommended Format
- **PNG** - Best for logos (transparency support)
- **JPG** - OK for photos/complex images
- **SVG** - Best for scalable graphics (no pixelation)

### Tips
- ✅ Transparent background (PNG)
- ✅ Clean, simple design
- ✅ High contrast (visible on dark background)
- ✅ Square aspect ratio (1:1)
- ❌ Don't use gradients (may look blurry)
- ❌ Don't use very thin lines (may disappear)

## Examples

### Using Official Icons

**Download Sonarr logo:**
```bash
cd html/icons/
curl -o sonarr.png https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png
```

**Download from Linuxserver:**
```bash
curl -o radarr.png https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/radarr-icon.png
```

**Download from Unraid:**
```bash
curl -o jellyfin.png https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/jellyfin-icon.png
```

### Using Multiple Formats

You can use PNG, JPG, and SVG together:

```bash
html/icons/
├── sonarr-custom.png       # Official PNG
├── radarr-custom.svg       # Official SVG
└── jellyfin-custom.jpg     # Custom JPG
```

Each service will use whatever format you provide.

## Viewing Icon Status

If you set `ICON_URL_<SERVICE>` env vars, the container logs download progress at startup (see `ICON-URLS.md` for details):

```bash
docker-compose logs apache-reverse-proxy | grep -A 20 "Downloading and Processing"
```

For manually-placed icon files (no `ICON_URL_*` set), there is no separate "Icon Status" log — simply check the file exists:

```bash
docker exec apache-reverse-proxy ls -la /var/www/html/icons/
```

## Installation Methods

### Method 1: Manual Download (Easiest)

1. Download icons to your computer
2. Place in `html/icons/` directory, named `<service>-custom.<ext>`
3. Rebuild the container (`docker-compose up --build -d`) — `html/` is baked into the image, so a plain restart won't see the new file

### Method 2: Docker Copy

```bash
# Copy icon file into running container
docker cp my-icon.png apache-reverse-proxy:/var/www/html/icons/sonarr-custom.png

# Restart to regenerate menu
docker-compose restart apache-reverse-proxy
```

### Method 3: Volume Mount

```yaml
volumes:
  - ./html:/var/www/html
```

Then edit icons directly on your host:
```bash
cp ~/Downloads/sonarr.png html/icons/sonarr-custom.png
docker-compose restart apache-reverse-proxy
```

### Method 4: Via Docker Build

Create a Dockerfile with icons:

```dockerfile
FROM apache-reverse-proxy:latest

# Copy custom icons
COPY icons/ /var/www/html/icons/
```

Build and run:
```bash
docker build -t apache-reverse-proxy:custom .
docker-compose up -d
```

## Customizing Icons After Deployment

### Add Icons to Running Container

```bash
# Copy icon into container
docker cp sonarr.png apache-reverse-proxy:/var/www/html/icons/sonarr-custom.png

# Restart container (menu regenerates)
docker-compose restart apache-reverse-proxy
```

### Replace Existing Icons

```bash
# Copy new version
docker cp new-radarr.png apache-reverse-proxy:/var/www/html/icons/radarr-custom.png

# Restart
docker-compose restart apache-reverse-proxy
```

### Remove Icon (Fall Back to Bundled Default)

```bash
# Delete the custom override
docker exec apache-reverse-proxy rm /var/www/html/icons/jellyfin-custom.png

# Restart (will fall back to the bundled html/icons/jellyfin.png,
# or a generated placeholder if no bundled default exists)
docker-compose restart apache-reverse-proxy
```

## Troubleshooting

### Icons Not Showing

**Check icon existence:**
```bash
docker exec apache-reverse-proxy ls -la /var/www/html/icons/
```

**Check icon download logs (only relevant if using `ICON_URL_*`):**
```bash
docker-compose logs apache-reverse-proxy | grep "Downloading and Processing" -A 20
```

**Verify permissions:**
```bash
docker exec apache-reverse-proxy stat /var/www/html/icons/sonarr-custom.png
# Should show readable by www-data user
```

### Icons Look Blurry

- Icons are too small (less than 64x64)
- Use PNG or SVG instead of JPG
- Check that icon format is supported

**Fix:** Download or create larger icons (256x256 or larger).

### Icon File Not Found

**Problem:** Icon file exists but isn't showing

**Causes:**
1. Wrong filename (must be lowercase and end in `-custom.<ext>`, e.g. `sonarr-custom.png`)
2. Wrong directory (`html/icons/` not `html/` or elsewhere)
3. File permissions (must be readable by www-data)

**Solution:**
```bash
# Verify file location and name
docker exec apache-reverse-proxy ls -la /var/www/html/icons/

# Fix permissions if needed
docker exec apache-reverse-proxy chmod 644 /var/www/html/icons/*.png

# Restart
docker-compose restart apache-reverse-proxy
```

### Mixed Icons and Placeholders

This is normal! You can have:
- Sonarr: custom override icon
- Radarr: bundled default icon
- Jellyfin: generated placeholder (no icon found at all)
- Plex: custom override icon

All coexist perfectly.

## Icon Collections You Can Use

### Pre-packaged Collections

**1. Linuxserver** (Recommended)
- Download: https://github.com/linuxserver/docker-templates/archive/master.zip
- Path: `/linuxserver.io/img/`
- Format: PNG 256x256
- Quality: Excellent

**2. Unraid Community Apps**
- Download: https://github.com/selfhosted/unraid-community-apps/archive/master.zip
- Path: `/source/community/img/`
- Format: PNG 256x256
- Quality: Very good

**3. CloudBox**
- Download: https://github.com/cloudbox/cloudbox/archive/master.zip
- Path: `/roles/*/defaults/`
- Format: PNG various sizes
- Quality: Good

### Downloading Pre-packaged Collections

```bash
# Download Linuxserver pack (rename to <service>-custom.<ext> as you go)
cd html/icons/
wget -O sonarr-custom.png https://github.com/linuxserver/docker-templates/raw/master/linuxserver.io/img/sonarr-icon.png
wget -O radarr-custom.png https://github.com/linuxserver/docker-templates/raw/master/linuxserver.io/img/radarr-icon.png
wget -O jellyfin-custom.png https://github.com/linuxserver/docker-templates/raw/master/linuxserver.io/img/jellyfin-icon.png
# ... and more
```

## FAQ

**Q: Do I have to use custom icons?**
A: No! Auto-generated SVG placeholders work fine. Custom icons are optional for better appearance.

**Q: Can I mix custom and auto-generated icons?**
A: Yes! Any service without a custom icon will use the colored placeholder.

**Q: What if I add icons after deployment?**
A: Rebuild the image (`docker-compose up --build -d`) unless you've bind-mounted `html/` — the menu regenerates automatically at container startup and will use the new icons.

**Q: Can I use different formats for different services?**
A: Yes! Use PNG for some, JPG for others, SVG for others - all supported.

**Q: Are icons cached?**
A: Icons are served directly from disk, no caching. Changes appear after refresh.

**Q: What size should icons be?**
A: 256x256 is ideal, but any size from 64x64 to 512x512 works well.

**Q: Can I use animated GIFs?**
A: Technically yes, but it's not recommended (uses more resources, can be distracting).

## Complete Example

### Setup with Icons

```bash
# 1. Create icons directory (if not exists)
mkdir -p html/icons

# 2. Download icons (note the -custom suffix so they override the bundled defaults)
cd html/icons/
curl -o sonarr-custom.png https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png
curl -o radarr-custom.png https://github.com/Radarr/Radarr/raw/develop/Logo/256.png
curl -o jellyfin-custom.png https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/jellyfin-icon.png
curl -o plex-custom.png https://plex.tv/downloads/Plex-icon.png

# 3. Verify files
ls -la

# 4. Rebuild and start the container (required since html/ is baked in at build time)
cd ../..
docker-compose up --build -d

# 5. Verify the files landed in the image
docker exec apache-reverse-proxy ls -la /var/www/html/icons/
```

Then visit `https://yourdomain.com` and see your custom icons in the menu!

---

**Your dashboard menu now supports professional app icons!** 🎨✨

