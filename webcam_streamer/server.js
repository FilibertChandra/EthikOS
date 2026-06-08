// Webcam streamer — run this on the PC the USB webcam is plugged into.
//
// It uses ffmpeg to grab frames from the webcam and exposes two HTTP endpoints:
//   GET /stream    -> live MJPEG stream (multipart/x-mixed-replace) for the live preview
//   GET /snapshot  -> a single JPEG of the most recent frame (the "capture photo" action)
//
// Prerequisites:
//   1. Install ffmpeg and make sure `ffmpeg` is on your PATH.
//      Check with:  ffmpeg -version
//   2. Find your webcam's exact device name:
//      ffmpeg -list_devices true -f dshow -i dummy
//      Look for a line like:  "Integrated Camera" or "USB Video Device"
//   3. Put that name in WEBCAM_NAME below (or set the WEBCAM_NAME env var).
//
// Then:  npm install  &&  npm start

const express = require('express');
const { spawn } = require('child_process');

const PORT = process.env.PORT || 5001;
// The exact device name from `ffmpeg -list_devices true -f dshow -i dummy`.
const WEBCAM_NAME = process.env.WEBCAM_NAME || 'USB Video Device';
// Path to the ffmpeg binary. If ffmpeg isn't on your PATH, set FFMPEG_PATH to the
// full path of ffmpeg.exe, e.g. set FFMPEG_PATH=C:\ffmpeg\bin\ffmpeg.exe
const FFMPEG_PATH = process.env.FFMPEG_PATH || 'ffmpeg';

const app = express();

// Allow the phone (any LAN origin) to connect.
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', '*');
  next();
});

// --- Capture pipeline ---------------------------------------------------------
// We keep one ffmpeg process running and parse its MJPEG output into individual
// JPEG frames. The most recent frame is kept in memory for /snapshot, and every
// frame is pushed to all connected /stream clients.

const JPEG_START = Buffer.from([0xff, 0xd8]); // SOI marker
const JPEG_END = Buffer.from([0xff, 0xd9]); // EOI marker

let latestFrame = null;
const streamClients = new Set();
let buffer = Buffer.alloc(0);

function startFfmpeg() {
  // -f dshow -i video="<name>"  : capture from the named DirectShow webcam (Windows)
  // -f mjpeg -q:v 5 pipe:1      : output a stream of JPEGs to stdout
  const ffmpeg = spawn(FFMPEG_PATH, [
    '-f', 'dshow',
    '-i', `video=${WEBCAM_NAME}`,
    '-f', 'mjpeg',
    '-q:v', '5',
    'pipe:1',
  ]);

  // If ffmpeg can't be launched at all (e.g. not found on PATH), don't crash the
  // whole process with an unhandled 'error' event — print a clear message.
  ffmpeg.on('error', (err) => {
    if (err.code === 'ENOENT') {
      console.error('\n[ERROR] Could not find ffmpeg.');
      console.error('  Either add ffmpeg to your PATH, or set FFMPEG_PATH to the full');
      console.error('  path of ffmpeg.exe, e.g.:');
      console.error('    set FFMPEG_PATH=C:\\path\\to\\ffmpeg\\bin\\ffmpeg.exe');
      console.error('  Then run npm start again.\n');
    } else {
      console.error('[ffmpeg spawn error]', err);
    }
  });

  ffmpeg.stdout.on('data', (chunk) => {
    buffer = Buffer.concat([buffer, chunk]);

    // Extract every complete JPEG (SOI ... EOI) currently in the buffer.
    let start = buffer.indexOf(JPEG_START);
    let end = buffer.indexOf(JPEG_END, start + 2);
    while (start !== -1 && end !== -1) {
      const frame = buffer.slice(start, end + 2);
      latestFrame = frame;
      pushFrame(frame);

      buffer = buffer.slice(end + 2);
      start = buffer.indexOf(JPEG_START);
      end = buffer.indexOf(JPEG_END, start + 2);
    }
  });

  ffmpeg.stderr.on('data', (data) => {
    // ffmpeg logs progress to stderr; only surface obvious errors.
    const msg = data.toString();
    if (msg.toLowerCase().includes('error') || msg.includes('Could not')) {
      console.error('[ffmpeg]', msg.trim());
    }
  });

  ffmpeg.on('close', (code) => {
    console.error(`ffmpeg exited (code ${code}). Restarting in 2s...`);
    setTimeout(startFfmpeg, 2000);
  });
}

function pushFrame(frame) {
  for (const res of streamClients) {
    res.write(`--frame\r\nContent-Type: image/jpeg\r\nContent-Length: ${frame.length}\r\n\r\n`);
    res.write(frame);
    res.write('\r\n');
  }
}

// --- Routes -------------------------------------------------------------------

app.get('/stream', (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'multipart/x-mixed-replace; boundary=frame',
    'Cache-Control': 'no-cache',
    Connection: 'close',
    Pragma: 'no-cache',
  });

  streamClients.add(res);
  req.on('close', () => streamClients.delete(res));
});

app.get('/snapshot', (req, res) => {
  if (!latestFrame) {
    return res.status(503).json({ message: 'No frame available yet' });
  }
  res.set('Content-Type', 'image/jpeg');
  res.send(latestFrame);
});

app.get('/', (req, res) => {
  res.json({ status: 'ok', webcam: WEBCAM_NAME, endpoints: ['/stream', '/snapshot'] });
});

startFfmpeg();
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Webcam streamer running on http://0.0.0.0:${PORT}`);
  console.log(`Capturing from device: "${WEBCAM_NAME}"`);
  console.log('Open http://localhost:%d/stream in a browser to test.', PORT);
});
