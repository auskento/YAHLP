# Upgrading YAHLP

## Version Information

YAHLP tracks version information in two ways:

### VERSION File
- **Location:** `/VERSION` in repository root
- **Format:** Semantic versioning (e.g., `b.2.0.27`)
- **Purpose:** Identifies the current build/release version
- **Container Location:** Copied to `/etc/yahlp/VERSION` during Docker build

**Reading Version in Running Container:**
```bash
# From host
docker exec yahlp cat /VERSION

# Or check mounted config
cat ./config/VERSION

# Check git version (if cloned)
git describe --tags
git log -1 --oneline
```

**Version Format:**
- `b.2.0.27` = Build 2, Major version 0, Minor version 27
- Always check VERSION before major upgrades
- Build number increments on each release

### Checking Current Version

```bash
# In container
cat /VERSION

# From host (if mounted)
docker exec -it yahlp cat /etc/yahlp/VERSION

# Via git (if cloned from repo)
cd /path/to/yahlp
git log -1 --oneline
cat VERSION
```

**Example Output:**
```
b.2.0.27
```

---

## Before You Upgrade

### Backup Your Data
Always backup before upgrading:

```bash
# Backup configuration
cp -r ./yahlp.json5 ./backup/yahlp.json5.backup
cp -r ./appdata/letsencrypt ./backup/letsencrypt.backup
cp -r ./templates ./backup/templates.backup

# Or full volume backup
docker run --rm -v yahlp_data:/data -v $(pwd)/backup:/backup \
  alpine tar czf /backup/yahlp-full-backup.tar.gz /data
```

### Check Current Version
```bash
# Version in git
git log -1 --oneline

# Version in container
docker exec -it yahlp cat /etc/yahlp/version.txt 2>/dev/null || echo "No version file"
```

## Upgrade Process

### 1. Stop Current Container
```bash
docker-compose down
```

### 2. Pull Latest Changes
```bash
git pull origin main

# Or update from GitHub releases
wget https://github.com/auskento/YAHLP/archive/refs/tags/v1.0.0.tar.gz
tar -xzf v1.0.0.tar.gz
cd YAHLP-1.0.0
```

### 3. Update Configuration Files
```bash
# Check for new config options
diff -u yahlp.example.json5 yahlp.json5

# Merge new options into your config
# (or use .env.example for env vars)
```

### 4. Rebuild Container
```bash
docker-compose build --no-cache

# Or use specific version tag
docker-compose build --build-arg VERSION=1.0.0
```

### 5. Start New Container
```bash
docker-compose up -d

# Check logs for errors
docker-compose logs -f yahlp

# Verify it started
docker ps | grep yahlp
```

### 6. Test Dashboard
1. Open https://yourdomain.com (or http://192.168.x.x)
2. Verify services appear correctly
3. Test clicking a few services
4. Check console (F12) for errors

## Version-Specific Upgrade Guides

### Upgrading to v1.1.0+
**Breaking Changes:** Jellyfin auto-auth now requires config mounting

**Steps:**
1. Ensure `yahlp.json5` is mounted in docker-compose.yml:
```yaml
volumes:
  - ./yahlp.json5:/etc/yahlp/yahlp.json5
```

2. Add Jellyfin credentials to `yahlp.json5`:
```json5
jellyfin: {
  enabled: true,
  url: 'http://jellyfin:8096',
  api_key: 'your-key',
  username: 'your-username',  // NEW
  password: 'your-password',  // NEW
}
```

3. Rebuild: `docker-compose build && docker-compose up -d`

### Upgrading to v1.0.0+
**New Features:** Multiple layout support, OAuth2, mobile layout

**Steps:**
1. Copy new example config:
```bash
cp yahlp.example.json5 yahlp.json5.new
diff yahlp.json5 yahlp.json5.new
# Merge differences manually
```

2. Set new env var:
```bash
DASHBOARD_STYLE=modern  # or classic, sleek, minimal
```

3. Test layout switcher works (if not locked)

## Rollback Procedure

If upgrade goes wrong:

### Quick Rollback (Last Backup)
```bash
docker-compose down

# Restore configuration
cp ./backup/yahlp.json5.backup ./yahlp.json5
cp -r ./backup/templates/* ./templates/

# Checkout previous version
git checkout HEAD~1

# Rebuild with old version
docker-compose build
docker-compose up -d
```

### Git Rollback
```bash
# Find previous version
git log --oneline | head -10

# Checkout old version
git checkout abc1234

# Rebuild
docker-compose build
docker-compose up -d
```

### Docker Rollback
```bash
# Keep multiple image versions
docker tag yahlp:latest yahlp:v1.0.0.backup

# Restore from backup
docker rmi yahlp:latest
docker tag yahlp:v1.0.0.backup yahlp:latest

docker-compose up -d
```

## Common Upgrade Issues

### 1. Container Won't Start
**Symptom:** `docker-compose logs` shows errors

**Solutions:**
```bash
# Check for config errors
docker run --rm -it yahlp node -c "JSON5.parse(fs.readFileSync('/etc/yahlp/yahlp.json5'))"

# View error details
docker-compose logs yahlp | tail -50

# Rebuild without cache
docker-compose build --no-cache
```

### 2. Services Not Appearing
**Symptom:** Dashboard loads but no services shown

**Solutions:**
```bash
# Check if services are enabled
docker exec -it yahlp cat /etc/yahlp/yahlp.json5 | grep "enabled"

# Check service URLs are accessible
docker exec -it yahlp curl http://sonarr:8989

# Verify environment variables
docker exec -it yahlp printenv | grep SONARR
```

### 3. Authentication Issues
**Symptom:** Can't log in after upgrade

**Solutions:**
```bash
# If using Basic Auth, regenerate htpasswd
docker exec -it yahlp htpasswd -c /etc/apache2/.htpasswd username

# If using OAuth, verify credentials
docker exec -it yahlp cat /etc/apache2/mods-enabled/oauth2.conf

# Check Apache error log
docker exec -it yahlp tail -f /var/log/apache2/error_log
```

### 4. Certificate Issues
**Symptom:** HTTPS errors, certificate warnings

**Solutions:**
```bash
# Check certificate status
docker exec -it yahlp openssl x509 -noout -dates \
  -in /etc/letsencrypt/live/yourdomain.com/cert.pem

# Force renewal
docker exec -it yahlp certbot renew --force-renewal

# Verify domain DNS
nslookup yourdomain.com
```

### 5. Layout/UI Issues
**Symptom:** Dashboard renders incorrectly after upgrade

**Solutions:**
```bash
# Clear browser cache (Ctrl+F5)
# Or use private browsing window

# Check CSS is being served
curl -I https://yourdomain.com/styles/layout-modern.css

# Verify CSS syntax
docker exec -it yahlp grep -n "error" html/styles/layout-modern.css
```

## Maintenance Upgrades

### Regular Updates
Every 1-2 weeks, check for updates:

```bash
git pull
git log -1 --oneline  # See latest commit
docker-compose build
docker-compose up -d
```

### Automated Updates (Optional)
Create a cron job for automatic upgrades:

```bash
# /etc/cron.d/yahlp-upgrade
0 2 * * 0 cd /path/to/YAHLP && git pull && \
  docker-compose build && docker-compose up -d
```

### Critical Security Updates
If security issue announced:
1. Check GitHub releases
2. Upgrade immediately if marked critical
3. Verify exploit doesn't affect your setup
4. Test thoroughly before deployment

## Database/Config Migrations

### Jellyfin Auto-Auth Setup
```json5
// Old config (v1.0.0)
jellyfin: {
  enabled: true,
  url: 'http://jellyfin:8096',
  api_key: 'old-key',
}

// New config (v1.1.0+)
jellyfin: {
  enabled: true,
  url: 'http://jellyfin:8096',
  api_key: 'old-key',
  username: 'admin',      // NEW
  password: 'password',   // NEW
}
```

### Layout Migration
If renaming/reorganizing layouts:
```bash
# Old: DASHBOARD_STYLE env var
# New: yahlp.json5 dashboard.style

# Old: single layout option
# New: multiple layout support (comma-separated)
```

## Support for Old Versions

| Version | Status | Support Until |
|---------|--------|-----------------|
| 1.1.0+ | Current | Latest release |
| 1.0.0 | Legacy | 6 months |
| 0.9.0 | EOL | No support |

**EOL (End of Life) versions:** No security updates, upgrade recommended

## Upgrade Path Examples

### From 0.9.0 → 1.1.0 (Multi-version jump)
1. **First, upgrade 0.9.0 → 1.0.0:**
   - `git checkout v1.0.0`
   - Test thoroughly
   - Keep this version for 1 week

2. **Then, upgrade 1.0.0 → 1.1.0:**
   - `git pull origin main`
   - Test thoroughly

### From 1.0.0 → Latest
1. `git pull origin main`
2. `docker-compose build && docker-compose up -d`
3. Verify services work

## Getting Help

- **GitHub Issues:** https://github.com/auskento/YAHLP/issues
- **Documentation:** Check relevant guide ([Configuration](configuration.md), [Services](services.md), etc)
- **Troubleshooting:** See [Troubleshooting Guide](troubleshooting.md)

---

**See also:** [Installation](installation.md) | [Backup & Restore](backup-restore.md) | [Troubleshooting](troubleshooting.md)
