import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';

class CreateFarmPostDialog extends StatefulWidget {
  final int farmId;
  final String farmName;
  final VoidCallback onPostCreated;

  const CreateFarmPostDialog({
    Key? key,
    required this.farmId,
    required this.farmName,
    required this.onPostCreated,
  }) : super(key: key);

  @override
  State<CreateFarmPostDialog> createState() => _CreateFarmPostDialogState();
}

class _CreateFarmPostDialogState extends State<CreateFarmPostDialog> {
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _accentColor = Color(0xFFC9A876);
  
  final TextEditingController _captionController = TextEditingController();
  String? _selectedImageUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      // Upload to Cloudinary
      final imageUrl = await ApiService.uploadImageToCloudinary(pickedFile);
      
      setState(() {
        _selectedImageUrl = imageUrl;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image uploadée'),
            backgroundColor: _primaryColor,
            duration: Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _publishPost() async {
    if (_selectedImageUrl == null || _selectedImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez sélectionner une image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService.currentSession?.userId ?? 0;
      await ApiService.createFarmPost(
        farmId: widget.farmId,
        userId: userId,
        imageUrl: _selectedImageUrl!,
        caption: _captionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Post publié!'),
            backgroundColor: _primaryColor,
            duration: Duration(milliseconds: 800),
          ),
        );

        widget.onPostCreated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Dialog(
      elevation: 0,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nouveau post',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Farm name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🌾 ${widget.farmName}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image picker
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _accentColor,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _primaryColor.withOpacity(0.05),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primaryColor,
                            ),
                          ),
                        )
                      : _selectedImageUrl != null && _selectedImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _selectedImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('Image non disponible', style: TextStyle(color: textColor, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 48, color: _primaryColor),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Cliquer pour sélectionner une image',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.7),
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PNG, JPG, GIF (max 5MB)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 16),

              // Caption text field
              TextField(
                controller: _captionController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Ajouter une description (facultatif)',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _accentColor.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _accentColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: _primaryColor.withOpacity(0.05),
                ),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _publishPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            )
                          : const Text(
                              'Publier',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
