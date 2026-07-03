# Custom Layout Templates Guide

This folder is a **guide location** for creating custom layout templates. Custom layout CSS files should be placed in your project's custom templates directory to avoid conflicts with YAHLP updates.

## Built-in Layouts

YAHLP includes the following built-in layouts:
- **classic** — Traditional vertical sidebar with services and sites
- **modern** — Right-side services frame with left sidebar  
- **sleek** — Clean, minimal design
- **minimal** — Minimal, distraction-free layout
- **mobile** — Mobile-optimized single-column layout

## Sample Custom Templates

Example custom layouts (neon, focus, storm variants) are available in a separate Custom Templates repository. Download them and place the CSS files in your custom templates directory.

## Creating Custom Templates

To create your own custom layout:

1. Create a new file: `layout-{yourname}.css`
2. Reference the base CSS variables in `/styles/base.css`
3. Define styles for core components:
   - `.app` — Main container
   - `.app-sidebar` — Service menu area
   - `.service-menu` — Service icons
   - `.app-content` — Main content area
   - `.dashboard-view` — Dashboard container
   - `.sites-section` — Quick links area
   - `.app-footer` — Footer bar

4. Place the CSS file in your custom templates directory (not in this folder)
5. The layout will be auto-detected by the `data-layout` attribute

## CSS Variables

All YAHLP components use CSS custom properties for theming:
- `--bg-primary`, `--bg-secondary`, `--bg-tertiary`
- `--text-primary`, `--text-secondary`, `--text-accent`
- `--border-color`, `--border-light`
- `--status-success`, `--status-error`

Use these variables in your custom templates for proper light/dark mode support.

## Best Practices

- Keep custom templates in a separate repository or directory to prevent conflicts with YAHLP updates
- Test layouts at different viewport sizes (desktop, tablet, mobile)
- Use CSS custom properties instead of hardcoded colors
- Reference existing layout files as examples for component selectors and patterns
