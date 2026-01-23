import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:mbaymi/services/api_service.dart';

class AnimalPhotoCarouselScreen extends StatefulWidget {
  final int livestockId;
  final String animalType;
  final int userId;
  final bool isDarkMode;

  const AnimalPhotoCarouselScreen({
    super.key,
    required this.livestockId,
    required this.animalType,
    required this.userId,
    required this.isDarkMode,
  });

  @override
  State<AnimalPhotoCarouselScreen> createState() =>
      _AnimalPhotoCarouselScreenState();
}

class _AnimalPhotoCarouselScreenState extends State<AnimalPhotoCarouselScreen> {
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _accentColor = Color(0xFFF4A261);

  late Future<List<Map<String, dynamic>>> _photosFuture;
  int _currentIndex = 0;
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() {
    setState(() {
      _photosFuture = ApiService.getAnimalPhotos(widget.livestockId);
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImageBytes == null) {
      _showError('Sélectionnez une image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create a temporary XFile from bytes
      final tempFile = XFile.fromData(
        _selectedImageBytes!,
        mimeType: 'image/jpeg',
        name: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Upload to Cloudinary
      final imageUrl = await ApiService.uploadImageToCloudinary(tempFile);

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Échec de l\'upload de l\'image');
      }

      // Save to backend
      await ApiService.addAnimalPhoto(
        livestockId: widget.livestockId,
        imageUrl: imageUrl,
      );

      setState(() {
        _selectedImageBytes = null;
        _currentIndex = 0;
      });

      _loadPhotos();
      _showSuccess('Photo ajoutée!');
    } catch (e) {
      _showError('Erreur upload: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePhoto(int photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ApiService.deleteAnimalPhoto(photoId);
        _loadPhotos();
        _showSuccess('Photo supprimée');
      } catch (e) {
        _showError('Erreur: $e');
      }
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAF9F6);
    // cardColor not used; removed to satisfy analyzer
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: Text('${widget.animalType} - Galerie'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Preview section
            if (_selectedImageBytes != null) ...[
              Text(
                'Aperçu de la photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _selectedImageBytes!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => setState(() => _selectedImageBytes = null),
                      icon: const Icon(Icons.close),
                      label: const Text('Annuler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _uploadPhoto,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.upload),
                      label: const Text('Envoyer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Ajout de photo
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _accentColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: _accentColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ajouter une photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Appuyez pour sélectionner une image',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Photos gallery
            Text(
              'Galerie de photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _photosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                final photos = snapshot.data ?? [];

                if (photos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Aucune photo pour le moment',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Carousel
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 300,
                        child: PageView.builder(
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
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

                    const SizedBox(height: 16),

                    // Indicateurs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        photos.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? _accentColor
                                : _accentColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Delete button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _deletePhoto(photos[_currentIndex]['id']),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer cette photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Grid des autres photos
                    if (photos.length > 1) ...[
                      Text(
                        'Autres photos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          final photo = photos[index];
                          final imageUrl = photo['image_url'] as String?;
                          final isSelected = _currentIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _currentIndex = index);
                            },
                            child: Container(
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
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          color: _accentColor.withOpacity(0.1),
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      )
                                    : Container(
                                        color: _accentColor.withOpacity(0.1),
                                        child: const Icon(Icons.image_outlined),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
