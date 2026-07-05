# Sites Configuration Guide

YAHLP includes quick-link support for popular torrent and usenet indexer sites. These appear as convenient shortcuts in your dashboard menu.

---

## Quick Start

To enable sites, set the `SITES_ENABLED` environment variable with comma-separated 3-letter site codes:

```env
SITES_ENABLED=TPB,FIL,HDB,DOG,DRS
```

This enables The Pirate Bay, FileList, HDBits, DOGnzb, and DrunkenSlug.

---

## Available Sites

### Torrent Sites (9 Total)

| Code | Site Name | URL |
|------|-----------|-----|
| TPB | The Pirate Bay | https://thepiratebay.org |
| FIL | FileList.io | https://filelist.io |
| HDB | HDBits | https://hdbits.org |
| IPT | IP Torrents | https://iptorrents.com |
| 1337 | 1337x | https://1337x.to |
| YTS | YTS | https://yts.torrentbay.st |
| LAT | LimeTorrents | https://limetorrents.cc |
| NYA | Nyaa | https://nyaa.si |
| PTP | PassThePopcorn | https://passthepopcorn.me |

### Usenet Sites (7 Total)

| Code | Site Name | URL |
|------|-----------|-----|
| DOG | DOGnzb | https://dognzb.cr/browse |
| DRS | DrunkenSlug | https://www.drunkenslug.com |
| NLF | nzb.life | https://nzb.life |
| NFW | NZBFinder.ws | https://nzbfinder.ws |
| NGK | NZBgeek | https://nzbgeek.info |
| PLA | nzbplanet.net | https://nzbplanet.net |
| TAB | Tabula Rasa | https://tabula-rasa.pw |

These are the preset values seeded into `sites.json` on first container start (from `generate-sites-config.sh`). If a site's URL changes, you can edit `sites.json` directly (see "Custom Sites" below) rather than waiting for an image update.

---

## Configuration Examples

### Enable All Torrent Sites

```env
SITES_ENABLED=TPB,FIL,HDB,IPT,1337,YTS,LAT,NYA,PTP
```

### Enable All Usenet Sites

```env
SITES_ENABLED=DOG,DRS,NLF,NFW,NGK,PLA,TAB
```

### Mixed Selection (Recommended Starting Point)

```env
SITES_ENABLED=TPB,FIL,HDB,DOG,DRS,NLF
```

### Disable Sites

Leave `SITES_ENABLED` empty or unset:

```env
SITES_ENABLED=
```

---

## How It Works

1. **Dashboard Menu**: Enabled sites appear as quick-link buttons in your dashboard sidebar
2. **Favicon Fetching**: On container startup, `generate-sites-config.sh` fetches a favicon for each enabled site via Google's public favicon service (`https://www.google.com/s2/favicons?sz=64&domain=...`) and resizes it to 64x64 with ImageMagick (if available). If a favicon already exists under `html/sites-icons/` (pre-cached in the image) or was already fetched to `/var/log/apache2/sites/`, that file is used instead and the fetch is skipped.
3. **User-Editable**: The `sites.json` configuration file can be modified for custom sites
4. **Link Generation Is Local**: The quick-link URLs themselves are generated locally with no external API calls — only the one-time favicon fetch talks to an external service (Google's favicon endpoint)

---

## Custom Sites (Advanced)

The default sites are seeded into `sites.json` on first container start (from the preset list in `generate-sites-config.sh`). The file lives at `/var/log/apache2/sites/sites.json` inside the container — it is not part of the `html/` directory. For advanced customization, you can modify `sites.json` directly (e.g. via `docker exec`), but this requires additional setup and is **not required** for standard operation.

**Note:** No extra volume mount is needed for normal operation. Sites configuration is optional and only needed if you want to add custom trackers or modify existing sites.

---

## Dashboard Display

Sites appear in your dashboard menu with:

- **Icon**: Site favicon (cached for performance)
- **Name**: Site display name
- **Link**: Direct URL to the site (opens in new tab)

---

## Troubleshooting

### Sites Not Showing Up

1. **Check SITES_ENABLED value:**
   ```bash
   docker exec <container> env | grep SITES_ENABLED
   ```

2. **Verify codes are valid:** Use codes from the table above

3. **Check for typos:** Codes are case-sensitive (e.g., `TPB` not `tpb`)

### Icon Not Loading

- Site favicon may be temporarily unavailable
- Icons are cached; wait a few moments and refresh
- Custom icons can be manually specified in `sites.json`

### Site Links Not Working

- Verify the site URL is still active
- Some sites may be geographically blocked
- Update site URL in `sites.json` if it has changed

---

## Security Note

The quick-link URLs themselves are generated locally by YAHLP and do not transmit any user data to YAHLP. Note that the one-time favicon fetch at container startup does contact Google's public favicon service (`google.com/s2/favicons`) for each newly-enabled site's domain — this only happens once per site (results are cached to disk) and is skipped entirely if a favicon is already pre-cached in `html/sites-icons/`. The links themselves simply provide convenient shortcuts to public torrent and usenet indexer sites. Users are responsible for ensuring their usage complies with local laws and regulations.

---

## Environment Variables Reference

```env
# Comma-separated 3-letter codes for enabled sites
# Leave empty to disable all sites
SITES_ENABLED=TPB,FIL,HDB,DOG,DRS
```

