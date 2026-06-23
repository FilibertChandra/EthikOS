import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays a live HLS (.m3u8) stream using video_player (ExoPlayer on Android).
/// Used for the CCTV camera live view.
class CctvPlayer extends StatefulWidget {
  final String url;

  const CctvPlayer({super.key, required this.url});

  @override
  State<CctvPlayer> createState() => _CctvPlayerState();
}

class _CctvPlayerState extends State<CctvPlayer> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(CctvPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize if the URL changed (e.g. user pasted a new camera link).
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _controller = null;
      _error = null;
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();
      controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) setState(() => _error = 'Cannot play stream: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}
