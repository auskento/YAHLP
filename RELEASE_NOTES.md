# YAHLP Release Notes

## Current Version: Configuration & Auth Overhaul

### Overview
This release introduces a comprehensive refactoring of YAHLP's configuration system and authentication handling. The focus is on reducing environment variable complexity, improving OAuth reliability, and enhancing security through proper file access controls and permission handling.

---

## Major Features

### 1. JSON5 Configuration System
- **Three-Tier Precedence**: JSON5 file defaults → environment variables → auto-generated values
- **Auto-Generation**: Initial `yahlp.json5` automatically created on first run based on detected services
- **User-Friendly**: Setting-first grouping (enabled{}, url{}, api_key{}, etc.) with inline environment variable documentation
- **Flexibility**: Users can configure via JSON5 file, environment variables, or combination of both

### 2. Intelligent OAuth Configuration
- **Auto-Generated Redirect URIs**: No manual redirect URI configuration needed
  - Entra: `https://{DOMAIN}/oauth2/callback`
  - Google: `https://{DOMAIN}/oauth2callback`
  - Services: Auto-derived from service domain configuration
- **Domain-Based Generation**: Single DOMAIN setting auto-generates all redirect URIs
- **Service Subdomains**: Emby, Plex, Seerr can have separate OAuth configurations via domain settings

### 3. Folder-Based Icon System
- **Location**: `/etc/yahlp/service_icons` and `/etc/yahlp/site_icons`
- **Format Support**: SVG preferred, PNG fallback
- **User Customizable**: Drop new icon files to replace defaults
- **Automatic Bundling**: Built-in icons copied on container startup

### 4. Security Enhancements
- **Sensitive File Protection**: `.env`, `.git`, `.json5`, backup files blocked from web access
- **HTTPS Enforcement**: OAuth always uses HTTPS regardless of access mode
- **Proper Permissions**: Non-root container support (PUID/PGID) with correct file ownership

### 5. Container & Deployment Improvements
- **Single Config Mount**: `/etc/yahlp` consolidates certificates, logs, icons, and configuration
- **Automatic Symlinks**: `/etc/letsencrypt` and `/var/log/apache2` linked for compatibility
- **First-Run Setup**: All subfolders created with correct permissions automatically
- **Non-Root Friendly**: Works correctly with custom PUID/PGID values

---

## Configuration Changes

### Environment Variables Removed (Now Auto-Generated)
- `ENTRA_REDIRECT_URI` - auto-generated from DOMAIN
- `GOOGLE_REDIRECT_URI` - auto-generated from DOMAIN
- `SEERR_REDIRECT_URI` - auto-generated from SEERR_DOMAIN
- `PLEX_REDIRECT_URI` - auto-generated from PLEX_DOMAIN
- `EMBY_REDIRECT_URI` - auto-generated from EMBY_DOMAIN
- All `*_ICON_URL` variables - replaced with folder-based system

### New Environment Variables
- `PUID` / `PGID` - for non-root container execution
- `ACCESS_MODE` - 'public' or 'private' (controls HTTPS/HTTP for redirect URIs)

### Configuration File
- `yahlp.json5` - main configuration file (replaces some environment variables)
  - Auto-generated on first run
  - Three-tier precedence system

---

## Migration Guide

### From Previous Version
1. **Redirect URIs**: No longer need manual configuration; set DOMAIN and SEERR_DOMAIN/PLEX_DOMAIN/EMBY_DOMAIN instead
2. **Icons**: Copy custom icons to `/etc/yahlp/service_icons` and `/etc/yahlp/site_icons` folders
3. **Configuration**: Can stay with environment variables OR adopt JSON5 file (or both)
4. **Non-Root Users**: Add `PUID=99` and `PGID=100` to docker-compose for proper permissions

### OAuth Setup
1. Register app with OAuth provider
2. Get Client ID and Client Secret
3. Register redirect URIs based on your domain:
   - **Entra**: `https://yourdomain.com/oauth2/callback`
   - **Google**: `https://yourdomain.com/oauth2callback`
4. Set DOMAIN, AUTHTYPE, ENTRA_CLIENT_ID, ENTRA_CLIENT_SECRET (or Google equivalents)
5. Container auto-generates redirect URIs at startup

---

## Bug Fixes

- **OAuth Flow**: Fixed state cookie handling with proper SameSite=None setting
- **Callback Handler**: Corrected SetHandler directive for `/oauth2/callback` paths
- **Theme Persistence**: Fixed localStorage clearing when toggling dashboard theme mode
- **Permission Handling**: Proper chown for non-root container users
- **Variable Assignment**: Fixed PROTOCOL assignment for public/private modes
- **Configuration Loading**: Eliminated orphaned else clauses in auth setup

---

## Documentation

### New/Updated Docs
- `docs/authentication.md`: OAuth redirect URI formats, troubleshooting
- `docs/CONFIGURATION.md`: JSON5 format, three-tier precedence, environment variables
- Troubleshooting section: Added "Bad Request" error causes (OAuth secret validation)

### Key Sections
- OAuth setup for Google and Entra
- Custom icon installation
- Configuration precedence explanation
- Non-root container setup

---

## Known Limitations

- Service-specific OAuth subdomains require separate domain setup (not auto-derived from main domain)
- Icon format detection prefers SVG; ensure SVG files have correct permissions if custom

---

## Testing Checklist

- [ ] OAuth login (Entra/Google) redirects and returns successfully
- [ ] State cookie persists across provider redirect
- [ ] Certificates generate and save to `/etc/yahlp/certs`
- [ ] Custom icons load from `/etc/yahlp/service_icons`
- [ ] Non-root container (PUID 99, PGID 100) has write access to config folders
- [ ] `.env` file is not accessible via web browser
- [ ] Service subdomains OAuth works if configured
- [ ] Dashboard theme persists on page reload

---

## System Requirements

- Docker & Docker Compose
- Volume mount for `/etc/yahlp` configuration
- Public domain with DNS resolution (for OAuth)
- Valid SSL certificate or Let's Encrypt access

---

## Support

For issues:
1. Check `docker-compose logs yahlp` for errors
2. Verify redirect URIs in OAuth provider match auto-generated values
3. Ensure OAuth Client Secret is correct (typos cause "Bad Request" errors)
4. Check folder permissions: `ls -la /etc/yahlp/`

