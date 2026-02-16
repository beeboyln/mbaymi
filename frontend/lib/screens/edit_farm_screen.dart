import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/utils/app_colors.dart';

class EditFarmScreen extends StatefulWidget {
  final Map<String, dynamic> farm;
  final int? userId;
  final bool isDarkMode;

  const EditFarmScreen({super.key, required this.farm, this.userId, this.isDarkMode = false});

  @override
  State<EditFarmScreen> createState() => _EditFarmScreenState();
}

class _EditFarmScreenState extends State<EditFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _sizeCtrl;
  
  final _nameFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _sizeFocus = FocusNode();
  
  final _scrollController = ScrollController();
  
  String _type = '🌱 Agricole';
  XFile? _profileFile;
  Uint8List? _profileBytes;
  bool _loading = false;
  bool _isPublic = false;

  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.farm['name'] ?? '');
    _locationCtrl = TextEditingController(text: widget.farm['location'] ?? '');
    _sizeCtrl = TextEditingController(text: widget.farm['size_hectares']?.toString() ?? '');
    _isPublic = widget.farm['is_public'] as bool? ?? false;
    
    final soilType = (widget.farm['soil_type'] ?? '').toString().trim();
    if (soilType.isNotEmpty) {
      if (soilType.contains('Agricole') && !soilType.contains('🌱')) {
        _type = '🌱 Agricole';
      } else if (soilType.contains('Élevage') && !soilType.contains('🐄')) {
        _type = '🐄 Élevage';
      } else if (soilType.contains('Mixte') && !soilType.contains('🌾')) {
        _type = '🌾 Mixte';
      } else {
        _type = soilType;
      }
    }
    
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus && isWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smartScroll(100);
        });
      }
    });

    _locationFocus.addListener(() {
      if (_locationFocus.hasFocus && isWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smartScroll(180);
        });
      }
    });

    _sizeFocus.addListener(() {
      if (_sizeFocus.hasFocus && isWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smartScroll(260);
        });
      }
    });
  }

  void _smartScroll(double offset) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetOffset = offset > maxScroll ? maxScroll : offset;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _sizeCtrl.dispose();
    _nameFocus.dispose();
    _locationFocus.dispose();
    _sizeFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickProfile() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (p == null) return;
    final b = await p.readAsBytes();
    setState(() {
      _profileFile = p;
      _profileBytes = b;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? profileUrl = widget.farm['image_url'] ?? widget.farm['imageUrl'];
      if (_profileFile != null) {
        final u = await ApiService.uploadImageToCloudinary(_profileFile!);
        if (u != null) profileUrl = u;
      }

      final farmId = widget.farm['id'] as int;
      final Map<String, dynamic> updated = await ApiService.updateFarm(
        farmId: farmId,
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        sizeHectares: _sizeCtrl.text.isNotEmpty ? double.tryParse(_sizeCtrl.text) : null,
        soilType: _type,
        imageUrl: profileUrl,
      );

      // Update farm visibility if it changed
      final userId = AuthService.currentSession?.userId;
      if (userId != null) {
        final wasPublic = widget.farm['is_public'] as bool? ?? false;
        if (wasPublic != _isPublic) {
          await ApiService.toggleFarmVisibility(
            userId: userId,
            farmId: farmId,
            isPublic: _isPublic,
          );
        }
      }

      setState(() {
        widget.farm.clear();
        widget.farm.addAll(updated);
        widget.farm['is_public'] = _isPublic;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ferme mise à jour', style: TextStyle(letterSpacing: 0.5)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
      Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: const TextStyle(letterSpacing: 0.5)),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFBF5);
    final textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? const Color(0xFF6B6B6B) : const Color(0xFF757575);
    
    return Scaffold(
      resizeToAvoidBottomInset: !isWeb,
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'ÉDITER LA FERME',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 2.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            top: 32,
            right: 24,
            bottom: isWeb ? 80 : 32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image section
                _buildImageSection(isDark, textColor),
                
                const SizedBox(height: 48),
                
                // Form fields
                _buildTextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  label: 'NOM DE LA FERME',
                  isDark: isDark,
                  textColor: textColor,
                  subtleColor: subtleColor,
                  validator: (v) => (v==null||v.trim().isEmpty)?'Nom requis':null,
                ),
                
                const SizedBox(height: 28),
                
                _buildTextField(
                  controller: _locationCtrl,
                  focusNode: _locationFocus,
                  label: 'LOCALISATION',
                  isDark: isDark,
                  textColor: textColor,
                  subtleColor: subtleColor,
                ),
                
                const SizedBox(height: 28),
                
                _buildTextField(
                  controller: _sizeCtrl,
                  focusNode: _sizeFocus,
                  label: 'SUPERFICIE (HECTARES)',
                  isDark: isDark,
                  textColor: textColor,
                  subtleColor: subtleColor,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                
                const SizedBox(height: 28),
                
                _buildTypeSelector(isDark, textColor, subtleColor),
                
                const SizedBox(height: 48),
                
                _buildVisibilityToggle(isDark, textColor, subtleColor),
                
                const SizedBox(height: 56),
                
                // Save button
                _buildSaveButton(isDark, textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHOTO',
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: _profileBytes != null
                ? _buildNewImagePreview(isDark)
                : _buildCurrentImage(isDark),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickProfile,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'MODIFIER LA PHOTO',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImagePreview(bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_profileBytes!, fit: BoxFit.cover),
        Positioned(
          top: 12,
          right: 12,
          child: InkWell(
            onTap: () {
              setState(() {
                _profileFile = null;
                _profileBytes = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentImage(bool isDark) {
    String? url;
    
    if (widget.farm['photos'] != null && (widget.farm['photos'] as List).isNotEmpty) {
      final firstPhoto = (widget.farm['photos'] as List).first;
      if (firstPhoto is Map) {
        url = firstPhoto['image_url'] as String?;
      } else if (firstPhoto is String) {
        url = firstPhoto;
      }
    }
    
    url ??= widget.farm['image_url'] as String? ?? widget.farm['imageUrl'] as String?;
    
    if (url == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.landscape_outlined,
              size: 48,
              color: isDark ? const Color(0xFF404040) : const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune image',
              style: TextStyle(
                color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(url, fit: BoxFit.cover),
        Positioned(
          top: 12,
          right: 12,
          child: InkWell(
            onTap: () => _deleteProfilePhoto(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteProfilePhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'SUPPRIMER LA PHOTO',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Voulez-vous supprimer la photo de profil de cette ferme ?',
          style: TextStyle(
            color: widget.isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'ANNULER',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'SUPPRIMER',
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (ok == true) {
      try {
        await ApiService.deleteFarmProfilePhoto(farmId: widget.farm['id'] as int);
        imageCache.clearLiveImages();
        imageCache.clear();
        widget.farm['image_url'] = null;
        widget.farm['imageUrl'] = null;
        setState(() {
          _profileBytes = null;
          _profileFile = null;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo de profil supprimée', style: TextStyle(letterSpacing: 0.5)),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur suppression: $e', style: const TextStyle(letterSpacing: 0.5)),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool isDark,
    required Color textColor,
    required Color subtleColor,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: keyboardType,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF757575) : const Color(0xFF1A1A1A),
                width: 1.5,
              ),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
            ),
            errorStyle: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTypeSelector(bool isDark, Color textColor, Color subtleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPE DE FERME',
          style: TextStyle(
            color: subtleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTypeOption('🌱 Agricole', isDark, textColor),
            const SizedBox(width: 12),
            _buildTypeOption('🐄 Élevage', isDark, textColor),
            const SizedBox(width: 12),
            _buildTypeOption('🌾 Mixte', isDark, textColor),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(String type, bool isDark, Color textColor) {
    final isSelected = _type == type;
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? (isDark ? const Color(0xFF757575) : const Color(0xFF1A1A1A))
                  : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
              width: isSelected ? 1.5 : 1,
            ),
            color: isSelected
                ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5))
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle(bool isDark, Color textColor, Color subtleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VISIBILITÉ',
                  style: TextStyle(
                    color: subtleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isPublic ? 'Publique' : 'Privée',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Switch(
              value: _isPublic,
              onChanged: (value) {
                setState(() => _isPublic = value);
              },
              activeColor: AppColors.accent,
              inactiveTrackColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _isPublic
              ? 'Cette ferme est visible publiquement et peut être découverte par d\'autres utilisateurs.'
              : 'Cette ferme est privée et ne sera visible que pour vous.',
          style: TextStyle(
            color: subtleColor,
            fontSize: 11,
            fontWeight: FontWeight.w300,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDark, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: _loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Text(
                'ENREGISTRER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
      ),
    );
  }
}