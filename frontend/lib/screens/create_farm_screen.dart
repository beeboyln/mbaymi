import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/map_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class CreateFarmScreen extends StatefulWidget {
  final int? userId;

  const CreateFarmScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _regionCtrl = TextEditingController();
  final TextEditingController _departmentCtrl = TextEditingController();
  final TextEditingController _communeCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _sizeCtrl = TextEditingController();
  String _type = 'Agricole';
  String? _location;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _loading = false;

  // Palette de couleurs marron moderne
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _primaryLight = Color(0xFFA58A6D);
  static const Color _primaryDark = Color(0xFF5D4730);
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    _departmentCtrl.dispose();
    _communeCtrl.dispose();
    _descCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _location = result);
    }
  }

  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (widget.userId == null) {
      _showErrorSnackBar('Utilisateur non connecté');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      String? uploadedUrl;
      double? lat;
      double? lng;
      if (_imageFile != null) {
        _imageBytes = await _imageFile!.readAsBytes();
        final url = await ApiService.uploadImageToCloudinary(_imageFile!);
        if (url == null) throw Exception('Échec de l\'upload de l\'image');
        uploadedUrl = url;
      }
      if (_location != null && _location!.contains(',')) {
        final parts = _location!.split(',');
        lat = double.tryParse(parts[0]);
        lng = double.tryParse(parts[1]);
      }
      final res = await ApiService.createFarm(
        userId: widget.userId!,
        name: _nameCtrl.text.trim(),
        location: _location ?? '${_regionCtrl.text} / ${_communeCtrl.text}',
        sizeHectares: _sizeCtrl.text.isNotEmpty ? double.tryParse(_sizeCtrl.text) : null,
        soilType: _type,
        imageUrl: uploadedUrl,
        latitude: lat,
        longitude: lng,
      );

      _showSuccessSnackBar('Ferme créée avec succès !');
      Navigator.pop(context, res);
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w300)),
        backgroundColor: const Color(0xFF8B6B4D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w300)),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getSecondaryTextColor(bool isDark) {
    return isDark ? _textSecondaryDark : _textSecondaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? _cardDark : _cardLight;
    final textColor = isDark ? _textDark : _textLight;
    final secondaryTextColor = _getSecondaryTextColor(isDark);
    final borderColor = isDark ? _borderDark : _borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header minimaliste
            Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: secondaryTextColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Créer une ferme',
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
            ),

            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo de la ferme
                      _buildImageSection(cardColor, borderColor),
                      const SizedBox(height: 32),

                      // Informations de base
                      _buildSectionTitle('Informations de base'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Nom de la ferme',
                        hint: 'Ex: Ferme Keur Moussa',
                        icon: Icons.agriculture_outlined,
                        cardColor: cardColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTypeSelector(cardColor, textColor, borderColor),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _sizeCtrl,
                        label: 'Superficie',
                        hint: 'Hectares',
                        icon: Icons.square_foot_outlined,
                        cardColor: cardColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 32),

                      // Localisation
                      _buildSectionTitle('Localisation'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _regionCtrl,
                        label: 'Région',
                        hint: 'Ex: Thiès',
                        icon: Icons.location_on_outlined,
                        cardColor: cardColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _departmentCtrl,
                        label: 'Département',
                        hint: 'Ex: Mbour',
                        icon: Icons.map_outlined,
                        cardColor: cardColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _communeCtrl,
                        label: 'Commune / Village',
                        hint: 'Ex: Saly',
                        icon: Icons.home_outlined,
                        cardColor: cardColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 16),
                      _buildMapSelector(cardColor, textColor, secondaryTextColor, borderColor),
                      const SizedBox(height: 32),

                      // Description
                      _buildSectionTitle('Description'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descCtrl,
                        label: 'Description',
                        hint: 'Décrivez votre ferme...',
                        icon: Icons.text_snippet_outlined,
                        cardColor: cardColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 40),

                      // Bouton de soumission
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: _primaryDark,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildImageSection(Color cardColor, Color borderColor) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: _imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: _primaryLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ajouter une photo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Touchez pour sélectionner',
                    style: TextStyle(
                      fontSize: 13,
                      color: _primaryLight,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.memory(
                      _imageBytes!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
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
    required Color secondaryTextColor,
    required Color borderColor,
    String? Function(String?)? validator,
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
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: textColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: secondaryTextColor,
            fontWeight: FontWeight.w300,
          ),
          labelStyle: TextStyle(
            color: secondaryTextColor,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: _primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(Color cardColor, Color textColor, Color borderColor) {
    final List<Map<String, dynamic>> types = const [
      {'icon': Icons.grass_outlined, 'label': 'Agricole', 'value': 'Agricole'},
      {'icon': Icons.agriculture_outlined, 'label': 'Élevage', 'value': 'Élevage'},
      {'icon': Icons.forest_outlined, 'label': 'Mixte', 'value': 'Mixte'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de ferme',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _getSecondaryTextColor(Theme.of(context).brightness == Brightness.dark),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: types.map((type) {
            final isSelected = _type == type['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _type = type['value'] as String);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor : cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _primaryColor : borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        color: isSelected ? Colors.white : _primaryColor,
                        size: 20,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        type['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMapSelector(Color cardColor, Color textColor, Color secondaryTextColor, Color borderColor) {
    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _location != null ? _primaryColor : _primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.map_outlined,
                color: _location != null ? Colors.white : _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _location != null ? 'Localisation définie' : 'Définir sur la carte',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _location ?? 'Sélectionner un emplacement',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: secondaryTextColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _submit,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Créer la ferme',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}