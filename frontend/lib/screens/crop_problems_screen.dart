import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class CropProblemsScreen extends StatefulWidget {
  final int farmId;
  final int cropId;
  final int userId;
  final String cropName;
  final bool isDarkMode;

  const CropProblemsScreen({
    Key? key,
    required this.farmId,
    required this.cropId,
    required this.userId,
    required this.cropName,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<CropProblemsScreen> createState() => _CropProblemsScreenState();
}

class _CropProblemsScreenState extends State<CropProblemsScreen> {
  late Future<List<dynamic>> _problemsFuture;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _problemsFuture = ApiService.getCropProblems(widget.cropId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.cropName} - Problèmes',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _problemsFuture = ApiService.getCropProblems(widget.cropId);
          });
        },
        child: FutureBuilder<List<dynamic>>(
          future: _problemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: const Color(0xFF6B8E23)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text('Erreur de chargement', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                  ],
                ),
              );
            }

            final problems = snapshot.data ?? [];

            if (problems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: const Color(0xFF6B8E23)),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun problème signalé',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre culture semble en bonne santé !',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: problems.length,
              itemBuilder: (context, index) {
                final problem = problems[index];
                return _buildProblemCard(problem);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showReportProblemDialog,
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
        foregroundColor: const Color(0xFF6B8E23),
        elevation: 1,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 24),
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        children: [
          // Header avec type et sévérité
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getProblemIcon(problemType),
                    color: _getSeverityColor(severity),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getProblemLabel(problemType),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(severity).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getSeverityLabel(severity),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _getSeverityColor(severity),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'il y a $daysAgo jour${daysAgo > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Photo si disponible
          if (photoUrl != null && photoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
            ),

          // Description
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photoUrl != null) const SizedBox(height: 8),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

          // Boutons d'action
          if (status != 'resolved')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _updateProblemStatus(problem['id'], 'treated'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B8E23),
                      ),
                      child: const Text('Traité'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _updateProblemStatus(problem['id'], 'resolved'),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF6B8E23),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Résolu'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showReportProblemDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => _ReportProblemForm(
        farmId: widget.farmId,
        cropId: widget.cropId,
        userId: widget.userId,
        isDarkMode: widget.isDarkMode,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour'),
          backgroundColor: const Color(0xFF6B8E23),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
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
        return Colors.green;
      case 'treated':
        return Colors.blue;
      case 'identified':
        return Colors.orange;
      default:
        return Colors.grey;
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

  IconData _getProblemIcon(String problemType) {
    switch (problemType) {
      case 'yellowing':
        return Icons.circle;
      case 'leaf_holes':
        return Icons.bug_report;
      case 'poor_yield':
        return Icons.trending_down;
      case 'rot':
        return Icons.cloud;
      case 'pest':
        return Icons.pest_control;
      case 'disease':
        return Icons.medical_services;
      default:
        return Icons.warning;
    }
  }

  String _getProblemLabel(String problemType) {
    const labels = {
      'yellowing': '🟡 Jaunissement',
      'leaf_holes': '🕳️ Feuilles trouées',
      'poor_yield': '📉 Mauvais rendement',
      'rot': '🌀 Pourriture',
      'pest': '🐛 Ravageurs',
      'disease': '🦠 Maladie',
      'wilting': '🥀 Flétrissement',
      'spotting': '⚫ Taches',
    };
    return labels[problemType] ?? problemType;
  }
}

class _ReportProblemForm extends StatefulWidget {
  final int farmId;
  final int cropId;
  final int userId;
  final bool isDarkMode;
  final Function() onSuccess;

  const _ReportProblemForm({
    required this.farmId,
    required this.cropId,
    required this.userId,
    required this.isDarkMode,
    required this.onSuccess,
  });

  @override
  State<_ReportProblemForm> createState() => __ReportProblemFormState();
}

class __ReportProblemFormState extends State<_ReportProblemForm> {
  String _selectedProblem = 'yellowing';
  String _selectedSeverity = 'medium';
  String _description = '';
  String? _photoUrl;
  bool _isLoading = false;

  final List<Map<String, String>> _problems = [
    {'value': 'yellowing', 'label': '🟡 Jaunissement des feuilles'},
    {'value': 'leaf_holes', 'label': '🕳️ Feuilles trouées'},
    {'value': 'poor_yield', 'label': '📉 Mauvais rendement'},
    {'value': 'rot', 'label': '🌀 Pourriture'},
    {'value': 'pest', 'label': '🐛 Ravageurs'},
    {'value': 'disease', 'label': '🦠 Maladie'},
    {'value': 'wilting', 'label': '🥀 Flétrissement'},
    {'value': 'spotting', 'label': '⚫ Taches sur feuilles'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signaler un problème',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Type de problème
              Text(
                'Type de problème',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedProblem,
                  underline: const SizedBox(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProblem = value);
                    }
                  },
                  items: _problems
                      .map((p) => DropdownMenuItem(
                            value: p['value'],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                p['label']!,
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Sévérité
              Text(
                'Sévérité',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final severity in ['low', 'medium', 'high'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(['Faible', 'Moyen', 'Élevé'][['low', 'medium', 'high'].indexOf(severity)]),
                          selected: _selectedSeverity == severity,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSeverity = severity);
                            }
                          },
                          backgroundColor: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                          selectedColor: const Color(0xFF6B8E23),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                onChanged: (value) => _description = value,
                autofocus: false,
                maxLines: 3,
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Décrivez le problème observé...',
                  hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black45),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton soumettre
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B8E23),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Signaler', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitReport() async {
    if (_description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez décrire le problème')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.reportCropProblem(
        cropId: widget.cropId,
        farmId: widget.farmId,
        userId: widget.userId,
        problemType: _selectedProblem,
        description: _description,
        severity: _selectedSeverity,
      );
      widget.onSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }
}
