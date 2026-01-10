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
  final int? farmOwnerId; // ID du propriétaire de la ferme
  final bool readOnly; // Mode lecture seul

  const ActivityScreen({
    Key? key,
    required this.farmId,
    required this.cropId,
    required this.userId,
    this.farmOwnerId,
    this.readOnly = false,
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

  bool _canEdit() {
    // Si mode readOnly, pas de modifications possibles
    if (widget.readOnly) {
      return false;
    }
    
    // Peut éditer UNIQUEMENT si c'est le propriétaire de la ferme
    // Si farmOwnerId est null, c'est une ferme locale (ParcelScreen) → peut éditer
    // Si farmOwnerId != null, c'est une visite publique → peut éditer QUE si propriétaire
    
    print('🔍 _canEdit check:');
    print('   userId: ${widget.userId}');
    print('   farmOwnerId: ${widget.farmOwnerId}');
    print('   readOnly: ${widget.readOnly}');
    print('   Can edit: ${widget.farmOwnerId == null || widget.userId == widget.farmOwnerId}');
    
    if (widget.farmOwnerId == null) {
      // Mode local: utilisateur visite sa propre ferme via ParcelScreen
      print('   → Mode local (farmOwnerId null) - CAN EDIT');
      return true;
    }
    // Mode public: vérifier que l'utilisateur est le propriétaire
    final canEdit = widget.userId == widget.farmOwnerId;
    print('   → Mode public - ${canEdit ? 'CAN EDIT' : 'CANNOT EDIT'}');
    return canEdit;
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
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
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
            // Bouton pour ajouter une activité - Visible seulement pour le propriétaire
            if (!_showAddActivityForm && _canEdit()) ...[
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
              autofocus: false,
              textInputAction: TextInputAction.next,
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
            textInputAction: TextInputAction.done,
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
    final activityId = activity['id'];
    final userId = activity['user_id'];
    
    // Vérifier si l'utilisateur actuel est le créateur de l'activité
    final isCreator = !widget.readOnly && userId == widget.userId;
    
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec type et boutons d'action
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type d'activité avec badge couleur
                            Container(
                              decoration: BoxDecoration(
                                color: (typeInfo['color'] as Color).withOpacity(0.15),
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: Text(
                                activityType,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: typeInfo['color'] as Color,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Date
                            if (activityDate != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: secondaryTextColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDateSafe(activityDate, pattern: 'd MMMM yyyy'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Boutons d'action (si créateur et pas readOnly)
                      if (isCreator)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: secondaryTextColor, size: 18),
                              onPressed: () => _showEditActivityDialog(activity),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                              onPressed: () => _showDeleteActivityConfirm(activityId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Notes
            if (activity['notes'] != null && activity['notes'].toString().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  activity['notes'].toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            // Images
            if (imgs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: imgs.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        child: Container(
                          width: 140,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Image.network(
                            imgs[i] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                ),
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Color(0xFF6B6B6B),
                                  size: 24,
                                ),
                              );
                            },
                          ),
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
    );
  }

  void _showEditActivityDialog(Map<String, dynamic> activity) {
    HapticFeedback.lightImpact();
    
    final editTypeCtrl = TextEditingController(text: activity['activity_type'] ?? '');
    final editNotesCtrl = TextEditingController(text: activity['notes'] ?? '');
    DateTime? editDate = activity['activity_date'] != null 
        ? DateTime.tryParse(activity['activity_date'].toString())
        : null;
    String editSelectedType = activity['activity_type'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Modifier l\'activité'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type d'activité
                  const Text('Type d\'activité', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: editSelectedType.isNotEmpty ? editSelectedType : null,
                    items: _activityCategories.values
                        .expand((category) => category)
                        .map((item) => DropdownMenuItem<String>(
                              value: item['value'] as String,
                              child: Row(
                                children: [
                                  Icon(item['icon'] as IconData, size: 16, color: item['color'] as Color),
                                  const SizedBox(width: 8),
                                  Text(item['label'] as String),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          editSelectedType = value;
                          editTypeCtrl.text = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date
                  const Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: editDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => editDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            editDate != null 
                                ? DateFormat('dd MMM yyyy', 'fr_FR').format(editDate!)
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color: editDate != null ? Colors.black : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notes
                  const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: editNotesCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ajouter des notes...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateActivityAction(
                    activity['id'],
                    editSelectedType,
                    editDate,
                    editNotesCtrl.text,
                  );
                },
                child: const Text('Enregistrer', style: TextStyle(color: Colors.green)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateActivityAction(
    int activityId,
    String activityType,
    DateTime? activityDate,
    String notes,
  ) async {
    if (activityType.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner un type');
      return;
    }
    
    try {
      setState(() => _loading = true);
      await ApiService.updateActivity(
        activityId: activityId,
        farmId: widget.farmId,
        cropId: widget.cropId,
        activityType: activityType,
        activityDate: activityDate,
        notes: notes.isEmpty ? null : notes,
      );
      _showSuccessSnackBar('Activité mise à jour ✓');
      await _refreshActivities();
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showDeleteActivityConfirm(dynamic activityId) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette activité?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                setState(() => _loading = true);
                await ApiService.deleteActivity(activityId as int);
                _showSuccessSnackBar('Activité supprimée ✓');
                await _refreshActivities();
              } catch (e) {
                _showErrorSnackBar('Erreur: $e');
              } finally {
                setState(() => _loading = false);
              }
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}