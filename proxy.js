const express = require('express');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PROXY_PORT || 3000;

// Service URL and key configuration
const services = {
  'jellyfin': { url: process.env.JELLYFIN_URL, key: process.env.JELLYFIN_API_KEY, authType: 'mediabrowser' },
  'plex': { url: process.env.PLEX_URL, key: process.env.PLEX_API_KEY, authType: 'plex' },
  'emby': { url: process.env.EMBY_URL, key: process.env.EMBY_API_KEY, authType: 'query' },
  'sonarr': { url: process.env.SONARR_URL, key: process.env.SONARR_API_KEY, authType: 'header' },
  'radarr': { url: process.env.RADARR_URL, key: process.env.RADARR_API_KEY, authType: 'header' },
  'lidarr': { url: process.env.LIDARR_URL, key: process.env.LIDARR_API_KEY, authType: 'header' },
  'whisparr': { url: process.env.WHISPARR_URL, key: process.env.WHISPARR_API_KEY, authType: 'header' },
  'qbittorrent': { url: process.env.QBITTORRENT_URL, key: process.env.QBITTORRENT_API_KEY, authType: 'query' },
  'transmission': { url: process.env.TRANSMISSION_URL, key: process.env.TRANSMISSION_PASSWORD, authType: 'transmission' },
  'sabnzbd': { url: process.env.SABNZBD_URL, key: process.env.SABNZBD_API_KEY, authType: 'query' },
  'nzbget': { url: process.env.NZBGET_URL, key: process.env.NZBGET_PASS, authType: 'nzbget' },
  'deluge': { url: process.env.DELUGE_URL, key: process.env.DELUGE_PASSWORD, authType: 'deluge' },
  'nzbhydra': { url: process.env.NZBHYDRA_URL, key: process.env.NZBHYDRA_API_KEY, authType: 'header' },
  'prowlarr': { url: process.env.PROWLARR_URL, key: process.env.PROWLARR_API_KEY, authType: 'header' },
  'seerr': { url: process.env.SEERR_URL, key: process.env.SEERR_API_KEY, authType: 'header' },
  'bazarr': { url: process.env.BAZARR_URL, key: process.env.BAZARR_API_KEY, authType: 'bazarr' },
  'tautulli': { url: process.env.TAUTULLI_URL, key: process.env.TAUTULLI_API_KEY, authType: 'query' },
  'maintainerr': { url: process.env.MAINTAINERR_URL, key: process.env.MAINTAINERR_API_KEY, authType: 'header' }
};

// Generic proxy endpoint for any service
app.all('/proxy/:service/*', async (req, res) => {
  try {
    const service = req.params.service;
    const path = req.params[0];
    const query = new URLSearchParams(req.query).toString();

    if (!services[service]) {
      return res.status(404).json({ error: `Unknown service: ${service}` });
    }

    const config = services[service];
    if (!config.url || !config.key) {
      return res.status(400).json({ error: `Service ${service} not configured` });
    }

    let url = `${config.url}/${path}`;
    let headers = { 'Content-Type': 'application/json' };
    let body = undefined;

    // Add query string if present
    if (query) url += `?${query}`;

    // Apply authentication based on service type
    switch (config.authType) {
      case 'header':
        headers['X-Api-Key'] = config.key;
        break;
      case 'query':
        url += query ? '&' : '?';
        url += `api_key=${encodeURIComponent(config.key)}`;
        break;
      case 'plex':
        url += query ? '&' : '?';
        url += `X-Plex-Token=${encodeURIComponent(config.key)}`;
        break;
      case 'mediabrowser':
        headers['Authorization'] = `MediaBrowser Token="${config.key}"`;
        break;
      case 'bazarr':
        headers['X-API-KEY'] = config.key;
        break;
      case 'transmission':
        headers['X-Transmission-Session-Id'] = config.key;
        break;
      case 'nzbget':
      case 'deluge':
        // These use JSON-RPC in request body, auth handled specially
        if (req.method === 'POST' && req.body) {
          body = JSON.stringify(req.body);
        }
        break;
    }

    console.log(`[PROXY] ${req.method} ${service}: ${path}`);

    const fetchOptions = {
      method: req.method,
      headers,
      redirect: 'follow'
    };

    if (req.method !== 'GET' && req.body) {
      fetchOptions.body = body || JSON.stringify(req.body);
    }

    const response = await fetch(url, fetchOptions);

    if (!response.ok && response.status !== 409) {
      console.error(`[PROXY] ${service} HTTP ${response.status}`);
      return res.status(response.status).json({ error: `${service} returned ${response.status}` });
    }

    const contentType = response.headers.get('content-type');
    const data = contentType?.includes('application/json') ? await response.json() : await response.text();

    // For Transmission 409, pass through session ID
    if (response.status === 409) {
      const sessionId = response.headers.get('X-Transmission-Session-Id');
      if (sessionId) {
        res.set('X-Transmission-Session-Id', sessionId);
      }
    }

    console.log(`[PROXY] ${service} success`);
    res.json(data);
  } catch (err) {
    console.error('[PROXY] Error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    services: Object.keys(services).reduce((acc, svc) => {
      acc[svc] = { configured: !!(services[svc].url && services[svc].key) };
      return acc;
    }, {})
  });
});

app.listen(PORT, () => {
  console.log(`🔀 API Proxy server listening on port ${PORT}`);
  console.log(`   All requests: http://localhost:${PORT}/proxy/:service/:path`);
  console.log(`   Health check: http://localhost:${PORT}/health`);
  console.log('\nConfigured services:');
  Object.entries(services).forEach(([service, config]) => {
    const status = config.url && config.key ? '✅' : '⏳';
    console.log(`   ${status} ${service}`);
  });
});
