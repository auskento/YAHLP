# Custom User Templates

This folder is mounted as a volume in Docker. Add your custom CSS templates here!

## How It Works

**Folder structure:**
```
(repo)/templates/          ← This folder (mounted as volume at /templates)
├── layout-custom.css      → generates /custom.html
├── layout-dark.css        → generates /dark.html
└── README.md              (this file)
```

**Auto-detection:**
1. Any file named `layout-*.css` is automatically detected
2. `generate-html-menu.sh`'s `generate_css_based_templates()` copies any `layout-*.css` file from `/templates` into `html/styles/` (which it then scans with `find ... -name "layout-*.css"`), and generates a matching `<name>.html` page
3. Generated templates appear at `http://your-server/name.html`

**Important — this runs at container *startup*, not at image build time.** It happens inside `docker-entrypoint.sh` every time the container starts, so once you've added a file to `./templates/`, a plain `docker-compose restart` is enough — you do **not** need `docker-compose up --build`. (A rebuild is only required if you change files that live outside the `./templates/` volume mount, e.g. editing `html/` directly in the repo.)

**Note:** `../html/templates/` in this repo currently ships **only a README** (a deep-dive guide for writing layout CSS) — there are no ready-to-copy example CSS files bundled there today. Don't expect built-in example templates to already exist; you're writing your CSS from scratch or by copying one of the built-in layouts in `../html/styles/`.

## Quick Start

**1. Add a custom template file:**

```bash
# Create your CSS file
cat > templates/layout-mytemplate.css << 'EOF'
/* Your custom CSS here */
.app {
  flex-direction: column;
}
/* ... more CSS ... */
EOF
```

**2. Restart the container:**

```bash
docker-compose restart
```

(No rebuild needed — the file is picked up from the `./templates:/templates` volume mount at container startup.)

**3. Access your template:**

```
http://your-server/mytemplate.html
```

## Create Your Own From a Built-in Layout

There are no pre-made example CSS files shipped yet (no "neon", "dark", etc.) — the fastest starting point is to copy one of the real built-in layouts and modify it:

```bash
# Copy a built-in layout as a starting point
docker cp apache-reverse-proxy:/var/www/html/styles/layout-classic.css templates/layout-mydesign.css
```

**Edit and restart (no rebuild needed):**

```bash
nano templates/layout-mydesign.css
docker-compose restart
```

See `../html/templates/README.md` for a full guide to the HTML structure, CSS selectors, and CSS variables available to style.

## CSS File Naming

Files must be named `layout-*.css`:

- ✅ `layout-custom.css` → generates `custom.html`
- ✅ `layout-dark-mode.css` → generates `dark-mode.html`
- ❌ `custom.css` → NOT detected
- ❌ `my-layout.css` → NOT detected

## Available Template Reference

**Built-in layouts** (always available, in `../html/styles/`):
- `/classic.html` - Traditional vertical sidebar with services and sites
- `/modern.html` - Right-side services frame with left sidebar
- `/sleek.html` - Clean, minimal 2-column sidebar
- `/minimal.html` - Minimal, distraction-free single-column layout
- `/mobile.html` - Mobile-optimized single-column layout

**Built-in examples** (in `../html/templates/`):
- None currently bundled — that folder only contains a documentation guide (`README.md`) today.

**Your custom templates** (in `./templates/`):
- Add your own `.css` files here

## Customization Guide

See `../CUSTOMIZATION.md` for:
- CSS class reference (all available class names)
- CSS variables for colors and styling
- Layout examples (sidebar, grid, header styles)
- Responsive design patterns
- Tips and best practices

## Debugging

**Template not appearing?**
- Check filename: must start with `layout-` and end with `.css`
- Verify file location: `ls -la templates/`
- Restart the container: `docker-compose restart` (no rebuild needed — this is a startup-time step in `docker-entrypoint.sh`)
- Check Docker logs: `docker-compose logs apache-reverse-proxy | grep -i template`

**Can't see changes after restart?**
- Hard refresh browser: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
- Clear browser cache completely
- Verify Docker picked up the file: `docker exec apache-reverse-proxy ls -la /templates/` and `docker exec apache-reverse-proxy ls -la /var/www/html/styles/`

**Docker says template folder doesn't exist?**
- This is normal if you haven't created `./templates/` yet
- Create the folder: `mkdir -p ./templates/`
- Add a CSS file
- Restart the container

## Examples

There are no example CSS files bundled in `../html/templates/` yet — that folder currently only contains a documentation guide (`README.md`). Use `../html/styles/layout-classic.css` (or any other built-in layout) as your starting point, and refer to `../html/templates/README.md` for the full CSS selector/variable reference.

## Contributing

Found a great template design? Share it!
- Test on desktop and mobile
- Document your CSS choices
- Submit as a PR to the main repo

## Docker Mount

The `./templates/` folder is mounted in docker-compose.yml:

```yaml
volumes:
  - ./templates:/templates
```

This makes any CSS files you add available to the dashboard builder as soon as the container (re)starts — no rebuild required, since `generate_css_based_templates()` copies `/templates/layout-*.css` into `html/styles/` at every startup.
Built-in layouts (classic/modern/sleek/minimal/mobile) always ship in `../html/styles/` regardless of what's in this folder; `../html/templates/` is a separate, currently example-free folder containing only a CSS-authoring guide.
