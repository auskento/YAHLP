#!/usr/bin/env node
/**
 * Convert yahlp.json5 to environment variable assignments
 * Outputs bash-compatible export statements
 * Usage: node json5-to-env.js > /tmp/yahlp.env
 * Then: source /tmp/yahlp.env
 */

const fs = require('fs');

let JSON5;
try {
  JSON5 = require('json5');
} catch (e) {
  console.error('Error: json5 module not found. Make sure it is installed globally or in node_modules');
  process.exit(1);
}

const configPath = '/etc/yahlp/yahlp.json5';

try {
  if (!fs.existsSync(configPath)) {
    process.exit(0);
  }

  const fileContent = fs.readFileSync(configPath, 'utf8');
  const config = JSON5.parse(fileContent);
  const env = {};

  // Process NEW FORMAT: settings grouped by type
  // enabled: { sabnzbd: true, sonarr: false } → SABNZBD_ENABLED, SONARR_ENABLED
  // url: { sabnzbd: 'http://...', sonarr: 'http://...' } → SABNZBD_URL, SONARR_URL
  const settingTypes = ['enabled', 'url', 'api_key', 'icon_url', 'username', 'password', 'landing', 'redirect_uri'];

  for (const settingType of settingTypes) {
    if (config[settingType] && typeof config[settingType] === 'object' && !Array.isArray(config[settingType])) {
      for (const [serviceName, value] of Object.entries(config[settingType])) {
        if (value === null || value === undefined || value === '') {
          continue;
        }

        const envKey = `${serviceName.toUpperCase()}_${settingType.toUpperCase()}`;
        if (typeof value === 'boolean') {
          env[envKey] = value ? 'true' : 'false';
        } else if (Array.isArray(value)) {
          env[envKey] = value.join(',');
        } else {
          env[envKey] = String(value);
        }
      }
    }
  }

  // Process top-level access and dashboard settings
  if (config.access && typeof config.access === 'object') {
    for (const [key, value] of Object.entries(config.access)) {
      if (value === null || value === undefined || value === '') {
        continue;
      }
      const envKey = `ACCESS_${key.toUpperCase()}`;
      env[envKey] = typeof value === 'boolean' ? (value ? 'true' : 'false') : String(value);
    }
  }

  if (config.dashboard && typeof config.dashboard === 'object') {
    for (const [key, value] of Object.entries(config.dashboard)) {
      if (value === null || value === undefined || value === '') {
        continue;
      }
      const envKey = `DASHBOARD_${key.toUpperCase()}`;
      env[envKey] = typeof value === 'boolean' ? (value ? 'true' : 'false') : String(value);
    }
  }

  // Process top-level domain and email
  if (config.domain) {
    env['DOMAIN'] = config.domain;
  }
  if (config.email) {
    env['EMAIL'] = config.email;
  }

  // Process sites_enabled if present
  if (config.sites_enabled && config.sites_enabled !== '') {
    env['DASHBOARD_SITES'] = config.sites_enabled;
  }

  // Output as bash export statements, but only for variables not already set in environment
  // This preserves -e environment variable overrides
  for (const [key, value] of Object.entries(env)) {
    if (process.env[key] === undefined) {
      const escaped = value.replace(/'/g, "'\\''");
      console.log(`export ${key}='${escaped}'`);
    }
  }

} catch (err) {
  console.error(`Error parsing ${configPath}:`, err.message);
  process.exit(1);
}
