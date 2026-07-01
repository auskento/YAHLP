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
| FIL | FileList | https://filelist.io |
| HDB | HDBits | https://hdbits.org |
| IPT | IP Torrents | https://iptorrents.com |
| 1337 | 1337x | https://1337x.to |
| YTS | YTS / YIFY | https://yts.mx |
| LAT | LimeTorrents | https://www.limetorrents.lol |
| NYA | Nyaa | https://nyaa.si |
| PTP | PassThePopcorn | https://passthepopcorn.me |

### Usenet Sites (7 Total)

| Code | Site Name | URL |
|------|-----------|-----|
| DOG | DOGnzb | https://dognzb.cr |
| DRS | DrunkenSlug | https://drunkenslug.com |
| NLF | nzb.life | https://nzb.life |
| NFW | NZBFinder | https://www.nzbfinder.com |
| NGK | NZBgeek | https://www.nzbgeek.info |
| PLA | nzbplanet | https://nzbplanet.net |
| TAB | Tabula Rasa | https://www.tabulasearch.com |

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
2. **Icon Caching**: Site favicons are pre-cached for instant loading
3. **User-Editable**: The `sites.json` configuration file can be modified for custom sites
4. **No External Dependencies**: Links are generated locally, no external API calls

---

## Custom Sites (Advanced)

The default sites are built into the container. For advanced customization, you can modify `sites.json`, but this requires additional setup and is **not required** for standard operation.

**Note:** The `/app/html/` directory does not need to be mounted as a volume for normal operation. Sites configuration is optional and only needed if you want to add custom trackers or modify existing sites.

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

Sites links are generated locally by YAHLP and do not transmit any user data to YAHLP. They simply provide convenient shortcuts to public torrent and usenet indexer sites. Users are responsible for ensuring their usage complies with local laws and regulations.

---

## Environment Variables Reference

```env
# Comma-separated 3-letter codes for enabled sites
# Leave empty to disable all sites
SITES_ENABLED=TPB,FIL,HDB,DOG,DRS
```

