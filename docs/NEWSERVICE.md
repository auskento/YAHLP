# Adding a New Service to YAHLP

## Information Required

To add a service cleanly from the start, gather this information:

### Service Identification
- **Service name** (lowercase, no spaces: e.g., `jackett`)
- **Service code** (2-3 uppercase letters: e.g., `JAC`)
- **Display name** (user-friendly: e.g., `Jackett`)

### Network Configuration
- **Internal port** (Docker container port: e.g., `9117`)
- **BaseURL setting** (if the app uses one: e.g., `/jackett`)
- **Proxy path** (whether it proxies to root `/` or to a named path: e.g., `/sonarr`)
  - Services that proxy to root: deluge, qbittorrent, seerr, nzbget, jackett
  - Most others proxy to `/{service_name}`

### API Health Check
- **Health check endpoint** (path relative to service: e.g., `/api/v2.0/indexers/all/results`)
- **HTTP method** (GET or POST)
- **API key format:**
  - Query parameter name (e.g., `apikey=`)
  - Header name (e.g., `X-API-Key:`)
  - Or other authentication method
- **Required parameters** (e.g., `Query=test`)
- **Expected response format** (what field indicates status/health)
- **Example working curl command** (for verification)

### UI Configuration
- **Dashboard category** (SEARCH, USENET, MEDIA, TORRENTS, etc.)
- **Icon URL** (where to download the service icon from)
- **Short description** (1-2 words: e.g., `Indexer aggregator`)
- **Dashboard color code** (hex: e.g., `#0d47a1`)

### Configuration Requirements
- **Required config fields** (URL, API key, username/password, etc.)
- **Default values** (if any)
- **Special environment variables** (if needed)

## Example Information Checklist

```
Service: Jackett
Code: JAC
Display Name: Jackett
Port: 9117
BaseURL: /jackett
Proxy Path: /jackett/ (proxies to root)
Health Endpoint: /jackett/api/v2.0/indexers/all/results?apikey={apikey}&Query=test
HTTP Method: GET
API Key Format: Query parameter (apikey=)
Response Field: Results (array)
Category: SEARCH
Icon URL: https://raw.githubusercontent.com/Jackett/Jackett/master/src/Jackett.Common/Definitions/jackett.png
Description: Indexer aggregator
Color: #0d47a1
Config Fields: url, api_key
Example Curl: curl "http://192.168.9.13:9117/jackett/api/v2.0/indexers/all/results?apikey=YOUR_KEY&Query=test"
```

## Implementation Steps

Once you have the information, modify these files in order:

### 1. generate-html-menu.sh

Add service to three locations:

**SERVICE_CODE_MAP (early in file):**
```bash
[JAC]="JACKETT"
```

**SERVICES array (within appropriate section):**
```bash
[JACKETT]="SEARCH|Jackett|Indexer aggregator|/icons/jackett.png|/jackett/|#0d47a1"
```

**SERVICE_ORDER (within appropriate category section):**
```bash
SEARCH="... JACKETT ..."
```

### 2. apache-conf/services/{service}.conf (create new file)

Example for jackett.conf:
```apache
<Location /jackett>
    ProxyPass http://jackett:9117/jackett
    ProxyPassReverse http://jackett:9117/jackett

    ProxyPreserveHost On
    RequestHeader set X-Real-IP %{REMOTE_ADDR}s
    RequestHeader set X-Forwarded-For %{HTTP:X-Forwarded-For}e
    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Host %{HTTP_HOST}e
</Location>
```

### 3. docker-entrypoint.sh

Add enable flag (around line 111):
```bash
ENABLE_JACKETT="${JACKETT_ENABLED:-false}"
```

Add to env.conf output (around line 143):
```bash
ENABLE_JACKETT="${ENABLE_JACKETT}"
```

### 4. apache-conf/reverse-proxy.conf.template

Add placeholder include (with other service includes):
```apache
@@INCLUDE_JACKETT@@
```

### 5. generate-config.sh

**If service proxies to root** (lines 44, 53), add to special handling:
```bash
[ "$service_name" = "jackett" ]
```

**Add service processing** (around line 87):
```bash
[ "$ENABLE_JACKETT" = "true" ] && process_service_config "jackett" "9117"
```

**Generate include directive** (around line 152):
```bash
JACKETT_INCLUDE=$(generate_include "jackett" "$ENABLE_JACKETT")
```

**Replace placeholder** (around line 262):
```bash
CONFIG="${CONFIG//@@INCLUDE_JACKETT@@/$JACKETT_INCLUDE}"
```

### 6. download-icons.sh

Add to ICON_URLS array (line 18-38):
```bash
[JACKETT]="${ICON_URL_JACKETT}"
```

### 7. proxy.js

**Add service configuration** (around line 154, services object):
```javascript
'jackett': { url: getConfigValue('jackett', 'url'), key: getConfigValue('jackett', 'api_key'), authType: 'query' },
```

**Add to service code mapping** (around line 863):
```javascript
'JAC': 'jackett'
```

**Add health check endpoint** (around line 351-380):
```javascript
app.get('/api/jackett/health', async (req, res) => {
  try {
    const cached = cache.get('jackett-health');
    if (cached) return res.json(cached);

    const config = services['jackett'];
    if (!config || !config.url || !config.key) {
      return res.status(404).json({ error: 'Jackett not configured' });
    }

    const healthUrl = `${config.url}/jackett/api/v2.0/indexers/all/results?apikey=${encodeURIComponent(config.key)}&Query=test`;

    console.log('[Jackett Health Check]', { url: healthUrl });

    const response = await fetch(healthUrl);

    if (!response.ok) {
      const errorBody = await response.text();
      console.log('[Jackett Health Check Error]', { status: response.status, body: errorBody });
      return res.status(response.status).json({ error: 'Jackett offline', details: errorBody });
    }

    const data = await response.json();
    const result = { status: 'ok', results: data.Results ? data.Results.length : 0 };
    cache.set('jackett-health', result);
    res.json(result);
  } catch (err) {
    console.log('[Jackett Health Check Exception]', err.message);
    res.status(500).json({ error: err.message });
  }
});
```

**Customize for your service:**
- Replace `jackett` with service name
- Update endpoint path based on actual API
- Adjust response parsing to match API response format
- Update cache key
- Update stat display field name

### 8. html/master.template

**Add to codeToService mapping** (around line 131-137):
```javascript
'JAC': 'jackett'
```

**Add URL endpoint in fetchServiceStatus()** (around line 258-264):
```javascript
} else if (service === 'jackett') {
    url = `${apiBase}/jackett/health`;
```

**Add stats parsing** (around line 317-320):
```javascript
} else if (service === 'jackett') {
    stats = [{ label: 'Results', value: data.results || 0 }];
```

## Configuration File Setup

Users will need to add to **yahlp.json5**:

```json5
{
  jackett: {
    url: "http://jackett:9117",
    api_key: "YOUR_API_KEY"
  }
}
```

And set environment variable:
```
JACKETT_ENABLED=true
```

## Verification Checklist

After implementation:

- [ ] Service appears in dashboard grid
- [ ] Service opens in frame via `/jackett/` path
- [ ] Service shows on service status panel
- [ ] Health check endpoint responds at `/api/jackett/health`
- [ ] Status shows Online/Offline correctly
- [ ] Stats display (e.g., results count)
- [ ] Console logs show health check being called
- [ ] Icon displays correctly

## Common Issues

**400 Bad Request on health check:**
- Verify API key format and parameter name
- Check endpoint path matches API documentation
- Ensure baseURL is handled correctly

**404 on health endpoint:**
- Verify endpoint is registered in proxy.js
- Check service name matches in all files
- Restart Docker container after code changes

**Service not appearing on panel:**
- Check codeToService mapping includes service code
- Verify service is in fetchServiceStatus function
- Check browser console for fetch errors
- Verify configuration has URL and API key set
