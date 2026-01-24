import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:mbaymi/services/api_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? assetPath;
  final bool autoplay;
  final bool looping;
  final bool muted;
  final double height;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.assetPath,
    this.autoplay = true,
    this.looping = true,
    this.muted = true,
    this.height = 200,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayer;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer = _initController();
  }

  Future<void> _initController() async {
    try {
      if (kIsWeb) {
        // Pour le web, utilise directement l'URL fournie (Cloudinary)
        _controller = VideoPlayerController.network(
          widget.videoUrl,
          videoPlayerOptions: VideoPlayerOptions(
            allowBackgroundPlayback: false,
            mixWithOthers: true,
          ),
        );
      } else {
        // Pour mobile, utilise l'asset si disponible, sinon l'URL réseau
        if (widget.assetPath != null && widget.assetPath!.isNotEmpty) {
          _controller = VideoPlayerController.asset(widget.assetPath!);
        } else {
          _controller = VideoPlayerController.network(widget.videoUrl);
        }
      }

      await _controller.initialize();

      if (mounted) {
        _controller.setLooping(widget.looping);
        _controller.setVolume(widget.muted ? 0.0 : 1.0);

        if (widget.autoplay) {
          await _controller.play();
        }
      }
    } catch (e) {
      print('Erreur initialisation vidéo: $e');
      if (mounted) {
        setState(() {
          _showFallback = true;
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
    if (_showFallback) {
      return Container(
        width: double.infinity,
        height: widget.height,
        color: Colors.grey[800],
      );
    }

    return FutureBuilder<void>(
      future: _initializeVideoPlayer,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // Fallback en cas d'erreur
            return Container(
              width: double.infinity,
              height: widget.height,
              color: Colors.grey[800],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Impossible de charger la vidéo',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            width: double.infinity,
            height: widget.height,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                // Play/Pause overlay
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _controller.value.isPlaying ? 0 : 0.7,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Loading state
        return Container(
          width: double.infinity,
          height: widget.height,
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
  }
}
