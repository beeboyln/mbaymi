import 'package:flutter/material.dart';

class FadingImagesWidget extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final Duration fadeDuration;
  final Duration displayDuration;

  const FadingImagesWidget({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.fadeDuration = const Duration(milliseconds: 700),
    this.displayDuration = const Duration(seconds: 4),
  });

  @override
  State<FadingImagesWidget> createState() => _FadingImagesWidgetState();
}

class _FadingImagesWidgetState extends State<FadingImagesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  int _currentImageIndex = 0;
  int _nextImageIndex = 1;
  final List<ImageProvider> _cachedImages = [];
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesLoaded) {
      _preloadImages();
    }
  }

  Future<void> _preloadImages() async {
    try {
      final imagesToLoad = widget.imageUrls
          .map((url) => NetworkImage(url))
          .toList();

      for (var imageProvider in imagesToLoad) {
        await precacheImage(imageProvider, context);
        _cachedImages.add(imageProvider);
      }

      if (mounted) {
        setState(() {
          _imagesLoaded = true;
          // If only one image, set nextImageIndex to 0
          if (widget.imageUrls.length <= 1) {
            _currentImageIndex = 0;
            _nextImageIndex = 0;
          }
        });
        // Only start cycle if there are multiple images
        if (widget.imageUrls.length > 1) {
          _startCycle();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imagesLoaded = true;
          if (widget.imageUrls.length <= 1) {
            _currentImageIndex = 0;
            _nextImageIndex = 0;
          }
        });
        if (widget.imageUrls.length > 1) {
          _startCycle();
        }
      }
    }
  }

  Future<void> _crossFadeImages() async {
    try {
      // Transition de l'image actuelle vers la suivante
      await _fadeController.forward();
      
      // Afficher l'image suivante
      await Future.delayed(widget.displayDuration);
      
      // Préparer la prochaine transition
      if (mounted) {
        setState(() {
          _currentImageIndex = _nextImageIndex;
          _nextImageIndex = (_nextImageIndex + 1) % widget.imageUrls.length;
        });
        _fadeController.reset();
      }
    } catch (e) {
      // Continuer en cas d'erreur
    }
  }

  void _startCycle() async {
    while (mounted) {
      await _crossFadeImages();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_imagesLoaded || _cachedImages.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Container(
          color: Colors.grey[300],
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image actuelle (en dessous)
          _cachedImages.isNotEmpty
              ? Image(
                  image: _cachedImages[_currentImageIndex.clamp(0, _cachedImages.length - 1)],
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : Container(),
          // Image suivante (au-dessus) avec fade - Only show if multiple images
          if (_cachedImages.length > 1)
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeController.value,
                  child: Image(
                    image: _cachedImages[_nextImageIndex.clamp(0, _cachedImages.length - 1)],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}