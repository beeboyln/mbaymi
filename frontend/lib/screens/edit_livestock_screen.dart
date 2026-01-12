import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:mbaymi/screens/animal_photo_carousel_screen.dart';

class EditLivestockScreen extends StatefulWidget {
  final int livestockId;
  final Map<String, dynamic> livestock;

  const EditLivestockScreen({
    Key? key,
    required this.livestockId,
    required this.livestock,
  }) : super(key: key);

  @override
  State<EditLivestockScreen> createState() => _EditLivestockScreenState();
}

class _EditLivestockScreenState extends State<EditLivestockScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _animalTypeCtrl;
  late TextEditingController _breedCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _healthCtrl;
  late TextEditingController _feedingCtrl;
  late TextEditingController _notesCtrl;

  late FocusNode _animalTypeFocus;
  late FocusNode _breedFocus;
  late FocusNode _quantityFocus;
  late FocusNode _ageFocus;
  late FocusNode _weightFocus;
  late FocusNode _healthFocus;
  late FocusNode _feedingFocus;
  late FocusNode _notesFocus;

  bool _loading = false;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  late Future<List<dynamic>> _photosFuture;
  List<dynamic> _animalPhotos = [];
  Map<String, dynamic>? _userProfile;
  late String _visibility;

  // Palette de couleurs
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _primaryLight = Color(0xFFA58A6D);
  static const Color _accentColor = Color(0xFFC4A484);
  static const Color _bgLight = Color(0xFFFAF8F5);
  static const Color _bgDark = Color(0xFF121212);
  static const Color _cardLight = Colors.white;
  static const Color _cardDark = Color(0xFF1E1E1E);
  static const Color _borderLight = Color(0xFFE8E2D8);
  static const Color _borderDark = Color(0xFF2C2C2C);
  static const Color _textLight = Color(0xFF1A1A1A);
  static const Color _textDark = Colors.white;
  static const Color _textSecondaryLight = Color(0xFF6B6B6B);
  static const Color _textSecondaryDark = Color(0xFF8E8E93);

  final List<String> _animalTypes = ['Bovins', 'Chèvres', 'Moutons', 'Porcs', 'Volailles', 'Autre'];
  final List<String> _healthStatuses = ['Sain', 'Malade', 'Vacciné', 'À surveiller'];
  final List<String> _feedingTypes = ['Herbe', 'Grains', 'Mixte', 'Aliment composé'];

  @override
  void initState() {
    super.initState();
    _existingImageUrl = widget.livestock['image_url'];
    _photosFuture = ApiService.getAnimalPhotos(widget.livestockId);
    _loadUserProfile();
    _visibility = widget.livestock['visibility'] ?? 'PRIVATE';
    
    _animalTypeCtrl = TextEditingController(text: widget.livestock['animal_type'] ?? '');
    _breedCtrl = TextEditingController(text: widget.livestock['breed'] ?? '');
    _quantityCtrl = TextEditingController(text: '${widget.livestock['quantity'] ?? 1}');
    _ageCtrl = TextEditingController(text: widget.livestock['age_months']?.toString() ?? '');
    _weightCtrl = TextEditingController(text: widget.livestock['weight_kg']?.toString() ?? '');
    _healthCtrl = TextEditingController(text: widget.livestock['health_status'] ?? '');
    _feedingCtrl = TextEditingController(text: widget.livestock['feeding_type'] ?? '');
    _notesCtrl = TextEditingController(text: widget.livestock['notes'] ?? '');

    _animalTypeFocus = FocusNode();
    _breedFocus = FocusNode();
    _quantityFocus = FocusNode();
    _ageFocus = FocusNode();
    _weightFocus = FocusNode();
    _healthFocus = FocusNode();
    _feedingFocus = FocusNode();
    _notesFocus = FocusNode();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = widget.livestock['user_id'] ?? 0;
      final profile = await ApiService.getUserProfile(userId);
      if (mounted) {
        setState(() => _userProfile = profile);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageFile = image;
        _imageBytes = bytes;
      });
    }
  }

  @override
  void dispose() {
    _animalTypeCtrl.dispose();
    _breedCtrl.dispose();
    _quantityCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _healthCtrl.dispose();
    _feedingCtrl.dispose();
    _notesCtrl.dispose();

    _animalTypeFocus.dispose();
    _breedFocus.dispose();
    _quantityFocus.dispose();
    _ageFocus.dispose();
    _weightFocus.dispose();
    _healthFocus.dispose();
    _feedingFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    try {
      String? imageUrl = _existingImageUrl;
      
      // Upload image to Cloudinary if new image selected
      if (_imageFile != null) {
        imageUrl = await ApiService.uploadImageToCloudinary(_imageFile!);
      }

      final res = await ApiService.updateLivestock(
        livestockId: widget.livestockId,
        animalType: _animalTypeCtrl.text.trim(),
        breed: _breedCtrl.text.trim(),
        quantity: int.tryParse(_quantityCtrl.text) ?? 1,
        ageMonths: int.tryParse(_ageCtrl.text),
        weightKg: double.tryParse(_weightCtrl.text),
        healthStatus: _healthCtrl.text.trim(),
        feedingType: _feedingCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        imageUrl: imageUrl,
        visibility: _visibility,
      );

      _showSuccessSnackBar('Animal modifié avec succès !');
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context, res);
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet animal?'),
        content: const Text('Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        await ApiService.deleteLivestock(widget.livestockId);
        _showSuccessSnackBar('Animal supprimé');
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, {'deleted': true});
      } catch (e) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
        setState(() => _loading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w300),
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w300),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? _cardDark : _cardLight;
    final textColor = isDark ? _textDark : _textLight;
    final secondaryTextColor = isDark ? _textSecondaryDark : _textSecondaryLight;
    final borderColor = isDark ? _borderDark : _borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(cardColor, textColor, secondaryTextColor, borderColor),

            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🖼️ GALERIE DE PHOTOS EN PREMIER (priorité visuelle)
                        _buildImageSection(
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 32),

                        // 🐾 INFOS DE BASE
                        _buildSectionTitle('Information de l\'animal'),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Type',
                          value: _animalTypeCtrl.text.isEmpty ? null : _animalTypeCtrl.text,
                          items: _animalTypes,
                          onChanged: (value) => setState(() => _animalTypeCtrl.text = value ?? ''),
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          icon: Icons.pets_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _breedCtrl,
                          label: 'Race/Variété',
                          hint: 'Ex: Race locale',
                          icon: Icons.info_outlined,
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _quantityCtrl,
                                label: 'Quantité',
                                hint: '1',
                                icon: Icons.numbers,
                                keyboardType: TextInputType.number,
                                cardColor: cardColor,
                                textColor: textColor,
                                borderColor: borderColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _ageCtrl,
                                label: 'Âge (mois)',
                                hint: 'Mois',
                                icon: Icons.calendar_month,
                                keyboardType: TextInputType.number,
                                cardColor: cardColor,
                                textColor: textColor,
                                borderColor: borderColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _weightCtrl,
                          label: 'Poids (kg)',
                          hint: 'Kilos',
                          icon: Icons.scale,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        const SizedBox(height: 32),

                        // 💊 SANTÉ & ALIMENTATION
                        _buildSectionTitle('Santé & Alimentation'),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'État de santé',
                          value: _healthCtrl.text.isEmpty ? null : _healthCtrl.text,
                          items: _healthStatuses,
                          onChanged: (value) => setState(() => _healthCtrl.text = value ?? ''),
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          icon: Icons.health_and_safety_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Type d\'alimentation',
                          value: _feedingCtrl.text.isEmpty ? null : _feedingCtrl.text,
                          items: _feedingTypes,
                          onChanged: (value) => setState(() => _feedingCtrl.text = value ?? ''),
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          icon: Icons.restaurant_outlined,
                        ),
                        const SizedBox(height: 32),

                        // 📝 NOTES & OBSERVATIONS
                        _buildSectionTitle('Notes & Observations'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _notesCtrl,
                          label: 'Observations',
                          hint: 'Remarques importantes...',
                          icon: Icons.note_outlined,
                          maxLines: 3,
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        const SizedBox(height: 32),

                        // 👁️ VISIBILITÉ
                        _buildSectionTitle('Visibilité'),
                        const SizedBox(height: 16),
                        _buildVisibilitySelector(
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 40),

                        // 🔘 ACTIONS (en dernier)
                        Row(
                          children: [
                            Expanded(
                              child: _buildDeleteButton(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _buildSubmitButton(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color cardColor, Color textColor, Color secondaryTextColor, Color borderColor) {
    final userImage = _userProfile?['profile_image'] as String?;
    final userName = _userProfile?['username'] as String? ?? 'Utilisateur';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Close button with enhanced styling
          Container(
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              icon: Icon(Icons.close_rounded, color: _primaryColor),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          
          // User avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: userImage != null && userImage.isNotEmpty
                  ? Image.network(
                      userImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _accentColor.withOpacity(0.2),
                        child: Icon(
                          Icons.person_outline,
                          color: _primaryColor,
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      color: _accentColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person_outline,
                        color: _primaryColor,
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Title and user info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Modifier l\'animal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'par $userName',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Gallery button with enhanced styling
          Container(
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimalPhotoCarouselScreen(
                      livestockId: widget.livestockId,
                      animalType: widget.livestock['animal_type'] ?? 'Animal',
                      userId: widget.livestock['user_id'] ?? 0,
                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.image_outlined, color: _accentColor),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              tooltip: 'Galerie de photos',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: _primaryColor,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    required Color borderColor,
    required Color secondaryTextColor,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: maxLines == 1 ? 1 : 3,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: textColor),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w300),
          labelStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w400),
          prefixIcon: Icon(icon, color: _primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required Color cardColor,
    required Color textColor,
    required Color borderColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Color(0xFF6B6B6B), fontWeight: FontWeight.w400),
        ),
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: textColor),
        dropdownColor: cardColor,
        isExpanded: true,
      ),
    );
  }

  Widget _buildImageSection({
    required Color cardColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Galerie de photos'),
        const SizedBox(height: 16),
        
        // Section galerie existante
        FutureBuilder<List<dynamic>>(
          future: _photosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _primaryColor),
                ),
              );
            }

            final photos = snapshot.data ?? [];
            _animalPhotos = photos;
            
            // Debug: Afficher les IDs des photos
            if (photos.isNotEmpty) {
              debugPrint('📸 Photos loaded: ${photos.map((p) => "id:${p['id']}").toList()}');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photos.isNotEmpty) ...[
                  Text(
                    '${photos.length} photo${photos.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index] as Map<String, dynamic>;
                      final photoId = photo['id'] as int?;
                      final imageUrl = photo['image_url'] as String?;

                      return Stack(
                        children: [
                          // Photo
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor, width: 1),
                            ),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Color(0xFF8B6B4D).withOpacity(0.1),
                                        child: Icon(Icons.image_not_supported, color: _primaryColor),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Color(0xFF8B6B4D).withOpacity(0.1),
                                    child: Icon(Icons.image_outlined, color: _primaryColor),
                                  ),
                          ),
                          
                          // Bouton supprimer
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _deleteAnimalPhoto(photoId, index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        'Aucune photo pour cet animal',
                        style: TextStyle(
                          color: Color(0xFF6B6B6B),
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            );
          },
        ),

        // Section ajouter une nouvelle photo
        Text(
          'Ajouter une photo',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B6B6B),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _loading ? null : _pickImage,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                    ),
                  )
                : _buildPlaceholder(textColor),
          ),
        ),
        if (_imageBytes != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: () => setState(() {
                _imageFile = null;
                _imageBytes = null;
              }),
              child: Text(
                'Annuler la sélection',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _deleteAnimalPhoto(int? photoId, int index) async {
    if (photoId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette photo?'),
        content: const Text('Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        debugPrint('🗑️ Attempting to delete photo id: $photoId');
        await ApiService.deleteAnimalPhoto(photoId);
        
        // Refresh the photos list from server
        setState(() {
          _photosFuture = ApiService.getAnimalPhotos(widget.livestockId);
        });
        
        _showSuccessSnackBar('Photo supprimée');
      } catch (e) {
        debugPrint('❌ Error deleting photo: $e');
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }

  Widget _buildPlaceholder(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: _primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Ajouter une photo',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Appuyez pour sélectionner une image',
            style: TextStyle(
              color: _textSecondaryLight,
              fontWeight: FontWeight.w300,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: Material(
        borderRadius: BorderRadius.circular(10),
        color: _primaryColor,
        child: InkWell(
          onTap: _loading ? null : _submit,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Modifier',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      height: 52,
      child: Material(
        borderRadius: BorderRadius.circular(10),
        color: Colors.red.shade100,
        child: InkWell(
          onTap: _loading ? null : _delete,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Icon(
              Icons.delete_outline,
              color: Colors.red.shade700,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector({
    required Color cardColor,
    required Color textColor,
    required Color borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibilityOptions = [
      {
        'value': 'PRIVATE',
        'label': 'Privé',
        'icon': Icons.lock_outlined,
        'description': 'Visible uniquement par vous',
        'color': Colors.red.shade400,
      },
      {
        'value': 'PARTIAL',
        'label': 'Partagé',
        'icon': Icons.people_outline,
        'description': 'Visible via les posts uniquement',
        'color': Colors.orange.shade400,
      },
      {
        'value': 'PUBLIC',
        'label': 'Public',
        'icon': Icons.public_outlined,
        'description': 'Visible par tous',
        'color': const Color(0xFF6B8E23),
      },
    ];

    return Column(
      children: visibilityOptions.map((option) {
        final isSelected = _visibility == option['value'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _visibility = option['value'] as String),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? (option['color'] as Color).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? (option['color'] as Color) : borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: option['color'] as Color,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['label'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['description'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: option['color'] as Color,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
