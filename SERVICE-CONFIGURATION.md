# YAHLP Service Configuration Reference

Minimal setup for each service to work with YAHLP reverse proxy. This covers **ONLY** the settings required for YAHLP integration.

**Last Updated**: 2026-06-30  
**YAHLP Version**: v1.0.0

---

## Quick Reference Table

| Service | Code | URL Base Setting | Special Config | YAHLP `.env` |
|---------|------|-----------------|-----------------|---|
| **Sonarr** | SON | `/sonarr` | None | `ENABLE_SONARR=true` |
| **Radarr** | RAD | `/radarr` | None | `ENABLE_RADARR=true` |
| **Lidarr** | LID | `/lidarr` | None | `ENABLE_LIDARR=true` |
| **Whisparr** | WHI | `/whisparr` | None | `ENABLE_WHISPARR=true` |
| **Prowlarr** | PRO | `/prowlarr` | None | `ENABLE_PROWLARR=true` |
| **Seerr** | SEE | `/seerr` | Private mode only | `ENABLE_SEERR=true` |
| **Bazarr** | BAZ | `/bazarr` | None | `ENABLE_BAZARR=true` |
| **SABnzbd** | SAB | `/sabnzbd` | None | `ENABLE_SABNZBD=true` |
| **NZBGet** | GET | No URL Base needed | Base64 auth via YAHLP | `ENABLE_NZBGET=true` |
| **NZBHydra** | HYD | `/nzbhydra` | None | `ENABLE_NZBHYDRA=true` |
| **Transmission** | TRA | `/transmission/rpc` | Edit settings.json | `ENABLE_TRANSMISSION=true` |
| **qBittorrent** | QBI | No URL Base needed | None | `ENABLE_QBITTORRENT=true` |
| **Deluge** | DEL | No URL Base needed | None | `ENABLE_DELUGE=true` |
| **Jellyfin** | JEL | `/jellyfin` | None | `ENABLE_JELLYFIN=true` |
| **Emby** | EMB | No URL Base setting | None | `ENABLE_EMBY=true` |
| **Plex** | PLX | No URL Base setting | None | `ENABLE_PLEX=true` |
| **Tautulli** | TAU | `/tautulli` | None | `ENABLE_TAUTULLI=true` |
| **Maintainerr** | MNT | No URL Base needed | `BASE_PATH=/maintainerr` env var | `ENABLE_MAINTAINERR=true` |

---

## CONTENT Services

### Sonarr (SON)
**YAHLP Setting**: `Settings → General → URL Base` = `/sonarr`

1. Navigate to **Settings → General**
2. Find **URL Base**
3. Set to: `/sonarr`
4. Click **Save**
5. Restart Sonarr

---

### Radarr (RAD)
**YAHLP Setting**: `Settings → General → URL Base` = `/radarr`

1. Navigate to **Settings → General**
2. Find **URL Base**
3. Set to: `/radarr`
4. Click **Save**
5. Restart Radarr

---

### Lidarr (LID)
**YAHLP Setting**: `Settings → General → URL Base` = `/lidarr`

1. Navigate to **Settings → General**
2. Find **URL Base**
3. Set to: `/lidarr`
4. Click **Save**
5. Restart Lidarr

---

### Whisparr (WHI)
**YAHLP Setting**: `Settings → General → URL Base` = `/whisparr`

1. Navigate to **Settings → General**
2. Find **URL Base**
3. Set to: `/whisparr`
4. Click **Save**
5. Restart Whisparr

---

## SEARCH Services

### Prowlarr (PRO)
**YAHLP Setting**: `Settings → General → URL Base` = `/prowlarr`

1. Navigate to **Settings → General**
2. Find **URL Base**
3. Set to: `/prowlarr`
4. Click **Save**
5. Restart Prowlarr

---

### Seerr (SEE)
**YAHLP Setting**: `Settings → General → URL Base` = `/seerr`

⚠️ **Important**: Seerr requires **PRIVATE MODE** in YAHLP
```yaml
ACCESS_MODE: private
```

Seerr has its own OAuth flow for Plex - YAHLP private mode prevents additional auth layers from interfering.

1. Navigate to **Settings → General**
2. Find **Base URL**
3. Set to: `/seerr`
4. Click **Save**
5. Restart Seerr

---

### Bazarr (BAZ)
**YAHLP Setting**: `Settings → General → Base URL` = `/bazarr`

1. Navigate to **Settings → General**
2. Find **Base URL**
3. Set to: `/bazarr`
4. Click **Save**
5. Restart Bazarr

---

## USENET Services

### SABnzbd (SAB)
**YAHLP Setting**: `Settings → General → URL Base` = `/sabnzbd`

1. Navigate to **Settings → General**
2. Find **URL Base**
3. Set to: `/sabnzbd`
4. Click **Save**
5. Restart SABnzbd

---

### NZBGet (GET)
**YAHLP Handling**: YAHLP injects base64-encoded credentials via HTTP headers

⚠️ **Important**: Credentials configured in YAHLP `.env`:
```yaml
ENABLE_NZBGET: "true"
NZBGET_USER: "admin"
NZBGET_PASS: "yourpassword"
```

**NZBGet itself**: No special URL Base configuration needed. YAHLP handles authentication automatically via reverse proxy headers.

---

### NZBHydra (HYD)
**YAHLP Setting**: `Settings → Config → Base URL` = `/nzbhydra`

1. Navigate to **Settings → Config**
2. Find **Base URL**
3. Set to: `/nzbhydra`
4. Click **Save and Restart**

---

## TORRENTS Services

### Transmission (TRA)
**YAHLP Setting**: Edit `settings.json` → `rpc-url` = `/transmission/rpc`

Transmission uses settings.json file (not web UI):

1. Stop Transmission service
2. Edit `settings.json` (in Transmission config directory)
3. Find line: `"rpc-url": "/transmission/",`
4. Change to: `"rpc-url": "/transmission/rpc",`
5. Save file
6. Restart Transmission

Verify by accessing: `https://yourdomain.com/transmission`

---

### qBittorrent (QBI)
**YAHLP Setting**: No URL Base configuration needed

qBittorrent works with YAHLP proxy as-is. No special web UI settings required.

Access via: `https://yourdomain.com/qbittorrent`

---

### Deluge (DEL)
**YAHLP Setting**: No URL Base configuration needed

Deluge web UI works with YAHLP proxy as-is. No special settings required.

Access via: `https://yourdomain.com/deluge`

---

## MEDIA Services

### Jellyfin (JEL)
**YAHLP Setting**: `Dashboard → Settings → General → URL Base` = `/jellyfin`

1. Navigate to **Dashboard → Settings → General**
2. Find **URL Base**
3. Set to: `/jellyfin`
4. Click **Save**
5. Refresh browser (may need to restart Jellyfin)

---

### Emby (EMB)
**YAHLP Setting**: No URL Base configuration needed

Emby does not have a URL Base setting. Access via: `https://yourdomain.com/emby`

---

### Plex (PLX)
**YAHLP Setting**: No URL Base configuration needed

Plex does not have a URL Base setting. Access via: `https://yourdomain.com/plex`

---

### Tautulli (TAU)
**YAHLP Setting**: `Settings → Web Interface → URL Base` = `/tautulli`

1. Navigate to **Settings → Web Interface**
2. Find **URL Base**
3. Set to: `/tautulli`
4. Click **Save & Reload**

---

### Maintainerr (MNT)
**YAHLP Setting**: Docker environment variable `BASE_PATH` = `/maintainerr`

Maintainerr requires the Base Path to be set via Docker environment variable:

1. In `docker-compose.yml` (Maintainerr service), set:
   ```yaml
   environment:
     BASE_PATH: /maintainerr
   ```

2. Or if running standalone, set environment variable:
   ```bash
   export BASE_PATH=/maintainerr
   ```

3. Restart Maintainerr container

Access via: `https://yourdomain.com/maintainerr`

---

## Summary

**For Most Services**: Set **URL Base** (or equivalent) to the service path
- `/sonarr`, `/radarr`, `/jellyfin`, etc.

**Exceptions**:
- **NZBGet**: Handled by YAHLP (credentials in `.env`)
- **qBittorrent**: No URL Base setting
- **Deluge**: No URL Base setting
- **Transmission**: Edit `settings.json` → `rpc-url`
- **Plex**: No URL Base setting
- **Emby**: No URL Base setting
- **Maintainerr**: Set Docker environment variable `BASE_PATH=/maintainerr`

**Seerr**: Requires `ACCESS_MODE=private` in YAHLP

---

**Last Updated**: 2026-06-30  
**Services Covered**: 18/18
