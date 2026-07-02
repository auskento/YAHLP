# Custom Templates

Add CSS files here to automatically generate custom dashboard templates!

## How It Works

**First time (Docker build):**
1. Example templates included: `layout-neon.css`
2. All templates in this folder are copied into the Docker image
3. Auto-detected and built when Docker starts
4. Access templates: `http://your-server/neon.html`

**Adding custom templates:**
1. Create a local `./templates/` folder on your host machine
2. Add CSS files named `layout-yourname.css`
3. Rebuild Docker: `docker-compose down && docker-compose up --build -d`
4. Access your template: `http://your-server/yourname.html`

## Example

```
templates/
├── layout-custom.css     → generates /custom.html
├── layout-dark.css       → generates /dark.html
├── layout-neon.css       → generates /neon.html
└── README.md             (this file)
```

## Creating a Custom Template

See `CUSTOMIZATION.md` in the root directory for:
- CSS class reference
- CSS variables
- Layout examples
- Tips & tricks

## Quick Start

**1. Copy the neon example or another built-in template:**

```bash
cp layout-neon.css layout-mytemplate.css
```

**2. Edit your template:**

```bash
nano layout-mytemplate.css
```

Customize colors, layout, spacing, transitions—whatever you want!

**3. Rebuild Docker:**

```bash
docker-compose down
docker-compose up --build -d
```

**4. Access your template:**

```
http://your-server/mytemplate.html
```

## Built-in Templates

Located in `../html/styles/` - always available:
- `/classic.html` - Horizontal menu bar
- `/sleek.html` - 2-column sidebar
- `/minimal.html` - Single-column sidebar
- `/focus.html` - Modern card-centric design

## Included Examples

Located in `./templates/` - copied into Docker at build time:
- `/neon.html` - Cyberpunk-inspired design with glow effects

Use these as starting points for your custom templates!

## CSS File Naming

**Important:** CSS files must be named `layout-*.css`

- ✅ `layout-custom.css` → generates `custom.html`
- ✅ `layout-dark.css` → generates `dark.html`
- ❌ `custom.css` → will NOT be detected
- ❌ `layout-custom-v2.css` → generates `custom-v2.html` (okay)

## Tips

- Use browser DevTools to inspect and debug CSS
- Reference existing layouts (`../html/styles/`) for examples
- Keep CSS organized with comments
- Test responsive behavior on mobile

## Troubleshooting

**Template not generating?**
- Filename must be `layout-*.css` (e.g., `layout-custom.css`)
- File must be in this folder: `./templates/`
- Rebuild Docker: `docker-compose down && docker-compose up --build -d`
- Check logs: `docker-compose logs apache-reverse-proxy | grep -i template`

**Can't see my template?**
- Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)
- Clear browser cache
- Verify file exists: `ls -la ./templates/`
- Verify Docker copied it: `docker exec apache-reverse-proxy ls -la /templates/`

**Examples disappeared after first run?**
- Examples are built into Docker at build time
- If you mount a local `./templates` folder, it overrides the Docker image
- Copy examples locally to keep them: `cp /path/to/repo/templates/* ./templates/`

**Want to modify built-in layouts?**
- Edit in `../html/styles/layout-*.css`
- Rebuild: `docker-compose down && docker-compose up --build -d`
- These are always available (not replaced by volume mount)

## Contributing

If you create a cool template, consider sharing it!
- Document your design choices
- Include responsive breakpoints
- Test on mobile
- Submit as a PR or issue on GitHub
