enum Environment { development, production }

class AppConfig {
  static Environment environment = Environment.development;

  static String get baseUrl {
    switch (environment) {
      case Environment.development:
        return 'https://recycling-amnesty-robbing.ngrok-free.dev/api';
      case Environment.production:
        //Not implemented yet
        return '';
    }
  }

  // The webcam streamer running on the PC the USB webcam is plugged into.
  // On the same Wi-Fi/LAN use the PC's local IP, e.g. http://192.168.1.20:5001
  static const String webcamStreamerBaseUrl = 'http://10.191.255.52:5001';

  static String get webcamStreamUrl => '$webcamStreamerBaseUrl/stream';
  static String get webcamSnapshotUrl => '$webcamStreamerBaseUrl/snapshot';

  // Server root (without the trailing /api) — used to build absolute image URLs.
  static String get serverRoot => baseUrl.replaceAll('/api', '');
}
