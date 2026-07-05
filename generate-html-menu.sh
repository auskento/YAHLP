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

# Generate services array respecting DASHBOARD_ORDER (with categories)
generate_services_array() {
    local array=""
    local first=true
    local order_array=()

    # Use DASHBOARD_ORDER if provided, otherwise use SERVICE_ORDER
    if [ ! -z "$DASHBOARD_ORDER" ]; then
        # Parse DASHBOARD_ORDER (service codes format: SAB,GET,HYD,etc + SEP for separators)
        IFS=',' read -ra codes <<< "$DASHBOARD_ORDER"
        for code in "${codes[@]}"; do
            code=$(echo "$code" | xargs)
            # Handle labeled separators (LBL:Label)
            if [[ "$code" =~ ^LBL: ]]; then
                order_array+=("$code")
            else
                code=$(echo "$code" | tr '[:lower:]' '[:upper:]')
                # Handle separator markers (SEP=invisible gap, VIS=visible line)
                if [ "$code" = "SEP" ] || [ "$code" = "VIS" ]; then
                    order_array+=("$code")
                elif [ -n "${SERVICE_CODE_MAP[$code]}" ]; then
                    order_array+=("${SERVICE_CODE_MAP[$code]}")
                fi
            fi
        done
    else
        order_array=("${SERVICE_ORDER[@]}")
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
            fi
        fi

        # Determine if popup (external link, qBittorrent, or MEDIA services with external URLs)
        local popup="false"
        [[ "$href" == http* ]] && popup="true"
        [[ "$service_key" == "QBITTORRENT" ]] && popup="true"
        # MEDIA services open as popup only if they're external (http) or SUBDOMAIN; subfolder services stay in-window
        if [ "$category" = "MEDIA" ] && [[ "$href" != /* ]]; then
            popup="true"
        fi

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

# Generate CSS-based templates from master.template
# Auto-detects CSS files in built-in templates and user-mounted /templates
generate_css_based_templates() {
    local MASTER_TEMPLATE="/var/www/html/master.template"
    local BUILTIN_STYLES="/var/www/html/styles"
    local BUILTIN_TEMPLATES="/var/www/html/templates"
    local USER_TEMPLATES="/templates"
    local services_array=$(generate_services_array)
    local sites_array=$(generate_sites_array)

    if [ ! -f "$MASTER_TEMPLATE" ]; then
        echo "Master template not found: $MASTER_TEMPLATE"
        return 1
    fi

    local layouts=()
    local template_count=0

    # Copy built-in templates to /templates BEFORE build process
    echo "📋 Populating /templates with built-in examples..."
    mkdir -p "$USER_TEMPLATES"
    if [ -d "$BUILTIN_TEMPLATES" ] && [ -n "$(ls -A "$BUILTIN_TEMPLATES" 2>/dev/null)" ]; then
        cp "$BUILTIN_TEMPLATES"/layout-*.css "$USER_TEMPLATES/" 2>/dev/null || true
        echo "  ✓ Built-in templates copied to /templates"
    fi

    # Copy any /templates CSS files to /var/www/html/styles for serving
    echo "📋 Copying /templates CSS files to styles folder..."
    if [ -d "$USER_TEMPLATES" ] && [ -n "$(ls -A "$USER_TEMPLATES"/layout-*.css 2>/dev/null)" ]; then
        cp "$USER_TEMPLATES"/layout-*.css "$BUILTIN_STYLES/" 2>/dev/null || true
        echo "  ✓ Custom templates copied to styles/"
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

    # Parse DASH_STYLE options
    # Format: "classic" (build all, use classic as default)
    #         "classic:only" (build only classic, lock to it)
    #         "classic,modern,sleek" (build only these, show only in slider)

    local STYLES_TO_BUILD=()
    local DEFAULT_STYLE=""

    if [[ "$DASH_STYLE" == *","* ]]; then
        # Comma-separated list: build only these styles
        IFS=',' read -ra STYLES_TO_BUILD <<< "$DASH_STYLE"
        DEFAULT_STYLE="${STYLES_TO_BUILD[0]}"
        echo "Building specific styles: ${STYLES_TO_BUILD[*]}"
    elif [[ "$DASH_STYLE" == *":only"* ]]; then
        # Single style with :only suffix: build only this, lock to it
        DEFAULT_STYLE="${DASH_STYLE%:only}"
        STYLES_TO_BUILD=("$DEFAULT_STYLE")
        echo "Style locked to: $DEFAULT_STYLE (style switcher disabled)"
    else
        # Single style: build all, use this as default
        DEFAULT_STYLE="$DASH_STYLE"
        echo "Building all styles, default: $DEFAULT_STYLE"
    fi

    # Generate CSS-based templates
    generate_css_based_templates

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






