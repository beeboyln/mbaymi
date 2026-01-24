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
        });
        _startCycle();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imagesLoaded = true;
        });
        _startCycle();
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
          Image(
            image: _cachedImages[_currentImageIndex],
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          // Image suivante (au-dessus) avec fade
          AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeController.value,
                child: Image(
                  image: _cachedImages[_nextImageIndex],
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