#!/bin/bash
set -e

# Ensure config folder exists (required for all deployments)
if [ ! -d /etc/yahlp ]; then
    echo "ERROR: Config folder not mounted to /etc/yahlp"
    echo "Docker must mount config folder: -v ./config:/etc/yahlp"
    exit 1
fi

# Fix permissions on mounted config folder for non-root execution
chown ${PUID:-0}:${PGID:-0} /etc/yahlp
chmod 775 /etc/yahlp

# Setup SSL certificate folder in config
# Certs folder needs write access from both root (certbot) and web server (PUID user)
mkdir -p /etc/yahlp/certs || {
    echo "ERROR: Failed to create /etc/yahlp/certs directory"
    exit 1
}
chmod -R 777 /etc/yahlp/certs || {
    echo "ERROR: Failed to set permissions on /etc/yahlp/certs"
    exit 1
}

# Pre-create certbot directory structure with full permissions
mkdir -p /etc/yahlp/certs/live /etc/yahlp/certs/archive /etc/yahlp/certs/renewal
chmod -R 777 /etc/yahlp/certs/live /etc/yahlp/certs/archive /etc/yahlp/certs/renewal

# Create symlink from /etc/letsencrypt to /etc/yahlp/certs for certbot compatibility
if [ ! -L /etc/letsencrypt ] && [ ! -d /etc/letsencrypt ]; then
    ln -s /etc/yahlp/certs /etc/letsencrypt
    echo "✓ Created symlink: /etc/letsencrypt → /etc/yahlp/certs"
elif [ -d /etc/letsencrypt ] && [ ! -L /etc/letsencrypt ]; then
    echo "Removing /etc/letsencrypt directory to create symlink..."
    rm -rf /etc/letsencrypt
    ln -s /etc/yahlp/certs /etc/letsencrypt
    echo "✓ Replaced /etc/letsencrypt with symlink → /etc/yahlp/certs"
fi

# Verify symlink
if [ -L /etc/letsencrypt ]; then
    LINK_TARGET=$(readlink /etc/letsencrypt)
    echo "✓ /etc/letsencrypt symlink verified → $LINK_TARGET"
else
    echo "ERROR: /etc/letsencrypt is not a symlink!"
    exit 1
fi

# Setup logs folder in config directory (Apache needs write access)
mkdir -p /etc/yahlp/logs || {
    echo "ERROR: Failed to create /etc/yahlp/logs directory"
    exit 1
}
chown -R ${PUID:-0}:${PGID:-0} /etc/yahlp/logs
chmod -R 775 /etc/yahlp/logs || {
    echo "ERROR: Failed to set permissions on /etc/yahlp/logs"
    exit 1
}

# Create symlink from /var/log/apache2 to /etc/yahlp/logs for Apache compatibility
if [ ! -L /var/log/apache2 ] && [ ! -d /var/log/apache2 ]; then
    ln -s /etc/yahlp/logs /var/log/apache2
    echo "✓ Created symlink: /var/log/apache2 → /etc/yahlp/logs"
elif [ -d /var/log/apache2 ] && [ ! -L /var/log/apache2 ]; then
    echo "WARNING: /var/log/apache2 exists as a real directory"
    echo "  Removing to create symlink to /etc/yahlp/logs"
    rm -rf /var/log/apache2
    ln -s /etc/yahlp/logs /var/log/apache2
    echo "✓ Created symlink: /var/log/apache2 → /etc/yahlp/logs"
fi

# Ensure sites directory exists in logs folder
mkdir -p /etc/yahlp/logs/sites || {
    echo "ERROR: Failed to create /etc/yahlp/logs/sites directory"
    exit 1
}
chown -R ${PUID:-0}:${PGID:-0} /etc/yahlp/logs/sites
chmod -R 775 /etc/yahlp/logs/sites || {
    echo "ERROR: Failed to set permissions on /etc/yahlp/logs/sites"
    exit 1
}

# Setup service icons folder and copy bundled icons
mkdir -p /etc/yahlp/service_icons || {
    echo "ERROR: Failed to create /etc/yahlp/service_icons directory"
    exit 1
}
cp -r /var/www/html/icons/* /etc/yahlp/service_icons/ 2>/dev/null || true
chown -R ${PUID:-0}:${PGID:-0} /etc/yahlp/service_icons
chmod 775 /etc/yahlp/service_icons
echo "✓ Service icons folder created: /etc/yahlp/service_icons"

# Setup site icons folder and copy bundled icons
mkdir -p /etc/yahlp/site_icons || {
    echo "ERROR: Failed to create /etc/yahlp/site_icons directory"
    exit 1
}
cp -r /var/www/html/sites-icons/* /etc/yahlp/site_icons/ 2>/dev/null || true
chown -R ${PUID:-0}:${PGID:-0} /etc/yahlp/site_icons
chmod 775 /etc/yahlp/site_icons
echo "✓ Site icons folder created: /etc/yahlp/site_icons"

# Copy icon configuration guide to config folder
cp /app/ICON_CONFIGURATION.md /etc/yahlp/ICON_CONFIGURATION.md 2>/dev/null || true
chmod 644 /etc/yahlp/ICON_CONFIGURATION.md 2>/dev/null || true
echo "✓ Icon configuration guide available: /etc/yahlp/ICON_CONFIGURATION.md"

# Configuration loading:
# 1. If yahlp.json5 is provided (mounted), convert it to environment variables
# 2. These become the defaults for the entire startup process
# 3. Any -e environment variables passed to Docker override these defaults
# 4. If no yahlp.json5, use environment variables only

echo "=== Configuration Loading ==="

# Generate example yahlp.json5 on first run if it doesn't exist
if [ ! -f /etc/yahlp/yahlp.json5 ]; then
    echo "Creating example yahlp.json5 configuration file..."
    # Use environment variables if provided, otherwise use defaults
    JSON_DOMAIN="${DOMAIN:-yourdomain.com}"
    JSON_EMAIL="${EMAIL:-admin@yourdomain.com}"
    JSON_ACCESS_MODE="${ACCESS_MODE:-public}"
    JSON_AUTHTYPE="${AUTHTYPE:-none}"

    # Detect enabled services from environment variables
    SERVICES_ENABLED_JSON=""
    SERVICES_URL_JSON=""
    SERVICES="sabnzbd nzbget nzbhydra transmission qbittorrent deluge sonarr radarr lidarr whisparr prowlarr jackett seerr bazarr jellyfin emby plex tautulli maintainerr"

    for service in $SERVICES; do
        SERVICE_UPPER=$(echo "$service" | tr '[:lower:]' '[:upper:]')
        SERVICE_ENABLED_VAR="${SERVICE_UPPER}_ENABLED"
        SERVICE_URL_VAR="${SERVICE_UPPER}_URL"

        eval "SERVICE_ENABLED=\$$SERVICE_ENABLED_VAR"
        eval "SERVICE_URL=\$$SERVICE_URL_VAR"

        # Add to enabled section
        if [ ! -z "$SERVICES_ENABLED_JSON" ]; then
            SERVICES_ENABLED_JSON="${SERVICES_ENABLED_JSON},"$'\n'
        fi
        SERVICES_ENABLED_JSON="${SERVICES_ENABLED_JSON}    ${service}: $([ "$SERVICE_ENABLED" = "true" ] && echo "true" || echo "false")"

        # Add to URL section if service URL is set
        if [ ! -z "$SERVICE_URL" ]; then
            if [ ! -z "$SERVICES_URL_JSON" ]; then
                SERVICES_URL_JSON="${SERVICES_URL_JSON},"$'\n'
            fi
            SERVICES_URL_JSON="${SERVICES_URL_JSON}    ${service}: '${SERVICE_URL}'"
        fi
    done

    # Use defaults if no services detected
    if [ -z "$SERVICES_ENABLED_JSON" ]; then
        SERVICES_ENABLED_JSON="    jellyfin: true,"$'\n'"    plex: false,"$'\n'"    emby: false,"$'\n'"    sonarr: false,"$'\n'"    radarr: false"
    fi
    if [ -z "$SERVICES_URL_JSON" ]; then
        SERVICES_URL_JSON="    jellyfin: 'http://jellyfin:8096',"$'\n'"    plex: 'http://plex:32400'"
    fi

    cat > /etc/yahlp/yahlp.json5 << JSONEOF
// YAHLP Configuration (JSON5 format)
// Edit this file to configure services with API keys, icons, and optional settings
// Environment variables (-e) override these settings

{
  access: {
    mode: '${JSON_ACCESS_MODE}',      // 'public' or 'private'
    type: '${JSON_AUTHTYPE}',        // 'none', 'basic', 'google', 'entra'
  },

  domain: '${JSON_DOMAIN}',
  email: '${JSON_EMAIL}',

  dashboard: {
    name: 'YAHLP',
    style: 'modern',     // 'classic', 'modern', 'sleek', 'minimal'
    color: '#00A99D',
    landing: '',
    order: 'SAB,GET,HYD,TRA,QBI,DEL,PRO,JAC,SON,RAD,LID,WHI,SEE,BAZ,TAU,MNT,JEL,PLX,EMB',
  },

  // Enable/disable services
  enabled: {
${SERVICES_ENABLED_JSON}
  },

  // Service URLs (can also be set via SERVICENAME_URL environment variables)
  url: {
${SERVICES_URL_JSON}
  },

  // API Keys (must be set here or via SERVICENAME_API_KEY environment variables)
  api_key: {
    sonarr: '',
    radarr: '',
    lidarr: '',
    whisparr: '',
    prowlarr: '',
    jackett: '',
    seerr: '',
    bazarr: '',
    jellyfin: '',
    emby: '',
    plex: '',
    tautulli: '',
    maintainerr: '',
    qbittorrent: '',
    sabnzbd: '',
    nzbhydra: '',
  },

  // Usernames for services that require them
  username: {
    nzbget: '',
  },

  // Passwords for services that require them
  password: {
    nzbget: '',
    transmission: '',
    deluge: '',
  },

  // Landing pages for services
  landing: {
    sonarr: '',
    radarr: '',
    whisparr: '',
  },

  // Custom internal websites
  sites: [
    // { name: 'Router', url: 'http://192.168.1.1' },
  ],
}
JSONEOF
    chmod 644 /etc/yahlp/yahlp.json5
    echo "✓ Created /etc/yahlp/yahlp.json5 - edit this file to configure services"
fi

echo ""
echo "Checking for /etc/yahlp/yahlp.json5..."

if [ -f /etc/yahlp/yahlp.json5 ]; then
    echo "✓ yahlp.json5 found ($(wc -c < /etc/yahlp/yahlp.json5) bytes)"
    echo "Converting to environment variables..."

    # Convert yahlp.json5 to environment variables using a temp file
    JSON5_ENV_FILE="/tmp/yahlp.env"

    # Run the script and capture output
    if node /usr/local/bin/json5-to-env.js > "$JSON5_ENV_FILE" 2>&1; then
        EXPORT_COUNT=$(grep -c '^export' "$JSON5_ENV_FILE" 2>/dev/null || echo 0)

        if [ "$EXPORT_COUNT" -gt 0 ]; then
            echo "✓ Script generated $EXPORT_COUNT export statements"
            echo "Sample exports:"
            head -5 "$JSON5_ENV_FILE" | sed 's/^/  /'

            # Source the exports
            set -a
            source "$JSON5_ENV_FILE"
            set +a
            echo "✓ Sourced environment variables from yahlp.json5"
        else
            echo "⚠ Script ran but generated no export statements"
            echo "Full output:"
            cat "$JSON5_ENV_FILE" | sed 's/^/  /'
        fi
        rm -f "$JSON5_ENV_FILE"
    else
        echo "✗ json5-to-env.js failed:"
        cat "$JSON5_ENV_FILE" | sed 's/^/  /'
        rm -f "$JSON5_ENV_FILE"
        exit 1
    fi
else
    echo "ℹ /etc/yahlp/yahlp.json5 not found"
    echo "  If using yahlp.json5, mount it to /etc/yahlp/yahlp.json5:ro"
    echo "  Otherwise, configure services via -e environment variables"
fi
echo ""

# Load persistent dashboard configuration if it exists (legacy support)
# This allows changing UI style and landing page without rebuilding the image
if [ -f /etc/apache2/dashboard.conf ]; then
    echo "Loading persistent dashboard configuration..."
    source /etc/apache2/dashboard.conf
fi

# Load env.local/env file for additional overrides (if it exists)
if [ -f /etc/yahlp/env.local ]; then
    echo "Loading additional overrides from env.local..."
    set -a
    source /etc/yahlp/env.local
    set +a
elif [ -f /etc/yahlp/.env.local ]; then
    echo "Loading additional overrides from .env.local..."
    set -a
    source /etc/yahlp/.env.local
    set +a
fi

# Determine deployment mode early to clear DOMAIN/EMAIL before writing env.conf
# EXCEPTION: Keep DOMAIN if using OAuth (Entra/Google) since they require it for redirect URIs
if [ "$ACCESS_MODE" = "private" ]; then
    if [ "$AUTHTYPE" != "entra" ] && [ "$AUTHTYPE" != "google" ]; then
        DOMAIN=""
    fi
    EMAIL=""
fi

# Detect LAN IP range dynamically if TRUSTED_LAN_RANGE not explicitly set
if [ -z "$TRUSTED_LAN_RANGE" ]; then
    # Get container's primary IP address
    CONTAINER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null)

    if [ ! -z "$CONTAINER_IP" ]; then
        # Calculate /24 subnet by replacing last octet with 0
        SUBNET=$(echo "$CONTAINER_IP" | sed 's/\([0-9]*\.[0-9]*\.[0-9]*\)\.[0-9]*/\1.0/')
        TRUSTED_LAN_RANGE="${SUBNET}/24 127.0.0.1"
        echo "✓ Detected LAN IP: $CONTAINER_IP"
        echo "✓ Detected LAN subnet: ${SUBNET}/24"
    else
        # Fallback to common private ranges if IP detection fails
        TRUSTED_LAN_RANGE="192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 127.0.0.1"
        echo "⚠ Could not detect container IP, using default private ranges"
    fi

    echo "✓ Trusted LAN range: $TRUSTED_LAN_RANGE"
fi

# Map {SERVICE}_ENABLED variables to ENABLE_{SERVICE} format for backward compatibility with scripts
# Convert SERVICE_ENABLED to ENABLE_SERVICE (new format to old format for legacy scripts)
ENABLE_JELLYFIN="${JELLYFIN_ENABLED:-false}"
ENABLE_PLEX="${PLEX_ENABLED:-false}"
ENABLE_EMBY="${EMBY_ENABLED:-false}"
ENABLE_SONARR="${SONARR_ENABLED:-false}"
ENABLE_RADARR="${RADARR_ENABLED:-false}"
ENABLE_LIDARR="${LIDARR_ENABLED:-false}"
ENABLE_WHISPARR="${WHISPARR_ENABLED:-false}"
ENABLE_QBITTORRENT="${QBITTORRENT_ENABLED:-false}"
ENABLE_TRANSMISSION="${TRANSMISSION_ENABLED:-false}"
ENABLE_SABNZBD="${SABNZBD_ENABLED:-false}"
ENABLE_NZBGET="${NZBGET_ENABLED:-false}"
ENABLE_DELUGE="${DELUGE_ENABLED:-false}"
ENABLE_NZBHYDRA="${NZBHYDRA_ENABLED:-false}"
ENABLE_JACKETT="${JACKETT_ENABLED:-false}"
ENABLE_PROWLARR="${PROWLARR_ENABLED:-false}"
ENABLE_SEERR="${SEERR_ENABLED:-false}"
ENABLE_BAZARR="${BAZARR_ENABLED:-false}"
ENABLE_TAUTULLI="${TAUTULLI_ENABLED:-false}"
ENABLE_MAINTAINERR="${MAINTAINERR_ENABLED:-false}"

# Write environment variables to config file for scripts to source
# Note: DOMAIN and EMAIL are cleared for private mode before this step

cat > /etc/apache2/env.conf << ENVEOF
ACCESS_MODE="${ACCESS_MODE:-public}"
DOMAIN="${DOMAIN}"
EMAIL="${EMAIL}"
PLEX_DOMAIN="${PLEX_DOMAIN:-}"
EMBY_DOMAIN="${EMBY_DOMAIN:-}"
SEERR_DOMAIN="${SEERR_DOMAIN:-}"
DASH_STYLE="${DASH_STYLE:-classic}"
DASHBOARD_THEME="${DASHBOARD_THEME:-dark}"
DASHBOARD_WINDOWS="${DASHBOARD_WINDOWS:-popout}"
ENABLE_SONARR="${ENABLE_SONARR}"
ENABLE_RADARR="${ENABLE_RADARR}"
ENABLE_WHISPARR="${ENABLE_WHISPARR}"
ENABLE_LIDARR="${ENABLE_LIDARR}"
ENABLE_PROWLARR="${ENABLE_PROWLARR}"
ENABLE_SEERR="${ENABLE_SEERR}"
ENABLE_JELLYFIN="${ENABLE_JELLYFIN}"
ENABLE_EMBY="${ENABLE_EMBY}"
ENABLE_PLEX="${ENABLE_PLEX}"
ENABLE_TAUTULLI="${ENABLE_TAUTULLI}"
ENABLE_MAINTAINERR="${ENABLE_MAINTAINERR}"
ENABLE_TRANSMISSION="${ENABLE_TRANSMISSION}"
ENABLE_QBITTORRENT="${ENABLE_QBITTORRENT}"
ENABLE_SABNZBD="${ENABLE_SABNZBD}"
ENABLE_DELUGE="${ENABLE_DELUGE}"
ENABLE_NZBGET="${ENABLE_NZBGET}"
ENABLE_NZBHYDRA="${ENABLE_NZBHYDRA}"
ENABLE_JACKETT="${ENABLE_JACKETT}"
ENABLE_BAZARR="${ENABLE_BAZARR}"
AUTHTYPE="${AUTHTYPE:-none}"
BASIC_AUTH_CREDENTIALS="${BASIC_AUTH_CREDENTIALS:-}"
ENTRA_CLIENT_ID="${ENTRA_CLIENT_ID:-}"
ENTRA_CLIENT_SECRET="${ENTRA_CLIENT_SECRET:-}"
ENTRA_PROVIDER_METADATA_URL="${ENTRA_PROVIDER_METADATA_URL:-}"
ENTRA_CRYPTO_PASSPHRASE="${ENTRA_CRYPTO_PASSPHRASE:-}"
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}"
GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-}"
SONARR_URL="${SONARR_URL:-}"
RADARR_URL="${RADARR_URL:-}"
WHISPARR_URL="${WHISPARR_URL:-}"
LIDARR_URL="${LIDARR_URL:-}"
PROWLARR_URL="${PROWLARR_URL:-}"
SEERR_URL="${SEERR_URL:-}"
JELLYFIN_URL="${JELLYFIN_URL:-}"
JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-}"
EMBY_URL="${EMBY_URL:-}"
EMBY_API_KEY="${EMBY_API_KEY:-}"
PLEX_URL="${PLEX_URL:-}"
PLEX_API_KEY="${PLEX_API_KEY:-}"
SONARR_API_KEY="${SONARR_API_KEY:-}"
RADARR_API_KEY="${RADARR_API_KEY:-}"
LIDARR_API_KEY="${LIDARR_API_KEY:-}"
WHISPARR_API_KEY="${WHISPARR_API_KEY:-}"
TAUTULLI_URL="${TAUTULLI_URL:-}"
TAUTULLI_API_KEY="${TAUTULLI_API_KEY:-}"
MAINTAINERR_URL="${MAINTAINERR_URL:-}"
MAINTAINERR_API_KEY="${MAINTAINERR_API_KEY:-}"
TRANSMISSION_URL="${TRANSMISSION_URL:-}"
QBITTORRENT_URL="${QBITTORRENT_URL:-}"
QBITTORRENT_API_KEY="${QBITTORRENT_API_KEY:-}"
SABNZBD_URL="${SABNZBD_URL:-}"
SABNZBD_API_KEY="${SABNZBD_API_KEY:-}"
DELUGE_URL="${DELUGE_URL:-}"
DELUGE_PASSWORD="${DELUGE_PASSWORD:-}"
NZBGET_URL="${NZBGET_URL:-}"
NZBGET_USERNAME="${NZBGET_USERNAME:-}"
NZBGET_PASSWORD="${NZBGET_PASSWORD:-}"
NZBHYDRA_URL="${NZBHYDRA_URL:-}"
NZBHYDRA_API_KEY="${NZBHYDRA_API_KEY:-}"
JACKETT_URL="${JACKETT_URL:-}"
JACKETT_API_KEY="${JACKETT_API_KEY:-}"
PROWLARR_URL="${PROWLARR_URL:-}"
PROWLARR_API_KEY="${PROWLARR_API_KEY:-}"
SEERR_URL="${SEERR_URL:-}"
SEERR_API_KEY="${SEERR_API_KEY:-}"
BAZARR_URL="${BAZARR_URL:-}"
BAZARR_API_KEY="${BAZARR_API_KEY:-}"
DASHBOARD_NAME="${DASHBOARD_NAME:-YAHLP}"
DASHBOARD_ICON_URL="${DASHBOARD_ICON_URL:-}"
DASHBOARD_COLOR="${DASHBOARD_COLOR:-#1a1a1a}"
DASHBOARD_LANDING="${DASHBOARD_LANDING:-}"
SONARR_LANDING="${SONARR_LANDING:-sonarr}"
RADARR_LANDING="${RADARR_LANDING:-radarr}"
WHISPARR_LANDING="${WHISPARR_LANDING:-whisparr}"
LIDARR_LANDING="${LIDARR_LANDING:-lidarr}"
# DASHBOARD_ORDER lists services in preferred order (e.g., "SON,RAD,JEL,PLX,SAB,TRA")
# Available: SON, RAD, LID, WHI, PRO, JAC, SEE, BAZ, TAU, MNT, JEL, PLX, EMB, SAB, GET, HYD, TRA, QBI, DEL
DASHBOARD_ORDER="${DASHBOARD_ORDER:-}"
DASHBOARD_SITES="${DASHBOARD_SITES:-}"
SSL_PROTOCOLS="${SSL_PROTOCOLS:-all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1}"
SSL_CIPHERS="${SSL_CIPHERS:-HIGH:!aNULL:!MD5}"
APACHE_LOG_LEVEL="${APACHE_LOG_LEVEL:-warn}"
DASHBOARD_TEST="${DASHBOARD_TEST:-false}"
TRUSTED_LAN_RANGE="${TRUSTED_LAN_RANGE}"
ENVEOF

# Now normalize and process variables that were in env.conf
# This must happen AFTER the heredoc so we can execute shell logic
ACCESS_MODE=$(echo "$ACCESS_MODE" | tr '[:upper:]' '[:lower:]')
AUTHTYPE=$(echo "$AUTHTYPE" | tr '[:upper:]' '[:lower:]')
DASHBOARD_TEST=$(echo "$DASHBOARD_TEST" | tr '[:upper:]' '[:lower:]')
SKIP_CERT_GENERATION=$(echo "$SKIP_CERT_GENERATION" | tr '[:upper:]' '[:lower:]')

# Auto-generate OAuth redirect URIs (Entra/Google only work with public access)
# OAuth always uses HTTPS regardless of ACCESS_MODE, since it requires public domain
ENTRA_REDIRECT_URI="https://${DOMAIN}/oauth2/callback"
GOOGLE_REDIRECT_URI="https://${DOMAIN}/oauth2callback"

# Auto-generate service-specific redirect URIs if service domains are configured (always HTTPS)
# Entra uses /oauth2/callback, Google uses /oauth2callback
OAUTH_PATH="/oauth2callback"
if [ "$AUTHTYPE" = "entra" ]; then
    OAUTH_PATH="/oauth2/callback"
fi

if [ ! -z "$SEERR_DOMAIN" ]; then
    SEERR_REDIRECT_URI="https://${SEERR_DOMAIN}${OAUTH_PATH}"
fi
if [ ! -z "$PLEX_DOMAIN" ]; then
    PLEX_REDIRECT_URI="https://${PLEX_DOMAIN}${OAUTH_PATH}"
fi
if [ ! -z "$EMBY_DOMAIN" ]; then
    EMBY_REDIRECT_URI="https://${EMBY_DOMAIN}${OAUTH_PATH}"
fi

echo ""
echo "=== Environment Configuration Loaded ==="
echo ""

# Source env.conf to load defaults for variables not set in environment
# Use set -a to export all variables so they're available to child processes
set -a
source /etc/apache2/env.conf
set +a

# Ensure config folder has proper permissions (users need access)
chmod 775 /etc/yahlp || {
    echo "ERROR: Failed to set permissions on /etc/yahlp"
    exit 1
}

# Setup templates folder in config directory (users need write access for custom templates)
echo ""
echo "=== Setting up Config Templates ==="

# Create templates folder if it doesn't exist
if [ ! -d /etc/yahlp/templates ]; then
    mkdir -p /etc/yahlp/templates || {
        echo "ERROR: Failed to create /etc/yahlp/templates directory"
        exit 1
    }
    echo "✓ Created /etc/yahlp/templates directory"
fi

# Set permissions on templates folder (755 for access, users add files as needed)
chmod 775 /etc/yahlp/templates || {
    echo "ERROR: Failed to set permissions on /etc/yahlp/templates"
    exit 1
}

# Copy built-in templates README to config folder for user instructions
if [ -f /templates/README.md ] && [ ! -f /etc/yahlp/templates/README.md ]; then
    cp /templates/README.md /etc/yahlp/templates/README.md || {
        echo "ERROR: Failed to copy templates README"
        exit 1
    }
    chmod 644 /etc/yahlp/templates/README.md
    echo "✓ Copied templates/README.md to /etc/yahlp/templates/"
    echo "  Users can add custom layout templates to this folder"
fi

# Verify all permissions are correctly set
echo ""
echo "=== Verifying Folder Permissions ==="
echo "Folder Permissions Summary:"
ls -ld /etc/yahlp | awk '{print "  /etc/yahlp: " $1}'
ls -ld /etc/yahlp/certs | awk '{print "  /etc/yahlp/certs: " $1}'
ls -ld /etc/yahlp/templates | awk '{print "  /etc/yahlp/templates: " $1}'
ls -ld /etc/yahlp/logs | awk '{print "  /etc/yahlp/logs: " $1}'
ls -ld /etc/yahlp/logs/sites | awk '{print "  /etc/yahlp/logs/sites: " $1}'

# Verify symlinks
echo ""
echo "Symlinks:"
if [ -L /etc/letsencrypt ]; then
    echo "  /etc/letsencrypt → $(readlink /etc/letsencrypt)"
fi
if [ -L /var/log/apache2 ]; then
    echo "  /var/log/apache2 → $(readlink /var/log/apache2)"
fi

echo ""
echo "=== Setting Global ServerName ==="
# Set global ServerName to suppress the warning (only if DOMAIN is set)
if ! grep -q "^ServerName" /etc/apache2/apache2.conf; then
    if [ ! -z "$DOMAIN" ]; then
        echo "ServerName $DOMAIN" >> /etc/apache2/apache2.conf
        echo "Added ServerName: $DOMAIN"
    fi
fi

# Update env.conf with modified DASH_STYLE (in case basic auth forced it to classic)
sed -i "s/^DASH_STYLE=.*/DASH_STYLE=\"${DASH_STYLE}\"/" /etc/apache2/env.conf
sed -i "s/^DASHBOARD_WINDOWS=.*/DASHBOARD_WINDOWS=\"${DASHBOARD_WINDOWS}\"/" /etc/apache2/env.conf || echo "DASHBOARD_WINDOWS=\"${DASHBOARD_WINDOWS}\"" >> /etc/apache2/env.conf

# Configuration - clean up ACCESS_MODE if it was set
ACCESS_MODE=$(echo "${ACCESS_MODE}" | tr '[:upper:]' '[:lower:]' | sed "s/'//g" | sed 's/"//g' | xargs)
DOMAIN="${DOMAIN:-example.com}"
EMAIL="${EMAIL:-admin@example.com}"
CERTBOT_WEBROOT="${CERTBOT_WEBROOT:-/var/www/letsencrypt}"

echo "=== Deployment Mode Setup ==="
echo "Access Mode: $ACCESS_MODE"

# Determine deployment mode and set SKIP_CERT_GENERATION accordingly
if [ "$ACCESS_MODE" = "private" ]; then
    echo "✓ Private mode - Internal dashboard only"
    SKIP_CERT_GENERATION=true

    # Validate that IP is provided in private mode
    if [ -z "$IP" ]; then
        echo "ERROR: IP environment variable is required for private mode"
        echo "Please provide: -e IP='192.168.9.244'"
        exit 1
    fi

    # Validate that only none or basic auth are used in private mode
    if [ "$AUTHTYPE" != "none" ] && [ "$AUTHTYPE" != "basic" ]; then
        echo "ERROR: Private mode only supports 'none' or 'basic' authentication"
        echo "Provided AUTHTYPE: $AUTHTYPE"
        exit 1
    fi

    echo "IP: $IP (private mode)"
elif [ "$ACCESS_MODE" = "public" ]; then
    echo "✓ Public mode - Full features enabled"
    SKIP_CERT_GENERATION=false
    echo "Domain: $DOMAIN"
    echo "Email: $EMAIL"
else
    echo "ERROR: Invalid ACCESS_MODE: $ACCESS_MODE"
    echo "Valid options: private, public"
    exit 1
fi

echo ""
echo "=== Test Mode Configuration ==="
# Setup staging flag for certbot if TEST mode is enabled
DRY_RUN_FLAG=""
if [ "$DASHBOARD_TEST" = "true" ]; then
    DRY_RUN_FLAG="--staging"
    echo "⚠ TEST mode enabled - using Let's Encrypt staging server (insecure test certificates)"
else
    echo "✓ Production mode - certificates will be issued from production Let's Encrypt"
fi

echo ""
echo "=== Apache Setup ==="
echo "Style: $DASH_STYLE (Auth: $AUTHTYPE)"

# Calculate cookie domain for OIDC session sharing before generating config
COOKIE_DOMAIN=".${DOMAIN#*.}"
[ "$COOKIE_DOMAIN" = "." ] && COOKIE_DOMAIN=".$DOMAIN"
export COOKIE_DOMAIN

# Generate Apache configuration from template based on environment variables
echo "Generating Apache configuration with enabled services..."
/usr/local/bin/generate-config.sh \
    /etc/apache2/sites-available/reverse-proxy.conf.template \
    /etc/apache2/sites-available/reverse-proxy.conf

# For private mode, update service configs with IP-based URLs
if [ "$ACCESS_MODE" = "private" ]; then
    IP=$(echo "$IP" | xargs)
    echo "Updating service configs for private mode (IP: $IP)..."
    # Replace https://example.com with http://IP in all service config files
    for service_conf in /etc/apache2/sites-available/services/*.conf; do
        if [ -f "$service_conf" ]; then
            sed -i "s|https://example\.com|http://$IP|g" "$service_conf"
        fi
    done
fi

# Substitute environment variables in service config files
echo "Substituting service URLs in config files..."

# List of all services (matching json5 service names)
SERVICES="jellyfin plex emby sonarr radarr lidarr whisparr qbittorrent transmission sabnzbd nzbget deluge nzbhydra jackett prowlarr seerr bazarr tautulli maintainerr"

for service in $SERVICES; do
    # Use tr for portable uppercase conversion (${var^^} doesn't work in all bash versions)
    SERVICE_UPPER=$(echo "$service" | tr '[:lower:]' '[:upper:]')
    SERVICE_ENABLED_VAR="${SERVICE_UPPER}_ENABLED"
    SERVICE_URL_VAR="${SERVICE_UPPER}_URL"

    # Get the actual variable values using indirect expansion
    eval "SERVICE_ENABLED=\$$SERVICE_ENABLED_VAR"
    eval "SERVICE_URL=\$$SERVICE_URL_VAR"

    # Check if service is enabled
    if [ "$SERVICE_ENABLED" = "true" ] && [ ! -z "$SERVICE_URL" ]; then
        CONF_FILE="/etc/apache2/sites-available/services/${service}.conf"

        if [ -f "$CONF_FILE" ]; then
            # Handle Jellyfin special case (needs websocket URL)
            if [ "$service" = "jellyfin" ]; then
                JELLYFIN_BASE_URL=$(echo "$SERVICE_URL" | sed 's|/jellyfin/?$||')
                JELLYFIN_URL_WS=$(echo "$JELLYFIN_BASE_URL" | sed 's|^http://|ws://|; s|^https://|wss://|')
                sed -i "s|@@JELLYFIN_URL@@|$JELLYFIN_BASE_URL|g" "$CONF_FILE"
                sed -i "s|@@JELLYFIN_URL_WS@@|$JELLYFIN_URL_WS|g" "$CONF_FILE"
                echo "✓ Configured $service"
            else
                # Substitute generic URL placeholder
                PLACEHOLDER="@@${SERVICE_UPPER}_URL@@"
                sed -i "s|$PLACEHOLDER|$SERVICE_URL|g" "$CONF_FILE"
                echo "✓ Configured $service"
            fi
        fi
    fi
done

# Copy pre-cached favicons from html/sites-icons/ if they exist (don't overwrite existing)
echo "Copying pre-cached site favicons (skip existing)..."
if [ -d /var/www/html/sites-icons ] && [ -n "$(find /var/www/html/sites-icons -maxdepth 1 -type f 2>/dev/null)" ]; then
    find /var/www/html/sites-icons -maxdepth 1 -type f -exec cp -n {} /var/log/apache2/sites/ \;
    chmod 644 /var/log/apache2/sites/* 2>/dev/null || true
    echo "✓ Pre-cached favicons copied"
else
    echo "✓ No pre-cached favicons found (will fetch on demand)"
fi

# Initialize and manage torrent/usenet sites
echo ""
/usr/local/bin/generate-sites-config.sh

# Generate HTML dashboard based on enabled services and DASH_STYLE
echo ""
echo "Generating dashboard menu based on enabled services..."
/usr/local/bin/generate-html-menu.sh

# Enable reverse proxy site
a2ensite reverse-proxy.conf 2>/dev/null || true

# Enable required Apache modules for OAuth2 and Basic Auth
echo "Enabling Apache modules..."
a2enmod auth_openidc 2>/dev/null || true
a2enmod auth_basic 2>/dev/null || true
a2enmod proxy 2>/dev/null || true
a2enmod proxy_http 2>/dev/null || true
a2enmod headers 2>/dev/null || true
a2enmod rewrite 2>/dev/null || true
a2enmod ssl 2>/dev/null || true
a2enmod session 2>/dev/null || true
a2enmod session_crypto 2>/dev/null || true

# Enable security configuration (blocks .env and other sensitive files)
a2enconf security 2>/dev/null || true

# Check if auth_openidc module file exists
if [ -f /usr/lib/apache2/modules/mod_auth_openidc.so ]; then
    echo "✓ auth_openidc module file found and enabled"
else
    echo "✗ WARNING: auth_openidc module file NOT found"
fi

# Normalize AUTHTYPE value (handle case and quotes)
AUTHTYPE=$(echo "${AUTHTYPE}" | tr '[:upper:]' '[:lower:]' | sed "s/'//g" | sed 's/"//g' | xargs)

# Force classic style for basic auth (basic auth doesn't support modern dashboards)
if [ "$AUTHTYPE" = "basic" ]; then
    DASH_STYLE="classic"
    echo "INFO: Basic auth requires DASH_STYLE=classic (modern dashboards require session management)"
fi

# Authentication Setup - Mutually Exclusive
case "${AUTHTYPE}" in
    basic)
        echo "=== Setting up Basic Authentication ==="

        # Validate required parameters
        if [ -z "$BASIC_AUTH_CREDENTIALS" ]; then
            echo "ERROR: BASIC_AUTH_CREDENTIALS is required when AUTHTYPE=basic"
            echo "Format: username:password|username2:password2 (pipe-separated pairs)"
            exit 1
        fi

        # Create .htpasswd file
        HTPASSWD_FILE="/etc/apache2/.htpasswd"
        > "$HTPASSWD_FILE"

        # Parse credentials and add to .htpasswd
        IFS='|' read -ra CREDENTIALS_ARRAY <<< "$BASIC_AUTH_CREDENTIALS"
        for credential in "${CREDENTIALS_ARRAY[@]}"; do
            IFS=':' read -r username password <<< "$credential"
            if [ -z "$username" ] || [ -z "$password" ]; then
                echo "ERROR: Invalid credential format. Expected 'username:password'"
                exit 1
            fi
            htpasswd -bB "$HTPASSWD_FILE" "$username" "$password" 2>/dev/null || {
                echo "ERROR: Failed to create htpasswd entry for user: $username"
                exit 1
            }
            echo "✓ Added user to basic auth: $username"
        done

        # Set proper permissions
        chown root:www-data "$HTPASSWD_FILE"
        chmod 640 "$HTPASSWD_FILE"

        # Enable basic auth config
        if [ -f /etc/apache2/conf-available/auth-basic.conf ]; then
            cp /etc/apache2/conf-available/auth-basic.conf /etc/apache2/conf-enabled/auth-basic.conf
            echo "✓ Basic authentication enabled"
        else
            echo "ERROR: auth-basic.conf not found"
            exit 1
        fi

        # Replace placeholder in reverse-proxy.conf with include statement
        sed -i 's|@@INCLUDE_BASIC_AUTH@@|Include /etc/apache2/conf-enabled/auth-basic.conf|g' /etc/apache2/sites-available/reverse-proxy.conf

        # Disable OAuth2
        a2disconf oauth2-office365 2>/dev/null || true
        a2disconf auth-office365-protect 2>/dev/null || true
        rm -f /etc/apache2/conf-enabled/oauth2-office365.conf
        rm -f /etc/apache2/conf-enabled/auth-office365-protect.conf

        # Clear OAuth auth placeholders
        sed -i 's|@@INCLUDE_AUTH_ENTRA@@||g' /etc/apache2/sites-available/reverse-proxy.conf
        sed -i 's|@@INCLUDE_AUTH_GOOGLE@@||g' /etc/apache2/sites-available/reverse-proxy.conf
        ;;

    entra)
        echo "=== Setting up Entra ID (Microsoft) Authentication ==="

        # Validate Entra OAuth credentials are provided
        if [ -z "$ENTRA_CLIENT_ID" ] || [ -z "$ENTRA_CLIENT_SECRET" ] || [ -z "$ENTRA_PROVIDER_METADATA_URL" ]; then
            echo "ERROR: ENTRA_CLIENT_ID, ENTRA_CLIENT_SECRET, and ENTRA_PROVIDER_METADATA_URL are required for Entra OAuth"
            exit 1
        else
            # Generate crypto passphrase if not provided
            if [ -z "$ENTRA_CRYPTO_PASSPHRASE" ]; then
                ENTRA_CRYPTO_PASSPHRASE=$(openssl rand -base64 24)
                echo "Generated random crypto passphrase"
            fi

            # Extract domain from ENTRA_REDIRECT_URI for wildcard cookie domain
            # Example: https://transfers.limosani.net.au/oauth2callback → .limosani.net.au
            COOKIE_DOMAIN=$(echo "$ENTRA_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
            if [ -z "$COOKIE_DOMAIN" ] || [ "$COOKIE_DOMAIN" = "$ENTRA_REDIRECT_URI" ]; then
                # Fallback: if URL doesn't have subdomain, use full domain
                COOKIE_DOMAIN=$(echo "$ENTRA_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
            fi

            # Configure Entra OAuth2 in Apache
            cat /etc/apache2/conf-available/oauth2-entra.conf \
                | sed "s|@@ENTRA_CLIENT_ID@@|$ENTRA_CLIENT_ID|g" \
                | sed "s|@@ENTRA_CLIENT_SECRET@@|$ENTRA_CLIENT_SECRET|g" \
                | sed "s|@@ENTRA_REDIRECT_URI@@|$ENTRA_REDIRECT_URI|g" \
                | sed "s|@@ENTRA_PROVIDER_METADATA_URL@@|$ENTRA_PROVIDER_METADATA_URL|g" \
                | sed "s|@@ENTRA_CRYPTO_PASSPHRASE@@|$ENTRA_CRYPTO_PASSPHRASE|g" \
                | sed "s|@@COOKIE_DOMAIN@@|$COOKIE_DOMAIN|g" \
                > /etc/apache2/conf-enabled/oauth2-entra.conf

            cp /etc/apache2/conf-available/auth-entra-protect.conf /etc/apache2/conf-enabled/
            a2enconf oauth2-entra 2>/dev/null || true
            a2enconf auth-entra-protect 2>/dev/null || true

            # Include auth-entra-protect in VirtualHost to enforce authentication
            sed -i 's|@@INCLUDE_AUTH_ENTRA@@|Include /etc/apache2/conf-available/auth-entra-protect.conf|g' /etc/apache2/sites-available/reverse-proxy.conf

            echo "✓ Entra OAuth configured in Apache"
            echo "  Client ID: ${ENTRA_CLIENT_ID:0:20}..."
        fi

        # Disable other auth methods
        rm -f /etc/apache2/conf-enabled/auth-basic.conf /etc/apache2/conf-enabled/oauth2-google.conf /etc/apache2/conf-enabled/auth-google-protect.conf
        rm -f /etc/apache2/.htpasswd

        # Clear Google auth placeholder
        sed -i 's|@@INCLUDE_AUTH_GOOGLE@@||g' /etc/apache2/sites-available/reverse-proxy.conf
        ;;

    google)
        echo "=== Setting up Google OAuth2 Authentication ==="

        # Validate Google OAuth credentials are provided
        if [ -z "$GOOGLE_CLIENT_ID" ] || [ -z "$GOOGLE_CLIENT_SECRET" ]; then
            echo "ERROR: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET are required for Google OAuth"
            exit 1
        else
            # Configure Google OAuth2 in Apache
            # Generate random encryption passphrase for sessions (internal use only)
            GOOGLE_CRYPTO_PASSPHRASE=$(openssl rand -base64 24)

            # Extract domain from GOOGLE_REDIRECT_URI for wildcard cookie domain
            # Example: https://transfers.limosani.net.au/oauth2callback → .limosani.net.au
            COOKIE_DOMAIN=$(echo "$GOOGLE_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
            if [ -z "$COOKIE_DOMAIN" ] || [ "$COOKIE_DOMAIN" = "$GOOGLE_REDIRECT_URI" ]; then
                # Fallback: if URL doesn't have subdomain, use full domain
                COOKIE_DOMAIN=$(echo "$GOOGLE_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
            fi

            cat /etc/apache2/conf-available/oauth2-google.conf \
                | sed "s|@@GOOGLE_CLIENT_ID@@|$GOOGLE_CLIENT_ID|g" \
                | sed "s|@@GOOGLE_CLIENT_SECRET@@|$GOOGLE_CLIENT_SECRET|g" \
                | sed "s|@@GOOGLE_REDIRECT_URI@@|$GOOGLE_REDIRECT_URI|g" \
                | sed "s|@@GOOGLE_CRYPTO_PASSPHRASE@@|$GOOGLE_CRYPTO_PASSPHRASE|g" \
                | sed "s|@@COOKIE_DOMAIN@@|$COOKIE_DOMAIN|g" \
                > /etc/apache2/conf-enabled/oauth2-google.conf

            cp /etc/apache2/conf-available/auth-google-protect.conf /etc/apache2/conf-enabled/
            a2enconf oauth2-google 2>/dev/null || true
            a2enconf auth-google-protect 2>/dev/null || true

            # Include auth-google-protect in VirtualHost to enforce authentication
            sed -i 's|@@INCLUDE_AUTH_GOOGLE@@|Include /etc/apache2/conf-available/auth-google-protect.conf|g' /etc/apache2/sites-available/reverse-proxy.conf

            echo "✓ Google OAuth configured in Apache"
            echo "  Client ID: ${GOOGLE_CLIENT_ID:0:20}..."
        fi

        # Disable other auth methods
        rm -f /etc/apache2/conf-enabled/auth-basic.conf /etc/apache2/conf-enabled/oauth2-entra.conf /etc/apache2/conf-enabled/auth-entra-protect.conf
        rm -f /etc/apache2/.htpasswd

        # Clear Entra auth placeholder
        sed -i 's|@@INCLUDE_AUTH_ENTRA@@||g' /etc/apache2/sites-available/reverse-proxy.conf
        ;;

    none|*)
        echo "=== Authentication Disabled (AUTHTYPE=none) ==="

        # Disable all authentication methods
        a2disconf oauth2-entra 2>/dev/null || true
        a2disconf auth-entra-protect 2>/dev/null || true
        a2disconf oauth2-google 2>/dev/null || true
        a2disconf auth-google-protect 2>/dev/null || true
        rm -f /etc/apache2/conf-enabled/oauth2-entra.conf /etc/apache2/conf-enabled/auth-entra-protect.conf
        rm -f /etc/apache2/conf-enabled/oauth2-google.conf /etc/apache2/conf-enabled/auth-google-protect.conf
        rm -f /etc/apache2/conf-enabled/auth-basic.conf
        rm -f /etc/apache2/.htpasswd

        # Remove auth placeholders from reverse-proxy.conf
        sed -i 's|@@INCLUDE_BASIC_AUTH@@||g' /etc/apache2/sites-available/reverse-proxy.conf
        sed -i 's|@@INCLUDE_AUTH_ENTRA@@||g' /etc/apache2/sites-available/reverse-proxy.conf
        sed -i 's|@@INCLUDE_AUTH_GOOGLE@@||g' /etc/apache2/sites-available/reverse-proxy.conf

        echo "✓ No authentication required"
        ;;
esac

# For entra/google auth types, also remove the basic auth placeholder
if [ "$AUTHTYPE" != "basic" ]; then
    sed -i 's|@@INCLUDE_BASIC_AUTH@@||g' /etc/apache2/sites-available/reverse-proxy.conf
fi

# Function to wait for certificate
wait_for_cert() {
    local domain=$1
    local max_wait=60
    local elapsed=0
    
    echo "Waiting for certificate for $domain..."
    while [ $elapsed -lt $max_wait ]; do
        if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
            echo "Certificate found for $domain"
            return 0
        fi
        sleep 1
        ((elapsed++))
    done
    
    echo "Warning: Certificate not found after $max_wait seconds"
    return 1
}



# Function to check if certificate is staging (Fake LE) and remove it if needed
check_and_remove_staging_cert() {
    local cert_path=$1
    local domain=$2

    if [ -f "$cert_path" ]; then
        # Use timeout to prevent openssl from hanging
        local cert_text=$(timeout 10 openssl x509 -in "$cert_path" -text -noout 2>/dev/null)
        local openssl_status=$?

        if [ $openssl_status -eq 124 ]; then
            echo "[ERROR] openssl command timed out after 10 seconds for $domain"
            return 2
        fi

        if [ $openssl_status -ne 0 ]; then
            return 1
        fi

        # Check for staging indicators: "Fake LE" in issuer, or "staging" in CN
        if echo "$cert_text" | grep -qi "Fake LE\|Staging\|staging"; then
            echo "⚠ Staging certificate found for $domain - removing to obtain production certificate"
            rm -rf "/etc/letsencrypt/live/$domain" "/etc/letsencrypt/archive/$domain" "/etc/letsencrypt/renewal/$domain.conf" 2>/dev/null || true
            echo "✓ Removed staging cert and renewal config for $domain"
            return 0  # Certificate removed
        else
            echo "✓ Certificate found for $domain (checking if valid production cert...)"
            return 1  # Certificate exists, assume production or valid
        fi
    fi
    return 2  # No certificate found
}

# Generate certificate only if not skipped (public mode)
if [ "$SKIP_CERT_GENERATION" = "false" ]; then
    echo ""
    echo "=== Obtaining Let's Encrypt Certificate ==="
    echo "Certificate path: /etc/yahlp/certs/live/$DOMAIN/fullchain.pem"

    # Check for staging certificates when switching from TEST to production mode
    FORCE_RENEWAL=""

    if [ "$DASHBOARD_TEST" = "false" ]; then
        set +e
        check_and_remove_staging_cert "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$DOMAIN"
        CERT_STATUS=$?
        set -e

        # If staging cert was found and removed, force renewal to get production cert
        if [ $CERT_STATUS -eq 0 ]; then
            echo "Requesting production certificate for $DOMAIN (staging removed)..."
            FORCE_RENEWAL="--force-renewal"
        elif [ $CERT_STATUS -eq 1 ]; then
            echo "✓ Production certificate already valid for $DOMAIN"
        fi
    fi

    # Check if certificate needs generation/renewal
    if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] || [ ! -z "$FORCE_RENEWAL" ]; then
        echo "Requesting certificate for main domain: $DOMAIN..."

        # Ensure directory exists
        mkdir -p "/etc/letsencrypt/live/$DOMAIN"

        # Obtain certificate using standalone method
        if certbot certonly \
            --standalone \
            --preferred-challenges http \
            --email "$EMAIL" \
            --agree-tos \
            --no-eff-email \
            --non-interactive \
            --deploy-hook "chmod -R 777 /etc/letsencrypt/live /etc/letsencrypt/archive" \
            $DRY_RUN_FLAG \
            $FORCE_RENEWAL \
            -d "$DOMAIN"; then
            echo "✓ Certificate obtained from Let's Encrypt for $DOMAIN"
        else
            echo "⚠ Certbot failed. Generating self-signed certificate as fallback..."

            # Ensure directory exists
            mkdir -p "/etc/letsencrypt/live/$DOMAIN"

            # Generate self-signed certificate
            openssl req -x509 -nodes -days 365 \
                -newkey rsa:2048 \
                -keyout "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
                -out "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
                -subj "/C=AU/ST=Victoria/L=Melbourne/O=Org/CN=$DOMAIN" \
                2>/dev/null || true

            echo "✓ Self-signed certificate generated for $DOMAIN"
        fi
    else
        echo "✓ Certificate already exists for main domain: $DOMAIN"
    fi
else
    echo ""
    echo "=== Certificate Generation Skipped (Private Mode - HTTP Only) ==="
    echo "✓ Private mode uses HTTP only (no SSL)"
fi

# Request certificates for Emby and Plex subdomains
if [ "$SKIP_CERT_GENERATION" = "false" ]; then
    if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$EMBY_DOMAIN" ] && [ "${ENABLE_EMBY}" = "true" ]; then
        EMBY_CERT_DOMAIN=$(echo "$EMBY_DOMAIN" | sed -E 's|^https?://[^.]+\.(.+)$|\1|')
        echo "Checking Emby certificate existence..."

        # Check for staging certificate when switching from TEST to production mode
        EMBY_FORCE_RENEWAL=""
        if [ "$DASHBOARD_TEST" = "false" ]; then
            set +e
            check_and_remove_staging_cert "/etc/letsencrypt/live/$EMBY_DOMAIN/fullchain.pem" "$EMBY_DOMAIN"
            EMBY_STATUS=$?
            set -e
            if [ $EMBY_STATUS -eq 0 ]; then
                EMBY_FORCE_RENEWAL="--force-renewal"
            fi
            set +e
            check_and_remove_staging_cert "/etc/letsencrypt/live/$EMBY_CERT_DOMAIN/fullchain.pem" "$EMBY_CERT_DOMAIN"
            EMBY_STATUS=$?
            set -e
            if [ $EMBY_STATUS -eq 0 ]; then
                EMBY_FORCE_RENEWAL="--force-renewal"
            fi
        fi

        if [ ! -f "/etc/letsencrypt/live/$EMBY_CERT_DOMAIN/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$EMBY_DOMAIN/fullchain.pem" ]; then
            echo "Requesting certificate for Emby subdomain: $EMBY_DOMAIN"
            certbot certonly --standalone --preferred-challenges http --email "$EMAIL" --agree-tos --no-eff-email --non-interactive --deploy-hook "chmod -R 777 /etc/letsencrypt/live /etc/letsencrypt/archive" $DRY_RUN_FLAG $EMBY_FORCE_RENEWAL -d "$EMBY_DOMAIN" || {
                echo "⚠ Certbot failed for Emby subdomain, using main domain certificate"
            }
        else
            echo "✓ Emby certificate already exists"
        fi
    fi

    if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$PLEX_DOMAIN" ] && [ "${ENABLE_PLEX}" = "true" ]; then
        PLEX_CERT_DOMAIN=$(echo "$PLEX_DOMAIN" | sed -E 's|^https?://[^.]+\.(.+)$|\1|')
        echo "Checking Plex certificate existence..."

        # Check for staging certificate when switching from TEST to production mode
        PLEX_FORCE_RENEWAL=""
        if [ "$DASHBOARD_TEST" = "false" ]; then
            set +e
            check_and_remove_staging_cert "/etc/letsencrypt/live/$PLEX_DOMAIN/fullchain.pem" "$PLEX_DOMAIN"
            PLEX_STATUS=$?
            set -e
            if [ $PLEX_STATUS -eq 0 ]; then
                PLEX_FORCE_RENEWAL="--force-renewal"
            fi
            set +e
            check_and_remove_staging_cert "/etc/letsencrypt/live/$PLEX_CERT_DOMAIN/fullchain.pem" "$PLEX_CERT_DOMAIN"
            PLEX_STATUS=$?
            set -e
            if [ $PLEX_STATUS -eq 0 ]; then
                PLEX_FORCE_RENEWAL="--force-renewal"
            fi
        fi

        if [ ! -f "/etc/letsencrypt/live/$PLEX_CERT_DOMAIN/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$PLEX_DOMAIN/fullchain.pem" ]; then
            echo "Requesting certificate for Plex subdomain: $PLEX_DOMAIN"
            certbot certonly --standalone --preferred-challenges http --email "$EMAIL" --agree-tos --no-eff-email --non-interactive --deploy-hook "chmod -R 777 /etc/letsencrypt/live /etc/letsencrypt/archive" $DRY_RUN_FLAG $PLEX_FORCE_RENEWAL -d "$PLEX_DOMAIN" || {
                echo "⚠ Certbot failed for Plex subdomain, using main domain certificate"
            }
        else
            echo "✓ Plex certificate already exists"
        fi
    fi

    if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$SEERR_DOMAIN" ] && [ "${ENABLE_SEERR}" = "true" ]; then
        SEERR_CERT_DOMAIN=$(echo "$SEERR_DOMAIN" | sed -E 's|^https?://[^.]+\.(.+)$|\1|')
        echo "Checking Seerr certificate existence..."

        # Check for staging certificate when switching from TEST to production mode
        SEERR_FORCE_RENEWAL=""
        if [ "$DASHBOARD_TEST" = "false" ]; then
            set +e
            check_and_remove_staging_cert "/etc/letsencrypt/live/$SEERR_DOMAIN/fullchain.pem" "$SEERR_DOMAIN"
            SEERR_STATUS=$?
            set -e
            if [ $SEERR_STATUS -eq 0 ]; then
                SEERR_FORCE_RENEWAL="--force-renewal"
            fi
            set +e
            check_and_remove_staging_cert "/etc/letsencrypt/live/$SEERR_CERT_DOMAIN/fullchain.pem" "$SEERR_CERT_DOMAIN"
            SEERR_STATUS=$?
            set -e
            if [ $SEERR_STATUS -eq 0 ]; then
                SEERR_FORCE_RENEWAL="--force-renewal"
            fi
        fi

        if [ ! -f "/etc/letsencrypt/live/$SEERR_CERT_DOMAIN/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$SEERR_DOMAIN/fullchain.pem" ]; then
            echo "Requesting certificate for Seerr subdomain: $SEERR_DOMAIN"
            certbot certonly --standalone --preferred-challenges http --email "$EMAIL" --agree-tos --no-eff-email --non-interactive --deploy-hook "chmod -R 777 /etc/letsencrypt/live /etc/letsencrypt/archive" $DRY_RUN_FLAG $SEERR_FORCE_RENEWAL -d "$SEERR_DOMAIN" || {
                echo "⚠ Certbot failed for Seerr subdomain, using main domain certificate"
            }
        else
            echo "✓ Seerr certificate already exists"
        fi
    fi
fi

# Fix certificate folder permissions (certbot creates dirs with 755, we need 777 for web server write access)
chmod -R 777 /etc/yahlp/certs
echo "✓ Certificate permissions fixed"

if [ "${ENABLE_EMBY}" = "true" ] && [ ! -z "$EMBY_DOMAIN" ] && [ ! -z "$EMBY_REDIRECT_URI" ] && ([ "$AUTHTYPE" = "google" ] || [ "$AUTHTYPE" = "entra" ]); then
    echo ""
    echo "=== Emby Subdomain OAuth Setup ==="
    echo "Emby domain: $EMBY_DOMAIN"

    # Extract subdomain from EMBY_DOMAIN (e.g., emby.limosani.net.au → emby)
    EMBY_SUBDOMAIN=$(echo "$EMBY_DOMAIN" | sed -E 's|^https?://([^.]+)\..*|\1|')

    # Extract domain for certificate (limosani.net.au)
    EMBY_CERT_DOMAIN=$(echo "$EMBY_DOMAIN" | sed -E 's|^https?://[^.]+\.(.+)$|\1|')

    echo "Emby subdomain: $EMBY_SUBDOMAIN, cert domain: $EMBY_CERT_DOMAIN"

    # Generate Emby OAuth config based on auth type
    case "$AUTHTYPE" in
        google)
            if [ ! -z "$EMBY_REDIRECT_URI" ]; then
                # Extract cookie domain from Emby redirect URI
                EMBY_COOKIE_DOMAIN=$(echo "$EMBY_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
                if [ -z "$EMBY_COOKIE_DOMAIN" ] || [ "$EMBY_COOKIE_DOMAIN" = "$EMBY_REDIRECT_URI" ]; then
                    EMBY_COOKIE_DOMAIN=$(echo "$EMBY_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
                fi

                cat /etc/apache2/conf-available/oauth2-google.conf \
                    | sed "s#@@GOOGLE_CLIENT_ID@@#$GOOGLE_CLIENT_ID#g" \
                    | sed "s#@@GOOGLE_CLIENT_SECRET@@#$GOOGLE_CLIENT_SECRET#g" \
                    | sed "s#@@GOOGLE_REDIRECT_URI@@#$EMBY_REDIRECT_URI#g" \
                    | sed "s#@@GOOGLE_CRYPTO_PASSPHRASE@@#$GOOGLE_CRYPTO_PASSPHRASE#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$EMBY_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/emby-google-oauth2.conf

                # Create auth-protect file for Emby with Google
                cat > /etc/apache2/conf-available/emby-google-protect.conf <<'AUTHEOF'
# Google Authentication Protection for Emby Subdomain
<Location /oauth2callback>
    SetHandler oauth2-handler
</Location>

<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>

RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Google"
AUTHEOF
                echo "✓ Emby Google auth-protect config generated"

                echo "✓ Emby Google OAuth config generated"
            fi
            ;;
        entra)
            if [ ! -z "$EMBY_REDIRECT_URI" ]; then
                # Extract cookie domain from Emby redirect URI
                EMBY_COOKIE_DOMAIN=$(echo "$EMBY_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
                if [ -z "$EMBY_COOKIE_DOMAIN" ] || [ "$EMBY_COOKIE_DOMAIN" = "$EMBY_REDIRECT_URI" ]; then
                    EMBY_COOKIE_DOMAIN=$(echo "$EMBY_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
                fi

                cat /etc/apache2/conf-available/oauth2-entra.conf \
                    | sed "s#@@ENTRA_CLIENT_ID@@#$ENTRA_CLIENT_ID#g" \
                    | sed "s#@@ENTRA_CLIENT_SECRET@@#$ENTRA_CLIENT_SECRET#g" \
                    | sed "s#@@ENTRA_REDIRECT_URI@@#$EMBY_REDIRECT_URI#g" \
                    | sed "s#@@ENTRA_PROVIDER_METADATA_URL@@#$ENTRA_PROVIDER_METADATA_URL#g" \
                    | sed "s#@@ENTRA_CRYPTO_PASSPHRASE@@#$ENTRA_CRYPTO_PASSPHRASE#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$EMBY_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/emby-entra-oauth2.conf

                # Create auth-protect file for Emby with Entra
                cat > /etc/apache2/conf-available/emby-entra-protect.conf <<'AUTHEOF'
# Entra ID Authentication Protection for Emby Subdomain
<Location /oauth2>
    SetHandler oauth2-handler
</Location>

<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>

RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Entra"
AUTHEOF
                echo "✓ Emby Entra auth-protect config generated"

                echo "✓ Emby Entra OAuth config generated"
            fi
            ;;
    esac
fi

if [ "${ENABLE_PLEX}" = "true" ] && [ ! -z "$PLEX_DOMAIN" ] && [ ! -z "$PLEX_REDIRECT_URI" ] && ([ "$AUTHTYPE" = "google" ] || [ "$AUTHTYPE" = "entra" ]); then
    echo ""
    echo "=== Plex Subdomain OAuth Setup ==="
    echo "Plex domain: $PLEX_DOMAIN"

    # Extract subdomain from PLEX_DOMAIN (e.g., plex.limosani.net.au → plex)
    PLEX_SUBDOMAIN=$(echo "$PLEX_DOMAIN" | sed -E 's|^https?://([^.]+)\..*|\1|')

    # Extract domain for certificate (limosani.net.au)
    PLEX_CERT_DOMAIN=$(echo "$PLEX_DOMAIN" | sed -E 's|^https?://[^.]+\.(.+)$|\1|')

    echo "Plex subdomain: $PLEX_SUBDOMAIN, cert domain: $PLEX_CERT_DOMAIN"

    # Generate Plex OAuth config based on auth type
    case "$AUTHTYPE" in
        google)
            if [ ! -z "$PLEX_REDIRECT_URI" ]; then
                # Extract cookie domain from Plex redirect URI
                PLEX_COOKIE_DOMAIN=$(echo "$PLEX_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
                if [ -z "$PLEX_COOKIE_DOMAIN" ] || [ "$PLEX_COOKIE_DOMAIN" = "$PLEX_REDIRECT_URI" ]; then
                    PLEX_COOKIE_DOMAIN=$(echo "$PLEX_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
                fi

                cat /etc/apache2/conf-available/oauth2-google.conf \
                    | sed "s#@@GOOGLE_CLIENT_ID@@#$GOOGLE_CLIENT_ID#g" \
                    | sed "s#@@GOOGLE_CLIENT_SECRET@@#$GOOGLE_CLIENT_SECRET#g" \
                    | sed "s#@@GOOGLE_REDIRECT_URI@@#$PLEX_REDIRECT_URI#g" \
                    | sed "s#@@GOOGLE_CRYPTO_PASSPHRASE@@#$GOOGLE_CRYPTO_PASSPHRASE#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$PLEX_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/plex-google-oauth2.conf

                # Create auth-protect file for Plex with Google
                cat > /etc/apache2/conf-available/plex-google-protect.conf <<'AUTHEOF'
# Google Authentication Protection for Plex Subdomain
<Location /oauth2callback>
    SetHandler oauth2-handler
</Location>

<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>

RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Google"
AUTHEOF
                echo "✓ Plex Google auth-protect config generated"

                echo "✓ Plex Google OAuth config generated"
            fi

            # Generate Seerr Google OAuth config (if SEERR_DOMAIN is set)
            if [ ! -z "$SEERR_DOMAIN" ] && [ ! -z "$SEERR_REDIRECT_URI" ]; then
                SEERR_COOKIE_DOMAIN=$(echo "$SEERR_DOMAIN" | sed 's|^[^.]*\.||')

                cat /etc/apache2/conf-available/oauth2-google.conf \
                    | sed "s#@@GOOGLE_CLIENT_ID@@#$GOOGLE_CLIENT_ID#g" \
                    | sed "s#@@GOOGLE_CLIENT_SECRET@@#$GOOGLE_CLIENT_SECRET#g" \
                    | sed "s#@@GOOGLE_REDIRECT_URI@@#$SEERR_REDIRECT_URI#g" \
                    | sed "s#@@GOOGLE_CRYPTO_PASSPHRASE@@#$GOOGLE_CRYPTO_PASSPHRASE#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$SEERR_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/seerr-google-oauth2.conf

                # Create auth-protect file for Seerr with Google
                cat > /etc/apache2/conf-available/seerr-google-protect.conf <<'AUTHEOF'
# Google Authentication Protection for Seerr Subdomain
<Location /oauth2callback>
    SetHandler oauth2-handler
</Location>

<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>

RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Google"
AUTHEOF
                echo "✓ Seerr Google auth-protect config generated"

                echo "✓ Seerr Google OAuth config generated"
            fi
            ;;
        entra)
            if [ ! -z "$PLEX_REDIRECT_URI" ]; then
                # Extract cookie domain from Plex redirect URI
                PLEX_COOKIE_DOMAIN=$(echo "$PLEX_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
                if [ -z "$PLEX_COOKIE_DOMAIN" ] || [ "$PLEX_COOKIE_DOMAIN" = "$PLEX_REDIRECT_URI" ]; then
                    PLEX_COOKIE_DOMAIN=$(echo "$PLEX_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
                fi

                cat /etc/apache2/conf-available/oauth2-entra.conf \
                    | sed "s#@@ENTRA_CLIENT_ID@@#$ENTRA_CLIENT_ID#g" \
                    | sed "s#@@ENTRA_CLIENT_SECRET@@#$ENTRA_CLIENT_SECRET#g" \
                    | sed "s#@@ENTRA_REDIRECT_URI@@#$PLEX_REDIRECT_URI#g" \
                    | sed "s#@@ENTRA_PROVIDER_METADATA_URL@@#$ENTRA_PROVIDER_METADATA_URL#g" \
                    | sed "s#@@ENTRA_CRYPTO_PASSPHRASE@@#$ENTRA_CRYPTO_PASSPHRASE#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$PLEX_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/plex-entra-oauth2.conf

                # Create auth-protect file for Plex with Entra
                cat > /etc/apache2/conf-available/plex-entra-protect.conf <<'AUTHEOF'
# Entra ID Authentication Protection for Plex Subdomain
<Location /oauth2>
    SetHandler oauth2-handler
</Location>

<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>

RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Entra"
AUTHEOF
                echo "✓ Plex Entra auth-protect config generated"

                echo "✓ Plex Entra OAuth config generated"
            fi

            # Generate Seerr Entra OAuth config (if SEERR_DOMAIN is set)
            if [ ! -z "$SEERR_DOMAIN" ] && [ ! -z "$SEERR_REDIRECT_URI" ]; then
                SEERR_COOKIE_DOMAIN=$(echo "$SEERR_DOMAIN" | sed 's|^[^.]*\.||')

                cat /etc/apache2/conf-available/oauth2-entra.conf \
                    | sed "s#@@ENTRA_CLIENT_ID@@#$ENTRA_CLIENT_ID#g" \
                    | sed "s#@@ENTRA_CLIENT_SECRET@@#$ENTRA_CLIENT_SECRET#g" \
                    | sed "s#@@ENTRA_REDIRECT_URI@@#$SEERR_REDIRECT_URI#g" \
                    | sed "s#@@ENTRA_PROVIDER_METADATA_URL@@#$ENTRA_PROVIDER_METADATA_URL#g" \
                    | sed "s#@@ENTRA_CRYPTO_PASSPHRASE@@#$ENTRA_CRYPTO_PASSPHRASE#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$SEERR_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/seerr-entra-oauth2.conf

                # Create auth-protect file for Seerr with Entra
                cat > /etc/apache2/conf-available/seerr-entra-protect.conf <<'AUTHEOF'
# Entra ID Authentication Protection for Seerr Subdomain
<Location /oauth2>
    SetHandler oauth2-handler
</Location>

<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>

RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Entra"
AUTHEOF
                echo "✓ Seerr Entra auth-protect config generated"

                echo "✓ Seerr Entra OAuth config generated"
            fi
            ;;
    esac
fi

# Generate Emby VirtualHost if enabled (public mode only)
if [ "$ACCESS_MODE" = "public" ] && [ "${ENABLE_EMBY}" = "true" ] && [ ! -z "$EMBY_DOMAIN" ]; then
    echo "=== Generating Emby VirtualHost ==="

    # Determine certificate path (subdomain cert, base domain cert, or main domain fallback)
    EMBY_DOMAIN_NAME="$EMBY_DOMAIN"
    EMBY_CERT_DOMAIN=$(echo "$EMBY_DOMAIN" | sed -E 's|^https?://||' | sed -E 's|[^.]+\.(.+)$|\1|')

    if [ -f "/etc/letsencrypt/live/$EMBY_DOMAIN_NAME/fullchain.pem" ]; then
        EMBY_CERT_PATH="$EMBY_DOMAIN_NAME"
    elif [ -f "/etc/letsencrypt/live/$EMBY_CERT_DOMAIN/fullchain.pem" ]; then
        EMBY_CERT_PATH="$EMBY_CERT_DOMAIN"
    else
        EMBY_CERT_PATH="$DOMAIN"
    fi

    /usr/local/bin/generate-vhost.sh "emby" "$EMBY_DOMAIN_NAME" "$EMBY_URL" "$EMBY_CERT_PATH" "$AUTHTYPE"
    echo "=== GENERATED EMBY VHOST CONFIG ==="
    cat /etc/apache2/sites-available/emby-vhost.conf
    echo "=== END EMBY VHOST CONFIG ==="

    # Enable the Emby VirtualHost
    a2ensite emby-vhost
    echo "✓ Enabled Emby VirtualHost"
fi

# Generate Plex VirtualHost if enabled (public mode only)
if [ "$ACCESS_MODE" = "public" ] && [ "${ENABLE_PLEX}" = "true" ] && [ ! -z "$PLEX_DOMAIN" ]; then
    echo ""
    echo "=== Generating Plex VirtualHost ==="

    # Determine certificate path (subdomain cert, base domain cert, or main domain fallback)
    PLEX_DOMAIN_NAME="$PLEX_DOMAIN"
    PLEX_CERT_DOMAIN=$(echo "$PLEX_DOMAIN" | sed -E 's|^https?://||' | sed -E 's|[^.]+\.(.+)$|\1|')

    if [ -f "/etc/letsencrypt/live/$PLEX_DOMAIN_NAME/fullchain.pem" ]; then
        PLEX_CERT_PATH="$PLEX_DOMAIN_NAME"
    elif [ -f "/etc/letsencrypt/live/$PLEX_CERT_DOMAIN/fullchain.pem" ]; then
        PLEX_CERT_PATH="$PLEX_CERT_DOMAIN"
    else
        PLEX_CERT_PATH="$DOMAIN"
    fi

    /usr/local/bin/generate-vhost.sh "plex" "$PLEX_DOMAIN_NAME" "$PLEX_URL" "$PLEX_CERT_PATH" "$AUTHTYPE"

    # Enable the Plex VirtualHost
    a2ensite plex-vhost
    echo "✓ Enabled Plex VirtualHost"
fi

# Configure Seerr subdomain VirtualHost (if SEERR_DOMAIN and SEERR_URL are set and in public mode)
if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$SEERR_DOMAIN" ] && [ ! -z "$SEERR_URL" ]; then
    echo ""
    echo "=== Generating Seerr VirtualHost ==="

    # Determine certificate path (subdomain cert, base domain cert, or main domain fallback)
    SEERR_DOMAIN_NAME="$SEERR_DOMAIN"
    SEERR_CERT_DOMAIN=$(echo "$SEERR_DOMAIN" | sed -E 's|^https?://||' | sed -E 's|[^.]+\.(.+)$|\1|')

    if [ -f "/etc/letsencrypt/live/$SEERR_DOMAIN_NAME/fullchain.pem" ]; then
        SEERR_CERT_PATH="$SEERR_DOMAIN_NAME"
    elif [ -f "/etc/letsencrypt/live/$SEERR_CERT_DOMAIN/fullchain.pem" ]; then
        SEERR_CERT_PATH="$SEERR_CERT_DOMAIN"
    else
        SEERR_CERT_PATH="$DOMAIN"
    fi

    /usr/local/bin/generate-vhost.sh "seerr" "$SEERR_DOMAIN_NAME" "$SEERR_URL" "$SEERR_CERT_PATH" "$AUTHTYPE"

    # Enable the Seerr VirtualHost
    a2ensite seerr-vhost
    echo "✓ Enabled Seerr VirtualHost"
else
    if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$SEERR_DOMAIN" ]; then
        echo "⚠ SEERR_DOMAIN is set but SEERR_URL is missing - skipping Seerr VirtualHost"
    fi
fi

# Configure Jackett subdomain VirtualHost (if JACKETT_DOMAIN and JACKETT_URL are set and in public mode)
if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$JACKETT_DOMAIN" ] && [ ! -z "$JACKETT_URL" ]; then
    echo ""
    echo "=== Generating Jackett VirtualHost ==="

    # Determine certificate path (subdomain cert, base domain cert, or main domain fallback)
    JACKETT_DOMAIN_NAME="$JACKETT_DOMAIN"
    JACKETT_CERT_DOMAIN=$(echo "$JACKETT_DOMAIN" | sed -E 's|^https?://||' | sed -E 's|[^.]+\.(.+)$|\1|')

    if [ -f "/etc/letsencrypt/live/$JACKETT_DOMAIN_NAME/fullchain.pem" ]; then
        JACKETT_CERT_PATH="$JACKETT_DOMAIN_NAME"
    elif [ -f "/etc/letsencrypt/live/$JACKETT_CERT_DOMAIN/fullchain.pem" ]; then
        JACKETT_CERT_PATH="$JACKETT_CERT_DOMAIN"
    else
        JACKETT_CERT_PATH="$DOMAIN"
    fi

    /usr/local/bin/generate-vhost.sh "jackett" "$JACKETT_DOMAIN_NAME" "$JACKETT_URL" "$JACKETT_CERT_PATH" "$AUTHTYPE"

    # Enable the Jackett VirtualHost
    a2ensite jackett-vhost
    echo "✓ Enabled Jackett VirtualHost"
else
    if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$JACKETT_DOMAIN" ]; then
        echo "⚠ JACKETT_DOMAIN is set but JACKETT_URL is missing - skipping Jackett VirtualHost"
    fi
fi

# Update Apache configuration based on mode
if [ "$ACCESS_MODE" = "private" ]; then

    # Normalize IP variable
    IP=$(echo "$IP" | xargs)

    # Use a temporary file to carefully modify the config
    # Remove the 80 VirtualHost (ACME challenge only), convert 443 to 80, and remove SSL directives
    sed \
        -e '/<VirtualHost \*:80>/,/<\/VirtualHost>/d' \
        -e 's/<VirtualHost \*:443>/<VirtualHost *:80>/g' \
        -e '/SSLEngine on/d' \
        -e '/SSLCertificateFile/d' \
        -e '/SSLCertificateKeyFile/d' \
        -e '/SSLProtocol/d' \
        -e '/SSLCipherSuite/d' \
        -e '/SSLHonorCipherOrder/d' \
        -e '/Header always set Strict-Transport-Security/d' \
        -e '/Header always set X-Content-Type-Options/d' \
        -e '/Header always set X-Frame-Options/d' \
        -e '/Header always set X-XSS-Protection/d' \
        -e '/ServerAlias www\./d' \
        -e "s|ServerName @@DOMAIN@@|ServerName $IP|g" \
        -e "s|ServerName example.com|ServerName $IP|g" \
        /etc/apache2/sites-available/reverse-proxy.conf > /tmp/reverse-proxy.tmp

    mv /tmp/reverse-proxy.tmp /etc/apache2/sites-available/reverse-proxy.conf
else
    echo "Configuring for public mode (HTTPS)"
    sed -i "s|@@DOMAIN@@|$DOMAIN|g" /etc/apache2/sites-available/reverse-proxy.conf
fi

# Setup cron for certificate renewal
if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --webroot --webroot-path $CERTBOT_WEBROOT --quiet && /usr/sbin/apache2ctl graceful") | crontab -
fi

# Start cron daemon
service cron start

# Auto-enable all VirtualHost configuration files in sites-available
echo "Enabling VirtualHost configurations..."
CUSTOM_DOMAINS=""
for vhost in /etc/apache2/sites-available/*.conf; do
    filename=$(basename "$vhost" .conf)
    # Skip reverse-proxy (already enabled) and template files
    if [ "$filename" != "reverse-proxy" ] && [ ! "$filename" = *".template" ]; then
        if [ -f "$vhost" ]; then
            a2ensite "$filename" 2>/dev/null || true
            echo "  ✓ Enabled: $filename"

            # Extract ServerName from vhost for SSL certificate generation
            if [ "$ACCESS_MODE" = "public" ]; then
                domain=$(grep -E '^\s*ServerName\s+' "$vhost" | grep -oE '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | head -1)
                if [ ! -z "$domain" ] && [ "$domain" != "$DOMAIN" ]; then
                    CUSTOM_DOMAINS="$CUSTOM_DOMAINS $domain"
                fi
            fi
        fi
    fi
done

# Request SSL certificates for custom domains if in public mode
if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$CUSTOM_DOMAINS" ]; then
    echo ""
    echo "Requesting SSL certificates for custom service domains..."
    for domain in $CUSTOM_DOMAINS; do
        # Validate domain format (must contain at least one dot)
        if ! echo "$domain" | grep -qE '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
            echo "  ⚠ Skipping invalid domain: $domain"
            continue
        fi

        if [ ! -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
            echo "  Requesting certificate for: $domain"
            set +e
            # Get the most recent certbot account (highest timestamp)
            account_id=$(certbot accounts list 2>/dev/null | grep -oP '^\d+\s+\K\S+' | tail -1)

            certbot_output=$(certbot certonly \
                --webroot \
                --webroot-path "$CERTBOT_WEBROOT" \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                --non-interactive \
                --expand \
                $([ ! -z "$account_id" ] && echo "--account $account_id" || echo "") \
                $([ "$DASHBOARD_TEST" = "true" ] && echo "--staging" || echo "") \
                -d "$domain" 2>&1)
            certbot_status=$?
            set -e

            if [ $certbot_status -eq 0 ]; then
                echo "    ✓ Certificate requested successfully"
            else
                echo "    ⚠ Certificate request status: $certbot_status"
                echo "    Output: $certbot_output" | head -5
            fi
        else
            echo "  ✓ Certificate exists for: $domain"
        fi
    done
fi

echo ""
echo "=== Generated reverse-proxy.conf ==="
cat /etc/apache2/sites-available/reverse-proxy.conf
echo "===================================="
echo ""
apache2ctl configtest || {
    echo "Apache configuration error!"
    exit 1
}

echo "=== Starting Node.js API Proxy ==="
cd /opt/proxy
node proxy.js &
PROXY_PID=$!
echo "✓ API Proxy started (PID: $PROXY_PID)"

echo "=== Starting Apache ==="

# Trap signals to gracefully shut down cron, proxy, and Apache
trap 'echo "Shutting down..."; service cron stop 2>/dev/null; kill ${PROXY_PID} 2>/dev/null; kill ${APACHE_PID} 2>/dev/null; wait ${APACHE_PID} 2>/dev/null; exit 0' SIGTERM SIGINT

# Start Apache in foreground and capture PID
apache2ctl -D FOREGROUND &
APACHE_PID=$!

# Wait for Apache process and check if it exits unexpectedly
wait ${APACHE_PID}
APACHE_EXIT=$?

# If Apache exited with error, show diagnostic info
if [ $APACHE_EXIT -ne 0 ]; then
    echo ""
    echo "========================================="
    echo "APACHE STARTUP FAILED (Exit code: $APACHE_EXIT)"
    echo "========================================="
    echo ""
    echo "=== Apache Error Log ==="
    cat /var/log/apache2/error.log 2>/dev/null || echo "(No error log found)"
    echo ""
    echo "=== Apache Access Log ==="
    tail -20 /var/log/apache2/access.log 2>/dev/null || echo "(No access log found)"
    echo ""
    echo "=== Generated Reverse Proxy Config ==="
    cat /etc/apache2/sites-available/reverse-proxy.conf 2>/dev/null || echo "(Config not found)"
    echo ""
    echo "=== Service VirtualHost Configs ==="
    ls -la /etc/apache2/sites-available/*-vhost.conf 2>/dev/null || echo "(No service VirtualHosts found)"
    echo ""
    echo "=== Available Config Files ==="
    ls -la /etc/apache2/conf-available/ | grep -E "emby|plex|seerr|google|entra" || echo "(No relevant configs found)"
    echo ""
    echo "========================================="
    echo "Container will keep running for debugging."
    echo "Check logs above for errors."
    echo "========================================="
    echo ""

    # Keep container running so you can debug
    while true; do
        sleep 300
        echo "[$(date)] Container still running - waiting for you to debug..."
    done
fi

# Display YAHLP release version
if [ -f /app/VERSION ]; then
    YAHLP_VERSION=$(cat /app/VERSION)
    echo ""
    echo "========================================="
    echo "✓ YAHLP Release: $YAHLP_VERSION"
    echo "========================================="
fi


