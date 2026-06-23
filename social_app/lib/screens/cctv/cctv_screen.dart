import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/post_service.dart';
import '../../widgets/cctv_player.dart';

/// Lets the user paste a CCTV HLS URL, watch it live, and capture a still.
/// The captured JPEG is returned to the create-post screen via Navigator.pop.
class CctvScreen extends StatefulWidget {
  const CctvScreen({super.key});

  @override
  State<CctvScreen> createState() => _CctvScreenState();
}

class _CctvScreenState extends State<CctvScreen> {
  final PostService _postService = PostService();
  final _urlController = TextEditingController();

  String? _activeUrl; // the URL currently being played
  bool _capturing = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _load() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _activeUrl = url);
  }

  Future<void> _capture() async {
    final url = _activeUrl;
    if (url == null) return;

    setState(() => _capturing = true);
    try {
      final Uint8List bytes = await _postService.fetchCctvSnapshot(url);
      if (!mounted) return;
      Navigator.pop(context, bytes); // hand the photo back to CreatePostScreen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CCTV Camera')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Paste HLS API URL (.m3u8)',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _load, child: const Text('Load')),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: _activeUrl == null
                  ? const Center(
                      child: Text(
                        'Paste a camera URL and tap Load',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : CctvPlayer(url: _activeUrl!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: (_activeUrl == null || _capturing) ? null : _capture,
              icon: _capturing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_capturing ? 'Capturing...' : 'Capture photo'),
            ),
          ),
        ],
      ),
    );
  }
}
