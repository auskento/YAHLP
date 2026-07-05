# Office 365 / Azure AD Authentication Guide

## Overview

This guide shows how to protect all your media server services with Office 365 / Azure AD (Microsoft Entra ID) authentication, using YAHLP's `AUTHTYPE=entra` option. Users will need to log in with their Microsoft account before accessing any services.

For the full picture of all supported auth methods (including Basic Auth and Google OAuth), see `AUTHENTICATION-SETUP.md`.

## Benefits

✅ **Single Sign-On (SSO)** - Users log in once with their Microsoft account  
✅ **Centralized Control** - Manage who can access via Azure AD  
✅ **No Password Management** - Uses Office 365 credentials  
✅ **Audit Trail** - Azure AD logs all access  
✅ **Multi-factor Authentication** - Can require MFA for extra security (via Azure AD Conditional Access)  
✅ **Access Restriction** - Scope sign-in via Azure AD app registration settings (org-only, specific tenants, or assigned users/groups)  

## Prerequisites

- Microsoft/Office 365 account or Azure AD tenant
- Access to Azure AD/Microsoft Entra ID admin portal
- A registered domain (yourdomain.com)
- Docker setup already running

## Step 1: Register an Application in Azure AD

### 1.1 Go to Azure AD Portal

1. Visit: https://portal.azure.com
2. Sign in with your Microsoft/Office 365 account
3. Navigate to **Azure Active Directory** → **App registrations**
4. Click **+ New registration**

### 1.2 Create New Application

Fill in the form:

- **Name**: `Media Server Reverse Proxy` (or any name you prefer)
- **Supported account types**: Choose based on your needs:
  - `Accounts in this organizational directory only` - Only your organization
  - `Accounts in any organizational directory` - Any Azure AD organization
  - `Accounts in any organizational directory and personal Microsoft accounts` - Anyone
- **Redirect URI**: 
  - Platform: `Web`
  - URI: `https://yourdomain.com/auth/oauth2/callback`

Click **Register**

### 1.3 Get Application Details

After registration, you'll see the application page:

**Copy these values:**
1. **Application (client) ID** - You'll need this for `ENTRA_CLIENT_ID`
2. **Directory (tenant) ID** - Required to build `ENTRA_PROVIDER_METADATA_URL` (see Step 2)

### 1.4 Create Client Secret

1. Go to **Certificates & secrets**
2. Click **+ New client secret**
3. Fill in:
   - **Description**: `Docker Reverse Proxy Secret`
   - **Expires**: Choose duration (24 months recommended)
4. Click **Add**
5. **Copy the VALUE** (not the ID) - You'll need this for `ENTRA_CLIENT_SECRET`

⚠️ **Important**: Save this secret securely - you won't see it again!

### 1.5 Configure API Permissions

1. Go to **API permissions**
2. Click **+ Add a permission**
3. Select **Microsoft Graph**
4. Choose **Delegated permissions**
5. Search for and select:
   - `User.Read` - Allow sign in and read profile
   - `email` - Access email address
   - `profile` - Access basic profile info
6. Click **Add permissions**
7. Click **Grant admin consent** to approve permissions

## Step 2: Configure Environment Variables

Edit your `.env` file (or `docker-compose.yml` environment block) and set:

```env
# Enable Entra ID (Office 365 / Azure AD) authentication
AUTHTYPE=entra

# From Azure AD app registration
ENTRA_CLIENT_ID="YOUR_APPLICATION_CLIENT_ID"
ENTRA_CLIENT_SECRET="YOUR_CLIENT_SECRET"

# Where users return after login (must match the Redirect URI registered in Azure AD)
ENTRA_REDIRECT_URI="https://yourdomain.com/auth/oauth2/callback"

# Tenant-specific OIDC metadata endpoint (built from your Directory/tenant ID)
ENTRA_PROVIDER_METADATA_URL="https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0/.well-known/openid-configuration"

# Random string for session cookie encryption (optional - auto-generated if omitted)
ENTRA_CRYPTO_PASSPHRASE="your-random-secure-passphrase-here"
```

Note: There is currently no built-in `OAUTH2_ALLOWED_DOMAINS`-style domain/user restriction — anyone who can authenticate against your Entra tenant/app (as scoped by "Supported account types" in the app registration) will be granted access. Restricting further requires custom Azure AD Conditional Access policies or app role assignment (see Advanced Configuration below).

### Generate Secure Passphrase (optional)

`ENTRA_CRYPTO_PASSPHRASE` is optional — if left blank, YAHLP generates a random one automatically at container startup. To set your own instead:

```bash
openssl rand -base64 24
```

Copy the output and set it as `ENTRA_CRYPTO_PASSPHRASE`.

**Example:**
```env
ENTRA_CRYPTO_PASSPHRASE="aBc1dE2fG3hI4jK5lM6nO7pQ8rS9tU=="
```

## Step 3: Update Redirect URI in Azure AD

The redirect URI must match exactly in both places:

1. **In Azure AD**: Applications → Your app → Authentication
   - Set Redirect URI to: `https://yourdomain.com/auth/oauth2/callback`
   - Mark as Public client: **No**

2. **In your `.env` file**:
   ```env
   ENTRA_REDIRECT_URI="https://yourdomain.com/auth/oauth2/callback"
   ```

⚠️ These must match exactly (including protocol https://)!

If you use `EMBY_DOMAIN`/`PLEX_DOMAIN`/`SEERR_DOMAIN` subdomains, each gets its own OIDC client instance (sharing the same `ENTRA_CLIENT_ID`/`ENTRA_CLIENT_SECRET`) using that subdomain's own `_REDIRECT_URI` variable — register those redirect URIs in Azure AD too (see AUTHENTICATION-SETUP.md for details).

## Step 4: Deploy

```bash
# Build and start
docker-compose build
docker-compose up -d

# Watch logs
docker-compose logs -f apache-reverse-proxy
```

Check for errors:
```
✓ Entra ID authentication enabled
  Client ID: YOUR_CLIENT_ID...
```

## Step 5: Test Authentication

1. Open browser to: `https://yourdomain.com`
2. You should be redirected to Microsoft login page
3. Enter your Office 365 credentials
4. You'll be asked to consent to permissions
5. After login, you'll be redirected back to your dashboard
6. You should now see your media services

## Troubleshooting

### Login Redirects But Shows Error

**Problem**: OAuth2 callback returns an error

**Solutions**:
1. Verify `ENTRA_REDIRECT_URI` matches Azure AD exactly
2. Check `ENTRA_CLIENT_ID`, `ENTRA_CLIENT_SECRET`, and `ENTRA_PROVIDER_METADATA_URL` are correct
3. Verify API permissions are granted in Azure AD
4. Check logs: `docker logs <container> | grep -i oauth` (or `apache2/error.log`)

### "Invalid client ID" Error

- Copy the correct Application (client) ID from Azure AD
- Make sure you're copying the ID, not the description

### "Secret expired" or "Invalid secret"

- Generate a new client secret in Azure AD
- Update `ENTRA_CLIENT_SECRET`
- Restart the container

### "Redirect URI mismatch"

- The redirect URI must match EXACTLY (including https://)
- Common mistake: `http://` vs `https://`
- Check for trailing slashes or differences in domain

### Users Can't Login

**Check permissions in Azure AD:**
1. Go to App registrations
2. Select your app
3. Go to API permissions
4. Verify `User.Read` is granted
5. Check "Grant admin consent" shows a green checkmark

### Unwanted Users Can Login

**Problem**: Anyone in your tenant (or any Microsoft account, depending on "Supported account types") can log in

**Solution**: There is no built-in email-domain allow-list in YAHLP. Restrict access using Azure AD itself — either narrow "Supported account types" on the app registration, use Conditional Access policies, or require the app role/group assignment.

### Session Expires Too Quickly

Adjust in `apache-conf/oauth2-entra.conf`:

```apache
OIDCSessionInactivityTimeout 3600  # Change to 7200 for 2 hours
OIDCSessionMaxDuration 86400       # Change to 604800 for 1 week
```

Then rebuild:
```bash
docker-compose build
docker-compose up -d
```

## Advanced Configuration

### Restrict to Specific Users

There is no built-in `OAUTH2_ALLOWED_DOMAINS`-style variable for restricting sign-in. To limit who can authenticate, restrict it in Azure AD itself:
- Set "Supported account types" to your organization only when registering the app, and/or
- Use "Enterprise applications → assignment required" to require explicit user/group assignment, and/or
- Use Conditional Access policies (see below)

### Require Multi-Factor Authentication

In Azure AD:
1. Go to **Conditional Access**
2. Create new policy
3. Select your application
4. Require MFA for access

### Different Access Levels

`apache-conf/auth-entra-protect.conf` is the file included when `AUTHTYPE=entra` and controls what's required to access proxied services (currently `Require valid-user` for all locations). Custom `Require` directives (e.g. group-based restrictions) can be added here, but this requires editing the Apache config directly — there is no environment-variable-driven group/role mapping built in.

### Logout Functionality

Users can end their session via the OAuth2 handler endpoint:
```
https://yourdomain.com/oauth2
```

The `/oauth2` and `/oauth2callback` locations are handled by `mod_auth_openidc`'s `oauth2-handler`, which manages session logout as well as login. Consult the `mod_auth_openidc` documentation for exact logout URL parameters if you need to link directly to a "Sign out" action.

## User Experience

### First Login
1. User visits `https://yourdomain.com`
2. Redirected to Microsoft login page
3. Enters Office 365 email and password
4. Grants permission to app
5. Redirected back to dashboard
6. Sees all enabled services

### Subsequent Logins
- User remains logged in
- Session lasts based on configured duration
- Refresh/reopen browser - stays logged in
- SSO with other Microsoft apps

### Headers Passed to Services

When authenticated, these headers are passed to backend services:

```
X-Remote-User: user@domain.com           # Email
X-Remote-Name: John Doe                  # Full name
X-Remote-ID: azure-ad-user-id            # Unique ID (OIDC sub claim)
X-Auth-Method: Entra                     # Auth method
```

Some services (Sonarr, Radarr, etc.) can read these headers for user-specific features.

## Security Best Practices

1. **Use HTTPS only** - Always use https:// for redirect URI
2. **Protect your secret** - Never commit `ENTRA_CLIENT_SECRET` to git
3. **Rotate secrets** - Generate new secrets periodically in Azure AD
4. **Monitor access** - Check Azure AD logs for suspicious activity
5. **Use strong passphrase** - Make `ENTRA_CRYPTO_PASSPHRASE` long and random (or leave blank to auto-generate)
6. **Restrict sign-in** - Since there's no built-in domain allow-list, restrict who can authenticate using Azure AD's own controls (account type scoping, assignment required, Conditional Access)
7. **Enable MFA** - Require multi-factor authentication in Azure AD
8. **Review permissions** - Only grant necessary API permissions

## Disable Authentication

To turn off Entra authentication:

```env
AUTHTYPE=none
```

Then restart the container. Services will be accessible without login.

## Complete Configuration Example

```env
DOMAIN=media.example.com
EMAIL=admin@example.com

# Services
ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_JELLYFIN=true

# Entra ID (Office 365 / Azure AD) Auth
AUTHTYPE=entra
ENTRA_CLIENT_ID="1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d"
ENTRA_CLIENT_SECRET="YOUR_SECRET_HERE~abc1234567-_=DEF"
ENTRA_REDIRECT_URI="https://media.example.com/auth/oauth2/callback"
ENTRA_PROVIDER_METADATA_URL="https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0/.well-known/openid-configuration"
ENTRA_CRYPTO_PASSPHRASE="RandomSecurePassphrase123456="
```

## Additional Resources

- [Azure AD Documentation](https://learn.microsoft.com/en-us/azure/active-directory/)
- [App Registration Guide](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [OpenID Connect Protocol](https://openid.net/connect/)
- [OAuth 2.0 Standards](https://oauth.net/2/)

## Support

If you encounter issues:

1. Check logs: `docker logs <container> | grep -i oauth` (or `/var/log/apache2/error.log`)
2. Verify Azure AD configuration
3. Ensure domain/DNS is correct
4. Check that HTTPS is working
5. Verify redirect URI matches exactly

---

**You now have enterprise-grade authentication for your media server!** 🔐

