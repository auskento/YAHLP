# Backend Proxy Setup for Plex & Seerr

The API dashboard uses a Node.js backend proxy to securely handle Plex and Seerr requests, avoiding CORS issues and keeping API tokens secure on the backend.

## Why a Backend Proxy?

1. **CORS Avoidance** - Backend requests to Plex/Seerr don't trigger CORS restrictions
2. **Token Security** - API keys stay in backend environment variables, never exposed to browser
3. **Cross-Origin Support** - Works with different IPs/domains without browser security restrictions

## Setup

### Option 1: Docker Compose (Recommended)

Add to your `docker-compose.yml`:

```yaml
proxy:
  build:
    context: .
    dockerfile: proxy.dockerfile
  ports:
    - "3000:3000"
  environment:
    - PROXY_PORT=3000
    - PLEX_URL=http://plex-server:32400
    - PLEX_API_KEY=${PLEX_API_KEY}
    - SEERR_URL=http://seerr:5055
    - SEERR_API_KEY=${SEERR_API_KEY}
  networks:
    - default
  restart: unless-stopped
```

### Option 2: Standalone Node.js

```bash
npm install
PLEX_URL=http://your-plex:32400 \
PLEX_API_KEY=your_token \
SEERR_URL=http://your-seerr:5055 \
SEERR_API_KEY=your_key \
npm start
```

## Environment Variables

| Variable | Required | Example |
|----------|----------|---------|
| `PLEX_URL` | Yes | `http://192.168.1.100:32400` |
| `PLEX_API_KEY` | Yes | Your Plex API token |
| `SEERR_URL` | Yes | `http://192.168.1.100:5055` |
| `SEERR_API_KEY` | Yes | Your Seerr API key |
| `PROXY_PORT` | No | `3000` (default) |

## Proxy Endpoints

Once running, the proxy provides these endpoints:

- **Plex Sessions**: `GET /proxy/plex/sessions`
  - Returns currently playing sessions
  - Token handled securely by proxy

- **Seerr Requests**: `GET /proxy/seerr/request/count`
  - Returns pending/approved request counts
  - No CORS issues

## Dashboard Integration

The dashboard automatically uses the proxy for Plex and Seerr:

- Plex calls: `http://localhost:3000/proxy/plex/sessions`
- Seerr calls: `http://localhost:3000/proxy/seerr/request/count`

No changes needed in the dashboard configuration.

## Behind a Reverse Proxy

If running behind a reverse proxy (nginx, Apache, etc.), update the proxy URLs in the dashboard template:

Change in `modern-api.template`:
```javascript
// From:
url = `http://localhost:3000/proxy/plex/sessions`;

// To:
url = `/api-proxy/plex/sessions`; // or wherever you proxy it
```

Add reverse proxy rule (nginx example):
```nginx
location /api-proxy/ {
  proxy_pass http://proxy-service:3000/proxy/;
}
```

## Troubleshooting

### Proxy won't connect to Plex/Seerr

1. Check environment variables are set correctly
2. Verify internal service URLs are correct (use service names in Docker)
3. Check logs: `docker logs yahlp-proxy`

### Still getting CORS errors

1. Ensure browser is calling proxy at `http://localhost:3000`, not Plex directly
2. Check dashboard console shows `(via proxy)` in log messages
3. Verify CORS is enabled in proxy.js

### Dashboard not seeing Plex/Seerr data

1. Check proxy health: `curl http://localhost:3000/health`
2. Test proxy endpoints directly:
   - `curl http://localhost:3000/proxy/plex/sessions`
   - `curl http://localhost:3000/proxy/seerr/request/count`
3. Check dashboard console for errors

## Performance

- Proxy adds ~50-100ms latency per request
- Caching can be added if needed
- Auto-refresh interval: 30 seconds (configurable in dashboard)
