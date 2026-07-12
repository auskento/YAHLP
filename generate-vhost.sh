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

    # OAuth/Auth Configuration
    @@INCLUDE_${SERVICE_UPPER}_OAUTH@@

    # Root location - require authentication
    <Location /oauth2callback>
        SetHandler oauth2-handler
    </Location>

    <Location />
        AuthType openid-connect
        Require valid-user
    </Location>

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
