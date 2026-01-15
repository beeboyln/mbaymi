import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:mbaymi/screens/animal_photo_carousel_screen.dart';
import 'package:mbaymi/widgets/farm_posts_widget.dart';

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

  bool _loading = false;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  // ignore: unused_field
  late Future<List<dynamic>> _photosFuture;
  late String _visibility;
  late int _userId;
  int _selectedTabIndex = 0;

  static const Color _primaryColor = Color(0xFF6B8E23);
  static const Color _bgLight = Color(0xFFF8F9FA);
  static const Color _bgDark = Color(0xFF0A0A0A);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF1A1A1A);

  final List<String> _animalTypes = ['Bovins', 'Chèvres', 'Moutons', 'Porcs', 'Volailles', 'Autre'];
  final List<String> _healthStatuses = ['Sain', 'Malade', 'Vacciné', 'À surveiller'];
  final List<String> _feedingTypes = ['Herbe', 'Grains', 'Mixte', 'Aliment composé'];

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    _existingImageUrl = widget.livestock['image_url'];
    _photosFuture = ApiService.getAnimalPhotos(widget.livestockId);
    _visibility = widget.livestock['visibility'] ?? 'PRIVATE';
    
    _animalTypeCtrl = TextEditingController(text: widget.livestock['animal_type'] ?? '');
    _breedCtrl = TextEditingController(text: widget.livestock['breed'] ?? '');
    _quantityCtrl = TextEditingController(text: '${widget.livestock['quantity'] ?? 1}');
    _ageCtrl = TextEditingController(text: widget.livestock['age_months']?.toString() ?? '');
    _weightCtrl = TextEditingController(text: widget.livestock['weight_kg']?.toString() ?? '');
    _healthCtrl = TextEditingController(text: widget.livestock['health_status'] ?? '');
    _feedingCtrl = TextEditingController(text: widget.livestock['feeding_type'] ?? '');
    _notesCtrl = TextEditingController(text: widget.livestock['notes'] ?? '');
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

      _showSnackBar('Animal modifié avec succès', isError: false);
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context, res);
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer cet animal?'),
        content: const Text('Cette action est irréversible.'),
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
        _showSnackBar('Animal supprimé', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, {'deleted': true});
      } catch (e) {
        _showSnackBar('Erreur: ${e.toString()}', isError: true);
        setState(() => _loading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : _primaryColor,
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
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Modifier l\'animal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _delete,
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: cardColor,
              child: TabBar(
                indicatorColor: _primaryColor,
                indicatorWeight: 3,
                labelColor: _primaryColor,
                unselectedLabelColor: secondaryTextColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                tabs: const [
                  Tab(text: 'Informations'),
                  Tab(text: 'Publications'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Onglet Informations
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo principale
                          _buildPhotoSection(cardColor, textColor, secondaryTextColor),
                          
                          const SizedBox(height: 32),

                          // Informations de base
                          _buildSectionTitle('Informations'),
                          const SizedBox(height: 16),
                          
                          _buildDropdown(
                            label: 'Type d\'animal',
                            value: _animalTypeCtrl.text.isEmpty ? null : _animalTypeCtrl.text,
                            items: _animalTypes,
                            onChanged: (value) => setState(() => _animalTypeCtrl.text = value ?? ''),
                            icon: Icons.pets,
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _breedCtrl,
                            label: 'Race',
                            hint: 'Ex: Race locale',
                            icon: Icons.info_outline,
                            cardColor: cardColor,
                            textColor: textColor,
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
                                  icon: Icons.format_list_numbered,
                                  keyboardType: TextInputType.number,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  secondaryTextColor: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _ageCtrl,
                                  label: 'Âge (mois)',
                                  hint: '12',
                                  icon: Icons.calendar_today,
                                  keyboardType: TextInputType.number,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  secondaryTextColor: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _weightCtrl,
                            label: 'Poids (kg)',
                            hint: '250',
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),

                          const SizedBox(height: 32),

                          // Santé
                          _buildSectionTitle('Santé & Alimentation'),
                          const SizedBox(height: 16),
                          
                          _buildDropdown(
                            label: 'État de santé',
                            value: _healthCtrl.text.isEmpty ? null : _healthCtrl.text,
                            items: _healthStatuses,
                            onChanged: (value) => setState(() => _healthCtrl.text = value ?? ''),
                            icon: Icons.favorite_outline,
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          _buildDropdown(
                            label: 'Alimentation',
                            value: _feedingCtrl.text.isEmpty ? null : _feedingCtrl.text,
                            items: _feedingTypes,
                            onChanged: (value) => setState(() => _feedingCtrl.text = value ?? ''),
                            icon: Icons.restaurant_outlined,
                            cardColor: cardColor,
                            textColor: textColor,
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
                            maxLines: 4,
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),

                          const SizedBox(height: 32),

                          // Visibilité
                          _buildSectionTitle('Visibilité'),
                          const SizedBox(height: 16),
                          
                          _buildVisibilityOptions(cardColor, textColor, secondaryTextColor),

                          const SizedBox(height: 40),

                          // Bouton enregistrer
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Enregistrer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  // Onglet Publications
                  _buildPostsSection(cardColor, textColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsSection(Color cardColor, Color textColor) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark ? _bgDark : _bgLight,
      child: FarmPostsWidget(
        farmId: widget.livestock['farm_id'] ?? 0,
        farmName: '${widget.livestock['animal_type'] ?? 'Animal'} - ${widget.livestock['breed'] ?? ''}',
        isOwner: _userId == widget.livestock['user_id'],
        livestockId: widget.livestock['id'],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
    );
  }

  Widget _buildPhotoSection(Color cardColor, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            TextButton.icon(
              onPressed: () {
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
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('Galerie'),
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white12
                    : Colors.black12,
              ),
            ),
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                    ),
                  )
                : _existingImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _existingImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(textColor, secondaryTextColor),
                        ),
                      )
                    : _buildPlaceholder(textColor, secondaryTextColor),
          ),
        ),
        if (_imageBytes != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => setState(() {
                _imageFile = null;
                _imageBytes = null;
              }),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Annuler'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(Color textColor, Color secondaryTextColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: _primaryColor),
        const SizedBox(height: 12),
        Text(
          'Ajouter une photo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Appuyez pour sélectionner',
          style: TextStyle(
            fontSize: 13,
            color: secondaryTextColor,
          ),
        ),
      ],
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
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white12
              : Colors.black12,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(fontSize: 15, color: textColor),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: secondaryTextColor),
          labelStyle: TextStyle(color: secondaryTextColor),
          prefixIcon: Icon(icon, color: _primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white12
              : Colors.black12,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: TextStyle(fontSize: 15, color: textColor),
        dropdownColor: cardColor,
        isExpanded: true,
      ),
    );
  }

  Widget _buildVisibilityOptions(Color cardColor, Color textColor, Color secondaryTextColor) {
    final options = [
      {
        'value': 'PRIVATE',
        'label': 'Privé',
        'icon': Icons.lock_outline,
        'desc': 'Visible uniquement par vous',
        'color': Colors.red.shade400,
      },
      {
        'value': 'PARTIAL',
        'label': 'Partagé',
        'icon': Icons.people_outline,
        'desc': 'Visible via les posts',
        'color': Colors.orange.shade400,
      },
      {
        'value': 'PUBLIC',
        'label': 'Public',
        'icon': Icons.public,
        'desc': 'Visible par tous',
        'color': _primaryColor,
      },
    ];

    return Column(
      children: options.map((option) {
        final isSelected = _visibility == option['value'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => _visibility = option['value'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? (option['color'] as Color).withOpacity(0.1)
                    : cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (option['color'] as Color)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : Colors.black12),
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
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
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
        );
      }).toList(),
    );
  }
}