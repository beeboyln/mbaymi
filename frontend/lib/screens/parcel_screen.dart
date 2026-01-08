import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/screens/activity_screen.dart';
import 'package:mbaymi/screens/crop_problems_screen.dart';

class ParcelScreen extends StatefulWidget {
  final int farmId;
  final int userId;

  const ParcelScreen({Key? key, required this.farmId, required this.userId}) : super(key: key);

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  late Future<List<dynamic>> _parcelsFuture;
  bool _loadingPhotos = false;

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
  void initState() {
    super.initState();
    _parcelsFuture = ApiService.getFarmCrops(widget.farmId);
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
          final cardColor = isDark ? _cardDark : _cardLight;
          final textColor = isDark ? _textDark : _textLight;
          final secondaryTextColor = isDark ? _textSecondaryDark : _textSecondaryLight;
          final borderColor = isDark ? _borderDark : _borderLight;

          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    const Center(
                      child: SizedBox(
                        width: 40,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFD1D1D6),
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      'Nouvelle parcelle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    _buildModalTextField(
                      controller: nameCtrl,
                      label: 'Nom de la parcelle',
                      hint: 'Ex: Parcelle Nord',
                      icon: Icons.edit_outlined,
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
                      icon: Icons.square_foot_outlined,
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
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip('En préparation', 'En préparation', status, (v) => setModalState(() => status = v), cardColor, borderColor, textColor, isDark),
                        _buildStatusChip('Semé', 'Semé', status, (v) => setModalState(() => status = v), cardColor, borderColor, textColor, isDark),
                        _buildStatusChip('En croissance', 'En croissance', status, (v) => setModalState(() => status = v), cardColor, borderColor, textColor, isDark),
                        _buildStatusChip('Récolté', 'Récolté', status, (v) => setModalState(() => status = v), cardColor, borderColor, textColor, isDark),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B6B4D),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
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
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Créer la parcelle',
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: textColor),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w300),
          labelStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w400, fontSize: 14),
          prefixIcon: Icon(icon, color: _primaryColor, size: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: isSelected ? Colors.white : textColor,
            ),
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

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  List<dynamic> _toList(dynamic v) {
    if (v == null) return const [];
    if (v is List<dynamic>) return v;
    try {
      return List<dynamic>.from(v as Iterable);
    } catch (e) {
      return const [];
    }
  }

  String? _firstString(dynamic v) {
    final l = _toList(v);
    if (l.isEmpty) return null;
    return l.first?.toString();
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
      body: SafeArea(
        child: Column(
          children: [
            // Header minimaliste
            DecoratedBox(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
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
                        'Mes Parcelles',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: textColor,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    // Photo Button
                    IconButton(
                      onPressed: _loadingPhotos ? null : _addFarmPhotos,
                      icon: _loadingPhotos
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF8B6B4D),
                              ),
                            )
                          : const Icon(
                              Icons.add_a_photo_outlined,
                              color: Color(0xFF8B6B4D),
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 8),
                    // Add Parcel Button
                    IconButton(
                      onPressed: _showAddParcel,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF8B6B4D),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contenu principal
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _parcelsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF8B6B4D),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Chargement...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B6B6B),
                              fontWeight: FontWeight.w300,
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
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFFFF3B30),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w300,
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
                          const Icon(
                            Icons.landscape_outlined,
                            size: 56,
                            color: Color(0xFFA58A6D),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Aucune parcelle',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Commencez par ajouter votre première parcelle',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: _showAddParcel,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: _primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text(
                              'Créer une parcelle',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: _primaryColor,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
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
          ],
        ),
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
    final Map<String, Map<String, dynamic>> statusColors = const {
      'En préparation': {'color': Colors.orange, 'icon': Icons.construction_outlined},
      'Semé': {'color': Colors.green, 'icon': Icons.grass_outlined},
      'En croissance': {'color': Colors.blue, 'icon': Icons.trending_up_outlined},
      'Récolté': {'color': Colors.purple, 'icon': Icons.check_circle_outlined},
    };

    final status = parcel['status'] ?? 'En préparation';
    final statusInfo = statusColors[status] ?? const {'color': Colors.grey, 'icon': Icons.help_outline_outlined};

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image - Afficher une image par défaut au lieu de faire un appel API
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Icon(
                      Icons.landscape_outlined,
                      size: 30,
                      color: _primaryColor,
                    ),
                  ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: (statusInfo['color'] as Color).withOpacity(0.1),
                              borderRadius: const BorderRadius.all(Radius.circular(6)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                      fontWeight: FontWeight.w400,
                                      color: statusInfo['color'] as Color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Color(0xFF6B6B6B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            parcel['planted_date'] ?? 'Non défini',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF6B6B6B),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Bouton Détails
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
                              cropId: _toInt(parcel['id']) ?? 0,
                              userId: widget.userId,
                            ),
                          ),
                        ).then((_) => _refresh());
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Détails',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 1,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFE8E2D8),
                    ),
                  ),
                ),
                // Bouton Activité
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
                              cropId: _toInt(parcel['id']) ?? 0,
                              userId: widget.userId,
                            ),
                          ),
                        ).then((_) => _refresh());
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Activité',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF8B6B4D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 1,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFE8E2D8),
                    ),
                  ),
                ),
                // Bouton Problèmes
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CropProblemsScreen(
                              farmId: widget.farmId,
                              cropId: _toInt(parcel['id']) ?? 0,
                              userId: widget.userId,
                              cropName: parcel['crop_name'] as String? ?? 'Culture',
                              isDarkMode: false,
                            ),
                          ),
                        ).then((_) => _refresh());
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            '🚨 Problèmes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFFE07856),
                            ),
                          ),
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
    );
  }

  Widget _buildDefaultImage(bool isDark) {
    return SizedBox(
      width: 60,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF8B6B4D).withOpacity(0.1),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Icon(
          Icons.landscape_outlined,
          color: Color(0xFF8B6B4D),
          size: 28,
        ),
      ),
    );
  }
}