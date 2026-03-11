/// Animal Health Tab - Vaccination and medical records
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/models/animal.dart';
import 'package:mbaymi/services/animal_service.dart';

class AnimalHealthTab extends StatefulWidget {
  final int animalId;

  const AnimalHealthTab({
    super.key,
    required this.animalId,
  });

  @override
  State<AnimalHealthTab> createState() => _AnimalHealthTabState();
}

class _AnimalHealthTabState extends State<AnimalHealthTab> {
  late Future<List<AnimalHealthRecord>> _healthRecords;
  late Future<AnimalHealthSummary> _healthSummary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _healthRecords = AnimalService.getHealthRecords(widget.animalId);
      _healthSummary = AnimalService.getHealthSummary(widget.animalId);
    });
  }

  String _getRecordTypeDisplay(String type) {
    switch (type) {
      case 'vaccination':
        return 'Vaccination';
      case 'deworming':
        return 'Vermifugation';
      case 'treatment':
        return 'Traitement';
      case 'checkup':
        return 'Examen';
      case 'surgery':
        return 'Chirurgie';
      default:
        return type;
    }
  }

  Color _getRecordTypeColor(String type) {
    switch (type) {
      case 'vaccination':
        return Colors.green;
      case 'deworming':
        return Colors.orange;
      case 'treatment':
        return Colors.red;
      case 'checkup':
        return Colors.blue;
      case 'surgery':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: FutureBuilder<AnimalHealthSummary>(
        future: _healthSummary,
        builder: (context, summarySnapshot) {
          return FutureBuilder<List<AnimalHealthRecord>>(
            future: _healthRecords,
            builder: (context, recordsSnapshot) {
              if (summarySnapshot.connectionState == ConnectionState.waiting ||
                  recordsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (summarySnapshot.hasError || recordsSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Erreur lors du chargement des données'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              final summary = summarySnapshot.data;
              final records = recordsSnapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Health summary cards
                  if (summary != null) ...[
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      childAspectRatio: 2.5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildSummaryCard(
                          'Examen',
                          summary.lastCheckupDate != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(summary.lastCheckupDate!)
                              : 'Jamais',
                          Colors.blue,
                        ),
                        _buildSummaryCard(
                          'Total records',
                          '${summary.totalHealthRecords}',
                          Colors.green,
                        ),
                        _buildSummaryCard(
                          'Vaccinations',
                          '${summary.recentVaccinations}',
                          Colors.purple,
                        ),
                        _buildSummaryCard(
                          'Tâches en retard',
                          '${summary.overdueCareCount}',
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Add record button
                  ElevatedButton.icon(
                    onPressed: () => _showAddHealthRecordDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un dossier'),
                  ),
                  const SizedBox(height: 16),

                  // Health records list
                  if (records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Aucun dossier de santé',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historique',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...records.map((record) => _buildHealthCard(record)),
                      ],
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(AnimalHealthRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getRecordTypeColor(record.recordType)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getRecordTypeIcon(record.recordType),
                    size: 16,
                    color: _getRecordTypeColor(record.recordType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRecordTypeDisplay(record.recordType),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        record.medicalName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yy').format(record.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (record.description != null ||
                record.dosage != null ||
                record.cost != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record.dosage != null)
                      Text(
                        'Dosage: ${record.dosage}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (record.description != null)
                      Text(
                        'Notes: ${record.description}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (record.cost != null)
                      Text(
                        'Coût: ${record.cost?.toStringAsFixed(2)}€',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            if (record.nextDueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Prochain: ${DateFormat('dd/MM/yyyy').format(record.nextDueDate!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getRecordTypeIcon(String type) {
    switch (type) {
      case 'vaccination':
        return Icons.vaccines;
      case 'deworming':
        return Icons.bug_report;
      case 'treatment':
        return Icons.local_hospital;
      case 'checkup':
        return Icons.medical_services;
      case 'surgery':
        return Icons.health_and_safety;
      default:
        return Icons.info;
    }
  }

  void _showAddHealthRecordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddHealthRecordDialog(
        animalId: widget.animalId,
        onRecordAdded: (_) {
          _loadData();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _AddHealthRecordDialog extends StatefulWidget {
  final int animalId;
  final Function(AnimalHealthRecord) onRecordAdded;

  const _AddHealthRecordDialog({
    required this.animalId,
    required this.onRecordAdded,
  });

  @override
  State<_AddHealthRecordDialog> createState() => _AddHealthRecordDialogState();
}

class _AddHealthRecordDialogState extends State<_AddHealthRecordDialog> {
  final _typeController = TextEditingController();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _costController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  static const List<String> _recordTypes = [
    'vaccination',
    'deworming',
    'treatment',
    'checkup',
    'surgery',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _typeController.text = 'vaccination';
  }

  @override
  void dispose() {
    _typeController.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le nom du produit')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AnimalService.addHealthRecord(
        widget.animalId,
        recordType: _typeController.text,
        date: _selectedDate!,
        medicalName: _nameController.text,
        dosage: _dosageController.text.isEmpty ? null : _dosageController.text,
        cost: _costController.text.isEmpty ? null : double.parse(_costController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dossier créé avec succès')),
        );
        widget.onRecordAdded(AnimalHealthRecord(
          id: 0,
          animalId: widget.animalId,
          userId: 0,
          recordType: _typeController.text,
          date: _selectedDate!,
          medicalName: _nameController.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajouter un dossier de santé',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _typeController.text,
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _recordTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _typeController.text = value;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du produit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _costController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Coût (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ajouter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
