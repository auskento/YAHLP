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
2. Docker scans `/templates` on startup
3. Generated templates appear at `http://your-server/name.html`

**Note:** Built-in examples are in `../html/templates/` (not this folder). They're always available.

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

**2. Rebuild Docker:**

```bash
docker-compose down
docker-compose up --build -d
```

**3. Access your template:**

```
http://your-server/mytemplate.html
```

## Create from Example

**Copy a built-in example:**

```bash
# Copy from repo's html/templates
cp html/templates/layout-neon.css templates/layout-myneon.css

# Or from the container after first build
docker cp apache-reverse-proxy:/var/www/html/templates/layout-neon.css templates/
```

**Edit and rebuild:**

```bash
nano templates/layout-myneon.css
docker-compose down && docker-compose up --build -d
```

## CSS File Naming

Files must be named `layout-*.css`:

- ✅ `layout-custom.css` → generates `custom.html`
- ✅ `layout-dark-mode.css` → generates `dark-mode.html`
- ❌ `custom.css` → NOT detected
- ❌ `my-layout.css` → NOT detected

## Available Template Reference

**Built-in styles** (always available, in `../html/styles/`):
- `/classic.html` - Horizontal menu bar
- `/sleek.html` - 2-column sidebar
- `/minimal.html` - Single-column sidebar
- `/focus.html` - Modern card-centric design

**Built-in examples** (in `../html/templates/`):
- `/neon.html` - Cyberpunk with glow effects
- (More examples can be added here)

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
- Rebuild: `docker-compose down && docker-compose up --build -d`
- Check Docker logs: `docker-compose logs apache-reverse-proxy | grep -i template`

**Can't see changes after rebuild?**
- Hard refresh browser: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
- Clear browser cache completely
- Verify Docker picked up the file: `docker exec apache-reverse-proxy ls -la /templates/`

**Docker says template folder doesn't exist?**
- This is normal if you haven't created `./templates/` yet
- Create the folder: `mkdir -p ./templates/`
- Add a CSS file
- Rebuild Docker

## Examples

Check `../html/templates/` for example CSS files you can copy and customize.

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

This makes any CSS files you add immediately available to the dashboard builder.
Only files in this folder are included in the mounted volume—built-in templates in `../html/templates/` are always available separately.
