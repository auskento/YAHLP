#!/usr/bin/env node
/**
 * Parse yahlp.json5 and determine enabled services
 * Outputs JSON with service name and config for each enabled service
 * Environment variables ({SERVICE}_ENABLED) override JSON5 settings
 */

const fs = require('fs');
const JSON5 = require('json5');

const configPath = '/etc/yahlp/yahlp.json5';
const enabledServices = {};

try {
  if (!fs.existsSync(configPath)) {
    console.log(JSON.stringify({}));
    process.exit(0);
  }

  const config = JSON5.parse(fs.readFileSync(configPath, 'utf8'));
  const services = config.services || {};

  // Map of service names
  const serviceNames = [
    'jellyfin', 'plex', 'emby', 'sonarr', 'radarr', 'lidarr', 'whisparr',
    'qbittorrent', 'transmission', 'sabnzbd', 'nzbget', 'deluge', 'nzbhydra',
    'prowlarr', 'seerr', 'bazarr', 'tautulli', 'maintainerr'
  ];

  for (const service of serviceNames) {
    const serviceConfig = services[service] || {};

    // Check environment variable first ({SERVICE}_ENABLED)
    const envEnabled = process.env[`${service.toUpperCase()}_ENABLED`];
    const enabled = envEnabled !== undefined ? envEnabled === 'true' : serviceConfig.enabled === true;

    if (enabled) {
      // Get URL from environment variable or JSON5
      const envUrl = process.env[`${service.toUpperCase()}_URL`];
      const url = envUrl || serviceConfig.url;

      if (url) {
        enabledServices[service] = {
          enabled: true,
          url: url,
          config: serviceConfig
        };
      }
    }
  }

  console.log(JSON.stringify(enabledServices));
} catch (err) {
  console.error('Error parsing yahlp.json5:', err.message);
  console.log(JSON.stringify({}));
  process.exit(1);
}
