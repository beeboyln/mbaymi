import 'package:flutter/material.dart';

/// Helper pour optimiser le chargement et le cache des images
class ImageOptimizer {
  /// Cache globale avec clé personnalisée
  static final Map<String, ImageProvider> _memoryCache = {};

  /// Charge une image réseau avec cache optimal
  static Widget buildNetworkImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    Duration cacheDuration = const Duration(days: 30),
  }) {
    // Éviter les URL vides
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.image, color: Colors.grey[600]),
      );
    }

    return _NetworkImageWithPlaceholder(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
    );
  }

  /// Charge une image circulaire optimisée pour les avatars
  static Widget buildCircleAvatar({
    required String imageUrl,
    required double radius,
    String? initials,
    Color backgroundColor = Colors.green,
    Duration cacheDuration = const Duration(days: 30),
  }) {
    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Text(
          initials ?? '?',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor,
              child: Text(
                initials ?? '?',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Précharge une image pour la mettre en cache
  static Future<void> preloadImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return Future.value();

    try {
      final provider = NetworkImage(imageUrl);
      // Use the global precacheImage from Flutter widgets
      return precacheImage(provider, context).catchError((_) => null);
    } catch (e) {
      debugPrint('Erreur preload image: $e');
      return Future.value();
    }
  }

  /// Efface le cache des images
  static Future<void> clearImageCache() async {
    _memoryCache.clear();
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Retourne la taille estimée du cache en MB
  static double estimateCacheSize() {
    // Approximation simple
    return _memoryCache.length * 0.5;
  }

  /// Limite le cache à une taille maximale
  static void limitCacheSize({int maxItems = 100}) {
    if (_memoryCache.length > maxItems) {
      final keysToRemove = _memoryCache.keys
          .skip(_memoryCache.length - maxItems)
          .toList();
      for (var key in keysToRemove) {
        _memoryCache.remove(key);
      }
    }
  }
}

/// Gestionnaire de cache personnalisé pour images réseau
class _NetworkImageWithPlaceholder extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final String? placeholder;

  const _NetworkImageWithPlaceholder({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.fit,
    this.placeholder,
  });

  @override
  State<_NetworkImageWithPlaceholder> createState() =>
      _NetworkImageWithPlaceholderState();
}

class _NetworkImageWithPlaceholderState
    extends State<_NetworkImageWithPlaceholder> {
  late ImageProvider _imageProvider;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _imageProvider = NetworkImage(widget.imageUrl);
    _precacheImage();
  }

  Future<void> _precacheImage() async {
    try {
      ImageOptimizer.preloadImage(context, widget.imageUrl);
      if (mounted) {
        setState(() => _imageLoaded = true);
      }
    } catch (e) {
      debugPrint('Erreur cache image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: _imageLoaded
          ? Image(
              image: _imageProvider,
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image,
                      color: Colors.grey[600]),
                );
              },
            )
          : Center(
              child: widget.placeholder != null
                  ? Image.asset(widget.placeholder!,
                      fit: widget.fit)
                  : const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
            ),
    );
  }
}

/// Extension pour les BufferedImage et Image optimization
extension ImageOptimizationExtension on Image {
  /// Applique les optimisations d'image standard
  Image withOptimization({
    BoxFit fit = BoxFit.cover,
    FilterQuality quality = FilterQuality.medium,
  }) {
    return Image(
      image: image,
      fit: fit,
      filterQuality: quality,
      semanticLabel: semanticLabel,
    );
  }
}

/// Widget pour charger des images avec fallback intelligent
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final String? placeholder;
  final Duration cacheDuration;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.cacheDuration = const Duration(days: 30),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ImageOptimizer.buildNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      cacheDuration: cacheDuration,
    );
  }
}
