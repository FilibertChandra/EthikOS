import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../models/post.dart';
import 'api_service.dart';

class PostService {
  Future<List<Post>> getPosts() async {
    final headers = await ApiService.getAuthHeaders();
    final response = await http.get(
      Uri.parse(ApiConstants.posts),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Post.fromJson(json)).toList();
    } else if (ApiService.handleUnauthorized(response.statusCode)) {
      throw Exception('Session expired. Please log in again.');
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<Post> createPost(String content, {Uint8List? imageBytes}) async {
    final headers = await ApiService.getAuthHeaders();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.posts),
    );
    // Carry over auth headers, but let http set the multipart Content-Type.
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.fields['content'] = content;

    if (imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'webcam-${DateTime.now().millisecondsSinceEpoch}.jpg',
        // Tag as JPEG so the backend's multer image filter accepts it.
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint('Create post response: ${response.body}');

    if (response.statusCode == 201) {
      return Post.fromJson(jsonDecode(response.body));
    } else if (ApiService.handleUnauthorized(response.statusCode)) {
      throw Exception('Session expired. Please log in again.');
    } else {
      throw Exception('Failed to create post');
    }
  }

  /// Grabs a single still JPEG from the webcam streamer running on the PC.
  Future<Uint8List> fetchWebcamSnapshot() async {
    final response = await http.get(Uri.parse(AppConfig.webcamSnapshotUrl));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to capture webcam snapshot');
    }
  }

  Future<void> likePost(String postId) async {
    final headers = await ApiService.getAuthHeaders();
    final response = await http.put(
      Uri.parse(ApiConstants.likePost(postId)),
      headers: headers,
    );

    if (ApiService.handleUnauthorized(response.statusCode)) {
      throw Exception('Session expired. Please log in again.');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to like post');
    }
  }

  Future<void> addComment(String postId, String text) async {
    final headers = await ApiService.getAuthHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.commentPost(postId)),
      headers: headers,
      body: jsonEncode({'text': text}),
    );

    if (ApiService.handleUnauthorized(response.statusCode)) {
      throw Exception('Session expired. Please log in again.');
    } else if (response.statusCode != 201) {
      throw Exception('Failed to add comment');
    }
  }
}
