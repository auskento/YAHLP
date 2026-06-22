#!/bin/bash

# Generate Emby Subdomain VirtualHost Configuration
# Called with: domain [enable_oauth]
# Requires OIDC env vars: OIDC_PROVIDER_METADATA_URL, OAUTH2_CLIENT_ID, OAUTH2_CLIENT_SECRET, OAUTH2_CRYPTO_PASSPHRASE

EMBY_DOMAIN="${1:-emby.example.com}"
ENABLE_OAUTH="${2:-false}"

cat << 'EOF'
# Emby Subdomain VirtualHost
<VirtualHost *:443>
    ServerName @@EMBY_DOMAIN@@
    
    # SSL/TLS Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/@@EMBY_DOMAIN@@/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/@@EMBY_DOMAIN@@/privkey.pem
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    
    # Proxy settings
    ProxyRequests Off
    ProxyPreserveHost On
    
    # Request limit settings for Emby compatibility
    LimitRequestFieldSize 32768
    LimitRequestFields 100
    LimitRequestLine 32768
    
    # KeepAlive and timeout settings
    KeepAlive On
    Timeout 300
    
    # Forward crucial headers
    RequestHeader set X-Forwarded-Proto "https" env=HTTPS
    RequestHeader set X-Forwarded-Port "443"
    RequestHeader set X-Real-IP %{REMOTE_ADDR}s
    RequestHeader set X-Forwarded-For %{HTTP:X-Forwarded-For}e
EOF

# Add OIDC configuration if OAuth is enabled
if [ "$ENABLE_OAUTH" = "true" ]; then
    cat << 'EOF'
    
    # Office 365 OpenID Connect Configuration for Emby subdomain
    OIDCSessionType server-cache
    OIDCClientID @@OAUTH2_CLIENT_ID@@
    OIDCClientSecret @@OAUTH2_CLIENT_SECRET@@
    OIDCRedirectURI https://@@EMBY_DOMAIN@@/oauth2/callback
    OIDCProviderMetadataURL @@OIDC_PROVIDER_METADATA_URL@@
    OIDCScope "openid profile email"
    OIDCSessionInactivityTimeout 3600
    OIDCSessionMaxDuration 86400
    OIDCClaimPrefix OIDC_
    OIDCPassClaimsAs environment
    OIDCCryptoPassphrase "@@OAUTH2_CRYPTO_PASSPHRASE@@"
    OIDCSSLValidateServer On
    OIDCClaimDelimiter ;
    OIDCPassUserInfoAs json
EOF
fi

cat << 'EOF'
    
    # OAuth2 Handlers
    <Location /oauth2>
        SetHandler oauth2-handler
    </Location>
    
    <Location /oauth2/callback>
        SetHandler oauth2-handler
    </Location>
EOF

# Add OAuth authentication if enabled
if [ "$ENABLE_OAUTH" = "true" ]; then
    cat << 'EOF'
    
    # OAuth2 Authentication Protection
    <Location />
        AuthType openid-connect
        Require valid-user
        LogLevel debug
    </Location>
    
    # Pass Office 365 user information headers to Emby
    RequestHeader set X-Remote-User %{OIDC_email}e
    RequestHeader set X-Remote-Name %{OIDC_name}e
    RequestHeader set X-Remote-ID %{OIDC_sub}e
    RequestHeader set X-Auth-Method "Office365"
EOF
fi

cat << 'EOF'
    
    # Route all traffic to Emby backend
    ProxyPass "/" "http://@@EMBY_HOST@@:@@EMBY_PORT@@/"
    ProxyPassReverse "/" "http://@@EMBY_HOST@@:@@EMBY_PORT@@/"
</VirtualHost>
EOF
