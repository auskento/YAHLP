#!/usr/bin/env node
/**
 * Convert yahlp.json5 to environment variable assignments
 * Outputs bash-compatible export statements
 * Usage: node json5-to-env.js > /tmp/yahlp.env
 * Then: source /tmp/yahlp.env
 */

const fs = require('fs');
const path = require('path');

let JSON5;
try {
  JSON5 = require('json5');
} catch (e) {
  console.error('Error: json5 module not found. Make sure it is installed in /opt/proxy/node_modules');
  process.exit(1);
}

const configPath = '/etc/yahlp/yahlp.json5';

try {
  if (!fs.existsSync(configPath)) {
    // No config file, exit silently
    process.exit(0);
  }

  const fileContent = fs.readFileSync(configPath, 'utf8');
  const config = JSON5.parse(fileContent);

  // Helper to flatten nested objects and convert to SCREAMING_SNAKE_CASE
  function flattenConfig(obj, prefix = '') {
    const result = {};
    for (const [key, value] of Object.entries(obj)) {
      const envKey = prefix ? `${prefix}_${key.toUpperCase()}` : key.toUpperCase();

      if (value === null || value === undefined) {
        continue;
      } else if (typeof value === 'object' && !Array.isArray(value)) {
        // Recurse for nested objects
        Object.assign(result, flattenConfig(value, envKey));
      } else if (Array.isArray(value)) {
        // Convert arrays to comma-separated strings
        result[envKey] = value.join(',');
      } else if (typeof value === 'boolean') {
        // Convert booleans to lowercase strings
        result[envKey] = value ? 'true' : 'false';
      } else {
        result[envKey] = String(value);
      }
    }
    return result;
  }

  let env = flattenConfig(config);

  // Handle NEW FORMAT: settings grouped by type
  // enabled: { sabnzbd: true, sonarr: false } → SABNZBD_ENABLED, SONARR_ENABLED
  const settingTypes = ['enabled', 'url', 'api_key', 'icon_url', 'username', 'password', 'landing', 'domain', 'redirect_uri'];
  let usedNewFormat = false;
  for (const settingType of settingTypes) {
    if (config[settingType] && typeof config[settingType] === 'object') {
      usedNewFormat = true;
      for (const [serviceName, value] of Object.entries(config[settingType])) {
        if (value === null || value === undefined) continue;
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
  // Remove setting-type root keys if using new format
  if (usedNewFormat) {
    settingTypes.forEach(type => delete env[type.toUpperCase()]);
  }

  // Handle OLD FORMAT (backwards compatibility): services grouped by service
  // services.jellyfin.enabled → JELLYFIN_ENABLED (not SERVICES_JELLYFIN_ENABLED)
  if (config.services && !usedNewFormat) {
    for (const [serviceName, serviceConfig] of Object.entries(config.services)) {
      // For each service field (enabled, url, api_key, etc.), create top-level env var
      for (const [fieldName, fieldValue] of Object.entries(serviceConfig)) {
        if (fieldValue === null || fieldValue === undefined) continue;

        const envKey = `${serviceName.toUpperCase()}_${fieldName.toUpperCase()}`;
        if (typeof fieldValue === 'boolean') {
          env[envKey] = fieldValue ? 'true' : 'false';
        } else if (Array.isArray(fieldValue)) {
          env[envKey] = fieldValue.join(',');
        } else {
          env[envKey] = String(fieldValue);
        }
      }
    }
    // Remove the SERVICES_* variables since we've extracted them
    const keysToDelete = Object.keys(env).filter(k => k.startsWith('SERVICES_'));
    keysToDelete.forEach(k => delete env[k]);
  }

  // Output as bash export statements, but only for variables not already set in environment
  // This preserves -e environment variable overrides
  for (const [key, value] of Object.entries(env)) {
    // Check if variable is already set in environment
    if (process.env[key] === undefined) {
      // Escape single quotes and wrap in single quotes
      const escaped = value.replace(/'/g, "'\\''");
      console.log(`export ${key}='${escaped}'`);
    }
  }

} catch (err) {
  console.error(`Error parsing ${configPath}:`, err.message);
  process.exit(1);
}
