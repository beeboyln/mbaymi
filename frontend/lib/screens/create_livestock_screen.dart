import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/utils/app_colors.dart';

class CreateLivestockScreen extends StatefulWidget {
  final int? userId;

  const CreateLivestockScreen({super.key, this.userId});

  @override
  State<CreateLivestockScreen> createState() => _CreateLivestockScreenState();
}

class _CreateLivestockScreenState extends State<CreateLivestockScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _animalTypeCtrl = TextEditingController();
  final TextEditingController _customAnimalTypeCtrl = TextEditingController();
  final TextEditingController _breedCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController(text: '1');
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _healthCtrl = TextEditingController();
  final TextEditingController _feedingCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  final FocusNode _animalTypeFocus = FocusNode();
  final FocusNode _breedFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _healthFocus = FocusNode();
  final FocusNode _feedingFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  bool _loading = false;
  final List<XFile> _imageFiles = [];
  final List<Uint8List> _imageBytes = [];
  String _visibility = 'PRIVATE'; // PRIVATE, PUBLIC, PARTIAL

  // Palette de couleurs
  static const Color _primaryColor = Color(0xFF8B6B4D);
  // ignore: unused_field
  static const Color _primaryLight = Color(0xFFA58A6D);
  static const Color _accentColor = Color(0xFFC4A484);
  static const Color _bgLight = Color(0xFFFAF8F5);
  static const Color _bgDark = Color(0xFF121212);
  static const Color _cardLight = AppColors.lightBg;
  static const Color _cardDark = Color(0xFF1E1E1E);
  static const Color _borderLight = Color(0xFFE8E2D8);
  static const Color _borderDark = Color(0xFF2C2C2C);
  static const Color _textLight = Color(0xFF1A1A1A);
  static const Color _textDark = Colors.white;
  static const Color _textSecondaryLight = Color(0xFF6B6B6B);
  static const Color _textSecondaryDark = Color(0xFF8E8E93);

  final List<String> _animalTypes = ['Bovins', 'Chèvres', 'Moutons', 'Volailles', 'Autre'];
  final List<String> _healthStatuses = ['Sain', 'Malade', 'Vacciné', 'À surveiller'];
  final List<String> _feedingTypes = ['Herbe', 'Grains', 'Mixte', 'Aliment composé'];

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
        _imageFiles.add(image);
        _imageBytes.add(bytes);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      _imageBytes.removeAt(index);
    });
  }

  @override
  void dispose() {
    _animalTypeCtrl.dispose();
    _customAnimalTypeCtrl.dispose();
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

    if (widget.userId == null) {
      _showErrorSnackBar('Utilisateur non connecté');
      return;
    }

    // Vérifier que le type d'animal est défini
    String animalType = _animalTypeCtrl.text.trim();
    if (animalType == 'Autre') {
      if (_customAnimalTypeCtrl.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez préciser le type d\'animal');
        return;
      }
      animalType = _customAnimalTypeCtrl.text.trim();
    }

    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    try {
      String? imageUrl;
      
      // Upload première image à Cloudinary si sélectionnée
      if (_imageFiles.isNotEmpty) {
        imageUrl = await ApiService.uploadImageToCloudinary(_imageFiles[0]);
      }

      final res = await ApiService.createLivestock(
        userId: widget.userId!,
        animalType: animalType,
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

      // Upload les photos supplémentaires (toutes sauf la première)
      if (_imageFiles.length > 1) {
        final livestockId = res['id'] as int;
        for (int i = 1; i < _imageFiles.length; i++) {
          try {
            final additionalImageUrl = await ApiService.uploadImageToCloudinary(_imageFiles[i]);
            if (additionalImageUrl != null && additionalImageUrl.isNotEmpty) {
              await ApiService.addAnimalPhoto(
                livestockId: livestockId,
                imageUrl: additionalImageUrl,
              );
            }
          } catch (e) {
            // Continuer malgré les erreurs d'upload de photos supplémentaires
            print('Erreur upload photo $i: $e');
          }
        }
      }

      _showSuccessSnackBar('Animal ajouté avec succès !');
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(cardColor, textColor, secondaryTextColor, borderColor),

            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: AnimatedPadding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + (bottomInset > 8 ? bottomInset : 0)),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type d'animal avec option personnalisée
                        _buildSectionTitle('Type d\'animal'),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Type',
                          value: _animalTypeCtrl.text.isEmpty ? null : _animalTypeCtrl.text,
                          items: _animalTypes,
                          onChanged: (value) {
                            setState(() => _animalTypeCtrl.text = value ?? '');
                            if (value == 'Autre') {
                              _customAnimalTypeCtrl.clear();
                            }
                          },
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          icon: Icons.pets_outlined,
                        ),
                        // Si "Autre" est sélectionné, afficher un champ texte pour type personnalisé
                        if (_animalTypeCtrl.text == 'Autre') ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _customAnimalTypeCtrl,
                            label: 'Précisez le type',
                            hint: 'Ex: Lapins, Chevaux, etc.',
                            icon: Icons.edit_outlined,
                            cardColor: cardColor,
                            textColor: textColor,
                            borderColor: borderColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ],
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
                        const SizedBox(height: 32),

                        // Informations de base
                        _buildSectionTitle('Informations'),
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

                        // Santé et alimentation
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

                        // Visibilité
                        _buildSectionTitle('Visibilité'),
                        const SizedBox(height: 16),
                        _buildVisibilitySelector(
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 32),

                        // Photo
                        _buildImageSection(
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 32),

                        // Notes
                        _buildSectionTitle('Notes'),
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
                        const SizedBox(height: 40),

                        // Bouton submit
                        _buildSubmitButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color cardColor, Color textColor, Color secondaryTextColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: Icon(Icons.close_rounded, color: secondaryTextColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              'Ajouter un animal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: textColor,
                letterSpacing: -0.8,
              ),
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
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextFormField(
        autocorrect: false,
        enableSuggestions: false,
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: maxLines == 1 ? 1 : 3,
        onChanged: onChanged,
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
        initialValue: value,
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
          labelStyle: const TextStyle(color: Color(0xFF6B6B6B), fontWeight: FontWeight.w400),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildSectionTitle('Photos')),
            if (_imageFiles.isNotEmpty)
              Text(
                '${_imageFiles.length} photo(s)',
                style: const TextStyle(
                  color: _accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Grille d'images existantes
        if (_imageBytes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _imageBytes.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _imageBytes[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // Bouton ajouter photo
        GestureDetector(
          onTap: _loading ? null : _pickImage,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
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
                  const Text(
                    'Appuyez pour ajouter des images',
                    style: TextStyle(
                      color: _textSecondaryLight,
                      fontWeight: FontWeight.w300,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilitySelector({
    required Color cardColor,
    required Color textColor,
    required Color borderColor,
  }) {
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ajouter l\'animal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
