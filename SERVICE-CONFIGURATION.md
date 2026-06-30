# YAHLP Service Configuration Guide

Complete setup instructions for all 18 services integrated with YAHLP reverse proxy.

**Last Updated**: 2026-06-30  
**YAHLP Version**: v1.0.0

---

## Table of Contents

1. [CONTENT Services](#content-services) - Sonarr, Radarr, Lidarr, Whisparr
2. [SEARCH Services](#search-services) - Prowlarr, Seerr, Bazarr
3. [USENET Services](#usenet-services) - SABnzbd, NZBGet, NZBHydra
4. [TORRENTS Services](#torrents-services) - Transmission, qBittorrent, Deluge
5. [MEDIA Services](#media-services) - Jellyfin, Emby, Plex, Tautulli, Maintainerr

---

## CONTENT Services

### 1. Sonarr (SON) - TV Show Management

**Access Path**: `https://yourdomain.com/sonarr`  
**Default Port**: 8989  
**Service Code**: `SON`

#### YAHLP Configuration

```yaml
ENABLE_SONARR: "true"
SONARR_URL: "http://sonarr:8989"
```

#### Sonarr Settings

1. **Settings → General → URL Base**
   - Set to: `/sonarr`
   - ✅ Save changes
   - *Why*: Allows Sonarr to generate correct URLs behind proxy

2. **Settings → Security → API Key**
   - Copy the API key (if required by other services)
   - Keep secure in `.env` or password manager

3. **Settings → Proxy Settings** (if behind corporate proxy)
   - Configure if your network requires upstream proxy
   - Leave blank for YAHLP setup

4. **Indexers Configuration**
   - Configure your preferred indexers (Prowlarr integration recommended)
   - See [Prowlarr Integration](#prowlarr-integration) section

#### Verification

```bash
# Test connection
curl https://yourdomain.com/sonarr/api/v3/config/host -H "X-Api-Key: YOUR_API_KEY"
# Should return 200 with JSON response
```

---

### 2. Radarr (RAD) - Movie Management

**Access Path**: `https://yourdomain.com/radarr`  
**Default Port**: 7878  
**Service Code**: `RAD`

#### YAHLP Configuration

```yaml
ENABLE_RADARR: "true"
RADARR_URL: "http://radarr:7878"
```

#### Radarr Settings

1. **Settings → General → URL Base**
   - Set to: `/radarr`
   - ✅ Save and restart

2. **Settings → Indexers**
   - Add indexers OR connect to Prowlarr (recommended)
   - Path: **Settings → Indexers → Custom Scripts** (if using webhooks)

3. **Settings → Download Clients**
   - Add your download client (see TORRENTS section)
   - Path format: Leave as default (Radarr handles)

4. **Settings → Quality Profiles**
   - Configure as needed for your library
   - Can sync profiles via API if desired

#### Verification

```bash
curl https://yourdomain.com/radarr/api/v3/system/status \
  -H "X-Api-Key: YOUR_API_KEY"
# Should return 200 with system info
```

---

### 3. Lidarr (LID) - Music Management

**Access Path**: `https://yourdomain.com/lidarr`  
**Default Port**: 8686  
**Service Code**: `LID`

#### YAHLP Configuration

```yaml
ENABLE_LIDARR: "true"
LIDARR_URL: "http://lidarr:8686"
```

#### Lidarr Settings

1. **Settings → General → URL Base**
   - Set to: `/lidarr`
   - ✅ Restart service

2. **Settings → Indexers**
   - Connect to Prowlarr for music indexers
   - Manual: Add music-specific indexers (Headphones, etc.)

3. **Settings → Download Clients**
   - Configure same download client as Sonarr/Radarr
   - Verify path handling

4. **Settings → Import Lists** (Optional)
   - Setup music import lists if desired
   - Requires API key configuration

#### Notes

- Music library detection may take time
- Ensure download client supports music formats (flac, mp3, etc.)

---

### 4. Whisparr (WHI) - Adult Content Management

**Access Path**: `https://yourdomain.com/whisparr`  
**Default Port**: 6969  
**Service Code**: `WHI`

#### YAHLP Configuration

```yaml
ENABLE_WHISPARR: "true"
WHISPARR_URL: "http://whisparr:6969"
```

#### Whisparr Settings

1. **Settings → General → URL Base**
   - Set to: `/whisparr`
   - ✅ Save and restart

2. **Settings → Indexers**
   - Add adult-specific indexers
   - Note: May require separate Prowlarr instance for adult content

3. **Settings → Download Clients**
   - Same configuration as Sonarr/Radarr
   - Ensure separate download path if needed

4. **Privacy Note**
   - Consider separate Docker network or host
   - Access control via YAHLP authentication recommended

---

## SEARCH Services

### 5. Prowlarr (PRO) - Indexer Management

**Access Path**: `https://yourdomain.com/prowlarr`  
**Default Port**: 9696  
**Service Code**: `PRO`

#### YAHLP Configuration

```yaml
ENABLE_PROWLARR: "true"
PROWLARR_URL: "http://prowlarr:9696"
```

#### Prowlarr Settings

1. **Settings → General → URL Base**
   - Set to: `/prowlarr`
   - ✅ Restart service

2. **Settings → Apps** - Configure Sonarr/Radarr/Lidarr Integration
   - For each app, add:
     - **Sync Level**: Full
     - **Name**: Sonarr (etc.)
     - **URL**: `https://yourdomain.com/sonarr` (via proxy) OR `http://sonarr:8989` (internal)
     - **API Key**: Copy from app's Settings → Security → API Key
   - ✅ Test connection should show ✓ Green

3. **Settings → Indexers**
   - Add your preferred indexers (Usenet/Torrent)
   - Prowlarr will sync to all connected apps automatically

4. **Settings → Proxy Settings** (if needed)
   - Configure upstream proxy if required

#### Prowlarr Integration Example

```yaml
# For Sonarr via YAHLP proxy:
URL: https://yourdomain.com/sonarr
API_KEY: [copy from Sonarr]

# Prowlarr will automatically:
# - Sync indexers to Sonarr
# - Test connectivity through YAHLP
# - Handle category mapping
```

#### Verification

```bash
# Fetch Prowlarr system status
curl https://yourdomain.com/prowlarr/api/v1/system/status \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

### 6. Seerr (SEE) - Request Management

**Access Path**: `https://yourdomain.com/seerr`  
**Default Port**: 5055  
**Service Code**: `SEE`

#### YAHLP Configuration (Private Mode)

```yaml
ENABLE_SEERR: "true"
SEERR_URL: "http://seerr:5055"
ACCESS_MODE: "private"      # Seerr requires private mode (no OAuth)
```

#### YAHLP Configuration (Public Mode - OAuth Required)

```yaml
ENABLE_SEERR: "true"
SEERR_URL: "http://seerr:5055"
ACCESS_MODE: "public"
AUTHTYPE: "basic"           # Use basic auth (OAuth flow in Seerr)
```

#### Seerr Settings

1. **Setup Wizard → Plex Login**
   - Authenticate with Plex account
   - Grant permission for server access

2. **Configuration → Services → Sonarr**
   - **URL**: `http://sonarr:8989` (internal) OR `https://yourdomain.com/sonarr` (proxy)
   - **API Key**: Copy from Sonarr Settings → Security
   - **Verify URL**: Should show ✓ Green

3. **Configuration → Services → Radarr**
   - **URL**: `http://radarr:7878` OR `https://yourdomain.com/radarr`
   - **API Key**: Copy from Radarr
   - **Verify URL**: Should show ✓ Green

4. **Configuration → Plex**
   - **Server**: Select your Plex server
   - **Library Sync**: Enable to sync libraries
   - **Request Notifications**: Configure as desired

5. **Configuration → Ombi (Optional)**
   - If using Ombi integration, configure here
   - Usually not needed with Seerr

#### Important: OAuth Configuration for Public Mode

If using Plex OAuth for Seerr in public mode:

1. **Seerr Settings → Authentication**
   - Enable Plex OAuth
   - Configure Plex API credentials
   - Users authenticate via Plex account

2. **YAHLP Role** (in public mode):
   - YAHLP authentication gates access
   - Inside, Seerr handles user identification via Plex
   - Maintain basic auth in YAHLP for security layer

#### Verification

```bash
# Test Seerr API
curl https://yourdomain.com/seerr/api/v1/settings/public \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

### 7. Bazarr (BAZ) - Subtitle Management

**Access Path**: `https://yourdomain.com/bazarr`  
**Default Port**: 6767  
**Service Code**: `BAZ`

#### YAHLP Configuration

```yaml
ENABLE_BAZARR: "true"
BAZARR_URL: "http://bazarr:6767"
```

#### Bazarr Settings

1. **Settings → General → Base URL**
   - Set to: `/bazarr`
   - ✅ Save

2. **Settings → Sonarr**
   - **URL**: `http://sonarr:8989` (internal) OR `https://yourdomain.com/sonarr` (proxy)
   - **API Key**: Copy from Sonarr
   - **Verify**: Should show ✓ Green

3. **Settings → Radarr**
   - **URL**: `http://radarr:7878` OR `https://yourdomain.com/radarr`
   - **API Key**: Copy from Radarr
   - **Verify**: Should show ✓ Green

4. **Settings → Subtitles → Subtitle Providers**
   - Add desired providers (OpenSubtitles, YIFY, etc.)
   - Configure API keys if required
   - Set language preferences

5. **Settings → Subtitles → Advanced**
   - Configure minimum score for automatic download
   - Set HI (Hearing Impaired) subtitle preferences
   - Enable automatic search on new episodes/movies

#### Verification

```bash
# Test Bazarr connectivity
curl https://yourdomain.com/bazarr/api/system/status \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## USENET Services

### 8. SABnzbd (SAB) - Usenet Client

**Access Path**: `https://yourdomain.com/sabnzbd`  
**Default Port**: 8080  
**Service Code**: `SAB`

#### YAHLP Configuration

```yaml
ENABLE_SABNZBD: "true"
SABNZBD_URL: "http://sabnzbd:8080"
```

#### SABnzbd Settings

1. **Settings → General → URL Base**
   - Set to: `/sabnzbd`
   - ✅ Restart service

2. **Settings → Servers**
   - Add your Usenet server(s)
   - Configure API key for each connection
   - Set retention, port, and SSL options

3. **Settings → Security → API Key**
   - Generate or copy existing API key
   - Use in Sonarr/Radarr/Lidarr

4. **Settings → Categories**
   - Ensure categories match expectations:
     - tv, movies, music, etc.
   - Map in Sonarr/Radarr as needed

#### Sonarr/Radarr Integration

```yaml
# In Sonarr/Radarr: Settings → Download Clients
Client Type: SABnzbd
URL: http://sabnzbd:8080    # Internal URL
API Key: [from SABnzbd settings]
Category: tv                # or 'movies' for Radarr
Test: Should show ✓ Green
```

#### Verification

```bash
# Test SABnzbd API
curl http://sabnzbd:8080/api?output=json&function=queue \
  -H "Authorization: SABnzbd YOUR_API_KEY"
```

---

### 9. NZBGet (GET) - Usenet Client

**Access Path**: `https://yourdomain.com/nzbget`  
**Default Port**: 6789  
**Service Code**: `GET`

#### YAHLP Configuration

⚠️ **Special**: NZBGet requires base64-encoded credentials in YAHLP

```yaml
ENABLE_NZBGET: "true"
NZBGET_URL: "http://nzbget:6789"
NZBGET_USER: "admin"        # Default username
NZBGET_PASS: "tegbzn6789"   # Default password (change immediately!)
```

#### NZBGet Settings

1. **Settings → Security → Username/Password**
   - Change default credentials immediately
   - Use strong password
   - YAHLP will base64-encode for proxy headers

2. **Settings → News Servers**
   - Add Usenet server(s)
   - Configure retention and speed
   - Enable SSL if available

3. **Settings → Categories**
   - tv, movies, music, etc.
   - Set paths per category

4. **Settings → API**
   - API is automatically accessible via YAHLP proxy
   - Authorization header handled by YAHLP reverse proxy

#### Sonarr/Radarr Integration

```yaml
# In Sonarr/Radarr: Settings → Download Clients
Client Type: NZBGet
URL: http://nzbget:6789     # Internal URL (authorization via proxy)
OR
URL: https://yourdomain.com/nzbget  # Via proxy (credentials in URL)
Username: admin
Password: tegbzn6789
Category: tv                # 'movies' for Radarr
Test: Should show ✓ Green
```

#### How YAHLP Handles NZBGet Auth

YAHLP converts NZBGET_USER:NZBGET_PASS to base64 and injects Authorization header:

```apache
# In apache-conf/services/nzbget.conf
RequestHeader set Authorization 'Basic QWRtaW46dGVnYnpuNjc4OQ=='
```

This allows external apps to access NZBGet without credentials in URL.

#### Verification

```bash
# Test via YAHLP proxy
curl https://yourdomain.com/nzbget/jsonrpc \
  -d '{"jsonrpc":"2.0","method":"version","params":[],"id":1}' \
  -H "Content-Type: application/json"
```

---

### 10. NZBHydra (HYD) - Usenet Index Aggregator

**Access Path**: `https://yourdomain.com/nzbhydra`  
**Default Port**: 5076  
**Service Code**: `HYD`

#### YAHLP Configuration

```yaml
ENABLE_NZBHYDRA: "true"
NZBHYDRA_URL: "http://nzbhydra:5076"
```

#### NZBHydra Settings

1. **Config → Host Name / Base URL**
   - **Host**: Set to your Docker container hostname or 0.0.0.0
   - **Base URL**: Set to `/nzbhydra`
   - ✅ Save and restart

2. **Config → Search Indexers**
   - Add Usenet indexers:
     - NZBGeek, NzbClub, Newznab, etc.
   - Set search timeout: 5-10s
   - Enable/disable as needed

3. **Config → Downloaders**
   - Add SABnzbd OR NZBGet
   - URL: `http://sabnzbd:8080` or `http://nzbget:6789`
   - API Key: From SABnzbd/NZBGet settings
   - Test connection

4. **Config → Authentication (if enabled)**
   - Set username/password if needed
   - YAHLP will proxy through authentication

#### Prowlarr Integration

NZBHydra can be used as a Newznab indexer in Prowlarr:

```yaml
# Prowlarr Settings → Indexers → Add Newznab
URL: http://nzbhydra:5076/api?apikey=YOUR_API_KEY
```

#### Verification

```bash
# Test NZBHydra search
curl https://yourdomain.com/nzbhydra/api?t=search&q=test
```

---

## TORRENTS Services

### 11. Transmission (TRA) - Torrent Client

**Access Path**: `https://yourdomain.com/transmission`  
**Default Port**: 6969  
**Service Code**: `TRA`

#### YAHLP Configuration

```yaml
ENABLE_TRANSMISSION: "true"
TRANSMISSION_URL: "http://transmission:6969"
```

#### Transmission Settings

1. **Edit settings.json → rpc-url**
   - Set to: `/transmission/rpc`
   - ✅ Restart service

2. **Edit settings.json → rpc-username / rpc-password**
   - Set username and password
   - Use for Sonarr/Radarr integration

3. **Edit settings.json → download-dir**
   - Ensure persistent volume mapping in docker-compose
   - Should be readable by other services

4. **Network Settings**
   - peer-port: Set unique port (e.g., 51413)
   - bandwidth-high/low: Configure speed limits

#### Sonarr/Radarr Integration

```yaml
# In Sonarr/Radarr: Settings → Download Clients
Client Type: Transmission
Host: transmission          # Internal Docker hostname
Port: 6969
Username: [transmission username]
Password: [transmission password]
Category: tv               # 'movies' for Radarr
Use SSL: Unchecked (internal network)
Test: Should show ✓ Green
```

#### Verification

```bash
# Test via proxy
curl https://yourdomain.com/transmission/rpc \
  -u username:password \
  -H "X-Transmission-Session-ID: ANY" \
  -d '{"method":"session-get"}'
```

---

### 12. qBittorrent (QBI) - Torrent Client

**Access Path**: `https://yourdomain.com/qbittorrent`  
**Default Port**: 8080  
**Service Code**: `QBI`

#### YAHLP Configuration

```yaml
ENABLE_QBITTORRENT: "true"
QBITTORRENT_URL: "http://qbittorrent:8080"
```

#### qBittorrent Settings

1. **Tools → Options → Web UI → Web User Interface (Remote control)**
   - ✅ Enable listening on all interfaces (0.0.0.0:8080)
   - Set username and password

2. **Tools → Options → Web UI → Security**
   - Ban threshold: Reasonable value (e.g., 5)
   - Max failed login attempts: 3

3. **Tools → Options → Advanced → Alternative Web UI**
   - Keep default (or use VueTorrent if preferred)

4. **Tools → Options → Downloads**
   - Set save path to persistent volume
   - Ensure readable by other services

5. **Tools → Options → BitTorrent → Network Interface**
   - Bind to specific interface if needed (usually auto is fine)

#### Sonarr/Radarr Integration

```yaml
# In Sonarr/Radarr: Settings → Download Clients
Client Type: qBittorrent
Host: qbittorrent
Port: 8080
Username: admin             # Default
Password: [your password]
Category: tv                # 'movies' for Radarr
Use SSL: Unchecked
Test: Should show ✓ Green

# Advanced (optional):
Initial State: Force Start
Sequential Download: Off
First/Last Piece Priority: Off
```

#### Notes

- qBittorrent has built-in web UI (no separate client needed)
- Supports search plugins for TPB, 1337x, etc.
- Can be used as Prowlarr torrent source

#### Verification

```bash
# Test via proxy (get auth cookie first)
curl https://yourdomain.com/qbittorrent/api/v2/auth/login \
  -d "username=admin&password=password"
```

---

### 13. Deluge (DEL) - Torrent Client

**Access Path**: `https://yourdomain.com/deluge`  
**Default Port**: 8112  
**Service Code**: `DEL`

#### YAHLP Configuration

```yaml
ENABLE_DELUGE: "true"
DELUGE_URL: "http://deluge:8112"
```

#### Deluge Settings

1. **Preferences → Server → Daemon Port**
   - Default: 58846
   - Keep as default for internal service-to-service comm.

2. **Preferences → Server → Allow Remote Connections**
   - ✅ Enable if using external clients
   - Configure username/password

3. **Preferences → Web → Port & SSL**
   - Port: 8112 (default)
   - SSL: Can enable (handled by YAHLP)

4. **Preferences → Downloads**
   - Download folder: Persistent volume
   - Move completed to folder: [your path]

5. **Preferences → Network**
   - Bind interface: 0.0.0.0 (Docker)
   - Incoming ports: Configure range if desired

#### Sonarr/Radarr Integration

```yaml
# In Sonarr/Radarr: Settings → Download Clients
Client Type: Deluge (via HTTP)
Host: deluge
Port: 8112
Username: localclient     # Default Deluge user
Password: [deluge password]
Category: tv              # 'movies' for Radarr
Use SSL: Unchecked
Test: Should show ✓ Green
```

#### Notes

- Deluge supports plugins (search plugins, ratio plugins, etc.)
- Default username is often "localclient" - change password!
- Supports remote connections (daemon) for external clients

#### Verification

```bash
# Test via proxy
curl https://yourdomain.com/deluge/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"1","method":"auth.login","params":["username","password"]}'
```

---

## MEDIA Services

### 14. Jellyfin (JEL) - Media Server

**Access Path**: `https://yourdomain.com/jellyfin`  
**Default Port**: 8096  
**Service Code**: `JEL`

#### YAHLP Configuration

```yaml
ENABLE_JELLYFIN: "true"
JELLYFIN_URL: "http://jellyfin:8096"
```

#### Jellyfin Settings

1. **Dashboard → Settings → General → URL Base**
   - Set to: `/jellyfin`
   - ✅ Save

2. **Playback → Streaming**
   - Transcoding: Configure bitrate limits if desired
   - Direct play quality: Set based on client needs

3. **Libraries**
   - Add libraries (Movies, TV Shows, Music, etc.)
   - Scan folders pointing to media volumes
   - Configure automatic scanning

4. **Users & Permissions**
   - Create library-specific access if needed
   - Default: Admin user has full access

5. **Plugins** (Optional)
   - Can install plugins for additional functionality
   - Ensure plugins are compatible with YAHLP proxy

#### Important: Public vs Private Mode

**Private Mode**: Jellyfin accessible to local network (recommended for family)
```yaml
ACCESS_MODE: private
AUTHTYPE: none
# Jellyfin's own auth handles users
```

**Public Mode**: Consider authentication layer
```yaml
ACCESS_MODE: public
AUTHTYPE: basic
# YAHLP auth + Jellyfin's internal auth = 2FA-like setup
```

#### Client Access (Desktop/Mobile)

Users can access via:
- `https://yourdomain.com/jellyfin` (browser)
- Jellyfin apps configured with base URL: `https://yourdomain.com/jellyfin`

#### Verification

```bash
# Test Jellyfin API
curl https://yourdomain.com/jellyfin/api/system/info
# Should return 200 with system info
```

---

### 15. Emby (EMB) - Media Server

**Access Path**: `https://yourdomain.com/emby`  
**Default Port**: 8096  
**Service Code**: `EMB`

#### YAHLP Configuration

```yaml
ENABLE_EMBY: "true"
EMBY_URL: "http://emby:8096"
```

#### Emby Settings

1. **Settings → Server → Remote Access**
   - ✅ Enable remote access
   - External URL: `https://yourdomain.com/emby`
   - HTTP Port: 8096
   - Use HTTPS: ✓ (handled by YAHLP)

2. **Settings → Server → Base URL**
   - Set to: `/emby`
   - ✅ Restart

3. **Settings → Library**
   - Add folders for Movies, TV, Music
   - Configure folder locations

4. **Settings → Playback**
   - Transcoding: Configure as needed
   - Quality: Set for various client types

5. **Settings → Users**
   - Create user accounts with appropriate permissions
   - Configure library access per user

#### Emby vs Jellyfin

| Feature | Jellyfin | Emby |
|---------|----------|------|
| License | Free/Open Source | Subscription ($120/year) |
| Direct Access | Via proxy | Via proxy + Emby servers |
| Plugins | Community | Official + Premium |
| Support | Community | Official |

**YAHLP works with both identically for reverse proxy**

#### Verification

```bash
# Test Emby API (requires API key)
curl https://yourdomain.com/emby/api/system/info/public
```

---

### 16. Plex (PLX) - Media Server

**Access Path**: `https://yourdomain.com/plex`  
**Default Port**: 32400  
**Service Code**: `PLX`

#### YAHLP Configuration

```yaml
ENABLE_PLEX: "true"
PLEX_URL: "http://plex:32400"
```

#### Plex Settings

1. **Settings → Remote Access**
   - ✅ Enable
   - Verify external access shows ✓ Green (may take time)

2. **Settings → Web → Base URL**
   - Set to: `/plex`
   - ✅ Save

3. **Libraries**
   - Add movies, TV, music libraries
   - Point to mounted volumes

4. **Remote Sharing**
   - Share libraries with Plex friends
   - Configure user permissions

#### Important: Plex + YAHLP Considerations

⚠️ **Plex has its own authentication** - YAHLP authentication adds a second layer:

```yaml
# Example: Public mode with YAHLP auth + Plex auth
ACCESS_MODE: public
AUTHTYPE: basic
BASIC_AUTH_CREDENTIALS: "user1:pass1"

# User flow:
# 1. Login to YAHLP (basic auth)
# 2. Plex prompts for Plex login
# 3. Access Plex library
```

#### Seerr Integration

Seerr can request content for Plex libraries (when Sonarr/Radarr are configured as downloaders).

#### Remote Access

Plex can be accessed:
- Via `https://yourdomain.com/plex` (through YAHLP)
- Via Plex app (configured with Plex server URL)
- Direct URL: `https://yourdomain.com:32400` (if port exposed, not recommended)

#### Verification

```bash
# Test Plex API
curl https://yourdomain.com/plex/api/v2/user
# May require Plex token for authentication
```

---

### 17. Tautulli (TAU) - Plex Analytics

**Access Path**: `https://yourdomain.com/tautulli`  
**Default Port**: 8181  
**Service Code**: `TAU`

#### YAHLP Configuration

```yaml
ENABLE_TAUTULLI: "true"
TAUTULLI_URL: "http://tautulli:8181"
```

#### Tautulli Settings

1. **Settings → Web Interface → URL Base**
   - Set to: `/tautulli`
   - ✅ Save & Reload

2. **Settings → Plex Media Server**
   - **Plex URL**: `http://plex:32400` (internal)
   - **Plex API Token**: Copy from Plex settings
     - Get token: Settings → Account → Authorized Applications
   - **Test Connection**: Should show ✓

3. **Settings → Notifications** (Optional)
   - Configure play, stop, pause notifications
   - Email, Discord, Telegram, etc.

4. **Settings → Graphs → Show Stats**
   - Enable graphs for watch history
   - Configure retention: 30, 60, 90 days, etc.

#### Tautulli Capabilities

- Monitor Plex playback in real-time
- Track user watching patterns
- Generate statistics & reports
- Send notifications on playback events
- Collect watch history long-term

#### Verification

```bash
# Test Tautulli API
curl https://yourdomain.com/tautulli/api/v2?apikey=YOUR_API_KEY&cmd=get_activity
```

---

### 18. Maintainerr (MNT) - Service Health Monitor

**Access Path**: `https://yourdomain.com/maintainerr`  
**Default Port**: 6246  
**Service Code**: `MNT`

#### YAHLP Configuration

```yaml
ENABLE_MAINTAINERR: "true"
MAINTAINERR_URL: "http://maintainerr:6246"
```

#### Maintainerr Setup

1. **Initial Setup Wizard**
   - Set application name: "YAHLP" (or custom)
   - Configure theme (light/dark)
   - Set default view

2. **Add Services (via Web UI)**
   - Click "Add Service"
   - For each service:
     - **Name**: Sonarr, Radarr, etc.
     - **URL**: `https://yourdomain.com/[service]` (via proxy)
     - **API Key**: Copy from service settings
     - **Type**: Select service type (Sonarr, Radarr, Jellyfin, etc.)
     - **Test**: Verify connection

3. **Maintainerr Configuration**
   - View dashboard with service health status
   - Green = Online, Red = Offline
   - Shows basic service statistics

4. **Notifications** (Optional)
   - Configure alerts for service downtime
   - Email, Discord, Telegram support

#### Services to Monitor

```yaml
# Recommended configuration:
Sonarr:      https://yourdomain.com/sonarr (API Key)
Radarr:      https://yourdomain.com/radarr (API Key)
Bazarr:      https://yourdomain.com/bazarr (API Key)
Prowlarr:    https://yourdomain.com/prowlarr (API Key)
Jellyfin:    https://yourdomain.com/jellyfin
qBittorrent: https://yourdomain.com/qbittorrent
NZBGet:      https://yourdomain.com/nzbget (includes auth)
SABnzbd:     https://yourdomain.com/sabnzbd (API Key)
```

#### Use Cases

1. **Monitoring**: Quick health check dashboard
2. **Alerts**: Get notified when service goes down
3. **Status Page**: Share public status with family/users
4. **Troubleshooting**: Identify which service is offline

#### Verification

```bash
# Test Maintainerr API
curl https://yourdomain.com/maintainerr/api/health
```

---

## Common Configuration Patterns

### Pattern 1: Complete Media Stack

```yaml
# All services enabled and integrated

# CONTENT
ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_LIDARR=true
ENABLE_WHISPARR=true

# SEARCH
ENABLE_PROWLARR=true
ENABLE_SEERR=true
ENABLE_BAZARR=true

# USENET
ENABLE_SABNZBD=true
ENABLE_NZBGET=true
ENABLE_NZBHYDRA=true

# TORRENTS
ENABLE_QBITTORRENT=true
ENABLE_TRANSMISSION=true
ENABLE_DELUGE=true

# MEDIA
ENABLE_JELLYFIN=true
ENABLE_PLEX=true
ENABLE_TAUTULLI=true
ENABLE_MAINTAINERR=true

# DASHBOARD
STYLE=modern
DASHBOARD_NAME="Complete Media Server"
DASHBOARD_ORDER=MEDIA,CONTENT,SEARCH,USENET,TORRENTS
```

### Pattern 2: TV Only (Minimal)

```yaml
# Just TV show management

ENABLE_SONARR=true
ENABLE_BAZARR=true
ENABLE_QBITTORRENT=true
ENABLE_JELLYFIN=true
ENABLE_TAUTULLI=true

STYLE=classic
DASHBOARD_NAME="TV Server"
DASHBOARD_LANDING=sonarr/series
```

### Pattern 3: Multi-User Family

```yaml
# Family with shared Jellyfin

ACCESS_MODE=public
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS="dad:password1|mom:password2|kid:password3"

ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_JELLYFIN=true
ENABLE_PLEX=true
ENABLE_TAUTULLI=true

DASHBOARD_COLOR=#2c3e50
DASHBOARD_NAME="Family Media Server"
```

### Pattern 4: Usenet Focus

```yaml
# Usenet indexing and downloading

ENABLE_NZBHYDRA=true
ENABLE_SABNZBD=true
ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_BAZARR=true

DASHBOARD_ORDER=USENET,CONTENT,SEARCH,MEDIA
```

---

## API Key Management

### How to Get API Keys

| Service | Location | How to Copy |
|---------|----------|-------------|
| **Sonarr** | Settings → Security → API Key | Copy full string |
| **Radarr** | Settings → Security → API Key | Copy full string |
| **Lidarr** | Settings → Security → API Key | Copy full string |
| **Whisparr** | Settings → Security → API Key | Copy full string |
| **Prowlarr** | Settings → Security → API Key | Copy full string |
| **Seerr** | Settings → API Keys → Create API Key | Copy full string |
| **Bazarr** | Settings → API Key | Copy full string |
| **SABnzbd** | Settings → Security → API Key | Copy full string |
| **qBittorrent** | No API key, uses user/pass | Use username/password |
| **Deluge** | No API key, uses user/pass | Use username/password |
| **Jellyfin** | No API key required (public API) | - |
| **Plex** | Account → Authorized Devices → Token | See: https://support.plex.tv/articles/204059436 |
| **Tautulli** | Settings → Web Interface → API Key | Copy full string |

### Storing API Keys Securely

⚠️ **Never commit `.env` file with keys to Git!**

```bash
# .gitignore should include:
.env
.env.local
docker-compose.override.yml
```

**Recommended**: Use Docker secrets or external vault (Hashicorp Vault, etc.)

---

## Troubleshooting Service Connectivity

### 502 Bad Gateway

**Symptom**: Service returns HTTP 502 error

**Debug Steps**:

```bash
# 1. Verify service is running
docker-compose ps sonarr

# 2. Check service URL in YAHLP config
cat .env | grep SONARR_URL

# 3. Test connectivity from YAHLP container
docker-compose exec yahlp curl -v http://sonarr:8989

# 4. Check Apache logs
docker-compose logs yahlp | grep -i error

# 5. Verify Apache config has service
docker-compose exec yahlp cat /etc/apache2/sites-enabled/reverse-proxy.conf | grep -i sonarr
```

### Authentication Failures

**Symptom**: API requests return 401 Unauthorized

```bash
# 1. Verify API key is correct
# Copy from Settings → Security → API Key

# 2. Test API call with key
curl https://yourdomain.com/sonarr/api/v3/config/host \
  -H "X-Api-Key: PASTE_YOUR_KEY_HERE"

# 3. Check YAHLP auth layer (if enabled)
# Ensure AUTHTYPE is configured for your mode
```

### Service Integration Failures

**Symptom**: Service can't connect to another service in YAHLP

```bash
# Example: Prowlarr can't connect to Sonarr

# 1. Try internal URL first (always more reliable)
URL: http://sonarr:8989
# NOT: https://yourdomain.com/sonarr (slower, potential cert issues)

# 2. If internal doesn't work:
docker-compose exec yahlp curl http://sonarr:8989/sonarr
# Should return HTML, not connection refused

# 3. If using proxy URL:
URL: https://yourdomain.com/sonarr
# Ensure HTTPS works and certificate is valid
# May need to disable SSL verification in some apps
```

---

## Summary Checklist

For each service you enable:

- [ ] Added `ENABLE_SERVICENAME=true` to `.env`
- [ ] Added `SERVICENAME_URL=http://...` to `.env`
- [ ] Set URL Base in service settings to `/servicename`
- [ ] Tested connectivity via `curl` command
- [ ] Integrated with dependent services (if applicable)
- [ ] Configured for private/public mode appropriately
- [ ] Added API key to password manager (if required)
- [ ] Verified in dashboard that service appears

---

**Last Updated**: 2026-06-30  
**YAHLP Version**: v1.0.0  
**Services Covered**: 18/18
