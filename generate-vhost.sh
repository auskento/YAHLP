#!/bin/bash

# Generate Service VirtualHost Configuration with embedded OIDC settings
# Usage: generate-vhost.sh <service> <domain> <url> [cert_path] [authtype]

SERVICE="${1:-}"
SERVICE_DOMAIN="${2:-}"
SERVICE_URL="${3:-}"
CERT_PATH="${4:-$DOMAIN}"
AUTHTYPE="${5:-${AUTHTYPE:-none}}"

# Validate inputs
if [ -z "$SERVICE" ] || [ -z "$SERVICE_DOMAIN" ] || [ -z "$SERVICE_URL" ]; then
    echo "ERROR: Usage: $0 <service> <domain> <url> [cert_path] [authtype]"
    exit 1
fi

SERVICE=$(echo "$SERVICE" | tr '[:upper:]' '[:lower:]')
VHOST_FILE="/etc/apache2/sites-available/${SERVICE}-vhost.conf"

# Calculate cookie domain (e.g., emby.example.com → .example.com)
COOKIE_DOMAIN=".${SERVICE_DOMAIN#*.}"

# Determine OAuth callback path based on auth type
OAUTH_CALLBACK_PATH="/oauth2callback"
if [ "$AUTHTYPE" = "entra" ]; then
    OAUTH_CALLBACK_PATH="/oauth2/callback"
fi

# Build OIDC configuration based on AUTHTYPE
OIDC_CONFIG=""
if [ "$AUTHTYPE" = "google" ]; then
    OIDC_CONFIG=$(cat <<'OIDC_EOF'
    # Google OpenID Connect Configuration
    OIDCSessionType server-cache
    OIDCClientID @@GOOGLE_CLIENT_ID@@
    OIDCClientSecret @@GOOGLE_CLIENT_SECRET@@
    OIDCRedirectURI @@GOOGLE_REDIRECT_URI@@
    OIDCProviderMetadataURL https://accounts.google.com/.well-known/openid-configuration
    OIDCScope "openid profile email"
    OIDCSessionInactivityTimeout 3600
    OIDCSessionMaxDuration 86400
    OIDCClaimPrefix OIDC_
    OIDCPassClaimsAs environment
    OIDCCryptoPassphrase "@@GOOGLE_CRYPTO_PASSPHRASE@@"
    OIDCSSLValidateServer On
    OIDCClaimDelimiter ;
    OIDCPassUserInfoAs json
    OIDCCookieDomain @@COOKIE_DOMAIN@@
    OIDCCookieSameSite None
OIDC_EOF
)
    # Substitute placeholders
    OIDC_CONFIG="${OIDC_CONFIG//@@GOOGLE_CLIENT_ID@@/$GOOGLE_CLIENT_ID}"
    OIDC_CONFIG="${OIDC_CONFIG//@@GOOGLE_CLIENT_SECRET@@/$GOOGLE_CLIENT_SECRET}"
    OIDC_CONFIG="${OIDC_CONFIG//@@GOOGLE_REDIRECT_URI@@/https://$SERVICE_DOMAIN$OAUTH_CALLBACK_PATH}"
    OIDC_CONFIG="${OIDC_CONFIG//@@GOOGLE_CRYPTO_PASSPHRASE@@/$GOOGLE_CRYPTO_PASSPHRASE}"
    OIDC_CONFIG="${OIDC_CONFIG//@@COOKIE_DOMAIN@@/$COOKIE_DOMAIN}"

elif [ "$AUTHTYPE" = "entra" ]; then
    OIDC_CONFIG=$(cat <<'OIDC_EOF'
    # Entra ID OpenID Connect Configuration
    OIDCSessionType server-cache
    OIDCClientID @@ENTRA_CLIENT_ID@@
    OIDCClientSecret @@ENTRA_CLIENT_SECRET@@
    OIDCRedirectURI @@ENTRA_REDIRECT_URI@@
    OIDCProviderMetadataURL @@ENTRA_PROVIDER_METADATA_URL@@
    OIDCScope "openid profile email"
    OIDCSessionInactivityTimeout 3600
    OIDCSessionMaxDuration 86400
    OIDCClaimPrefix OIDC_
    OIDCPassClaimsAs environment
    OIDCCryptoPassphrase "@@ENTRA_CRYPTO_PASSPHRASE@@"
    OIDCSSLValidateServer On
    OIDCClaimDelimiter ;
    OIDCPassUserInfoAs json
    OIDCCookieDomain @@COOKIE_DOMAIN@@
    OIDCCookieSameSite None
OIDC_EOF
)
    # Substitute placeholders
    OIDC_CONFIG="${OIDC_CONFIG//@@ENTRA_CLIENT_ID@@/$ENTRA_CLIENT_ID}"
    OIDC_CONFIG="${OIDC_CONFIG//@@ENTRA_CLIENT_SECRET@@/$ENTRA_CLIENT_SECRET}"
    OIDC_CONFIG="${OIDC_CONFIG//@@ENTRA_REDIRECT_URI@@/https://$SERVICE_DOMAIN$OAUTH_CALLBACK_PATH}"
    OIDC_CONFIG="${OIDC_CONFIG//@@ENTRA_PROVIDER_METADATA_URL@@/$ENTRA_PROVIDER_METADATA_URL}"
    OIDC_CONFIG="${OIDC_CONFIG//@@ENTRA_CRYPTO_PASSPHRASE@@/$ENTRA_CRYPTO_PASSPHRASE}"
    OIDC_CONFIG="${OIDC_CONFIG//@@COOKIE_DOMAIN@@/$COOKIE_DOMAIN}"
fi

# Generate the VirtualHost configuration with embedded OIDC settings
cat > "$VHOST_FILE" <<EOF
<VirtualHost *:80>
    ServerName $SERVICE_DOMAIN
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    DocumentRoot /var/www/letsencrypt
    <Directory /var/www/letsencrypt>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:443>
    ServerName $SERVICE_DOMAIN

$OIDC_CONFIG

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$CERT_PATH/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$CERT_PATH/privkey.pem
    SSLProtocol ${SSL_PROTOCOLS:-all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1}
    SSLCipherSuite ${SSL_CIPHERS:-HIGH:!aNULL:!MD5}
    SSLHonorCipherOrder on

    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"

    <Location /oauth2callback>
        SetHandler oauth2-handler
    </Location>

    <Location /oauth2>
        SetHandler oauth2-handler
    </Location>

    <LocationMatch "^/(?!oauth2)">
        AuthType openid-connect
        Require valid-user
    </LocationMatch>

    ProxyRequests Off
    ProxyPreserveHost On
    ProxyVia Off

    <Proxy *>
        Order deny,allow
        Allow from all
        Satisfy Any
    </Proxy>

    ProxyTimeout 300
    Timeout 300

    ProxyPass / $SERVICE_URL/
    ProxyPassReverse / $SERVICE_URL/

    ErrorDocument 502 /error-pages/502.html
    ErrorDocument 503 /error-pages/503.html

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    LogLevel warn
</VirtualHost>
EOF

echo "✓ Generated $SERVICE VirtualHost config: $VHOST_FILE"

# Enable the VirtualHost site
a2ensite "${SERVICE}-vhost.conf" 2>/dev/null || true
echo "✓ $SERVICE VirtualHost enabled"
