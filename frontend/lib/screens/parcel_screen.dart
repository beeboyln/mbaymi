import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/screens/activity_screen.dart';
import 'package:mbaymi/screens/crop_problems_screen.dart';
import 'package:mbaymi/screens/parcel_inputs_screen.dart';
import 'package:mbaymi/screens/parcel_finance_screen.dart';
import 'package:mbaymi/screens/parcel_reminders_screen.dart';
import 'package:mbaymi/widgets/farm_posts_widget.dart';
import 'package:mbaymi/utils/app_colors.dart';

class ParcelScreen extends StatefulWidget {
  final int farmId;
  final int userId;
  final bool readOnly;

  const ParcelScreen({
    Key? key,
    required this.farmId,
    required this.userId,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  late Future<List<dynamic>> _parcelsFuture;
  late int _userId;
  int _selectedSection = 0; // 0: Parcelles, 1: Posts

  static const Color _primaryColor = Color(0xFF6B8E23);
  static const Color _bgLight = AppColors.lightBg;
  static const Color _bgDark = Color(0xFF0A0A0A);
  static const Color _cardLight = AppColors.lightBg;
  static const Color _cardDark = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    _loadData();
  }

  void _loadData() {
    _parcelsFuture = ApiService.getFarmCrops(widget.farmId);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  void _showAddParcel() {
    final nameCtrl = TextEditingController();
    String status = 'En préparation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardColor = isDark ? _cardDark : _cardLight;
          final textColor = isDark ? Colors.white : Colors.black87;
          final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;

          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: 20,
              left: 24,
              right: 24,
              top: 20,
            ),
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Nouvelle parcelle',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Name Field
                TextField(
                  controller: nameCtrl,
                  autofocus: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(fontSize: 16, color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Nom de la parcelle',
                    hintText: 'Ex: Parcelle Nord',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    hintStyle: TextStyle(color: secondaryTextColor),
                    prefixIcon: Icon(Icons.landscape_outlined, color: _primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Status
                Text(
                  'Statut',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip('En préparation', status, (v) => setModalState(() => status = v), cardColor, textColor),
                    _buildStatusChip('Semé', status, (v) => setModalState(() => status = v), cardColor, textColor),
                    _buildStatusChip('En croissance', status, (v) => setModalState(() => status = v), cardColor, textColor),
                    _buildStatusChip('Récolté', status, (v) => setModalState(() => status = v), cardColor, textColor),
                  ],
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      
                      await ApiService.addCrop(
                        farmId: widget.farmId,
                        cropName: name,
                        status: status,
                      );
                      Navigator.pop(context);
                      _refresh();
                      _showSnackBar('Parcelle créée avec succès', isError: false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: const Text(
                      'Créer la parcelle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String label, String currentStatus, Function(String) onTap, Color cardColor, Color textColor) {
    final isSelected = currentStatus == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }

  Future<void> _addParcelPhoto(int cropId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (picked == null) return;
    
    try {
      final url = await ApiService.uploadImageToCloudinary(picked);
      if (url != null) {
        await ApiService.addCropPhoto(cropId: cropId, imageUrl: url);
      }
      if (!mounted) return;
      _showSnackBar('Photo ajoutée', isError: false);
      _refresh();
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  Future<void> _addPost() async {
    // Implémentez la logique pour ajouter un post
    _showSnackBar('Fonctionnalité d\'ajout de post à implémenter', isError: false);
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
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
          splashRadius: 1,
        ),
        title: Text(
          _selectedSection == 0 ? 'Parcelles' : 'Posts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          if (!widget.readOnly && _selectedSection == 0)
            IconButton(
              icon: Icon(Icons.add, color: _primaryColor),
              onPressed: _showAddParcel,
              tooltip: 'Ajouter une parcelle',
              splashRadius: 1,
            ),
          if (!widget.readOnly && _selectedSection == 1)
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: _primaryColor),
              onPressed: _addPost,
              tooltip: 'Ajouter un post',
              splashRadius: 1,
            ),
        ],
      ),
      body: Column(
        children: [
          // Onglets de sections
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSectionTab(
                    index: 0,
                    label: 'Parcelles',
                    icon: Icons.landscape_outlined,
                  ),
                ),
                Expanded(
                  child: _buildSectionTab(
                    index: 1,
                    label: 'Posts',
                    icon: Icons.chat_bubble_outline,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedSection == 0
                ? _buildParcelsSection(cardColor, textColor, secondaryTextColor, isDark)
                : _buildPostsSection(cardColor, textColor, secondaryTextColor, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedSection == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedSection = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? _primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? _primaryColor : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _primaryColor : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParcelsSection(
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: _parcelsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _primaryColor,
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(color: secondaryTextColor),
                ),
              ],
            ),
          );
        }
        
        final parcels = snapshot.data ?? [];
        
        if (parcels.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.landscape_outlined,
                      size: 64,
                      color: _primaryColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune parcelle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez votre première parcelle',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    if (!widget.readOnly) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddParcel,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Créer une parcelle',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          splashFactory: NoSplash.splashFactory,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _refresh,
          color: _primaryColor,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: parcels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final parcel = parcels[index] as Map<String, dynamic>;
              return _buildParcelCard(
                parcel,
                cardColor,
                textColor,
                secondaryTextColor,
                isDark,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostsSection(
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: FarmPostsWidget(
        farmId: widget.farmId,
        farmName: 'Posts de la ferme',
        isOwner: _userId == widget.userId,
      ),
    );
  }

  Widget _buildParcelCard(
    Map<String, dynamic> parcel,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final Map<String, Map<String, dynamic>> statusConfig = {
      'En préparation': {
        'color': const Color(0xFFFFA726),
        'icon': Icons.construction_outlined,
      },
      'Semé': {
        'color': const Color(0xFF66BB6A),
        'icon': Icons.grass_outlined,
      },
      'En croissance': {
        'color': const Color(0xFF42A5F5),
        'icon': Icons.trending_up_outlined,
      },
      'Récolté': {
        'color': const Color(0xFFAB47BC),
        'icon': Icons.check_circle_outlined,
      },
    };

    final status = parcel['status'] ?? 'En préparation';
    final config = statusConfig[status] ?? statusConfig['En préparation']!;
    final statusColor = config['color'] as Color;
    final statusIcon = config['icon'] as IconData;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image avec overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: _primaryColor.withOpacity(0.1),
                  child: parcel['image_url'] != null &&
                          parcel['image_url'].toString().isNotEmpty
                      ? Image.network(
                          parcel['image_url'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),
              
              // Gradient overlay
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),

              // Bouton ajouter photo
              if (!widget.readOnly)
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    onPressed: () => _addParcelPhoto(_toInt(parcel['id']) ?? 0),
                    icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),

              // Titre et statut
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel['crop_name'] ?? 'Parcelle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Informations
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  parcel['planted_date'] ?? 'Non défini',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (!widget.readOnly)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  _buildActionButton(
                    label: 'Activités',
                    icon: Icons.timeline,
                    onTap: () {
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
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildActionButton(
                    label: 'Problèmes',
                    icon: Icons.warning_outlined,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CropProblemsScreen(
                            farmId: widget.farmId,
                            cropId: _toInt(parcel['id']) ?? 0,
                            userId: widget.userId,
                            cropName: parcel['crop_name'] as String? ?? 'Culture',
                            isDarkMode: isDark,
                          ),
                        ),
                      ).then((_) => _refresh());
                    },
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildActionButton(
                    label: 'Intrants',
                    icon: Icons.shopping_bag_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParcelInputsScreen(farmId: widget.farmId, cropId: _toInt(parcel['id']) ?? 0),
                        ),
                      ).then((_) => _refresh());
                    },
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildActionButton(
                    label: 'Finances',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParcelFinanceScreen(farmId: widget.farmId),
                        ),
                      ).then((_) => _refresh());
                    },
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildActionButton(
                    label: 'Rappels',
                    icon: Icons.calendar_month_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParcelRemindersScreen(farmId: widget.farmId, cropId: _toInt(parcel['id']) ?? 0),
                        ),
                      ).then((_) => _refresh());
                    },
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color ?? _primaryColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color ?? _primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.landscape_outlined,
            size: 48,
            color: _primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajouter une photo',
            style: TextStyle(
              fontSize: 13,
              color: _primaryColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}