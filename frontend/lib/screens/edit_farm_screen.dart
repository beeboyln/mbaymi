import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class EditFarmScreen extends StatefulWidget {
  final Map<String, dynamic> farm;
  final int? userId;
  final bool isDarkMode;

  const EditFarmScreen({Key? key, required this.farm, this.userId, this.isDarkMode = false}) : super(key: key);

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

  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.farm['name'] ?? '');
    _locationCtrl = TextEditingController(text: widget.farm['location'] ?? '');
    _sizeCtrl = TextEditingController(text: widget.farm['size_hectares']?.toString() ?? '');
    
    final soilType = (widget.farm['soil_type'] ?? '').toString().trim();
    if (soilType.isNotEmpty) {
      // Normalize soil type - ensure it has emoji
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

      final Map<String, dynamic> updated = await ApiService.updateFarm(
        farmId: widget.farm['id'] as int,
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        sizeHectares: _sizeCtrl.text.isNotEmpty ? double.tryParse(_sizeCtrl.text) : null,
        soilType: _type,
        imageUrl: profileUrl,
      );

      // Update local farm map so UI reflects saved values
      setState(() {
        widget.farm.clear();
        widget.farm.addAll(updated);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ferme mise à jour')));
      Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = (widget.farm['photos'] as List?) ?? [];
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[700];
    
    return Scaffold(
      resizeToAvoidBottomInset: !isWeb,
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Éditer la ferme'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: EdgeInsets.only(
          left: 16,
          top: 16,
          right: 16,
          bottom: isWeb ? 60 : 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: labelColor),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                ),
                validator: (v) => (v==null||v.trim().isEmpty)?'Nom requis':null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                focusNode: _locationFocus,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Localisation',
                  labelStyle: TextStyle(color: labelColor),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizeCtrl,
                focusNode: _sizeFocus,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Superficie (ha)',
                  labelStyle: TextStyle(color: labelColor),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                style: TextStyle(color: textColor),
                dropdownColor: cardBg,
                items: const [
                  DropdownMenuItem(value: '🌱 Agricole', child: Text('🌱 Agricole')),
                  DropdownMenuItem(value: '🐄 Élevage', child: Text('🐄 Élevage')),
                  DropdownMenuItem(value: '🌾 Mixte', child: Text('🌾 Mixte')),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
                decoration: InputDecoration(
                  labelText: 'Type de ferme',
                  labelStyle: TextStyle(color: labelColor),
                  filled: true,
                  fillColor: cardBg,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _profileBytes == null
                        ? _buildProfileDisplay()
                        : Stack(
                            children: [
                              Image.memory(_profileBytes!, height: 80, width: double.infinity, fit: BoxFit.cover),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _profileFile = null;
                                      _profileBytes = null;
                                    });
                                  },
                                  child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                                ),
                              ),
                            ],
                          ),
                  ),
                  TextButton.icon(onPressed: _pickProfile, icon: const Icon(Icons.photo), label: const Text('Changer photo')),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _loading?null:_save, child: _loading?const CircularProgressIndicator():const Text('Enregistrer')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDisplay() {
    String? url;
    
    // Essayer d'obtenir l'URL depuis les photos
    if (widget.farm['photos'] != null && (widget.farm['photos'] as List).isNotEmpty) {
      final firstPhoto = (widget.farm['photos'] as List).first;
      if (firstPhoto is Map) {
        url = firstPhoto['image_url'] as String?;
      } else if (firstPhoto is String) {
        url = firstPhoto;
      }
    }
    
    // Sinon utiliser image_url ou imageUrl
    if (url == null) {
      url = widget.farm['image_url'] as String? ?? widget.farm['imageUrl'] as String?;
    }
    
    if (url == null) return const Text('Aucune image');
    
    return Stack(
      children: [
        Image.network(url, height: 80, width: double.infinity, fit: BoxFit.cover),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Supprimer la photo de profil'),
                  content: const Text('Voulez-vous supprimer la photo de profil de cette ferme ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                  ],
                ),
              );
              if (ok == true) {
                try {
                  await ApiService.deleteFarmProfilePhoto(farmId: widget.farm['id'] as int);
                  // Vider le cache d'images
                  imageCache.clearLiveImages();
                  imageCache.clear();
                  // Update local farm map
                  widget.farm['image_url'] = null;
                  widget.farm['imageUrl'] = null;
                  setState(() {
                    _profileBytes = null;
                    _profileFile = null;
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo de profil supprimée')));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
                }
              }
            },
            child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete, color: Colors.white, size: 16)),
          ),
        ),
      ],
    );
  }

  Widget profileImageWidget(Map<String, dynamic> farm) {
    final url = (farm['photos'] != null && (farm['photos'] as List).isNotEmpty) ? (farm['photos'] as List).first : (farm['image_url'] ?? farm['imageUrl']);
    if (url == null) return const Expanded(child: Text('Aucune image'));
    return Expanded(child: Image.network(url, height: 80));
  }
}
