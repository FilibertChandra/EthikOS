import '../config/app_config.dart';

class ApiConstants {
  static String get baseUrl => AppConfig.baseUrl;

  // Auth endpoints
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';

  // Post endpoints
  static String get posts => '$baseUrl/posts';
  static String likePost(String id) => '$baseUrl/posts/$id/like';
  static String commentPost(String id) => '$baseUrl/posts/$id/comment';
}
