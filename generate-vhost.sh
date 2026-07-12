#!/bin/bash

# Generate Service VirtualHost Configuration
# Unified script for Emby, Plex, Seerr, and other services requiring subdomains
#
# Usage: generate-vhost.sh <service> <domain> <url> [cert_path] [authtype]
# Example: generate-vhost.sh plex plex.example.com http://plex:32400 plex.example.com entra
#
# Environment Variables (from docker-entrypoint.sh):
#   DOMAIN - Main domain for certificate fallback
#   AUTHTYPE - Authentication type (none, basic, entra, google)
#   SSL_PROTOCOLS - SSL protocol configuration
#   SSL_CIPHERS - SSL cipher configuration

SERVICE="${1:-}"
SERVICE_DOMAIN="${2:-}"
SERVICE_URL="${3:-}"
CERT_PATH="${4:-$DOMAIN}"
AUTHTYPE="${5:-${AUTHTYPE:-none}}"

# Validate inputs
if [ -z "$SERVICE" ] || [ -z "$SERVICE_DOMAIN" ] || [ -z "$SERVICE_URL" ]; then
    echo "ERROR: Usage: $0 <service> <domain> <url> [cert_path] [authtype]"
    echo "Example: $0 plex plex.example.com http://plex:32400"
    exit 1
fi

# Normalize service name to lowercase
SERVICE=$(echo "$SERVICE" | tr '[:upper:]' '[:lower:]')
SERVICE_UPPER=$(echo "$SERVICE" | tr '[:lower:]' '[:upper:]')

# Output configuration file path
VHOST_FILE="/etc/apache2/sites-available/${SERVICE}-vhost.conf"

# Generate the VirtualHost configuration
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

    # Require authentication before proxying
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

# Embed OIDC provider config inside VirtualHost with substitutions
if [ "${AUTHTYPE}" = "google" ]; then
    OIDC_CONFIG=$(cat /etc/apache2/conf-available/oauth2-google.conf \
        | sed "s#@@GOOGLE_CLIENT_ID@@#${GOOGLE_CLIENT_ID}#g" \
        | sed "s#@@GOOGLE_CLIENT_SECRET@@#${GOOGLE_CLIENT_SECRET}#g" \
        | sed "s#@@GOOGLE_REDIRECT_URI@@#https://${SERVICE_DOMAIN}/oauth2callback#g" \
        | sed "s#@@GOOGLE_CRYPTO_PASSPHRASE@@#${GOOGLE_CRYPTO_PASSPHRASE}#g" \
        | sed "s#@@COOKIE_DOMAIN@@#.${SERVICE_DOMAIN#*.}#g")
    sed -i "/<\/VirtualHost>/i\\    # OAuth2 Provider Config\\n${OIDC_CONFIG}" "$VHOST_FILE"
elif [ "${AUTHTYPE}" = "entra" ]; then
    OIDC_CONFIG=$(cat /etc/apache2/conf-available/oauth2-entra.conf \
        | sed "s#@@ENTRA_CLIENT_ID@@#${ENTRA_CLIENT_ID}#g" \
        | sed "s#@@ENTRA_CLIENT_SECRET@@#${ENTRA_CLIENT_SECRET}#g" \
        | sed "s#@@ENTRA_REDIRECT_URI@@#https://${SERVICE_DOMAIN}/oauth2/callback#g" \
        | sed "s#@@ENTRA_PROVIDER_METADATA_URL@@#${ENTRA_PROVIDER_METADATA_URL}#g" \
        | sed "s#@@ENTRA_CRYPTO_PASSPHRASE@@#${ENTRA_CRYPTO_PASSPHRASE}#g" \
        | sed "s#@@COOKIE_DOMAIN@@#.${SERVICE_DOMAIN#*.}#g")
    sed -i "/<\/VirtualHost>/i\\    # OAuth2 Provider Config\\n${OIDC_CONFIG}" "$VHOST_FILE"
fi

# Handle OAuth configuration based on AUTHTYPE
# Service subdomains include both OAuth2 and auth-protect using wildcard pattern
case "${AUTHTYPE}" in
    entra|google|basic)
        # Replace placeholder with wildcard include (matches both oauth2 and protect files)
        # e.g., emby-google-oauth2.conf and emby-google-protect.conf
        sed -i "s|@@INCLUDE_${SERVICE_UPPER}_OAUTH@@|IncludeOptional /etc/apache2/conf-available/${SERVICE}-${AUTHTYPE}*.conf|" "$VHOST_FILE"
        ;;
    none|*)
        # Remove placeholder if no auth
        sed -i "/@@INCLUDE_${SERVICE_UPPER}_OAUTH@@/d" "$VHOST_FILE"
        ;;
esac

# Enable the VirtualHost site
a2ensite "${SERVICE}-vhost.conf" 2>/dev/null || true
echo "✓ $SERVICE VirtualHost enabled"

