const express = require('express');
const { spawn } = require('child_process');
const router = express.Router();
const auth = require('../middleware/authMiddleware');

// All routes here require authentication
router.use(auth);

// Optional allowlist: comma-separated hostnames the snapshot URL may point at.
// e.g. CCTV_ALLOWED_HOSTS=portal.example.com,cdn.example.com
// If unset, any http(s) host is allowed (acceptable for the lab; tighten for prod).
const allowedHosts = (process.env.CCTV_ALLOWED_HOSTS || '')
  .split(',')
  .map((h) => h.trim())
  .filter(Boolean);

function isUrlAllowed(rawUrl) {
  let url;
  try {
    url = new URL(rawUrl);
  } catch {
    return false;
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return false;
  if (allowedHosts.length > 0 && !allowedHosts.includes(url.hostname)) return false;
  return true;
}

// POST /api/cctv/snapshot  { url: "<HLS .m3u8 url with token>" }
// Returns a single JPEG frame grabbed from the stream via ffmpeg.
router.post('/snapshot', (req, res, next) => {
  const { url } = req.body;

  if (!url || typeof url !== 'string') {
    return res.status(400).json({ message: 'Missing "url"' });
  }
  if (!isUrlAllowed(url)) {
    return res.status(400).json({ message: 'URL not allowed' });
  }

  // Grab one frame and write a JPEG to stdout.
  const ffmpeg = spawn('ffmpeg', [
    '-y',
    '-i', url,
    '-frames:v', '1',
    '-q:v', '2',
    '-f', 'image2',
    'pipe:1',
  ]);

  const chunks = [];
  let stderr = '';
  let finished = false;

  // Don't let a stalled stream hang the request forever.
  const timeout = setTimeout(() => {
    if (!finished) {
      finished = true;
      ffmpeg.kill('SIGKILL');
      res.status(504).json({ message: 'Snapshot timed out' });
    }
  }, 20000);

  ffmpeg.stdout.on('data', (chunk) => chunks.push(chunk));
  ffmpeg.stderr.on('data', (data) => { stderr += data.toString(); });

  ffmpeg.on('error', (err) => {
    if (finished) return;
    finished = true;
    clearTimeout(timeout);
    next(err);
  });

  ffmpeg.on('close', (code) => {
    if (finished) return;
    finished = true;
    clearTimeout(timeout);

    const image = Buffer.concat(chunks);
    if (code === 0 && image.length > 0) {
      res.set('Content-Type', 'image/jpeg');
      return res.send(image);
    }
    console.error('[cctv snapshot] ffmpeg failed:', stderr.split('\n').slice(-3).join(' '));
    res.status(502).json({ message: 'Failed to capture snapshot from stream' });
  });
});

module.exports = router;
