#!/bin/bash

# Debug logging helper - only output if DEBUG=true
log_debug() {
    if [ "$DEBUG" = "true" ]; then
        echo "$@" >&2
    fi
    return 0
}

# Generate HTML Menu Based on Enabled Services
# Uses index.html.template with dynamic service icons
# Organized in same categories as React dashboard

# Source environment variables from config file written by entrypoint
if [ -f /etc/apache2/env.conf ]; then
    source /etc/apache2/env.conf
fi

# Function to find custom icon (checks for <name>-custom.* with any extension)
get_icon_path() {
    local icon_name=$1
    local default_path=$2

    # Check for custom icon with any extension
    for custom_icon in "/var/www/html/icons/${icon_name}-custom".*; do
        if [ -f "$custom_icon" ]; then
            local ext="${custom_icon##*.}"
            echo "/icons/${icon_name}-custom.${ext}"
            return 0
        fi
    done

    # Fall back to default path
    echo "$default_path"
}

# Function to get service icon path (checks for custom icon first, then default)
get_service_icon_path() {
    local service_key=$1
    local default_icon_path=$2

    local service_path=$(echo "$service_key" | tr '[:upper:]' '[:lower:]')

    # Check for custom icon with any extension
    for custom_icon in "/var/www/html/icons/${service_path}-custom".*; do
        if [ -f "$custom_icon" ]; then
            local ext="${custom_icon##*.}"
            echo "/icons/${service_path}-custom.${ext}"
            return 0
        fi
    done

    # Fall back to default
    echo "$default_icon_path"
}

# Determine dashboard icon path - use custom version if it exists, otherwise use default
DASHBOARD_ICON_PATH=$(get_icon_path "dashboard" "/icons/yahlp.png")

SITES_JSON="/etc/yahlp/yahlp.sites.json"
SITES_DIR="/etc/yahlp"

# Function to generate sites array for JavaScript
generate_sites_array() {
    if [ ! -f "$SITES_JSON" ] || [ -z "$SITES_ENABLED" ]; then
        echo "[]"
        return
    fi

    if ! command -v jq &> /dev/null; then
        echo "[]"
        return
    fi

    local sites_array="["
    local first=true

    # Parse SITES_ENABLED and generate array for each enabled site
    IFS=',' read -ra CODES <<< "$SITES_ENABLED"
    for code in "${CODES[@]}"; do
        code=$(echo "$code" | xargs)  # Trim whitespace

        # Extract site data from sites.json using jq with safe argument passing
        site_json=$(jq --arg code "$code" '.sites[]? | select(.code == $code)' "$SITES_JSON" 2>/dev/null)
        if [ -z "$site_json" ]; then
            continue
        fi

        url=$(echo "$site_json" | jq -r '.url // empty' 2>/dev/null)
        name=$(echo "$site_json" | jq -r '.name // empty' 2>/dev/null)
        icon=$(echo "$site_json" | jq -r '.icon // empty' 2>/dev/null)

        if [ -z "$url" ]; then
            continue
        fi

        # Use icon from JSON if provided, otherwise fall back to file lookup
        if [ -z "$icon" ]; then
            # Check for favicon files
            for ext in ico jpg jpeg png svg gif webp; do
                if [ -f "$SITES_DIR/${code,,}.favicon.$ext" ]; then
                    icon="/sites/${code,,}.favicon.$ext"
                    break
                fi
            done

            if [ -z "$icon" ]; then
                for ext in ico jpg jpeg png svg gif webp; do
                    if [ -f "/var/www/html/sites-icons/${code,,}.favicon.$ext" ]; then
                        icon="/sites/${code,,}.favicon.$ext"
                        break
                    fi
                done
            fi

            if [ -z "$icon" ]; then
                icon="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Crect fill='%23666' width='16' height='16'/%3E%3C/svg%3E"
            fi
        fi

        if [ "$first" = false ]; then
            sites_array+=","
        fi
        first=false

        sites_array+="{id:'$code',name:'$name',href:'$url',icon:'$icon',popup:true}"
    done

    sites_array+="]"
    printf '%s' "$sites_array"
}

# Define all available services with metadata
# Format: SERVICE_KEY="Category|Name|Description|Icon|Href|Accent"
# Categories: USENET, TORRENTS, CONTENT, SEARCH, MEDIA
declare -A SERVICES=(
    # USENET category
    [SABNZBD]="USENET|SABnzbd|Usenet downloads|/icons/sabnzbd.png|/sabnzbd/|#f5c20f"
    [NZBGET]="USENET|NZBGet|Usenet downloads|/icons/nzbget.png|/nzbget/|#3da7e0"
    [NZBHYDRA]="USENET|NZBHydra|NZB indexer|/icons/nzbhydra.png|/nzbhydra/|#3e9c7d"

    # TORRENTS category
    [DELUGE]="TORRENTS|Deluge|Torrent client|/icons/deluge.png|/deluge/|#3aa3e0"
    [TRANSMISSION]="TORRENTS|Transmission|Torrents|/icons/transmission.png|/transmission/|#343434"
    [QBITTORRENT]="TORRENTS|qBittorrent|Torrent client|/icons/qbittorrent.png|/qbittorrent/|#3683b6"

    # CONTENT category
    [SONARR]="CONTENT|Sonarr|TV shows|/icons/sonarr.png|@@SONARR_LANDING@@|#3aa0e0"
    [RADARR]="CONTENT|Radarr|Movies|/icons/radarr.png|@@RADARR_LANDING@@|#febc2e"
    [LIDARR]="CONTENT|Lidarr|Music|/icons/lidarr.png|@@LIDARR_LANDING@@|#2ecd6f"
    [WHISPARR]="CONTENT|Whisparr|Adult content|/icons/whisparr.png|@@WHISPARR_LANDING@@|#ef7e30"

    # SEARCH category
    [SEERR]="SEARCH|Seerr|Requests|/icons/seerr.png|SUBDOMAIN|#00a4dc"
    [JACKETT]="SEARCH|Jackett|Indexer aggregator|/icons/jackett.png|SUBDOMAIN|#0d47a1"
    [PROWLARR]="SEARCH|Prowlarr|Indexer manager|/icons/prowlarr.png|/prowlarr/|#e8810e"
    [BAZARR]="SEARCH|Bazarr|Subtitles|/icons/bazarr.png|/bazarr/|#e91e63"

    # MEDIA category
    [EMBY]="MEDIA|Emby|Streaming|/icons/emby.png|SUBDOMAIN|#9146FF"
    [PLEX]="MEDIA|Plex|Streaming|/icons/plex.png|SUBDOMAIN|#e5a00d"
    [JELLYFIN]="MEDIA|Jellyfin|Streaming|/icons/jellyfin.png|/jellyfin/|#00a4dc"
    [TAUTULLI]="MEDIA|Tautulli|Analytics|/icons/tautulli.png|/tautulli/|#4a9eff"
    [MAINTAINERR]="MEDIA|Maintainerr|Media maintenance|/icons/maintainerr.png|/maintainerr/|#1e90ff"
)

# Substitute service landing page variables
# If DASHBOARD_LANDING is set, sync the corresponding service landing page
if [ ! -z "$DASHBOARD_LANDING" ]; then
    # Extract service name from DASHBOARD_LANDING (first path component)
    service_name=$(echo "$DASHBOARD_LANDING" | sed 's|^/||' | cut -d'/' -f1)

    case "$service_name" in
        sonarr)
            SONARR_LANDING="${SONARR_LANDING:-$DASHBOARD_LANDING}"
            ;;
        radarr)
            RADARR_LANDING="${RADARR_LANDING:-$DASHBOARD_LANDING}"
            ;;
        lidarr)
            LIDARR_LANDING="${LIDARR_LANDING:-$DASHBOARD_LANDING}"
            ;;
        whisparr)
            WHISPARR_LANDING="${WHISPARR_LANDING:-$DASHBOARD_LANDING}"
            ;;
    esac
fi

# Format hrefs to use "/" prefix for consistency
SONARR_LANDING="${SONARR_LANDING:-sonarr}"
RADARR_LANDING="${RADARR_LANDING:-radarr}"
LIDARR_LANDING="${LIDARR_LANDING:-lidarr}"
WHISPARR_LANDING="${WHISPARR_LANDING:-whisparr}"

# Ensure landing pages start with /
[[ ! "$SONARR_LANDING" =~ ^/ ]] && SONARR_LANDING="/$SONARR_LANDING"
[[ ! "$RADARR_LANDING" =~ ^/ ]] && RADARR_LANDING="/$RADARR_LANDING"
[[ ! "$LIDARR_LANDING" =~ ^/ ]] && LIDARR_LANDING="/$LIDARR_LANDING"
[[ ! "$WHISPARR_LANDING" =~ ^/ ]] && WHISPARR_LANDING="/$WHISPARR_LANDING"

# Ensure landing pages end with /
[[ ! "$SONARR_LANDING" =~ /$ ]] && SONARR_LANDING="$SONARR_LANDING/"
[[ ! "$RADARR_LANDING" =~ /$ ]] && RADARR_LANDING="$RADARR_LANDING/"
[[ ! "$LIDARR_LANDING" =~ /$ ]] && LIDARR_LANDING="$LIDARR_LANDING/"
[[ ! "$WHISPARR_LANDING" =~ /$ ]] && WHISPARR_LANDING="$WHISPARR_LANDING/"

# Update SERVICES array with actual landing page values
SERVICES[SONARR]="CONTENT|Sonarr|TV shows|/icons/sonarr.png|$SONARR_LANDING|#3aa0e0"
SERVICES[RADARR]="CONTENT|Radarr|Movies|/icons/radarr.png|$RADARR_LANDING|#febc2e"
SERVICES[LIDARR]="CONTENT|Lidarr|Music|/icons/lidarr.png|$LIDARR_LANDING|#2ecd6f"
SERVICES[WHISPARR]="CONTENT|Whisparr|Adult content|/icons/whisparr.png|$WHISPARR_LANDING|#ef7e30"

# Scan for additional service configurations
log_debug "[Apps] Scanning for additional service configurations..."
ADDITIONAL_APPS=()
declare -A SERVICE_OVERRIDES  # Per-service dashboard setting overrides
declare -A SERVICE_APPNAMES   # Per-service display name overrides
ADDITIONAL_CONF_DIR="/etc/yahlp/additional-conf"
log_debug "[Apps] Directory: $ADDITIONAL_CONF_DIR"
if [ -d "$ADDITIONAL_CONF_DIR" ]; then
    log_debug "[Apps] Directory exists, scanning for *.conf files..."
    for conf_file in "$ADDITIONAL_CONF_DIR"/*.conf; do
        log_debug "[Apps] Found file: $conf_file"
        if [ -f "$conf_file" ]; then
            filename=$(basename "$conf_file")
            log_debug "[Apps] Processing: $filename"

            # Skip example files
            if [[ "$filename" == *"example"* ]]; then
                log_debug "[Apps] Skipping (example): $filename"
                continue
            fi

            # Skip vhost files (not added to menu)
            if [[ "$filename" == *"vhost"* ]]; then
                log_debug "[Apps] Skipping (vhost): $filename"
                continue
            fi

            # Only process 3-4 letter service codes
            code=$(basename "$conf_file" .conf)
            log_debug "[Apps] Code: $code"
            if [[ "$code" =~ ^[a-zA-Z]{3,4}$ ]]; then
                log_debug "[Apps] Code matches pattern!"
                app_code="$code"
                app_icon="/sites-icons/${app_code,,}.png"
                app_key="${app_code^^}"  # Convert to uppercase for array key

                # Check if icon file exists (check both locations)
                icon_file="/etc/yahlp/service_icons/${app_code,,}.png"
                if [ ! -f "$icon_file" ]; then
                    # Try sites-icons as fallback
                    icon_file="/etc/yahlp/sites-icons/${app_code,,}.png"
                fi

                if [ ! -f "$icon_file" ]; then
                    log_debug "[Apps] WARNING: Icon not found for $app_code"
                    log_debug "[Apps]   Checked: /etc/yahlp/service_icons/${app_code,,}.png"
                    log_debug "[Apps]   Checked: /etc/yahlp/sites-icons/${app_code,,}.png"
                    log_debug "[Apps] Skipping service (icon required)"
                    continue
                fi

                # Get friendly name from code
                app_name=$(echo "$app_code" | sed 's/^\(.\)/\U\1/' | tr '[:upper:]' '[:lower:]' | sed 's/^\(.\)/\U\1/')

                # Extract href from <Location> directive in the config file
                app_href=$(grep -oP '(?<=<Location\s)[^\s>]*' "$conf_file" | head -1)
                # Remove quotes if present
                app_href="${app_href%\"}"
                app_href="${app_href#\"}"
                if [ -z "$app_href" ]; then
                    app_href="/${app_code,,}/"
                    log_debug "[Apps] No Location directive found, using default href: $app_href"
                else
                    log_debug "[Apps] Extracted href from config: $app_href"
                fi

                # Extract per-service settings from comments
                # #DASHBOARD_WINDOW=embed or #DASHBOARD_WINDOW=popout
                app_dashboard_window=$(grep -i 'DASHBOARD_WINDOW' "$conf_file" | sed 's/^[[:space:]]*#*[[:space:]]*//' | sed 's/DASHBOARD_WINDOW[[:space:]]*=[[:space:]]*//' | head -1 | tr -d ' ')
                if [ ! -z "$app_dashboard_window" ]; then
                    echo "[Apps] ✓ Found window setting for $app_key: DASHBOARD_WINDOW=$app_dashboard_window" >&2
                    SERVICE_OVERRIDES[$app_key]="$app_dashboard_window"
                fi

                # #APPNAME=Tdarr or similar
                app_display_name=$(grep -i 'APPNAME' "$conf_file" | sed 's/^[[:space:]]*#*[[:space:]]*//' | sed 's/APPNAME[[:space:]]*=[[:space:]]*//' | head -1)
                if [ ! -z "$app_display_name" ]; then
                    echo "[Apps] ✓ Found app name for $app_key: APPNAME=$app_display_name" >&2
                    SERVICE_APPNAMES[$app_key]="$app_display_name"
                    app_name="$app_display_name"
                fi

                # Add to additional apps array
                ADDITIONAL_APPS+=("$app_key")

                # Add to SERVICES array with custom app metadata
                # Format: SERVICE_KEY="CUSTOM|Name|Description|Icon|Href|Accent"
                app_icon="/icons/${app_code,,}.png"
                SERVICES[$app_key]="CUSTOM|$app_name|Custom application|$app_icon|$app_href|#6366f1"

                log_debug "[Apps] Found additional service: $app_key (icon: $icon_file)"
            fi
        fi
    done
fi

# Scan vhost files for dashboard-visible services
echo "[Apps] Scanning for dashboard-visible vhost services..."
ADDITIONAL_VHOST_DIR="/etc/yahlp/additional-vhost"
if [ -d "$ADDITIONAL_VHOST_DIR" ]; then
    echo "[Apps] Found vhost directory: $ADDITIONAL_VHOST_DIR"
    vhost_count=0
    for vhost_file in "$ADDITIONAL_VHOST_DIR"/*.conf; do
        if [ -f "$vhost_file" ]; then
            filename=$(basename "$vhost_file")
            echo "[Apps] Processing vhost file: $filename"

            # Skip example files
            if [[ "$filename" == *"example"* ]]; then
                echo "[Apps] ✗ Skipping $filename - example file"
                continue
            fi

            # Extract DASHBOARD_CODE (3-letter code)
            vhost_dashboard_code=$(grep -i 'DASHBOARD_CODE' "$vhost_file" | sed 's/^[[:space:]]*#*[[:space:]]*//' | sed 's/DASHBOARD_CODE[[:space:]]*=[[:space:]]*//' | head -1 | tr -d ' ')
            echo "[Apps] DASHBOARD_CODE for $filename: '$vhost_dashboard_code'"

            if [ -z "$vhost_dashboard_code" ]; then
                echo "[Apps] ✗ Skipping $filename - no DASHBOARD_CODE found"
                continue
            fi

            # Extract DASHBOARD_VISIBLE
            vhost_dashboard_visible=$(grep -i 'DASHBOARD_VISIBLE' "$vhost_file" | sed 's/^[[:space:]]*#*[[:space:]]*//' | sed 's/DASHBOARD_VISIBLE[[:space:]]*=[[:space:]]*//' | head -1 | tr -d ' ')
            echo "[Apps] DASHBOARD_VISIBLE for $filename: '$vhost_dashboard_visible'"

            if [ "$vhost_dashboard_visible" != "true" ]; then
                echo "[Apps] ✗ Skipping $filename - DASHBOARD_VISIBLE is not true"
                continue
            fi

            # Extract optional settings
            vhost_appname=$(grep -i 'APPNAME' "$vhost_file" | sed 's/^[[:space:]]*#*[[:space:]]*//' | sed 's/APPNAME[[:space:]]*=[[:space:]]*//' | head -1)
            vhost_dashboard_window=$(grep -i 'DASHBOARD_WINDOW' "$vhost_file" | sed 's/^[[:space:]]*#*[[:space:]]*//' | sed 's/DASHBOARD_WINDOW[[:space:]]*=[[:space:]]*//' | head -1 | tr -d ' ')

            # Defaults
            [ -z "$vhost_appname" ] && vhost_appname="$(echo $vhost_dashboard_code | tr '[:lower:]' '[:upper:]')"
            [ -z "$vhost_dashboard_window" ] && vhost_dashboard_window="popout"

            # Look for icon file
            vhost_icon_file=""
            vhost_icon="/icons/${vhost_dashboard_code}.png"
            if [ -f "/etc/yahlp/service_icons/${vhost_dashboard_code}.png" ]; then
                vhost_icon="/icons/${vhost_dashboard_code}.png"
                vhost_icon_file="/etc/yahlp/service_icons/${vhost_dashboard_code}.png"
                echo "[Apps] ✓ Found icon: $vhost_icon_file"
            elif [ -f "/etc/yahlp/service_icons/${vhost_dashboard_code}.svg" ]; then
                vhost_icon="/icons/${vhost_dashboard_code}.svg"
                vhost_icon_file="/etc/yahlp/service_icons/${vhost_dashboard_code}.svg"
                echo "[Apps] ✓ Found icon: $vhost_icon_file"
            else
                echo "[Apps] ⚠ No icon found for ${vhost_dashboard_code}"
            fi

            # Extract ServerName from VirtualHost directive (href)
            vhost_server_name=$(grep -i 'ServerName' "$vhost_file" | head -1 | sed 's/^[[:space:]]*ServerName[[:space:]]*//' | tr -d ' ')
            echo "[Apps] ServerName for $filename: '$vhost_server_name'"

            if [ -z "$vhost_server_name" ]; then
                echo "[Apps] ✗ Skipping $filename - no ServerName found"
                continue
            fi

            # Build href (https if public, http if private)
            vhost_href="https://${vhost_server_name}/"

            # Store settings with uppercase key to match service_key lookup
            vhost_app_key="${vhost_dashboard_code^^}"
            SERVICE_OVERRIDES["$vhost_app_key"]="$vhost_dashboard_window"
            SERVICE_APPNAMES["$vhost_app_key"]="$vhost_appname"

            # Add to additional apps array
            ADDITIONAL_APPS+=("$vhost_app_key")

            # Check for matching JSON5 metrics file in additional-vhost
            vhost_json5_file="/etc/yahlp/additional-vhost/${vhost_dashboard_code,,}.json5"

            # Add to SERVICES array - mark as CUSTOM_VHOST so it can be handled as dynamic service
            # Format: category|name|desc|icon|href|accent|json5_file_path
            # If JSON5 file exists, include its path so metrics can be extracted at render time
            if [ -f "$vhost_json5_file" ]; then
                SERVICES[$vhost_app_key]="CUSTOM_VHOST|$vhost_appname|Custom vhost|$vhost_icon|$vhost_href|#6366f1|$vhost_json5_file"
                log_debug "[Apps] Vhost $vhost_dashboard_code will load metrics from $vhost_json5_file"
            else
                SERVICES[$vhost_app_key]="CUSTOM_VHOST|$vhost_appname|Custom vhost|$vhost_icon|$vhost_href|#6366f1"
            fi

            echo "[Apps] ✓ Added vhost to menu: ${vhost_dashboard_code} (${vhost_appname}) → ${vhost_href}"
            ((vhost_count++)) || true
        fi
    done
    echo "[Apps] Found $vhost_count dashboard-visible vhost(s)"
else
    echo "[Apps] Vhost directory not found: $ADDITIONAL_VHOST_DIR"
fi

# Scan JSON5 files for dynamic services (in both directories)
# additional-conf: full service definitions
# additional-vhost: metrics metadata, only create service if no vhost exists
echo "[Apps] Scanning for JSON5 service configurations..."
JSON5_COUNT=0
for json_dir in "/etc/yahlp/additional-conf" "/etc/yahlp/additional-vhost"; do
    if [ -d "$json_dir" ]; then
        for json_file in "$json_dir"/*.json5; do
            if [ -f "$json_file" ]; then
                filename=$(basename "$json_file")
                echo "[Apps] Processing JSON5: $filename"

                # Extract service name and config using grep/sed (basic JSON5 parsing)
                service_name=$(grep "service\s*:" "$json_file" | sed "s/.*service\s*:\s*['\"]//;s/['\"].*//" | head -1)
                app_name=$(grep "name\s*:" "$json_file" | sed "s/.*name\s*:\s*['\"]//;s/['\"].*//" | head -1)
                app_icon=$(grep "icon\s*:" "$json_file" | sed "s/.*icon\s*:\s*['\"]//;s/['\"].*//" | head -1)

                if [ -z "$service_name" ] || [ -z "$app_name" ]; then
                    echo "[Apps] ✗ Skipping $filename - missing service name or app name"
                    continue
                fi

                # Use uppercase service name as key
                app_key="${service_name^^}"

                # Use icon if provided, otherwise use service name
                if [ -z "$app_icon" ]; then
                    app_icon="${service_name}.png"
                fi

                app_icon_path="/icons/${app_icon}"

                # Check if icon exists
                if [ ! -f "/etc/yahlp/service_icons/${app_icon}" ]; then
                    echo "[Apps] ⚠ Warning: Icon not found for ${service_name} (${app_icon})"
                fi

                # Add to additional apps array and SERVICES (but don't overwrite existing vhost services)
                # Check if service already exists (from a vhost)
                if [ -z "${SERVICES[$app_key]}" ]; then
                    ADDITIONAL_APPS+=("$app_key")
                    # JSON5 services - store for later processing with full config
                    SERVICES[$app_key]="JSON5|$app_name|Custom service|$app_icon_path|/${service_name}/|#6366f1|$json_file"
                    echo "[Apps] ✓ Added JSON5 service: ${app_key} (${app_name}) from $json_file"
                    ((JSON5_COUNT++)) || true
                else
                    echo "[Apps] ⓘ JSON5 metrics for $app_name found (service exists from vhost)"
                fi
            fi
        done
    fi
done
echo "[Apps] Found $JSON5_COUNT JSON5 service(s)"

# Service display order (same order for both menus)
declare -a SERVICE_ORDER=(
    # USENET
    "SABNZBD" "NZBGET" "NZBHYDRA"
    # TORRENTS
    "DELUGE" "TRANSMISSION" "QBITTORRENT"
    # CONTENT
    "SONARR" "RADARR" "LIDARR" "WHISPARR"
    # SEARCH
    "SEERR" "JACKETT" "PROWLARR" "BAZARR"
    # MEDIA
    "EMBY" "PLEX" "JELLYFIN" "TAUTULLI" "MAINTAINERR"
)

# Add additional apps to the end of SERVICE_ORDER
if [ ${#ADDITIONAL_APPS[@]} -gt 0 ]; then
    log_debug "[Apps] Adding ${#ADDITIONAL_APPS[@]} additional app(s) to menu"
    SERVICE_ORDER+=("${ADDITIONAL_APPS[@]}")
    log_debug "[Apps] SERVICE_ORDER now has ${#SERVICE_ORDER[@]} total services"
fi

# Service code to service key mapping
declare -A SERVICE_CODE_MAP=(
    [SAB]="SABNZBD"
    [GET]="NZBGET"
    [HYD]="NZBHYDRA"
    [JAC]="JACKETT"
    [TRA]="TRANSMISSION"
    [QBI]="QBITTORRENT"
    [DEL]="DELUGE"
    [SON]="SONARR"
    [RAD]="RADARR"
    [LID]="LIDARR"
    [WHI]="WHISPARR"
    [PRO]="PROWLARR"
    [SEE]="SEERR"
    [BAZ]="BAZARR"
    [JEL]="JELLYFIN"
    [EMB]="EMBY"
    [PLX]="PLEX"
    [TAU]="TAUTULLI"
    [MNT]="MAINTAINERR"
)

# Generate services array respecting DASHBOARD_ORDER (with categories)
generate_services_array() {
    local array=""
    local first=true
    local order_array=()
    local services_count=0

    # Use DASHBOARD_ORDER if provided, otherwise use SERVICE_ORDER
    if [ ! -z "$DASHBOARD_ORDER" ]; then
        log_debug "[Menu] Using DASHBOARD_ORDER: $DASHBOARD_ORDER"
        # Parse DASHBOARD_ORDER (service codes format: SAB,GET,HYD,etc + SEP for separators)
        IFS=',' read -ra codes <<< "$DASHBOARD_ORDER"
        for code in "${codes[@]}"; do
            code=$(echo "$code" | xargs)
            log_debug "[Menu] Processing code: $code"
            # Handle labeled separators (LBL:Label)
            if [[ "$code" =~ ^LBL: ]]; then
                order_array+=("$code")
                log_debug "[Menu] Added separator: $code"
            else
                code=$(echo "$code" | tr '[:lower:]' '[:upper:]')
                log_debug "[Menu] Converted to uppercase: $code"
                # Handle separator markers (SEP=invisible gap, VIS=visible line)
                if [ "$code" = "SEP" ] || [ "$code" = "VIS" ]; then
                    order_array+=("$code")
                    log_debug "[Menu] Added marker: $code"
                elif [ -n "${SERVICE_CODE_MAP[$code]}" ]; then
                    # Service found in built-in code map
                    order_array+=("${SERVICE_CODE_MAP[$code]}")
                    log_debug "[Menu] Added from CODE_MAP: $code → ${SERVICE_CODE_MAP[$code]}"
                elif [ -n "${SERVICES[$code]}" ]; then
                    # Service is an additional/custom service (use code as key directly)
                    order_array+=("$code")
                    log_debug "[Menu] Added from SERVICES: $code"
                else
                    log_debug "[Menu] NOT FOUND: $code (not in CODE_MAP or SERVICES)"
                fi
            fi
        done
    else
        log_debug "[Menu] Using default SERVICE_ORDER (no DASHBOARD_ORDER)"
        order_array=("${SERVICE_ORDER[@]}")
    fi

    # Always add any additional services that aren't already in the order array
    # This ensures vhost and JSON5 services are included even with DASHBOARD_ORDER
    if [ ${#ADDITIONAL_APPS[@]} -gt 0 ]; then
        log_debug "[Menu] Checking if additional apps are in order array..."
        for app in "${ADDITIONAL_APPS[@]}"; do
            # Check if this app is already in order_array
            found=false
            for item in "${order_array[@]}"; do
                if [ "$item" = "$app" ]; then
                    found=true
                    log_debug "[Menu] $app already in order array"
                    break
                fi
            done
            # If not found, add it to the end
            if [ "$found" = false ]; then
                order_array+=("$app")
                log_debug "[Menu] Added $app to end of order array"
            fi
        done
        log_debug "[Menu] Final order array has ${#order_array[@]} services: ${order_array[@]}"
    fi

    for service_key in "${order_array[@]}"; do
        # Handle labeled separators (LBL:Label)
        if [[ "$service_key" =~ ^LBL: ]]; then
            local label="${service_key#LBL:}"
            if [ "$first" = true ]; then
                first=false
            else
                array+=",$( printf '\n    ')"
            fi
            array+="{ id: 'LBL', name: '$label', desc: '', icon: '', href: '', accent: '', popup: false }"
            continue
        fi

        # Handle separator markers (SEP=invisible, VIS=visible)
        if [ "$service_key" = "SEP" ] || [ "$service_key" = "VIS" ]; then
            # Add separator object
            if [ "$first" = true ]; then
                first=false
            else
                array+=",$( printf '\n    ')"
            fi
            array+="{ id: '$service_key', name: '', desc: '', icon: '', href: '', accent: '', popup: false }"
            continue
        fi

        # Parse service metadata (format: category|name|desc|icon|href|accent[|json5_file])
        # Need to handle pipes carefully since json5_file path might contain pipes
        local service_data="${SERVICES[$service_key]}"
        local IFS_OLD="$IFS"
        IFS='|'
        read -r category name desc icon href accent json5_file <<< "$service_data"
        IFS="$IFS_OLD"

        # Check for per-service appname override (from #APPNAME= in conf file)
        local appname="${SERVICE_APPNAMES[$service_key]}"
        if [ -z "$appname" ]; then
            appname="$name"
        fi

        # Check if service is enabled
        # CUSTOM and CUSTOM_VHOST services are always enabled (they're already in additional-conf/additional-vhost)
        if [ "$category" != "CUSTOM" ] && [ "$category" != "CUSTOM_VHOST" ]; then
            local enable_var="ENABLE_${service_key}"
            local is_enabled="${!enable_var}"

            # Skip disabled built-in services
            if [ "$is_enabled" != "true" ]; then
                continue
            fi
        fi

        # Find the 3-letter code for this service key
        local id=""
        if [ "$category" = "CUSTOM" ] || [ "$category" = "CUSTOM_VHOST" ]; then
            # For custom services, use lowercase app code as id
            id="${service_key,,}"
        else
            # For built-in services, look up the code mapping
            for code in "${!SERVICE_CODE_MAP[@]}"; do
                if [ "${SERVICE_CODE_MAP[$code]}" = "$service_key" ]; then
                    id="$code"
                    break
                fi
            done
        fi

        # Check for custom icon version
        icon=$(get_service_icon_path "$service_key" "$icon")

        # MEDIA services: use DOMAIN in public mode, URL in private mode
        if [ "$category" = "MEDIA" ]; then
            if [ "$ACCESS_MODE" = "public" ]; then
                # Public mode: use subdomains if configured
                case "$service_key" in
                    EMBY)
                        if [ ! -z "$EMBY_DOMAIN" ]; then
                            href="https://$EMBY_DOMAIN/"
                        else
                            [ -z "$EMBY_URL" ] && continue
                            href="$EMBY_URL"
                        fi
                        ;;
                    PLEX)
                        if [ ! -z "$PLEX_DOMAIN" ]; then
                            href="https://$PLEX_DOMAIN/"
                        else
                            [ -z "$PLEX_URL" ] && continue
                            href="$PLEX_URL"
                        fi
                        ;;
                esac
            else
                # Private mode: use internal URLs
                case "$service_key" in
                    EMBY)
                        [ -z "$EMBY_URL" ] && continue
                        href="$EMBY_URL"
                        ;;
                    PLEX)
                        [ -z "$PLEX_URL" ] && continue
                        href="$PLEX_URL"
                        ;;
                esac
            fi
        elif [ "$href" = "SUBDOMAIN" ]; then
            # Handle other subdomain services (shouldn't reach here for MEDIA)
            if [ "$service_key" = "EMBY" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$EMBY_DOMAIN" ]; then
                    href="https://$EMBY_DOMAIN/"
                else
                    [ -z "$EMBY_URL" ] && continue
                    href="$EMBY_URL"
                fi
            elif [ "$service_key" = "PLEX" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$PLEX_DOMAIN" ]; then
                    href="https://$PLEX_DOMAIN/"
                else
                    [ -z "$PLEX_URL" ] && continue
                    href="$PLEX_URL"
                fi
            elif [ "$service_key" = "SEERR" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$SEERR_DOMAIN" ]; then
                    href="https://$SEERR_DOMAIN/"
                else
                    [ -z "$SEERR_URL" ] && continue
                    href="$SEERR_URL"
                fi
            elif [ "$service_key" = "JACKETT" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$JACKETT_DOMAIN" ]; then
                    href="https://$JACKETT_DOMAIN/"
                else
                    [ -z "$JACKETT_URL" ] && continue
                    href="$JACKETT_URL"
                fi
            fi
        fi

        # Determine if popup (window_method controls how it opens)
        local popup="false"
        local window_method="${DASHBOARD_WINDOWS:-popout}"

        # Check for per-service override (#DASHBOARD_WINDOW=embed or popout in conf file)
        local service_override="${SERVICE_OVERRIDES[$service_key]}"

        # CUSTOM and CUSTOM_VHOST services: default to popup=true unless explicitly set to embed
        if [ "$category" = "CUSTOM" ] || [ "$category" = "CUSTOM_VHOST" ]; then
            if [ "$service_override" = "embed" ]; then
                popup="false"
                window_method=""
            else
                # Default or "popout" = popup using DASHBOARD_WINDOWS method
                popup="true"
                window_method="${DASHBOARD_WINDOWS:-popout}"
            fi
        # Built-in services: use per-service override if set
        elif [ ! -z "$service_override" ]; then
            if [ "$service_override" = "embed" ]; then
                popup="false"
                window_method=""
            else
                popup="true"
                window_method="${DASHBOARD_WINDOWS:-popout}"
            fi
        else
            # Default behavior for built-in services if no per-service override
            [[ "$href" == http* ]] && popup="true"
            [[ "$service_key" == "QBITTORRENT" ]] && popup="true"
            # MEDIA services open as popup only if they're external (http) or SUBDOMAIN
            if [ "$category" = "MEDIA" ] && [[ "$href" != /* ]]; then
                popup="true"
            fi
        fi

        # Add comma between items (with newline for readability)
        if [ "$first" = true ]; then
            first=false
        else
            array+=",$( printf '\n    ')"
        fi

        # Add service object with correct accent color and appname
        if [ "$category" = "JSON5" ] || [ "$category" = "CUSTOM" ] || [ "$category" = "CUSTOM_VHOST" ]; then
            # For JSON5 and custom/vhost services, add isDynamic flag (metrics fetched at runtime from proxy.js)
            local metrics_str=""
            if [ ! -z "$json5_file" ] && [ -f "$json5_file" ]; then
                # Extract metrics array from JSON5 file - look for dashboard.metrics array
                # This is a simplified extraction that works for standard JSON5 format
                metrics_str=$(sed -n '/dashboard\s*:\s*{/,/^[[:space:]]*}/p' "$json5_file" | \
                    sed -n '/metrics\s*:\s*\[/,/^\s*\]/p' | \
                    sed "s/^[[:space:]]*//;s/[[:space:]]*$//;s/'\"'\"/g" 2>/dev/null)

                if [ ! -z "$metrics_str" ]; then
                    # Convert from JSON5 to JSON (remove trailing commas, quote keys)
                    metrics_str=$(echo "$metrics_str" | sed "s/,\s*\]/]/g;s/,\s*}/}/g")
                    metrics_str=", metrics: $metrics_str"
                fi
            fi
            array+="{ id: '$id', name: '$name', appname: '$appname', desc: '$desc', icon: '$icon', href: '$href', accent: '$accent', popup: $popup, isDynamic: true$metrics_str }"
        else
            array+="{ id: '$id', name: '$name', appname: '$appname', desc: '$desc', icon: '$icon', href: '$href', accent: '$accent', popup: $popup }"
        fi
        ((services_count++))
    done

    # Debug: log enabled services count
    [ "$services_count" -gt 0 ] && log_debug "[Services] Enabled $services_count services"

    echo "[$array]"
}

# Generate CSS-based templates from master.template
# Auto-detects CSS files in built-in templates and user-mounted config/templates
generate_css_based_templates() {
    local MASTER_TEMPLATE="/var/www/html/master.template"
    local BUILTIN_STYLES="/var/www/html/styles"
    local BUILTIN_TEMPLATES="/var/www/html/templates"
    local USER_TEMPLATES="/etc/yahlp/templates"
    local services_array=$(generate_services_array)
    local sites_array=$(generate_sites_array)

    if [ ! -f "$MASTER_TEMPLATE" ]; then
        echo "Master template not found: $MASTER_TEMPLATE"
        return 1
    fi

    local layouts=()
    local template_count=0

    # Copy any custom config/templates CSS files to /var/www/html/styles for serving
    if [ -d "$USER_TEMPLATES" ] && [ -n "$(ls -A "$USER_TEMPLATES"/layout-*.css 2>/dev/null)" ]; then
        echo "📋 Found custom templates in config/templates..."
        cp "$USER_TEMPLATES"/layout-*.css "$BUILTIN_STYLES/" 2>/dev/null || true
        echo "  ✓ Custom templates from config/templates copied to styles/"
    fi

    # Scan built-in styles directory (layout-classic.css, layout-sleek.css, etc.)
    if [ -d "$BUILTIN_STYLES" ]; then
        echo "📁 Built-in styles: $BUILTIN_STYLES"
        while IFS= read -r -d '' css_file; do
            local layout_name=$(basename "$css_file" | sed 's/^layout-//' | sed 's/\.css$//')
            layouts+=("$layout_name")
            echo "  ✓ Found: layout-${layout_name}.css"
            ((template_count++))
        done < <(find "$BUILTIN_STYLES" -name "layout-*.css" -print0 2>/dev/null)
    fi

    # Filter layouts if STYLES_TO_BUILD is specified
    if [ ${#STYLES_TO_BUILD[@]} -gt 0 ]; then
        local filtered_layouts=()
        for style in "${STYLES_TO_BUILD[@]}"; do
            style=$(echo "$style" | xargs | tr '[:lower:]' '[:upper:]')
            for layout in "${layouts[@]}"; do
                if [ "$(echo "$layout" | tr '[:lower:]' '[:upper:]')" = "$style" ]; then
                    filtered_layouts+=("$layout")
                    break
                fi
            done
        done
        layouts=("${filtered_layouts[@]}")
    fi

    if [ ${#layouts[@]} -eq 0 ]; then
        echo "⚠️  No layout CSS files found! Generating defaults..."
        layouts=("classic" "sleek" "minimal" "focus")
    fi

    # Ensure mobile layout is always included
    local has_mobile=false
    for layout in "${layouts[@]}"; do
        if [ "$layout" = "mobile" ]; then
            has_mobile=true
            break
        fi
    done
    if [ "$has_mobile" = false ]; then
        layouts+=("mobile")
    fi

    # Separate core and custom layouts, sort alphabetically
    local core_layouts=()
    local custom_layouts=()
    local core_names=("classic" "modern" "sleek" "minimal" "mobile")

    for layout in "${layouts[@]}"; do
        local is_core=false
        for core in "${core_names[@]}"; do
            if [ "$layout" = "$core" ]; then
                is_core=true
                break
            fi
        done

        if [ "$is_core" = true ]; then
            core_layouts+=("$layout")
        else
            custom_layouts+=("$layout")
        fi
    done

    # Sort each group alphabetically
    IFS=$'\n' core_layouts=($(sort <<<"${core_layouts[*]}"))
    unset IFS
    IFS=$'\n' custom_layouts=($(sort <<<"${custom_layouts[*]}"))
    unset IFS

    # Combine: core first, then custom
    layouts=("${core_layouts[@]}" "${custom_layouts[@]}")

    echo ""
    echo "🎨 Generating ${#layouts[@]} template(s)..."

    # Generate JavaScript array of all available templates (sorted order)
    local templates_js="const AVAILABLE_TEMPLATES = ["
    local first=true
    for layout in "${layouts[@]}"; do
        if [ "$first" = true ]; then
            templates_js+="'$layout'"
            first=false
        else
            templates_js+=", '$layout'"
        fi
    done
    templates_js+="];"

    # Determine if style switcher should be locked (when :only is used)
    local dashboard_locked="false"
    if [[ "$STYLE_CONFIG" == *":only" ]]; then
        dashboard_locked="true"
    fi

    # Generate HTML for each layout
    for layout in "${layouts[@]}"; do
        # DASHBOARD_COLOR only applies to the built-in layouts. Custom layouts
        # render their own colors, so leave their --bg-secondary at the
        # base.css default instead of forcing this admin setting onto them.
        local dashboard_color_override=""
        case "$layout" in
            classic|modern|sleek|minimal|mobile)
                dashboard_color_override=":root { --bg-secondary: ${DASHBOARD_COLOR:-#1a1a1a}; }"
                ;;
        esac

        local html_content=$(cat "$MASTER_TEMPLATE")
        html_content="${html_content//@@TEMPLATE_TYPE@@/$layout}"
        html_content="${html_content//@@AVAILABLE_TEMPLATES@@/$templates_js}"
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@SITES_ARRAY@@/$sites_array}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
        html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        html_content="${html_content//@@DASHBOARD_COLOR_OVERRIDE@@/$dashboard_color_override}"
        html_content="${html_content//@@DASHBOARD_LOCKED@@/$dashboard_locked}"
        html_content="${html_content//@@DASHBOARD_WINDOWS@@/${DASHBOARD_WINDOWS:-popout}}"

        echo "$html_content" > "/var/www/html/${layout}.html"
        echo "  ✓ Generated ${layout}.html"
    done

    echo ""
    echo "✅ Built ${#layouts[@]} template(s)"
    echo ""
    echo "Available templates:"
    for layout in "${layouts[@]}"; do
        echo "  • http://localhost/${layout}.html"
    done

    # Generate index.html with default DASH_STYLE
    echo ""
    echo "📄 Generating index.html..."
    if [ -f "/var/www/html/index.template" ]; then
        local index_content=$(cat "/var/www/html/index.template")
        index_content="${index_content//@@DASH_STYLE@@/${DASH_STYLE:-classic}}"
        echo "$index_content" > "/var/www/html/index.html"
        echo "  ✓ Generated index.html (default: ${DASH_STYLE:-classic})"
    fi
}

# Main generation function
generate_html() {
    # Use DASHBOARD_STYLE if set, otherwise fall back to DASH_STYLE
    STYLE_CONFIG="${DASHBOARD_STYLE:-${DASH_STYLE:-classic}}"

    echo "Generating dashboards for DASHBOARD_STYLE=$STYLE_CONFIG..."
    echo ""

    # Count enabled services
    local count=0
    for service_key in "${SERVICE_ORDER[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((count++))
        fi
    done

    # Parse DASHBOARD_STYLE options
    # Format: "classic" (build all, use classic as default)
    #         "classic:only" (build only classic, lock to it)
    #         "classic,modern,sleek" (build only these, show only in slider)

    local STYLES_TO_BUILD=()
    local DEFAULT_STYLE=""

    if [[ "$STYLE_CONFIG" == *","* ]]; then
        # Comma-separated list: build only these styles
        IFS=',' read -ra STYLES_TO_BUILD <<< "$STYLE_CONFIG"
        DEFAULT_STYLE="${STYLES_TO_BUILD[0]}"
        echo "Building specific styles: ${STYLES_TO_BUILD[*]}"
    elif [[ "$STYLE_CONFIG" == *":only"* ]]; then
        # Single style with :only suffix: build only this, lock to it
        DEFAULT_STYLE="${STYLE_CONFIG%:only}"
        STYLES_TO_BUILD=("$DEFAULT_STYLE")
        echo "Style locked to: $DEFAULT_STYLE (style switcher disabled)"
    else
        # Single style: build all, use this as default
        DEFAULT_STYLE="$STYLE_CONFIG"
        echo "Building all styles, default: $DEFAULT_STYLE"
    fi

    # Generate CSS-based templates
    generate_css_based_templates

    # Update DirectoryIndex in reverse-proxy.conf based on built layouts
    local directory_index="$DEFAULT_STYLE.html"
    # Add other built layouts (excluding default and mobile)
    for layout in "${layouts[@]}"; do
        if [ "$layout" != "$DEFAULT_STYLE" ] && [ "$layout" != "mobile" ]; then
            directory_index="$directory_index $layout.html"
        fi
    done
    # Always include mobile at the end
    local has_mobile=false
    for layout in "${layouts[@]}"; do
        if [ "$layout" = "mobile" ]; then
            has_mobile=true
            break
        fi
    done
    if [ "$has_mobile" = false ]; then
        directory_index="$directory_index mobile.html"
    fi

    # Update DirectoryIndex in reverse-proxy.conf if it exists
    if [ -f /etc/apache2/sites-available/reverse-proxy.conf ]; then
        sed -i "s/DirectoryIndex .*/DirectoryIndex $directory_index/" /etc/apache2/sites-available/reverse-proxy.conf
        echo "Updated DirectoryIndex: $directory_index"
    fi

    echo ""
    echo "✓ Dashboards generated with $count enabled service(s)"
    echo ""
    echo "Available dashboards (Apache DirectoryIndex = $DEFAULT_STYLE.html):"
    echo "  /classic.html"
    echo "  /modern.html"
    echo "  /sleek.html"
    echo "  /minimal.html"
    echo "  /mobile.html"
    echo ""
    echo "Primary: /$DEFAULT_STYLE.html (via DirectoryIndex)"
}

# Run generation
generate_html







