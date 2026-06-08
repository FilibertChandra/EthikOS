import 'package:flutter/foundation.dart';

class Comment {
  final String id;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    debugPrint('Comment JSON: $json');
    return Comment(
      id: json['_id']?.toString() ?? '',
      userId: json['user'] is Map
          ? json['user']['_id']?.toString() ?? ''
          : json['user']?.toString() ?? '',
      username: json['user'] is Map
          ? json['user']['username']?.toString() ?? 'Unknown'
          : 'Unknown',
      text: json['text']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Post {
  final String id;
  final String authorId;
  final String authorUsername;
  final String content;
  final String? imageUrl;
  final List<String> likes;
  final List<Comment> comments;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final String authorId;
    final String authorUsername;

    if (author is Map) {
      authorId = author['_id']?.toString() ?? '';
      authorUsername = author['username']?.toString() ?? '';
    } else {
      authorId = author?.toString() ?? '';
      authorUsername = 'Unknown';
    }

    return Post(
      id: json['_id']?.toString() ?? '',
      authorId: authorId,
      authorUsername: authorUsername,
      content: json['content']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      likes:
          List<String>.from((json['likes'] as List).map((e) => e.toString())),
      comments:
          (json['comments'] as List).map((c) => Comment.fromJson(c)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
