import 'package:flutter/material.dart';
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
import 'package:mbaymi/widgets/skeleton_loader.dart';

class ParcelScreen extends StatefulWidget {
  final int farmId;
  final int userId;
  final bool readOnly;
  final bool openAddCultureModal;

  const ParcelScreen({
    super.key,
    required this.farmId,
    required this.userId,
    this.readOnly = false,
    this.openAddCultureModal = false,
  });

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  late Future<List<dynamic>> _parcelsFuture;
  late int _userId;
  int _selectedSection = 0; // 0: Parcelles, 1: Posts

  static const Color _primaryColor = AppColors.accent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.openAddCultureModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddParcel();
      });
    }
  }

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
          final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              left: 24,
              right: 24,
              top: 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  'NOUVELLE PARCELLE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                // Nom
                TextField(
                  controller: nameCtrl,
                  autofocus: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'NOM',
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    hintText: 'Ex: Parcelle Nord',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white : Colors.black87,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 32),

                // Statut
                Text(
                  'STATUT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatusChip('En préparation', status, (v) => setModalState(() => status = v), isDark),
                    _buildStatusChip('Semé', status, (v) => setModalState(() => status = v), isDark),
                    _buildStatusChip('En croissance', status, (v) => setModalState(() => status = v), isDark),
                    _buildStatusChip('Récolté', status, (v) => setModalState(() => status = v), isDark),
                  ],
                ),
                const SizedBox(height: 40),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
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
                      _showSnackBar('Parcelle créée', isError: false);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      'CRÉER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
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

  Widget _buildStatusChip(String label, String currentStatus, Function(String) onTap, bool isDark) {
    final isSelected = currentStatus == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.white : Colors.black87)
              : Colors.transparent,
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
            color: isSelected 
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : Colors.black87),
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
    _showSnackBar('Fonctionnalité en développement', isError: false);
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: isError ? Colors.red.shade400 : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedSection == 0 ? 'PARCELLES' : 'POSTS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!widget.readOnly)
            IconButton(
              icon: Icon(
                _selectedSection == 0 ? Icons.add : Icons.edit_outlined,
                color: isDark ? Colors.white70 : Colors.black87,
                size: 20,
              ),
              onPressed: _selectedSection == 0 ? _showAddParcel : _addPost,
            ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSectionTab(
                    index: 0,
                    label: 'PARCELLES',
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: isDark 
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                ),
                Expanded(
                  child: _buildSectionTab(
                    index: 1,
                    label: 'POSTS',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedSection == 0
                ? _buildParcelsSection(isDark)
                : _buildPostsSection(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTab({
    required int index,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedSection == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedSection = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      ),
    );
  }

  Widget _buildParcelsSection(bool isDark) {
    return FutureBuilder<List<dynamic>>(
      future: _parcelsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 32,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                const SizedBox(height: 24),
                Text(
                  'ERREUR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
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
                Icon(
                  Icons.landscape_outlined,
                  size: 40,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                const SizedBox(height: 24),
                Text(
                  'AUCUNE PARCELLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                if (!widget.readOnly) ...[
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: _showAddParcel,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      'CRÉER UNE PARCELLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _refresh,
          color: _primaryColor,
          backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: parcels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final parcel = parcels[index] as Map<String, dynamic>;
              return _buildParcelCard(parcel, isDark, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildPostsSection(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: FarmPostsWidget(
        farmId: widget.farmId,
        farmName: 'Posts de la ferme',
        isOwner: _userId == widget.userId,
      ),
    );
  }

  Future<void> _deleteParcel(int cropId, String cropName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'SUPPRIMER LA PARCELLE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Confirmer la suppression de "$cropName" ? Cette action est irréversible.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ANNULER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final success = await ApiService.deleteCrop(cropId);
                if (success && mounted) {
                  _showSnackBar('Parcelle supprimée', isError: false);
                  _refresh();
                } else if (mounted) {
                  _showSnackBar('Erreur de suppression', isError: true);
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Erreur: $e', isError: true);
                }
              }
            },
            child: const Text(
              'SUPPRIMER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelCard(
    Map<String, dynamic> parcel,
    bool isDark,
    int index,
  ) {
    final statusConfig = {
      'En préparation': const Color(0xFFFFB74D),
      'Semé': const Color(0xFF81C784),
      'En croissance': const Color(0xFF64B5F6),
      'Récolté': const Color(0xFF9575CD),
    };

    final status = parcel['status'] ?? 'En préparation';
    final statusColor = statusConfig[status] ?? statusConfig['En préparation']!;
    final cropName = parcel['crop_name'] ?? 'Parcelle';
    final plantedDate = parcel['planted_date'] ?? '—';
    final expectedHarvest = parcel['expected_harvest_date'] ?? '—';
    final area = parcel['area'] ?? '—';
    final imageUrl = parcel['image_url'] as String?;
    final cropId = _toInt(parcel['id']) ?? 0;

    return _ParcelCardWidget(
      cropId: cropId,
      cropName: cropName,
      status: status,
      statusColor: statusColor,
      plantedDate: plantedDate,
      expectedHarvest: expectedHarvest,
      area: area,
      imageUrl: imageUrl,
      index: index,
      isDark: isDark,
      readOnly: widget.readOnly,
      onPhotoAdd: () => _addParcelPhoto(cropId),
      onDelete: () => _deleteParcel(cropId, cropName),
      onNavigate: (screen) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
            .then((_) => _refresh());
      },
      farmId: widget.farmId,
      userId: widget.userId,
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.landscape_outlined,
            size: 40,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(height: 12),
          Text(
            'AJOUTER UNE PHOTO',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}

// Stateful widget for expandable parcel card
class _ParcelCardWidget extends StatefulWidget {
  final int cropId;
  final String cropName;
  final String status;
  final Color statusColor;
  final String plantedDate;
  final String expectedHarvest;
  final String area;
  final String? imageUrl;
  final int index;
  final bool isDark;
  final bool readOnly;
  final VoidCallback onPhotoAdd;
  final VoidCallback onDelete;
  final Function(Widget) onNavigate;
  final int farmId;
  final int userId;

  const _ParcelCardWidget({
    required this.cropId,
    required this.cropName,
    required this.status,
    required this.statusColor,
    required this.plantedDate,
    required this.expectedHarvest,
    required this.area,
    required this.imageUrl,
    required this.index,
    required this.isDark,
    required this.readOnly,
    required this.onPhotoAdd,
    required this.onDelete,
    required this.onNavigate,
    required this.farmId,
    required this.userId,
  });

  @override
  State<_ParcelCardWidget> createState() => _ParcelCardWidgetState();
}

class _ParcelCardWidgetState extends State<_ParcelCardWidget> with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isActionsExpanded = false;
  late AnimationController _animationController;
  late AnimationController _actionsAnimationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _actionsExpandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _actionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _actionsExpandAnimation = CurvedAnimation(
      parent: _actionsAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _actionsAnimationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleActionsExpand() {
    setState(() {
      _isActionsExpanded = !_isActionsExpanded;
      if (_isActionsExpanded) {
        _actionsAnimationController.forward();
      } else {
        _actionsAnimationController.reverse();
      }
    });
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.landscape_outlined,
            size: 40,
            color: widget.isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(height: 12),
          Text(
            'AJOUTER UNE PHOTO',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
              color: widget.isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDelete
                    ? Colors.red
                    : (widget.isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                    color: isDelete
                        ? Colors.red
                        : (widget.isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: widget.isDark ? Colors.white24 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkBg : Colors.white,
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image avec overlay
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                color: widget.isDark
                    ? AppColors.darkCardBg
                    : AppColors.lightCardBg,
                child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                    ? Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                color: widget.isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          );
                        },
                      )
                    : _buildPlaceholder(),
              ),

              // Gradient overlay
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // Numéro de parcelle
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '#${widget.index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Bouton photo
              if (!widget.readOnly)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: widget.onPhotoAdd,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

              // Titre et statut
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cropName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.5,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: widget.statusColor.withOpacity(0.2),
                        border: Border.all(
                          color: widget.statusColor.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2,
                          color: widget.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Section cliquable pour révéler les détails
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpand,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DÉTAILS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: widget.isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Détails expansibles avec animation
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.black.withOpacity(0.02),
                border: Border(
                  bottom: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('SEMIS', widget.plantedDate),
                  const SizedBox(height: 12),
                  _buildInfoRow('RÉCOLTE', widget.expectedHarvest),
                  const SizedBox(height: 12),
                  _buildInfoRow('SURFACE', widget.area),
                ],
              ),
            ),
          ),

          // Section cliquable pour révéler les actions
          if (!widget.readOnly)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleActionsExpand,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: widget.isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_view_outlined,
                        size: 16,
                        color: widget.isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ACTIONS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.5,
                          color: widget.isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _isActionsExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: widget.isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Actions expansibles avec animation
          if (!widget.readOnly)
            SizeTransition(
              sizeFactor: _actionsExpandAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.black.withOpacity(0.02),
                ),
                child: Column(
                  children: [
                    _buildActionButton(
                      label: 'ACTIVITÉS',
                      icon: Icons.timeline_outlined,
                      onTap: () => widget.onNavigate(
                        ActivityScreen(
                          farmId: widget.farmId,
                          cropId: widget.cropId,
                          userId: widget.userId,
                        ),
                      ),
                    ),
                    _buildActionButton(
                      label: 'PROBLÈMES',
                      icon: Icons.warning_outlined,
                      onTap: () => widget.onNavigate(
                        CropProblemsScreen(
                          farmId: widget.farmId,
                          cropId: widget.cropId,
                          userId: widget.userId,
                          cropName: widget.cropName,
                          isDarkMode: widget.isDark,
                        ),
                      ),
                    ),
                    _buildActionButton(
                      label: 'INTRANTS',
                      icon: Icons.inventory_2_outlined,
                      onTap: () => widget.onNavigate(
                        ParcelInputsScreen(
                          farmId: widget.farmId,
                          cropId: widget.cropId,
                        ),
                      ),
                    ),
                    _buildActionButton(
                      label: 'FINANCES',
                      icon: Icons.analytics_outlined,
                      onTap: () => widget.onNavigate(
                        ParcelFinanceScreen(
                          farmId: widget.farmId,
                        ),
                      ),
                    ),
                    _buildActionButton(
                      label: 'RAPPELS',
                      icon: Icons.notifications_outlined,
                      onTap: () => widget.onNavigate(
                        ParcelRemindersScreen(
                          farmId: widget.farmId,
                          cropId: widget.cropId,
                        ),
                      ),
                    ),
                    _buildActionButton(
                      label: 'SUPPRIMER',
                      icon: Icons.delete_outline,
                      onTap: widget.onDelete,
                      isDelete: true,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
            color: widget.isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
            color: widget.isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}