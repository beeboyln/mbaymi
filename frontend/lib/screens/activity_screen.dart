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

  const ActivityScreen({Key? key, required this.farmId, required this.cropId, required this.userId}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  final _typeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _date;
  bool _loading = false;
  List<XFile> _imageFiles = [];
  List<Uint8List> _imageBytes = [];
  late Future<List<dynamic>> _activitiesFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedActivityType = '';

  final List<Map<String, dynamic>> _activityTypes = [
    {'icon': '🌱', 'label': 'Semis', 'value': 'Semis', 'color': Color(0xFF34C759)},
    {'icon': '💧', 'label': 'Arrosage', 'value': 'Arrosage', 'color': Color(0xFF30B0C7)},
    {'icon': '🌿', 'label': 'Fertilisation', 'value': 'Fertilisation', 'color': Color(0xFF32ADE6)},
    {'icon': '✂️', 'label': 'Taille', 'value': 'Taille', 'color': Color(0xFFFF9500)},
    {'icon': '🐛', 'label': 'Traitement', 'value': 'Traitement', 'color': Color(0xFFFF3B30)},
    {'icon': '🌾', 'label': 'Récolte', 'value': 'Récolte', 'color': Color(0xFFFFD60A)},
    {'icon': '🚜', 'label': 'Labour', 'value': 'Labour', 'color': Color(0xFF8E8E93)},
    {'icon': '📝', 'label': 'Autre', 'value': 'Autre', 'color': Color(0xFF5856D6)},
  ];

  @override
  void initState() {
    super.initState();
    _activitiesFuture = ApiService.getActivitiesForCrop(widget.cropId);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      List<String> uploadedUrls = [];
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
      // Fallback to ISO-like date if intl locale data isn't available yet
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
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B6B6B);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Subtle header background (minimal)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              color: bgColor,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Activités',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add Activity Section
                          _buildSectionHeader('Nouvelle activité', Icons.add_task_rounded, textColor),
                          const SizedBox(height: 20),
                          _buildAddActivityForm(cardColor, textColor, secondaryTextColor, borderColor, isDark),
                          const SizedBox(height: 32),

                          // Activities List Section
                          _buildSectionHeader('Historique', Icons.history_rounded, textColor),
                          const SizedBox(height: 20),
                          _buildActivitiesList(cardColor, textColor, secondaryTextColor, borderColor, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFF2D5016),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Enregistrement...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEFF7EE),
          child: Icon(icon, color: const Color(0xFF2D5016), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAddActivityForm(Color cardColor, Color textColor, Color secondaryTextColor, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Type Selector
          Text(
            'Type d\'activité',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: secondaryTextColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _activityTypes.map((type) {
              final isSelected = _selectedActivityType == type['value'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedActivityType = type['value'] as String);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (type['color'] as Color).withOpacity(0.15)
                        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? (type['color'] as Color)
                          : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        type['icon'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: isSelected ? (type['color'] as Color) : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Custom Activity Type (if Autre selected)
          if (_selectedActivityType == 'Autre') ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: TextField(
                controller: _typeCtrl,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Précisez le type d\'activité',
                  hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.edit_rounded, color: const Color(0xFF2D5016), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Date Selector
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: const Color(0xFF2D5016),
                        onPrimary: Colors.white,
                        surface: cardColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _date != null ? const Color(0xFF34C759) : borderColor,
                  width: _date != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _date != null
                            ? [const Color(0xFF34C759), const Color(0xFF30D158)]
                            : [const Color(0xFF2D5016), const Color(0xFF3D6B1F)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _date != null ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _date != null ? 'Date sélectionnée' : 'Sélectionner une date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: textColor,
                          ),
                        ),
                        if (_date != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatDateSafe(_date, pattern: 'EEEE d MMMM yyyy'),
                                style: TextStyle(
                                  fontSize: 12,
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

          const SizedBox(height: 20),

          // Notes Field
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 4,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textColor, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Ajouter des notes ou observations...',
                hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Photos Section
          Text(
            'Photos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: secondaryTextColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_imageBytes.isNotEmpty)
            Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageBytes.length,
                itemBuilder: (context, i) => Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(
                        _imageBytes[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _removeImage(i),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          GestureDetector(
            onTap: _pickImages,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    color: const Color(0xFF2D5016),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _imageBytes.isEmpty ? 'Ajouter des photos' : 'Ajouter d\'autres photos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF2D5016),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Enregistrer',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(Color cardColor, Color textColor, Color secondaryTextColor, Color borderColor, bool isDark) {
    return FutureBuilder<List<dynamic>>(
      future: _activitiesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: const Color(0xFF2D5016),
                backgroundColor: borderColor,
              ),
            ),
          );
        }

        if (snap.hasError) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFFF3B30)),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snap.error}',
                  style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final activities = snap.data ?? [];
        
        if (activities.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2D5016), Color(0xFF3D6B1F)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timeline_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucune activité',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Commencez par enregistrer votre première activité',
                  style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
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
    final typeInfo = _activityTypes.firstWhere(
      (t) => t['value'] == activityType,
      orElse: () => _activityTypes.last,
    );

    DateTime? activityDate;
    if (activity['activity_date'] != null) {
      activityDate = DateTime.tryParse(activity['activity_date'].toString());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (typeInfo['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (typeInfo['color'] as Color).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  typeInfo['icon'] as String,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityType,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w300,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (activityDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateSafe(activityDate, pattern: 'd MMM yyyy'),
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.w400,
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
                itemBuilder: (context, i) => Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    imgs[i] as String,
                    width: 160,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 160,
                        height: 120,
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                        child: Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: secondaryTextColor,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}