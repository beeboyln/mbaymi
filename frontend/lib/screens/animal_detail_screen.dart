import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';

class AnimalDetailScreen extends StatefulWidget {
  final int livestockId;
  final Map<String, dynamic> animal;
  final bool isDarkMode;

  const AnimalDetailScreen({
    Key? key,
    required this.livestockId,
    required this.animal,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _accentColor = Color(0xFFF4A261);

  late Future<List<Map<String, dynamic>>> _photosFuture;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    // Use photos from animal if available, otherwise fetch from API
    final existingPhotos = widget.animal['photos'] as List?;
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAF9F6);
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: Text('${widget.animal['animal_type'] ?? 'Animal'} - Détails'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos carousel
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _photosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      height: 300,
                      child: CircularProgressIndicator(color: _accentColor),
                    ),
                  );
                }

                final photos = snapshot.data ?? [];

                if (photos.isEmpty) {
                  return Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: _accentColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune photo',
                            style: TextStyle(color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Main carousel
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 300,
                        child: PageView.builder(
                          onPageChanged: (index) {
                            setState(() => _currentPhotoIndex = index);
                          },
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            final imageUrl = photo['image_url'] as String?;

                            return imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: _accentColor.withOpacity(0.1),
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  )
                                : Container(
                                    color: _accentColor.withOpacity(0.1),
                                    child: const Icon(Icons.image_outlined),
                                  );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        photos.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPhotoIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPhotoIndex == index
                                ? _accentColor
                                : _accentColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Thumbnails
                    if (photos.length > 1)
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            final imageUrl = photo['image_url'] as String?;
                            final isSelected = _currentPhotoIndex == index;

                            return GestureDetector(
                              onTap: () {
                                setState(() => _currentPhotoIndex = index);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: isSelected
                                      ? Border.all(
                                          color: _accentColor,
                                          width: 3,
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: _accentColor.withOpacity(0.1),
                                            child: const Icon(Icons.broken_image),
                                          ),
                                        )
                                      : Container(
                                          width: 80,
                                          color: _accentColor.withOpacity(0.1),
                                          child: const Icon(Icons.image_outlined),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Animal details
            _buildDetailCard(
              'Type d\'animal',
              widget.animal['animal_type'] ?? 'N/A',
              Icons.pets,
              textColor,
              cardColor,
            ),

            const SizedBox(height: 12),

            _buildDetailCard(
              'Race',
              widget.animal['breed'] ?? 'N/A',
              Icons.info,
              textColor,
              cardColor,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    'Quantité',
                    '${widget.animal['quantity'] ?? 1}',
                    Icons.numbers,
                    textColor,
                    cardColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    'Âge (mois)',
                    '${widget.animal['age_months'] ?? 0}',
                    Icons.calendar_today,
                    textColor,
                    cardColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    'Poids (kg)',
                    '${widget.animal['weight_kg'] ?? 0}',
                    Icons.scale,
                    textColor,
                    cardColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    'Santé',
                    widget.animal['health_status'] ?? 'N/A',
                    Icons.health_and_safety,
                    textColor,
                    cardColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildDetailCard(
              'Alimentation',
              widget.animal['feeding_type'] ?? 'N/A',
              Icons.restaurant,
              textColor,
              cardColor,
            ),

            const SizedBox(height: 12),

            if ((widget.animal['notes'] ?? '').isNotEmpty)
              _buildDetailCard(
                'Notes',
                widget.animal['notes'] ?? '',
                Icons.note,
                textColor,
                cardColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color cardColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accentColor.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: _accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
