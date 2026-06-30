# YAHLP - Claude Documentation

## Project Overview

**YAHLP (Yet Another HomeLab Portal)** is a production-ready v1.0.0 reverse proxy system for managing 18 homelab applications with automatic HTTPS via Let's Encrypt, flexible authentication (4 methods), and customizable dashboards with multiple themes.

**Repository**: [auskento/YAHLP](https://github.com/auskento/YAHLP)  
**License**: MIT  
**Status**: Production Ready v1.0.0

---

## Architecture Overview

### Core Stack
- **Base**: Alpine Linux + Apache 2.4
- **HTTPS**: Let's Encrypt (Certbot) with automatic daily renewal
- **Reverse Proxy**: Apache mod_proxy + mod_ssl
- **Dashboards**: 4 themes (Modern, Classic, Sleek, Minimal) + Mobile
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
├── classic.template     # Sidebar menu, fixed sizing
├── modern.template      # React-based, feature-rich
├── sleek.template       # Compact with gradients
├── minimal.template     # Single-column vertical
├── mobile.template      # Mobile-optimized layout
└── (generated at runtime: *.html)
```

---

## Implementation Details

### 1. Service Code System (SERVICE_CODE_MAP)

Located in `generate-config.sh` and `docker-entrypoint.sh`:

```bash
declare -A SERVICE_CODE_MAP=(
    [SAB]="sabnzbd"      [GET]="nzbget"      [HYD]="nzbhydra2"
    [TRA]="transmission" [QBI]="qbittorrent" [DEL]="deluge"
    [SON]="sonarr"       [RAD]="radarr"      [LID]="lidarr"    [WHI]="whisparr"
    [PRO]="prowlarr"     [SEE]="seerr"       [BAZ]="bazarr"
    [JEL]="jellyfin"     [EMB]="emby"        [PLX]="plex"
    [TAU]="tautulli"     [MNT]="maintainerr"
)
```

**Usage**: All service-related logic references only the 3-letter code via the map.

### 2. Private vs Public Mode Separation

**Logic in `docker-entrypoint.sh` (lines 177-182, 489-533)**:

```bash
# TEST mode for Let's Encrypt dry-run
TEST="${TEST:-false}"
if [ "$TEST" = "true" ]; then
    DRY_RUN_FLAG="--dry-run"
fi

# Private mode: skip certificates and OAuth
if [ "$ACCESS_MODE" = "private" ]; then
    # Skip Seerr OAuth, skip certificate generation
    # Only HTTP available
else
    # Public mode: certificates + OAuth
fi
```

### 3. Certificate Generation

**Flow**:
1. If `ACCESS_MODE=public` and domain/email provided → Generate certificates
2. If `TEST=true` → Use `--dry-run` flag (no cert issued)
3. Daily renewal via cron in container
4. Certificates stored at `/etc/letsencrypt/` (volume-mapped)

### 4. Dashboard Customization

**Dynamic Icon Sizing** (generate-html-menu.sh, `calculate_icon_sizes()` function):
- Reduces icon size based on enabled service count (prevents horizontal scroll)
- Logo multiplier: 1.0 (1-15 services) → 0.8 (16+ services)

**Theme System**:
- 4 themes + mobile variant
- `DASH_STYLE` variable: `classic`, `modern`, `sleek`, `minimal`
- Optional `:only` suffix to disable style switcher: `classic:only`
- DirectoryIndex automatically strips `:only` suffix for filename

**Color Customization**:
- `DASHBOARD_COLOR`: 6-digit hex code for menu/header background (default: `#1a1a1a`)
- `DASHBOARD_THEME`: `dark` or `light` mode toggle

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

All templates use `@@PLACEHOLDER@@` format replaced in `generate_all_styles()` function:

```bash
html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
html_content="${html_content//@@DASHBOARD_COLOR@@/${DASHBOARD_COLOR:-#1a1a1a}}"
html_content="${html_content//@@DASHBOARD_THEME@@/${DASHBOARD_THEME:-dark}}"
```

**Note**: Placeholders must exist in template for substitution to work.

---

## Environment Variables Reference

### Critical Variables

```bash
# Domain & Email (required for public mode)
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com
ACCESS_MODE=public                    # public or private

# Dashboard
STYLE=modern                          # modern, classic, sleek, minimal
DASHBOARD_NAME="My Homelab"           # Display name
DASHBOARD_ICON="/icons/yahlp.png"     # Icon path
DASHBOARD_COLOR="#1a1a1a"             # 6-digit hex, menu background
DASHBOARD_THEME=dark                  # dark or light
DASHBOARD_LANDING=""                  # Default service on load
DASHBOARD_ORDER="CONTENT,SEARCH,USENET,TORRENTS,MEDIA"  # Category order

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

1. **Update SERVICE_CODE_MAP** in `generate-config.sh`:
   ```bash
   [XYZ]="myservice"
   ```

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

1. Edit template file (e.g., `html/classic.template`)
2. Ensure all `@@PLACEHOLDER@@` are defined
3. Run `generate-html-menu.sh` to regenerate
4. Template is processed by `generate_all_styles()` in `generate-html-menu.sh`

### Debugging

```bash
# View generated Apache config
docker-compose exec yahlp cat /etc/apache2/sites-enabled/reverse-proxy.conf

# Check dashboard generation
docker-compose logs yahlp | grep "Generating dashboards"

# Test Apache syntax
docker-compose exec yahlp apache2ctl configtest

# Verify substitution (check generated HTML)
docker-compose exec yahlp grep "DASHBOARD_COLOR" /var/www/html/classic.html
```

---

## Common Issues & Solutions

### DASHBOARD_COLOR Not Applying

**Issue**: Color placeholder shows in generated HTML instead of hex value.

**Cause**: Variable substitution in `generate_all_styles()` requires placeholder in template AND variable set in environment.

**Fix**:
1. Verify template has `@@DASHBOARD_COLOR@@` placeholder
2. Verify `generate_all_styles()` has substitution line (all templates now included)
3. Check `.env` file has `DASHBOARD_COLOR=` set
4. Rebuild: `docker-compose build`

### 502 Bad Gateway

**Cause**: Service not accessible at configured URL.

**Debug**:
```bash
docker-compose exec yahlp curl -v http://sonarr:8989/sonarr
# Should return 200 or 401, not connection refused
```

### DirectoryIndex Shows `:only` in Filename

**Issue**: Browser tries to load `classic:only.html` instead of `classic.html`.

**Fix**: Update `generate-config.sh` to strip `:only` suffix before Apache substitution (fixed in recent commit).

### Let's Encrypt Certificate Not Generating

**Debug**:
1. Check `TEST` is not set to `true`
2. Verify domain is publicly accessible
3. Check logs: `docker-compose logs yahlp | grep certbot`
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
- Fixed DASHBOARD_COLOR substitution in all templates (moved to generate_all_styles function)
- Added DASHBOARD_THEME support to all templates
- Fixed DirectoryIndex to strip `:only` suffix
- Applied DASHBOARD_COLOR to mobile template main background

---

## Team Notes

### Code Conventions
- Service references ALWAYS use 3-letter codes (never hardcode service names)
- Environment variable substitution via sed/bash parameter expansion
- Apache config generation is fully automated
- Dashboard HTML is fully generated at runtime

### Critical Paths
- Service code mapping: `generate-config.sh` line ~30 (SERVICE_CODE_MAP)
- Dashboard generation: `generate-html-menu.sh` function `generate_all_styles()` (line 767)
- Apache config template: `apache-conf/reverse-proxy.conf.template`
- Docker startup: `docker-entrypoint.sh` (orchestrates all scripts)

### Review Checklist for PRs
- [ ] SERVICE_CODE_MAP updated if service added
- [ ] All templates have `@@PLACEHOLDER@@` if introducing new variable
- [ ] `generate_all_styles()` has substitution for all new placeholders
- [ ] Template works in all 5 themes (modern, classic, sleek, minimal, mobile)
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
docker-compose logs -f yahlp

# Restart after .env change
docker-compose restart yahlp

# Shell access
docker-compose exec yahlp bash

# Check Apache config
docker-compose exec yahlp apache2ctl configtest

# View generated config
docker-compose exec yahlp cat /etc/apache2/sites-enabled/reverse-proxy.conf

# View generated dashboard
docker-compose exec yahlp cat /var/www/html/classic.html
```

---

**Last Updated**: 2026-06-30  
**Maintainer**: YAHLP Project Team
