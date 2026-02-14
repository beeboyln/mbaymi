import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/map_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_spacing.dart';
import 'package:mbaymi/utils/app_typography.dart';
import 'package:mbaymi/utils/app_radius.dart';

class CreateFarmScreen extends StatefulWidget {
  final int? userId;

  const CreateFarmScreen({super.key, this.userId});

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
  
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _regionFocus = FocusNode();
  final FocusNode _departmentFocus = FocusNode();
  final FocusNode _communeFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _sizeFocus = FocusNode();
  
  String _type = 'Agricole';
  String? _location;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _loading = false;

  // Constantes pour les dimensions
  static const double _defaultPadding = AppSpacing.lg;
  static const double _smallPadding = AppSpacing.sm;
  static const double _mediumPadding = AppSpacing.md;
  static const double _largePadding = AppSpacing.xl;
  static const double _borderRadius = AppRadius.md;
  static const double _buttonHeight = AppSpacing.buttonHeight;
  static const double _imageHeight = 200.0;

  @override
  void dispose() {
    // Dispose tous les contrôleurs et focus nodes
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    _departmentCtrl.dispose();
    _communeCtrl.dispose();
    _descCtrl.dispose();
    _sizeCtrl.dispose();
    
    _nameFocus.dispose();
    _regionFocus.dispose();
    _departmentFocus.dispose();
    _communeFocus.dispose();
    _descFocus.dispose();
    _sizeFocus.dispose();
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
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85, // Compression pour de meilleures performances
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    // Ferme le clavier avant la soumission
    FocusScope.of(context).unfocus();
    
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
        if (url == null) {
          throw Exception('Échec de l\'upload de l\'image');
        }
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
        sizeHectares: _sizeCtrl.text.isNotEmpty 
            ? double.tryParse(_sizeCtrl.text) 
            : null,
        soilType: _type,
        imageUrl: uploadedUrl,
        latitude: lat,
        longitude: lng,
      );

      _showSuccessSnackBar('Ferme créée avec succès !');
      
      // Petite délai pour que l'utilisateur voie le message
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
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
    );
  }

  Color _getSecondaryTextColor(bool isDark) {
    return AppColors.getTextColor(isDark).withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.getBgColor(isDark);
    final cardColor = AppColors.getCardBgColor(isDark);
    final textColor = AppColors.getTextColor(isDark);
    final secondaryTextColor = _getSecondaryTextColor(isDark);
    final borderColor = AppColors.getBorderColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header minimaliste
            _buildHeader(cardColor, textColor, secondaryTextColor, borderColor),
            
            // Formulaire - Scrollable avec padding dynamique
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: _defaultPadding,
                  right: _defaultPadding,
                  top: _defaultPadding,
                  bottom: MediaQuery.of(context).viewInsets.bottom + _defaultPadding,
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo de la ferme
                        _buildImageSection(cardColor, borderColor),
                        const SizedBox(height: _largePadding),

                        // Informations de base
                        _buildSectionTitle('Informations de base'),
                        const SizedBox(height: _mediumPadding),
                        _buildTextField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          label: 'Nom de la ferme',
                          hint: 'Ex: Ferme Keur Moussa',
                          icon: Icons.agriculture_outlined,
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                          textInputAction: TextInputAction.next,
                          onSubmitted: () => FocusScope.of(context).requestFocus(_sizeFocus),
                        ),
                        const SizedBox(height: _mediumPadding),
                        _buildTypeSelector(cardColor, textColor, borderColor),
                        const SizedBox(height: _mediumPadding),
                        _buildTextField(
                          controller: _sizeCtrl,
                          focusNode: _sizeFocus,
                          label: 'Superficie',
                          hint: 'Hectares',
                          icon: Icons.square_foot_outlined,
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          onSubmitted: () => FocusScope.of(context).requestFocus(_regionFocus),
                        ),
                        const SizedBox(height: _largePadding),

                        // Localisation
                        _buildSectionTitle('Localisation'),
                        const SizedBox(height: _mediumPadding),
                        _buildTextField(
                          controller: _regionCtrl,
                          focusNode: _regionFocus,
                          label: 'Région',
                          hint: 'Ex: Thiès',
                          icon: Icons.location_on_outlined,
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          textInputAction: TextInputAction.next,
                          onSubmitted: () => FocusScope.of(context).requestFocus(_departmentFocus),
                        ),
                        const SizedBox(height: _mediumPadding),
                        _buildTextField(
                          controller: _departmentCtrl,
                          focusNode: _departmentFocus,
                          label: 'Département',
                          hint: 'Ex: Mbour',
                          icon: Icons.map_outlined,
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          textInputAction: TextInputAction.next,
                          onSubmitted: () => FocusScope.of(context).requestFocus(_communeFocus),
                        ),
                        const SizedBox(height: _mediumPadding),
                        _buildTextField(
                          controller: _communeCtrl,
                          focusNode: _communeFocus,
                          label: 'Commune / Village',
                          hint: 'Ex: Saly',
                          icon: Icons.home_outlined,
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          textInputAction: TextInputAction.next,
                          onSubmitted: () => FocusScope.of(context).requestFocus(_descFocus),
                        ),
                        const SizedBox(height: _mediumPadding),
                        _buildMapSelector(cardColor, textColor, secondaryTextColor, borderColor),
                        const SizedBox(height: _largePadding),

                        // Description
                        _buildSectionTitle('Description'),
                        const SizedBox(height: _mediumPadding),
                        _buildTextField(
                          controller: _descCtrl,
                          focusNode: _descFocus,
                          label: 'Description',
                          hint: 'Décrivez votre ferme...',
                          icon: Icons.text_snippet_outlined,
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          maxLines: 4,
                          textInputAction: TextInputAction.done,
                          onSubmitted: () => FocusScope.of(context).unfocus(),
                        ),
                        const SizedBox(height: 40),

                        // Bouton de soumission
                        _buildSubmitButton(),
                        const SizedBox(height: _defaultPadding),
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

  // ... (le reste de vos méthodes _buildHeader, _buildImageSection, etc. reste inchangé)
  Widget _buildHeader(Color cardColor, Color textColor, Color secondaryTextColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.only(
        left: _defaultPadding,
        right: _defaultPadding,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            icon: Icon(Icons.close_rounded, color: secondaryTextColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: _defaultPadding),
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.primary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildImageSection(Color cardColor, Color borderColor) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: _imageHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: _imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.primaryLight),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ajouter une photo',
                    style: AppTypography.body.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Touchez pour sélectionner',
                    style: AppTypography.caption.copyWith(color: AppColors.primaryLight),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(_borderRadius - 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_imageBytes!, fit: BoxFit.cover, cacheWidth: 800),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(_smallPadding),
                        ),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
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
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: false,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: maxLines == 1 ? 1 : 3,
        textInputAction: textInputAction,
        onFieldSubmitted: (_) => onSubmitted?.call(),
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: textColor),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w300),
          labelStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w400),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: _mediumPadding, vertical: _mediumPadding),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(Color cardColor, Color textColor, Color borderColor) {
    const List<Map<String, dynamic>> types = [
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
        const SizedBox(height: _smallPadding),
        Row(
          children: types.map((type) {
            final isSelected = _type == type['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: _smallPadding),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _type = type['value'] as String);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : cardColor,
                      borderRadius: BorderRadius.circular(_smallPadding),
                      border: Border.all(color: isSelected ? AppColors.primary : borderColor, width: 1),
                    ),
                    child: Column(
                      children: [
                        Icon(type['icon'] as IconData, color: isSelected ? Colors.white : AppColors.primary, size: 20),
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
        padding: const EdgeInsets.all(_mediumPadding),
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
                color: _location != null ? AppColors.primary : AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(_smallPadding),
              ),
              child: Icon(Icons.map_outlined, color: _location != null ? Colors.white : AppColors.primary, size: 20),
            ),
            const SizedBox(width: _mediumPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _location != null ? 'Localisation définie' : 'Définir sur la carte',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _location ?? 'Sélectionner un emplacement',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: secondaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: secondaryTextColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: _buttonHeight,
      child: Material(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.primary,
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
                      SizedBox(width: _smallPadding),
                      Text(
                        'Créer la ferme',
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