import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';

class CreateFarmPostDialog extends StatefulWidget {
  final int farmId;
  final String farmName;
  final VoidCallback onPostCreated;
  final int? livestockId;

  const CreateFarmPostDialog({
    super.key,
    required this.farmId,
    required this.farmName,
    required this.onPostCreated,
    this.livestockId,
  });

  @override
  State<CreateFarmPostDialog> createState() => _CreateFarmPostDialogState();
}

class _CreateFarmPostDialogState extends State<CreateFarmPostDialog> {
  final _imagePicker = ImagePicker();
  final _captionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _selectedImageUrl;
  bool _isLoading = false;
  String _postIntent = "share";  // "share" ou "sell"
  String _unit = "kg";  // kg, litre, pièce, etc.

  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const List<String> UNITS = ['kg', 'litre', 'pièce', 'panier', 'sac'];

  @override
  void dispose() {
    _captionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload to Cloudinary
      final imageUrl = await ApiService.uploadImageToCloudinary(image);

      if (imageUrl != null) {
        setState(() => _selectedImageUrl = imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image téléchargée'),
            backgroundColor: _primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur téléchargement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost() async {
    if (_selectedImageUrl == null || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une image et entrer une caption'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService.currentSession?.userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await ApiService.createFarmPost(
        farmId: widget.farmId,
        userId: userId,
        imageUrl: _selectedImageUrl!,
        caption: _captionController.text.trim(),
        postIntent: _postIntent,
        price: _postIntent == "sell" ? double.tryParse(_priceController.text) : null,
        unit: _unit,
        livestockId: widget.livestockId,
      );

      // Invalidate cached API data so the social feed picks up the new post
      ApiService.clearCache();
      // Notify listeners (SocialFeedScreen) to refresh immediately
      ApiService.notifyFarmPostCreated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Post créé avec succès'),
            backgroundColor: _primaryColor,
          ),
        );
        Navigator.pop(context);
        widget.onPostCreated();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Post'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // Farm name
                Text(
                  'Ferme: ${widget.farmName}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),

              // Image picker
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: _primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: _primaryColor.withOpacity(0.1),
                  ),
                  child: _selectedImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _selectedImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: _primaryColor,
                            ),
                          ),
                        )
                      : Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: _primaryColor,
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: _primaryColor,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tapez pour ajouter une image',
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Caption field
              TextField(
                controller: _captionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Écrivez une description...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),

              // POST INTENT SELECTOR
              Text(
                'Type de post',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _postIntent = "share"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _postIntent == "share" ? _primaryColor : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: _postIntent == "share"
                              ? _primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.image,
                                size: 28,
                                color: _primaryColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Je partage',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _postIntent = "sell"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _postIntent == "sell" ? _primaryColor : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: _postIntent == "sell"
                              ? _primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.local_atm,
                                size: 28,
                                color: _primaryColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Je vends',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Show pricing fields only if selling
              if (_postIntent == "sell") ...[
                const SizedBox(height: 20),
                // Price and unit row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Prix',
                          hintText: '5000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.local_atm, color: _primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        items: UNITS.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _unit = value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Unité',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _primaryColor),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Publier',
                              style: TextStyle(color: Colors.white),
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
