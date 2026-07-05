#!/usr/bin/env node
/**
 * Generate yahlp.json5 from environment variables
 * This is called by docker-entrypoint.sh to populate config from env vars
 */

const fs = require('fs');
const path = require('path');

const configPath = '/etc/yahlp/yahlp.json5';

// Only generate if it doesn't already exist
if (fs.existsSync(configPath)) {
  console.log('✓ yahlp.json5 already exists');
  process.exit(0);
}

const config = {
  dashboard: {
    name: process.env.DASHBOARD_NAME || 'YAHLP Dashboard',
    icon_url: process.env.DASHBOARD_ICON_URL || 'https://via.placeholder.com/64',
    color: process.env.DASHBOARD_COLOR || '#00A99D',
    theme: process.env.DASHBOARD_THEME || 'dark',
    style: process.env.DASHBOARD_STYLE || 'classic',
    landing: process.env.DASHBOARD_LANDING || 'dashboard',
    order: process.env.DASHBOARD_ORDER ?
      process.env.DASHBOARD_ORDER.split(',').map(s => s.trim()) :
      ['JEL', 'PLX', 'EMB', 'SON', 'RAD', 'LID', 'WHI', 'QBI', 'TRA', 'SAB', 'GET', 'DEL', 'HYD', 'PRO', 'SEE', 'BAZ', 'TAU', 'MNT'],
    sites: process.env.DASHBOARD_SITES ?
      process.env.DASHBOARD_SITES.split(',').map(s => s.trim()) :
      [],
  },

  access: {
    mode: process.env.ACCESS_MODE || 'private',
    domain: process.env.ACCESS_DOMAIN || 'localhost:3000',
  },

  auth: {
    type: process.env.AUTH_TYPE || 'none',
  },

  services: {},
};

// Service definitions
const services = [
  'jellyfin', 'plex', 'emby', 'sonarr', 'radarr', 'lidarr', 'whisparr',
  'qbittorrent', 'transmission', 'sabnzbd', 'nzbget', 'deluge', 'nzbhydra',
  'prowlarr', 'seerr', 'bazarr', 'tautulli', 'maintainerr'
];

services.forEach(service => {
  const serviceConfig = {};
  const envPrefix = service.toUpperCase();

  const enabled = process.env[`${envPrefix}_ENABLED`];
  if (enabled !== undefined) serviceConfig.enabled = enabled === 'true';

  const url = process.env[`${envPrefix}_URL`];
  if (url) serviceConfig.url = url;

  const apiKey = process.env[`${envPrefix}_API_KEY`];
  if (apiKey) serviceConfig.api_key = apiKey;

  const username = process.env[`${envPrefix}_USERNAME`];
  if (username) serviceConfig.username = username;

  const password = process.env[`${envPrefix}_PASSWORD`];
  if (password) serviceConfig.password = password;

  const iconUrl = process.env[`${envPrefix}_ICON_URL`];
  if (iconUrl) serviceConfig.icon_url = iconUrl;

  const domainName = process.env[`${envPrefix}_DOMAIN_NAME`];
  if (domainName) serviceConfig.domain_name = domainName;

  const redirectUri = process.env[`${envPrefix}_REDIRECT_URI`];
  if (redirectUri) serviceConfig.redirect_uri = redirectUri;

  const landing = process.env[`${envPrefix}_LANDING`];
  if (landing) serviceConfig.landing = landing;

  if (Object.keys(serviceConfig).length > 0) {
    config.services[service] = serviceConfig;
  }
});

// Google OAuth
if (process.env.GOOGLE_CLIENT_ID) {
  config.google = {
    client_id: process.env.GOOGLE_CLIENT_ID,
    client_secret: process.env.GOOGLE_CLIENT_SECRET || '',
    redirect_uri: process.env.GOOGLE_REDIRECT_URI || 'http://localhost:3000/auth/callback',
  };
}

// Entra/Azure AD
if (process.env.ENTRA_CLIENT_ID) {
  config.entra = {
    client_id: process.env.ENTRA_CLIENT_ID,
    client_secret: process.env.ENTRA_CLIENT_SECRET || '',
    redirect_uri: process.env.ENTRA_REDIRECT_URI || 'http://localhost:3000/auth/callback',
    provider_metadata_url: process.env.ENTRA_PROVIDER_METADATA_URL || '',
    crypto_passphrase: process.env.ENTRA_CRYPTO_PASSPHRASE || '',
  };
}

// Write the config (simple JSON, not JSON5 from env vars - user can edit yahlp.json5 manually for JSON5 features)
try {
  // Ensure directory exists
  const dir = path.dirname(configPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log('✓ Generated yahlp.json5 from environment variables');
} catch (err) {
  console.error('✗ Failed to generate yahlp.json5:', err.message);
  process.exit(1);
}
