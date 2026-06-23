import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';
import '../auth/login_screen.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => Provider.of<PostProvider>(context, listen: false).fetchPosts());
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EthikOS'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: postProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : postProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          postProvider.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => postProvider.fetchPosts(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : postProvider.posts.isEmpty
                  ? const Center(child: Text('No posts yet. Be the first!'))
                  : RefreshIndicator(
                      onRefresh: () => postProvider.fetchPosts(),
                      child: ListView.builder(
                        itemCount: postProvider.posts.length,
                        itemBuilder: (context, index) {
                          return PostCard(post: postProvider.posts[index]);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (mounted) {
            Provider.of<PostProvider>(context, listen: false).clearError();
            Provider.of<PostProvider>(context, listen: false).fetchPosts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
