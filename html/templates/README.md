# Built-in Template Examples

These are example templates included with YAHLP. They're automatically detected and built when the dashboard starts.

## Available Examples

- **layout-neon.css** — Cyberpunk-inspired design with neon glow effects

## Using These Examples

Access the neon example:
```
http://your-server/neon.html
```

## Creating Custom Templates

To create your own custom templates, see the main `/templates/README.md` in the repository root.

**Quick reference:**
1. Copy an example: `cp layout-neon.css ./my-template.css`
2. Edit the CSS to customize
3. Rebuild Docker: `docker-compose down && docker-compose up --build -d`
4. Access at: `http://your-server/my-template.html`

See `../CUSTOMIZATION.md` for the complete CSS customization guide.
