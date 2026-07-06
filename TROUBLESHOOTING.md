# Troubleshooting Guide

Common issues and solutions for YAHLP.

## Table of Contents
1. [Installation Issues](#installation-issues)
2. [Service Connection](#service-connection)
3. [HTTPS & Certificates](#https--certificates)
4. [Authentication](#authentication)
5. [Dashboard Issues](#dashboard-issues)
6. [Getting Help](#getting-help)

---

## Installation Issues

### Container Won't Start

**Symptom:** Docker container shows `exited` or `error` status

**Check logs:**
```bash
docker-compose logs yahlp
```

**Common causes:**

**Port already in use:**
```
Error: bind: address already in use :443
```
Solution:
```bash
# Find what's using port 80/443
netstat -tlnp | grep :80
netstat -tlnp | grep :443

# Stop conflicting service or use different ports in docker-compose.yml
```

**Volume permission error:**
```
Permission denied: /etc/letsencrypt
```
Solution:
```bash
# Fix volume permissions
sudo chown -R 99:100 ./appdata/
sudo chmod -R 755 ./appdata/
```

**Out of disk space:**
```
No space left on device
```
Solution:
```bash
# Free up disk space
df -h  # Check disk usage
docker system prune  # Clean up unused Docker data
```

### Dashboard Not Loading on First Run

**Symptom:** "Connection refused" or blank page for first 2-5 minutes

This is normal! YAHLP takes time on first start:
- Apache loading
- Certificates generating (public mode)
- Dashboard building
- Check logs: `docker-compose logs -f yahlp`

**Wait 3-5 minutes and try again.**

---

## Service Connection

### Service Shows "Offline" or "Unreachable"

**Symptom:** Service shows offline despite being configured

**Step 1: Verify service is running**
```bash
docker-compose ps sonarr
# Should show "Up" status
```

**Step 2: Check service URL**
```bash
# Verify URL in .env matches actual service
# Common format: http://servicename:port

# Example:
SONARR_URL=http://sonarr:8989  # Correct
SONARR_URL=http://localhost:8989  # Wrong (localhost doesn't work in Docker)
SONARR_URL=http://192.168.1.100:8989  # Wrong (use container name)
```

**Step 3: Test connectivity**
```bash
# From inside YAHLP container
docker-compose exec yahlp curl http://sonarr:8989

# Should return HTML or HTTP 200 (not connection refused)
```

**Step 4: Check firewall**
```bash
# Is service listening?
docker-compose exec sonarr netstat -tlnp | grep 8989
# Should show service listening
```

**Step 5: Restart service**
```bash
docker-compose restart sonarr
docker-compose restart yahlp
# Wait 30 seconds then check health
```

### Getting "502 Bad Gateway"

**Symptom:** Click service, get error page "502 Bad Gateway"

**Causes:**
1. Service URL wrong
2. Service not running
3. Service crashed
4. Network problem between YAHLP and service

**Debug:**
```bash
# Check Apache logs
docker-compose logs yahlp | grep 502

# Check if service is really up
docker-compose ps
docker-compose logs servicename | tail -20

# Try direct curl from YAHLP
docker-compose exec yahlp curl http://servicename:port
```

### Service Reports "502" or "Connection Refused"

**Symptom:** Service loads but shows proxy error

**Check:**
1. Service is configured correctly in `.env`
2. Service container is running: `docker-compose ps`
3. Service web port is correct (see [SERVICES.md](SERVICES.md))
4. Service isn't behind its own authentication

**Example fix:**
```bash
# qBittorrent shows 502

# Check it's running
docker-compose ps qbittorrent  # Should show "Up"

# Check port
docker-compose logs qbittorrent | grep "8080"  # Should show listening

# Restart
docker-compose restart qbittorrent
docker-compose restart yahlp
```

---

## HTTPS & Certificates

### Certificate Error in Browser

**Symptom:** "Not secure" warning or certificate error

**Common causes:**

**Domain name mismatch:**
```
Certificate is for: yourdomain.com
Browser is accessing: www.yourdomain.com
```
Solution: Access via exact domain in certificate

**Certificate not yet generated (public mode):**
- Wait 2-5 minutes on first run
- Check logs: `docker-compose logs yahlp | grep -i cert`

**Expired certificate:**
- Should auto-renew
- Check: `docker-compose logs yahlp | grep -i renew`
- If expired, restart: `docker-compose restart yahlp`

**Self-signed certificate (private mode):**
This is normal - browser will warn but it's secure
- Click "Advanced" → "Proceed anyway"
- Or accept permanent exception

### Let's Encrypt Certificate Not Generated

**Symptom:** Public mode but no valid certificate

**Checklist:**
1. ✅ `ACCESS_MODE=public` set
2. ✅ `DOMAIN` set to valid domain name
3. ✅ `EMAIL` set to valid email
4. ✅ Domain DNS resolves: `nslookup yourdomain.com`
5. ✅ Ports 80/443 open: Test with port scanner
6. ✅ No firewall blocking 80/443

**Check logs:**
```bash
docker-compose logs yahlp | grep -i "acme\|let's\|certificate"
```

**Common error: "dns-01 challenge failed"**
- DNS not resolving correctly
- Wait 24 hours for DNS propagation
- Try different DNS (8.8.8.8)

**Common error: "connection refused"**
- Ports 80/443 not open to internet
- Check firewall rules
- Check port forwarding on router

**Force renewal:**
```bash
# Remove old cert and restart
rm -rf ./appdata/*
docker-compose restart yahlp
# Wait 5 minutes for new certificate
```

### Certificate Renewal Failing

**Symptom:** Cert will expire soon but won't renew

**Check auto-renewal logs:**
```bash
docker-compose logs yahlp | grep -i "renew\|auto"
```

**Manual renewal:**
```bash
# Restart container to trigger renewal
docker-compose restart yahlp

# Monitor
docker-compose logs -f yahlp | grep -i cert
```

---

## Authentication

### Basic Auth Not Prompting for Password

**Symptom:** No login prompt, can access without password

**Check:**
1. AUTHTYPE is set: `AUTHTYPE=basic`
2. Credentials are configured: `BASIC_AUTH_CREDENTIALS=user:pass`
3. Container restarted: `docker-compose restart yahlp`

**Debug:**
```bash
# Check if auth is enabled in Apache
docker-compose exec yahlp grep -r "basic" /etc/apache2/conf-enabled/

# Should show "AuthType Basic"
# If not, restart was needed
```

### Wrong Password Keeps Rejecting

**Symptom:** Type correct password but get "401 Unauthorized"

**Check:**
1. No typos in password
2. No special shell characters
3. Format is correct: `BASIC_AUTH_CREDENTIALS=username:password`

**If using special characters:**
```bash
# Use quotes in .env
BASIC_AUTH_CREDENTIALS="user:pass@word!"
```

**Reset credentials:**
```bash
# Edit .env
BASIC_AUTH_CREDENTIALS=newuser:newpass

# Restart
docker-compose restart yahlp

# Wait 10 seconds, try new credentials
```

### OAuth Shows "Invalid Redirect URI"

**Symptom:** Google/Microsoft OAuth shows redirect error

**Check in OAuth provider:**
1. Google Cloud Console / Azure Portal
2. Find your application
3. Check "Redirect URIs" or "Authorized redirect URIs"
4. Must include: `https://yourdomain.com/auth/oauth2/callback`
5. Add if missing
6. Wait 2-3 minutes for changes to apply

**Also check:**
- HTTPS working (valid certificate)
- Domain resolves correctly
- Domain matches exactly (no www prefix if not registered)

---

## Dashboard Issues

### Services Not Showing on Dashboard

**Symptom:** Enabled services don't appear in grid

**Check:**
1. Service is enabled: `ENABLE_SERVICENAME=true`
2. URL is set: `SERVICENAME_URL=http://...`
3. Service is running: `docker-compose ps`
4. YAHLP restarted after changes: `docker-compose restart yahlp`

**Wait for health check:**
- Health check runs every 30 seconds
- First check takes 60+ seconds
- Watch logs: `docker-compose logs -f yahlp`

### Service Status Always "Offline"

**Symptom:** Service enabled and running but shows offline

**Common causes:**
1. Service returns non-200 HTTP status
2. Service requires authentication
3. Service health endpoint unavailable

**Check health endpoint:**
```bash
# Try what YAHLP tries
curl http://servicename:8989/api/v3/system/status  # Sonarr example

# If it fails, service may need auth configured
```

### Layout Switcher Not Appearing

**Symptom:** No slider at bottom to change layouts

**Check:**
1. `DASHBOARD_STYLE` doesn't have `:only` suffix
2. Viewing on desktop (not mobile, where it's hidden)
3. Not using fullscreen/kiosk mode
4. Browser cache cleared (Ctrl+Shift+R)

**If you want to hide switcher:**
```bash
DASHBOARD_STYLE=modern:only
docker-compose restart yahlp
```

### Dashboard Loads Slow

**Symptom:** Dashboard takes 10+ seconds to load

**Causes:**
1. Too many services (15+)
2. Slow service responses
3. Network latency
4. API timeouts

**Optimization:**
1. Disable unused services: `ENABLE_SERVICE=false`
2. Check service health: Restart slow services
3. Increase timeout (if option available in future)
4. Use simpler layout: `DASHBOARD_STYLE=minimal`

### Dashboard Styling Broken

**Symptom:** Missing colors, misaligned layout, broken fonts

**Solutions:**
1. Clear browser cache: Ctrl+Shift+Del
2. Hard refresh: Ctrl+Shift+R
3. Try private/incognito window
4. Try different browser

**If persists:**
```bash
# Rebuild HTML files
docker-compose restart yahlp
# Wait 2 minutes
```

---

## Network/Connectivity

### "Cannot reach yourdomain.com"

**Symptom:** Domain is not accessible from external network

**Check:**
1. Domain DNS working: `nslookup yourdomain.com`
2. Ports 80/443 open: Test with [canyouseeme.org](https://canyouseeme.org)
3. Router port forwarding enabled
4. Firewall allows 80/443

**Test DNS:**
```bash
nslookup yourdomain.com
# Should return your public IP
```

**Test ports:**
```bash
# From another computer
telnet yourdomain.com 443
# Should connect (no "connection refused")
```

### "This site can't be reached" but PING works

**Symptom:** Domain resolves but won't load

**Causes:**
1. HTTP(S) server not listening
2. Firewall blocking 443
3. Wrong port in Docker mapping

**Check:**
```bash
# Is YAHLP actually listening?
docker-compose exec yahlp netstat -tlnp | grep 443

# Should show Apache listening on 0.0.0.0:443
```

---

## Docker Issues

### "Docker command not found"

**Symptom:** `docker: command not found`

**Solution:**
- Docker not installed or not in PATH
- Install Docker Desktop
- Or use full path: `/usr/bin/docker`

### Containers keep restarting

**Symptom:** Container starts then exits immediately

**Check logs:**
```bash
docker-compose logs --tail=50 yahlp
```

**Common causes:**
- Configuration error
- Port in use
- Volume permission issue
- Out of memory

### "Cannot connect to Docker daemon"

**Symptom:** Docker command fails with daemon error

**Solution:**
- Docker daemon not running
- Start Docker Desktop
- Or check systemd: `sudo systemctl start docker`

---

## Getting Help

### Before Asking for Help

1. Check these docs:
   - [INSTALLATION.md](INSTALLATION.md) - Setup
   - [CONFIGURATION.md](CONFIGURATION.md) - Settings
   - [SERVICES.md](SERVICES.md) - Service setup
   - [AUTHENTICATION.md](AUTHENTICATION.md) - Auth issues

2. Collect information:
   ```bash
   # Get error logs
   docker-compose logs yahlp > logs.txt
   
   # Get config (without secrets)
   grep -v "SECRET\|KEY\|PASSWORD" .env > config.txt
   
   # Get status
   docker-compose ps > status.txt
   ```

3. Check Docker:
   - Container running: `docker-compose ps`
   - Container logs: `docker-compose logs`
   - Network: `docker network ls`

### Reporting Issues

Include:
- Error message (exact)
- Docker logs (last 50 lines)
- Your configuration (without passwords)
- What you've tried
- Your environment (OS, Docker version)

### Resources

- GitHub Issues: [github.com/auskento/YAHLP/issues](https://github.com/auskento/YAHLP/issues)
- Docker Docs: [docs.docker.com](https://docs.docker.com)
- Let's Encrypt Status: [letsencrypt.org/status](https://letsencrypt.org/status)

---

## See Also

- [INSTALLATION.md](INSTALLATION.md) - Setup help
- [CONFIGURATION.md](CONFIGURATION.md) - Configuration reference
- [SERVICES.md](SERVICES.md) - Service-specific help
- [AUTHENTICATION.md](AUTHENTICATION.md) - Auth setup
