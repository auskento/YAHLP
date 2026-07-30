# Custom Services Guide

YAHLP v2.1.0 introduces a modular framework for adding custom services without modifying core code. This guide covers both methods: via configuration files (simple) and virtual host files (advanced).

---

## Quick Start

### Method 1: Configuration File (Recommended for Location-based services)

1. Create a `.conf` file in `/config/additional-conf/` (3-letter code):
   ```bash
   /config/additional-conf/tda.conf
   ```

2. Add Apache Location directives and configuration:
   ```apache
   # Tdarr transfer tracker
   # #APPNAME=Tdarr
   # #DASHBOARD_WINDOW=popout
   
   <Location /tdarr/>
       ProxyPass http://tdarr:8265/
       ProxyPassReverse http://tdarr:8265/
   </Location>
   ```

3. Add an icon to the same folder:
   ```
   /config/additional-conf/tda.png
   ```

4. Restart the container — service appears on dashboard automatically.

### Method 2: Virtual Host File (For independent domains)

1. Create a `vhost` file in `/config/additional-conf/`:
   ```bash
   /config/additional-conf/custom-service.vhost.conf
   ```

2. Define a complete VirtualHost:
   ```apache
   <VirtualHost *:443>
       ServerName app.yourdomain.com
       DocumentRoot /var/www/app
       SSLEngine on
       # ... full vhost config
   </VirtualHost>
   ```

3. Restart — vhost is enabled and served independently (not added to dashboard).

---

## Configuration File Details

### File Format

Conf files are named `XYZ.conf` where `XYZ` is a 3-letter service code. The system scans `/etc/yahlp/additional-conf/` at startup and:
- **Includes** `.conf` files without "vhost" in Apache config
- **Enables** separate vhost files with "vhost" in the filename
- **Ignores** files with "example" in the name

### Per-Service Configuration

Control how a service appears on the dashboard using comment-based settings in the `.conf` file:

#### `#APPNAME`
Display name for the dashboard. If omitted, uses capitalized service code.
```apache
# #APPNAME=Tdarr
```

#### `#DASHBOARD_WINDOW`
How the service opens. Use `newtab` or `popout`. If omitted, defaults to `popout` for custom services.
```apache
# #DASHBOARD_WINDOW=newtab
```

### Location Directive

The `<Location>` block path is extracted as the service href. The Location must match the proxied service path:

```apache
<Location /tdarr/>
    ProxyPass http://tdarr:8265/
    ProxyPassReverse http://tdarr:8265/
</Location>
```

**Important**: The trailing slash in both the Location path and ProxyPass URL should match the target service's path structure.

### Icon Files

Place icons alongside the `.conf` file:

```
/config/additional-conf/
├── tda.conf
├── tda.png          # PNG format, any size
├── kee.conf
└── kee.png
```

**Supported formats**: PNG (recommended), SVG

**Icon resolution**: 64×64px or larger recommended for dashboard clarity.

### Complete Example

```apache
# Tdarr Configuration
# #APPNAME=Tdarr
# #DASHBOARD_WINDOW=popout

<Location /tdarr/>
    ProxyPass http://tdarr:8265/
    ProxyPassReverse http://tdarr:8265/
    ProxyPreserveHost On
</Location>
```

With `tda.png` placed in the same folder, the service appears on the dashboard as "Tdarr" with the PNG icon, opening in a popout window.

---

## Virtual Host (Advanced)

For services that need their own domain or independent SSL configuration:

### File Format

Name the file with "vhost" in it: `custom-service.vhost.conf`

```apache
<VirtualHost *:443>
    ServerName app.yourdomain.com
    DocumentRoot /var/www/app
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/yourdomain.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/yourdomain.com/privkey.pem
    
    <Directory /var/www/app>
        Require all granted
    </Directory>
</VirtualHost>
```

**Notes**:
- Vhost files are **not** added to the dashboard menu
- Must contain the word "vhost" in the filename
- Fully independent configuration per-service domain
- Requires Let's Encrypt certificate for the domain

---

## Environment Variables

Global dashboard behavior can be controlled via environment variables (override per-service settings):

### `DASHBOARD_WINDOWS`
Default window method for all custom services: `popout` or `newtab`

```bash
DASHBOARD_WINDOWS=newtab
```

Per-service `#DASHBOARD_WINDOW` settings in `.conf` files override this global default.

### `DEBUG`
Enable verbose logging during startup to see service discovery details:

```bash
DEBUG=true
```

Shows file scanning, config extraction, and menu generation steps.

---

## Troubleshooting

### Service Not Appearing on Dashboard

**Check**:
1. File is in `/config/additional-conf/` (not `/etc/yahlp/additional-conf/`)
2. Filename is exactly 3 letters: `xyz.conf` (not `custom.conf` or `xyz-custom.conf`)
3. File does not contain "vhost" or "example"
4. Icon file exists with matching name: `xyz.png` or `xyz.svg`
5. Enable `DEBUG=true` and check boot logs for extraction errors

**Example Log Entry**:
```
[DEBUG] Found additional service: tda
[DEBUG] APPNAME: Tdarr, DASHBOARD_WINDOW: popout
```

### Icon Not Displaying

1. Confirm icon file exists: `/config/additional-conf/tda.png`
2. Check icon size (64×64px or larger recommended)
3. Verify file extension matches config file code: `tda.png` for `tda.conf`
4. Restart container to trigger icon sync to `/etc/yahlp/service_icons/`

### Service URL Opens Blank Page

1. Verify the `<Location>` path in `.conf` file is correct
2. Ensure the backend service is running: `ProxyPass` destination must be reachable
3. Check Apache logs: `docker logs <container>`
4. Confirm HTTP vs HTTPS in ProxyPass URL

### ProxyPass SSL Issues

If proxying to an HTTPS backend:
```apache
<Location /service/>
    ProxyPass https://backend:8443/ sslproxyverify=optional
    ProxyPassReverse https://backend:8443/
</Location>
```

---

## File Structure Reference

```
config/
├── additional-conf/           # Mounted to /etc/yahlp/additional-conf/
│   ├── tda.conf              # Configuration file
│   ├── tda.png               # Icon file
│   ├── kee.conf
│   ├── kee.png
│   └── custom.vhost.conf     # VirtualHost (not on dashboard)
```

The `additional-conf` folder is created on first run if it doesn't exist. Example files are copied from `/app/examples/additional-conf/` for reference.

---

## Security Considerations

1. **Authentication**: Custom services inherit the dashboard's authentication (OIDC, Basic Auth, or none)
2. **Path Validation**: Ensure ProxyPass destinations are trusted internal services
3. **Headers**: Add security headers as needed:
   ```apache
   <Location /service/>
       Header set X-Frame-Options "SAMEORIGIN"
       ProxyPass http://backend:port/
   </Location>
   ```
4. **VirtualHost SSL**: Always use HTTPS for internet-facing services; Let's Encrypt certificates auto-renew

---

## Examples Included in Repository

The repository includes example templates in `examples/additional-conf/`:

- `tda.example.conf` — Tdarr integration template
- `custom.example.vhost.conf` — Custom VirtualHost template

Copy these to `/config/additional-conf/` (rename to remove "example") and customize for your services.

---

## Migration from Pre-2.1.0

If you were using VirtualHost files before v2.1.0:

1. Move `.vhost.conf` files to `/config/additional-conf/`
2. Ensure filenames contain "vhost" (e.g., `service.vhost.conf`)
3. Restart — files are auto-discovered and enabled
4. No configuration changes needed; existing vhosts continue to work

For new services added via Location directives, follow the "Quick Start" guide above.

---

## Frequently Asked Questions

**Q: Can I use custom services without the dashboard?**
A: Yes — vhost files work independently. Conf files appear on the dashboard but can also be accessed directly via path (e.g., `/tdarr/`).

**Q: How many custom services can I add?**
A: No limit. Performance depends on backend services and available resources.

**Q: Can I edit `.conf` files without restarting?**
A: No — restart the container to re-scan `/etc/yahlp/additional-conf/` and regenerate the dashboard.

**Q: Do custom services get automatic SSL certificates?**
A: VirtualHost domains use Let's Encrypt when deployed with `ACCESS_MODE=public` and `DOMAIN=yourdomain.com`. Conf-file services use the main domain's certificate.

**Q: Can I disable a custom service without deleting it?**
A: Yes — rename the `.conf` file to include "example" (e.g., `tda.example.conf`) and restart.
