const express = require('express');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const cors = require('cors');
const NodeCache = require('node-cache');
const fs = require('fs');
const path = require('path');
const JSON5 = require('json5');

const app = express();
app.use(cors());
app.use(express.json());

const cache = new NodeCache({ stdTTL: 30, checkperiod: 10 });

// JSON5 Validation Function
function validateJSON5(filePath, fileName) {
  if (!fs.existsSync(filePath)) {
    return { valid: false, error: `File not found: ${filePath}` };
  }

  try {
    const content = fs.readFileSync(filePath, 'utf8');
    JSON5.parse(content);
    return { valid: true, error: null };
  } catch (err) {
    const lineMatch = err.message.match(/line (\d+)/);
    const line = lineMatch ? lineMatch[1] : 'unknown';
    return {
      valid: false,
      error: `${fileName} - Line ${line}: ${err.message.replace(/^Error: /, '')}`
    };
  }
}

// Validate configuration files on startup
const configPath = '/etc/yahlp/yahlp.json5';
const sitesPath = '/etc/yahlp/sites.json5';
const validationErrors = [];

const configValidation = validateJSON5(configPath, 'yahlp.json5');
if (!configValidation.valid) {
  validationErrors.push(configValidation.error);
}

// Only validate sites.json5 if it exists (optional file)
let sitesValidation = { valid: true, error: null };
if (fs.existsSync(sitesPath)) {
  sitesValidation = validateJSON5(sitesPath, 'sites.json5');
  if (!sitesValidation.valid) {
    validationErrors.push(sitesValidation.error);
  }
}

if (validationErrors.length > 0) {
  console.error('❌ JSON5 Validation Errors:');
  validationErrors.forEach(error => {
    console.error(`   ${error}`);
  });
  console.error('\nPlease fix the errors above and restart the application.');
}

// Load configuration from mounted yahlp.json5 and sites.json5
// Configuration priority: Environment variables > JSON5 files > Defaults
// JSON5 format allows comments and provides the base configuration
let jsonConfig = {};
let sitesConfig = { sites: [] };

if (fs.existsSync(configPath)) {
  try {
    jsonConfig = JSON5.parse(fs.readFileSync(configPath, 'utf8'));
    console.log('✓ Configuration loaded from yahlp.json5');
    console.log('  Note: Environment variables will override JSON5 values');

    // Log what's configured
    const hasServices = jsonConfig.services && Object.keys(jsonConfig.services).length > 0;
    const hasAuth = jsonConfig.auth?.type;
    const hasGoogleAuth = jsonConfig.google?.client_id;
    const hasEntraAuth = jsonConfig.entra?.client_id;
    const hasDashboard = jsonConfig.dashboard?.name;

    console.log('  Services in JSON5:', hasServices ? Object.keys(jsonConfig.services).length : '0');
    console.log('  Auth configured:', hasAuth || 'none');
    if (hasGoogleAuth) console.log('  Google OAuth: configured');
    if (hasEntraAuth) console.log('  Entra OAuth: configured');
    if (hasDashboard) console.log('  Dashboard: ' + jsonConfig.dashboard.name);
  } catch (err) {
    console.error('Error loading yahlp.json5:', err.message);
  }
} else {
  console.warn('⚠ yahlp.json5 not found at', configPath);
}

if (fs.existsSync(sitesPath)) {
  try {
    sitesConfig = JSON5.parse(fs.readFileSync(sitesPath, 'utf8'));
    console.log('✓ Sites loaded from sites.json5:', (sitesConfig.sites || []).length, 'sites');
  } catch (err) {
    console.error('Error loading sites.json5:', err.message);
  }
}

// Helper function to get nested config value from JSON object
function getNestedValue(obj, path) {
  return path.split('.').reduce((current, key) => current?.[key], obj);
}

// Helper function to get config value: env vars override JSON5, which overrides defaults
function getConfigValue(service, key) {
  // Check environment variable first (highest priority)
  const envKey = `${service.toUpperCase()}_${key.toUpperCase()}`;
  const envValue = process.env[envKey];
  if (envValue !== undefined) return envValue;

  // Fall back to JSON5 config
  const jsonValue = jsonConfig.services?.[service]?.[key];
  if (jsonValue !== undefined) return jsonValue;

  return undefined;
}

// Helper function to get any config value with env var override support
function getConfig(path, defaultValue) {
  // Check environment variable first (highest priority)
  // Convert path like 'dashboard.name' to 'DASHBOARD_NAME'
  const envKey = path.toUpperCase().replace(/\./g, '_');
  const envValue = process.env[envKey];
  if (envValue !== undefined) return envValue;

  // Fall back to JSON5 config
  const jsonValue = getNestedValue(jsonConfig, path);
  if (jsonValue !== undefined) return jsonValue;

  return defaultValue;
}

// Helper function to get boolean config value for a service (e.g., SERVICE_ENABLED)
function getBoolValue(service, key, defaultValue = false) {
  const envKey = `${service.toUpperCase()}_${key.toUpperCase()}`;
  const envValue = process.env[envKey];
  if (envValue !== undefined) {
    return envValue.toLowerCase() === 'true' || envValue === '1';
  }

  // Fall back to JSON5 config
  const jsonValue = jsonConfig.services?.[service]?.[key];
  if (jsonValue !== undefined) {
    return Boolean(jsonValue);
  }

  return defaultValue;
}

// API Proxy port - hardcoded as 3000, not configurable
const PORT = 3000;

// Service URL and key configuration - all from yahlp.json5
const services = {
  'jellyfin': { enabled: getBoolValue('jellyfin', 'enabled', false), url: getConfigValue('jellyfin', 'url'), key: getConfigValue('jellyfin', 'api_key'), authType: 'mediabrowser' },
  'plex': { enabled: getBoolValue('plex', 'enabled', false), url: getConfigValue('plex', 'url'), key: getConfigValue('plex', 'api_key'), authType: 'plex' },
  'emby': { enabled: getBoolValue('emby', 'enabled', false), url: getConfigValue('emby', 'url'), key: getConfigValue('emby', 'api_key'), authType: 'query' },
  'sonarr': { enabled: getBoolValue('sonarr', 'enabled', false), url: getConfigValue('sonarr', 'url'), key: getConfigValue('sonarr', 'api_key'), authType: 'header' },
  'radarr': { enabled: getBoolValue('radarr', 'enabled', false), url: getConfigValue('radarr', 'url'), key: getConfigValue('radarr', 'api_key'), authType: 'header' },
  'lidarr': { enabled: getBoolValue('lidarr', 'enabled', false), url: getConfigValue('lidarr', 'url'), key: getConfigValue('lidarr', 'api_key'), authType: 'header' },
  'whisparr': { enabled: getBoolValue('whisparr', 'enabled', false), url: getConfigValue('whisparr', 'url'), key: getConfigValue('whisparr', 'api_key'), authType: 'header' },
  'qbittorrent': { enabled: getBoolValue('qbittorrent', 'enabled', false), url: getConfigValue('qbittorrent', 'url'), key: getConfigValue('qbittorrent', 'api_key'), authType: 'qbittorrent' },
  'transmission': { enabled: getBoolValue('transmission', 'enabled', false), url: getConfigValue('transmission', 'url'), authType: 'transmission' },
  'sabnzbd': { enabled: getBoolValue('sabnzbd', 'enabled', false), url: getConfigValue('sabnzbd', 'url'), key: getConfigValue('sabnzbd', 'api_key'), authType: 'query' },
  'nzbget': { enabled: getBoolValue('nzbget', 'enabled', false), url: getConfigValue('nzbget', 'url'), username: getConfigValue('nzbget', 'username'), password: getConfigValue('nzbget', 'password'), authType: 'nzbget' },
  'deluge': { enabled: getBoolValue('deluge', 'enabled', false), url: getConfigValue('deluge', 'url'), key: getConfigValue('deluge', 'password'), authType: 'deluge' },
  'nzbhydra': { enabled: getBoolValue('nzbhydra', 'enabled', false), url: getConfigValue('nzbhydra', 'url'), key: getConfigValue('nzbhydra', 'api_key'), authType: 'header' },
  'jackett': { enabled: getBoolValue('jackett', 'enabled', false), url: getConfigValue('jackett', 'url'), key: getConfigValue('jackett', 'api_key'), authType: 'query' },
  'prowlarr': { enabled: getBoolValue('prowlarr', 'enabled', false), url: getConfigValue('prowlarr', 'url'), key: getConfigValue('prowlarr', 'api_key'), authType: 'header' },
  'seerr': { enabled: getBoolValue('seerr', 'enabled', false), url: getConfigValue('seerr', 'url'), key: getConfigValue('seerr', 'api_key'), authType: 'header' },
  'bazarr': { enabled: getBoolValue('bazarr', 'enabled', false), url: getConfigValue('bazarr', 'url'), key: getConfigValue('bazarr', 'api_key'), authType: 'bazarr' },
  'tautulli': { enabled: getBoolValue('tautulli', 'enabled', false), url: getConfigValue('tautulli', 'url'), key: getConfigValue('tautulli', 'api_key'), authType: 'query' },
  'maintainerr': { enabled: getBoolValue('maintainerr', 'enabled', false), url: getConfigValue('maintainerr', 'url'), key: getConfigValue('maintainerr', 'api_key'), authType: 'header' }
};

// Check if any services are configured
// Services that don't require API keys: transmission, qbittorrent
const noKeyRequired = ['transmission', 'qbittorrent'];
const configuredServices = Object.keys(services).filter(key => {
  const svc = services[key];
  if (noKeyRequired.includes(key)) {
    return !!svc.url;
  }
  return svc.url && svc.key;
});
const hasConfiguredServices = configuredServices.length > 0;

if (!hasConfiguredServices) {
  console.warn('[Proxy] No services configured. Proxy will have limited functionality.');
}

// Generic request helper
async function makeRequest(serviceKey, endpoint, options = {}) {
  const config = services[serviceKey];
  if (!config || !config.url) {
    throw new Error(`Service ${serviceKey} not configured`);
  }

  // Check for required authentication based on auth type
  switch (config.authType) {
    case 'qbittorrent':
      // qBittorrent requires API key
      if (!config.key) {
        throw new Error(`Service ${serviceKey} not configured`);
      }
      break;
    case 'nzbget':
      // NZBGet requires username and password
      if (!config.username || !config.password) {
        throw new Error(`Service ${serviceKey} not configured`);
      }
      break;
    case 'transmission':
      // Transmission doesn't require auth for stats
      break;
    default:
      // All other services require an API key
      if (!config.key) {
        throw new Error(`Service ${serviceKey} not configured`);
      }
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
      // Transmission uses session ID from server response, no auth needed for status check
      break;
    case 'qbittorrent':
      // qBittorrent uses API key in cookie or header
      headers['Cookie'] = `qBittorrentAPIToken=${config.key}`;
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

    const config = services['tautulli'];
    if (!config.url || !config.key) {
      throw new Error('Tautulli not configured');
    }

    // Append /tautulli to SERVICE_URL if not already present
    const baseUrl = config.url.endsWith('/tautulli') ? config.url : `${config.url}/tautulli`;

    const librariesUrl = `${baseUrl}/api/v2?apikey=${encodeURIComponent(config.key)}&cmd=get_libraries`;
    const librariesResp = await fetch(librariesUrl);
    if (!librariesResp.ok) {
      throw new Error(`Tautulli libraries HTTP ${librariesResp.status}`);
    }
    const librariesData = await librariesResp.json();

    const usersUrl = `${baseUrl}/api/v2?apikey=${encodeURIComponent(config.key)}&cmd=get_users`;
    const usersResp = await fetch(usersUrl);
    if (!usersResp.ok) {
      throw new Error(`Tautulli users HTTP ${usersResp.status}`);
    }
    const usersData = await usersResp.json();

    const users = usersData.response?.data || [];
    const topUser = users.length > 0 ? users[0].friendly_name : 'N/A';
    const libraries = librariesData.response?.data || [];
    const totalLibraries = libraries.length;

    const result = {
      topUser,
      users: users.length,
      libraries: totalLibraries
    };

    cache.set('tautulli-status', result);
    res.json(result);
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

// Jackett health check
app.get('/api/jackett/health', async (req, res) => {
  try {
    const cached = cache.get('jackett-health');
    if (cached) return res.json(cached);

    const config = services['jackett'];
    if (!config || !config.url || !config.key) {
      return res.status(404).json({ error: 'Jackett not configured' });
    }

    // Jackett API endpoint for health check (assumes /jackett baseURL like other proxies)
    const healthUrl = `${config.url}/jackett/api/v2.0/indexers/all/results?apikey=${encodeURIComponent(config.key)}&Query=test`;

    const response = await fetch(healthUrl);

    if (!response.ok) {
      return res.status(response.status).json({ error: 'Jackett offline' });
    }

    const data = await response.json();
    const result = { status: 'ok', results: data.Results ? data.Results.length : 0 };
    cache.set('jackett-health', result);
    res.json(result);
  } catch (err) {
    console.log('[Jackett Health Check Exception]', err.message);
    res.status(500).json({ error: err.message });
  }
});

// NZBHydra endpoints (GET/POST for compatibility)
// Just checks if nzbhydra is online - returns empty object since caps endpoint returns XML
const nzbhydraHandler = async (req, res) => {
  try {
    const cached = cache.get('nzbhydra-status');
    if (cached) return res.json(cached);

    const config = services['nzbhydra'];
    if (!config.url || !config.key) {
      throw new Error('NZBHydra not configured');
    }

    // Check if nzbhydra is accessible via caps endpoint
    // Append /nzbhydra to SERVICE_URL if not already present
    const baseUrl = config.url.endsWith('/nzbhydra') ? config.url : `${config.url}/nzbhydra`;
    const url = `${baseUrl}/api?t=caps&apikey=${encodeURIComponent(config.key)}`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`NZBHydra HTTP ${response.status}`);
    }

    // If we got a response, nzbhydra is online
    const result = {};
    cache.set('nzbhydra-status', result);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

app.get('/api/nzbhydra', nzbhydraHandler);
app.post('/api/nzbhydra', nzbhydraHandler);

// Sonarr endpoints
app.get('/api/sonarr/queue', async (req, res) => {
  try {
    const cached = cache.get('sonarr-queue');
    if (cached) return res.json(cached);

    const data = await makeRequest('sonarr', '/api/v3/queue');
    const queue = Array.isArray(data) ? data : data.records || [];

    const result = {
      queue: queue.length,
      downloading: queue.filter(i => i.status === 'Downloading').length,
      completed: queue.filter(i => i.status === 'Completed').length
    };

    cache.set('sonarr-queue', result);
    res.json(result);
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
    const queue = Array.isArray(data) ? data : data.records || [];

    const result = {
      queue: queue.length,
      downloading: queue.filter(i => i.status === 'Downloading').length,
      completed: queue.filter(i => i.status === 'Completed').length
    };

    cache.set('radarr-queue', result);
    res.json(result);
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
    const queue = Array.isArray(data) ? data : data.records || [];

    const result = {
      queue: queue.length,
      downloading: queue.filter(i => i.status === 'Downloading').length,
      completed: queue.filter(i => i.status === 'Completed').length
    };

    cache.set('lidarr-queue', result);
    res.json(result);
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
    const queue = Array.isArray(data) ? data : data.records || [];

    const result = {
      queue: queue.length,
      downloading: queue.filter(i => i.status === 'Downloading').length,
      completed: queue.filter(i => i.status === 'Completed').length
    };

    cache.set('whisparr-queue', result);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// qBittorrent endpoints
app.get('/api/qbittorrent/stats', async (req, res) => {
  try {
    const cached = cache.get('qbittorrent-stats');
    if (cached) return res.json(cached);

    const torrents = await makeRequest('qbittorrent', '/api/v2/torrents/info');
    const active = (torrents || []).filter(t => t.state.includes('dl')).length;
    const seeding = (torrents || []).filter(t => t.state.includes('up')).length;
    const dlSpeed = (torrents || []).reduce((sum, t) => sum + (t.dl_speed || 0), 0);
    const ulSpeed = (torrents || []).reduce((sum, t) => sum + (t.up_speed || 0), 0);

    const result = {
      active,
      seeding,
      total: torrents?.length || 0,
      dlSpeed: Math.round(dlSpeed / 1024 / 1024 * 100) / 100,
      ulSpeed: Math.round(ulSpeed / 1024 / 1024 * 100) / 100
    };

    cache.set('qbittorrent-stats', result);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Transmission endpoints
app.post('/api/transmission/stats', async (req, res) => {
  try {
    const cached = cache.get('transmission-stats');
    if (cached) return res.json(cached);

    const config = services['transmission'];
    if (!config.url) {
      throw new Error('Transmission not configured');
    }

    const payload = { method: 'session-stats' };

    let response = await fetch(`${config.url}/transmission/rpc`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (response.status === 409) {
      const sessionId = response.headers.get('X-Transmission-Session-Id');
      if (sessionId) {
        response = await fetch(`${config.url}/transmission/rpc`, {
          method: 'POST',
          headers: {
            'X-Transmission-Session-Id': sessionId,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(payload)
        });
      }
    }

    const data = await response.json();
    const args = data.arguments || {};

    const result = {
      active: args.activeTorrentCount || 0,
      paused: args.pausedTorrentCount || 0,
      dlSpeed: Math.round((args.downloadSpeed || 0) / 1024 / 1024 * 100) / 100,
      ulSpeed: Math.round((args.uploadSpeed || 0) / 1024 / 1024 * 100) / 100
    };

    cache.set('transmission-stats', result);
    res.json(result);
  } catch (err) {
    console.error('[TRANSMISSION]', err.message);
    res.status(500).json({ error: err.message });
  }
});

// SABnzbd endpoints
app.get('/api/sabnzbd/stats', async (req, res) => {
  try {
    const cached = cache.get('sabnzbd-stats');
    if (cached) return res.json(cached);

    const config = services['sabnzbd'];
    if (!config.url || !config.key) {
      throw new Error('SABnzbd not configured');
    }

    const url = `${config.url}/api?mode=queue&output=json&apikey=${encodeURIComponent(config.key)}`;
    const response = await fetch(url);
    const data = await response.json();

    const queue = data.queue?.slots || [];
    const dlSpeed = parseFloat(data.queue?.kbps || 0);

    const result = {
      queue: queue.length,
      items: queue.length,
      dlSpeed: Math.round(dlSpeed / 1024 * 100) / 100
    };

    cache.set('sabnzbd-stats', result);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// NZBGet endpoints
app.post('/api/nzbget/stats', async (req, res) => {
  try {
    const cached = cache.get('nzbget-stats');
    if (cached) return res.json(cached);

    const config = services['nzbget'];
    if (!config.url || !config.username || !config.password) {
      throw new Error('NZBGet not configured');
    }

    const payload = {
      version: '1.1',
      method: 'status',
      params: [],
      id: 1
    };

    const basicAuth = Buffer.from(config.username + ':' + config.password).toString('base64');
    const response = await fetch(`${config.url}/jsonrpc`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ' + basicAuth
      },
      body: JSON.stringify(payload),
      timeout: 10000
    });

    if (!response.ok) {
      throw new Error(`NZBGet HTTP ${response.status}`);
    }

    const data = await response.json();
    const result = data.result || {};

    const result_clean = {
      downloading: result.ArticlesDownloading || 0,
      remaining: result.RemainingSizeMB || 0,
      dlSpeed: Math.round((result.DownloadRate || 0) / 1024 / 1024 * 100) / 100
    };

    cache.set('nzbget-stats', result_clean);
    res.json(result_clean);
  } catch (err) {
    console.error('[NZBGET]', err.message);
    res.status(500).json({ error: err.message });
  }
});

// Deluge login endpoint - returns session cookie for web UI authentication
app.get('/api/deluge/login', async (req, res) => {
  try {
    const config = services['deluge'];
    if (!config.enabled) {
      throw new Error('Deluge not enabled');
    }
    if (!config.url || !config.key) {
      throw new Error('Deluge not configured');
    }


    const authPayload = {
      method: 'auth.login',
      params: [config.key],
      id: 1
    };

    const response = await fetch(`${config.url}/json`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(authPayload),
      timeout: 10000
    });


    if (!response.ok) {
      throw new Error(`Deluge auth HTTP ${response.status}`);
    }

    const authData = await response.json();

    if (!authData || !authData.result) {
      throw new Error('Deluge auth failed');
    }

    // Extract session cookie
    const setCookie = response.headers.get('set-cookie');

    if (!setCookie) {
      throw new Error('No session cookie received from Deluge');
    }

    // Parse cookie and attributes
    const cookieParts = setCookie.split(';').map(s => s.trim());
    const sessionCookie = cookieParts[0]; // name=value

    // Build cookie string for client with necessary attributes
    const cookieString = `${sessionCookie}; path=/; SameSite=Lax`;

    res.json({
      success: true,
      cookie: cookieString,
      url: `${config.url}/`
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Deluge endpoints
app.post('/api/deluge/stats', async (req, res) => {
  try {
    const config = services['deluge'];
    if (!config.enabled) {
      throw new Error('Deluge not enabled');
    }

    const cached = cache.get('deluge-stats');
    if (cached) return res.json(cached);

    if (!config.url || !config.key) {
      throw new Error('Deluge not configured');
    }

    // First auth
    let authPayload = {
      method: 'auth.login',
      params: [config.key],
      id: 1
    };
    let response = await fetch(`${config.url}/json`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(authPayload),
      timeout: 10000
    });

    if (!response.ok) {
      throw new Error(`Deluge auth HTTP ${response.status}`);
    }

    let authData = await response.json();
    if (!authData || !authData.result) {
      throw new Error('Deluge auth failed');
    }

    // Extract cookies from auth response
    const setCookie = response.headers.get('set-cookie');
    const cookieHeader = setCookie ? setCookie.split(';')[0] : '';

    // Get torrents with cookie
    let statsPayload = {
      method: 'core.get_torrents_status',
      params: [[], ['state']],
      id: 2
    };
    const headers = { 'Content-Type': 'application/json' };
    if (cookieHeader) {
      headers['Cookie'] = cookieHeader;
    }

    response = await fetch(`${config.url}/json`, {
      method: 'POST',
      headers,
      body: JSON.stringify(statsPayload),
      timeout: 10000
    });

    const data = await response.json();

    // Get speed stats
    const speedPayload = {
      method: 'core.get_session_status',
      params: [['download_rate', 'upload_rate']],
      id: 3
    };
    const speedResponse = await fetch(`${config.url}/json`, {
      method: 'POST',
      headers,
      body: JSON.stringify(speedPayload),
      timeout: 10000
    });
    const speedData = await speedResponse.json();
    const speedResult = speedData.result || {};

    const torrents = Object.values(data.result || {});
    const downloading = torrents.filter(t =>
      t.state && ['Downloading', 'Allocating'].includes(t.state)
    ).length;

    const result = {
      downloading,
      total: torrents.length,
      dlSpeed: Math.round((speedResult.download_rate || 0) / 1024 / 1024 * 100) / 100,
      ulSpeed: Math.round((speedResult.upload_rate || 0) / 1024 / 1024 * 100) / 100
    };

    cache.set('deluge-stats', result);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Jellyfin endpoints
app.get('/api/jellyfin/auth', async (req, res) => {
  try {
    const config = services['jellyfin'];
    if (!config.enabled) {
      return res.json({ authenticated: false, error: 'Jellyfin not enabled' });
    }

    const username = getConfigValue('jellyfin', 'username');
    const password = getConfigValue('jellyfin', 'password');

    console.log('[Jellyfin Auth] Username provided:', !!username, 'Password provided:', !!password);
    console.log('[Jellyfin Auth] Jellyfin URL:', config?.url);

    // If credentials not provided, skip auto-auth
    if (!username || !password) {
      console.log('[Jellyfin Auth] Credentials not configured, skipping auto-auth');
      return res.json({ authenticated: false, error: 'Credentials not configured' });
    }

    // Check cache first
    const cached = cache.get('jellyfin-auth-token');
    if (cached) {
      return res.json({ authenticated: true, token: cached });
    }

    // Authenticate with Jellyfin
    const authResponse = await fetch(`${config.url}/Users/AuthenticateByName`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        Username: username,
        Pw: password,
        RememberMe: true
      })
    });

    if (!authResponse.ok) {
      return res.json({ authenticated: false, error: 'Authentication failed' });
    }

    const authData = await authResponse.json();
    const token = authData.AccessToken;

    if (token) {
      // Cache token for 1 hour
      cache.set('jellyfin-auth-token', token, 3600);
      res.json({ authenticated: true, token });
    } else {
      res.json({ authenticated: false, error: 'No token received' });
    }
  } catch (err) {
    res.status(500).json({ authenticated: false, error: err.message });
  }
});

app.get('/api/jellyfin/info', async (req, res) => {
  try {
    const config = services['jellyfin'];
    if (!config.enabled) {
      return res.status(503).json({ error: 'Jellyfin not enabled' });
    }

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
app.get('/api/maintainerr/api/overlays/sections', async (req, res) => {
  try {
    const cached = cache.get('maintainerr-sections');
    if (cached) return res.json(cached);

    const config = services['maintainerr'];
    if (!config.url || !config.key) {
      throw new Error('Maintainerr not configured');
    }

    // Append /maintainerr to SERVICE_URL if not already present
    const baseUrl = config.url.endsWith('/maintainerr') ? config.url : `${config.url}/maintainerr`;
    const url = `${baseUrl}/api/overlays/sections`;
    const response = await fetch(url, {
      headers: { 'X-Api-Key': config.key }
    });
    if (!response.ok) {
      throw new Error(`Maintainerr HTTP ${response.status}`);
    }

    const data = await response.json();
    cache.set('maintainerr-sections', data);
    res.json(data || []);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/maintainerr/api/storage-metrics/library-sizes', async (req, res) => {
  try {
    const cached = cache.get('maintainerr-sizes');
    if (cached) return res.json(cached);

    const config = services['maintainerr'];
    if (!config.url || !config.key) {
      throw new Error('Maintainerr not configured');
    }

    // Append /maintainerr to SERVICE_URL if not already present
    const baseUrl = config.url.endsWith('/maintainerr') ? config.url : `${config.url}/maintainerr`;
    const url = `${baseUrl}/api/storage-metrics/library-sizes`;
    const response = await fetch(url, {
      headers: { 'X-Api-Key': config.key }
    });
    if (!response.ok) {
      throw new Error(`Maintainerr HTTP ${response.status}`);
    }

    const data = await response.json();
    cache.set('maintainerr-sizes', data);
    res.json(data || []);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Service code mapping
const codeToService = {
  'JEL': 'jellyfin', 'PLX': 'plex', 'EMB': 'emby',
  'SON': 'sonarr', 'RAD': 'radarr', 'LID': 'lidarr', 'WHI': 'whisparr',
  'QBI': 'qbittorrent', 'TRA': 'transmission', 'GET': 'nzbget', 'SAB': 'sabnzbd',
  'DEL': 'deluge', 'HYD': 'nzbhydra', 'JAC': 'jackett', 'PRO': 'prowlarr', 'SEE': 'seerr',
  'BAZ': 'bazarr', 'TAU': 'tautulli', 'MNT': 'maintainerr'
};

// Configuration endpoints - serve dashboard and sites configuration
// These support environment variable overrides
app.get('/api/config/dashboard', (req, res) => {
  let order = getConfig('dashboard.order', null);

  // Handle DASHBOARD_ORDER environment variable (comma-separated 3-letter codes)
  if (process.env.DASHBOARD_ORDER) {
    order = process.env.DASHBOARD_ORDER.split(',').map(s => s.trim().toUpperCase());
  }

  // Fall back to JSON5 order or default order
  if (!order) {
    order = jsonConfig.dashboard?.order || [
      'JEL', 'PLX', 'EMB',
      'SON', 'RAD', 'LID', 'WHI',
      'QBI', 'TRA',
      'SAB', 'GET', 'DEL',
      'HYD', 'PRO', 'SEE',
      'BAZ', 'TAU', 'MNT',
    ];
  }

  const dashboard = {
    name: getConfig('dashboard.name', 'YAHLP Dashboard'),
    icon_url: getConfig('dashboard.icon_url', 'https://via.placeholder.com/64'),
    color: getConfig('dashboard.color', '#00A99D'),
    theme: getConfig('dashboard.theme', 'dark'),
    style: getConfig('dashboard.style', 'classic'),
    landing: getConfig('dashboard.landing', 'dashboard'),
    order: order
  };
  res.json(dashboard);
});

// Built-in torrent and usenet sites (icons stored in /var/www/html/sites-icons/ as lowercase)
const builtInSites = {
  'TPB': { code: 'TPB', name: 'The Pirate Bay', url: 'https://thepiratebay.org', icon: '/sites-icons/tpb.favicon.ico', category: 'torrent' },
  'FIL': { code: 'FIL', name: 'FileList.io', url: 'https://filelist.io', icon: '/sites-icons/fil.favicon.ico', category: 'torrent' },
  'HDB': { code: 'HDB', name: 'HDBits', url: 'https://hdbits.org', icon: '/sites-icons/hdb.favicon.ico', category: 'torrent' },
  'IPT': { code: 'IPT', name: 'IP Torrents', url: 'https://iptorrents.com', icon: '/sites-icons/ipt.favicon.ico', category: 'torrent' },
  '1337': { code: '1337', name: '1337x', url: 'https://1337x.to', icon: '/sites-icons/1337.favicon.ico', category: 'torrent' },
  'YTS': { code: 'YTS', name: 'YTS', url: 'https://yts.torrentbay.st', icon: '/sites-icons/yts.favicon.ico', category: 'torrent' },
  'LAT': { code: 'LAT', name: 'LimeTorrents', url: 'https://limetorrents.cc', icon: '/sites-icons/lat.favicon.ico', category: 'torrent' },
  'NYA': { code: 'NYA', name: 'Nyaa', url: 'https://nyaa.si', icon: '/sites-icons/nya.favicon.ico', category: 'torrent' },
  'PTP': { code: 'PTP', name: 'PassThePopcorn', url: 'https://passthepopcorn.me', icon: '/sites-icons/ptp.favicon.ico', category: 'torrent' },
  'DOG': { code: 'DOG', name: 'DOGnzb', url: 'https://dognzb.cr/browse', icon: '/sites-icons/dog.favicon.ico', category: 'usenet' },
  'DRS': { code: 'DRS', name: 'DrunkenSlug', url: 'https://www.drunkenslug.com', icon: '/sites-icons/drs.favicon.ico', category: 'usenet' },
  'NLF': { code: 'NLF', name: 'nzb.life', url: 'https://nzb.life', icon: '/sites-icons/nlf.favicon.ico', category: 'usenet' },
  'NFW': { code: 'NFW', name: 'NZBFinder.ws', url: 'https://nzbfinder.ws', icon: '/sites-icons/nfw.favicon.ico', category: 'usenet' },
  'NGK': { code: 'NGK', name: 'NZBgeek', url: 'https://nzbgeek.info', icon: '/sites-icons/ngk.favicon.ico', category: 'usenet' },
  'PLA': { code: 'PLA', name: 'nzbplanet.net', url: 'https://nzbplanet.net', icon: '/sites-icons/pla.favicon.ico', category: 'usenet' },
  'TAB': { code: 'TAB', name: 'Tabula Rasa', url: 'https://tabula-rasa.pw', icon: '/sites-icons/tab.favicon.ico', category: 'usenet' },
};

app.get('/api/config/sites', (req, res) => {
  const allSites = [];

  // Get sites from dashboard.sites config or DASHBOARD_SITES env var (env var takes precedence)
  let dashboardSites = jsonConfig.dashboard?.sites || [];
  const envDashboardSites = process.env.DASHBOARD_SITES ?
    process.env.DASHBOARD_SITES.split(',').map(s => s.trim().toUpperCase()) : [];

  // Environment variable takes precedence over JSON5 config
  const siteCodes = envDashboardSites.length > 0 ? envDashboardSites : dashboardSites.map(s => s.toUpperCase ? s.toUpperCase() : s);

  // Add built-in sites if any are specified
  if (siteCodes.length > 0) {
    siteCodes.forEach(code => {
      if (builtInSites[code]) {
        allSites.push(builtInSites[code]);
      }
    });
  }

  // Add custom sites from sites.json5 (those with enabled: true)
  const customSites = sitesConfig.sites || [];
  customSites.forEach(site => {
    if (site.enabled !== false) {
      allSites.push(site);
    }
  });

  res.json(allSites);
});

app.get('/api/config/access', (req, res) => {
  const access = {
    mode: getConfig('access.mode', 'localhost'),
    domain: getConfig('access.domain', 'localhost:3000'),
    protocol: getConfig('access.protocol', 'http')
  };
  res.json(access);
});

app.get('/api/config/auth', (req, res) => {
  const authType = getConfig('auth.type', 'none');
  // Never send secrets to frontend - only type and provider info
  const safeAuth = { type: authType };

  // Add Google OAuth config (without secrets)
  if (authType === 'google' || jsonConfig.google?.client_id) {
    safeAuth.google = {
      client_id: process.env.GOOGLE_CLIENT_ID || jsonConfig.google?.client_id || '',
      redirect_uri: process.env.GOOGLE_REDIRECT_URI || jsonConfig.google?.redirect_uri || '',
    };
  }

  // Add Entra OAuth config (without secrets)
  if (authType === 'entra' || jsonConfig.entra?.client_id) {
    safeAuth.entra = {
      client_id: process.env.ENTRA_CLIENT_ID || jsonConfig.entra?.client_id || '',
      redirect_uri: process.env.ENTRA_REDIRECT_URI || jsonConfig.entra?.redirect_uri || '',
    };
  }

  res.json(safeAuth);
});

// Helper to check if any services with API keys are configured
function hasConfiguredApiServices() {
  const apiServices = ['qbittorrent', 'nzbget', 'jackett', 'prowlarr', 'sonarr', 'radarr', 'lidarr', 'whisparr', 'seerr', 'bazarr', 'sabnzbd', 'nzbhydra', 'tautulli', 'maintainerr', 'jellyfin', 'emby', 'plex'];
  return apiServices.some(serviceName => {
    const config = services[serviceName];
    if (!config || !config.enabled) return false;
    if (!config.url) return false;

    if (serviceName === 'qbittorrent' || serviceName === 'nzbget') {
      if (serviceName === 'qbittorrent') return !!config.key;
      if (serviceName === 'nzbget') return !!(config.username && config.password);
    }
    return !!config.key;
  });
}

// Helper to check if a service is properly configured based on its auth type
function isServiceConfigured(serviceName, config) {
  // Service must be enabled first
  if (!config.enabled) return false;
  if (!config.url) return false;

  switch (config.authType) {
    case 'transmission':
    case 'deluge':
      // These download clients only show as configured if other services with API keys are also configured
      if (!hasConfiguredApiServices()) return false;
      if (config.authType === 'transmission') return !!config.url;
      if (config.authType === 'deluge') return !!config.url && !!config.key;
      break;
    case 'qbittorrent':
      return !!config.url && !!config.key;
    case 'nzbget':
      return !!config.username && !!config.password;
    default:
      return !!config.key;
  }
}

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
      acc[svc] = { configured: isServiceConfigured(svc, services[svc]) };
      return acc;
    }, {})
  });
});

// Listen on both IPv4 and IPv6
const http = require('http');
const net = require('net');

const server = http.createServer(app);

// Listen on IPv4
server.listen(PORT, '0.0.0.0');

// Listen on IPv6
const server6 = http.createServer(app);
server6.listen(PORT, '::');

server.on('listening', () => {
  const addr = server.address();
  console.log(`🔀 API Aggregator listening on port ${PORT}`);
  console.log(`   IPv4: http://localhost:${PORT}`);
  console.log(`   IPv6: http://[::1]:${PORT}`);
  console.log(`   Cache TTL: 30 seconds`);
  console.log(`   Health check: http://localhost:${PORT}/health`);
  console.log('\nConfigured services:');
  Object.entries(services).forEach(([service, config]) => {
    const status = isServiceConfigured(service, config) ? '✅' : '⏳';
    console.log(`   ${status} ${service}`);
  });
});

server6.on('error', (err) => {
  if (err.code !== 'EADDRINUSE') throw err;
  console.error(`IPv6 listen error: ${err.message}`);
});
