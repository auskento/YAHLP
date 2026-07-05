# Creating Custom Templates

YAHLP uses a **CSS-only customization system**. All templates render from the same `html/master.template` markup — only the CSS differs per layout.

## File Structure

```
html/
  master.template          # Single template (all layouts use this)
  styles/
    base.css              # Common styles, variables, typography
    layout-classic.css    # Classic menu bar layout
    layout-modern.css     # Right-side services frame with left sidebar
    layout-sleek.css      # Sleek 2-column sidebar
    layout-minimal.css    # Minimal single-column sidebar
    layout-mobile.css     # Mobile-optimized single-column layout
    layout-custom.css     # Your custom template (create this)
```

Layout selection happens via a `data-layout="<name>"` attribute on the `.app` div — `generate-html-menu.sh` auto-discovers every `layout-*.css` file under `html/styles/` (via `find "$BUILTIN_STYLES" -name "layout-*.css"`) and builds a corresponding `<name>.html` page at container startup. No core files need editing to add a new layout.

## Creating a Custom Template

### Step 1: Create Your CSS File

Copy an existing layout file as a starting point:

```bash
cp html/styles/layout-classic.css html/styles/layout-custom.css
```

Edit `layout-custom.css` to customize:

```css
/* Custom Layout: Your description */

.app {
  /* Your flex layout */
  flex-direction: column; /* or row, etc. */
}

.app-header {
  /* Hide, modify size, change colors, etc. */
  display: none; /* or flex, etc. */
}

.app-sidebar {
  width: 150px; /* Your sidebar width */
  background: var(--bg-secondary);
  /* ... */
}

.service-menu {
  /* Grid, flex, or custom layout */
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
}

.menu-item {
  /* Style your menu items */
  padding: 12px;
  /* ... */
}

.dashboard-content {
  /* Grid columns for service cards */
  grid-template-columns: repeat(4, 1fr); /* 4 columns */
  gap: 20px;
}

/* Add more customizations... */
```

### Step 2: Make It Available to the Container

No shell script edits are needed — `generate_css_based_templates()` in `generate-html-menu.sh` auto-discovers any `layout-*.css` file under `html/styles/` at container startup.

- If you're editing the repo directly (e.g. adding `html/styles/layout-custom.css` before building the image), just rebuild:
  ```bash
  docker-compose down
  docker-compose up --build -d
  ```
- If you'd rather not touch the repo, drop `layout-custom.css` into the `./templates/` folder at the repo root instead (mounted to `/templates` in `docker-compose.yml`). It gets copied into `html/styles/` automatically at container startup — see `templates/README.md` for details. Since this copy happens in the entrypoint (not at image build time), a plain `docker-compose restart` picks it up; no rebuild required.

### Step 3: View Your Template

Access your template at: `http://your-server/custom.html`

## CSS Class Reference

All customizable elements use semantic class names:

### Layout

- `.app` - Root container (add `data-layout="your-layout"` attribute)
- `.app-header` - Top header bar
- `.app-sidebar` - Sidebar container
- `.app-content` - Main content area

### Header

- `.header-logo` - Logo section
- `.logo-img` - Logo image
- `.logo-text` - Logo text
- `.header-time` - Clock/date section
- `.current-time` - Time display
- `.current-date` - Date display

### Sidebar & Menu

- `.service-menu` - Service menu container
- `.menu-item` - Individual service button
- `.menu-icon` - Service icon
- `.menu-label` - Service name label
- `.menu-separator` / `.menu-separator-visible` / `.menu-separator-label` / `.menu-separator-invisible` - Dividers between service groups (see `html/templates/README.md` for the full reference)

### Dashboard

- `.dashboard-view` - Dashboard container
- `.dashboard-header` - Header section
- `.dashboard-title` - "Service Status" title
- `.dashboard-subtitle` - Subtitle text
- `.dashboard-content` - Service cards grid

### Service Cards

- `.service-card` - Individual card (clickable)
- `.service-card-header` - Card header
- `.service-card-icon` - Service icon
- `.service-card-title` - Service name
- `.service-card-status` - Online/Offline status
- `.status-dot` - Status indicator
- `.status-dot.online` - Online state
- `.status-dot.offline` - Offline state
- `.service-stat` - Individual stat row
- `.stat-label` - Stat name
- `.stat-value` - Stat value

### Other

- `.service-frame` - Embedded iframe
- `.welcome-screen` - Welcome screen (shown when no services configured)
- `.loading-placeholder` - Loading state
- `.no-services` - No services message

## CSS Variables

Customize colors via CSS variables in `base.css`:

```css
:root {
  --bg-primary: #08090c;
  --bg-secondary: #1a1a1a;
  --bg-tertiary: rgba(74, 158, 255, 0.1);
  --text-primary: #e9ecf2;
  --text-secondary: #5d6575;
  --text-accent: #6b7385;
  --text-link: #4a9eff;
  --border-color: #444;
  --status-success: #10b981;
  --status-error: #ef4444;
}
```

Override in your custom layout:

```css
/* layout-custom.css */
:root {
  --bg-primary: #001122;
  --text-primary: #ffffff;
  /* ... */
}
```

## Layout Examples

### Example 1: 3-Column Sidebar + 4-Column Grid

```css
.app-sidebar {
  width: 240px;
  display: flex;
  flex-direction: column;
}

.service-menu {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 8px;
}

.dashboard-content {
  grid-template-columns: repeat(4, 1fr);
}
```

### Example 2: Top Bar + Full Width

```css
.app {
  flex-direction: column;
}

.app-header {
  display: flex;
  padding: 16px 24px;
}

.app-sidebar {
  display: none;
}

.dashboard-content {
  grid-template-columns: repeat(6, 1fr);
}
```

### Example 3: Vertical Stack (Mobile-Like)

```css
.app {
  flex-direction: column;
}

.app-sidebar {
  width: 100%;
  height: auto;
  flex-direction: row;
  border: none;
  border-top: 1px solid var(--border-color);
}

.service-menu {
  flex-direction: row;
  flex-wrap: wrap;
}

.menu-item {
  flex: 0 1 auto;
  min-width: 60px;
}

.dashboard-content {
  grid-template-columns: repeat(2, 1fr);
}
```

## Testing Your Template

1. **Rebuild Docker:**
   ```bash
   docker-compose down
   docker-compose up --build -d
   ```

2. **Open in browser:**
   ```
   http://your-server/custom.html
   ```

3. **Check DevTools (F12):**
   - Verify CSS is loading
   - Check computed styles
   - Test responsive behavior

## Common Customizations

### Change Sidebar Width
```css
.app-sidebar {
  width: 200px; /* Adjust as needed */
}
```

### Hide/Show Header
```css
.app-header {
  display: none; /* or flex */
}
```

### Change Service Card Grid
```css
.dashboard-content {
  grid-template-columns: repeat(5, 1fr); /* 5 columns */
  gap: 20px; /* Adjust spacing */
}
```

### Full-Width Cards (1 Column)
```css
.dashboard-content {
  grid-template-columns: 1fr;
}
```

### Custom Colors
```css
:root {
  --bg-primary: #your-color;
  --text-primary: #your-color;
  /* ... */
}
```

### Dark/Light Mode Toggle
The system supports light theme via `[data-theme="light"]`:

```css
[data-theme="light"] {
  --bg-primary: #f5f5f7;
  --text-primary: #1a1a1a;
  /* ... */
}
```

## Tips

- **Always test responsive** behavior (test on mobile-sized viewport)
- **Use CSS variables** for colors—don't hardcode hex values
- **Keep semantic structure**—don't change HTML classes
- **Reference existing layouts** when unsure about structure
- **Use browser DevTools** to inspect and debug CSS

## Contributing Templates

Want to share your template?

1. Create your `layout-custom.css`
2. Test thoroughly
3. Submit as a GitHub PR with:
   - Description of the layout
   - Screenshot (if possible)
   - Any special features

## Support

For questions or issues:
- Check existing layout files for examples
- Use browser DevTools to debug CSS
- Reference the CSS class reference above
