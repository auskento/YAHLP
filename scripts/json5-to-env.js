#!/usr/bin/env node
/**
 * Convert yahlp.json5 to environment variables
 * Outputs bash export statements with env var precedence
 * Usage: eval "$(node json5-to-env.js)"
 */

const fs = require('fs');
const JSON5 = require('json5');

const configPath = '/etc/yahlp/yahlp.json5';

// Load JSON5 config if it exists
let config = {};
if (fs.existsSync(configPath)) {
  try {
    config = JSON5.parse(fs.readFileSync(configPath, 'utf8'));
  } catch (err) {
    console.error(`Error parsing ${configPath}:`, err.message);
    process.exit(1);
  }
}

// Helper function to format values for bash export
function formatValue(value) {
  if (value === null || value === undefined) {
    return '';
  }
  if (Array.isArray(value)) {
    // Convert array to comma-separated string
    return value.map(v => String(v).replace(/"/g, '\\"')).join(',');
  }
  if (typeof value === 'boolean') {
    return value ? 'true' : 'false';
  }
  if (typeof value === 'object') {
    return '';
  }
  // Escape quotes in string values
  return String(value).replace(/"/g, '\\"');
}

// Flatten object and output env vars with precedence
function flattenAndExport(obj, prefix = '') {
  const exports = [];

  for (const [key, value] of Object.entries(obj)) {
    const envKey = prefix ? `${prefix}_${key}`.toUpperCase() : key.toUpperCase();

    if (value === null || value === undefined) {
      continue;
    }

    if (typeof value === 'object' && !Array.isArray(value)) {
      // Recursively flatten nested objects
      exports.push(...flattenAndExport(value, envKey));
    } else {
      // Format value for bash
      const formattedValue = formatValue(value);
      // Use bash parameter expansion to allow env var override
      exports.push(`export ${envKey}="\${${envKey}:-${formattedValue}}"`);
    }
  }

  return exports;
}

// Generate all exports from config
const exports = [];

// Dashboard settings
if (config.dashboard) {
  exports.push(...flattenAndExport(config.dashboard, 'DASHBOARD'));
}

// Access settings
if (config.access) {
  exports.push(...flattenAndExport(config.access, 'ACCESS'));
}

// Auth settings
if (config.auth) {
  exports.push(...flattenAndExport(config.auth, 'AUTH'));
}

// Google OAuth settings
if (config.google) {
  exports.push(...flattenAndExport(config.google, 'GOOGLE'));
}

// Entra OAuth settings
if (config.entra) {
  exports.push(...flattenAndExport(config.entra, 'ENTRA'));
}

// Service settings
if (config.services) {
  for (const [serviceName, serviceConfig] of Object.entries(config.services)) {
    const servicePrefix = serviceName.toUpperCase();
    if (serviceConfig && typeof serviceConfig === 'object') {
      for (const [key, value] of Object.entries(serviceConfig)) {
        if (value !== null && value !== undefined) {
          const envKey = `${servicePrefix}_${key.toUpperCase()}`;
          const formattedValue = formatValue(value);
          exports.push(`export ${envKey}="\${${envKey}:-${formattedValue}}"`);
        }
      }
    }
  }
}

// Output all exports
console.log(exports.join('\n'));
