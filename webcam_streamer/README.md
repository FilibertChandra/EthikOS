# Webcam Streamer

Runs on the **PC the USB webcam is plugged into**. It exposes the webcam over the
local network so the EthikOS mobile app can show a live preview and capture photos.

```
USB webcam  ->  this streamer (ffmpeg + Node)  ->  Wi-Fi/LAN  ->  EthikOS app
```

## Setup

1. **Install ffmpeg** and confirm it's on your PATH:
   ```
   ffmpeg -version
   ```
2. **Find your webcam's device name:**
   ```
   ffmpeg -list_devices true -f dshow -i dummy
   ```
   Copy the exact name (e.g. `Integrated Camera` or `USB Video Device`).
3. **Install deps and run**, passing your webcam name:
   ```
   npm install
   set WEBCAM_NAME=USB Video Device
   npm start
   ```
   (On PowerShell: `$env:WEBCAM_NAME="USB Video Device"; npm start`)

## Test

- On the PC: open <http://localhost:5001/stream> (live video) and
  <http://localhost:5001/snapshot> (a still).
- Find the PC's LAN IP with `ipconfig` (e.g. `192.168.1.20`).
- From the phone's browser (same Wi-Fi): open `http://192.168.1.20:5001/stream`.

## Point the app at it

Set `webcamStreamerBaseUrl` in
`social_app/lib/config/app_config.dart` to `http://<PC-LAN-IP>:5001`.

## Over the internet (later)

Keep the streamer running and expose it with a tunnel, e.g.:
```
ngrok http 5001
```
Then use the ngrok URL as `webcamStreamerBaseUrl`. No app code changes needed.
