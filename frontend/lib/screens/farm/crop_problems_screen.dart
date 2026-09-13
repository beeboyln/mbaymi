import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/traceability_export_service.dart';

class CropProblemsScreen extends StatefulWidget {
  final int farmId;
  final int cropId;
  final int userId;
  final String cropName;
  final bool isDarkMode;

  const CropProblemsScreen({
    super.key,
    required this.farmId,
    required this.cropId,
    required this.userId,
    required this.cropName,
    this.isDarkMode = false,
  });

  @override
  State<CropProblemsScreen> createState() => _CropProblemsScreenState();
}

class _CropProblemsScreenState extends State<CropProblemsScreen> {
  late Future<List<dynamic>> _problemsFuture;

  @override
  void initState() {
    super.initState();
    _problemsFuture = ApiService.getCropProblems(widget.cropId);
  }

  // Tokens de design cohérents
  Color get _bgColor =>
      widget.isDarkMode ? const Color(0xFF111111) : const Color(0xFFF7F6F4);
  Color get _cardColor =>
      widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _accentColor => const Color(0xFF4A7C59);
  Color get _textColor =>
      widget.isDarkMode ? Colors.white : const Color(0xFF111111);
  Color get _mutedColor =>
      widget.isDarkMode ? Colors.white54 : const Color(0xFF888888);

  Future<void> _exportTraceability() {
    return TraceabilityExportService.showExportMenu(
      context: context,
      title: 'Traçabilité des maladies',
      loadSections: () async {
        final problems = await _problemsFuture;
        return [
          TraceabilitySection(
            title: 'Maladies et problèmes signalés',
            rows: problems
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList(),
          )
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _problemsFuture = ApiService.getCropProblems(widget.cropId);
          });
        },
        color: _accentColor,
        child: FutureBuilder<List<dynamic>>(
          future: _problemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF111111), strokeWidth: 1),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final problems = snapshot.data ?? [];

            if (problems.isEmpty) {
              return _buildEmptyState();
            }

            return _buildProblemsList(problems);
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _textColor, size: 20),
        onPressed: () => Navigator.pop(context),
        splashRadius: 24,
      ),
      title: Text('PROBLÈMES',
          style: TextStyle(
              fontSize: 11,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
              color: _textColor)),
      centerTitle: true,
      toolbarHeight: 56,
      actions: [
        IconButton(
          tooltip: 'Télécharger la traçabilité',
          icon: Icon(Icons.download_outlined, color: _textColor, size: 20),
          onPressed: _exportTraceability,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.eco_outlined,
                size: 32,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Culture en excellent état',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Aucun problème signalé. Continuez le suivi régulier de votre culture.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _mutedColor,
                  fontSize: 13,
                  height: 1.5,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: const Color(0xFFD97757),
          ),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger',
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vérifiez votre connexion',
            style: TextStyle(
              color: _mutedColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemsList(List<dynamic> problems) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: problems.length + 2,
      separatorBuilder: (_, index) => index == 0
          ? const SizedBox(height: 16)
          : Container(height: 1, color: _mutedColor.withOpacity(0.14)),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Text('SIGNALEMENTS',
              style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 3,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500));
        }
        if (index == problems.length + 1) return const SizedBox(height: 8);
        return _buildProblemCard(problems[index - 1]);
      },
    );
  }

  Widget _buildProblemCard(dynamic problem) {
    final problemType = problem['problem_type'] as String? ?? 'unknown';
    final severity = problem['severity'] as String? ?? 'medium';
    final status = problem['status'] as String? ?? 'reported';
    final description = problem['description'] as String? ?? '';
    final photoUrl = problem['photo_url'] as String?;
    final createdAt = DateTime.parse(problem['created_at'] as String);
    final daysAgo = DateTime.now().difference(createdAt).inDays;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border.all(color: _mutedColor.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getProblemLabel(problemType),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'il y a $daysAgo jour${daysAgo > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _mutedColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 12,
                      color: _mutedColor.withOpacity(0.2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getSeverityLabel(severity),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getSeverityColor(severity),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (photoUrl != null && photoUrl.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: _accentColor.withOpacity(0.05),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: _mutedColor,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _mutedColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: _textColor.withOpacity(0.8),
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          if (status != 'resolved') ...[
            Container(
              height: 1,
              color: _mutedColor.withOpacity(0.08),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          _updateProblemStatus(problem['id'], 'treated'),
                      style: TextButton.styleFrom(
                        foregroundColor: _accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Traité',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          _updateProblemStatus(problem['id'], 'resolved'),
                      style: TextButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Résolu',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            height: 1,
            color: _mutedColor.withOpacity(0.08),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _showEditProblemModal(problem),
                    style: TextButton.styleFrom(
                      foregroundColor: _accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Modifier',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => _confirmDeleteProblem(problem['id']),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD97757),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Supprimer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
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

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: _showReportProblemModal,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: _textColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('AJOUTER',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showReportProblemModal([Map<String, dynamic>? problem]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ReportProblemWizard(
        farmId: widget.farmId,
        cropId: widget.cropId,
        userId: widget.userId,
        isDarkMode: widget.isDarkMode,
        bgColor: _bgColor,
        accentColor: _accentColor,
        textColor: _textColor,
        mutedColor: _mutedColor,
        cardColor: _cardColor,
        existingProblem: problem,
        onSuccess: () {
          setState(() {
            _problemsFuture = ApiService.getCropProblems(widget.cropId);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditProblemModal(dynamic problem) {
    _showReportProblemModal(Map<String, dynamic>.from(problem as Map));
  }

  Future<void> _deleteProblem(int problemId) async {
    try {
      await ApiService.deleteCropProblem(problemId);
      setState(() {
        _problemsFuture = ApiService.getCropProblems(widget.cropId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Maladie supprimée'),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: const Color(0xFFD97757),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteProblem(int problemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la maladie ?'),
        content: const Text(
          'Cette action supprimera le signalement et son image associée dans le système.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD97757),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteProblem(problemId);
    }
  }

  void _updateProblemStatus(int problemId, String status) async {
    try {
      await ApiService.updateProblemStatus(
        problemId: problemId,
        status: status,
      );
      setState(() {
        _problemsFuture = ApiService.getCropProblems(widget.cropId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'resolved' ? 'Problème résolu' : 'Marqué comme traité',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: const Color(0xFFD97757),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFD97757);
      case 'medium':
        return const Color(0xFFC4A570);
      default:
        return _accentColor;
    }
  }

  String _getSeverityLabel(String severity) {
    const labels = {
      'low': 'Faible',
      'medium': 'Moyen',
      'high': 'Élevé',
    };
    return labels[severity] ?? severity;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return _accentColor;
      case 'treated':
        return const Color(0xFF4A90E2);
      case 'identified':
        return const Color(0xFFC4A570);
      default:
        return _mutedColor;
    }
  }

  String _getStatusLabel(String status) {
    const labels = {
      'reported': 'Signalé',
      'identified': 'Identifié',
      'treated': 'Traité',
      'resolved': 'Résolu',
    };
    return labels[status] ?? status;
  }

  String _getProblemLabel(String problemType) {
    const labels = {
      'yellowing': 'Jaunissement',
      'leaf_holes': 'Feuilles trouées',
      'poor_yield': 'Mauvais rendement',
      'rot': 'Pourriture',
      'pest': 'Ravageurs',
      'disease': 'Maladie',
      'wilting': 'Flétrissement',
      'spotting': 'Taches',
    };
    return labels[problemType] ?? problemType;
  }
}

// ============================================================================
// WIZARD MULTI-ÉTAPES
// ============================================================================

class _ReportProblemWizard extends StatefulWidget {
  final int farmId;
  final int cropId;
  final int userId;
  final bool isDarkMode;
  final Color bgColor;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Map<String, dynamic>? existingProblem;
  final Function() onSuccess;

  const _ReportProblemWizard({
    required this.farmId,
    required this.cropId,
    required this.userId,
    required this.isDarkMode,
    required this.bgColor,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    this.existingProblem,
    required this.onSuccess,
  });

  @override
  State<_ReportProblemWizard> createState() => __ReportProblemWizardState();
}

class __ReportProblemWizardState extends State<_ReportProblemWizard>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String _selectedProblem = 'yellowing';
  String _selectedSeverity = 'medium';
  String _description = '';
  final _descriptionCtrl = TextEditingController();
  bool _isLoading = false;
  XFile? _selectedProblemImage;
  String? _existingPhotoUrl;
  int? _selectedInputId;
  String _financeType = 'expense';
  final _quantityCtrl = TextEditingController();
  final _financeCtrl = TextEditingController();
  late Future<List<dynamic>> _inputsFuture;
  late AnimationController _animationCtrl;

  final List<Map<String, String>> _problems = [
    {'value': 'yellowing', 'label': 'Jaunissement des feuilles'},
    {'value': 'leaf_holes', 'label': 'Feuilles trouées'},
    {'value': 'poor_yield', 'label': 'Mauvais rendement'},
    {'value': 'rot', 'label': 'Pourriture'},
    {'value': 'pest', 'label': 'Ravageurs'},
    {'value': 'disease', 'label': 'Maladie'},
    {'value': 'wilting', 'label': 'Flétrissement'},
    {'value': 'spotting', 'label': 'Taches sur feuilles'},
  ];

  @override
  void initState() {
    super.initState();
    _inputsFuture = ApiService.listInputsForCrop(widget.cropId);
    if (widget.existingProblem != null) {
      final problem = widget.existingProblem!;
      _selectedProblem = problem['problem_type'] as String? ?? 'yellowing';
      _selectedSeverity = problem['severity'] as String? ?? 'medium';
      _description = problem['description'] as String? ?? '';
      _descriptionCtrl.text = _description;
      _existingPhotoUrl = problem['photo_url'] as String? ?? '';
    }
    _animationCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationCtrl.forward();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _quantityCtrl.dispose();
    _financeCtrl.dispose();
    _animationCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _description.trim().isEmpty) {
      _showErrorSnackBar('Décrivez le problème observé');
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _animationCtrl.reset();
      _animationCtrl.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _animationCtrl.reset();
      _animationCtrl.forward();
    }
  }

  void _submitReport() async {
    setState(() => _isLoading = true);

    final quantity = double.tryParse(_quantityCtrl.text.replaceAll(',', '.'));
    final financeAmount =
        double.tryParse(_financeCtrl.text.replaceAll(',', '.'));

    if (_selectedInputId != null && (quantity == null || quantity <= 0)) {
      _showErrorSnackBar('Quantité invalide');
      setState(() => _isLoading = false);
      return;
    }

    try {
      String? photoUrl = _existingPhotoUrl;
      if (_selectedProblemImage != null) {
        photoUrl = await ApiService.uploadImageToCloudinary(_selectedProblemImage!);
      }

      if (widget.existingProblem != null) {
        await ApiService.updateCropProblem(
          problemId: widget.existingProblem!['id'] as int,
          problemType: _selectedProblem,
          description: _description.trim(),
          photoUrl: photoUrl,
          severity: _selectedSeverity,
        );
      } else {
        await ApiService.reportCropProblem(
          cropId: widget.cropId,
          farmId: widget.farmId,
          userId: widget.userId,
          problemType: _selectedProblem,
          description: _description.trim(),
          photoUrl: photoUrl,
          severity: _selectedSeverity,
          inputId: _selectedInputId,
          quantityUsed: quantity,
          financeType: financeAmount == null ? null : _financeType,
          financeAmount: financeAmount,
        );
      }
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur : $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickProblemImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => _selectedProblemImage = picked);
    }
  }

  void _clearProblemImage() {
    setState(() {
      _selectedProblemImage = null;
      _existingPhotoUrl = null;
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFD97757),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationCtrl.value)),
          child: Opacity(
            opacity: _animationCtrl.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  children: [
                    _buildDragHandle(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressIndicator(),
                          const SizedBox(height: 48),
                          if (_currentStep == 0) _buildStep1(),
                          if (_currentStep == 1) _buildStep2(),
                          if (_currentStep == 2) _buildStep3(),
                          const SizedBox(height: 48),
                          _buildNavigationButtons(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: 40,
        height: 2.5,
        decoration: BoxDecoration(
          color: widget.mutedColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(1.25),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? widget.accentColor.withOpacity(0.7)
                        : widget.mutedColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _getStepTitle(_currentStep),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: widget.mutedColor.withOpacity(0.5),
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Décrivez le problème';
      case 1:
        return 'Sévérité';
      case 2:
        return 'Options supplémentaires';
      default:
        return '';
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel('Type de problème'),
        const SizedBox(height: 16),
        _buildProblemSelector(),
        const SizedBox(height: 40),
        _buildFormLabel('Observations'),
        const SizedBox(height: 16),
        _buildDescriptionField(),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel('Sévérité du problème'),
        const SizedBox(height: 16),
        _buildSeveritySelector(),
        const SizedBox(height: 48),
        _buildFormLabel('Photo liée à la maladie'),
        const SizedBox(height: 20),
        _buildPhotoPicker(),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options avancées',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: widget.textColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ces champs sont optionnels',
          style: TextStyle(
            fontSize: 12,
            color: widget.mutedColor.withOpacity(0.5),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 32),
        FutureBuilder<List<dynamic>>(
          future: _inputsFuture,
          builder: (context, snapshot) {
            final inputs = snapshot.data ?? [];
            if (inputs.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormLabel('Médicament utilisé'),
                const SizedBox(height: 16),
                _buildInputSelector(inputs),
                if (_selectedInputId != null) ...[
                  const SizedBox(height: 32),
                  _buildFormLabel('Quantité utilisée'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _quantityCtrl,
                    'Ex: 2.5',
                    'Quantité',
                  ),
                ],
                const SizedBox(height: 40),
              ],
            );
          },
        ),
        _buildFormLabel('Dépense de traitement'),
        const SizedBox(height: 16),
        _buildFinanceSection(),
      ],
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: widget.textColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProblemSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedProblem,
      isExpanded: true,
      decoration: InputDecoration(
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.accentColor.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
      icon: Icon(Icons.expand_more,
          color: widget.mutedColor.withOpacity(0.6), size: 18),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedProblem = value);
        }
      },
      items: _problems
          .map((p) => DropdownMenuItem(
                value: p['value'],
                child: Text(
                  p['label']!,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ))
          .toList(),
      dropdownColor: widget.cardColor,
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionCtrl,
      onChanged: (value) => _description = value,
      maxLines: 4,
      minLines: 3,
      style: TextStyle(
        color: widget.textColor,
        height: 1.7,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: 'Décrivez les symptômes observés...',
        hintStyle: TextStyle(
          color: widget.mutedColor.withOpacity(0.4),
          fontSize: 14,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.accentColor.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildSeveritySelector() {
    return Row(
      children: [
        for (final (index, severity) in ['low', 'medium', 'high'].indexed)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedSeverity = severity),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedSeverity == severity
                            ? widget.accentColor
                            : widget.mutedColor.withOpacity(0.15),
                        width: _selectedSeverity == severity ? 1.5 : 1,
                      ),
                    ),
                  ),
                  child: Text(
                    ['Faible', 'Moyen', 'Élevé'][index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedSeverity == severity
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: _selectedSeverity == severity
                          ? widget.accentColor
                          : widget.textColor.withOpacity(0.6),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
          bottom: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedProblemImage == null
                      ? (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                          ? 'Image actuelle sélectionnée'
                          : 'Aucune image sélectionnée')
                      : _selectedProblemImage!.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _selectedProblemImage == null &&
                            (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty)
                        ? widget.mutedColor.withOpacity(0.5)
                        : widget.textColor,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _pickProblemImage,
                icon: Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: widget.accentColor,
                ),
                label: Text(
                  _selectedProblemImage == null ? 'Choisir' : 'Changer',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedProblemImage != null || (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _selectedProblemImage != null
                  ? FutureBuilder<Uint8List>(
                      future: _selectedProblemImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            height: 180,
                            color: widget.mutedColor.withOpacity(0.08),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          );
                        }
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        }
                        return Container(
                          height: 180,
                          color: widget.mutedColor.withOpacity(0.08),
                          child: const Center(child: Icon(Icons.image_not_supported_outlined)),
                        );
                      },
                    )
                  : Image.network(
                      _existingPhotoUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearProblemImage,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD97757),
                ),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputSelector(List<dynamic> inputs) {
    return DropdownButtonFormField<int?>(
      value: _selectedInputId,
      isExpanded: true,
      decoration: InputDecoration(
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.accentColor.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
      icon: Icon(Icons.expand_more,
          color: widget.mutedColor.withOpacity(0.6), size: 18),
      onChanged: (value) => setState(() => _selectedInputId = value),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(
            'Aucun médicament',
            style: TextStyle(color: widget.textColor, fontSize: 14),
          ),
        ),
        ...inputs.map((item) => DropdownMenuItem<int?>(
              value: item['id'] as int,
              child: Text(
                '${item['name'] ?? item['input_type']} (${item['quantity'] ?? 0} ${item['unit'] ?? ''})',
                style: TextStyle(color: widget.textColor, fontSize: 14),
              ),
            )),
      ],
      dropdownColor: widget.cardColor,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
          color: widget.textColor, fontSize: 14, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: widget.mutedColor.withOpacity(0.4),
          fontSize: 14,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: widget.accentColor.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildFinanceSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _financeType = 'expense'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _financeType == 'expense'
                            ? widget.accentColor
                            : widget.mutedColor.withOpacity(0.15),
                        width: _financeType == 'expense' ? 1.5 : 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Dépense',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _financeType == 'expense'
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: _financeType == 'expense'
                          ? widget.accentColor
                          : widget.textColor.withOpacity(0.6),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _financeType = 'income'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _financeType == 'income'
                            ? widget.accentColor
                            : widget.mutedColor.withOpacity(0.15),
                        width: _financeType == 'income' ? 1.5 : 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Revenu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _financeType == 'income'
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: _financeType == 'income'
                          ? widget.accentColor
                          : widget.textColor.withOpacity(0.6),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextField(
          _financeCtrl,
          'Ex: 15000',
          'Montant (FCFA)',
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: TextButton(
              onPressed: _previousStep,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.textColor.withOpacity(0.6),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_currentStep < 2 ? _nextStep : _submitReport),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    _currentStep < 2 ? 'Continuer' : 'Signaler',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}