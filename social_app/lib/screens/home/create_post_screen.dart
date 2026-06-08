import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../webcam/webcam_screen.dart';

class CreatePostScreen extends StatefulWidget {
  /// Optional image (e.g. a webcam snapshot) to attach to the post.
  final Uint8List? imageBytes;

  const CreatePostScreen({super.key, this.imageBytes});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageBytes;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _openWebcam() async {
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const WebcamScreen()),
    );
    if (bytes != null && mounted) {
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final success = await postProvider.createPost(
      _contentController.text.trim(),
      imageBytes: _imageBytes,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: postProvider.isLoading ? null : _submit,
            child: postProvider.isLoading
                ? const CircularProgressIndicator()
                : const Text(
                    'Post',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _contentController,
                    maxLines: 6,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'What is on your mind?',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // Text is optional when an image is attached; only require
                      // text if there's no image.
                      if ((value == null || value.trim().isEmpty) &&
                          _imageBytes == null) {
                        return 'Add some text or capture an image';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_imageBytes != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _imageBytes!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, color: Colors.white),
                          ),
                          onPressed: () => setState(() => _imageBytes = null),
                        ),
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openWebcam,
                      icon: const Icon(Icons.videocam),
                      label: Text(
                        _imageBytes == null
                            ? 'Capture from webcam'
                            : 'Retake from webcam',
                      ),
                    ),
                  ),
                  if (postProvider.errorMessage != null)
                    Text(
                      postProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
