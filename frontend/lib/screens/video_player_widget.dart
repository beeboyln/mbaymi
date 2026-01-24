import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class VideoPlayerWidget extends StatefulWidget {
  final String assetPath;
  final String? webUrl;
  const VideoPlayerWidget({
    super.key, 
    required this.assetPath,
    this.webUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.assetPath);
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(0.0);
      _controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement vidéo: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sur le web, utiliser une vidéo HTML native
    if (kIsWeb) {
      return Container(
        color: Colors.grey.shade300,
        child: Center(
          child: HtmlElementView(
            viewType: 'video-container-${widget.hashCode}',
            onPlatformViewCreated: (_) {
              final videoElement = html.VideoElement()
                ..src = widget.webUrl ?? 'assets/assets/images/v.mp4'
                ..autoplay = true
                ..loop = true
                ..muted = true
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.objectFit = 'cover';
              
              html.document.body!.append(videoElement);
            },
          ),
        ),
      );
    }

    // Sur mobile natif
    if (_hasError) {
      return Container(
        color: Colors.grey.shade300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, color: Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(
                'Erreur chargement vidéo',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return VideoPlayer(_controller);
  }
}