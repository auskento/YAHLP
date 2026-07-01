const express = require('express');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const cors = require('cors');
const NodeCache = require('node-cache');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PROXY_PORT || 3000;
const cache = new NodeCache({ stdTTL: 30, checkperiod: 10 });

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

// Generic request helper
async function makeRequest(serviceKey, endpoint, options = {}) {
  const config = services[serviceKey];
  if (!config.url || !config.key) {
    throw new Error(`Service ${serviceKey} not configured`);
  }

  const url = `${config.url}${endpoint}`;
  const headers = { 'Content-Type': 'application/json' };
  let finalUrl = url;

  // Apply authentication based on service type
  switch (config.authType) {
    case 'header':
      headers['X-Api-Key'] = config.key;
      break;
    case 'query':
      finalUrl += `${endpoint.includes('?') ? '&' : '?'}api_key=${encodeURIComponent(config.key)}`;
      break;
    case 'plex':
      finalUrl += `${endpoint.includes('?') ? '&' : '?'}X-Plex-Token=${encodeURIComponent(config.key)}`;
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
  }

  const response = await fetch(finalUrl, { ...options, headers });

  if (!response.ok) {
    throw new Error(`${serviceKey} HTTP ${response.status}`);
  }

  const contentType = response.headers.get('content-type');
  return contentType?.includes('application/json') ? await response.json() : await response.text();
}

// Plex endpoints
app.get('/api/plex/server', async (req, res) => {
  try {
    const cached = cache.get('plex-server');
    if (cached) return res.json(cached);

    const data = await makeRequest('plex', '/identity');
    cache.set('plex-server', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Seerr endpoints
app.get('/api/seerr/status', async (req, res) => {
  try {
    const cached = cache.get('seerr-status');
    if (cached) return res.json(cached);

    const data = await makeRequest('seerr', '/api/v1/status');
    cache.set('seerr-status', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Tautulli endpoints
app.get('/api/tautulli/status', async (req, res) => {
  try {
    const cached = cache.get('tautulli-status');
    if (cached) return res.json(cached);

    const data = await makeRequest('tautulli', '/api/v2?cmd=status');
    cache.set('tautulli-status', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Bazarr endpoints
app.get('/api/bazarr/status', async (req, res) => {
  try {
    const cached = cache.get('bazarr-status');
    if (cached) return res.json(cached);

    const data = await makeRequest('bazarr', '/api/status');
    cache.set('bazarr-status', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Prowlarr endpoints
app.get('/api/prowlarr/health', async (req, res) => {
  try {
    const cached = cache.get('prowlarr-health');
    if (cached) return res.json(cached);

    const data = await makeRequest('prowlarr', '/api/v1/health');
    cache.set('prowlarr-health', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// NZBHydra endpoints
app.get('/api/nzbhydra/status', async (req, res) => {
  try {
    const cached = cache.get('nzbhydra-status');
    if (cached) return res.json(cached);

    const data = await makeRequest('nzbhydra', '/api/stats');
    cache.set('nzbhydra-status', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Sonarr endpoints
app.get('/api/sonarr/queue', async (req, res) => {
  try {
    const cached = cache.get('sonarr-queue');
    if (cached) return res.json(cached);

    const data = await makeRequest('sonarr', '/api/v3/queue');
    cache.set('sonarr-queue', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Radarr endpoints
app.get('/api/radarr/queue', async (req, res) => {
  try {
    const cached = cache.get('radarr-queue');
    if (cached) return res.json(cached);

    const data = await makeRequest('radarr', '/api/v3/queue');
    cache.set('radarr-queue', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Lidarr endpoints
app.get('/api/lidarr/queue', async (req, res) => {
  try {
    const cached = cache.get('lidarr-queue');
    if (cached) return res.json(cached);

    const data = await makeRequest('lidarr', '/api/v1/queue');
    cache.set('lidarr-queue', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Whisparr endpoints
app.get('/api/whisparr/queue', async (req, res) => {
  try {
    const cached = cache.get('whisparr-queue');
    if (cached) return res.json(cached);

    const data = await makeRequest('whisparr', '/api/v3/queue');
    cache.set('whisparr-queue', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// qBittorrent endpoints
app.get('/api/qbittorrent/stats', async (req, res) => {
  try {
    const cached = cache.get('qbittorrent-stats');
    if (cached) return res.json(cached);

    const data = await makeRequest('qbittorrent', '/api/v2/server/preferences');
    cache.set('qbittorrent-stats', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Transmission endpoints
app.post('/api/transmission/stats', async (req, res) => {
  try {
    const cached = cache.get('transmission-stats');
    if (cached) return res.json(cached);

    const data = await makeRequest('transmission', '/transmission/rpc', {
      method: 'POST',
      body: JSON.stringify({
        method: 'session-get',
        arguments: {}
      })
    });
    cache.set('transmission-stats', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// SABnzbd endpoints
app.get('/api/sabnzbd/stats', async (req, res) => {
  try {
    const cached = cache.get('sabnzbd-stats');
    if (cached) return res.json(cached);

    const data = await makeRequest('sabnzbd', '/api?mode=queue&output=json');
    cache.set('sabnzbd-stats', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// NZBGet endpoints
app.post('/api/nzbget/stats', async (req, res) => {
  try {
    const cached = cache.get('nzbget-stats');
    if (cached) return res.json(cached);

    const data = await makeRequest('nzbget', '/jsonrpc', {
      method: 'POST',
      body: JSON.stringify({
        version: '1.1',
        method: 'status',
        params: [],
        id: 1
      })
    });
    cache.set('nzbget-stats', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Deluge endpoints
app.post('/api/deluge/stats', async (req, res) => {
  try {
    const cached = cache.get('deluge-stats');
    if (cached) return res.json(cached);

    const data = await makeRequest('deluge', '/json', {
      method: 'POST',
      body: JSON.stringify({
        method: 'core.get_free_space',
        params: ['/'],
        id: 1
      })
    });
    cache.set('deluge-stats', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Jellyfin endpoints
app.get('/api/jellyfin/info', async (req, res) => {
  try {
    const cached = cache.get('jellyfin-info');
    if (cached) return res.json(cached);

    const data = await makeRequest('jellyfin', '/System/Info');
    cache.set('jellyfin-info', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Emby endpoints
app.get('/api/emby/info', async (req, res) => {
  try {
    const cached = cache.get('emby-info');
    if (cached) return res.json(cached);

    const data = await makeRequest('emby', '/System/Info');
    cache.set('emby-info', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Maintainerr endpoints
app.get('/api/maintainerr/health', async (req, res) => {
  try {
    const cached = cache.get('maintainerr-health');
    if (cached) return res.json(cached);

    const data = await makeRequest('maintainerr', '/api/health');
    cache.set('maintainerr-health', data);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    cache: {
      keys: cache.keys().length,
      ttl: cache.getStats().kexpired || 0
    },
    services: Object.keys(services).reduce((acc, svc) => {
      acc[svc] = { configured: !!(services[svc].url && services[svc].key) };
      return acc;
    }, {})
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🔀 API Aggregator listening on port ${PORT}`);
  console.log(`   Cache TTL: 30 seconds`);
  console.log(`   Health check: http://localhost:${PORT}/health`);
  console.log('\nConfigured services:');
  Object.entries(services).forEach(([service, config]) => {
    const status = config.url && config.key ? '✅' : '⏳';
    console.log(`   ${status} ${service}`);
  });
});
