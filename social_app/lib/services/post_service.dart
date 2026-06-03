import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/post.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

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
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<Post> createPost(String content) async {
    final headers = await ApiService.getAuthHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.posts),
      headers: headers,
      body: jsonEncode({'content': content}),
    );

    debugPrint('Create post response: ${response.body}');

    if (response.statusCode == 201) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create post');
    }
  }

  Future<void> likePost(String postId) async {
    final headers = await ApiService.getAuthHeaders();
    final response = await http.put(
      Uri.parse(ApiConstants.likePost(postId)),
      headers: headers,
    );

    if (response.statusCode != 200) {
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

    if (response.statusCode != 201) {
      throw Exception('Failed to add comment');
    }
  }
}
