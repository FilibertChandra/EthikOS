enum Environment { development, production }

class AppConfig {
  static Environment environment = Environment.development;

  static String get baseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://140.116.233.195:5000/api';
      case Environment.production:
        //Not implemented yet
        return '';
    }
  }
}
