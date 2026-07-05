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
    style: process.env.DASH_STYLE || 'classic',
    landing: process.env.DASHBOARD_LANDING || 'dashboard',
  },

  access: {
    mode: process.env.ACCESS_MODE || 'localhost',
    domain: process.env.DOMAIN || 'localhost:3000',
    protocol: process.env.PROTOCOL || 'http',
  },

  proxy: {
    port: parseInt(process.env.PROXY_PORT || '3000'),
  },

  auth: {
    type: process.env.AUTHTYPE || 'none',
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

  const url = process.env[`${envPrefix}_URL`];
  if (url) serviceConfig.url = url;

  const apiKey = process.env[`${envPrefix}_API_KEY`];
  if (apiKey) serviceConfig.api_key = apiKey;

  const password = process.env[`${envPrefix}_PASSWORD`];
  if (password) serviceConfig.password = password;

  const username = process.env[`${envPrefix}_USERNAME`];
  if (username) serviceConfig.username = username;

  const username = process.env[`${envPrefix}_USERNAME`];
  if (username) serviceConfig.username = username;

  const password = process.env[`${envPrefix}_PASSWORD`];
  if (password) serviceConfig.password = password;

  if (Object.keys(serviceConfig).length > 0) {
    config.services[service] = serviceConfig;
  }
});

// Google OAuth
if (process.env.GOOGLE_CLIENT_ID) {
  config.google = {
    client_id: process.env.GOOGLE_CLIENT_ID,
    client_secret: process.env.GOOGLE_CLIENT_SECRET || '',
    redirect_uri: process.env.GOOGLE_REDIRECT_URI || '',
  };
}

// Entra/Azure AD
if (process.env.ENTRA_CLIENT_ID) {
  config.entra = {
    client_id: process.env.ENTRA_CLIENT_ID,
    client_secret: process.env.ENTRA_CLIENT_SECRET || '',
    redirect_uri: process.env.ENTRA_REDIRECT_URI || '',
    provider_metadata_url: process.env.ENTRA_PROVIDER_METADATA_URL || '',
    crypto_passphrase: process.env.ENTRA_CRYPTO_PASSPHRASE || '',
  };
}

// Write the config
fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log('✓ Generated yahlp.json5 from environment variables');
