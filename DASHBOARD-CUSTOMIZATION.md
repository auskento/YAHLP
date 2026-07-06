# Dashboard Customization Guide

Customize the look, feel, and layout of your YAHLP dashboard.

## Table of Contents
1. [Layouts](#layouts)
2. [Color & Appearance](#color--appearance)
3. [Service Organization](#service-organization)
4. [Landing Pages](#landing-pages)
5. [Built-in Sites](#built-in-sites)

---

## Layouts

YAHLP offers 5 responsive dashboard layouts.

### Layout Configurations

#### Single Layout (All Available)
```bash
DASHBOARD_STYLE=modern
```
- Builds all 5 layouts
- Shows layout switcher at bottom
- Sets specified layout as default

#### Curated Layouts
```bash
DASHBOARD_STYLE=modern,sleek
```
- Builds only specified layouts (plus mobile)
- Shows only these in switcher
- First listed is default

#### Locked Layout (Hide Switcher)
```bash
DASHBOARD_STYLE=modern:only
```
- Builds only specified layout
- Layout switcher completely hidden
- Enforces consistent UI
- Mobile layout still auto-loaded on small screens

### Available Layouts

#### Classic
Topbar with services listed horizontally across the top.

**Best for:**
- Lots of services (15+)
- Desktop-first viewing
- Wide screens

**Features:**
- Horizontal service bar at top
- Service grid below
- Full-width content area

#### Modern
Left service bar with main content panel on the right.

**Best for:**
- Balanced service count
- Modern aesthetic
- Developer preference

**Features:**
- Service menu on left sidebar
- Main content on right
- API-style sidebar navigation

#### Sleek
Left service bar with compact gradient design and high information density.

**Best for:**
- Limited screen space
- Minimalist preference
- 5-10 services

**Features:**
- Left sidebar service menu
- Gradient background
- Compact cards
- Minimal chrome

#### Minimal
Left service bar with ultra-simple single-column layout.

**Best for:**
- Mobile-first
- Minimalists
- Quick access only

**Features:**
- Left sidebar service menu
- One column layout
- Large, tappable buttons

#### Mobile
Automatically loaded on phones/tablets (included with all builds).

**Features:**
- Touch-optimized buttons
- Full-width layout
- No sidebar

### Switching Layouts

If layout switcher is enabled (not `:only`):

1. Look for slider at bottom of page
2. Drag or click to select layout
3. Page loads new layout instantly
4. Selection saved in browser

### Testing Layouts

To preview different layouts without rebuilding:

```bash
# Visit each layout directly by filename
https://yourdomain.com/classic.html
https://yourdomain.com/modern.html
https://yourdomain.com/sleek.html
https://yourdomain.com/minimal.html
https://yourdomain.com/mobile.html
```

---

## Color & Appearance

### Dashboard Color

Set the accent color for the dashboard:

```bash
DASHBOARD_COLOR=#FF6B6B
```

This color is used for:
- Content panel background (blended)
- Button accents
- Status indicators
- Theme color

### Color Examples

**Cool Colors:**
```bash
DASHBOARD_COLOR=#00A99D    # Teal (default)
DASHBOARD_COLOR=#4ECDC4    # Turquoise
DASHBOARD_COLOR=#2E86AB    # Blue
```

**Warm Colors:**
```bash
DASHBOARD_COLOR=#FF6B6B    # Red
DASHBOARD_COLOR=#F97316    # Orange
DASHBOARD_COLOR=#FFD93D    # Yellow
```

**Purple/Pink:**
```bash
DASHBOARD_COLOR=#9B59B6    # Purple
DASHBOARD_COLOR=#E84393    # Pink
DASHBOARD_COLOR=#C9184A    # Magenta
```

### Theme

Dark theme is currently the default and only theme. Light theme support may be added in future.

```bash
# Currently only option:
# No DASHBOARD_THEME variable needed
```

---

## Service Organization

### Service Ordering

Control the order services appear in the dashboard using 3-letter service codes.

#### Default Order
```bash
DASHBOARD_ORDER=JEL,PLX,EMB,SON,RAD,LID,WHI,QBI,TRA,SAB,GET,DEL,HYD,PRO,SEE,BAZ,TAU,MNT
```

Shows services in: Jellyfin, Plex, Emby, Sonarr, Radarr, Lidarr, Whisparr, qBittorrent, Transmission, SABnzbd, NZBGet, Deluge, NZBHydra, Prowlarr, Seerr, Bazarr, Tautulli, Maintainerr

#### Custom Order Examples

**Media First:**
```bash
DASHBOARD_ORDER=JEL,PLX,EMB,SON,RAD,QBI
# Shows: Media servers first, then content, then download client
```

**Download-Focused:**
```bash
DASHBOARD_ORDER=QBI,TRA,SAB,GET,DEL,SON,RAD,JEL
# Shows: Download clients first (qBittorrent, Transmission, SABnzbd, NZBGet, Deluge), then content, then media
```

**Content to Media:**
```bash
DASHBOARD_ORDER=SON,RAD,JEL,PLX,QBI
# Shows: Get content (Sonarr, Radarr) → watch it (Jellyfin, Plex) → download
```

#### Partial Order

You don't need all services:

```bash
DASHBOARD_ORDER=JEL,SON,RAD,QBI
# Shows these 4 services in this order
```

Services not in the list still appear (at the end, in default order).

---

## Landing Pages

Set which service loads when accessing the dashboard.

### Service Landing Pages

#### Calendar View (Sonarr)
```bash
DASHBOARD_LANDING=sonarr/calendar
```
Shows upcoming TV episodes.

#### Movie List (Radarr)
```bash
DASHBOARD_LANDING=radarr
```
Shows movie library.

#### Media Server (Jellyfin/Plex)
```bash
DASHBOARD_LANDING=jellyfin
DASHBOARD_LANDING=plex
```
Shows library homepage.

#### Library (Lidarr)
```bash
DASHBOARD_LANDING=lidarr
```
Shows music library.

### Default Behavior

If not set, dashboard shows:
- Service health grid (list of all services and status)
- User can click any service to open it

```bash
DASHBOARD_LANDING=  # Empty = show health grid
```

### Examples

**TV Show Calendar on Load:**
```bash
DASHBOARD_NAME="My Media Server"
DASHBOARD_LANDING=sonarr/calendar
# When accessing dashboard, immediately shows Sonarr calendar
```

**Movie Library on Load:**
```bash
DASHBOARD_LANDING=radarr
# When accessing dashboard, immediately shows Radarr movie list
```

**Jellyfin Media Server on Load:**
```bash
DASHBOARD_LANDING=jellyfin
# When accessing dashboard, immediately shows Jellyfin library
```

---

## Built-in Sites

Quick-link shortcuts to torrent and usenet tracking sites.

### Available Sites

#### Torrent Sites
- **TPB** - The Pirate Bay
- **FIL** - FileList.io
- **HDB** - HDBits
- **IPT** - IP Torrents
- **1337** - 1337x
- **YTS** - YTS
- **LAT** - LimeTorrents
- **NYA** - Nyaa
- **PTP** - PassThePopcorn

#### Usenet Sites
- **DOG** - DOGnzb
- **DRS** - DrunkenSlug
- **NLF** - nzb.life
- **NFW** - NZBFinder.ws
- **NGK** - NZBgeek
- **PLA** - nzbplanet.net
- **TAB** - Tabula Rasa

### Enable Sites

```bash
DASHBOARD_SITES=TPB,YTS,DOG,DRS,NLF
```

### Access

Sites appear as icon grid:
- Click icon to open site in new window
- Shows below service grid or in dedicated section
- Sites change based on `DASHBOARD_SITES` setting

### Examples

**Torrent Sites Only:**
```bash
DASHBOARD_SITES=TPB,YTS,LAT,1337
```

**Usenet Sites Only:**
```bash
DASHBOARD_SITES=DOG,DRS,NLF,NGK
```

**Mixed Setup:**
```bash
DASHBOARD_SITES=TPB,YTS,DOG,DRS,NLF,NFW
# Shows 2 torrent sites + 4 usenet sites
```

### Custom Sites

To add your own site shortcuts, edit `/etc/yahlp/sites.json5`:

```json5
{
  sites: [
    {
      code: "TOR",
      name: "MyTracker",
      url: "https://mytracker.example.com",
      icon: "https://mytracker.example.com/favicon.ico",
      enabled: true
    }
  ]
}
```

Sites must have `enabled: true` to show.

---

## Complete Customization Example

```bash
# Modern layout with curated options
DASHBOARD_STYLE=modern,sleek

# Branded name and color
DASHBOARD_NAME="My Media Server"
DASHBOARD_COLOR=#FF6B6B

# Services in download order: Downloads first, then content, then media
DASHBOARD_ORDER=QBI,TRA,SAB,SON,RAD,JEL,PLX

# Load Sonarr calendar by default
DASHBOARD_LANDING=sonarr/calendar

# Add site shortcuts
DASHBOARD_SITES=TPB,YTS,DOG,DRS,NLF
```

Result:
- Modern or sleek layout (user can switch)
- Red accent color
- Download clients first (qBittorrent, Transmission, SABnzbd), then content (Sonarr, Radarr), then media (Jellyfin, Plex)
- Sonarr calendar appears on load
- Site shortcuts for popular trackers

---

## Responsive Behavior

All layouts automatically adjust:

| Screen Size | Behavior |
|-------------|----------|
| > 1024px | Full desktop layout |
| 768-1024px | Tablet-optimized (narrower sidebar) |
| < 768px | Mobile layout (auto-loads) |

Mobile layout ignores `DASHBOARD_STYLE` setting and always loads its optimized version.

---

## Layout Switcher Tips

**If you don't see the switcher:**
- Check `DASHBOARD_STYLE` doesn't have `:only` suffix
- Check browser width > 768px (mobile hides it)
- Check browser cache (Ctrl+Shift+R to hard-refresh)

**To hide switcher permanently:**
```bash
DASHBOARD_STYLE=modern:only
# Locks to modern layout, hides switcher completely
```

---

## See Also

- [CONFIGURATION.md](CONFIGURATION.md) - All configuration options
- [INSTALLATION.md](INSTALLATION.md) - Initial setup
- [README.md](README.md) - Overview
