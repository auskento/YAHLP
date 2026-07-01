const express = require('express');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PROXY_PORT || 3000;

// Plex proxy endpoint
app.get('/proxy/plex/sessions', async (req, res) => {
  try {
    const plexToken = process.env.PLEX_API_KEY;
    const plexUrl = process.env.PLEX_URL;

    if (!plexToken || !plexUrl) {
      return res.status(400).json({ error: 'PLEX_API_KEY or PLEX_URL not configured' });
    }

    const url = `${plexUrl}/api/sessions.json?X-Plex-Token=${plexToken}`;
    console.log(`[PROXY] Fetching Plex sessions...`);

    const response = await fetch(url);
    if (!response.ok) {
      console.error(`[PROXY] Plex HTTP ${response.status}`);
      return res.status(response.status).json({ error: `Plex returned ${response.status}` });
    }

    const data = await response.json();
    console.log(`[PROXY] Plex success: ${data.MediaContainer?.Metadata?.length || 0} sessions`);
    res.json(data);
  } catch (err) {
    console.error('[PROXY] Plex error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// Seerr proxy endpoint
app.get('/proxy/seerr/request/count', async (req, res) => {
  try {
    const seerrToken = process.env.SEERR_API_KEY;
    const seerrUrl = process.env.SEERR_URL;

    if (!seerrToken || !seerrUrl) {
      return res.status(400).json({ error: 'SEERR_API_KEY or SEERR_URL not configured' });
    }

    const url = `${seerrUrl}/api/v1/request/count`;
    console.log(`[PROXY] Fetching Seerr request count...`);

    const response = await fetch(url, {
      headers: { 'X-Api-Key': seerrToken }
    });

    if (!response.ok) {
      console.error(`[PROXY] Seerr HTTP ${response.status}`);
      return res.status(response.status).json({ error: `Seerr returned ${response.status}` });
    }

    const data = await response.json();
    console.log(`[PROXY] Seerr success:`, data);
    res.json(data);
  } catch (err) {
    console.error('[PROXY] Seerr error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`🔀 API Proxy server listening on port ${PORT}`);
  console.log(`   Plex proxy: http://localhost:${PORT}/proxy/plex/sessions`);
  console.log(`   Seerr proxy: http://localhost:${PORT}/proxy/seerr/request/count`);
});
