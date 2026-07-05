# Backend API Proxy

YAHLP includes a small Node.js API aggregator (`proxy.js`) that the dashboard uses to fetch live status data (queue counts, session info, health, etc.) from your backend services. It securely handles requests to Plex, Sonarr, Radarr, Seerr, and the other supported services, avoiding CORS issues and keeping API tokens out of the browser.

## Why a Backend Proxy?

1. **CORS Avoidance** - Backend requests to your services don't trigger CORS restrictions
2. **Token Security** - API keys stay in backend environment variables (or a mounted config file), never exposed to the browser
3. **Cross-Origin Support** - Works with different IPs/domains without browser security restrictions

## How It Works

The proxy is **not a separate container** — it's a background Node.js process that the main YAHLP image starts automatically alongside Apache.

- The `Dockerfile` installs Node.js/npm into the same Debian/Apache image, copies `package.json` and `proxy.js` to `/opt/proxy`, and runs `npm install --production` at build time.
- `docker-entrypoint.sh` starts Apache in the foreground (`apache2ctl -D FOREGROUND`) as the container's main process, and launches the proxy as a background process (`cd /opt/proxy && node proxy.js &`) inside the same container.
- Apache forwards `/api/*` and `/health` internally to `http://localhost:3000` (the Node process on loopback), as configured in `apache-conf/reverse-proxy.conf.template`:
  ```apache
  ProxyPass /api http://localhost:3000/api
  ProxyPassReverse /api http://localhost:3000/api

  <Location /health>
      ProxyPass http://localhost:3000/health
      ProxyPassReverse http://localhost:3000/health
  </Location>
  ```

Because of this, `/api/*` and `/health` already ride through the normal Apache ports (80/443) that you expose for the dashboard. There is nothing to separately build, run, or reverse-proxy — the proxy just needs its target services configured via environment variables (or `yahlp.json`).

Note: the root `docker-compose.yml` also publishes port 3000 directly on the host (`"3000:3000"`). This is not required for the dashboard to work (all traffic can go through 80/443 via Apache's `/api` passthrough) — you can safely remove that port mapping if you don't need to hit the aggregator directly for debugging.

## Setup

There is no separate setup step. Just set the relevant `<SERVICE>_URL` / `<SERVICE>_API_KEY` (or service-specific equivalent) environment variables on the main `apache-reverse-proxy` container for whichever services you want status data from. The proxy picks these up automatically at container start.

```yaml
environment:
  PROXY_PORT: 3000            # optional, defaults to 3000 (internal/loopback only)

  PLEX_URL: http://plex:32400
  PLEX_API_KEY: ${PLEX_API_KEY}

  SONARR_URL: http://sonarr:8989
  SONARR_API_KEY: ${SONARR_API_KEY}

  SEERR_URL: http://seerr:5055
  SEERR_API_KEY: ${SEERR_API_KEY}
```

Services with no URL/key configured are simply skipped — the proxy logs them as not configured and returns an error only if the dashboard asks for that specific service's data.

### Configuration via yahlp.json (optional)

Instead of (or in addition to) environment variables, you can mount `/etc/yahlp/yahlp.json` into the container. Values under `services.<name>.url` / `services.<name>.api_key` (or the service-specific key name, e.g. `services.nzbget.pass`) take precedence over environment variables — see `getConfigValue()` in `proxy.js`.

```json
{
  "services": {
    "plex": { "url": "http://plex:32400", "api_key": "your-plex-token" },
    "sonarr": { "url": "http://sonarr:8989", "api_key": "your-sonarr-key" }
  }
}
```

### Per-service auth types

Each service uses whatever auth scheme it natively expects; the proxy translates the configured key/password into the right header or query string automatically:

| Service | Auth mechanism |
|---|---|
| Sonarr, Radarr, Lidarr, Whisparr, NZBHydra, Prowlarr, Seerr, Maintainerr | `X-Api-Key` header |
| Emby, qBittorrent, SABnzbd, Tautulli | `api_key` query string |
| Plex | `X-Plex-Token` query string |
| Jellyfin | `Authorization: MediaBrowser Token="..."` header |
| Bazarr | `X-API-KEY` header |
| Transmission | `X-Transmission-Session-Id` header (session negotiated automatically) |
| NZBGet | HTTP Basic auth (`NZBGET_USER` / `NZBGET_PASS`) over JSON-RPC |
| Deluge | Session cookie obtained via `auth.login` (`DELUGE_PASSWORD`) |

## Proxy Endpoints

The dashboard calls these routes on the same origin, via Apache's `/api` passthrough (e.g. `https://yourdomain.com/api/sonarr/queue`). They are served internally by `proxy.js` on `http://localhost:3000`:

| Route | Service |
|---|---|
| `GET /api/plex/server` | Plex server identity |
| `GET /api/seerr/status` | Seerr status |
| `GET /api/tautulli/status` | Tautulli library/user summary |
| `GET /api/bazarr/status` | Bazarr status |
| `GET /api/prowlarr/health` | Prowlarr health |
| `GET/POST /api/nzbhydra` | NZBHydra online check |
| `GET /api/sonarr/queue` | Sonarr download queue |
| `GET /api/radarr/queue` | Radarr download queue |
| `GET /api/lidarr/queue` | Lidarr download queue |
| `GET /api/whisparr/queue` | Whisparr download queue |
| `GET /api/qbittorrent/stats` | qBittorrent torrent stats |
| `POST /api/transmission/stats` | Transmission session stats |
| `GET /api/sabnzbd/stats` | SABnzbd queue stats |
| `POST /api/nzbget/stats` | NZBGet status |
| `GET /api/deluge/login` | Deluge session cookie (for the web UI) |
| `POST /api/deluge/stats` | Deluge torrent stats |
| `GET /api/jellyfin/info` | Jellyfin system info |
| `GET /api/emby/info` | Emby system info |
| `GET /api/maintainerr/api/overlays/sections` | Maintainerr overlay sections |
| `GET /api/maintainerr/api/storage-metrics/library-sizes` | Maintainerr library sizes |
| `GET /health` | Proxy health check + per-service configured status |

Responses are cached in-memory for 30 seconds (`node-cache`, `stdTTL: 30`) to reduce load on backend services.

## Advanced: Running the Proxy Standalone

`proxy.dockerfile` (a minimal `node:18-alpine` image running `npm start`) is included for advanced use cases where you want to run the Node aggregator as its own container, separate from the Apache image — for example, fronting services with a different reverse proxy entirely. This is not the default or documented path; most users never need it, since the proxy already runs automatically inside the main YAHLP container.

## Troubleshooting

### Dashboard shows no live status data for a service

1. Confirm the `<SERVICE>_URL` and `<SERVICE>_API_KEY` (or equivalent) environment variables are set on the `apache-reverse-proxy` container.
2. Check the proxy's startup log inside the container — it prints a configured/pending (✅/⏳) line per service:
   ```bash
   docker logs apache-reverse-proxy | grep -A20 "API Aggregator listening"
   ```
3. Check proxy health and per-service configured status:
   ```bash
   docker exec apache-reverse-proxy curl -s http://localhost:3000/health
   ```
4. Test a specific route directly against Apache's public port:
   ```bash
   curl https://yourdomain.com/api/sonarr/queue
   ```

### Getting HTTP 500 from an `/api/*` route

The proxy returns `{ "error": "<message>" }` with a 500 status when the backend service call fails (wrong URL, wrong key, service down, or non-2xx response). Check the container logs for the specific service (some handlers log with a `[SERVICE]` prefix, e.g. `[DELUGE]`, `[NZBGET]`, `[TRANSMISSION]`) and verify the backend service is reachable from inside the container:

```bash
docker exec apache-reverse-proxy curl -I http://sonarr:8989
```

## Performance

- Responses are cached for 30 seconds per endpoint to avoid hammering backend services.
- The proxy listens on both IPv4 and IPv6 inside the container. The dashboard reaches it via Apache's internal `ProxyPass` on `localhost:3000`, so it doesn't need port 3000 published on the host at all.
