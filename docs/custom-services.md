# Custom Services

This guide explains how to add custom services to YAHLP using VirtualHost configuration files and JSON5 metrics definitions without modifying the core application.

## Overview

YAHLP supports adding optional services in two ways:

### Apache VirtualHost Files
Create `.conf` files in `/etc/yahlp/additional-vhost/` to add custom services with automatic HTTPS and optional authentication.

When you add a vhost file:
1. **Automatic SSL certificates** are generated via Let's Encrypt
2. **VirtualHost is enabled** and loaded by Apache
3. **Authentication is applied** (optional, configurable per-service)
4. **Service is accessible** at your custom subdomain

### JSON5 Metrics Configuration
Add `.json5` files alongside vhost files to enable dashboard metrics display and GraphQL support.

When you add a JSON5 metrics file:
1. **Dashboard panels** automatically appear for services with metrics
2. **Real-time data** is fetched from GraphQL endpoints or custom APIs
3. **Value transformations** are applied (KB to GB, etc.)
4. **Metrics are cached** for performance (30-second TTL)

This feature allows you to extend YAHLP with any custom application (e.g., Unraid, Overseerr, custom dashboards) without forking the codebase.

## Vhost Metadata Options

Add optional metadata comments to control how services appear on the dashboard. All metadata is optional except `DASHBOARD_CODE` and `DASHBOARD_VISIBLE`.

### Metadata Reference

| Metadata | Required | Values | Purpose |
|----------|----------|--------|---------|
| `DASHBOARD_CODE` | **Yes** | 3 letters (e.g., `UNR`) | Unique identifier for the service |
| `DASHBOARD_VISIBLE` | **Yes** | `true` / `false` | Show/hide service on dashboard |
| `APPNAME` | No | Any string | Display name in dashboard (overrides derived name) |
| `DASHBOARD_WINDOW` | No | `embed` / `popout` | How to open: embedded panel or popup |
| `SKIP_OIDC` | No | (flag only) | Skip OAuth authentication for this vhost |

### Example with All Metadata

```apache
# DASHBOARD_CODE=UNR
# APPNAME=Unraid Storage
# DASHBOARD_VISIBLE=true
# DASHBOARD_WINDOW=popout
# SKIP_OIDC

<VirtualHost *:443>
    ServerName unraid.yourdomain.com
    ...
</VirtualHost>
```

## Quick Start

### 1. Create a VirtualHost File

Create a file in `/etc/yahlp/additional-vhost/` with **"vhost" in the filename**:

```
/etc/yahlp/keeper_automator_vhost.conf
/etc/yahlp/custom_app_vhost.conf
/etc/yahlp/subdomain_vhost.conf
```

**Filename requirements:**
- Must contain the word `vhost` (case-insensitive)
- Must end with `.conf` extension
- Examples: `myapp-vhost.conf`, `custom_vhost.conf`, `app_vhost_v2.conf` ✅
- Non-examples: `myapp.conf`, `vhost-template.bak`, `myapp.backup` ❌

### 2. Add VirtualHost Configuration

Minimal example for Keeper Automator:

```apache
<VirtualHost *:80 *:443>
    ServerName keeper-automator.yourdomain.com
    DocumentRoot /var/www/html

    # HTTP redirect to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    # SSL configuration (auto-managed by YAHLP)
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/keeper-automator.yourdomain.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/keeper-automator.yourdomain.com/privkey.pem
    
    # Proxy to backend service
    ProxyPreserveHost On
    ProxyPass / http://keeper-automator:8080/
    ProxyPassReverse / http://keeper-automator:8080/
    
    # Optional: Bypass authentication
    <LocationMatch ^/(.*)$>
        AuthType None
        Require all granted
    </LocationMatch>
</VirtualHost>
```

### 3. Add Metadata Comments (Optional)

Add optional metadata as comments at the top of your vhost file to customize how it appears on the dashboard:

```apache
# DASHBOARD_CODE=KPR
# APPNAME=Keeper Automator
# DASHBOARD_VISIBLE=true
# DASHBOARD_WINDOW=embed
# SKIP_OIDC

<VirtualHost *:80 *:443>
    ServerName keeper-automator.yourdomain.com
    ...
</VirtualHost>
```

Metadata explanations:
- **DASHBOARD_CODE** — Unique 3-letter identifier for the service (UNR, KPR, DRS, etc.)
- **APPNAME** — Custom display name shown in the dashboard menu (otherwise derived from domain)
- **DASHBOARD_VISIBLE** — Set to `true` to show on dashboard, `false` to hide
- **DASHBOARD_WINDOW** — `embed` to show in a panel, `popout` to open in a popup window
- **SKIP_OIDC** — Add this flag to disable OAuth/OIDC authentication for the service (useful when the service handles its own auth)

### 4. Restart YAHLP

When the container starts:
- Scans for files with "vhost" in the filename
- Extracts domain names from VirtualHost ServerName directives
- Requests SSL certificates from Let's Encrypt
- Enables the vhost files
- Apache loads the configuration

## Adding Dashboard Metrics

To display real-time metrics for your custom service on the status dashboard, add a JSON5 configuration file alongside your vhost file.

### 1. Create a JSON5 Metrics File

Create a `.json5` file in `/etc/yahlp/additional-vhost/` with the same base name as your vhost file:

**Example: `unraid.limosani.au.vhost.conf` → `unr.json5`**

```json5
{
  service: 'unr',                          // Service identifier (must be lowercase)
  name: 'Unraid',                          // Display name in dashboard
  backend: 'http://192.168.9.13',          // Backend service URL
  api_key: 'your-api-key-here',            // Optional: API key for authentication
  
  // Enable dashboard metrics display
  dashboard: {
    metrics: [
      {
        id: 'free_space',                  // Unique metric ID
        label: 'Free Space',               // Display label
        unit: 'GB',                        // Unit for display
        type: 'text',                      // Metric type (text, gauge, etc.)
        query: '{ array { capacity { kilobytes { free } } } }',  // GraphQL query
        path: 'array.capacity.kilobytes.free',  // Path to value in response
        transform: 'kb_to_gb'              // Transform: kb_to_gb converts kilobytes to gigabytes
      }
    ]
  }
}
```

### 2. GraphQL Configuration

If your service uses GraphQL:

```json5
{
  service: 'myservice',
  name: 'My Service',
  backend: 'http://myservice:3000',
  api_key: 'sk_xyz...',
  
  graphql: true,                           // Enable GraphQL mode
  
  dashboard: {
    metrics: [
      {
        id: 'users',
        label: 'Active Users',
        query: 'query { users { count } }',
        path: 'users.count',
        type: 'text'
      }
    ]
  }
}
```

### 3. Supported Transformations

| Transform | Input | Output | Example |
|-----------|-------|--------|---------|
| `kb_to_gb` | Kilobytes | Gigabytes | 1048576 KB → 1.0 GB |

Omit `transform` if no conversion is needed.

### 4. API Key Formats

The proxy supports multiple authentication header formats automatically:
- `X-Api-Key: {api_key}` (common for REST/GraphQL APIs)
- `Authorization: Bearer {api_key}` (standard OAuth format)

Specify your API key in the JSON5 file:

```json5
{
  api_key: 'your-secret-key-here',  // Sent as both X-Api-Key and Authorization headers
  ...
}
```

### 5. Service Appears Automatically

Once you create the JSON5 file:
1. Service metrics are loaded by the proxy
2. Dashboard displays panels with real-time data
3. No container restart required
4. Metrics are cached for 30 seconds

## VirtualHost File Format

### Full Example with Authentication

```apache
<VirtualHost *:80 *:443>
    ServerName myservice.yourdomain.com
    DocumentRoot /var/www/html

    # HTTP to HTTPS redirect
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/myservice.yourdomain.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/myservice.yourdomain.com/privkey.pem
    SSLProtocols all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5
    SSLHonorCipherOrder on
    
    # Backend proxy
    ProxyPreserveHost On
    ProxyPass / http://myservice:8080/
    ProxyPassReverse / http://myservice:8080/
    
    # IMPORTANT: Bypass OIDC authentication
    # The main YAHLP OIDC module may interfere with custom vhosts
    <LocationMatch ^/(.*)$>
        AuthType None
        Require all granted
    </LocationMatch>
</VirtualHost>
```

### Key Configuration Points

**1. ServerName Directive**
```apache
ServerName myservice.yourdomain.com
```
- Must use full domain name (YAHLP extracts this for SSL certificate generation)
- Only one ServerName per vhost
- Used to determine certificate domain

**2. SSL Configuration**
```apache
SSLCertificateFile /etc/letsencrypt/live/myservice.yourdomain.com/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/myservice.yourdomain.com/privkey.pem
```
- Paths follow Let's Encrypt standard structure
- Certificates are auto-generated and renewed
- Use the same domain as ServerName

**3. Proxy Rules (for web apps)**
```apache
ProxyPreserveHost On
ProxyPass / http://backend-service:port/
ProxyPassReverse / http://backend-service:port/
```
- ProxyPreserveHost maintains Host header
- ProxyPass routes requests to backend
- ProxyPassReverse maintains redirect headers

**4. Authentication Bypass (IMPORTANT)**
```apache
<LocationMatch ^/(.*)$>
    AuthType None
    Require all granted
</LocationMatch>
```
- Disables OIDC authentication for this vhost
- Allows unauthenticated access
- Remove or modify if you want authentication

## Examples

### Keeper Automator

```apache
<VirtualHost *:80 *:443>
    ServerName keeper-automator.yourdomain.com
    DocumentRoot /var/www/html

    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/keeper-automator.yourdomain.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/keeper-automator.yourdomain.com/privkey.pem
    SSLProtocols all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5
    
    ProxyPreserveHost On
    ProxyPass / http://keeper-automator:8080/
    ProxyPassReverse / http://keeper-automator:8080/
    
    <LocationMatch ^/(.*)$>
        AuthType None
        Require all granted
    </LocationMatch>
</VirtualHost>
```

### Overseerr (with authentication)

```apache
<VirtualHost *:80 *:443>
    ServerName overseerr.yourdomain.com
    DocumentRoot /var/www/html

    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/overseerr.yourdomain.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/overseerr.yourdomain.com/privkey.pem
    SSLProtocols all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5
    
    ProxyPreserveHost On
    ProxyPass / http://overseerr:5055/
    ProxyPassReverse / http://overseerr:5055/
    
    # Use YAHLP authentication
    # Include auth config based on your AUTHTYPE
    Include /etc/apache2/conf-available/auth-google-protect.conf
</VirtualHost>
```

### Static Content Service

```apache
<VirtualHost *:80 *:443>
    ServerName static.yourdomain.com
    DocumentRoot /var/www/static-content
    
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/static.yourdomain.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/static.yourdomain.com/privkey.pem
    SSLProtocols all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5
    
    <Directory /var/www/static-content>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

## Mounting VirtualHost Files

### Docker Compose

```yaml
services:
  yahlp:
    image: auskento/yahlp:latest
    environment:
      - DOMAIN=yourdomain.com
      - ACCESS_MODE=public
      # ... other environment variables
    volumes:
      - yahlp_config:/etc/yahlp
      # Mount custom vhost files
      - ./config/keeper_automator_vhost.conf:/etc/yahlp/keeper_automator_vhost.conf:ro
      - ./config/custom_vhost.conf:/etc/yahlp/custom_vhost.conf:ro

volumes:
  yahlp_config:
```

### Docker Volume

```yaml
services:
  yahlp:
    image: auskento/yahlp:latest
    volumes:
      - yahlp_config:/etc/yahlp

# Place vhost files in:
# yahlp_config/keeper_automator_vhost.conf
# yahlp_config/custom_vhost.conf
```

### Unraid Template

In Unraid's Docker settings, add path mappings:
```
Container Path: /etc/yahlp/keeper_automator_vhost.conf
Host Path: /mnt/user/appdata/yahlp/keeper_automator_vhost.conf
```

## SSL Certificate Management

### Automatic Generation

When YAHLP starts:
1. Scans for files containing "vhost" in the filename
2. Extracts `ServerName` directives from each file
3. Checks if certificates already exist
4. Requests new certificates for missing domains
5. Enables all vhost files with Apache's `a2ensite`

### Certificate Renewal

Certificates are automatically renewed via cron:
- Runs daily at 2 AM (container timezone)
- Uses `certbot renew` for existing certificates
- Pre-renewal: Apache is stopped to free port 443
- Post-renewal: Apache is restarted

### Staging vs Production

If `DASHBOARD_TEST=true` (staging certificates):
- Custom vhost certificates also use Let's Encrypt staging server
- Not trusted by browsers (for testing only)
- Unlimited rate limits for testing

When switching `DASHBOARD_TEST=false` (production):
- Staging certificates are automatically removed
- New production certificates are requested
- Force renewal ensures valid certificates are issued

### Troubleshooting Certificates

**Certificate request failed:**
```bash
docker logs yahlp-container | grep "Certificate request"
```

**Check certificate status:**
```bash
docker exec yahlp-container certbot certificates
```

**Manually renew a certificate:**
```bash
docker exec yahlp-container certbot renew --force-renewal
```

## Authentication

### Bypass (No Authentication)

```apache
<LocationMatch ^/(.*)$>
    AuthType None
    Require all granted
</LocationMatch>
```

Use this if the backend service handles its own authentication.

### Basic Authentication

```apache
<LocationMatch ^/(.*)$>
    AuthType Basic
    AuthName "Custom Service"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</LocationMatch>
```

Create `.htpasswd`:
```bash
docker exec yahlp-container htpasswd -c /etc/apache2/.htpasswd username
```

### Google OAuth (OIDC)

```apache
<LocationMatch ^/(.*)$>
    AuthType openid-connect
    Require claim email:your-email@gmail.com
</LocationMatch>
```

Requires AUTHTYPE=google configured in YAHLP.

### Azure Entra (OIDC)

```apache
<LocationMatch ^/(.*)$>
    AuthType openid-connect
    Require claim sub:user-object-id
</LocationMatch>
```

Requires AUTHTYPE=entra configured in YAHLP.

## Troubleshooting

### VirtualHost Not Loading

**Symptom:** Service inaccessible, certificate not generated

**Diagnosis:**
1. Check filename contains "vhost": `ls /etc/yahlp/*vhost*`
2. Verify Apache syntax: `docker exec yahlp-container apache2ctl configtest`
3. Check logs: `docker logs yahlp-container | grep -i vhost`

**Solution:**
- Rename file to include "vhost" in name
- Fix Apache syntax errors in config
- Restart container: `docker restart yahlp-container`

### SSL Certificate Not Generated

**Symptom:** HTTPS returns untrusted certificate error

**Diagnosis:**
1. Check certificate status: `docker exec yahlp-container certbot certificates`
2. Check logs: `docker logs yahlp-container | grep -i certificate`
3. Verify DNS: `nslookup keeper-automator.yourdomain.com`

**Solutions:**
- Verify domain resolves to correct IP
- Ensure port 80 is accessible (needed for Let's Encrypt validation)
- Check DNS propagation (may take time)
- Manually trigger cert request: `docker exec yahlp-container /usr/local/bin/docker-entrypoint.sh`

### Service Inaccessible After Setup

**Symptom:** Domain loads but shows error/blank page

**Diagnosis:**
1. Test backend service: `docker exec yahlp-container curl http://keeper-automator:8080`
2. Check Apache error logs: `docker exec yahlp-container tail /var/log/apache2/error.log`
3. Verify proxy rules in vhost file

**Solutions:**
- Confirm backend service is running and accessible
- Check backend container network connectivity
- Verify proxy ports and paths match backend service
- Add debug headers to proxy: `Header set X-Forwarded-Proto "https"`

### Authentication Bypass Not Working

**Symptom:** Still prompted for login, can't access service

**Cause:** Default YAHLP OIDC module checking cookie domain globally

**Solution:** Ensure LocationMatch block is present:
```apache
<LocationMatch ^/(.*)$>
    AuthType None
    Require all granted
</LocationMatch>
```

The exact path `^/(.*)$` is important - it matches all requests to bypass OIDC.

### Certificate Renewal Issues

**Symptom:** Certificate expiry warnings, manual renewal required

**Diagnosis:**
```bash
docker logs yahlp-container | grep -i renewal
```

**Solutions:**
- Check cron is running: `docker exec yahlp-container ps aux | grep cron`
- Verify Apache can be stopped/started
- Manual renewal: `docker exec yahlp-container certbot renew --force-renewal`

## File Locations

| Item | Location |
|------|----------|
| VirtualHost files | `/etc/yahlp/*.conf` |
| SSL Certificates | `/etc/letsencrypt/live/yourdomain.com/` |
| Apache logs | `/var/log/apache2/error.log` |
| Certbot logs | `/var/log/letsencrypt/letsencrypt.log` |
| Renewal config | `/etc/letsencrypt/renewal/yourdomain.com.conf` |

## Best Practices

1. **Naming:**
   - Use descriptive names: `keeper-automator_vhost.conf`, not `temp.conf`
   - Always include "vhost" in filename

2. **Security:**
   - Use HTTPS for all vhosts (automatically configured)
   - Enable authentication when accessing sensitive data
   - Test with `DASHBOARD_TEST=true` before production

3. **Backups:**
   - Keep vhost files in version control
   - Mount config as persistent volume
   - Regular backups of `/etc/yahlp/`

4. **Testing:**
   - Test in staging mode first (`DASHBOARD_TEST=true`)
   - Verify DNS before requesting certificates
   - Check backend service connectivity

5. **Documentation:**
   - Keep comments in vhost files explaining configuration
   - Document backend service requirements
   - Note any special authentication needs

## Deployment Examples

### Complete Docker Compose with Custom Service

```yaml
version: '3.8'

services:
  yahlp:
    image: auskento/yahlp:latest
    container_name: yahlp
    environment:
      - DOMAIN=yourdomain.com
      - ACCESS_MODE=public
      - EMAIL=admin@yourdomain.com
      - DASHBOARD_TEST=false
      - AUTHTYPE=none
      - DASHBOARD_NAME=My Portal
    volumes:
      - yahlp_config:/etc/yahlp
      - ./keeper_automator_vhost.conf:/etc/yahlp/keeper_automator_vhost.conf:ro
    ports:
      - "80:80"
      - "443:443"
      - "3000:3000"
    restart: unless-stopped

  keeper-automator:
    image: keeper/automator:latest
    container_name: keeper-automator
    environment:
      - PORT=8080
    restart: unless-stopped

volumes:
  yahlp_config:
```

## See Also

- [Configuration Reference](configuration.md) - YAHLP environment variables
- [Security](security.md) - SSL/TLS and authentication setup
- [Services](services.md) - Built-in service configuration
