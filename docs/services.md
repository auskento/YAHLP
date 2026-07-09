# Services Reference

Complete setup guides for all 19 supported services.

## Quick Reference Table

| Code | Service | Category | Default Port | Auth |
|------|---------|----------|--------------|------|
| SAB | SABnzbd | Usenet | 8080 | Optional API Key |
| GET | NZBGet | Usenet | 6789 | Optional Username/Password |
| HYD | NZBHydra | Usenet | 5076 | Optional API Key |
| TRA | Transmission | Torrents | 6969 | None |
| QBI | qBittorrent | Torrents | 8080 | Required API Key |
| DEL | Deluge | Torrents | 8112 | Required Password |
| PRO | Prowlarr | Search | 9696 | Optional API Key |
| JAC | Jackett | Search | 9117 | Optional API Key |
| SON | Sonarr | Search | 8989 | Optional API Key |
| RAD | Radarr | Search | 7878 | Optional API Key |
| LID | Lidarr | Search | 8686 | Optional API Key |
| WHI | Whisparr | Search | 6969 | Optional API Key |
| SEE | Seerr | Infrastructure | 5055 | Optional API Key |
| BAZ | Bazarr | Infrastructure | 6767 | Optional API Key |
| TAU | Tautulli | Infrastructure | 8181 | Optional API Key |
| MNT | Maintainerr | Infrastructure | 6246 | Optional API Key |
| JEL | Jellyfin | Media | 8096 | Optional API Key |
| EMB | Emby | Media | 8096 | Optional API Key |
| PLX | Plex | Media | 32400 | Optional API Key |

---

## Search Services

### Prowlarr (PRO)

Indexer manager for Sonarr/Radarr integration.

**Docker Compose:**
```yaml
prowlarr:
  image: hotio/prowlarr:latest
  ports:
    - "9696:9696"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/prowlarr:/config
```

**YAHLP Configuration:**
```bash
PROWLARR_ENABLED=true
PROWLARR_URL=http://prowlarr:9696
PROWLARR_API_KEY=your-api-key  # Optional
```

**URL:** `https://yourdomain.com/prowlarr`

---

### Jackett (JAC)

Indexer aggregator and API proxy for torrent and usenet indexers.

**Docker Compose:**
```yaml
jackett:
  image: linuxserver/jackett:latest
  ports:
    - "9117:9117"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/jackett:/config
    - /etc/localtime:/etc/localtime:ro
```

**Get API Key:**
1. Access Jackett WebUI: `http://localhost:9117`
2. Click on "Admin" (top right)
3. Copy the API Key

**YAHLP Configuration:**
```bash
JACKETT_ENABLED=true
JACKETT_URL=http://jackett:9117
JACKETT_API_KEY=your-api-key  # Get from Admin page
```

**Health Check:**
The health check uses: `/api/v2.0/indexers/all/results?apikey=YOUR_KEY&Query=test`

**URL:** `https://yourdomain.com/jackett`

---

### Sonarr (SON)

TV series manager with automatic downloads.

**Docker Compose:**
```yaml
sonarr:
  image: linuxserver/sonarr:latest
  ports:
    - "8989:8989"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/sonarr:/config
    - /mnt/media/tv:/tv
    - /mnt/downloads:/downloads
```

**YAHLP Configuration:**
```bash
SONARR_ENABLED=true
SONARR_URL=http://sonarr:8989
# Optional - get from Settings > General > API Key
SONARR_API_KEY=your-api-key
# Optional - set landing page to calendar
SONARR_LANDING=sonarr/calendar
```

**URL:** `https://yourdomain.com/sonarr`

---

### Radarr (RAD)

Movie manager with automatic downloads.

**Docker Compose:**
```yaml
radarr:
  image: linuxserver/radarr:latest
  ports:
    - "7878:7878"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/radarr:/config
    - /mnt/media/movies:/movies
    - /mnt/downloads:/downloads
```

**YAHLP Configuration:**
```bash
RADARR_ENABLED=true
RADARR_URL=http://radarr:7878
RADARR_API_KEY=your-api-key  # Optional
```

**URL:** `https://yourdomain.com/radarr`

---

### Lidarr (LID)

Music manager with automatic downloads.

**Docker Compose:**
```yaml
lidarr:
  image: linuxserver/lidarr:latest
  ports:
    - "8686:8686"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/lidarr:/config
    - /mnt/media/music:/music
    - /mnt/downloads:/downloads
```

**YAHLP Configuration:**
```bash
LIDARR_ENABLED=true
LIDARR_URL=http://lidarr:8686
LIDARR_API_KEY=your-api-key  # Optional
```

**URL:** `https://yourdomain.com/lidarr`

---

### Whisparr (WHI)

Adult content manager with automatic downloads.

**Docker Compose:**
```yaml
whisparr:
  image: hotio/whisparr:latest
  ports:
    - "6969:6969"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/whisparr:/config
    - /mnt/media/adult:/adult
    - /mnt/downloads:/downloads
```

**YAHLP Configuration:**
```bash
WHISPARR_ENABLED=true
WHISPARR_URL=http://whisparr:6969
WHISPARR_API_KEY=your-api-key  # Optional
```

**URL:** `https://yourdomain.com/whisparr`

---

## Usenet Services

### SABnzbd (SAB)

Usenet/NZB download client.

**Docker Compose:**
```yaml
sabnzbd:
  image: linuxserver/sabnzbd:latest
  ports:
    - "8080:8080"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/sabnzbd:/config
    - /mnt/downloads:/downloads
```

**YAHLP Configuration:**
```bash
SABNZBD_ENABLED=true
SABNZBD_URL=http://sabnzbd:8080
SABNZBD_API_KEY=your-api-key  # Optional
```

**URL:** `https://yourdomain.com/sabnzbd`

---

### NZBGet (GET)

Lightweight NZB/usenet downloader.

**Docker Compose:**
```yaml
nzbget:
  image: hotio/nzbget:latest
  ports:
    - "6789:6789"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/nzbget:/config
    - /mnt/downloads:/downloads
```

**YAHLP Configuration:**
```bash
NZBGET_ENABLED=true
NZBGET_URL=http://nzbget:6789
NZBGET_USERNAME=your-username  # Optional
NZBGET_PASSWORD=your-password  # Optional
```

**Authentication:**
- NZBGet uses HTTP Basic Authentication
- Username and password are from NZBGet's settings
- Default: `nzbget` / `tegbzn6789` (change in NZBGet web UI)
- Leave empty if auth disabled in NZBGet

**URL:** `https://yourdomain.com/nzbget`

---

### NZBHydra (HYD)

NZB indexer proxy for multiple indexers.

**Docker Compose:**
```yaml
nzbhydra:
  image: hotio/nzbhydra2:latest
  ports:
    - "5076:5076"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/nzbhydra:/config
```

**YAHLP Configuration:**
```bash
NZBHYDRA_ENABLED=true
NZBHYDRA_URL=http://nzbhydra:5076
NZBHYDRA_API_KEY=your-api-key  # Optional
```

**URL:** `https://yourdomain.com/nzbhydra`

---

## Torrent Services

### Transmission (TRA)

Lightweight torrent client (no authentication).

**Docker Compose:**
```yaml
transmission:
  image: linuxserver/transmission:latest
  ports:
    - "6969:6969"
    - "6969:6969/udp"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/transmission:/config
    - /mnt/downloads:/downloads
```

**YAHLP Configuration:**
```bash
TRANSMISSION_ENABLED=true
TRANSMISSION_URL=http://transmission:6969
# No authentication needed
```

**URL:** `https://yourdomain.com/transmission`

---

### qBittorrent (QBI)

Feature-rich torrent client (requires API key).

**Docker Compose:**
```yaml
qbittorrent:
  image: linuxserver/qbittorrent:latest
  ports:
    - "8080:8080"
  environment:
    PUID: 1000
    PGID: 1000
    WEBUI_PORT: 8080
  volumes:
    - ./config/qbittorrent:/config
    - /mnt/downloads:/downloads
```

**Get API Key:**
1. Access qBittorrent WebUI
2. Tools → Options → Web UI → Authentication
3. Copy API Token

**YAHLP Configuration:**
```bash
QBITTORRENT_ENABLED=true
QBITTORRENT_URL=http://qbittorrent:8080
QBITTORRENT_API_KEY=your-api-token  # Required
```

**URL:** `https://yourdomain.com/qbittorrent`

---

### Deluge (DEL)

Powerful torrent client (requires password).

**Docker Compose:**
```yaml
deluge:
  image: linuxserver/deluge:latest
  ports:
    - "8112:8112"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/deluge:/config
    - /mnt/downloads:/downloads
```

**YAHLP Configuration:**
```bash
DELUGE_ENABLED=true
DELUGE_URL=http://deluge:8112
DELUGE_PASSWORD=your-password  # Required (set in deluge config)
```

**URL:** `https://yourdomain.com/deluge`

---

## Infrastructure Services

### Seerr (SEE)

Request and manage media requests.

**Docker Compose:**
```yaml
seerr:
  image: hotio/seerr:latest
  ports:
    - "5055:5055"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/seerr:/config
```

**YAHLP Configuration:**
```bash
SEERR_ENABLED=true
SEERR_URL=http://seerr:5055
SEERR_API_KEY=your-api-key  # Optional
```

**URL:** `https://yourdomain.com/seerr`

---

### Bazarr (BAZ)

Subtitle manager for TV and movies.

**Docker Compose:**
```yaml
bazarr:
  image: linuxserver/bazarr:latest
  ports:
    - "6767:6767"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/bazarr:/config
    - /mnt/media/tv:/tv
    - /mnt/media/movies:/movies
```

**YAHLP Configuration:**
```bash
BAZARR_ENABLED=true
BAZARR_URL=http://bazarr:6767
```

**URL:** `https://yourdomain.com/bazarr`

---

### Tautulli (TAU)

Plex monitoring and statistics.

**Docker Compose:**
```yaml
tautulli:
  image: linuxserver/tautulli:latest
  ports:
    - "8181:8181"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/tautulli:/config
```

**YAHLP Configuration:**
```bash
TAUTULLI_ENABLED=true
TAUTULLI_URL=http://tautulli:8181
TAUTULLI_API_KEY=your-api-key  # Optional
```

**URL:** `https://yourdomain.com/tautulli`

---

### Maintainerr (MNT)

Media library maintenance tool.

**Docker Compose:**
```yaml
maintainerr:
  image: hotio/maintainerr:latest
  ports:
    - "6246:6246"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/maintainerr:/config
```

**YAHLP Configuration:**
```bash
MAINTAINERR_ENABLED=true
MAINTAINERR_URL=http://maintainerr:6246
```

**URL:** `https://yourdomain.com/maintainerr`

---

## Media Services

### Jellyfin (JEL)

Open-source media server (free alternative to Plex).

**Docker Compose:**
```yaml
jellyfin:
  image: jellyfin/jellyfin:latest
  ports:
    - "8096:8096"
  environment:
    PUID: 1000
    PGID: 1000
  volumes:
    - ./config/jellyfin:/config
    - /mnt/media:/media
```

**YAHLP Configuration:**
```bash
JELLYFIN_ENABLED=true
JELLYFIN_URL=http://jellyfin:8096
JELLYFIN_API_KEY=your-api-key  # Optional
```

**URL:** `https://yourdomain.com/jellyfin`

---

### Emby (EMB)

Commercial media server.

**Docker Compose:**
```yaml
emby:
  image: emby/embyserver:latest
  ports:
    - "8096:8096"
  environment:
    UID: 1000
    GID: 1000
  volumes:
    - ./config/emby:/config
    - /mnt/media:/mnt/share1
```

**YAHLP Configuration:**
```bash
EMBY_ENABLED=true
EMBY_URL=http://emby:8096
EMBY_API_KEY=your-api-key  # Optional
# For public subdomain
EMBY_DOMAIN=emby.example.com
# For Google/Entra OAuth (required if using OAuth with Emby)
EMBY_REDIRECT_URI=https://emby.example.com/oauth2callback
```

**OAuth Setup (Optional):**
- If using Google or Entra authentication, Emby can be accessed via its own subdomain with OAuth
- Requires `EMBY_DOMAIN` and `EMBY_REDIRECT_URI` to be set
- Add `https://emby.example.com/oauth2callback` to your OAuth provider's redirect URIs

**URL:** `https://yourdomain.com/emby` or `https://emby.example.com` (if OAuth enabled)

---

### Plex (PLX)

Popular media server.

**Docker Compose:**
```yaml
plex:
  image: plexinc/pms-docker:latest
  ports:
    - "32400:32400"
  environment:
    PUID: 1000
    PGID: 1000
    PLEX_CLAIM: claim-token  # Get from plex.tv/claim
  volumes:
    - ./config/plex:/config
    - /mnt/media:/media
```

**YAHLP Configuration:**
```bash
PLEX_ENABLED=true
PLEX_URL=http://plex:32400
PLEX_API_KEY=your-api-key  # Optional
# For public subdomain
PLEX_DOMAIN=plex.example.com
# For Google/Entra OAuth (required if using OAuth with Plex)
PLEX_REDIRECT_URI=https://plex.example.com/oauth2callback
```

**OAuth Setup (Optional):**
- If using Google or Entra authentication, Plex can be accessed via its own subdomain with OAuth
- Requires `PLEX_DOMAIN` and `PLEX_REDIRECT_URI` to be set
- Add `https://plex.example.com/oauth2callback` to your OAuth provider's redirect URIs

**URL:** `https://yourdomain.com/plex` or `https://plex.example.com` (if OAuth enabled)

---

## Common Docker Compose

```yaml
version: '3.8'

networks:
  homelab:
    external: false

services:
  yahlp:
    build: ./yahlp
    container_name: yahlp
    networks:
      - homelab
    ports:
      - "80:80"
      - "443:443"
    environment:
      DOMAIN: media.example.com
      EMAIL: admin@example.com
      ACCESS_MODE: public
      SONARR_ENABLED: "true"
      SONARR_URL: http://sonarr:8989
      RADARR_ENABLED: "true"
      RADARR_URL: http://radarr:7878
      # ... more services
    volumes:
      - ./appdata:/etc/letsencrypt
      - ./config:/etc/yahlp

  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    networks:
      - homelab
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
    volumes:
      - ./config/sonarr:/config
      - /mnt/media/tv:/tv
      - /mnt/downloads:/downloads
    restart: unless-stopped

  radarr:
    image: linuxserver/radarr:latest
    container_name: radarr
    networks:
      - homelab
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
    volumes:
      - ./config/radarr:/config
      - /mnt/media/movies:/movies
      - /mnt/downloads:/downloads
    restart: unless-stopped

  # ... more services
```

---

## Getting API Keys

Most services generate API keys in their settings:

1. **Access service web UI** (usually port shown in table above)
2. **Navigate to Settings/Administration**
3. **Find "API Key" or "API Token" section**
4. **Copy the key**
5. **Add to YAHLP configuration**

Example (Sonarr):
- Access: `http://sonarr:8989`
- Go to: Settings → General → API Key
- Copy the 32-character key
- Add to `.env`: `SONARR_API_KEY=abc123def456...`

---

## See Also

- [CONFIGURATION.md](CONFIGURATION.md) - All configuration options
- [INSTALLATION.md](INSTALLATION.md) - Setup instructions
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Service troubleshooting
