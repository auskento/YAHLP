#!/usr/bin/env node
/**
 * Convert yahlp.json5 to environment variable assignments
 * Outputs bash-compatible export statements
 * Usage: node json5-to-env.js > /tmp/yahlp.env
 * Then: source /tmp/yahlp.env
 */

const fs = require('fs');
const JSON5 = require('json5');

const configPath = '/etc/yahlp/yahlp.json5';

try {
  if (!fs.existsSync(configPath)) {
    // No config file, output nothing
    process.exit(0);
  }

  const config = JSON5.parse(fs.readFileSync(configPath, 'utf8'));

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

  // Handle services specially - extract to top-level env vars
  // services.jellyfin.enabled → JELLYFIN_ENABLED (not SERVICES_JELLYFIN_ENABLED)
  if (config.services) {
    for (const [serviceName, serviceConfig] of Object.entries(config.services)) {
      const serviceEnv = flattenConfig(serviceConfig, serviceName.toUpperCase());
      Object.assign(env, serviceEnv);
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
