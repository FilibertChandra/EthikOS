import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../models/post.dart';
import 'api_service.dart';

class PostService {
  // Network timeouts so a stalled request doesn't hang the app indefinitely. 15s for normal requests, 30s for uploads / ffmpeg snapshot.
  static const _timeout = Duration(seconds: 15);
  static const _uploadTimeout =
      Duration(seconds: 30); // uploads / ffmpeg snapshot

  static Never _timedOut() =>
      throw Exception('Request timed out. Please check your connection.');

  Future<List<Post>> getPosts() async {
    final headers = await ApiService.getAuthHeaders();
    final response = await http
        .get(
          Uri.parse(ApiConstants.posts),
          headers: headers,
        )
        .timeout(_timeout, onTimeout: _timedOut);

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

    final streamed =
        await request.send().timeout(_uploadTimeout, onTimeout: _timedOut);
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

  // (Legacy, webcam mode) Grabs a still JPEG from the local webcam streamer.
  //Kept so the webcam screen still compiles; not used while in CCTV mode.
  Future<Uint8List> fetchWebcamSnapshot() async {
    final response = await http.get(Uri.parse(AppConfig.webcamSnapshotUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to capture webcam snapshot');
    }
  }

  // Asks the backend to grab a single still JPEG from a CCTV HLS stream.
  // The backend uses ffmpeg to pull one frame from [hlsUrl].
  Future<Uint8List> fetchCctvSnapshot(String hlsUrl) async {
    final headers = await ApiService.getAuthHeaders();
    final response = await http
        .post(
          Uri.parse(ApiConstants.cctvSnapshot),
          headers: headers,
          body: jsonEncode({'url': hlsUrl}),
        )
        .timeout(_uploadTimeout, onTimeout: _timedOut);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else if (ApiService.handleUnauthorized(response.statusCode)) {
      throw Exception('Session expired. Please log in again.');
    } else {
      throw Exception('Failed to capture snapshot from stream');
    }
  }

  Future<void> likePost(String postId) async {
    final headers = await ApiService.getAuthHeaders();
    final response = await http
        .put(
          Uri.parse(ApiConstants.likePost(postId)),
          headers: headers,
        )
        .timeout(_timeout, onTimeout: _timedOut);

    if (ApiService.handleUnauthorized(response.statusCode)) {
      throw Exception('Session expired. Please log in again.');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to like post');
    }
  }

  Future<void> addComment(String postId, String text) async {
    final headers = await ApiService.getAuthHeaders();
    final response = await http
        .post(
          Uri.parse(ApiConstants.commentPost(postId)),
          headers: headers,
          body: jsonEncode({'text': text}),
        )
        .timeout(_timeout, onTimeout: _timedOut);

    if (ApiService.handleUnauthorized(response.statusCode)) {
      throw Exception('Session expired. Please log in again.');
    } else if (response.statusCode != 201) {
      throw Exception('Failed to add comment');
    }
  }
}
