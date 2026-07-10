# Backup & Restore

## Data Persistence Overview

YAHLP stores all data in a single mounted config folder. **Must** be backed up to prevent data loss:

| Folder | Contents | Backup Frequency |
|--------|----------|------------------|
| `/etc/yahlp/` (mounted `./config`) | Configuration, certificates, templates, and logs | Every change |
| | - `yahlp.json5` - Configuration file | |
| | - `sites.json5` - Custom sites | |
| | - `certs/` - SSL certificates (public mode) | |
| | - `templates/` - Custom layouts | |
| | - `logs/` - Apache access/error logs | |

## Backup Strategies

### Strategy 1: Selective File Backup (Recommended for Most)

**Pros:** Simple, fast, smaller backup size
**Cons:** Need to remember what to backup

```bash
#!/bin/bash
# backup.sh - Backup critical YAHLP files

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up YAHLP data..."

# Configuration, certificates, and templates (all in config folder)
cp -r ./config "$BACKUP_DIR/" 2>/dev/null || true

# .env file
cp ./.env "$BACKUP_DIR/" 2>/dev/null || true

echo "Backup complete: $BACKUP_DIR"

# Keep only last 5 backups
cd backups
ls -t | tail -n +6 | xargs -r rm -rf
```

**Run daily:**
```bash
chmod +x backup.sh
0 2 * * * /path/to/backup.sh  # 2 AM daily
```

### Strategy 2: Full Volume Backup (Maximum Safety)

**Pros:** Complete data backup, easier restore
**Cons:** Larger file size, requires tar

```bash
#!/bin/bash
# full-backup.sh - Full volume backup

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/yahlp-full-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Creating full backup..."

# Backup config folder (includes certificates, config, and templates)
docker run --rm \
  -v yahlp_config:/etc/yahlp \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/yahlp-full-$TIMESTAMP.tar.gz" \
  /etc/yahlp

echo "Backup complete: $BACKUP_FILE"
echo "Size: $(du -h $BACKUP_FILE | cut -f1)"

# Keep only last 3 full backups
cd "$BACKUP_DIR"
ls -t yahlp-full-*.tar.gz | tail -n +4 | xargs -r rm
```

### Strategy 3: Cloud Backup (Off-Site)

**Pros:** Protected from local disasters, automated
**Cons:** Requires cloud account, network bandwidth

```bash
#!/bin/bash
# cloud-backup.sh - Sync to cloud storage

# Using AWS S3 (requires aws-cli)
aws s3 sync ./backups s3://my-backup-bucket/yahlp/ \
  --delete --exclude "*.log"

# Or using Backblaze B2
b2 sync --keepDays 30 ./backups b2://my-backup-bucket/yahlp/

# Or using Nextcloud
rclone sync ./backups nextcloud:YAHLP_Backups/ --delete
```

## Backup Implementation Examples

### Docker Compose with Single Volume
```yaml
version: '3.8'
services:
  yahlp:
    image: yahlp:latest
    volumes:
      - config:/etc/yahlp

volumes:
  config:
    driver: local
```

**Backup via docker CLI:**
```bash
# Backup config volume (includes certificates, config, and templates)
docker run --rm -v yahlp_config:/data -v $(pwd):/backup \
  alpine tar czf /backup/yahlp-config.tar.gz -C /data .

# Restore from backup
docker run --rm -v yahlp_config:/data -v $(pwd):/backup \
  alpine tar xzf /backup/yahlp-config.tar.gz -C /data
```

### Local Directory Volumes
```yaml
volumes:
  - ./appdata/letsencrypt:/etc/letsencrypt
  - ./appdata/yahlp:/etc/yahlp
  - ./templates:/templates
  - ./logs:/var/log/apache2
```

**Backup is simple:**
```bash
# Just tar the directories
tar -czf backup-$(date +%Y%m%d).tar.gz \
  ./config ./logs
```

## Restore Procedures

### Restore Everything (Full Restore)
```bash
# 1. Stop container
docker-compose down

# 2. Remove old volume
docker volume rm yahlp_config

# 3. Restore from backup
docker run --rm \
  -v yahlp_config:/etc/yahlp \
  -v $(pwd):/backup \
  alpine tar xzf /backup/yahlp-full-20240101_020000.tar.gz

# 4. Start container
docker-compose up -d

# 5. Verify
docker-compose logs yahlp
```

### Restore Configuration Only
```bash
# 1. Restore just the config files
docker cp ./backup/config/yahlp.json5 yahlp:/etc/yahlp/yahlp.json5 2>/dev/null || true
docker cp ./backup/config/sites.json5 yahlp:/etc/yahlp/sites.json5 2>/dev/null || true

# 2. Restart for changes to take effect
docker-compose restart yahlp
```

### Restore Certificates Only
```bash
# 1. Copy certificates from backup (stored in config/certs/)
docker cp ./backup/config/certs/. yahlp:/etc/yahlp/certs/

# 2. Restart Apache
docker exec -it yahlp apache2ctl graceful
```

### Restore Custom Layouts
```bash
# 1. Copy templates from backup
docker cp ./backup/config/templates/. yahlp:/etc/yahlp/templates/

# 2. Browser reload (Ctrl+Shift+R to bypass cache)
# Dashboard should show custom layouts immediately
```

## Disaster Recovery

### If Certificate is Lost

If `/etc/yahlp/certs/` is deleted and auto-renewal failed:

```bash
# 1. Restart container (it will try to renew)
docker-compose restart yahlp

# 2. Check renewal status
docker exec -it yahlp certbot renew --dry-run

# 3. If stuck, force renewal
docker exec -it yahlp certbot renew --force-renewal

# 4. If certificate still unavailable, let it auto-generate
# YAHLP will generate a self-signed cert as fallback
```

**Note:** Certificates are now stored in `/etc/yahlp/certs/` (inside your mounted config folder), so backup your config folder regularly to protect your Let's Encrypt certificates.

### If Configuration is Lost

If `yahlp.json5` is deleted:

```bash
# 1. Use .env variables (if set)
# YAHLP will read configuration from environment variables
docker-compose up -d

# 2. Or restore from backup
cp ./backup/yahlp.json5 ./yahlp.json5
docker-compose restart yahlp

# 3. Or start fresh
cp yahlp.example.json5 yahlp.json5
# Edit yahlp.json5 manually
docker-compose restart yahlp
```

### If Everything is Lost

Complete data loss recovery:

```bash
# 1. Check if you have ANY backup
ls -la ./backups/

# 2. If backup exists, restore it
# See "Restore Everything" section above

# 3. If no backup, rebuild from scratch
docker-compose down

# 4. Start fresh (will regenerate certificates)
docker-compose up -d

# 5. Services will be inaccessible until cert is issued
# Wait 2-5 minutes for Let's Encrypt
docker logs -f yahlp | grep "certificate"

# 6. Reconfigure services in yahlp.json5
```

## Backup Verification

### Test Restore (Monthly)
Important! Backup is only good if you can restore it.

```bash
#!/bin/bash
# test-restore.sh - Verify backup can be restored

BACKUP_FILE="./backups/yahlp-full-latest.tar.gz"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "ERROR: No backup file found!"
  exit 1
fi

# Create temporary test directory
TEST_DIR=$(mktemp -d)
echo "Testing restore to $TEST_DIR..."

# Extract backup
tar -xzf "$BACKUP_FILE" -C "$TEST_DIR"

# Verify key files exist
if [ -d "$TEST_DIR/etc/letsencrypt/live" ]; then
  echo "✓ Certificates present"
else
  echo "✗ Certificates MISSING!"
  exit 1
fi

if [ -f "$TEST_DIR/etc/yahlp/yahlp.json5" ]; then
  echo "✓ Configuration present"
else
  echo "✗ Configuration MISSING!"
  exit 1
fi

# Check file integrity
if tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
  echo "✓ Backup file integrity OK"
else
  echo "✗ Backup file CORRUPTED!"
  exit 1
fi

echo "Backup verification PASSED"
rm -rf "$TEST_DIR"
```

## Backup Encryption

### Encrypt Sensitive Backups
```bash
# Backup and encrypt with GPG
tar -czf - ./yahlp.json5 ./appdata/letsencrypt | \
  gpg --encrypt --recipient your-email@example.com \
  > backup-$(date +%Y%m%d).tar.gz.gpg

# Decrypt when needed
gpg --decrypt backup-20240101.tar.gz.gpg | tar -xz
```

### Symmetric Encryption (Simpler)
```bash
# Encrypt with password
tar -czf - ./appdata | \
  openssl enc -aes-256-cbc -salt > backup-$(date +%Y%m%d).tar.gz.enc

# Decrypt with password
openssl enc -aes-256-cbc -d -in backup-20240101.tar.gz.enc | tar -xz
```

## Backup Schedule Template

```bash
# Daily at 2 AM
0 2 * * * /path/to/backup.sh

# Weekly full backup (Sunday at 3 AM)
0 3 * * 0 /path/to/full-backup.sh

# Monthly verification (1st at 4 AM)
0 4 1 * * /path/to/test-restore.sh

# Weekly cloud sync (Friday at 5 AM)
0 5 * * 5 /path/to/cloud-backup.sh
```

## Important Notes

⚠️ **Critical Reminders:**
- Backups are useless if they can't be restored—test regularly
- Store backups in at least 2 locations (local + cloud)
- Encrypt backups containing API keys and credentials
- Keep certificates backed up—recreating them takes 30+ minutes
- Test restore process before disaster strikes
- Document your backup procedure

✅ **Best Practices:**
- Backup at least daily
- Test restore monthly
- Keep offsite backups
- Encrypt sensitive data
- Monitor backup job status
- Alert on backup failures

---

**See also:** [Upgrading](upgrading.md) | [Troubleshooting](troubleshooting.md) | [Security](security.md)
