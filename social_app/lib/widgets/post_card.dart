import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import 'comment_card.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _commentController = TextEditingController();
  bool _showComments = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await postProvider.addComment(
      widget.post.id,
      _commentController.text.trim(),
      userId: authProvider.currentUser?.id ?? '',
      username: authProvider.currentUser?.username ?? 'You',
    );

    if (success && mounted) {
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id ?? '';
    final isLiked = widget.post.likes.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),
                Text(
                  widget.post.authorUsername,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(widget.post.content),
            if (widget.post.imageUrl != null &&
                widget.post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: '${AppConfig.serverRoot}${widget.post.imageUrl}',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // ngrok header so its free-plan interstitial doesn't break images.
                  httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () => postProvider.likePost(
                    widget.post.id,
                    currentUserId,
                  ),
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                ),
                Text('${widget.post.likes.length}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showComments = !_showComments;
                    });
                  },
                  icon: const Icon(Icons.comment_outlined),
                ),
                Text('${widget.post.comments.length}'),
              ],
            ),
            if (_showComments) ...[
              const Divider(),
              ...widget.post.comments.map(
                (comment) => CommentCard(comment: comment),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _submitComment,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
