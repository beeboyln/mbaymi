import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/screens/farm/activity_screen.dart';
import 'package:mbaymi/screens/farm/crop_problems_screen.dart';
import 'package:mbaymi/screens/farm/parcel_inputs_screen.dart';
import 'package:mbaymi/screens/farm/parcel_finance_screen.dart';
import 'package:mbaymi/screens/farm/parcel_reminders_screen.dart';
import 'package:mbaymi/widgets/farm_posts_widget.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/services/traceability_export_service.dart';
import 'package:intl/intl.dart';

class ParcelScreen extends StatefulWidget {
  final int farmId;
  final int userId;
  final int? farmOwnerId;  // ID of the farm owner for read-only mode
  final bool readOnly;
  final bool openAddCultureModal;
  final int? selectedParcelId;  // ID d'une parcelle à afficher en priorité

  const ParcelScreen({
    super.key,
    required this.farmId,
    required this.userId,
    this.farmOwnerId,
    this.readOnly = false,
    this.openAddCultureModal = false,
    this.selectedParcelId,
  });

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  late Future<List<dynamic>> _parcelsFuture;
  late int _userId;
  int _selectedSection = 0; // 0: Parcelles, 1: Posts
  late ScrollController _scrollController;
  bool _hasScrolledToParcel = false;

  static const Color _primaryColor = AppColors.accent;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _userId = AuthService.currentSession?.userId ?? 0;
    _loadData();
  }

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    _parcelsFuture = ApiService.getFarmCrops(widget.farmId);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
      _hasScrolledToParcel = false; // Reset pour permettre re-scroll
    });
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null || dateValue == '' || dateValue == '—') {
      return '—';
    }
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return '—';
      }
      // Format: "20 Feb 2026"
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return '—';
    }
  }

  String _formatArea(dynamic areaValue) {
    if (areaValue == null || areaValue == '' || areaValue == '—') {
      return '—';
    }
    
    try {
      final area = areaValue is double ? areaValue : double.tryParse(areaValue.toString());
      if (area == null) return '—';
      
      // Si la valeur est >= 1, c'est probablement en m², sinon en hectares
      if (area >= 100) {
        return '${area.toStringAsFixed(0)} m²';
      } else {
        return '${area.toStringAsFixed(2)} ha';
      }
    } catch (e) {
      return '—';
    }
  }

  Future<String> _getSowingDate(int cropId) async {
    try {
      final activities = await ApiService.getActivitiesForCrop(cropId);
      
      // Find the most recent 'sowing' activity
      for (var activity in activities) {
        if (activity['activity_type'] == 'sowing') {
          return _formatDate(activity['activity_date']);
        }
      }
      return '—';
    } catch (e) {
      debugPrint('Error getting sowing date: $e');
      return '—';
    }
  }

  Future<String> _getHarvestDate(int cropId) async {
    try {
      final activities = await ApiService.getActivitiesForCrop(cropId);
      
      // Find the most recent 'harvest' activity
      for (var activity in activities) {
        if (activity['activity_type'] == 'harvest') {
          return _formatDate(activity['activity_date']);
        }
      }
      return '—';
    } catch (e) {
      debugPrint('Error getting harvest date: $e');
      return '—';
    }
  }

  void _scrollToParcel(int index) {
    if (_hasScrolledToParcel) return;
    _hasScrolledToParcel = true;
    
    // Chaque item fait ~200px (card ~170px + gap 24px)
    final double offset = (index * 194.0) - 50; // 194 = card + gap, -50 pour centrer un peu
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _showAddParcel() {
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    String status = 'En préparation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = AppColors.getBgColor(isDark);

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
                      color: isDark ? Colors.white38 : Colors.black26,
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

                // Surface
                TextField(
                  controller: areaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'SURFACE',
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    hintText: 'Ex: 500 m² ou 0.5 hectares',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: isDark ? Colors.white38 : Colors.black26,
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
                      
                      final area = areaCtrl.text.trim().isEmpty
                          ? null
                          : double.tryParse(areaCtrl.text.trim());
                      
                      await ApiService.addCrop(
                        farmId: widget.farmId,
                        cropName: name,
                        status: status,
                        area: area,
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
                : (isDark ? Colors.white60 : Colors.black87),
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

  Future<void> _editParcel(
    int cropId,
    String currentName,
    double? currentArea,
    String currentStatus,
  ) async {
    final nameCtrl = TextEditingController(text: currentName);
    final areaCtrl = TextEditingController(text: currentArea?.toString() ?? '');
    String status = currentStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = AppColors.getBgColor(isDark);

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
                  'MODIFIER PARCELLE',
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

                // Surface
                TextField(
                  controller: areaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'SURFACE',
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    hintText: 'Ex: 500 m² ou 0.5 hectares',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: isDark ? Colors.white38 : Colors.black26,
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

                // État
                Text(
                  'ÉTAT',
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

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text(
                          'ANNULER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          
                          final area = areaCtrl.text.trim().isEmpty
                              ? null
                              : double.tryParse(areaCtrl.text.trim());
                          
                          try {
                            await ApiService.updateCrop(
                              cropId: cropId,
                              updates: {
                                'crop_name': name,
                                'area': area,
                                'status': status,
                              },
                            );
                            Navigator.pop(context);
                            _refresh();
                            _showSnackBar('Parcelle mise à jour', isError: false);
                          } catch (e) {
                            _showSnackBar('Erreur: $e', isError: true);
                          }
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
                          'ENREGISTRER',
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
              ],
            ),
          );
        },
      ),
    );
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
      AppColors.createSnackBar(
        message: message,
        isError: isError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.getBgColor(isDark);

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
                color: isDark ? Colors.white60 : Colors.black87,
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
                color: isDark ? Colors.white38 : Colors.black12,
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
                    color: isDark ? Colors.white38 : Colors.black26,
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
                    color: isDark ? Colors.white38 : Colors.black26,
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
          backgroundColor: AppColors.getBgColor(isDark),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: parcels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final parcel = parcels[index] as Map<String, dynamic>;
              // Après le build, scroll vers la parcelle si c'est celle sélectionnée
              if (!_hasScrolledToParcel && widget.selectedParcelId != null && parcel['id'] == widget.selectedParcelId) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToParcel(index);
                });
              }
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
        isOwner: !widget.readOnly && (_userId == widget.userId),
      ),
    );
  }

  Future<void> _downloadParcelTraceability(int cropId, String cropName) async {
    await TraceabilityExportService.showExportMenu(
      context: context,
      title: cropName,
      loadSections: () async {
        final activities = await ApiService.getActivitiesForCrop(cropId);
        final inputs = await ApiService.listInputsForCrop(cropId);
        final transactions = await ApiService.listTransactionsForCrop(cropId);
        final financeSummary = await ApiService.getFinanceSummaryForCrop(cropId);
        final problems = await ApiService.getCropProblems(cropId);
        final reminders = await ApiService.listRemindersForCrop(widget.farmId, cropId);

        final allParcels = await ApiService.getFarmCrops(widget.farmId);
        final currentParcel = allParcels.firstWhere(
          (parcel) => (parcel['id'] == cropId || parcel['crop_id'] == cropId),
          orElse: () => <String, dynamic>{'area': null},
        );
        final summaryRow = <String, dynamic>{
          'Parcelle': cropName,
          'Surface': _formatArea(currentParcel['area']),
        };
        if (financeSummary.isNotEmpty) {
          summaryRow.addAll(Map<String, dynamic>.from(financeSummary));
        }

        final enrichedActivities = TraceabilityExportService.enrichActivityRows(
          activities: activities.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
          inputs: inputs,
        );

        return [
          TraceabilitySection(
            title: 'Résumé de la parcelle',
            rows: [summaryRow],
          ),
          if (activities.isNotEmpty)
            TraceabilitySection(
              title: 'Activités',
              rows: enrichedActivities,
            ),
          if (inputs.isNotEmpty)
            TraceabilitySection(
              title: 'Intrants',
              rows: inputs.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
            ),
          if (transactions.isNotEmpty)
            TraceabilitySection(
              title: 'Finances',
              rows: transactions.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
            ),
          if (problems.isNotEmpty)
            TraceabilitySection(
              title: 'Maladies et problèmes',
              rows: problems.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
            ),
          if (reminders.isNotEmpty)
            TraceabilitySection(
              title: 'Rappels',
              rows: reminders.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
            ),
        ].whereType<TraceabilitySection>().toList();
      },
    );
  }

  Future<void> _deleteParcel(int cropId, String cropName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.getBgColor(isDark) : Colors.white,
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
            color: isDark ? Colors.white60 : Colors.black54,
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
                color: isDark ? Colors.white60 : Colors.black54,
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
    final area = _formatArea(parcel['area']);
    final imageUrl = parcel['image_url'] as String?;
    final cropId = _toInt(parcel['id']) ?? 0;

    return _ParcelCardWidget(
      cropId: cropId,
      cropName: cropName,
      status: status,
      statusColor: statusColor,
      plantedDateFuture: _getSowingDate(cropId),
      expectedHarvestFuture: _getHarvestDate(cropId),
      area: area,
      imageUrl: imageUrl,
      index: index,
      isDark: isDark,
      readOnly: widget.readOnly,
      farmOwnerId: widget.farmOwnerId,
      onPhotoAdd: () => _addParcelPhoto(cropId),
      onDelete: () => _deleteParcel(cropId, cropName),
      onDownload: () => _downloadParcelTraceability(cropId, cropName),
      onEdit: (id, name) => _editParcel(
        id,
        name,
        parcel['area'] as double?,
        (parcel['status'] ?? 'En préparation').toString(),
      ),
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
              color: isDark ? Colors.white38 : Colors.black26,
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
  final Future<String> plantedDateFuture;
  final Future<String> expectedHarvestFuture;
  final String area;
  final String? imageUrl;
  final int index;
  final bool isDark;
  final bool readOnly;
  final int? farmOwnerId;
  final VoidCallback onPhotoAdd;
  final VoidCallback onDelete;
  final VoidCallback onDownload;
  final Function(Widget) onNavigate;
  final int farmId;
  final int userId;
  final Function(int cropId, String cropName) onEdit;

  const _ParcelCardWidget({
    required this.cropId,
    required this.cropName,
    required this.status,
    required this.statusColor,
    required this.plantedDateFuture,
    required this.expectedHarvestFuture,
    required this.area,
    required this.imageUrl,
    required this.index,
    required this.isDark,
    required this.readOnly,
    this.farmOwnerId,
    required this.onPhotoAdd,
    required this.onDelete,
    required this.onDownload,
    required this.onNavigate,
    required this.farmId,
    required this.userId,
    required this.onEdit,
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

  Future<void> _showSaleDialog() async {
    final productCtrl = TextEditingController(text: widget.cropName);
    final quantityCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'kg');
    final priceCtrl = TextEditingController();
    final buyerCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            final quantity = double.tryParse(
                quantityCtrl.text.trim().replaceAll(',', '.'));
            final unitPrice = double.tryParse(
                priceCtrl.text.trim().replaceAll(',', '.'));
            final product = productCtrl.text.trim();
            if (product.isEmpty || quantity == null || quantity <= 0 || unitPrice == null || unitPrice <= 0) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(content: Text('Renseignez le produit, la quantité et le prix unitaire.')),
              );
              return;
            }

            setSheetState(() => saving = true);
            final buyer = buyerCtrl.text.trim();
            final notes = notesCtrl.text.trim();
            final saleNotes = [
              'Quantité : ${quantity.toString()} ${unitCtrl.text.trim().isEmpty ? 'unité(s)' : unitCtrl.text.trim()}',
              if (buyer.isNotEmpty) 'Acheteur : $buyer',
              if (notes.isNotEmpty) notes,
            ].join(' · ');
            try {
              await ApiService.createSale({
                'farm_id': widget.farmId,
                'crop_id': widget.cropId,
                'product_name': product,
                'quantity': quantity,
                'unit': unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
                'price_per_unit': unitPrice,
                'category': 'Vente parcelle',
                'description': saleNotes,
              });
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vente enregistrée dans les finances.')),
              );
            } catch (error) {
              if (!sheetContext.mounted) return;
              setSheetState(() => saving = false);
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(content: Text('Impossible d’enregistrer la vente : $error')),
              );
            }
          }

          final textColor = widget.isDark ? Colors.white : Colors.black87;
          final mutedColor = widget.isDark ? Colors.white54 : Colors.black54;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: mutedColor.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('ENREGISTRER UNE VENTE',
                      style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 20),
                  _saleField(productCtrl, 'PRODUIT', 'Maïs, tomate…', textColor, mutedColor),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _saleField(quantityCtrl, 'QUANTITÉ', '0', textColor, mutedColor, numeric: true)),
                      const SizedBox(width: 10),
                      SizedBox(width: 105, child: _saleField(unitCtrl, 'UNITÉ', 'kg', textColor, mutedColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _saleField(priceCtrl, 'PRIX UNITAIRE (FCFA)', '0', textColor, mutedColor, numeric: true),
                  const SizedBox(height: 12),
                  _saleField(buyerCtrl, 'ACHETEUR (OPTIONNEL)', 'Nom du client', textColor, mutedColor),
                  const SizedBox(height: 12),
                  _saleField(notesCtrl, 'NOTES', 'Détails de la vente…', textColor, mutedColor, maxLines: 2),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving ? null : submit,
                      icon: saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 17),
                      label: Text(saving ? 'ENREGISTREMENT…' : 'ENREGISTRER LA VENTE'),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.isDark ? Colors.white : Colors.black87,
                        foregroundColor: widget.isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    productCtrl.dispose();
    quantityCtrl.dispose();
    unitCtrl.dispose();
    priceCtrl.dispose();
    buyerCtrl.dispose();
    notesCtrl.dispose();
  }

  Widget _saleField(
    TextEditingController controller,
    String label,
    String hint,
    Color textColor,
    Color mutedColor, {
    bool numeric = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(fontSize: 13, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 10, letterSpacing: 1, color: mutedColor),
        hintStyle: TextStyle(fontSize: 12, color: mutedColor),
        filled: true,
        fillColor: widget.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: mutedColor.withOpacity(0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: mutedColor.withOpacity(0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: textColor)),
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
              color: widget.isDark ? Colors.white38 : Colors.black26,
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
                    : (widget.isDark ? Colors.white60 : Colors.black87),
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
                        : (widget.isDark ? Colors.white60 : Colors.black87),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: widget.isDark ? Colors.white38 : Colors.black26,
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
        color: widget.isDark ? AppColors.getCardBgColor(widget.isDark) : Colors.white,
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
                                color: widget.isDark ? Colors.white38 : Colors.black12,
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
                        color: widget.isDark ? Colors.white60 : Colors.black54,
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
                  _buildInfoRow('ÉTAT', widget.status),
                  const SizedBox(height: 12),
                  _buildInfoRow('SURFACE', widget.area),
                ],
              ),
            ),
          ),

          // Mode lecture seule: afficher seulement le bouton ACTIVITÉS
          if (widget.readOnly)
            _buildActionButton(
              label: 'VOIR LES ACTIVITÉS',
              icon: Icons.timeline_outlined,
              onTap: () => widget.onNavigate(
                ActivityScreen(
                  farmId: widget.farmId,
                  cropId: widget.cropId,
                  userId: widget.userId,
                  farmOwnerId: widget.farmOwnerId,
                  readOnly: widget.readOnly,
                ),
              ),
            ),

          // Mode édition: afficher la section complète ACTIONS
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
                          color: widget.isDark ? Colors.white60 : Colors.black54,
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
                      label: 'MODIFIER',
                      icon: Icons.edit_outlined,
                      onTap: () => widget.onEdit(widget.cropId, widget.cropName),
                    ),
                    _buildActionButton(
                      label: 'ACTIVITÉS',
                      icon: Icons.timeline_outlined,
                      onTap: () => widget.onNavigate(
                        ActivityScreen(
                          farmId: widget.farmId,
                          cropId: widget.cropId,
                          userId: widget.userId,
                          farmOwnerId: widget.farmOwnerId,
                          readOnly: widget.readOnly,
                        ),
                      ),
                    ),
                    _buildActionButton(
                      label: 'VENDRE',
                      icon: Icons.point_of_sale_outlined,
                      onTap: _showSaleDialog,
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
                          cropId: widget.cropId,
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
                      label: 'TÉLÉCHARGER',
                      icon: Icons.download_outlined,
                      onTap: widget.onDownload,
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
            color: widget.isDark ? Colors.white60 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowAsync(String label, Future<String> valueFuture) {
    return FutureBuilder<String>(
      future: valueFuture,
      builder: (context, snapshot) {
        final value = snapshot.hasData ? snapshot.data! : '—';
        
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
                color: widget.isDark ? Colors.white60 : Colors.black87,
              ),
            ),
          ],
        );
      },
    );
  }
}