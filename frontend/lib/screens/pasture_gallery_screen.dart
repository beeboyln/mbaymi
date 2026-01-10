import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'package:mbaymi/services/api_service.dart';

class PastureGalleryScreen extends StatefulWidget {
  final int userId;
  
  const PastureGalleryScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<PastureGalleryScreen> createState() => _PastureGalleryScreenState();
}

class _PastureGalleryScreenState extends State<PastureGalleryScreen> {
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _accentColor = Color(0xFFF4A261);
  
  late Future<List<Map<String, dynamic>>> _pastureImages;
  bool _isLoading = false;
  XFile? _selectedImage;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPastureImages();
  }

  void _loadPastureImages() {
    _pastureImages = ApiService.getPastureImages(widget.userId);
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload to Cloudinary
      final imageUrl = await ApiService.uploadImageToCloudinary(
        _selectedImage!,
      );

      // Save to backend
      if (imageUrl != null) {
        await ApiService.addPastureImage(
          userId: widget.userId,
          imageUrl: imageUrl,
          title: _titleController.text.isNotEmpty ? _titleController.text : null,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        );
      }

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      setState(() => _selectedImage = null);

      // Reload
      _loadPastureImages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Image ajoutée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteImage(int imageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'image?'),
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
        await ApiService.deletePastureImage(imageId);
        _loadPastureImages();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Image supprimée')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAF9F6);
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('Galerie des Pâturages'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Upload section
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajouter une photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Image preview
                    if (_selectedImage != null) ...[
                      FutureBuilder<Uint8List>(
                        future: _selectedImage!.readAsBytes().then((bytes) => Uint8List.fromList(bytes)),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              height: 200,
                              color: _accentColor.withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(color: _accentColor),
                              ),
                            );
                          }
                          if (snapshot.hasData) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                snapshot.data!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return Container(
                            height: 200,
                            color: _accentColor.withOpacity(0.1),
                            child: const Icon(Icons.error, color: _accentColor),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Select image button
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _accentColor,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_outlined, color: _accentColor),
                            const SizedBox(width: 8),
                            Text(
                              _selectedImage != null
                                  ? 'Changer l\'image'
                                  : 'Sélectionner une image',
                              style: const TextStyle(
                                color: _accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title field
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Nom du pâturage (ex: Champ Nord)',
                        hintStyle: TextStyle(color: secondaryTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description field
                    TextField(
                      controller: _descriptionController,
                      style: TextStyle(color: textColor),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Description (optionnel)',
                        hintStyle: TextStyle(color: secondaryTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _uploadImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Ajouter la photo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Gallery section
            Text(
              'Mes photos de pâturage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _pastureImages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  );
                }

                final images = snapshot.data ?? [];

                if (images.isEmpty) {
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

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final image = images[index];
                    final imageUrl = image['image_url'] as String?;
                    final title = image['title'] as String?;
                    final imageId = image['id'] as int?;

                    return GestureDetector(
                      onLongPress: () {
                        if (imageId != null) {
                          _deleteImage(imageId);
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image
                            imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: _accentColor.withOpacity(0.1),
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: _accentColor,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: _accentColor.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.image_outlined,
                                      color: _accentColor,
                                    ),
                                  ),

                            // Overlay with title
                            if (title != null && title.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),

                            // Delete hint
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
