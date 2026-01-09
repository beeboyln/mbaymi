import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class ActivityScreen extends StatefulWidget {
  final int farmId;
  final int cropId;
  final int userId;

  const ActivityScreen({
    Key? key,
    required this.farmId,
    required this.cropId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController _typeCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime? _date;
  bool _loading = false;
  final List<XFile> _imageFiles = [];
  final List<Uint8List> _imageBytes = [];
  late Future<List<dynamic>> _activitiesFuture;
  String _selectedActivityType = '';
  bool _showAddActivityForm = false;

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

  // Types d'activités organisées par catégories
  static const Map<String, List<Map<String, dynamic>>> _activityCategories = {
    'Culture': [
      {'icon': Icons.grass, 'label': 'Semis', 'value': 'Semis', 'color': Colors.green},
      {'icon': Icons.eco, 'label': 'Plantation', 'value': 'Plantation', 'color': Colors.green},
      {'icon': Icons.agriculture, 'label': 'Récolte', 'value': 'Récolte', 'color': Colors.yellow},
      {'icon': Icons.agriculture_outlined, 'label': 'Labour', 'value': 'Labour', 'color': Colors.brown},
    ],
    'Soins': [
      {'icon': Icons.water_drop, 'label': 'Arrosage', 'value': 'Arrosage', 'color': Colors.blue},
      {'icon': Icons.clean_hands, 'label': 'Fertilisation', 'value': 'Fertilisation', 'color': Color(0xFF32ADE6)},
      {'icon': Icons.content_cut, 'label': 'Taille', 'value': 'Taille', 'color': Colors.orange},
      {'icon': Icons.bug_report, 'label': 'Traitement', 'value': 'Traitement', 'color': Colors.red},
    ],
    'Autres': [
      {'icon': Icons.assignment, 'label': 'Inspection', 'value': 'Inspection', 'color': Colors.purple},
      {'icon': Icons.build, 'label': 'Maintenance', 'value': 'Maintenance', 'color': Colors.grey},
      {'icon': Icons.assessment, 'label': 'Suivi', 'value': 'Suivi', 'color': Colors.cyan},
      {'icon': Icons.edit, 'label': 'Autre', 'value': 'Autre', 'color': Colors.purple},
    ],
  };

  @override
  void initState() {
    super.initState();
    _activitiesFuture = ApiService.getActivitiesForCrop(widget.cropId);
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshActivities() async {
    setState(() {
      _activitiesFuture = ApiService.getActivitiesForCrop(widget.cropId);
    });
  }

  Future<void> _submit() async {
    final activityType = _selectedActivityType.isEmpty ? _typeCtrl.text.trim() : _selectedActivityType;
    if (activityType.isEmpty) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar('Veuillez sélectionner un type d\'activité');
      return;
    }
    
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final List<String> uploadedUrls = [];
      for (final f in _imageFiles) {
        final url = await ApiService.uploadImageToCloudinary(f);
        if (url != null) uploadedUrls.add(url);
      }

      await ApiService.createActivity(
        farmId: widget.farmId,
        cropId: widget.cropId,
        userId: widget.userId,
        activityType: activityType,
        activityDate: _date,
        notes: _notesCtrl.text.trim(),
        imageUrls: uploadedUrls,
      );
      
      if (mounted) {
        _showSuccessSnackBar('Activité enregistrée avec succès');
        _typeCtrl.clear();
        _notesCtrl.clear();
        _imageFiles.clear();
        _imageBytes.clear();
        _date = null;
        _selectedActivityType = '';
        _showAddActivityForm = false;
        await _refreshActivities();
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Erreur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(maxWidth: 1600);
    if (picked == null || picked.isEmpty) return;
    
    final bytesList = <Uint8List>[];
    for (final p in picked) {
      final b = await p.readAsBytes();
      bytesList.add(b);
    }
    setState(() {
      _imageFiles.addAll(picked);
      _imageBytes.addAll(bytesList);
    });
  }

  String _formatDateSafe(DateTime? dt, {String pattern = 'd MMM yyyy'}) {
    if (dt == null) return '';
    try {
      return DateFormat(pattern, 'fr_FR').format(dt);
    } catch (e) {
      return dt.toLocal().toString().split('.')[0];
    }
  }

  void _removeImage(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _imageFiles.removeAt(index);
      _imageBytes.removeAt(index);
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w300)),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w300)),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    );
  }

  void _toggleAddActivityForm() {
    HapticFeedback.lightImpact();
    setState(() {
      _showAddActivityForm = !_showAddActivityForm;
    });
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
      resizeToAvoidBottomInset: true, // ✅ Laisse Flutter gérer la compensation
      body: SafeArea( // ✅ Wrap tout le body avec SafeArea
        child: Column(
          children: [
            // Header minimaliste
            DecoratedBox(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: secondaryTextColor,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Activités',
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
            ),

            // Contenu principal - Scrollable avec padding normal
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20), // ✅ Padding normal, pas de viewInsets
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    // Section pour ajouter une nouvelle activité
                    _buildAddActivitySection(cardColor, textColor, secondaryTextColor, borderColor, isDark),
                    
                    // Historique des activités
                    _buildActivitiesList(cardColor, textColor, secondaryTextColor, borderColor, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddActivitySection(Color cardColor, Color textColor, Color secondaryTextColor, Color borderColor, bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bouton pour ajouter une activité
            if (!_showAddActivityForm) ...[
              GestureDetector(
                onTap: _toggleAddActivityForm,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B6B4D),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Ajouter une activité',
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
            ],

            // Formulaire d'ajout (caché par défaut)
            if (_showAddActivityForm) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nouvelle activité',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleAddActivityForm,
                    icon: Icon(
                      Icons.close,
                      color: secondaryTextColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildActivityForm(cardColor, textColor, secondaryTextColor, borderColor, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityForm(Color cardColor, Color textColor, Color secondaryTextColor, Color borderColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type d'activité avec catégories
        Text(
          'Type d\'activité',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 12),

        // Affichage par catégories
        ..._activityCategories.entries.map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: category.value.map((type) {
                  final isSelected = _selectedActivityType == type['value'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedActivityType = type['value'] as String);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryColor : cardColor,
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        border: Border.all(
                          color: isSelected ? _primaryColor : borderColor,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: isSelected ? Colors.white : type['color'] as Color,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
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
              const SizedBox(height: 16),
            ],
          );
        }).toList(),

        // Type personnalisé
        if (_selectedActivityType == 'Autre') ...[
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: TextField(
              controller: _typeCtrl,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: textColor),
              decoration: InputDecoration(
                hintText: 'Précisez le type d\'activité',
                hintStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w300),
                prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF8B6B4D), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Date
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (d != null) setState(() => _date = d);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(
                color: _date != null ? _primaryColor : borderColor,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _date != null ? _primaryColor : _primaryLight.withOpacity(0.1),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Icon(
                      _date != null ? Icons.check_circle_outline : Icons.calendar_today_outlined,
                      color: _date != null ? Colors.white : _primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _date != null ? 'Date sélectionnée' : 'Sélectionner une date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                        if (_date != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDateSafe(_date, pattern: 'EEEE d MMMM yyyy'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
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
          ),
        ),

        const SizedBox(height: 20),

        // Notes
        DecoratedBox(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: TextField(
            controller: _notesCtrl,
            maxLines: 4,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: textColor, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Ajouter des notes ou observations...',
              hintStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w300),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Photos
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_imageBytes.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageBytes.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            child: Image.memory(
                              _imageBytes[i],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(i),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_imageBytes.isNotEmpty) const SizedBox(height: 12),
            
            GestureDetector(
              onTap: _pickImages,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: Color(0xFF8B6B4D),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ajouter des photos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF8B6B4D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _toggleAddActivityForm,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B6B4D),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _loading ? null : _submit,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
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
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Enregistrer',
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
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivitiesList(Color cardColor, Color textColor, Color secondaryTextColor, Color borderColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: _primaryDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<dynamic>>(
            future: _activitiesFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8B6B4D),
                      ),
                    ),
                  ),
                );
              }

              if (snap.hasError) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final activities = snap.data ?? [];
              
              if (activities.isEmpty) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.timeline_outlined,
                          size: 56,
                          color: Color(0xFFA58A6D),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Aucune activité',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Commencez par enregistrer votre première activité',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B6B6B),
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: activities.map((a) => _buildActivityCard(
                  a as Map<String, dynamic>,
                  cardColor,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                  isDark,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    Map<String, dynamic> activity,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    bool isDark,
  ) {
    final imgs = (activity['image_urls'] as List?) ?? [];
    final activityType = activity['activity_type'] ?? 'Activité';
    
    // Trouver le type d'activité dans les catégories
    late Map<String, dynamic> typeInfo;
    bool found = false;
    
    for (final category in _activityCategories.values) {
      final match = category.firstWhere(
        (t) => t['value'] == activityType,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        typeInfo = match;
        found = true;
        break;
      }
    }
    
    if (!found) {
      typeInfo = _activityCategories['Autres']!.last;
    }

    DateTime? activityDate;
    if (activity['activity_date'] != null) {
      activityDate = DateTime.tryParse(activity['activity_date'].toString());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: (typeInfo['color'] as Color).withOpacity(0.1),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(
                        color: (typeInfo['color'] as Color).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        typeInfo['icon'] as IconData,
                        color: typeInfo['color'] as Color,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activityType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                        if (activityDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_outlined,
                                size: 14,
                                color: Color(0xFF6B6B6B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateSafe(activityDate, pattern: 'd MMM yyyy'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              if (activity['notes'] != null && activity['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  activity['notes'].toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],

              if (imgs.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imgs.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          child: Image.network(
                            imgs[i] as String,
                            width: 160,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox(
                                width: 160,
                                height: 120,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                                  ),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Color(0xFF6B6B6B),
                                    size: 32,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}