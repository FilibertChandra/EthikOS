import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Displays a live MJPEG (multipart/x-mixed-replace) HTTP stream.
///
/// It opens the stream once, splits the byte feed into individual JPEG frames
/// (each delimited by the SOI `FFD8` and EOI `FFD9` markers) and repaints as
/// each new frame arrives. Self-contained so it works with http ^1.x.
class MjpegView extends StatefulWidget {
  final String streamUrl;
  final BoxFit fit;

  const MjpegView(
      {super.key, required this.streamUrl, this.fit = BoxFit.contain});

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  static const int _soi = 0xd8; // start of image (preceded by 0xff)
  static const int _eoi = 0xd9; // end of image (preceded by 0xff)

  final http.Client _client = http.Client();
  StreamSubscription<List<int>>? _subscription;
  final List<int> _buffer = [];
  Uint8List? _frame;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      final response = await _client.send(request);

      debugPrint('status: ${response.statusCode}');
      debugPrint('headers: ${response.headers}');
      debugPrint('content-type: ${response.headers['content-type']}');

      if (response.statusCode != 200) {
        setState(() => _error = 'Stream error: ${response.statusCode}');
        return;
      }

      _subscription = response.stream.listen(
        _onData,
        onError: (e) => setState(() => _error = 'Stream error: $e'),
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Cannot reach webcam: $e');
    }
  }

  void _onData(List<int> chunk) {
    _buffer.addAll(chunk);

    // Pull every complete JPEG currently sitting in the buffer.
    while (true) {
      final start = _indexOfMarker(_buffer, _soi, 0);
      if (start == -1) return;
      final end = _indexOfMarker(_buffer, _eoi, start + 2);
      if (end == -1) {
        // Drop anything before the current SOI so the buffer can't grow forever.
        if (start > 0) _buffer.removeRange(0, start);
        return;
      }

      final frame = Uint8List.fromList(_buffer.sublist(start, end + 2));
      _buffer.removeRange(0, end + 2);
      if (mounted) setState(() => _frame = frame);
    }
  }

  /// Finds `0xff <marker>` starting at [from]; returns the index of 0xff.
  int _indexOfMarker(List<int> data, int marker, int from) {
    for (var i = from; i < data.length - 1; i++) {
      if (data[i] == 0xff && data[i + 1] == marker) return i;
    }
    return -1;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _client.close();
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
    if (_frame == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Image.memory(_frame!, fit: widget.fit, gaplessPlayback: true);
  }
}
