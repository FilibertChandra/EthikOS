import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/post_service.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final PostService _postService = PostService();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _postService.getPosts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPost(String content, {Uint8List? imageBytes}) async {
    try {
      final newPost =
          await _postService.createPost(content, imageBytes: imageBytes);
      _posts.insert(0, newPost);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      await _postService.likePost(postId);

      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = _posts[index];
        final updatedLikes = post.likes.contains(userId)
            ? post.likes.where((id) => id != userId).toList()
            : [...post.likes, userId];

        _posts[index] = Post(
          id: post.id,
          authorId: post.authorId,
          authorUsername: post.authorUsername,
          content: post.content,
          imageUrl: post.imageUrl,
          likes: updatedLikes,
          comments: post.comments,
          createdAt: post.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addComment(
    String postId,
    String text, {
    required String userId,
    required String username,
  }) async {
    try {
      await _postService.addComment(postId, text);

      // Append the comment locally instead of re-downloading the whole feed.
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = _posts[index];
        final newComment = Comment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          username: username,
          text: text,
          createdAt: DateTime.now(),
        );
        _posts[index] = Post(
          id: post.id,
          authorId: post.authorId,
          authorUsername: post.authorUsername,
          content: post.content,
          imageUrl: post.imageUrl,
          likes: post.likes,
          comments: [...post.comments, newComment],
          createdAt: post.createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
