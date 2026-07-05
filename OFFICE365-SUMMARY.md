# Office 365 Authentication - Feature Summary

## 🔐 What's New

Your reverse proxy supports **enterprise-grade Office 365 / Azure AD authentication** via YAHLP's `AUTHTYPE=entra` option (Microsoft Entra ID, formerly Azure AD)!

This means:
- ✅ All services protected with Microsoft login
- ✅ Single Sign-On (SSO) with Office 365
- ✅ No separate password management
- ✅ Access can be scoped via Azure AD app registration settings
- ✅ Full audit trail in Azure AD
- ✅ Optional multi-factor authentication
- ✅ User info passed to backend services

## Quick Enable/Disable

```env
# Enable Entra ID auth
AUTHTYPE=entra

# Disable (services accessible without login)
AUTHTYPE=none
```

## Setup (5 Steps)

### Step 1: Register App in Azure AD
1. Go to https://portal.azure.com
2. Create new app registration
3. Set redirect URI to: `https://yourdomain.com/auth/oauth2/callback`
4. Get Application (client) ID and Directory (tenant) ID

### Step 2: Create Client Secret
1. In app → Certificates & secrets
2. Create new client secret
3. Copy the VALUE (save securely!)

### Step 3: Set Environment Variables
```env
AUTHTYPE=entra
ENTRA_CLIENT_ID="YOUR_APP_ID"
ENTRA_CLIENT_SECRET="YOUR_SECRET"
ENTRA_REDIRECT_URI="https://yourdomain.com/auth/oauth2/callback"
ENTRA_PROVIDER_METADATA_URL="https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0/.well-known/openid-configuration"
ENTRA_CRYPTO_PASSPHRASE=""   # Optional - auto-generated if left blank
```

### Step 4: Deploy
```bash
docker-compose build
docker-compose up -d
```

### Step 5: Test
1. Visit https://yourdomain.com
2. Login with Office 365 account
3. Access your services!

## Relevant Files

- `AUTHENTICATION-SETUP.md` / `OFFICE365-AUTH.md` ⭐ - Setup guides
- `apache-conf/oauth2-entra.conf` - OpenID Connect config (templated with `@@ENTRA_*@@` placeholders, filled in by `docker-entrypoint.sh`)
- `apache-conf/auth-entra-protect.conf` - Authorization rules (included when `AUTHTYPE=entra`)
- `Dockerfile` - Installs and enables `libapache2-mod-auth-openidc` (`a2enmod auth_openidc`)
- `docker-entrypoint.sh` - Reads `AUTHTYPE`/`ENTRA_*` vars, validates them, and wires up the Entra OAuth2 config (also handles Emby/Plex/Seerr subdomain OAuth when their `*_DOMAIN`/`*_REDIRECT_URI` vars are set)
- `generate-config.sh` - Generates the `Include` directive for `auth-entra-protect.conf` in the main reverse-proxy vhost
- `.env.example` - `AUTHTYPE`/`ENTRA_*` variable definitions

## Architecture

```
User visits https://yourdomain.com
         ↓
    Not logged in?
         ↓
  Redirect to Microsoft Login
         ↓
  User enters credentials
         ↓
  Azure AD validates
         ↓
  Redirect back to /auth/oauth2/callback
         ↓
  Apache validates token
         ↓
  Create session
         ↓
  User can access services!
         ↓
Service (Sonarr, Radarr, etc.)
Gets user info in headers:
  X-Remote-User: user@domain.com
  X-Remote-Name: John Doe
  X-Remote-ID: azure-ad-id
```

## Security Features

✅ **HTTPS only** - OAuth2 requires secure connection (enforced in public mode)  
✅ **Token validation** - Azure AD tokens verified  
✅ **Session encryption** - `ENTRA_CRYPTO_PASSPHRASE` (auto-generated if not set)  
✅ **Access scoping** - Controlled via Azure AD app registration ("Supported account types", assignment required, Conditional Access) — no built-in domain allow-list variable  
✅ **Automatic logout** - Session timeout configurable  
✅ **No password storage** - Uses Office 365 credentials  
✅ **Audit trail** - Azure AD logs everything  
✅ **MFA capable** - Can require MFA in Azure AD  

## Use Cases

### Company Internal Network
Set "Supported account types" to your organization only when registering the Entra app. Only employees in your tenant can access.

### Family/Friends or Personal Accounts
Set "Supported account types" to "Accounts in any organizational directory and personal Microsoft accounts" to allow any Microsoft account to sign in.

### Specific Users Only
Under **Enterprise applications**, enable "Assignment required" for the app and explicitly assign individual users or groups.

## Environment Variables

| Variable | Required | Example |
|----------|----------|---------|
| `AUTHTYPE` | Yes | `entra` |
| `ENTRA_CLIENT_ID` | Yes (if AUTHTYPE=entra) | `1a2b3c4d-5e6f-7a8b-9c0d...` |
| `ENTRA_CLIENT_SECRET` | Yes (if AUTHTYPE=entra) | `abc123~DEF456_GHI789=` |
| `ENTRA_REDIRECT_URI` | Yes (if AUTHTYPE=entra) | `https://yourdomain.com/auth/oauth2/callback` |
| `ENTRA_PROVIDER_METADATA_URL` | Yes (if AUTHTYPE=entra) | `https://login.microsoftonline.com/TENANT_ID/v2.0/.well-known/openid-configuration` |
| `ENTRA_CRYPTO_PASSPHRASE` | Optional | `randomSecureString123` (auto-generated if omitted) |

## How It Works

### Authentication Flow

1. **User arrives at reverse proxy**
   - No session cookie

2. **Apache checks authentication**
   - If not authenticated, redirect to OAuth2 login

3. **User redirected to Microsoft**
   - Microsoft login page displayed

4. **User provides credentials**
   - Office 365 validates them

5. **Redirect back to proxy**
   - With authorization code

6. **Proxy exchanges code for token**
   - Validates with Azure AD

7. **Session created**
   - Cookie stored in browser

8. **User can now access services**
   - Session header included in requests

### User Info Passed to Services

After login, these headers are available to backend services:

```
X-Remote-User: john@example.com
X-Remote-Name: John Smith
X-Remote-ID: 550e8400-e29b-41d4-a716-446655440000
X-Auth-Method: Entra
```

Services like Sonarr, Radarr can read these headers for features like:
- User-specific content tracking
- Personal watchlists
- Custom notifications
- Advanced integration

## Troubleshooting

### Common Issues

**"Invalid client ID"**
- Check you copied the correct Application (client) ID from Azure AD
- Restart the container after changing

**"Redirect URI mismatch"**
- Must be EXACT match between Azure AD and `ENTRA_REDIRECT_URI`
- Include protocol (https://) and domain
- No trailing slashes

**"Expired secret"**
- Generate new secret in Azure AD
- Update `ENTRA_CLIENT_SECRET`
- Restart the container

**Login button not working**
- Check HTTPS is enabled (required for OAuth2 — public deployment mode only)
- Verify redirect URI is exactly correct
- Check logs: `docker-compose logs -f apache-reverse-proxy` (or `docker logs <container>`)

**Users can't access after login**
- Verify API permissions in Azure AD app
- Check "Grant admin consent" is clicked
- If sign-in should be restricted, verify Azure AD's "Supported account types" / Conditional Access / assignment settings (there is no `OAUTH2_ALLOWED_DOMAINS`-style variable in YAHLP)

**See detailed troubleshooting in `OFFICE365-AUTH.md`**

## Configuration Examples

### Complete Media Server with Auth
```env
# Basics
DOMAIN=media.company.com
EMAIL=admin@company.com

# Services
ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_JELLYFIN=true
ENABLE_QBITTORRENT=true
ENABLE_SEERR=true

# Entra ID Auth
AUTHTYPE=entra
ENTRA_CLIENT_ID="1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d"
ENTRA_CLIENT_SECRET="~abc1234567890DEF_GHI=JKL"
ENTRA_REDIRECT_URI="https://media.company.com/auth/oauth2/callback"
ENTRA_PROVIDER_METADATA_URL="https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0/.well-known/openid-configuration"
ENTRA_CRYPTO_PASSPHRASE="RandomPassphrase123456789="
```

### Personal Homelab (No Auth)
```env
AUTHTYPE=none
# Services accessible without login
```

### Friends/Family Access
```env
AUTHTYPE=entra
# In Azure AD app registration, set "Supported account types" to
# "Accounts in any organizational directory and personal Microsoft accounts"
# so friends/family can sign in with any Microsoft account
```

## Performance Impact

- Minimal overhead for authentication
- First login: ~2-3 seconds (redirect to Microsoft)
- Subsequent requests: <100ms (local session check)
- Sessions cached in Apache (no external calls needed)

## Cost

**Free!**
- Office 365 authentication uses Azure AD (free tier)
- No additional costs
- Works with:
  - Free Office 365 accounts
  - Business subscriptions
  - Enterprise plans
  - Personal Microsoft accounts

## Next Steps

1. **Read `OFFICE365-AUTH.md`** - Complete step-by-step guide
2. **Register app in Azure AD** - 5-10 minutes
3. **Get credentials** - Client ID, Secret, and Directory (tenant) ID
4. **Update your `.env` file** (or `docker-compose.yml` environment block) with `AUTHTYPE=entra` and `ENTRA_*` variables
5. **Deploy and test** - Try logging in!

## FAQ

**Q: Do users need Office 365 licenses?**
A: No! Free Microsoft accounts work fine.

**Q: Can I use personal Microsoft accounts?**
A: Yes! If your Azure AD app registration's "Supported account types" allows personal Microsoft accounts.

**Q: What if user forgets Office 365 password?**
A: They reset it via Microsoft account recovery - not your problem!

**Q: Can I mix authentication methods?**
A: Not currently - `AUTHTYPE` is a single global setting (`none`, `basic`, `entra`, or `google`); either all protected or all open.

**Q: Do I need to store passwords?**
A: No! Office 365 handles authentication.

**Q: How long are sessions?**
A: Default 1 hour inactivity, 24 hours max (configurable in `apache-conf/oauth2-entra.conf`).

**Q: Can I revoke access?**
A: Yes! Remove/disable the user's assignment in Azure AD (Enterprise applications), or revoke their account, and restart if needed.

---

**You now have enterprise-grade authentication protecting your media server!** 🔒

See `OFFICE365-AUTH.md` for the complete setup guide.

