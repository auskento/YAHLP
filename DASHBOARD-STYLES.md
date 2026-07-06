# Dashboard Styles & Layouts

YAHLP supports flexible dashboard layout configuration through the `DASHBOARD_STYLE` environment variable.

## Overview

The `DASHBOARD_STYLE` variable controls:
1. **Which layouts are built** during Docker startup
2. **Which layouts appear** in the layout switcher
3. **The default layout** when accessing the dashboard

## Configuration Options

### Option 1: Single Style (Build All, Use One as Default)

```bash
DASHBOARD_STYLE=modern
```

**Behavior:**
- Builds all 5 layouts: classic, modern, sleek, minimal, mobile
- Shows all layouts in the slider at the bottom
- Sets `modern` as the default (DirectoryIndex: `modern.html`)
- Users can switch between any layout

**Use Case:** Let users choose their preferred layout while setting a sensible default

---

### Option 2: Comma-Separated List (Build & Show Specific Layouts)

```bash
DASHBOARD_STYLE=modern,sleek
```

**Behavior:**
- Builds only the specified layouts: modern, sleek (plus mobile)
- Shows only those layouts in the slider
- Sets the first one (`modern`) as default
- DirectoryIndex: `modern.html sleek.html mobile.html`

**Use Case:** Curate the layout options available to users

---

### Option 3: Lock to Single Layout (Hide Slider)

```bash
DASHBOARD_STYLE=modern:only
```

**Behavior:**
- Builds only the specified layout: modern (plus mobile)
- Layout slider is **completely hidden**
- Users cannot switch layouts
- Users get mobile layout automatically on mobile devices

**Use Case:** Enterprise deployments or when you want a consistent UI for all users

---

## Available Layouts

| Layout | Description | Best For |
|--------|-------------|----------|
| **classic** | Traditional sidebar with service menu on left | Familiar interface, lots of services |
| **modern** | API-inspired with sidebar menu + right panel | Developer-friendly, clean look |
| **sleek** | Compact gradient design | Minimalists, high info density |
| **minimal** | Single-column ultra-simple | Mobile-first, uncluttered |
| **mobile** | Always built (auto-loaded on mobile devices) | Small screens, touch interfaces |

## Usage Examples

### Example 1: Family Setup (One Default, All Options)
```bash
DASHBOARD_STYLE=classic
# Result: All layouts available, classic is default
```

### Example 2: Media Team (Curated Options)
```bash
DASHBOARD_STYLE=modern,sleek
# Result: Only modern and sleek shown, modern is default
```

### Example 3: Corporate Dashboard (Locked Style)
```bash
DASHBOARD_STYLE=modern:only
# Result: Only modern layout, no switcher, consistent UI
```

### Example 4: Mobile-First App (Minimal Only)
```bash
DASHBOARD_STYLE=minimal:only
# Result: Clean minimal interface, always mobile-optimized
```

## How It Works

### Build Process

1. **Entrypoint Detection:** `docker-entrypoint.sh` reads `DASHBOARD_STYLE`
2. **Script Parsing:** `generate-html-menu.sh` parses the value:
   - Comma separators → List of layouts to build
   - `:only` suffix → Lock mode (hide slider)
   - Single value → Build all layouts
3. **File Generation:** Creates HTML files for each specified layout
4. **DirectoryIndex Update:** Updates Apache's DirectoryIndex with correct order

### DirectoryIndex Order

Apache serves files in the order listed. YAHLP sets DirectoryIndex as:

```
DirectoryIndex {default}.html {other-layouts}.html mobile.html
```

Examples:
- `DASHBOARD_STYLE=modern` → `DirectoryIndex modern.html classic.html sleek.html minimal.html mobile.html`
- `DASHBOARD_STYLE=modern,sleek` → `DirectoryIndex modern.html sleek.html mobile.html`
- `DASHBOARD_STYLE=modern:only` → `DirectoryIndex modern.html mobile.html` (slider hidden)

## Environment Variable Syntax

| Setting | Syntax | Example |
|---------|--------|---------|
| Build all, use default | Single style | `modern` |
| Build specific, show all | Comma-separated | `modern,sleek,minimal` |
| Build specific, lock mode | Style with `:only` | `modern:only` |

**Note:** Style names are case-insensitive internally (converted to lowercase)

## Docker Compose Example

```yaml
services:
  yahlp:
    image: auskento/yahlp
    environment:
      DOMAIN: example.com
      EMAIL: admin@example.com
      ACCESS_MODE: public
      DASHBOARD_STYLE: modern,sleek  # Two options, modern is default
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - appdata:/etc/letsencrypt
      - config:/etc/yahlp
```

## Unraid Installation

Both Unraid templates include the `DASHBOARD_STYLE` setting:

- **yahlp-simple.xml**: Basic template with common styles as dropdown options
- **yahlp-full.xml**: Comprehensive template with all configuration options

## Docker Run Command

```bash
docker run -d \
  --name yahlp \
  -e DOMAIN=example.com \
  -e EMAIL=admin@example.com \
  -e ACCESS_MODE=public \
  -e DASHBOARD_STYLE=modern:only \
  -p 80:80 \
  -p 443:443 \
  -v appdata:/etc/letsencrypt \
  auskento/yahlp
```

## Troubleshooting

### Slider Still Shows After `:only`

**Problem:** Set `modern:only` but slider still appears with all layouts

**Solution:** 
- Rebuild the container: `docker-compose build --no-cache`
- Clear browser cache (Ctrl+Shift+Delete or Cmd+Shift+Delete)
- Check browser console for errors (F12 → Console tab)

### Wrong Layout as Default

**Problem:** Set `sleek` as default but modern.html loads first

**Solution:**
- Rebuild container
- Check Docker logs: `docker-compose logs yahlp`
- Verify environment variable: `docker-compose exec yahlp env | grep DASHBOARD_STYLE`

### Layouts Not Appearing in Slider

**Problem:** Only built the layouts you want but slider shows all 5

**Solution:**
- Ensure `:only` suffix is used to lock if needed
- If using comma-separated list, those should be the only ones shown
- Clear localStorage: Open DevTools (F12) → Application → Clear Site Data

## Technical Details

### Files Modified During Build

- `/var/www/html/classic.html` → Created if "classic" in DASHBOARD_STYLE
- `/var/www/html/modern.html` → Created if "modern" in DASHBOARD_STYLE
- `/var/www/html/sleek.html` → Created if "sleek" in DASHBOARD_STYLE
- `/var/www/html/minimal.html` → Created if "minimal" in DASHBOARD_STYLE
- `/var/www/html/mobile.html` → Always created
- `/etc/apache2/sites-available/reverse-proxy.conf` → DirectoryIndex updated
- `localStorage['dashboard-locked']` → Set to 'true' if `:only` is used

### Client-Side Lock Detection

When `:only` is used:
```javascript
if (@@DASHBOARD_LOCKED@@) {
    localStorage.setItem('dashboard-locked', 'true');
}
```

The `initFooter()` function checks this flag:
```javascript
const isLocked = localStorage.getItem('dashboard-locked') === 'true';
if (isLocked) {
  slider.style.display = 'none';  // Hide layout switcher
  label.style.display = 'none';   // Hide layout name
}
```

## Best Practices

✅ **DO:**
- Use `:only` for production deployments needing consistency
- Use comma-separated for curated, team-based setups
- Use single style for user choice with sensible default
- Test layout switches in different browsers/devices

❌ **DON'T:**
- Mix `:only` with comma-separated (only rightmost `:only` is used)
- Use non-existent layout names (ignored silently)
- Change `DASHBOARD_STYLE` without rebuilding container

## Future Enhancements

Potential features for consideration:
- Per-user layout preferences (saved in user account)
- Style scheduling (different layouts at different times)
- Custom CSS for style overrides
- Style preview without rebuild

