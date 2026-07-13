#!/bin/bash
# Generate Apache reverse proxy configuration from template based on environment variables

# Source environment variables from config file written by entrypoint
if [ -f /etc/apache2/env.conf ]; then
    source /etc/apache2/env.conf
fi

TEMPLATE_FILE="${1:-/etc/apache2/sites-available/reverse-proxy.conf.template}"
OUTPUT_FILE="${2:-/etc/apache2/sites-available/reverse-proxy.conf}"

# Default values (overridable from env.conf)
DOMAIN="${DOMAIN:-example.com}"
EMAIL="${EMAIL:-admin@example.com}"
SSL_PROTOCOLS="${SSL_PROTOCOLS:-all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1}"
SSL_CIPHERS="${SSL_CIPHERS:-HIGH:!aNULL:!MD5}"

# After sourcing env.conf, process service config files to replace hardcoded URLs
# This converts sonarr:8989 -> the actual SONARR_URL if provided

process_service_config() {
    local service_name=$1
    local service_url_var="${1^^}_URL"  # Convert to uppercase: SONARR_URL
    local service_url="${!service_url_var}"  # Get the variable value
    local template_port="${2:-8989}"  # Default port in template
    local service_file="/etc/apache2/sites-available/services/${service_name}.conf"
    
    if [ -z "$service_url" ]; then
        # No custom URL provided, use default
        return
    fi
    
    # Extract host:port from URL
    service_host_with_port=$(echo "$service_url" | sed 's|^https*://||;s|/.*||')
    
    # Extract host WITHOUT port for cookie domain
    service_host_only=$(echo "$service_url" | sed 's|^https*://||;s|/.*||;s|:.*||')
    
    # Extract the path from the URL (everything after host:port)
    service_path=$(echo "$service_url" | sed 's|^https*://[^/]*||')

    # If no path, default to the service name (except services that proxy to root)
    if [ -z "$service_path" ]; then
        if [ "$service_name" = "deluge" ] || [ "$service_name" = "qbittorrent" ] || [ "$service_name" = "seerr" ] || [ "$service_name" = "nzbget" ] || [ "$service_name" = "jackett" ]; then
            service_path="/"
        else
            service_path="/$service_name"
        fi
    fi

    # Replace ProxyPass URLs, preserving the path
    # Special handling for services that proxy to root (/)
    if [ "$service_name" = "deluge" ] || [ "$service_name" = "qbittorrent" ] || [ "$service_name" = "seerr" ] || [ "$service_name" = "nzbget" ] || [ "$service_name" = "jackett" ]; then
        sed -i "s|http://${service_name}:${template_port}|http://${service_host_with_port}|g" "$service_file"
        sed -i "s|ws://${service_name}:${template_port}|ws://${service_host_with_port}|g" "$service_file"
    else
        sed -i "s|http://[^/]*:${template_port}/[^/]*|http://${service_host_with_port}${service_path}|g" "$service_file"
        sed -i "s|ws://[^/]*:${template_port}/[^/]*|ws://${service_host_with_port}${service_path}|g" "$service_file"
    fi

    # Replace cookie domain ONLY if the line contains ProxyPassReverseCookieDomain
    sed -i "s|\(ProxyPassReverseCookieDomain\) $service_name |\1 $service_host_only |g" "$service_file"

    # Replace DOMAIN placeholder for services that use it (e.g., Seerr)
    sed -i "s|@@DOMAIN@@|$DOMAIN|g" "$service_file"

    echo "Updated $service_name config to use: $service_url"
}

# Process each service if it's enabled
[ "$ENABLE_SONARR" = "true" ] && process_service_config "sonarr" "8989"
[ "$ENABLE_RADARR" = "true" ] && process_service_config "radarr" "7878"
[ "$ENABLE_WHISPARR" = "true" ] && process_service_config "whisparr" "6969"
[ "$ENABLE_LIDARR" = "true" ] && process_service_config "lidarr" "8686"
[ "$ENABLE_PROWLARR" = "true" ] && process_service_config "prowlarr" "9696"
[ "$ENABLE_SEERR" = "true" ] && process_service_config "seerr" "5055"
[ "$ENABLE_JELLYFIN" = "true" ] && process_service_config "jellyfin" "8096"
# Emby and Plex use vhost configs, not service configs - skip here
[ "$ENABLE_TAUTULLI" = "true" ] && process_service_config "tautulli" "8181"
[ "$ENABLE_MAINTAINERR" = "true" ] && process_service_config "maintainerr" "6246"
[ "$ENABLE_TRANSMISSION" = "true" ] && process_service_config "transmission" "9091"
[ "$ENABLE_QBITTORRENT" = "true" ] && process_service_config "qbittorrent" "8080"
[ "$ENABLE_SABNZBD" = "true" ] && process_service_config "sabnzbd" "8080"
[ "$ENABLE_DELUGE" = "true" ] && process_service_config "deluge" "8112"
[ "$ENABLE_NZBGET" = "true" ] && process_service_config "nzbget" "6789"
[ "$ENABLE_NZBHYDRA" = "true" ] && process_service_config "nzbhydra" "5076"
[ "$ENABLE_JACKETT" = "true" ] && process_service_config "jackett" "9117"
[ "$ENABLE_BAZARR" = "true" ] && process_service_config "bazarr" "6767"


# Function to generate include directive (output ONLY the Include line)
generate_include() {
    local service_name=$1
    local enable_flag=$2

    # For Emby, Plex, Seerr: Check if vhost exists (public mode with domain configured)
    # Otherwise use service proxy config (private mode or no domain set)
    if [ "$service_name" = "emby" ]; then
        if [ -f "/etc/apache2/sites-available/emby-vhost.conf" ]; then
            echo "# Emby using vhost ($(basename /etc/apache2/sites-available/emby-vhost.conf))"
            return
        fi
    elif [ "$service_name" = "plex" ]; then
        if [ -f "/etc/apache2/sites-available/plex-vhost.conf" ]; then
            echo "# Plex using vhost ($(basename /etc/apache2/sites-available/plex-vhost.conf))"
            return
        fi
    elif [ "$service_name" = "seerr" ]; then
        # Check for seerr vhost (created when SEERR_DOMAIN is set in public mode)
        if [ -f "/etc/apache2/sites-available/seerr-vhost.conf" ]; then
            echo "# Seerr using vhost ($(basename /etc/apache2/sites-available/seerr-vhost.conf))"
            return
        fi
    fi

    local service_file="/etc/apache2/sites-available/services/${service_name}.conf"

    if [ "$enable_flag" = "true" ] && [ -f "$service_file" ]; then
        echo "Include $service_file"
    fi
}

# Function to generate auth include directive
generate_auth_include() {
    local auth_name=$1
    local enable_flag=$2
    local auth_file="/etc/apache2/conf-available/${auth_name}.conf"
    
    if [ "$enable_flag" = "true" ]; then
        echo "Include $auth_file"
    fi
}

# Generate include directives for each service
SONARR_INCLUDE=$(generate_include "sonarr" "$ENABLE_SONARR")
RADARR_INCLUDE=$(generate_include "radarr" "$ENABLE_RADARR")
WHISPARR_INCLUDE=$(generate_include "whisparr" "$ENABLE_WHISPARR")
LIDARR_INCLUDE=$(generate_include "lidarr" "$ENABLE_LIDARR")
PROWLARR_INCLUDE=$(generate_include "prowlarr" "$ENABLE_PROWLARR")
# Emby, Plex, Seerr use VirtualHost configs only - no service includes
SEERR_INCLUDE=""
JELLYFIN_INCLUDE=$(generate_include "jellyfin" "$ENABLE_JELLYFIN")
EMBY_INCLUDE=""
PLEX_INCLUDE=""
TAUTULLI_INCLUDE=$(generate_include "tautulli" "$ENABLE_TAUTULLI")
MAINTAINERR_INCLUDE=$(generate_include "maintainerr" "$ENABLE_MAINTAINERR")
TRANSMISSION_INCLUDE=$(generate_include "transmission" "$ENABLE_TRANSMISSION")
QBITTORRENT_INCLUDE=$(generate_include "qbittorrent" "$ENABLE_QBITTORRENT")
SABNZBD_INCLUDE=$(generate_include "sabnzbd" "$ENABLE_SABNZBD")
DELUGE_INCLUDE=$(generate_include "deluge" "$ENABLE_DELUGE")
NZBGET_INCLUDE=$(generate_include "nzbget" "$ENABLE_NZBGET")
NZBHYDRA_INCLUDE=$(generate_include "nzbhydra" "$ENABLE_NZBHYDRA")
JACKETT_INCLUDE=$(generate_include "jackett" "$ENABLE_JACKETT")
BAZARR_INCLUDE=$(generate_include "bazarr" "$ENABLE_BAZARR")

# Generate auth includes based on AUTHTYPE (mutually exclusive)
AUTH_ENTRA_INCLUDE=""
AUTH_GOOGLE_INCLUDE=""
BASIC_AUTH_INCLUDE=""
case "$AUTHTYPE" in
    entra)
        AUTH_ENTRA_INCLUDE=$(generate_auth_include "auth-entra-protect" "true")
        ;;
    google)
        AUTH_GOOGLE_INCLUDE=$(generate_auth_include "auth-google-protect" "true")
        ;;
    basic)
        BASIC_AUTH_INCLUDE=$(generate_auth_include "auth-basic" "true")
        ;;
esac

# Generate NZBGet authentication header if credentials provided
if [ -n "$NZBGET_USERNAME" ] && [ -n "$NZBGET_PASSWORD" ]; then
    # Base64 encode the username:password
    AUTH_BASIC=$(echo -n "$NZBGET_USERNAME:$NZBGET_PASSWORD" | base64)
    NZBGET_AUTH_HEADER_LINE="    RequestHeader set Authorization 'Basic $AUTH_BASIC'"
    echo "NZBGet authentication header configured"

    # Update nzbget.conf with auth header
    NZBGET_CONF="/etc/apache2/sites-available/services/nzbget.conf"
    if [ -f "$NZBGET_CONF" ]; then
        sed -i "s|@@NZBGET_AUTH_HEADER@@|$NZBGET_AUTH_HEADER_LINE|g" "$NZBGET_CONF"
    fi
else
    # Use comment placeholder if no credentials provided
    NZBGET_AUTH_HEADER_LINE="    # NZBGet authentication not configured"

    # Update nzbget.conf with comment
    NZBGET_CONF="/etc/apache2/sites-available/services/nzbget.conf"
    if [ -f "$NZBGET_CONF" ]; then
        sed -i "s|@@NZBGET_AUTH_HEADER@@|$NZBGET_AUTH_HEADER_LINE|g" "$NZBGET_CONF"
    fi
fi

# Generate custom backend include if enabled
CUSTOM_BACKEND_INCLUDE=""
if [ "$ENABLE_CUSTOM_BACKEND" = "true" ]; then
    CUSTOM_BACKEND_PATH="${CUSTOM_BACKEND_PATH:-/custom}"
    CUSTOM_BACKEND_URL="${CUSTOM_BACKEND_URL:-http://backend:8080}"
    CUSTOM_BACKEND_INCLUDE="<Location $CUSTOM_BACKEND_PATH>
    ProxyPass $CUSTOM_BACKEND_URL
    ProxyPassReverse $CUSTOM_BACKEND_URL
    ProxyConnectTimeout 30
    ProxyTimeout 300
    ProxyPreserveHost On
    RequestHeader set X-Real-IP %{REMOTE_ADDR}s
    RequestHeader set X-Forwarded-For %{HTTP:X-Forwarded-For}e
    RequestHeader set X-Forwarded-Proto \"https\"
    RequestHeader set X-Forwarded-Host %{HTTP_HOST}e
</Location>"
fi

# Read template file
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Determine landing page based on enabled services
echo ""
echo "=== Setting Landing Page ==="
if [ "$ENABLE_SONARR" = "true" ]; then
    LANDING_PAGE="/sonarr/calendar"
    echo "Landing page: Sonarr Calendar"
elif [ "$ENABLE_RADARR" = "true" ]; then
    LANDING_PAGE="/radarr"
    echo "Landing page: Radarr"
else
    LANDING_PAGE="/index.html"
    echo "Landing page: Menu"
fi

# Generate configuration from template
echo ""
echo "Generating configuration from template..."

CONFIG=$(cat "$TEMPLATE_FILE")

# Replace placeholders
CONFIG="${CONFIG//@@DOMAIN@@/$DOMAIN}"
CONFIG="${CONFIG//@@STYLE@@/$STYLE}"
CONFIG="${CONFIG//@@SSL_PROTOCOLS@@/$SSL_PROTOCOLS}"
CONFIG="${CONFIG//@@SSL_CIPHERS@@/$SSL_CIPHERS}"

# Replace service includes
CONFIG="${CONFIG//@@INCLUDE_SONARR@@/$SONARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_RADARR@@/$RADARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_WHISPARR@@/$WHISPARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_LIDARR@@/$LIDARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_PROWLARR@@/$PROWLARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_SEERR@@/$SEERR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_JELLYFIN@@/$JELLYFIN_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_EMBY@@/$EMBY_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_PLEX@@/$PLEX_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_TAUTULLI@@/$TAUTULLI_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_MAINTAINERR@@/$MAINTAINERR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_TRANSMISSION@@/$TRANSMISSION_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_QBITTORRENT@@/$QBITTORRENT_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_SABNZBD@@/$SABNZBD_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_DELUGE@@/$DELUGE_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_NZBGET@@/$NZBGET_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_NZBHYDRA@@/$NZBHYDRA_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_JACKETT@@/$JACKETT_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_BAZARR@@/$BAZARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_CUSTOM_BACKEND@@/$CUSTOM_BACKEND_INCLUDE}"

# Calculate cookie domain BEFORE OIDC config generation: use root domain for cross-subdomain sharing
# e.g., transfers.limosani.net.au → .limosani.net.au
COOKIE_DOMAIN=".${DOMAIN#*.}"
[ "$COOKIE_DOMAIN" = "." ] && COOKIE_DOMAIN=".$DOMAIN"  # Fallback if no dot in domain

# Replace auth includes
CONFIG="${CONFIG//@@INCLUDE_AUTH_ENTRA@@/$AUTH_ENTRA_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_AUTH_GOOGLE@@/$AUTH_GOOGLE_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_BASIC_AUTH@@/$BASIC_AUTH_INCLUDE}"

# Replace OIDC configuration placeholders for reverse-proxy VirtualHost
case "$AUTHTYPE" in
    google)
        CONFIG="${CONFIG//@@GOOGLE_CLIENT_ID@@/$GOOGLE_CLIENT_ID}"
        CONFIG="${CONFIG//@@GOOGLE_CLIENT_SECRET@@/$GOOGLE_CLIENT_SECRET}"
        CONFIG="${CONFIG//@@GOOGLE_REDIRECT_URI@@/https:\/\/$DOMAIN\/oauth2callback}"
        ;;
    entra)
        # For Entra, replace placeholder config with Entra-specific configuration
        ENTRA_OIDC_CONFIG="    # Entra ID OpenID Connect Configuration
    OIDCSessionType client-cookie:persistent
    OIDCClientID $ENTRA_CLIENT_ID
    OIDCClientSecret $ENTRA_CLIENT_SECRET
    OIDCRedirectURI https://$DOMAIN/oauth2/callback
    OIDCProviderMetadataURL $ENTRA_PROVIDER_METADATA_URL
    OIDCScope \"openid profile email\"
    OIDCSessionInactivityTimeout 3600
    OIDCSessionMaxDuration 86400
    OIDCClaimPrefix OIDC_
    OIDCPassClaimsAs environment
    OIDCCryptoPassphrase \"$ENTRA_CRYPTO_PASSPHRASE\"
    OIDCSSLValidateServer On
    OIDCClaimDelimiter ;
    OIDCPassUserInfoAs json
    OIDCCookieDomain $COOKIE_DOMAIN
    OIDCCookieSameSite None"
        # Replace Google config with Entra config
        GOOGLE_PLACEHOLDER=$(cat << 'EOF'
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
EOF
)
        CONFIG="${CONFIG//$GOOGLE_PLACEHOLDER/$ENTRA_OIDC_CONFIG}"
        ;;
    *)
        # For no auth or basic auth, remove OIDC config
        GOOGLE_PLACEHOLDER=$(cat << 'EOF'
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
EOF
)
        CONFIG="${CONFIG//$GOOGLE_PLACEHOLDER/}"
        ;;
esac

# Replace generic OIDC placeholders for Google (@@COOKIE_DOMAIN@@ already calculated above)
CONFIG="${CONFIG//@@COOKIE_DOMAIN@@/$COOKIE_DOMAIN}"

# Replace DASH_STYLE for DirectoryIndex
DASH_STYLE="${DASH_STYLE:-classic}"
# Strip :only suffix if present for DirectoryIndex filename
DASH_STYLE_BASE="${DASH_STYLE%:only}"
CONFIG="${CONFIG//@@DASH_STYLE@@/$DASH_STYLE_BASE}"

# Replace trusted LAN range for local access bypass
TRUSTED_LAN_RANGE="${TRUSTED_LAN_RANGE:-192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 127.0.0.1}"
CONFIG="${CONFIG//@@TRUSTED_LAN_RANGE@@/$TRUSTED_LAN_RANGE}"

# Generate dynamic service proxy rules with URL substitution
generate_service_proxy_rules() {
    local proxy_rules=""

    # Helper function to add proxy rule
    add_proxy_rule() {
        local path=$1
        local default_url=$2
        local service_name=$(echo "$path" | sed 's|/||g')
        local service_url_var="${service_name^^}_URL"
        local service_url="${!service_url_var:-$default_url}"

        # Extract host:port from URL
        local host_port=$(echo "$service_url" | sed 's|^https*://||;s|/.*||')
        # Extract path from URL
        local url_path=$(echo "$service_url" | sed 's|^https*://[^/]*||')

        # If no path, default based on service type
        # Services that run at root: deluge, qbittorrent, nzbget, jackett, seerr
        if [ -z "$url_path" ]; then
            if [ "$service_name" = "deluge" ] || [ "$service_name" = "qbittorrent" ] || [ "$service_name" = "nzbget" ] || [ "$service_name" = "jackett" ] || [ "$service_name" = "seerr" ]; then
                url_path="/"
            else
                url_path="/$service_name"
            fi
        fi

        proxy_rules+="    ProxyPass $path http://${host_port}${url_path}
    ProxyPassReverse $path http://${host_port}${url_path}
"
    }

    # Only add proxy rules for enabled services
    [ "$ENABLE_SONARR" = "true" ] && add_proxy_rule "/sonarr" "sonarr:8989/sonarr"
    [ "$ENABLE_RADARR" = "true" ] && add_proxy_rule "/radarr" "radarr:7878/radarr"
    [ "$ENABLE_WHISPARR" = "true" ] && add_proxy_rule "/whisparr" "whisparr:6969/whisparr"
    [ "$ENABLE_LIDARR" = "true" ] && add_proxy_rule "/lidarr" "lidarr:8686/lidarr"
    [ "$ENABLE_PROWLARR" = "true" ] && add_proxy_rule "/prowlarr" "prowlarr:9696/prowlarr"
    [ "$ENABLE_JELLYFIN" = "true" ] && add_proxy_rule "/jellyfin" "jellyfin:8096/jellyfin"
    [ "$ENABLE_TAUTULLI" = "true" ] && add_proxy_rule "/tautulli" "tautulli:8181/tautulli"
    [ "$ENABLE_MAINTAINERR" = "true" ] && add_proxy_rule "/maintainerr" "maintainerr:6246/maintainerr"
    [ "$ENABLE_TRANSMISSION" = "true" ] && add_proxy_rule "/transmission" "transmission:9091/transmission"
    [ "$ENABLE_QBITTORRENT" = "true" ] && add_proxy_rule "/qbittorrent" "qbittorrent:8080/qbittorrent"
    [ "$ENABLE_SABNZBD" = "true" ] && add_proxy_rule "/sabnzbd" "sabnzbd:8080/sabnzbd"
    [ "$ENABLE_DELUGE" = "true" ] && add_proxy_rule "/deluge" "deluge:8112/"
    [ "$ENABLE_NZBGET" = "true" ] && add_proxy_rule "/nzbget" "nzbget:6789/"
    [ "$ENABLE_NZBHYDRA" = "true" ] && add_proxy_rule "/nzbhydra" "nzbhydra:5076/nzbhydra"
    [ "$ENABLE_JACKETT" = "true" ] && add_proxy_rule "/jackett" "jackett:9117/"
    [ "$ENABLE_BAZARR" = "true" ] && add_proxy_rule "/bazarr" "bazarr:6767/bazarr"
    [ "$ENABLE_SEERR" = "true" ] && add_proxy_rule "/seerr" "seerr:5055/"

    echo "$proxy_rules"
}

PROXY_RULES=$(generate_service_proxy_rules)
CONFIG="${CONFIG//@@SERVICE_PROXY_RULES@@/$PROXY_RULES}"

# Write output file
echo "$CONFIG" > "$OUTPUT_FILE"

echo "Configuration generated: $OUTPUT_FILE"
echo "=== Configuration Complete ==="
