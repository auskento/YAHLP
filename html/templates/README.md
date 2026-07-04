# Custom Layout Templates Guide

This folder contains guidance for creating custom layout templates for YAHLP. Custom layout CSS files should be placed in your project's custom templates directory to avoid conflicts with YAHLP updates.

## How YAHLP Layouts Work

### Layout Detection

The layout system works by:
1. An HTML element with class `app` has a `data-layout` attribute: `<div class="app" data-layout="classic">`
2. The corresponding CSS file is loaded: `/styles/layout-classic.css` or `/templates/layout-{name}.css`
3. All CSS selectors in that file override the base styles defined in `/styles/base.css`

The layout selector controls which CSS file is loaded and applied to the entire dashboard.

## Built-in Layouts

YAHLP includes the following built-in layouts (in `/html/styles/`):
- **classic** — Traditional vertical sidebar with services and sites
- **modern** — Right-side services frame with left sidebar  
- **sleek** — Clean, minimal design
- **minimal** — Minimal, distraction-free layout
- **mobile** — Mobile-optimized single-column layout

## Sample Custom Templates

Example custom layouts are available in a separate Custom Templates repository. Download them and place the CSS files in your custom templates directory (mapped to `/templates` in Docker).

## Docker Setup for Custom Templates

To use custom templates with Docker, map your custom templates directory to `/var/www/html/templates` in your docker-compose.yml:

```yaml
services:
  yahlp:
    image: yahlp:latest
    volumes:
      - /path/to/custom-templates:/var/www/html/templates
```

Place your `layout-*.css` files in `/path/to/custom-templates/` on the host, and they will be available at `/templates/layout-*.css` inside the container and served to the browser.

## Complete HTML Structure Reference

Understanding the HTML structure is essential for styling. Here's the full component hierarchy:

```html
<div class="app" data-layout="custom" data-theme="dark">
  <!-- Header bar (logo, time) -->
  <header class="app-header">
    <a href="/" class="header-logo">
      <img src="..." class="logo-img">
      <div class="logo-text">...</div>
    </a>
    <div class="header-time">
      <div class="current-time" id="currentTime">--:--</div>
      <div class="current-date" id="currentDate">---</div>
    </div>
  </header>

  <!-- Left/top sidebar with service menu -->
  <aside class="app-sidebar">
    <nav class="service-menu" id="serviceMenu">
      <button class="menu-item" title="Service Name">
        <img src="/icons/service.png" class="menu-icon">
        <span class="menu-label">Service Name</span>
      </button>
      <!-- Separators for grouping -->
      <div class="menu-separator menu-separator-visible"></div>
      <div class="menu-separator menu-separator-label">Group Name</div>
    </nav>
    <!-- Sites grid in sidebar (for sidebar-based layouts) -->
    <div id="sidebar-sites-section" class="sidebar-sites-section">
      <div id="sidebar-sites-grid" class="sidebar-sites-grid">
        <a href="#" class="site-link" title="Site Name">
          <div class="site-icon">
            <img src="/sites-icons/site.png" alt="Site Name">
          </div>
          <div class="site-name">Site Name</div>
        </a>
      </div>
    </div>
  </aside>

  <!-- Main content area -->
  <main class="app-content">
    <!-- Hidden iframe for service frames -->
    <iframe id="service-frame" class="service-frame" src="" title="Service"></iframe>

    <!-- Dashboard with service status cards -->
    <div id="dashboard-view" class="dashboard-view">
      <div class="dashboard-header">
        <h1 class="dashboard-title">Service Status</h1>
        <p class="dashboard-subtitle">Real-time data from your services</p>
      </div>
      <div id="dashboard-content" class="dashboard-content">
        <div class="service-card" data-service-href="..." data-service-popup="false">
          <div class="service-card-header">
            <div class="service-card-icon">
              <img src="/icons/service.png" alt="Service Name">
            </div>
            <div class="service-card-title">Service Name</div>
            <div class="service-card-status">
              <span class="status-dot online"></span>
              Online
            </div>
          </div>
          <div class="service-stat">
            <span class="stat-label">Stat Name</span>
            <span class="stat-value">42</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Welcome screen (shown when no services configured) -->
    <div id="welcome-screen" class="welcome-screen" style="display:none">
      <img src="..." alt="Dashboard" class="welcome-logo">
      <div class="welcome-title">Welcome to YAHLP</div>
      <div class="welcome-message">Configure your services with API keys...</div>
    </div>
  </main>

  <!-- Quick links section (for right-side layouts) -->
  <div id="sites-section" class="sites-section">
    <div class="sites-title">Quick Links</div>
    <div id="sites-grid" class="sites-grid">
      <a href="#" class="site-link" title="Site Name">
        <div class="site-icon">
          <img src="/sites-icons/site.png" alt="Site Name">
        </div>
        <div class="site-name">Site Name</div>
      </a>
    </div>
  </div>
</div>

<!-- Footer bar -->
<footer class="app-footer">
  <div class="footer-left">
    <a href="/">
      <img src="..." alt="Dashboard" class="footer-icon">
      <span class="footer-name">YAHLP</span>
    </a>
  </div>
  <div class="footer-center">
    <input type="range" id="templateSlider" class="template-slider">
    <span class="template-label" id="templateLabel">Custom</span>
  </div>
  <div class="footer-right">
    <div class="footer-time">
      <span id="footerTime">--:--</span>
      <span id="footerDate">---</span>
    </div>
    <button id="themeToggle" class="theme-toggle" title="Toggle dark/light mode">🌙</button>
  </div>
</footer>
```

## CSS Selectors Reference

Key selectors typically styled in custom layouts:

### Layout Container
```css
.app                           /* Main container, set flex-direction, background */
.app[data-layout="custom"]    /* Target specific layouts */
[data-theme="dark"]           /* Dark/light theme selector */
```

### Header
```css
.app-header                    /* Header bar container */
.header-logo                   /* Logo section */
.logo-img                      /* Logo image */
.logo-text                     /* Logo text */
.header-time                   /* Time display section */
.current-time                  /* Time value */
.current-date                  /* Date value */
```

### Sidebar (Service Menu)
```css
.app-sidebar                   /* Sidebar container */
.service-menu                  /* Service button container, use flex-direction, gap */
.menu-item                     /* Individual service button */
.menu-icon                     /* Service icon image */
.menu-label                    /* Service label text */
.menu-separator                /* Divider between service groups */
.menu-separator-visible        /* Visible line separator */
.menu-separator-label          /* Text label separator */
```

### Sidebar Sites (for sidebar-based layouts)
```css
.sidebar-sites-section         /* Sites container in sidebar */
.sidebar-sites-grid            /* Sites grid, use flex-direction */
.sidebar-sites-section .site-link        /* Individual site link */
.sidebar-sites-section .site-icon        /* Site icon */
```

**This `display` rule is what tells YAHLP whether your layout is sidebar-based —
no core file edits needed.** Set it explicitly one way or the other:

```css
/* Sidebar-based layout (sites render inside the sidebar) */
.sidebar-sites-section { display: flex; }
.sites-section { display: none; }

/* Right-frame/full-width layout (sites render in the #sites-section panel) */
.sidebar-sites-section { display: none !important; }
```

### Content Area
```css
.app-content                   /* Main content container */
.dashboard-view                /* Dashboard container */
.dashboard-header              /* Dashboard title section */
.dashboard-title               /* "Service Status" heading */
.dashboard-subtitle            /* Subtitle text */
.dashboard-content             /* Service cards grid container */
```

### Service Cards
```css
.service-card                  /* Individual service status card */
.service-card-header           /* Card header with icon and status */
.service-card-icon             /* Service icon in card */
.service-card-title            /* Service name in card */
.service-card-status           /* Status badge (Online/Offline) */
.status-dot                    /* Status indicator dot */
.status-dot.online             /* Online status styling */
.status-dot.offline            /* Offline status styling */
.service-stat                  /* Service stat row (queue, playing, etc.) */
.stat-label                    /* Stat label text */
.stat-value                    /* Stat value number */
.loading-placeholder           /* Loading message */
.no-services                   /* "No configured services" message */
```

### Welcome Screen
```css
.welcome-screen                /* Welcome message container (overlays dashboard) */
.welcome-logo                  /* Logo in welcome screen */
.welcome-title                 /* "Welcome to YAHLP" title */
.welcome-message               /* Welcome instructions text */
```

### Sites Section (right-side layouts)
```css
.sites-section                 /* Quick links container */
.sites-title                   /* "Quick Links" heading */
.sites-grid                    /* Sites grid container */
.site-link                     /* Individual site link */
.site-icon                     /* Site icon/favicon */
.site-name                     /* Site label text (hidden in all layouts) */
```

### Footer
```css
.app-footer                    /* Footer bar container */
.footer-left                   /* Left section (logo) */
.footer-center                 /* Center section (layout name) */
.footer-right                  /* Right section (time and theme toggle) */
.footer-name                   /* YAHLP text in footer */
.footer-time                   /* Time display in footer */
.template-slider               /* Layout selector range input */
.template-label                /* Current layout name label */
.theme-toggle                  /* Dark/light mode toggle button */
```

## CSS Variables Reference

All available CSS custom properties for theming and styling:

### Surface Colors
```css
:root {
  --bg-primary: #08090c;           /* Page background (darkest) */
  --bg-secondary: #1a1a1a;         /* Card/panel background */
  --bg-tertiary: rgba(74, 158, 255, 0.1);  /* Hover/interactive background */
}

[data-theme="light"] {
  --bg-primary: #f5f5f7;           /* Light mode primary */
  --bg-secondary: #ffffff;         /* Light mode secondary */
  --text-primary: #1a1a1a;         /* Dark text on light bg */
  --text-secondary: #666;          /* Medium gray text */
}
```

### Text Colors
```css
--text-primary: #e9ecf2;           /* Main text */
--text-secondary: #5d6575;         /* Secondary/muted text */
--text-accent: #6b7385;            /* Accent text */
--text-link: #4a9eff;              /* Link color */
```

### Border Colors
```css
--border-color: #444;              /* Default borders */
--border-light: rgba(255, 255, 255, 0.1);  /* Light borders */
```

### Status Colors
```css
--status-success: #10b981;         /* Online/success green */
--status-error: #ef4444;           /* Offline/error red */
```

## Step-by-Step: Creating a Custom Layout

### 1. Create the CSS File

Create `layout-mydesign.css` with the filename matching your desired layout name.

### 2. Start with Core Structure

```css
/* MyDesign Layout */

.app {
  display: flex;
  flex-direction: column;  /* or 'row' for side-by-side */
  height: 100%;
  width: 100%;
  background: linear-gradient(135deg, #0a0b0f 0%, #12131a 100%);
}
```

### 3. Style the Header

```css
.app-header {
  padding: 20px 32px;
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border-color);
  display: flex;
  align-items: center;
  gap: 24px;
}

.logo-img {
  width: 32px;
  height: 32px;
}

.header-time {
  margin-left: auto;
}

.current-time {
  font-weight: 600;
  color: var(--text-link);
}
```

### 4. Style the Sidebar

```css
.app-sidebar {
  display: flex;
  flex-direction: column;  /* vertical stacking */
  width: 100%;
  padding: 12px 24px;
  background: var(--bg-secondary);
  gap: 0;
}

.service-menu {
  display: flex;
  flex-direction: row;    /* horizontal icons */
  gap: 12px;
  align-items: center;
  justify-content: center;
}

.menu-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.menu-item:hover {
  background: var(--bg-tertiary);
  transform: translateY(-2px);
}

.menu-icon {
  width: 56px;           /* Service icons are 2x site icons */
  height: 56px;
  display: block;
}

.menu-label {
  display: none;         /* Hide labels for icon-only layout */
}
```

### 5. Style the Content Area

```css
.app-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
}

.dashboard-view {
  flex: 1;
  overflow-y: auto;
  padding: 32px;
}

.dashboard-header {
  margin-bottom: 32px;
  text-align: center;
}

.dashboard-title {
  font-size: 28px;
  font-weight: 600;
  margin-bottom: 8px;
  color: var(--text-primary);
}

.dashboard-subtitle {
  font-size: 14px;
  color: var(--text-secondary);
}

.dashboard-content {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 16px;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
}
```

### 6. Style Service Cards

```css
.service-card {
  background: var(--bg-tertiary);
  border: 1px solid var(--border-color);
  border-radius: 12px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
  overflow: hidden;
}

.service-card:hover {
  border-color: var(--text-link);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.service-card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

.service-card-icon {
  width: 32px;
  height: 32px;
  flex-shrink: 0;
  border-radius: 8px;
  background: #111;
  display: flex;
  align-items: center;
  justify-content: center;
}

.service-card-title {
  flex: 1;
  font-weight: 600;
  color: var(--text-primary);
  font-size: 14px;
}

.service-card-status {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 4px;
}

.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  display: inline-block;
}

.status-dot.online {
  background: var(--status-success);
}

.status-dot.offline {
  background: var(--status-error);
}
```

### 7. Style the Footer

```css
.app-footer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 48px;
  background: var(--bg-secondary);
  border-top: 1px solid var(--border-color);
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 0 16px;
  z-index: 1000;
}

.footer-name {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-primary);
}

.footer-time {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--text-secondary);
}

.template-label {
  font-size: 11px;
  color: var(--text-secondary);
  text-transform: uppercase;
}

.theme-toggle {
  width: 28px;
  height: 28px;
  border: 1px solid var(--border-color);
  background: transparent;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
}
```

### 8. Add Responsive Design

```css
@media (max-width: 1024px) {
  .dashboard-content {
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 12px;
  }

  .dashboard-view {
    padding: 24px;
  }
}

@media (max-width: 768px) {
  .app {
    flex-direction: column;
  }

  .dashboard-view {
    padding: 16px;
  }

  .dashboard-content {
    grid-template-columns: 1fr;
  }

  .service-menu {
    gap: 8px;
  }

  .menu-icon {
    width: 40px;
    height: 40px;
  }
}
```

## Common Patterns

### Sidebar-based Layout (classic)
- Sidebar on left/top with horizontal service menu
- Sites grid below services in same sidebar
- Dashboard content fills remaining space
- Footer fixed at bottom

### Right-frame Layout (modern, sleek)
- Left sidebar with service menu
- Main content on right
- Sites section as right sidebar
- Footer fixed at bottom

### Full-width Layout (minimal)
- No sidebar
- Services and content in full width
- Sites at bottom
- Header and footer at top/bottom

## Common Gotchas & Tips

### 1. Flexbox Order Property
Use CSS `order` property to rearrange layout elements without changing HTML:
```css
.app-sidebar { order: 2; }
.app-content { order: 3; }
.sites-section { order: 4; }
.app-footer { order: 5; }
```

### 2. Fixed Footer
If footer is fixed, add bottom padding to app to prevent overlap:
```css
.app {
  padding-bottom: 48px;  /* Match footer height */
}
```

### 3. Light/Dark Mode
Always use CSS variables for colors—they automatically switch on theme change:
```css
/* Good — works in both modes */
color: var(--text-primary);

/* Bad — only works in dark mode */
color: #e9ecf2;
```

### 4. Site Icon Sizing
Service icons should be **2x the size of site icons** for visual hierarchy:
```css
.menu-icon {
  width: 56px;           /* Service icons */
}

.site-icon {
  width: 28px;           /* Sites are 28px (half of 56px) */
}
```

### 5. Welcome Screen
The welcome screen overlays the dashboard when no services are configured:
```css
.welcome-screen {
  position: absolute;    /* Overlays dashboard-view */
  inset: 0;             /* Covers entire app-content */
  display: none;        /* Hidden by default */
  z-index: 100;         /* Ensure it's on top */
}
```

### 6. Scrollbars
The dashboard content scrolls independently:
```css
.dashboard-view {
  overflow-y: auto;     /* Enable vertical scroll */
  overflow-x: hidden;   /* Prevent horizontal scroll */
}
```

## Best Practices

- **Use CSS variables** instead of hardcoded colors for theme compatibility
- **Test responsive** at 768px, 1024px, and 1280px breakpoints
- **Reference existing layouts** in `/html/styles/` for proven patterns
- **Keep custom templates separate** from core installation to avoid conflicts with updates
- **Document your layout** with comments explaining the design approach
- **Minimize specificity** — avoid `!important` and deeply nested selectors
- **Use semantic gap sizes** — stick to 8px, 12px, 16px, 24px, 32px multiples

## File Placement

```
your-project/
├── html/                          (YAHLP core)
│   ├── master.template
│   └── styles/
│       ├── base.css
│       ├── layout-classic.css
│       └── ...
└── custom-templates/              (Your custom layouts)
    ├── layout-mydesign.css
    ├── layout-corporate.css
    └── ...
```

Place your custom layouts in a **separate directory** from the YAHLP core to prevent conflicts during updates.
