import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/screens/activity_screen.dart';

class ParcelScreen extends StatefulWidget {
  final int farmId;
  final int userId;

  const ParcelScreen({Key? key, required this.farmId, required this.userId}) : super(key: key);

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _parcelsFuture;
  bool _loadingPhotos = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _parcelsFuture = ApiService.getFarmCrops(widget.farmId);
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
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _parcelsFuture = ApiService.getFarmCrops(widget.farmId);
    });
  }

  void _showAddParcel() {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    String status = 'En préparation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
          final secondaryTextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B6B6B);
          final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5);

          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D5016), Color(0xFF3D6B1F)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.landscape_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Nouvelle parcelle',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    _buildModalTextField(
                      controller: nameCtrl,
                      label: 'Nom de la parcelle',
                      hint: 'Ex: Parcelle Nord',
                      icon: Icons.edit_rounded,
                      cardColor: cardColor,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Size Field
                    _buildModalTextField(
                      controller: sizeCtrl,
                      label: 'Superficie (hectares)',
                      hint: 'Ex: 2.5',
                      icon: Icons.square_foot_rounded,
                      cardColor: cardColor,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
                      isDark: isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 20),

                    // Status Selector
                    Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip('🌱 En préparation', 'En préparation', status, (v) => setModalState(() => status = v), cardColor, borderColor, textColor, isDark),
                        _buildStatusChip('🌾 Semé', 'Semé', status, (v) => setModalState(() => status = v), cardColor, borderColor, textColor, isDark),
                        _buildStatusChip('🌿 En croissance', 'En croissance', status, (v) => setModalState(() => status = v), cardColor, borderColor, textColor, isDark),
                        _buildStatusChip('✅ Récolté', 'Récolté', status, (v) => setModalState(() => status = v), cardColor, borderColor, textColor, isDark),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D5016), Color(0xFF3D6B1F), Color(0xFF4A7F26)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D5016).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              HapticFeedback.heavyImpact();
                              return;
                            }
                            HapticFeedback.mediumImpact();
                            await ApiService.addCrop(farmId: widget.farmId, cropName: name, status: status);
                            Navigator.pop(context);
                            _refresh();
                            _showSuccessSnackBar('Parcelle ajoutée avec succès');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Créer la parcelle',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5), fontWeight: FontWeight.w400),
          labelStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w600, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF2D5016), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, String currentStatus, Function(String) onTap, Color cardColor, Color borderColor, Color textColor, bool isDark) {
    final isSelected = currentStatus == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D5016) : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D5016) : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textColor,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Future<void> _addFarmPhotos() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(maxWidth: 1600);
    if (picked.isEmpty) return;
    
    setState(() => _loadingPhotos = true);
    try {
      for (final file in picked) {
        final url = await ApiService.uploadImageToCloudinary(file);
        if (url != null) {
          await ApiService.addFarmPhoto(farmId: widget.farmId, imageUrl: url);
        }
      }
      if (!mounted) return;
      _showSuccessSnackBar('${picked.length} photo(s) ajoutée(s)');
      _refresh();
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    } finally {
      if (mounted) setState(() => _loadingPhotos = false);
    }
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
          // Gradient Header Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D5016),
                    const Color(0xFF3D6B1F).withOpacity(0.8),
                    bgColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Mes Parcelles',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      // Photo Button
                      GestureDetector(
                        onTap: _loadingPhotos ? null : _addFarmPhotos,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: _loadingPhotos
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Parcel Button
                      GestureDetector(
                        onTap: _showAddParcel,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded, color: Color(0xFF2D5016), size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Ajouter',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D5016),
                                ),
                              ),
                            ],
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
                    child: FutureBuilder<List<dynamic>>(
                      future: _parcelsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: const Color(0xFF2D5016),
                                  backgroundColor: borderColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chargement...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: Color(0xFFFF3B30),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Erreur de chargement',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        final parcels = snapshot.data ?? [];
                        
                        if (parcels.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2D5016), Color(0xFF3D6B1F)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.landscape_rounded,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Aucune parcelle',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Commencez par ajouter votre première parcelle',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: _showAddParcel,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2D5016), Color(0xFF3D6B1F)],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2D5016).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_circle_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Créer une parcelle',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _refresh,
                          color: const Color(0xFF2D5016),
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            itemCount: parcels.length,
                            itemBuilder: (context, index) {
                              final p = parcels[index] as Map<String, dynamic>;
                              return _buildParcelCard(p, cardColor, textColor, secondaryTextColor, borderColor, isDark);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelCard(
    Map<String, dynamic> parcel,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    bool isDark,
  ) {
    final statusColors = {
      'En préparation': {'color': const Color(0xFFFF9500), 'icon': Icons.construction_rounded},
      'Semé': {'color': const Color(0xFF34C759), 'icon': Icons.grass_rounded},
      'En croissance': {'color': const Color(0xFF30B0C7), 'icon': Icons.trending_up_rounded},
      'Récolté': {'color': const Color(0xFF5856D6), 'icon': Icons.check_circle_rounded},
    };

    final status = parcel['status'] ?? 'En préparation';
    final statusInfo = statusColors[status] ?? {'color': Colors.grey, 'icon': Icons.help_outline_rounded};

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActivityScreen(
              farmId: widget.farmId,
              cropId: parcel['id'] as int,
              userId: widget.userId,
            ),
          ),
        ).then((_) => _refresh());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
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
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Image with Future Builder
                  FutureBuilder<List<dynamic>>(
                    future: ApiService.getActivitiesForCrop(parcel['id'] as int),
                    builder: (context, snap) {
                      Widget imageWidget;
                      
                      if (snap.connectionState == ConnectionState.waiting) {
                        imageWidget = Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFF2D5016),
                                backgroundColor: borderColor,
                              ),
                            ),
                          ),
                        );
                      } else if (snap.hasData && (snap.data?.isNotEmpty ?? false)) {
                        final activities = (snap.data! as List<dynamic>).cast<Map<String, dynamic>>();
                        final withImages = activities.where((a) => ((a['image_urls'] as List?)?.isNotEmpty ?? false)).toList();
                        
                        if (withImages.isNotEmpty) {
                          withImages.sort((a, b) {
                            final da = DateTime.tryParse(a['activity_date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                            final db = DateTime.tryParse(b['activity_date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                            return db.compareTo(da);
                          });
                          final latest = withImages.first;
                          final imgUrl = (latest['image_urls'] as List).first as String;
                          
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              imgUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDefaultImage(isDark),
                            ),
                          );
                        } else {
                          imageWidget = _buildDefaultImage(isDark);
                        }
                      } else {
                        imageWidget = _buildDefaultImage(isDark);
                      }

                      return imageWidget;
                    },
                  ),
                  const SizedBox(width: 16),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parcel['crop_name'] ?? 'Parcelle',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (statusInfo['color'] as Color).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (statusInfo['color'] as Color).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusInfo['icon'] as IconData,
                                    size: 14,
                                    color: statusInfo['color'] as Color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: statusInfo['color'] as Color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              parcel['planted_date'] ?? 'Non défini',
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<List<dynamic>>(
                          future: ApiService.getActivitiesForCrop(parcel['id'] as int),
                          builder: (context, actSnap) {
                            if (actSnap.connectionState == ConnectionState.waiting) {
                              return const SizedBox.shrink();
                            }
                            final count = (actSnap.data ?? []).length;
                            return Row(
                              children: [
                                Icon(
                                  Icons.assignment_turned_in_rounded,
                                  size: 14,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$count activité${count > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow Button
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5016).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFF2D5016),
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityScreen(
                                farmId: widget.farmId,
                                cropId: parcel['id'] as int,
                                userId: widget.userId,
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility_rounded,
                                size: 18,
                                color: textColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Voir les détails',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: borderColor,
                  ),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityScreen(
                                farmId: widget.farmId,
                                cropId: parcel['id'] as int,
                                userId: widget.userId,
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_task_rounded,
                                size: 18,
                                color: Color(0xFF2D5016),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ajouter activité',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D5016),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultImage(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5016), Color(0xFF3D6B1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.grass_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}