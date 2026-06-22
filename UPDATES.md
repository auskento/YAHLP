# What's New: Whisparr + Custom HTML Support

## ✨ New Features Added

### 1. Whisparr Support

**Whisparr** is now fully integrated! It's a comic and manga automation tool similar to Sonarr/Radarr.

**Quick Enable:**
```yaml
ENABLE_WHISPARR: "true"
```

**Access at:** `https://yourdomain.com/whisparr`

**Port:** 6969

**What it does:**
- Automate comic book collection
- Track manga series
- Manage digital collections
- Integration with download clients

**docker-compose service included:**
```yaml
whisparr:
  image: lscr.io/linuxserver/whisparr:latest
  container_name: whisparr
  ports:
    - "6969:6969"
  volumes:
    - /path/to/whisparr/config:/config
    - /path/to/media:/media
```

### 2. Custom HTML Support

You can now use your own custom HTML files for the reverse proxy layout!

**Three ways to customize:**

#### Option 1: Edit Existing Files (Simplest)
Just edit the HTML files in the `html/` directory:
- `html/index.html` - Home page
- `html/error-pages/502.html` - Bad gateway error
- `html/error-pages/503.html` - Unavailable error

Changes apply on restart.

#### Option 2: Volume Mount (For Development)
In `docker-compose.yml`, add a volume mount:
```yaml
volumes:
  - ./html:/var/www/html
```

Now changes are live without rebuilding!

#### Option 3: Replace Entire Directory
Point to your custom HTML directory:
```yaml
volumes:
  - /path/to/your/custom/html:/var/www/html
```

**New Documentation:**
→ Read `CUSTOM-HTML.md` for complete guide with examples

---

## Files Updated

### Configuration
- ✅ `docker-compose.yml` - Added Whisparr service and environment variable
- ✅ `apache-conf/services/whisparr.conf` - New Whisparr proxy config
- ✅ `apache-conf/reverse-proxy.conf.template` - Added Whisparr placeholder
- ✅ `generate-config.sh` - Added Whisparr logic
- ✅ `.env.example` - Added ENABLE_WHISPARR option

### Documentation
- ✅ `CUSTOM-HTML.md` - NEW! Complete HTML customization guide
- ✅ `SERVICES.md` - Updated with Whisparr details
- ✅ `INDEX.md` - Updated service count (13→14) and service list

---

## Quick Examples

### TV/Movie/Comic Automation Stack
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_WHISPARR: "true"
ENABLE_PROWLARR: "true"
ENABLE_SEERR: "true"
ENABLE_QBITTORRENT: "true"
```

Access:
- `https://yourdomain.com/sonarr` - TV shows
- `https://yourdomain.com/radarr` - Movies
- `https://yourdomain.com/whisparr` - Comics/Manga
- `https://yourdomain.com/prowlarr` - Indexer management
- `https://yourdomain.com/seerr` - Requests
- `https://yourdomain.com/qbittorrent` - Torrents

### With Custom HTML
1. Create your custom `html/index.html` with links to all services
2. Use volume mount for live editing
3. Restart proxy to apply

Example HTML template provided in `CUSTOM-HTML.md`!

---

## What Changed

### Whisparr Integration
The modular system now automatically includes Whisparr when `ENABLE_WHISPARR: "true"` is set.

**How it works:**
1. You set `ENABLE_WHISPARR: "true"` in docker-compose.yml
2. Container starts
3. `generate-config.sh` reads environment variables
4. Whisparr config automatically included in Apache
5. Accessible immediately at `/whisparr`

### Custom HTML System
The `html/` directory is completely customizable:

**Option A (Live Editing):**
```yaml
volumes:
  - ./html:/var/www/html
```
Edit files and refresh browser - changes are instant!

**Option B (Build-time):**
Copy your HTML into `html/` directory, rebuild, deploy.

**Option C (External Directory):**
Point to external directory via volume mount.

All files in the `html/` directory are served from `/` (root path).

---

## File Structure (Updated)

```
outputs/
├── 📄 Documentation
│   ├── CUSTOM-HTML.md              ← NEW! How to customize HTML
│   ├── QUICKSTART-SERVICES.md
│   ├── SERVICES.md                 ← Updated with Whisparr
│   ├── README.md
│   ├── INDEX.md                    ← Updated service count
│   └── TROUBLESHOOTING.md
│
├── 🐳 Docker & Configuration
│   ├── Dockerfile
│   ├── docker-compose.yml          ← Added Whisparr service
│   ├── docker-entrypoint.sh
│   ├── generate-config.sh          ← Added Whisparr logic
│   ├── cert-renewal-cron
│   └── .env.example                ← Added ENABLE_WHISPARR
│
├── 🔧 Apache Configuration
│   ├── apache-conf/
│   │   ├── reverse-proxy.conf.template  ← Added @@INCLUDE_WHISPARR@@
│   │   ├── ssl-config.conf
│   │   └── services/
│   │       ├── whisparr.conf            ← NEW!
│   │       ├── sonarr.conf
│   │       ├── radarr.conf
│   │       └── ... (10+ others)
│
└── 🎨 Web Assets
    └── html/
        ├── index.html              ← Fully customizable!
        └── error-pages/
            ├── 502.html            ← Fully customizable!
            └── 503.html            ← Fully customizable!
```

---

## Updated Environment Variables

```bash
# New in this release
ENABLE_WHISPARR: "true"  # Comic & Manga automation
```

All other services remain the same:
```bash
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_LIDARR: "false"
ENABLE_PROWLARR: "false"
ENABLE_SEERR: "false"
ENABLE_JELLYFIN: "false"
ENABLE_EMBY: "false"
ENABLE_PLEX: "false"
ENABLE_TAUTULLI: "false"
ENABLE_TRANSMISSION: "false"
ENABLE_QBITTORRENT: "false"
```

---

## Using Whisparr

### 1. Enable in docker-compose.yml
```yaml
environment:
  ENABLE_WHISPARR: "true"
```

### 2. Uncomment the service (or add your own)
```yaml
whisparr:
  image: lscr.io/linuxserver/whisparr:latest
  container_name: whisparr
  volumes:
    - /path/to/whisparr/config:/config
    - /path/to/media:/media
  ports:
    - "6969:6969"
  networks:
    - proxy-network
```

### 3. Restart the proxy
```bash
docker-compose restart apache-reverse-proxy
```

### 4. Access at
`https://yourdomain.com/whisparr`

---

## Custom HTML Guide

**See `CUSTOM-HTML.md` for:**
- How to provide your own HTML files
- CSS styling and theming
- Custom error pages
- Dashboard examples
- Responsive design tips
- JavaScript integration
- Asset management (CSS, JS, images)

**Quick Start:**
1. Create `html/index.html` with your custom content
2. Add volume mount to docker-compose.yml
3. Changes are live instantly!

---

## All 14 Services Now Available

1. **Sonarr** - TV shows
2. **Radarr** - Movies
3. **Whisparr** - Comics/Manga ⭐ NEW
4. **Lidarr** - Music
6. **Prowlarr** - Indexer manager
7. **Seerr** - Request manager
8. **Jellyfin** - Media playback
9. **Emby** - Premium media center
10. **Plex** - Cloud sync media
11. **Tautulli** - Plex monitoring
12. **Transmission** - Torrent client
13. **qBittorrent** - Advanced torrents
14. **Custom Backend** - Any service via custom config

---

## Recommended Setups

### Complete Media Automation + Comics
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_WHISPARR: "true"      # ← New!
ENABLE_PROWLARR: "true"
ENABLE_SEERR: "true"
ENABLE_QBITTORRENT: "true"
```

### Media Server with Comics
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_WHISPARR: "true"      # ← New!
ENABLE_JELLYFIN: "true"
ENABLE_QBITTORRENT: "true"
ENABLE_TAUTULLI: "true"
```

---

## Next Steps

1. **Update docker-compose.yml** with `ENABLE_WHISPARR: "true"`
2. **Create custom HTML** (see `CUSTOM-HTML.md`)
3. **Restart the proxy**: `docker-compose up -d`
4. **Access services:**
   - `https://yourdomain.com/` - Your custom HTML
   - `https://yourdomain.com/sonarr` - TV shows
   - `https://yourdomain.com/radarr` - Movies
   - `https://yourdomain.com/whisparr` - Comics/Manga ⭐

---

**Questions?** Check `SERVICES.md` for service details or `CUSTOM-HTML.md` for HTML customization! 🚀
