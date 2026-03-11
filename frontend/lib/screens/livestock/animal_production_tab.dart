/// Animal Production Tab - Track milk, eggs, wool, meat
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/models/animal.dart';
import 'package:mbaymi/services/animal_service.dart';

class AnimalProductionTab extends StatefulWidget {
  final int animalId;
  final String animalSpecies;

  const AnimalProductionTab({
    super.key,
    required this.animalId,
    required this.animalSpecies,
  });

  @override
  State<AnimalProductionTab> createState() => _AnimalProductionTabState();
}

class _AnimalProductionTabState extends State<AnimalProductionTab> {
  late Future<List<AnimalProductionRecord>> _records;
  late Future<Map<String, dynamic>> _stats;
  String _selectedMetric = 'all';
  int _selectedPeriod = 30;

  List<String> _getAvailableMetrics(String species) {
    switch (species) {
      case 'cattle':
      case 'goat':
        return ['all', 'milk'];
      case 'poultry':
        return ['all', 'eggs'];
      case 'sheep':
        return ['all', 'wool', 'milk'];
      case 'pig':
      case 'sheep':
        return ['all', 'meat'];
      default:
        return ['all'];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _records = AnimalService.getProductionRecords(
        widget.animalId,
        metricType: _selectedMetric == 'all' ? null : _selectedMetric,
      );
      _stats = AnimalService.getProductionStats(
        widget.animalId,
        period: _selectedPeriod,
      );
    });
  }

  String _getMetricDisplay(String metric) {
    switch (metric) {
      case 'milk':
        return 'Lait';
      case 'eggs':
        return 'Œufs';
      case 'wool':
        return 'Laine';
      case 'meat':
        return 'Viande';
      default:
        return metric;
    }
  }

  String _getMetricIcon(String metric) {
    switch (metric) {
      case 'milk':
        return '🥛';
      case 'eggs':
        return '🥚';
      case 'wool':
        return '🧶';
      case 'meat':
        return '🥩';
      default:
        return '📊';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _stats,
        builder: (context, statsSnapshot) {
          return FutureBuilder<List<AnimalProductionRecord>>(
            future: _records,
            builder: (context, recordsSnapshot) {
              if (statsSnapshot.connectionState == ConnectionState.waiting ||
                  recordsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (statsSnapshot.hasError || recordsSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Erreur lors du chargement'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              final stats = statsSnapshot.data ?? {};
              final records = recordsSnapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedMetric,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedMetric = value);
                              _loadData();
                            }
                          },
                          items: _getAvailableMetrics(widget.animalSpecies)
                              .map((metric) {
                            final display = metric == 'all'
                                ? 'Tous les types'
                                : _getMetricDisplay(metric);
                            return DropdownMenuItem(
                              value: metric,
                              child: Text(display),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: _selectedPeriod,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPeriod = value);
                            _loadData();
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 30, child: Text('30 jours')),
                          DropdownMenuItem(value: 60, child: Text('60 jours')),
                          DropdownMenuItem(value: 90, child: Text('90 jours')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Statistics cards
                  if (stats.isNotEmpty)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      childAspectRatio: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          'Total',
                          (stats['total_quantity'] ?? 0).toString(),
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Moyenne/jour',
                          (stats['average_per_day'] ?? 0).toStringAsFixed(2),
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Meilleur jour',
                          (stats['best_day_quantity'] ?? 0).toString(),
                          Colors.purple,
                        ),
                        _buildStatCard(
                          'Pire jour',
                          (stats['worst_day_quantity'] ?? 0).toString(),
                          Colors.orange,
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Add record button
                  ElevatedButton.icon(
                    onPressed: () => _showAddProductionDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une production'),
                  ),
                  const SizedBox(height: 16),

                  // Production records list
                  if (records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Aucun enregistrement de production',
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
                        ...records.map((record) => _buildProductionCard(record)),
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

  Widget _buildStatCard(String label, String value, Color color) {
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

  Widget _buildProductionCard(AnimalProductionRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getMetricIcon(record.metricType),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getMetricDisplay(record.metricType),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${record.quantity} ${record.unit}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(record.date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (record.qualityGrade != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  record.qualityGrade!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddProductionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddProductionDialog(
        animalId: widget.animalId,
        availableMetrics: _getAvailableMetrics(widget.animalSpecies),
        onRecordAdded: (_) {
          _loadData();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _AddProductionDialog extends StatefulWidget {
  final int animalId;
  final List<String> availableMetrics;
  final Function(AnimalProductionRecord) onRecordAdded;

  const _AddProductionDialog({
    required this.animalId,
    required this.availableMetrics,
    required this.onRecordAdded,
  });

  @override
  State<_AddProductionDialog> createState() => _AddProductionDialogState();
}

class _AddProductionDialogState extends State<_AddProductionDialog> {
  late String _selectedMetric;
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    final metrics = widget.availableMetrics
        .where((m) => m != 'all')
        .toList();
    _selectedMetric = metrics.isNotEmpty ? metrics.first : 'milk';
    _setDefaultUnit();
  }

  void _setDefaultUnit() {
    switch (_selectedMetric) {
      case 'milk':
        _unitController.text = 'liters';
        break;
      case 'eggs':
        _unitController.text = 'number';
        break;
      case 'wool':
        _unitController.text = 'kg';
        break;
      case 'meat':
        _unitController.text = 'kg';
        break;
      default:
        _unitController.text = '';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer la quantité')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AnimalService.addProductionRecord(
        widget.animalId,
        date: _selectedDate!,
        metricType: _selectedMetric,
        quantity: double.parse(_quantityController.text),
        unit: _unitController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Production enregistrée')),
        );
        widget.onRecordAdded(AnimalProductionRecord(
          id: 0,
          animalId: widget.animalId,
          userId: 0,
          date: _selectedDate!,
          metricType: _selectedMetric,
          quantity: double.parse(_quantityController.text),
          unit: _unitController.text,
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
                'Enregistrer une production',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedMetric,
                decoration: InputDecoration(
                  labelText: 'Type de production',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: widget.availableMetrics
                    .where((m) => m != 'all')
                    .map((metric) {
                  return DropdownMenuItem(
                    value: metric,
                    child: Text(metric),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMetric = value;
                      _setDefaultUnit();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantité',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Unité',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
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
                        : const Text('Enregistrer'),
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
