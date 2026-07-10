# Development Guide

## Project Structure

```
yahlp/
├── Dockerfile              # Alpine Linux container definition
├── docker-compose.yml      # Service orchestration
├── docker-entrypoint.sh    # Container startup script
├── proxy.js                # Node.js API proxy server
├── .env.example            # Environment variable template
├── yahlp.example.json5     # Configuration template
├── sites.example.json5     # Built-in sites template
├── html/                   # Dashboard HTML/CSS/JS
│   ├── index.html          # Main dashboard page
│   ├── master.template     # Base template (generated)
│   ├── styles/             # CSS layouts
│   │   ├── layout-classic.css
│   │   ├── layout-modern.css
│   │   ├── layout-sleek.css
│   │   ├── layout-minimal.css
│   │   └── layout-mobile.css
│   ├── icons/              # Service icons (SVG)
│   └── js/                 # JavaScript files
├── apache/                 # Apache configuration
│   ├── httpd.conf          # Main Apache config
│   ├── oauth2/             # OAuth2 module configs
│   └── auth/               # Authentication configs
├── docs/                   # Documentation
└── node_modules/           # NPM dependencies
```

## Building Locally

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for local development)
- Git

### Clone & Setup
```bash
git clone https://github.com/auskento/YAHLP.git
cd YAHLP

# Copy example configs
cp .env.example .env
cp yahlp.example.json5 yahlp.json5
```

### Build Docker Image
```bash
# Build locally
docker-compose build

# Run
docker-compose up -d

# View logs
docker-compose logs -f yahlp
```

### Local Testing
```bash
# Stop container
docker-compose down

# Edit files locally
nano html/styles/layout-modern.css

# Rebuild with changes
docker-compose build
docker-compose up -d
```

## Code Changes

### Adding a New Service

1. **Update `proxy.js`** - Add service configuration:
```javascript
const services = {
  'mynewservice': { 
    url: getConfigValue('mynewservice', 'url'), 
    key: getConfigValue('mynewservice', 'api_key'), 
    authType: 'header' 
  },
  // ... existing services
};
```

2. **Update `yahlp.example.json5`** - Add service template:
```json5
mynewservice: {
  enabled: false,
  url: 'http://mynewservice:8080',
  api_key: 'your-api-key-here',
}
```

3. **Update `.env.example`** - Add environment variables:
```bash
MYNEWSERVICE_ENABLED=false
MYNEWSERVICE_URL=http://mynewservice:8080
MYNEWSERVICE_API_KEY=
```

4. **Update `html/index.html`** - Add service to dashboard ordering constants

5. **Add icon** to `html/icons/` folder (PNG format):
   - Icon will be bundled in the container
   - Users can override by replacing the file in `/etc/yahlp/service_icons/` on their mounted config

### Modifying Layouts

CSS layouts are in `html/styles/layout-*.css`:

```css
:root {
  --max-icon-size: 144px;
  --bg-primary: #1a1a1a;
  --bg-secondary: #2a2a2a;
  --border-color: #404040;
  --text-primary: #ffffff;
  --text-accent: #00a99d;
}
```

Each layout controls:
- Service menu layout (grid, flex)
- Icon sizing
- Spacing and padding
- Responsive breakpoints

### Editing Dashboard HTML/CSS/JS

**Main template:** `html/master.template`
**Generated output:** `html/index.html` (don't edit directly)

The template system allows:
- Variable substitution for environment-based config
- Conditional sections for enabled services
- Layout selection logic

### Proxy.js API Endpoints

All endpoints are at `http://localhost:3000/api/`:

```javascript
// GET /api/services - List all configured services
app.get('/api/services', (req, res) => { ... });

// GET /api/health - Overall system health
app.get('/api/health', (req, res) => { ... });

// POST /api/proxy/:service - Proxy API requests
app.post('/api/proxy/:service', (req, res) => { ... });

// GET /api/jellyfin/auth - Jellyfin auto-auth token
app.get('/api/jellyfin/auth', (req, res) => { ... });
```

## Contributing

### Before Submitting PR
1. Test your changes locally with `docker-compose`
2. Verify responsive behavior (mobile, tablet, desktop)
3. Check console for JavaScript errors
4. Update documentation if needed
5. Follow existing code style

### Testing Checklist
- [ ] Dashboard loads without errors
- [ ] All enabled services appear
- [ ] Service click opens correct URL
- [ ] Layout switching works (if multiple layouts)
- [ ] Mobile view displays correctly
- [ ] Auth method works as expected
- [ ] No console errors
- [ ] Configuration changes persist after restart

## Debugging

### Enable Debug Logging

In `proxy.js`:
```javascript
console.log('[DEBUG] Service request:', service, method, path);
```

View logs:
```bash
docker-compose logs -f yahlp
```

### Browser Console
Open DevTools (F12) to see:
- Service loading errors
- Authentication issues
- Configuration problems
- JavaScript errors

### Apache Logs
```bash
# Inside container
docker exec -it yahlp tail -f /var/log/apache2/error_log
docker exec -it yahlp tail -f /var/log/apache2/access_log
```

### Configuration Validation

Check if config is loaded:
```bash
docker exec -it yahlp cat /etc/yahlp/yahlp.json5
```

Verify environment variables:
```bash
docker exec -it yahlp printenv | grep SONARR
```

## Performance Optimization

### Caching
- Service list cached in browser `sessionStorage`
- Jellyfin auth tokens cached 1 hour in Node.js
- Static assets served with appropriate cache headers

### Image Optimization
- Icons auto-downloaded and resized to 100x100px
- Unused service icons fallback to colored SVG
- CSS is minified in production build

### Network
- Single dashboard load fetches service list once
- Subsequent service access direct (no proxy through dashboard)
- API calls use connection keep-alive

## Common Development Tasks

### Adding a New OAuth Provider
1. Install Apache module for OAuth2 provider
2. Add configuration template in `apache/oauth2/`
3. Update `docker-entrypoint.sh` to generate config
4. Add provider environment variables to `.env.example`
5. Test OAuth flow

### Creating Custom Layout
1. Copy `html/styles/layout-modern.css` to `layout-custom.css`
2. Modify CSS variables and selectors
3. Update `yahlp.json5`: `style: 'custom'`
4. Rebuild: `docker-compose build && docker-compose up -d`

### Adding Service Auto-Auth (like Jellyfin)
1. Add credentials fields to `yahlp.example.json5`
2. Create `/api/service/auth` endpoint in `proxy.js`
3. Implement service login logic
4. Cache token/session appropriately
5. Inject token in dashboard when opening service

## Troubleshooting Development

**Container won't start**
```bash
docker-compose logs yahlp
# Check for syntax errors in configs
```

**Changes not reflected**
```bash
# Rebuild container
docker-compose down
docker-compose build
docker-compose up -d
```

**Port already in use**
```bash
# Change ports in docker-compose.yml
ports:
  - "8080:80"  # Use 8080 instead of 80
  - "8443:443" # Use 8443 instead of 443
```

**Service appears but shows error**
1. Check service URL in config
2. Verify service is running: `docker ps`
3. Test URL from container: `docker exec -it yahlp curl http://service:8080`

## Testing Against Real Services

```bash
# Start all services in docker-compose
docker-compose up -d sonarr radarr jellyfin

# Verify they're running
docker ps

# Configure YAHLP to connect to them
# Edit .env with service URLs
docker-compose down yahlp
docker-compose up -d yahlp

# Check service connections
docker logs yahlp | grep "Service"
```

---

**See also:** [Architecture](architecture.md) | [Contributing](#) | [Issues](https://github.com/auskento/YAHLP/issues)
