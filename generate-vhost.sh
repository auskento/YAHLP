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
    OIDCSessionType client-cookie:persistent
    OIDCClientID @@GOOGLE_CLIENT_ID@@
    OIDCClientSecret @@GOOGLE_CLIENT_SECRET@@
    OIDCRedirectURI @@GOOGLE_REDIRECT_URI@@
    OIDCProviderMetadataURL https://accounts.google.com/.well-known/openid-configuration
    OIDCScope "openid profile email"
    OIDCSessionInactivityTimeout 3600
    OIDCSessionMaxDuration 86400
    OIDCClaimPrefix OIDC_
    OIDCPassClaimsAs environment
    OIDCSSLValidateServer On
    OIDCClaimDelimiter ;
    OIDCPassUserInfoAs json
    OIDCCookieDomain @@COOKIE_DOMAIN@@
    OIDCCookieSameSite None
OIDC_EOF
)
    # Substitute placeholders using sed with # delimiter (safer for special chars)
    ESCAPED_PASS=$(echo "$GOOGLE_CRYPTO_PASSPHRASE" | sed 's/#/\\#/g')
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@GOOGLE_CLIENT_ID@@#$GOOGLE_CLIENT_ID#g")
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@GOOGLE_CLIENT_SECRET@@#$GOOGLE_CLIENT_SECRET#g")
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@GOOGLE_REDIRECT_URI@@#https://$SERVICE_DOMAIN$OAUTH_CALLBACK_PATH#g")
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@GOOGLE_CRYPTO_PASSPHRASE@@#$ESCAPED_PASS#g")
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@COOKIE_DOMAIN@@#$COOKIE_DOMAIN#g")

elif [ "$AUTHTYPE" = "entra" ]; then
    OIDC_CONFIG=$(cat <<'OIDC_EOF'
    # Entra ID OpenID Connect Configuration
    OIDCSessionType client-cookie:persistent
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
    # Substitute placeholders using sed with # delimiter (safer for special chars)
    ESCAPED_PASS=$(echo "$ENTRA_CRYPTO_PASSPHRASE" | sed 's/#/\\#/g')
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@ENTRA_CLIENT_ID@@#$ENTRA_CLIENT_ID#g")
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@ENTRA_CLIENT_SECRET@@#$ENTRA_CLIENT_SECRET#g")
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@ENTRA_REDIRECT_URI@@#https://$SERVICE_DOMAIN$OAUTH_CALLBACK_PATH#g")
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@ENTRA_PROVIDER_METADATA_URL@@#$ENTRA_PROVIDER_METADATA_URL#g")
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@ENTRA_CRYPTO_PASSPHRASE@@#$ESCAPED_PASS#g")
    OIDC_CONFIG=$(echo "$OIDC_CONFIG" | sed "s#@@COOKIE_DOMAIN@@#$COOKIE_DOMAIN#g")
fi

# Get TRUSTED_LAN_RANGE from environment or use defaults
TRUSTED_LAN_RANGE="${TRUSTED_LAN_RANGE:-192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 127.0.0.1}"

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
        <RequireAny>
            Require ip $TRUSTED_LAN_RANGE
            Require valid-user
        </RequireAny>
    </Proxy>

    ProxyTimeout 300
    Timeout 300

    # Use ProxyPassMatch to exclude oauth paths from proxying
    # This allows Location blocks to handle auth before proxying
    ProxyPassMatch ^/oauth2 !
    ProxyPassMatch ^/oauth2callback !
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

# Enable the configuration
a2enconf "${SERVICE}-vhost" 2>/dev/null || true
echo "✓ $SERVICE VirtualHost config enabled"
