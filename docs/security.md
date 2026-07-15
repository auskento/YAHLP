# Security

## Overview

YAHLP implements multiple layers of security to protect your homelab utilities:

1. **Network Security** - Reverse proxy, TLS encryption, isolated containers
2. **Authentication** - Basic auth, OAuth2 (Entra/Google), session management
3. **Authorization** - Service-level access control
4. **Data Protection** - Certificate management, credential storage

## TLS/SSL Configuration

### Automatic HTTPS (Public Mode)
- **Provider:** Let's Encrypt
- **Renewal:** Automatic 30 days before expiration
- **Certificates:** Stored in `/etc/letsencrypt/` volume
- **Security:** TLS 1.2+ enforced, modern ECDHE ciphers, weak ciphers disabled
- **Cipher Suites:** ECDHE (Elliptic Curve Diffie-Hellman Ephemeral) for forward secrecy

#### Modern SSL/TLS Configuration
```
TLS Versions: 1.2 (minimum) and 1.3 (preferred)
Protocols: -SSLv2 -SSLv3 -TLSv1 -TLSv1.1 (all disabled)

Cipher Suites (in order of preference):
- ECDHE-RSA-AES256-GCM-SHA384  (TLS 1.2/1.3, ECDHE, AES-256-GCM)
- ECDHE-RSA-AES128-GCM-SHA256  (TLS 1.2/1.3, ECDHE, AES-128-GCM)
- ECDHE-RSA-CHACHA20-POLY1305  (TLS 1.2/1.3, ECDHE, ChaCha20-Poly1305)

Disabled Ciphers:
- aNULL (no authentication)
- MD5 (broken hash algorithm)
- RC4 (weak stream cipher)
- DES (too small key)
```

**Configuration (auto-applied):**
```bash
SSL_PROTOCOLS=all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSL_CIPHERS=HIGH:!aNULL:!MD5
```

#### Verify Configuration
```bash
# Verify certificate and dates
docker exec -it yahlp openssl x509 -noout -dates -in /etc/letsencrypt/live/yourdomain.com/cert.pem

# Test SSL/TLS protocols and ciphers
docker exec -it yahlp openssl s_client -connect localhost:443 -tls1_2

# Verify ECDHE is enabled
docker exec -it yahlp openssl s_client -connect localhost:443 -cipher "ECDHE"

# Test with external tool (Mozilla SSL Configuration Generator)
# Visit: https://ssl-config.mozilla.org/ to validate
```

### Manual HTTPS (Private Mode)
- Self-signed or custom certificates
- Configure paths in `docker-compose.yml`
- Mount certificate files as volumes

```yaml
volumes:
  - ./certs/cert.pem:/etc/apache2/ssl/server.crt
  - ./certs/key.pem:/etc/apache2/ssl/server.key
```

### SSL Best Practices
✅ Do:
- Keep certificates renewed automatically
- Use strong cipher suites
- Enable HSTS headers
- Monitor certificate expiration
- Rotate certificates annually

❌ Don't:
- Use self-signed certificates in production without warning
- Disable certificate verification
- Share private keys
- Use outdated TLS versions (< 1.2)

## Authentication Methods

### No Authentication
```bash
AUTHTYPE=none
```
- Dashboard publicly accessible
- **Use only on:** Private networks behind firewall
- **Not recommended for:** Internet-facing deployments

### Basic Authentication
```bash
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS="user1:password1|user2:password2"
```
- **How it works:** HTTP Basic Auth (base64 encoded credentials)
- **Security:** Always use with HTTPS to protect credentials
- **Best for:** Simple homelab deployments
- **Limitations:** No session management, credentials in headers

**Security considerations:**
- Passwords transmitted in every request (HTTPS only!)
- Use strong, unique passwords
- Limit user accounts to necessary personnel

### Entra ID / Azure AD OAuth
```bash
AUTHTYPE=entra
ENTRA_CLIENT_ID=your-client-id
ENTRA_CLIENT_SECRET=your-client-secret
ENTRA_REDIRECT_URI=https://yourdomain.com/auth/oauth2/callback
ENTRA_PROVIDER_METADATA_URL=https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration
```
- **How it works:** OAuth2 redirect to Microsoft login
- **Best for:** Enterprise/corporate deployments
- **Benefits:** 
  - Centralized identity management
  - MFA support via Azure
  - No password storage
  - Audit trail in Azure AD logs
- **Setup:** See [Azure AD Setup Guide](#azure-ad-oauth-setup)

### Google OAuth
```bash
AUTHTYPE=google
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REDIRECT_URI=https://yourdomain.com
```
- **How it works:** OAuth2 redirect to Google login
- **Best for:** Personal deployments with Google accounts
- **Benefits:**
  - No password storage
  - 2FA support via Google Account
  - Simple setup
- **Setup:** See [Google OAuth Setup Guide](#google-oauth-setup)

## Credential Management

### API Keys
Store securely in configuration:

**✅ Good:**
```bash
# In docker-compose environment variables
SONARR_API_KEY=${SONARR_API_KEY}

# Or yahlp.json5
sonarr: {
  api_key: '...'  # Loaded from environment, not hardcoded
}
```

**❌ Bad:**
```bash
# Hardcoded in docker-compose.yml
SONARR_API_KEY=abc123...  # Will be committed to git!

# Visible in process list
docker exec yahlp env | grep API_KEY
```

### Secret Storage Best Practices

1. **Use `.env` file (git-ignored)**
   ```bash
   SONARR_API_KEY=your-actual-key
   JELLYFIN_API_KEY=your-actual-key
   ```

2. **Use Docker Secrets** (swarm mode)
   ```yaml
   secrets:
     sonarr_api_key:
       file: ./secrets/sonarr_api_key.txt
   ```

3. **Use Environment Variables** (Kubernetes)
   - Injected at runtime
   - Never stored on disk

4. **Never hardcode** in:
   - docker-compose.yml
   - Configuration files checked into git
   - GitHub repositories
   - Container images

## Network Security

### Internal Network Isolation
```yaml
networks:
  homelab:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: docker0
```
- Services only accessible via Docker network
- Cannot reach external networks without explicit routing
- Prevents lateral movement if one service compromised

### Firewall Rules

**Public deployment:**
```bash
# Only expose YAHLP, not individual services
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny 3000/tcp          # Block Node.js API port
ufw deny 8989/tcp          # Block individual service ports
```

**Private deployment:**
```bash
# Allow only from internal network
ufw allow from 192.168.1.0/24 to any port 80
ufw allow from 192.168.1.0/24 to any port 443
```

### Port Mapping
```yaml
# ❌ Avoid exposing individual service ports
ports:
  - "8989:8989"  # Sonarr accessible directly!
  - "7878:7878"  # Radarr accessible directly!

# ✅ Only expose reverse proxy
ports:
  - "80:80"
  - "443:443"
```

## Service-Level Security

### Request Validation
- Strip sensitive headers before proxying
- Validate API keys before forwarding
- Limit request sizes
- Rate limiting per service

### API Key Authentication
```javascript
// In proxy.js
const apiKey = services[service].key;
if (authType === 'header') {
  headers['X-Api-Key'] = apiKey;  // Inject securely
} else if (authType === 'query') {
  url += `?apikey=${apiKey}`;     // Query parameter
}
```

### CORS Policy
- Restricted to same-origin by default
- Prevents cross-site request attacks
- Service-specific CORS headers injected by proxy

## Data Protection

### Persistent Volume Security
```bash
# Certificate storage
/etc/letsencrypt/
  └── live/yourdomain.com/
      ├── privkey.pem      # Keep ownership: root:root
      └── fullchain.pem

# Configuration
/etc/yahlp/
  ├── yahlp.json5          # Contains API keys
  └── sites.json5

# Logs
/var/log/apache2/
  ├── access.log           # May contain sensitive headers
  └── error.log
```

**Permissions:**
```bash
# Restrict to container user
docker exec yahlp chmod 600 /etc/letsencrypt/live/*/privkey.pem
docker exec yahlp chmod 644 /etc/letsencrypt/live/*/fullchain.pem
```

### Backup Security
When backing up persistent volumes:
```bash
# Exclude sensitive data
tar --exclude='yahlp.json5' --exclude='privkey.pem' -czf backup.tar.gz /data/

# Or encrypt backup
tar -czf - /data/ | gpg --encrypt -r you@example.com > backup.tar.gz.gpg

# Decrypt when needed
gpg --decrypt backup.tar.gz.gpg | tar -xz
```

## Monitoring & Logging

### Apache Logs
```bash
# View access log
docker exec -it yahlp tail -f /var/log/apache2/access_log

# View error log
docker exec -it yahlp tail -f /var/log/apache2/error_log

# Search for failed auth attempts
docker exec -it yahlp grep "401\|403" /var/log/apache2/access_log
```

### Security Log Monitoring
```bash
# Failed login attempts
docker exec -it yahlp grep -i "denied\|failed\|unauthorized" /var/log/apache2/error_log

# Certificate issues
docker exec -it yahlp grep -i "certificate\|ssl\|tls" /var/log/apache2/error_log

# API errors
docker logs yahlp | grep -i "error\|failed"
```

### Log Aggregation
For production, consider:
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Splunk
- Cloudflare/Datadog
- Local syslog server

## Security Hardening Checklist

- [ ] Enable HTTPS (Let's Encrypt or custom cert)
- [ ] Configure authentication (Basic/OAuth/None)
- [ ] Use strong passwords (if Basic Auth)
- [ ] Store API keys in `.env` (never hardcoded)
- [ ] Restrict firewall to only ports 80/443
- [ ] Use isolated Docker network
- [ ] Enable Docker restart policy
- [ ] Keep container/host OS updated
- [ ] Monitor logs regularly
- [ ] Backup certificates and config
- [ ] Test disaster recovery
- [ ] Document security procedures

## Common Vulnerabilities & Mitigation

### Hardcoded Credentials
**Problem:** API keys in docker-compose.yml
**Solution:** Use `.env` file, environment variables, or Docker secrets

### Exposed Ports
**Problem:** Individual service ports accessible directly
**Solution:** Only expose 80/443, bind internal services to localhost

### Weak Passwords
**Problem:** Simple Basic Auth passwords
**Solution:** Use strong passwords + HTTPS, or OAuth2

### Certificate Expiration
**Problem:** Let's Encrypt certificate expires
**Solution:** Enable auto-renewal, monitor expiration dates

### Unencrypted Communication
**Problem:** HTTP traffic in transit
**Solution:** Force HTTPS redirect, use TLS 1.2+

### Service Misconfiguration
**Problem:** Services with default credentials
**Solution:** Change all default passwords, use authentication

## Incident Response

### If Compromised
1. Revoke affected API keys immediately
2. Review logs for unauthorized access
3. Rotate all passwords
4. Regenerate OAuth credentials
5. Consider rebuilding container from scratch
6. Update all downstream services

### Incident Log Template
```
Date: YYYY-MM-DD HH:MM:SS UTC
Severity: [Critical/High/Medium/Low]
Service(s) Affected: [service names]
Root Cause: [what happened]
Impact: [affected users/data]
Actions Taken: [response steps]
Prevention: [how to prevent future]
```

---

**See also:** [Architecture](architecture.md) | [Configuration](configuration.md) | [Troubleshooting](troubleshooting.md)
