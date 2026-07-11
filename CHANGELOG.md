# YAHLP Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **JSON5 Configuration System**: New `yahlp.json5` with three-tier precedence (defaults → env vars → auto-generated)
- **OAuth Auto-Generation**: Redirect URIs auto-generated from domain configuration
- **Folder-Based Icons**: `/etc/yahlp/service_icons` and `/etc/yahlp/site_icons` for custom icons
- **Security Configuration**: `apache-conf/security.conf` blocks access to sensitive files (`.env`, `.git`, etc.)
- **PUID/PGID Support**: Non-root container users with proper folder ownership
- **Service-Specific OAuth**: Separate redirect URIs for Emby, Plex, Seerr subdomains
- **Initial Config Generation**: Auto-detect enabled services and generate yahlp.json5 on first run
- **Troubleshooting Docs**: Added "Bad Request" error cause documentation

### Changed
- **OAuth Redirect URIs**: Now auto-generated instead of manually configured
  - Entra: `/oauth2/callback` (with slash)
  - Google: `/oauth2callback` (no slash)
- **Icon System**: Moved from environment variable URLs to folder-based system
- **Configuration Precedence**: JSON5 file → environment variables → auto-generated values
- **Docker Entrypoint**: Complete refactor for config folder consolidation and auto-setup
- **Cookie Settings**: `OIDCCookieSameSite` set to `None` for cross-site OAuth redirects
- **Folder Permissions**: Proper `chown` to PUID:PGID for non-root execution
- **Environment Variables**: Removed icon URL variables, added access mode normalization

### Fixed
- **OAuth Callback Handler**: Fixed state cookie persistence with proper SameSite configuration
- **Handler Location Blocks**: Corrected `/oauth2` prefix matching for callbacks
- **Theme Persistence**: Fixed localStorage clearing when toggling dashboard-only mode
- **PROTOCOL Variable**: Fixed assignment for public/private access modes
- **Permission Issues**: Non-root containers now have proper write access to config folders
- **Configuration Syntax**: Fixed orphaned else clauses in Entra/Google OAuth sections
- **Redirect URI Generation**: Conditional path based on AUTHTYPE (Entra vs Google)

### Removed
- **Manual Redirect URI Variables**: `*_REDIRECT_URI` environment variables (auto-generated now)
- **Icon URL Variables**: `*_ICON_URL` environment variables (folder-based system replaces)
- **Duplicate Location Blocks**: Removed redundant authentication configuration

---

## Detailed Commit Log

### Configuration & OAuth (963ee29)
- Fix folder permissions: chown subfolders to PUID:PGID for non-root container users

### Documentation (90a7f35)
- docs: Add troubleshooting note for Bad Request errors caused by OAuth secret typos

### OAuth Service Redirects (bf7c593)
- Fix OAuth handler: use /oauth2 prefix match + SameSite=None cookie
- Fix service-specific OAuth redirect URIs: use correct path for Entra (/oauth2/callback) vs Google (/oauth2callback)

### Security (Earlier commits)
- Create security.conf to block access to sensitive files (.env, .git, config files)
- Enable security.conf in Apache via a2enconf

### Icon System (Earlier commits)
- Remove icon URL environment variables from .env.example
- Update yahlp.example.json5 with icon folder documentation
- Add getIconPath() function to convert .png to .svg when available

### Initial Config Generation (Earlier commits)
- Auto-generate yahlp.json5 on first run with detected services
- Detect enabled services from environment variables and populate config
- Implement three-tier configuration precedence system

### Domain-Based Configuration (Earlier commits)
- Auto-generate ENTRA_REDIRECT_URI from DOMAIN setting
- Auto-generate GOOGLE_REDIRECT_URI from DOMAIN setting
- Auto-generate service-specific redirect URIs from SEERR_DOMAIN, PLEX_DOMAIN, EMBY_DOMAIN
- Set PROTOCOL based on ACCESS_MODE (public=https, private=http)

### Docker Setup (Earlier commits)
- Consolidate config to single /etc/yahlp mount point
- Move certificates to /etc/yahlp/certs with symlink to /etc/letsencrypt
- Move logs to /etc/yahlp/logs with symlink to /var/log/apache2
- Create /etc/yahlp/service_icons and /etc/yahlp/site_icons on startup
- Implement proper symlink setup and verification

---

## Version History

### Pre-Release
- Initial YAHLP implementation with environment variable configuration
- Basic OAuth support (manual redirect URI setup)
- Icon URL-based system
- Standard Docker configuration

---

## Migration Notes

### For Users Upgrading
1. **Redirect URIs**: No longer need manual setup; auto-generated from domain
2. **Icons**: Migrate from environment variables to `/etc/yahlp/service_icons` folder
3. **Configuration**: Consider adopting `yahlp.json5` for more options, or stay with environment variables
4. **Containers**: If running as non-root, add PUID/PGID environment variables

### For Developers
- JSON5 library is installed globally via npm
- Configuration loading order: Read JSON5 → merge with env vars → apply auto-generation
- Icon lookup prefers SVG over PNG; implement fallback chain
- OAuth paths are conditional: Entra uses `/oauth2/callback`, Google uses `/oauth2callback`

---

## Known Issues

- [ ] Service OAuth domains not auto-derived from main domain (manual setup required)
- [ ] Icon format detection requires exact filename matching (e.g., `jellyfin.svg` or `jellyfin.png`)

---

## Future Improvements

- [ ] IP blocklist/geolocation filtering
- [ ] Enhanced dashboard customization
- [ ] Service health checks and status indicators
- [ ] Automated backup configuration
- [ ] Rate limiting and DDoS protection

