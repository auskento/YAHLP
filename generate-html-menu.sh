#!/bin/bash

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

CLASSIC_TEMPLATE="/var/www/html/classic.template"
MODERN_TEMPLATE="/var/www/html/modern.template"
SLEEK_TEMPLATE="/var/www/html/sleek.template"
MINIMAL_TEMPLATE="/var/www/html/minimal.template"
MOBILE_TEMPLATE="/var/www/html/mobile.template"
SITES_JSON="/var/log/apache2/sites/sites.json"
SITES_DIR="/var/log/apache2/sites"

# Function to generate sites HTML
generate_sites_html() {
    local sites_html=""

    if [ ! -f "$SITES_JSON" ]; then
        return
    fi

    if [ -z "$SITES_ENABLED" ]; then
        return
    fi

    # Parse SITES_ENABLED and generate HTML for each enabled site
    IFS=',' read -ra CODES <<< "$SITES_ENABLED"
    for code in "${CODES[@]}"; do
        code=$(echo "$code" | xargs)  # Trim whitespace

        # Extract site URL from sites.json using grep/sed
        url=$(grep -A 3 "\"code\": \"$code\"" "$SITES_JSON" | grep "\"url\"" | sed 's/.*"url": "\(.*\)".*/\1/')
        name=$(grep -A 2 "\"code\": \"$code\"" "$SITES_JSON" | grep "\"name\"" | sed 's/.*"name": "\(.*\)".*/\1/')

        if [ ! -z "$url" ]; then
            # Check for favicon in sites directory with multiple formats
            favicon_url=""
            favicon_file=""

            # Check primary sites directory (/var/log/apache2/sites/) - try multiple formats
            for ext in ico jpg jpeg png svg gif webp; do
                if [ -f "$SITES_DIR/${code,,}.favicon.$ext" ]; then
                    favicon_file="$SITES_DIR/${code,,}.favicon.$ext"
                    favicon_url="/sites/${code,,}.favicon.$ext"
                    break
                fi
            done

            # Check html/sites-icons (pre-cached in image) if not found
            if [ -z "$favicon_url" ]; then
                for ext in ico jpg jpeg png svg gif webp; do
                    if [ -f "/var/www/html/sites-icons/${code,,}.favicon.$ext" ]; then
                        favicon_url="/sites/${code,,}.favicon.$ext"
                        break
                    fi
                done
            fi

            # Use placeholder if no favicon found
            if [ -z "$favicon_url" ]; then
                favicon_url="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Crect fill='%23666' width='16' height='16'/%3E%3C/svg%3E"
            fi

            # Include site (all on one line to avoid bash parameter expansion issues)
            sites_html+="<a href='$url' class='site-link' title='$name' target='_blank'><div class='site-icon'><img src='$favicon_url' alt='$name' /></div></a>"
        fi
    done

    # Output on single line to prevent bash parameter expansion issues
    printf '%s' "$sites_html"
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

# Service display order (same order for both menus)
declare -a SERVICE_ORDER=(
    # USENET
    "SABNZBD" "NZBGET" "NZBHYDRA"
    # TORRENTS
    "DELUGE" "TRANSMISSION" "QBITTORRENT"
    # CONTENT
    "SONARR" "RADARR" "LIDARR" "WHISPARR"
    # SEARCH
    "SEERR" "PROWLARR" "BAZARR"
    # MEDIA
    "EMBY" "PLEX" "JELLYFIN" "TAUTULLI" "MAINTAINERR"
)

# Service code to service key mapping
declare -A SERVICE_CODE_MAP=(
    [SAB]="SABNZBD"
    [GET]="NZBGET"
    [HYD]="NZBHYDRA"
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

# Category labels
declare -A CATEGORY_LABEL=(
    [USENET]="USENET"
    [TORRENTS]="TORRENTS"
    [CONTENT]="CONTENT"
    [SEARCH]="SEARCH"
    [MEDIA]="MEDIA"
)

# Generate group order from DASHBOARD_ORDER variable (service codes version)
generate_group_order() {
    local dash_order="${DASHBOARD_ORDER:-SAB,GET,HYD,TRA,QBI,DEL,SON,RAD,LID,WHI,PRO,SEE,BAZ,JEL,EMB,PLX,TAU,MNT}"
    local items=()

    # Split by comma and pass service codes as-is (no conversion)
    IFS=',' read -ra codes <<< "$dash_order"

    for code in "${codes[@]}"; do
        code=$(echo "$code" | xargs | tr '[:lower:]' '[:upper:]')
        items+=("'$code'")
    done

    # Join array with commas and output as JavaScript array literal
    local IFS=', '
    echo "[${items[*]}]"
}

# Generate menu items HTML respecting DASHBOARD_ORDER (supports both service codes and category names)
generate_menu_items() {
    local menu_html=""

    # Parse DASHBOARD_ORDER - defaults to service codes format
    local dash_order="${DASHBOARD_ORDER:-SAB,GET,HYD,TRA,QBI,DEL,SON,RAD,LID,WHI,PRO,SEE,BAZ,JEL,EMB,PLX,TAU}"
    IFS=',' read -ra order_items <<< "$dash_order"

    # Process each item in DASHBOARD_ORDER
    for order_item in "${order_items[@]}"; do
        order_item=$(echo "$order_item" | xargs | tr '[:lower:]' '[:upper:]')
        local service_key=""

        # Check if this is a service code (3 letters) or category name
        if [ ${#order_item} -eq 3 ] && [[ -n "${SERVICE_CODE_MAP[$order_item]}" ]]; then
            # Using 3-letter service code
            service_key="${SERVICE_CODE_MAP[$order_item]}"
        else
            # Category name - skip, we're now using service codes
            continue
        fi

        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"

        if [ "$is_enabled" != "true" ]; then
            continue
        fi

        # Parse service metadata
        IFS='|' read -r category service_name service_desc icon_path href accent <<< "${SERVICES[$service_key]}"

        # Check for custom icon version
        icon_path=$(get_service_icon_path "$service_key" "$icon_path")

        # Handle subdomain services (Emby, Plex, Seerr)
        if [ "$href" = "SUBDOMAIN" ]; then
            if [ "$service_key" = "EMBY" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$EMBY_DOMAIN" ]; then
                    href="https://$EMBY_DOMAIN/"
                else
                    if [ -z "$EMBY_URL" ]; then
                        continue
                    fi
                    href="$EMBY_URL"
                fi
            elif [ "$service_key" = "PLEX" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$PLEX_DOMAIN" ]; then
                    href="https://$PLEX_DOMAIN/"
                else
                    if [ -z "$PLEX_URL" ]; then
                        continue
                    fi
                    href="$PLEX_URL"
                fi
            elif [ "$service_key" = "SEERR" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$SEERR_DOMAIN" ]; then
                    href="https://$SEERR_DOMAIN/"
                else
                    if [ -z "$SEERR_URL" ]; then
                        continue
                    fi
                    href="$SEERR_URL"
                fi
            fi
        fi

        # Check if this service should open in a popup
        local popup_attr=""
        if [[ "$service_key" == "QBITTORRENT" ]] || [[ "$href" == http* ]]; then
            popup_attr=" onclick=\"window.open(this.href, 'popup_' + Date.now(), 'width=1200,height=800,resizable=yes,status=yes,location=yes,toolbar=yes,menubar=yes,scrollbars=yes'); return false;\""
        else
            popup_attr=" target='Main'"
        fi

        # Add menu item
        menu_html+="<td class='menu-item'><a href='$href'$popup_attr title='$service_name'><img src='$icon_path' alt='$service_name' /></a></td>"
    done

    echo "$menu_html"
}

# Generate enabled services list for iframe fallback
generate_services_list() {
    local list_html=""
    
    for service_key in "${SERVICE_ORDER[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        # Parse service metadata
        IFS='|' read -r category service_name service_desc icon_path href accent <<< "${SERVICES[$service_key]}"

        # Check for custom icon version
        icon_path=$(get_service_icon_path "$service_key" "$icon_path")

        # Handle subdomain services
        if [ "$href" = "SUBDOMAIN" ]; then
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
            fi
        fi
        
        # Add list item
        list_html+="<li><a href='$href' target='content'>$service_name</a></li>"
    done
    
    # If no services enabled, show message
    if [ -z "$list_html" ]; then
        list_html="<li class='no-services'>⚠️ No services are currently enabled</li>"
    fi
    
    echo "$list_html"
}

# Generate services array for React dashboard (with categories)
generate_services_array() {
    local array=""
    local first=true

    for service_key in "${SERVICE_ORDER[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"

        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi

        # Parse service metadata (format: category|name|desc|icon|href|accent)
        IFS='|' read -r category name desc icon href accent <<< "${SERVICES[$service_key]}"

        # Find the 3-letter code for this service key
        local id=""
        for code in "${!SERVICE_CODE_MAP[@]}"; do
            if [ "${SERVICE_CODE_MAP[$code]}" = "$service_key" ]; then
                id="$code"
                break
            fi
        done

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
                    TAUTULLI)
                        [ -z "$TAUTULLI_URL" ] && continue
                        href="$TAUTULLI_URL"
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
                    TAUTULLI)
                        [ -z "$TAUTULLI_URL" ] && continue
                        href="$TAUTULLI_URL"
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
            fi
        fi

        # Determine if popup (external link, qBittorrent, or MEDIA services)
        local popup="false"
        [[ "$href" == http* ]] && popup="true"
        [[ "$service_key" == "QBITTORRENT" ]] && popup="true"
        [ "$category" = "MEDIA" ] && popup="true"

        # Add comma between items (with newline for readability)
        if [ "$first" = true ]; then
            first=false
        else
            array+=",$( printf '\n    ')"
        fi

        # Add service object with correct accent color
        array+="{ id: '$id', name: '$name', desc: '$desc', icon: '$icon', href: '$href', accent: '$accent', popup: $popup }"
    done

    echo "[$array]"
}

# Calculate dynamic icon sizes based on service count
calculate_icon_sizes() {
    local service_count=$1
    local icon_multiplier gap_multiplier logo_multiplier

    if [ "$service_count" -le 5 ]; then
        icon_multiplier="1.7"
        gap_multiplier="1.4"
        logo_multiplier="1.5"
    elif [ "$service_count" -le 8 ]; then
        icon_multiplier="1.6"
        gap_multiplier="1.2"
        logo_multiplier="1.375"
    elif [ "$service_count" -le 12 ]; then
        icon_multiplier="1.5"
        gap_multiplier="1.0"
        logo_multiplier="1.25"
    elif [ "$service_count" -le 15 ]; then
        icon_multiplier="1.4"
        gap_multiplier="0.8"
        logo_multiplier="1.125"
    else
        icon_multiplier="1.2"
        gap_multiplier="0.6"
        logo_multiplier="1.0"
    fi

    echo "$icon_multiplier|$gap_multiplier|$logo_multiplier"
}

# Generate style switcher HTML for classic template
generate_style_switcher_classic() {
    if [ "$SHOW_STYLE_SWITCHER" = "true" ]; then
        echo '<div class="style-switcher" style="display:flex;gap:6px;justify-content:center;align-items:center">
                <a href="/classic.html" style="text-decoration:none;color:#4a9eff">Classic</a>
                <span style="color:#5d6575">|</span>
                <a href="/modern.html" style="text-decoration:none;color:#4a9eff">Modern</a>
                <span style="color:#5d6575">|</span>
                <a href="/sleek.html" style="text-decoration:none;color:#4a9eff">Sleek</a>
                <span style="color:#5d6575">|</span>
                <a href="/minimal.html" style="text-decoration:none;color:#4a9eff">Minimal</a>
                <span style="color:#5d6575">|</span>
                <button id="theme-toggle-classic" style="background:none;border:none;cursor:pointer;font-size:14px;padding:0;color:var(--text-accent)" title="Toggle theme">☀️</button>
            </div>'
    else
        echo '<div style="display:flex;gap:6px;justify-content:center;align-items:center">
                <button id="theme-toggle-classic" style="background:none;border:none;cursor:pointer;font-size:14px;padding:0;color:var(--text-accent)" title="Toggle theme">☀️</button>
            </div>'
    fi
}

# Generate style switcher HTML for modern template
generate_style_switcher_modern() {
    if [ "$SHOW_STYLE_SWITCHER" = "true" ]; then
        echo '<div style="font-size:11px;text-align:center;padding:8px 0;border-top:1px solid var(--border-color);display:flex;gap:6px;justify-content:center;flex-wrap:wrap;align-items:center">
        <a href="/classic.html" style="color:var(--text-link);text-decoration:none;transition:color 0.2s">Classic</a>
        <span style="color:var(--text-tertiary)">|</span>
        <a href="/modern.html" style="color:var(--text-link);text-decoration:none;transition:color 0.2s">Modern</a>
        <span style="color:var(--text-tertiary)">|</span>
        <a href="/sleek.html" style="color:var(--text-link);text-decoration:none;transition:color 0.2s">Sleek</a>
        <span style="color:var(--text-tertiary)">|</span>
        <a href="/minimal.html" style="color:var(--text-link);text-decoration:none;transition:color 0.2s">Minimal</a>
        <span style="color:var(--text-tertiary)">|</span>
        <button id="theme-toggle-modern" style="background:none;border:none;cursor:pointer;font-size:11px;padding:0;color:var(--text-link);transition:color 0.2s" title="Toggle theme">☀️</button>
      </div>'
    else
        echo '<div style="font-size:11px;text-align:center;padding:8px 0;border-top:1px solid var(--border-color);display:flex;gap:6px;justify-content:center;flex-wrap:wrap;align-items:center">
        <button id="theme-toggle-modern" style="background:none;border:none;cursor:pointer;font-size:11px;padding:0;color:var(--text-link);transition:color 0.2s" title="Toggle theme">☀️</button>
      </div>'
    fi
}

# Generate style switcher HTML for sleek template
generate_style_switcher_sleek() {
    if [ "$SHOW_STYLE_SWITCHER" = "true" ]; then
        echo '<div style="font-size:9px;text-align:center;padding:8px 0;border-top:1px solid rgba(255,255,255,.1);display:flex;gap:4px;justify-content:center;flex-wrap:wrap;width:100%;align-items:center">
      <a href="/classic.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Classic</a>
      <span style="color:#5d6575">|</span>
      <a href="/modern.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Modern</a>
      <span style="color:#5d6575">|</span>
      <a href="/sleek.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Sleek</a>
      <span style="color:#5d6575">|</span>
      <a href="/minimal.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Minimal</a>
      <span style="color:#5d6575">|</span>
      <button id="theme-toggle-sleek" style="background:none;border:none;cursor:pointer;font-size:12px;padding:0;color:#4a9eff;transition:color 0.2s" title="Toggle theme">☀️</button>
    </div>'
    else
        echo '<div style="font-size:9px;text-align:center;padding:8px 0;border-top:1px solid rgba(255,255,255,.1);display:flex;gap:4px;justify-content:center;flex-wrap:wrap;width:100%;align-items:center">
      <button id="theme-toggle-sleek" style="background:none;border:none;cursor:pointer;font-size:12px;padding:0;color:#4a9eff;transition:color 0.2s" title="Toggle theme">☀️</button>
    </div>'
    fi
}

# Generate style switcher HTML for minimal template
generate_style_switcher_minimal() {
    if [ "$SHOW_STYLE_SWITCHER" = "true" ]; then
        echo '<div style="font-size:9px;text-align:center;padding:8px 0;border-top:1px solid rgba(255,255,255,.1);display:flex;gap:4px;justify-content:center;flex-wrap:wrap;width:100%;align-items:center">
      <a href="/classic.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Classic</a>
      <span style="color:#5d6575">|</span>
      <a href="/modern.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Modern</a>
      <span style="color:#5d6575">|</span>
      <a href="/sleek.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Sleek</a>
      <span style="color:#5d6575">|</span>
      <a href="/minimal.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Minimal</a>
      <span style="color:#5d6575">|</span>
      <button id="theme-toggle-minimal" style="background:none;border:none;cursor:pointer;font-size:12px;padding:0;color:#4a9eff;transition:color 0.2s" title="Toggle theme">☀️</button>
    </div>'
    else
        echo '<div style="font-size:9px;text-align:center;padding:8px 0;border-top:1px solid rgba(255,255,255,.1);display:flex;gap:4px;justify-content:center;flex-wrap:wrap;width:100%;align-items:center">
      <button id="theme-toggle-minimal" style="background:none;border:none;cursor:pointer;font-size:12px;padding:0;color:#4a9eff;transition:color 0.2s" title="Toggle theme">☀️</button>
    </div>'
    fi
}

# Generate dashboard based on DASH_STYLE
generate_style_dashboard() {
    local DASH_STYLE="${DASH_STYLE:-classic}"
    local OUTPUT_FILE="/var/www/html/${DASH_STYLE}.html"
    local TEMPLATE_FILE

    # Map style to template
    case "$DASH_STYLE" in
        classic)
            TEMPLATE_FILE="$CLASSIC_TEMPLATE"
            ;;
        modern)
            TEMPLATE_FILE="$MODERN_TEMPLATE"
            ;;
        sleek)
            TEMPLATE_FILE="$SLEEK_TEMPLATE"
            ;;
        minimal)
            TEMPLATE_FILE="$MINIMAL_TEMPLATE"
            ;;
        *)
            echo "ERROR: Invalid DASH_STYLE: $DASH_STYLE"
            return 1
            ;;
    esac

    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "ERROR: Template not found: $TEMPLATE_FILE"
        return 1
    fi

    # For classic style, generate menu items and services list
    if [ "$DASH_STYLE" = "classic" ]; then
        local menu_items=$(generate_menu_items)
        local services_list=$(generate_services_list)
        local style_switcher=$(generate_style_switcher_classic)

        local html_content=$(cat "$TEMPLATE_FILE")
        html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
        html_content="${html_content//@@ENABLED_SERVICES_LIST@@/$services_list}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
        html_content="${html_content//@@DASHBOARD_THEME@@/${DASHBOARD_THEME:-dark}}"

        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"|src="about:blank"|')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi

        echo "$html_content" > "$OUTPUT_FILE"
    elif [ "$DASH_STYLE" = "modern" ]; then
        # Modern dashboard uses React with full services array (with categories)
        local services_array=$(generate_services_array)
        local dash_order=$(generate_group_order)
        local style_switcher=$(generate_style_switcher_modern)
        local html_content=$(cat "$TEMPLATE_FILE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
        html_content="${html_content//@@DASHBOARD_ORDER@@/$dash_order}"
        html_content="${html_content//@@DASHBOARD_THEME@@/${DASHBOARD_THEME:-dark}}"

        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi

        echo "$html_content" > "$OUTPUT_FILE"
    else
        # For sleek and minimal styles, generate icons-only services array
        local services_array=$(generate_dashboard2_services_array)
        local service_count=0
        for service_key in "${SERVICE_ORDER[@]}"; do
            local enable_var="ENABLE_${service_key}"
            if [ "${!enable_var}" = "true" ]; then
                ((service_count++))
            fi
        done

        local sizes=$(calculate_icon_sizes "$service_count")
        local ICON_SIZE=$(echo "$sizes" | cut -d'|' -f1)
        local ICON_GAP=$(echo "$sizes" | cut -d'|' -f2)
        local LOGO_SIZE=$(echo "$sizes" | cut -d'|' -f3)

        # Determine which style switcher to use
        local style_switcher
        if [ "$DASH_STYLE" = "sleek" ]; then
            style_switcher=$(generate_style_switcher_sleek)
        else
            style_switcher=$(generate_style_switcher_minimal)
        fi

        local html_content=$(cat "$TEMPLATE_FILE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
        html_content="${html_content//@@DASHBOARD_THEME@@/${DASHBOARD_THEME:-dark}}"

        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi

        html_content="${html_content//@@ICON_SIZE@@/$ICON_SIZE}"
        html_content="${html_content//@@ICON_GAP@@/$ICON_GAP}"
        html_content="${html_content//@@LOGO_SIZE@@/$LOGO_SIZE}"

        echo "$html_content" > "$OUTPUT_FILE"
    fi

    echo "✓ Dashboard generated: $DASH_STYLE → $OUTPUT_FILE"
}

# Generate all dashboard styles for style switching
generate_all_styles() {
    local DASH_STYLE="${DASH_STYLE:-classic}"
    local service_count=0
    for service_key in "${SERVICE_ORDER[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((service_count++))
        fi
    done

    local sizes=$(calculate_icon_sizes "$service_count")
    local ICON_SIZE=$(echo "$sizes" | cut -d'|' -f1)
    local ICON_GAP=$(echo "$sizes" | cut -d'|' -f2)
    local LOGO_SIZE=$(echo "$sizes" | cut -d'|' -f3)

    # Generate Classic (always)
    if [ -f "$CLASSIC_TEMPLATE" ]; then
        local menu_items=$(generate_menu_items)
        local services_list=$(generate_services_list)
        local sites_items=$(generate_sites_html)
        local style_switcher=$(generate_style_switcher_classic)
        local html_content=$(cat "$CLASSIC_TEMPLATE")
        html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
        html_content="${html_content//@@ENABLED_SERVICES_LIST@@/$services_list}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"|src="about:blank"|')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi
        echo "$html_content" > "/var/www/html/classic.html"
    fi

    # Generate Modern (always)
    if [ -f "$MODERN_TEMPLATE" ]; then
        local services_array=$(generate_services_array)
        local dash_order=$(generate_group_order)
        local sites_items=$(generate_sites_html)
        local style_switcher=$(generate_style_switcher_modern)
        local html_content=$(cat "$MODERN_TEMPLATE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
        html_content="${html_content//@@DASHBOARD_ORDER@@/$dash_order}"
        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi
        echo "$html_content" > "/var/www/html/modern.html"
    fi

    # Generate Sleek (always)
    if [ -f "$SLEEK_TEMPLATE" ]; then
        local services_array=$(generate_services_array)
        local sites_items=$(generate_sites_html)
        local style_switcher=$(generate_style_switcher_sleek)
        local html_content=$(cat "$SLEEK_TEMPLATE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi
        html_content="${html_content//@@ICON_SIZE@@/$ICON_SIZE}"
        html_content="${html_content//@@ICON_GAP@@/$ICON_GAP}"
        html_content="${html_content//@@LOGO_SIZE@@/$LOGO_SIZE}"
        echo "$html_content" > "/var/www/html/sleek.html"
    fi

    # Generate Minimal (always)
    if [ -f "$MINIMAL_TEMPLATE" ]; then
        local services_array=$(generate_services_array)
        local sites_items=$(generate_sites_html)
        local style_switcher=$(generate_style_switcher_minimal)
        local html_content=$(cat "$MINIMAL_TEMPLATE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi
        html_content="${html_content//@@ICON_SIZE@@/$ICON_SIZE}"
        html_content="${html_content//@@ICON_GAP@@/$ICON_GAP}"
        html_content="${html_content//@@LOGO_SIZE@@/$LOGO_SIZE}"
        echo "$html_content" > "/var/www/html/minimal.html"
    fi

    # Generate Mobile (always)
    if [ -f "$MOBILE_TEMPLATE" ]; then
        local menu_items=$(generate_menu_items)
        local sites_items=$(generate_sites_html)
        local html_content=$(cat "$MOBILE_TEMPLATE")
        html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON_PATH}"
        echo "$html_content" > "/var/www/html/mobile.html"
    fi
}


# Main generation function
generate_html() {
    echo "Generating dashboards for DASH_STYLE=$DASH_STYLE..."
    echo ""

    # Count enabled services
    local count=0
    for service_key in "${SERVICE_ORDER[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((count++))
        fi
    done

    # Always show style switcher
    SHOW_STYLE_SWITCHER="true"

    # Generate all style variants
    generate_all_styles

    echo ""
    echo "✓ Dashboards generated with $count enabled service(s)"
    echo ""
    echo "Available dashboards (Apache DirectoryIndex = $DASH_STYLE.html):"
    echo "  /classic.html"
    echo "  /modern.html"
    echo "  /sleek.html"
    echo "  /minimal.html"
    echo "  /mobile.html"
    echo ""
    echo "Primary: /$DASH_STYLE.html (via DirectoryIndex)"
}

# Run generation
generate_html





