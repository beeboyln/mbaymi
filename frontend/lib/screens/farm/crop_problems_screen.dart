import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';

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

class _CropProblemsScreenState extends State<CropProblemsScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _problemsFuture;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _problemsFuture = ApiService.getCropProblems(widget.cropId);
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // Palette couleurs Zara agricole minimaliste
  Color get _bgColor =>
      widget.isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFFAF8F5);
  Color get _cardColor =>
      widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _accentColor => const Color(0xFF5D7B3F); // Vert kaki luxe
  Color get _textColor =>
      widget.isDarkMode ? const Color(0xFFF5F3F0) : const Color(0xFF2A2A28);
  Color get _mutedColor =>
      widget.isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF8A8783);

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
              return _buildSkeletonLoader();
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
    );
  }

  // AppBar minimaliste
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.cropName,
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Suivi sanitaire',
            style: TextStyle(
              color: _mutedColor,
              fontWeight: FontWeight.w400,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      centerTitle: false,
      toolbarHeight: 70,
    );
  }

  // Skeleton loader élégant
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Shimmer.fromColors(
              baseColor: _cardColor,
              highlightColor: widget.isDarkMode
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF0F0F0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    margin: const EdgeInsets.all(16),
                    color: _mutedColor.withOpacity(0.2),
                  ),
                  Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: _mutedColor.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // État vide inspirant
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

  // État erreur
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

  // Liste des problèmes avec timeline
  Widget _buildProblemsList(List<dynamic> problems) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: problems.length,
      itemBuilder: (context, index) {
        final problem = problems[index];
        final isLast = index == problems.length - 1;

        return Column(
          children: [
            // Connecteur de timeline
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 8,
                  child: Center(
                    child: Container(
                      height: 1,
                      color: _accentColor.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
            _buildProblemCard(problem),
            if (!isLast) const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  // Carte problème raffinée
  Widget _buildProblemCard(dynamic problem) {
    final problemType = problem['problem_type'] as String? ?? 'unknown';
    final severity = problem['severity'] as String? ?? 'medium';
    final status = problem['status'] as String? ?? 'reported';
    final description = problem['description'] as String? ?? '';
    final photoUrl = problem['photo_url'] as String?;
    final createdAt = DateTime.parse(problem['created_at'] as String);
    final daysAgo = DateTime.now().difference(createdAt).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        children: [
          // En-tête avec indicateur temporel minimaliste
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Indicateur de sévérité (point)
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
                    // Badge de statut minimaliste
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

          // Photo si disponible
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

          // Description
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

          // Actions (si non résolu)
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
        ],
      ),
    );
  }

  // FAB raffiné
  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
      ),
      child: FloatingActionButton(
        onPressed: () {
          _fabController.reverse();
          _showReportProblemDialog();
        },
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  void _showReportProblemDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _ReportProblemForm(
        farmId: widget.farmId,
        cropId: widget.cropId,
        userId: widget.userId,
        isDarkMode: widget.isDarkMode,
        bgColor: _bgColor,
        accentColor: _accentColor,
        textColor: _textColor,
        mutedColor: _mutedColor,
        cardColor: _cardColor,
        onSuccess: () {
          setState(() {
            _problemsFuture = ApiService.getCropProblems(widget.cropId);
          });
          Navigator.pop(context);
        },
      ),
    );
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
        return const Color(0xFFD97757); // Terracotta
      case 'medium':
        return const Color(0xFFC4A570); // Doré
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

// Shimmer widget simple (remplacez par package shimmer_flutter si disponible)
class Shimmer extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;
  final Widget child;

  const Shimmer.fromColors({
    required this.baseColor,
    required this.highlightColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// Formulaire de signalement raffiné
class _ReportProblemForm extends StatefulWidget {
  final int farmId;
  final int cropId;
  final int userId;
  final bool isDarkMode;
  final Color bgColor;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Function() onSuccess;

  const _ReportProblemForm({
    required this.farmId,
    required this.cropId,
    required this.userId,
    required this.isDarkMode,
    required this.bgColor,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.onSuccess,
  });

  @override
  State<_ReportProblemForm> createState() => __ReportProblemFormState();
}

class __ReportProblemFormState extends State<_ReportProblemForm> {
  String _selectedProblem = 'yellowing';
  String _selectedSeverity = 'medium';
  String _description = '';
  bool _isLoading = false;
  int? _selectedInputId;
  String _financeType = 'expense';
  final _quantityCtrl = TextEditingController();
  final _financeCtrl = TextEditingController();
  late Future<List<dynamic>> _inputsFuture;

  @override
  void initState() {
    super.initState();
    _inputsFuture = ApiService.listInputsForCrop(widget.cropId);
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _financeCtrl.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée de drag
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: widget.mutedColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // En-tête
              Row(
                children: [
                  Container(
                    width: 2,
                    height: 24,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signaler un problème',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: widget.textColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aidez-nous à suivre la santé de votre culture',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.mutedColor,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Type de problème
              _buildFormSection(
                'Type de problème',
                _buildProblemDropdown(),
              ),
              const SizedBox(height: 20),

              // Sévérité
              _buildFormSection(
                'Sévérité',
                _buildSeverityChips(),
              ),
              const SizedBox(height: 20),

              // Description
              _buildFormSection(
                'Description',
                _buildDescriptionField(),
              ),
              const SizedBox(height: 24),

              FutureBuilder<List<dynamic>>(
                future: _inputsFuture,
                builder: (context, snapshot) {
                  final inputs = snapshot.data ?? [];
                  if (inputs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormSection('Médicament utilisé (optionnel)', DropdownButtonFormField<int?>(
                        value: _selectedInputId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Aucun médicament')),
                          ...inputs.map((item) => DropdownMenuItem<int?>(value: item['id'] as int, child: Text('${item['name'] ?? item['input_type']} (${item['quantity'] ?? 0} ${item['unit'] ?? ''})'))),
                        ],
                        onChanged: (value) => setState(() => _selectedInputId = value),
                      )),
                      if (_selectedInputId != null) ...[
                        const SizedBox(height: 12),
                        TextField(controller: _quantityCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantité utilisée')),
                      ],
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
              _buildFormSection('Dépense de traitement (optionnel)', Column(
                children: [
                  Row(children: [
                    Expanded(child: RadioListTile<String>(title: const Text('Dépense'), value: 'expense', groupValue: _financeType, onChanged: (v) => setState(() => _financeType = v!))),
                    Expanded(child: RadioListTile<String>(title: const Text('Revenu'), value: 'income', groupValue: _financeType, onChanged: (v) => setState(() => _financeType = v!))),
                  ]),
                  TextField(controller: _financeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Montant (FCFA)')),
                ],
              )),
              const SizedBox(height: 24),

              // Bouton soumettre
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Signaler',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.mutedColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildProblemDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        border: Border.all(
          color: widget.mutedColor.withOpacity(0.15),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedProblem,
        underline: const SizedBox(),
        icon: Icon(Icons.expand_more, color: widget.mutedColor, size: 20),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedProblem = value);
          }
        },
        items: _problems
            .map((p) => DropdownMenuItem(
                  value: p['value'],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      p['label']!,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 13,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSeverityChips() {
    return Row(
      children: [
        for (final (index, severity) in ['low', 'medium', 'high'].indexed)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index > 0 ? 6 : 0,
                right: index < 2 ? 6 : 0,
              ),
              child: ChoiceChip(
                showCheckmark: false,
                label: Text(
                  ['Faible', 'Moyen', 'Élevé'][index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                selected: _selectedSeverity == severity,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSeverity = severity);
                  }
                },
                backgroundColor: widget.cardColor,
                selectedColor: widget.accentColor,
                labelStyle: TextStyle(
                  color: _selectedSeverity == severity
                      ? Colors.white
                      : widget.textColor,
                ),
                side: BorderSide(
                  color: _selectedSeverity == severity
                      ? widget.accentColor
                      : widget.mutedColor.withOpacity(0.2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      onChanged: (value) => _description = value,
      autofocus: false,
      maxLines: 4,
      minLines: 3,
      textInputAction: TextInputAction.newline,
      style: TextStyle(
        color: widget.textColor,
        height: 1.5,
        fontSize: 13,
        letterSpacing: 0.1,
      ),
      decoration: InputDecoration(
        hintText: 'Décrivez le problème observé...',
        hintStyle: TextStyle(
          color: widget.mutedColor.withOpacity(0.6),
          fontSize: 13,
        ),
        filled: true,
        fillColor: widget.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.mutedColor.withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.accentColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  void _submitReport() async {
    if (_description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Décrivez le problème'),
          backgroundColor: const Color(0xFFD97757),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final quantity = double.tryParse(_quantityCtrl.text.replaceAll(',', '.'));
    final financeAmount = double.tryParse(_financeCtrl.text.replaceAll(',', '.'));
    if (_selectedInputId != null && (quantity == null || quantity <= 0)) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await ApiService.reportCropProblem(
        cropId: widget.cropId,
        farmId: widget.farmId,
        userId: widget.userId,
        problemType: _selectedProblem,
        description: _description.trim(),
        severity: _selectedSeverity,
        inputId: _selectedInputId,
        quantityUsed: quantity,
        financeType: financeAmount == null ? null : _financeType,
        financeAmount: financeAmount,
      );
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: const Color(0xFFD97757),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
