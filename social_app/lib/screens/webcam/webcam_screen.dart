import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/post_service.dart';
import '../../widgets/mjpeg_view.dart';

/// Live preview of the USB webcam (streamed from the PC) plus a Capture button
/// that grabs a still and hands it to the create-post screen.
class WebcamScreen extends StatefulWidget {
  const WebcamScreen({super.key});

  @override
  State<WebcamScreen> createState() => _WebcamScreenState();
}

class _WebcamScreenState extends State<WebcamScreen> {
  final PostService _postService = PostService();
  bool _capturing = false;

  Future<void> _capture() async {
    setState(() => _capturing = true);
    try {
      final Uint8List bytes = await _postService.fetchWebcamSnapshot();
      if (!mounted) return;
      // Return the captured photo to the create-post screen that opened us.
      Navigator.pop(context, bytes);
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
      appBar: AppBar(title: const Text('Webcam')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: MjpegView(streamUrl: AppConfig.webcamStreamUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _capturing ? null : _capture,
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
