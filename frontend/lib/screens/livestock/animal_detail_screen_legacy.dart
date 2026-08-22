import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';

// Définition de la palette de couleurs personnalisée
class NaturalPalette {
  static const Color beigeClair = Color(0xFFF7F4EF);
  static const Color creme = Color(0xFFFFFDF9);
  static const Color marronOcre = Color(0xFFC67D38);
  static const Color vertOliveKaki = Color(0xFF707E63);
  static const Color orangeDoux = Color(0xFFE08D58);
  static const Color saumon = Color(0xFFE89882);
  static const Color brunFonce = Color(0xFF3B2A21);
  static const Color grisAnthracite = Color(0xFF2B2C2C);
  static const Color roseTresPale = Color(0xFFFBF0EE);
  static const Color chair = Color(0xFFE8CBB9);
}

class AnimalDetailScreen extends StatefulWidget {
  final int livestockId;
  final Map<String, dynamic> animal;
  final bool isDarkMode;

  const AnimalDetailScreen({
    super.key,
    required this.livestockId,
    required this.animal,
    required this.isDarkMode,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late Future<List<Map<String, dynamic>>> _photosFuture;
  late Map<String, dynamic> _animalData;
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _animalData = Map<String, dynamic>.from(widget.animal);
    _loadAnimalDetails();
    final existingPhotos = _animalData['photos'] as List?;
    if (existingPhotos != null && existingPhotos.isNotEmpty) {
      _photosFuture = Future.value(
        List<Map<String, dynamic>>.from(
          existingPhotos.cast<Map<String, dynamic>>(),
        ),
      );
    } else {
      _photosFuture = ApiService.getAnimalPhotos(widget.livestockId);
    }
  }

  Future<void> _loadAnimalDetails() async {
    try {
      final details = await ApiService.getLivestockById(widget.livestockId);
      if (!mounted) return;
      setState(() => _animalData = {..._animalData, ...details});
    } catch (e) {
      debugPrint('Erreur chargement détails animal: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getAnimalEmoji(String? type) {
    switch (type?.toLowerCase()) {
      case 'mouton':
        return '🐑';
      case 'chèvre':
        return '🐐';
      case 'vache':
        return '🐄';
      case 'cochon':
        return '🐷';
      case 'poule':
        return '🐔';
      case 'âne':
        return '🫏';
      case 'cheval':
        return '🐴';
      case 'chameau':
        return '🐪';
      default:
        return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    
    // Application des couleurs de la palette selon le mode
    final bgColor = isDark ? NaturalPalette.grisAnthracite : NaturalPalette.beigeClair;
    final cardBg = isDark ? NaturalPalette.brunFonce : NaturalPalette.creme;
    final textColor = isDark ? NaturalPalette.beigeClair : NaturalPalette.brunFonce;
    final textSecondary = isDark ? NaturalPalette.chair : NaturalPalette.vertOliveKaki;
    final accentColor = NaturalPalette.marronOcre;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Photo Hero Section
              SliverToBoxAdapter(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _photosFuture,
                  builder: (context, snapshot) {
                    final photos = snapshot.data ?? [];
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting;

                    return Stack(
                      children: [
                        SizedBox(
                          height: 420,
                          child: loading
                              ? Container(
                                  color: cardBg,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: NaturalPalette.marronOcre,
                                    ),
                                  ),
                                )
                              : photos.isEmpty
                                  ? Container(
                                      color: cardBg,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _getAnimalEmoji(
                                                  _animalData['animal_type']),
                                              style:
                                                  const TextStyle(fontSize: 64),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Aucune photo disponible',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: textSecondary,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : PageView.builder(
                                      controller: _pageController,
                                      onPageChanged: (index) {
                                        setState(
                                            () => _currentPhotoIndex = index);
                                      },
                                      itemCount: photos.length,
                                      itemBuilder: (context, index) {
                                        final imageUrl =
                                            photos[index]['image_url'] as String?;
                                        return imageUrl != null &&
                                                imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  color: cardBg,
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                    color: textSecondary
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                              )
                                            : Container(color: cardBg);
                                      },
                                    ),
                        ),

                        // Shadow overlay at bottom of photo
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  NaturalPalette.brunFonce.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Page Indicators (Orange doux & Saumon)
                        if (photos.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                photos.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: _currentPhotoIndex == index ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentPhotoIndex == index
                                        ? NaturalPalette.orangeDoux
                                        : NaturalPalette.saumon.withOpacity(0.5),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Title Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_animalData['animal_type'] ?? 'Animal')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                                color: NaturalPalette.vertOliveKaki,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _animalData['breed'] ?? 'Race non spécifiée',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _getAnimalEmoji(_animalData['animal_type']),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ),

              // Specifications Grid (Without borders, flush rectangular cards)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    color: cardBg,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildAppleSpecTile(
                                'Quantité',
                                '${_animalData['quantity'] ?? 1}',
                                textColor,
                                textSecondary,
                                accentColor,
                              ),
                            ),
                            Expanded(
                              child: _buildAppleSpecTile(
                                'Âge',
                                '${_animalData['age_months'] ?? 0} mois',
                                textColor,
                                textSecondary,
                                accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAppleSpecTile(
                                'Poids',
                                '${_animalData['weight_kg'] ?? 0} kg',
                                textColor,
                                textSecondary,
                                accentColor,
                              ),
                            ),
                            Expanded(
                              child: _buildAppleSpecTile(
                                'Santé',
                                _animalData['health_status'] ?? 'N/A',
                                textColor,
                                textSecondary,
                                accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAppleSpecTile(
                                'Alimentation',
                                _animalData['feeding_type'] ?? 'N/A',
                                textColor,
                                textSecondary,
                                accentColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Notes Section (Rose très pâle background accent for subtle contrast)
              if ((_animalData['notes'] ?? '').toString().isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Container(
                      width: double.infinity,
                      color: isDark
                          ? NaturalPalette.brunFonce
                          : NaturalPalette.roseTresPale,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'À PROPOS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              color: NaturalPalette.marronOcre,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _animalData['notes'] ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: textColor,
                              height: 1.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Thumbnail Gallery Strip
              SliverToBoxAdapter(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _photosFuture,
                  builder: (context, snapshot) {
                    final photos = snapshot.data ?? [];
                    if (photos.length <= 1) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GALERIE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              color: NaturalPalette.vertOliveKaki,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: photos.length,
                              itemBuilder: (context, index) {
                                final imageUrl =
                                    photos[index]['image_url'] as String?;
                                final isSelected = _currentPhotoIndex == index;

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _pageController.animateToPage(
                                      index,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Opacity(
                                    opacity: isSelected ? 1.0 : 0.45,
                                    child: Container(
                                      width: 70,
                                      margin: const EdgeInsets.only(right: 12),
                                      color: cardBg,
                                      child: imageUrl != null &&
                                              imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              Icons.image_outlined,
                                              color: textSecondary,
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),

          // Floating Frosted Glass Back Button (Tinted with Chair / Brun foncé)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    color: (isDark
                            ? NaturalPalette.brunFonce
                            : NaturalPalette.chair)
                        .withOpacity(0.45),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark
                            ? NaturalPalette.beigeClair
                            : NaturalPalette.brunFonce,
                        size: 16,
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

  Widget _buildAppleSpecTile(
    String label,
    String value,
    Color textColor,
    Color textSecondary,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: textColor,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}