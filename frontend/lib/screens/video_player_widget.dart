import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class VideoPlayerWidget extends StatefulWidget {
  final String assetPath;
  final String? webUrl; // URL alternative pour le web
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
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Sur le web, utiliser l'URL fournie ou un chemin relatif
      if (kIsWeb) {
        final videoUrl = widget.webUrl ?? '/assets/images/v.mp4';
        _controller = VideoPlayerController.network(videoUrl);
      } else {
        // Sur mobile natif, utiliser l'asset
        _controller = VideoPlayerController.asset(widget.assetPath);
      }

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.grey),
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