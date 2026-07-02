# Custom Templates

Drop CSS files here to automatically generate custom dashboard templates!

## How It Works

1. **Add a CSS file** named `layout-yourname.css` to this folder
2. **Rebuild Docker**: `docker-compose down && docker-compose up --build -d`
3. **Access your template**: `http://your-server/yourname.html`

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

Copy an existing layout:

```bash
cp ../html/styles/layout-focus.css ./layout-mytemplate.css
```

Edit `layout-mytemplate.css` to customize colors, layout, spacing, etc.

Rebuild:

```bash
docker-compose down
docker-compose up --build -d
```

Access at: `http://your-server/mytemplate.html`

## Built-in Templates

The following layouts are always available:
- `/classic.html` - Horizontal menu bar
- `/sleek.html` - 2-column sidebar
- `/minimal.html` - Single-column sidebar
- `/focus.html` - Modern card-centric design

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
- Check filename starts with `layout-` and ends with `.css`
- Rebuild Docker: `docker-compose down && docker-compose up --build -d`
- Check Docker logs: `docker-compose logs apache-reverse-proxy`

**Can't see changes?**
- Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)
- Clear browser cache
- Check file is in this folder: `ls -la templates/`

**Want to modify built-in layouts?**
- Edit in `../html/styles/layout-*.css`
- Rebuild: `docker-compose down && docker-compose up --build -d`

## Contributing

If you create a cool template, consider sharing it!
- Document your design choices
- Include responsive breakpoints
- Test on mobile
- Submit as a PR or issue on GitHub
