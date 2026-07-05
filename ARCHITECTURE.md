# YAHLP Architecture & Development Guide

## Project Overview

**YAHLP (Yet Another HomeLab Portal)** is a production-ready v1.0.0 reverse proxy system for managing 18 homelab applications with automatic HTTPS via Let's Encrypt, flexible authentication (4 methods), and customizable dashboards with multiple themes.

**Repository**: [auskento/YAHLP](https://github.com/auskento/YAHLP)  
**License**: MIT  
**Status**: Production Ready v1.0.0

---

## Architecture Overview

### Core Stack
- **Base**: Debian 13 slim + Apache 2.4
- **HTTPS**: Let's Encrypt (Certbot) with automatic daily renewal
- **Reverse Proxy**: Apache mod_proxy + mod_ssl
- **Dashboards**: 5 layouts (Classic, Modern, Sleek, Minimal, Mobile)
- **Authentication**: None / Basic Auth / Entra ID (Azure) / Google OAuth

### Key Design Principles
1. **Service Code System**: All 18 services identified by 3-letter codes (e.g., `SON` = Sonarr, `RAD` = Radarr)
2. **Scalable Architecture**: New services added only via SERVICE_CODE_MAP associative array
3. **Private vs Public Modes**:
   - **Private**: HTTP-only, IP-based access, no certificates generated
   - **Public**: HTTPS with Let's Encrypt, domain-based, OAuth support
4. **Modular Configuration**: Each service has isolated Apache config in `apache-conf/services/`
5. **Template-based HTML**: Dashboards generated from templates with dynamic substitutions

---

## File Structure & Key Components

### Configuration & Scripts

| File | Purpose | Key Variables |
|------|---------|---|
| `.env` | Environment configuration | DOMAIN, EMAIL, ACCESS_MODE, AUTH settings, ENABLE_* flags |
| `docker-entrypoint.sh` | Docker startup orchestration | Calls generate-config.sh and generate-html-menu.sh |
| `generate-config.sh` | Apache configuration generator | Uses SERVICE_CODE_MAP to generate reverse proxy configs |
| `generate-html-menu.sh` | Dashboard HTML generator | Dynamic icon sizing, theme switching, service ordering |
| `docker-compose.yml` | Service orchestration | Volume mappings, port exposure, network config |

### Apache Configuration

```
apache-conf/
├── reverse-proxy.conf.template    # Main template with @@placeholders@@
├── auth-basic.conf                # Basic auth includes
├── auth-entra-protect.conf        # Entra/Azure AD auth
├── auth-google-protect.conf       # Google OAuth
└── services/
    ├── sonarr.conf → ProxyPass /sonarr http://sonarr:8989/sonarr
    ├── radarr.conf
    ├── nzbget.conf → Special: RequestHeader for base64 auth
    └── (15 more service configs)
```

### Dashboard Templates

```
html/
├── master.template          # Single HTML template for every layout
├── styles/
│   ├── base.css             # Shared base styles
│   ├── layout-classic.css   # Sidebar menu, fixed sizing
│   ├── layout-modern.css    # Right-side services frame with left sidebar
│   ├── layout-sleek.css     # Compact with gradients
│   ├── layout-minimal.css   # Single-column vertical
│   └── layout-mobile.css    # Mobile-optimized layout
└── (generated at runtime: *.html)
```

Each layout is selected via the `data-layout` attribute on the `.app` element and its matching `layout-<name>.css` file — `generate-html-menu.sh` auto-discovers any `layout-*.css` file under `html/styles/`, so adding a new layout is just adding a new CSS file (see `html/templates/README.md` for the custom layout guide).

---

## Implementation Details

### 1. Service Code System (SERVICE_CODE_MAP)

Declared in `generate-html-menu.sh` (maps 3-letter codes to the internal `SERVICES` array keys) and mirrored in spirit by `docker-entrypoint.sh`'s `ENABLE_*`/`*_URL` variables and `.env.example`. `generate-config.sh` does not declare its own `SERVICE_CODE_MAP` — it enables services directly via `ENABLE_<NAME>` checks:

```bash
declare -A SERVICE_CODE_MAP=(
    [SAB]="SABNZBD"      [GET]="NZBGET"      [HYD]="NZBHYDRA"
    [TRA]="TRANSMISSION" [QBI]="QBITTORRENT" [DEL]="DELUGE"
    [SON]="SONARR"       [RAD]="RADARR"      [LID]="LIDARR"    [WHI]="WHISPARR"
    [PRO]="PROWLARR"     [SEE]="SEERR"       [BAZ]="BAZARR"
    [JEL]="JELLYFIN"     [EMB]="EMBY"        [PLX]="PLEX"
    [TAU]="TAUTULLI"     [MNT]="MAINTAINERR"
)
```

**Usage**: All service-related logic references only the 3-letter code via the map.

### 2. Private vs Public Mode Separation

**Logic in `docker-entrypoint.sh`** (TEST/dry-run handling and the `ACCESS_MODE` branch, illustrative — not a verbatim excerpt):

```bash
# TEST mode for Let's Encrypt dry-run
TEST="${TEST:-false}"
if [ "$TEST" = "true" ]; then
    DRY_RUN_FLAG="--dry-run"
fi

# Private mode: skip certificates, HTTP-only, IP-based access
if [ "$ACCESS_MODE" = "private" ]; then
    # Skip certificate generation
    # Services accessed via IP address (e.g., http://192.168.1.100/sonarr)
    # No OAuth, HTTPS, or domain-based access
else
    # Public mode: HTTPS certificates, domain-based access
    # OAuth available (Entra ID, Google)
fi
```

**Key Difference**: 
- **Private Mode**: Access via IP address only (e.g., `http://192.168.1.100/sonarr`)
- **Public Mode**: Access via domain name (e.g., `https://yourdomain.com/sonarr`)

### 3. Certificate Generation

**Flow**:
1. If `ACCESS_MODE=public` and domain/email provided → Generate certificates
2. If `TEST=true` → Use `--dry-run` flag (no cert issued)
3. Daily renewal via cron in container
4. Certificates stored at `/etc/letsencrypt/` (volume-mapped)

### 4. Dashboard Customization

**Dynamic Icon Sizing** (generate-html-menu.sh, `calculate_icon_sizes()` function):
- Per-template sizing: Each template (classic, sleek, minimal, mobile) has optimized multipliers
- Classic: Compact sizing (horizontal row) - 0.65× for 18+ services
- Sleek: Larger sizing (2-column grid) - 0.85× for 18+ services
- Minimal: Larger sizing (single column) - 0.8× for 18+ services
- Mobile: Compact sizing (mobile grid) - 0.65× for 18+ services

**Layout System**:
- 4 built-in layouts + mobile variant (classic, modern, sleek, minimal, mobile)
- `DASH_STYLE` variable: `classic`, `modern`, `sleek`, `minimal`
- Optional `:only` suffix to disable style switcher: `classic:only`
- DirectoryIndex automatically strips `:only` suffix for filename

**Color Customization**:
- `DASHBOARD_COLOR`: 6-digit hex code for menu/header background (default: `#1a1a1a`), applied only to built-in layouts via `@@DASHBOARD_COLOR_OVERRIDE@@`

**Dark/Light Mode**:
- Purely client-side: a footer toggle button flips the `data-theme` attribute (`dark`/`light`) on the `.app` element and persists the choice in the browser (localStorage)
- `master.template` hardcodes `data-theme="dark"` as the initial value; there is no build-time substitution for it
- The `DASHBOARD_THEME` env var is written to `env.conf` but is not currently consumed by `generate-html-menu.sh` or `master.template`

### 5. Authentication Methods

| Method | Config Variable | Use Case |
|--------|-----------------|----------|
| **None** | `AUTHTYPE=none` | Private networks, trusted users |
| **Basic** | `AUTHTYPE=basic` + `BASIC_AUTH_CREDENTIALS="user1:pass1\|user2:pass2"` | Simple access control |
| **Entra** | `AUTHTYPE=entra` + Azure AD app details | Enterprise/Office 365 |
| **Google** | `AUTHTYPE=google` + Google OAuth app details | Personal/family access |

### 6. NZBGet Authentication

**Special case**: NZBGet requires base64-encoded credentials in Authorization header.

**Implementation** (`generate-config.sh`, lines 161-181):
```bash
AUTH_BASIC=$(echo -n "$NZBGET_USER:$NZBGET_PASS" | base64)
NZBGET_AUTH_HEADER_LINE="    RequestHeader set Authorization 'Basic $AUTH_BASIC'"
# Substituted into nzbget.conf via sed
```

### 7. Template Variable Substitution

`html/master.template` uses `@@PLACEHOLDER@@` format replaced once per layout in `generate_css_based_templates()`:

```bash
html_content="${html_content//@@TEMPLATE_TYPE@@/$layout}"
html_content="${html_content//@@AVAILABLE_TEMPLATES@@/$templates_js}"
html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
html_content="${html_content//@@SITES_ARRAY@@/$sites_array}"
html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
html_content="${html_content//@@DASHBOARD_COLOR_OVERRIDE@@/$dashboard_color_override}"
```

`@@DASHBOARD_COLOR_OVERRIDE@@` is only populated for the built-in layouts (classic/modern/sleek/minimal/mobile) — it injects an inline `:root { --bg-secondary: ... }` block so custom layouts keep their own colors instead of inheriting DASHBOARD_COLOR. The dashboard theme (dark/light) is controlled client-side via the `data-theme` attribute and a footer toggle, not a build-time placeholder.

**Note**: Placeholders must exist in the template for substitution to work.

---

## Environment Variables Reference

### Critical Variables

```bash
# Domain & Email (required for public mode)
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com
ACCESS_MODE=public                    # public or private

# Dashboard
DASH_STYLE=modern                     # modern, classic, sleek, minimal (mobile always available)
DASHBOARD_NAME="My Homelab"           # Display name
DASHBOARD_ICON_URL=""                 # Optional: URL to download custom icon
DASHBOARD_COLOR="#1a1a1a"             # 6-digit hex, menu background (built-in layouts only)
DASHBOARD_LANDING=""                  # Default service on load
DASHBOARD_ORDER="SAB,GET,HYD,TRA,QBI,DEL,SON,RAD,LID,WHI,PRO,SEE,BAZ,JEL,EMB,PLX,TAU,MNT"  # Service code order

# Testing
TEST=false                            # Set to true for Let's Encrypt dry-run

# Authentication
AUTHTYPE=none                         # none, basic, entra, google
BASIC_AUTH_CREDENTIALS=""             # Format: user1:pass1|user2:pass2
```

### Service Enable Flags & URLs

For each service, provide:
```bash
ENABLE_SERVICENAME=true
SERVICENAME_URL=http://service-hostname:port
```

Example:
```bash
ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989

ENABLE_NZBGET=true
NZBGET_URL=http://nzbget:6789
NZBGET_USER=admin
NZBGET_PASS=secret123
```

See `.env.example` and `ENVIRONMENT-VARIABLES.md` for complete list.

---

## Development & Customization

### Adding a New Service

1. **Update SERVICE_CODE_MAP and SERVICES** in `generate-html-menu.sh`:
   ```bash
   [XYZ]="MYSERVICE"          # in SERVICE_CODE_MAP
   [MYSERVICE]="CATEGORY|My Service|Description|/icons/myservice.png|/myservice/|#hexcolor"   # in SERVICES
   ```
   Also add an `ENABLE_MYSERVICE` check in `generate-config.sh` alongside the other `process_service_config`/`generate_include` calls.

2. **Create Apache config** at `apache-conf/services/myservice.conf`:
   ```apache
   <Location /myservice>
       ProxyPass http://myservice:8080/myservice
       ProxyPassReverse http://myservice:8080/myservice
       # Add auth/headers as needed
   </Location>
   ```

3. **Add enable flag** to `.env.example` and documentation

4. **Test** via `docker-compose build && docker-compose up`

### Modifying Dashboard Theme

1. Edit the layout's CSS file (e.g., `html/styles/layout-classic.css`), or add a new `layout-<name>.css` for a custom layout (see `html/templates/README.md`)
2. `html/master.template` provides the shared HTML structure and `@@PLACEHOLDER@@` substitutions — only edit it if the change applies to every layout
3. Run `generate-html-menu.sh` to regenerate
4. Templates are built by `generate_css_based_templates()` in `generate-html-menu.sh`, which auto-discovers `layout-*.css` files under `html/styles/`

### Debugging

```bash
# View generated Apache config
docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-enabled/reverse-proxy.conf

# Check dashboard generation
docker-compose logs apache-reverse-proxy | grep "Generating dashboards"

# Test Apache syntax
docker-compose exec apache-reverse-proxy apache2ctl configtest

# Verify substitution (check generated HTML)
docker-compose exec apache-reverse-proxy grep "DASHBOARD_COLOR" /var/www/html/classic.html
```

---

## Common Issues & Solutions

### DASHBOARD_COLOR Not Applying

**Issue**: DASHBOARD_COLOR doesn't change the sidebar/header/footer background on a built-in layout.

**Cause**: `generate_css_based_templates()` only injects a `:root { --bg-secondary: ... }` override (via `@@DASHBOARD_COLOR_OVERRIDE@@`) for the built-in layouts (classic/modern/sleek/minimal/mobile). Custom layouts intentionally keep their own colors and never receive this override.

**Fix**:
1. Confirm you're on a built-in layout, not a custom one — custom layouts ignore DASHBOARD_COLOR by design
2. Check `.env` file has `DASHBOARD_COLOR=` set to a 6-digit hex value
3. Rebuild: `docker-compose build`

### 502 Bad Gateway

**Cause**: Service not accessible at configured URL.

**Debug**:
```bash
docker-compose exec apache-reverse-proxy curl -v http://sonarr:8989/sonarr
# Should return 200 or 401, not connection refused
```

### DirectoryIndex Shows `:only` in Filename

**Issue**: Browser tries to load `classic:only.html` instead of `classic.html`.

**Fix**: Update `generate-config.sh` to strip `:only` suffix before Apache substitution (fixed in recent commit).

### Let's Encrypt Certificate Not Generating

**Debug**:
1. Check `TEST` is not set to `true`
2. Verify domain is publicly accessible
3. Check logs: `docker-compose logs apache-reverse-proxy | grep certbot`
4. Try `TEST=true` for dry-run to debug issues

---

## Version History (v1.0.0)

### Major Features
✅ 18 service support with 3-letter code system  
✅ 5 dashboard themes (Modern, Classic, Sleek, Minimal, Mobile)  
✅ 4 authentication methods  
✅ Let's Encrypt with automatic daily renewal  
✅ Private/Public mode separation  
✅ Dynamic icon sizing based on service count  
✅ Custom dashboard color (DASHBOARD_COLOR)  
✅ Custom dashboard theme toggle  
✅ STYLE :only suffix for locked theme  
✅ TEST mode for Let's Encrypt dry-run  
✅ NZBGet base64 authentication  
✅ Dashboard service ordering  
✅ WebSocket support  

### Recent Changes
- Fixed DASHBOARD_COLOR substitution in all templates (at the time, handled in the now-removed per-style `generate_all_styles` function; this logic now lives in `generate_css_based_templates()`)
- Added DASHBOARD_THEME environment variable plumbing (not currently wired into template output — see Theme System note above)
- Fixed DirectoryIndex to strip `:only` suffix
- Applied DASHBOARD_COLOR to mobile template main background
- Removed the dead per-style template generators (`generate_all_styles()`, `generate_style_dashboard()`) and the old `html/*.template` files (classic/modern/modern-api/sleek/minimal/mobile/basic) in favor of the single CSS-based `master.template` + `layout-*.css` system described above

---

## Team Notes

### Code Conventions
- Service references ALWAYS use 3-letter codes (never hardcode service names)
- Environment variable substitution via sed/bash parameter expansion
- Apache config generation is fully automated
- Dashboard HTML is fully generated at runtime

### Critical Paths
- Service code mapping: `generate-html-menu.sh` (`SERVICE_CODE_MAP`, near the `SERVICES` array)
- Dashboard generation: `generate-html-menu.sh` function `generate_css_based_templates()`
- Apache config template: `apache-conf/reverse-proxy.conf.template`
- Docker startup: `docker-entrypoint.sh` (orchestrates all scripts)

### Review Checklist for PRs
- [ ] SERVICE_CODE_MAP updated if service added
- [ ] `html/master.template` has `@@PLACEHOLDER@@` if introducing new shared variable
- [ ] `generate_css_based_templates()` has substitution for all new placeholders
- [ ] Layout works across all built-in `layout-*.css` files (classic, modern, sleek, minimal, mobile)
- [ ] Private/Public mode separation maintained
- [ ] Documentation updated in ENVIRONMENT-VARIABLES.md

---

## Quick Reference

```bash
# Full rebuild
docker-compose build

# Deploy
docker-compose up -d

# Logs
docker-compose logs -f apache-reverse-proxy

# Restart after .env change
docker-compose restart apache-reverse-proxy

# Shell access
docker-compose exec apache-reverse-proxy bash

# Check Apache config
docker-compose exec apache-reverse-proxy apache2ctl configtest

# View generated config
docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-enabled/reverse-proxy.conf

# View generated dashboard
docker-compose exec apache-reverse-proxy cat /var/www/html/classic.html
```

---

**Last Updated**: 2026-06-30  
**Maintainer**: YAHLP Project Team
