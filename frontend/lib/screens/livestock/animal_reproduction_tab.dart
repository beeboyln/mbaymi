/// Animal Reproduction Tab - Track breeding cycles, gestation, births
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/models/animal.dart';
import 'package:mbaymi/services/animal_service.dart';

class AnimalReproductionTab extends StatefulWidget {
  final int animalId;
  final String animalGender;

  const AnimalReproductionTab({
    Key? key,
    required this.animalId,
    required this.animalGender,
  }) : super(key: key);

  @override
  State<AnimalReproductionTab> createState() => _AnimalReproductionTabState();
}

class _AnimalReproductionTabState extends State<AnimalReproductionTab> {
  late Future<List<AnimalReproductionRecord>> _records;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _records = AnimalService.getReproductionRecords(widget.animalId);
    });
  }

  String _getEventTypeDisplay(String type) {
    switch (type) {
      case 'heat':
        return 'Chaleur';
      case 'mating':
        return 'Accouplement';
      case 'pregnancy':
        return 'Gestation';
      case 'birth':
        return 'Naissance';
      default:
        return type;
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'heat':
        return Colors.red;
      case 'mating':
        return Colors.pink;
      case 'pregnancy':
        return Colors.purple;
      case 'birth':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String type) {
    switch (type) {
      case 'heat':
        return Icons.favorite;
      case 'mating':
        return Icons.people;
      case 'pregnancy':
        return Icons.pregnant_woman;
      case 'birth':
        return Icons.child_friendly;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: FutureBuilder<List<AnimalReproductionRecord>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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

          final records = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info for female animals
              if (widget.animalGender == 'female')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suivi reproductif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        records.isEmpty
                            ? 'Aucun événement enregistré'
                            : _buildReproductiveStatus(records),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              if (widget.animalGender == 'female')
                const SizedBox(height: 16),

              // Add event button
              ElevatedButton.icon(
                onPressed: () => _showAddReproductionDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un événement'),
              ),
              const SizedBox(height: 16),

              // Reproduction events list
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Aucun événement de reproduction',
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
                    ...records
                        .asMap()
                        .entries
                        .map((entry) => _buildReproductionCard(
                              entry.value,
                              entry.key < records.length - 1 ? records[entry.key + 1] : null,
                            )),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  String _buildReproductiveStatus(List<AnimalReproductionRecord> records) {
    if (records.isEmpty) return 'Aucun événement';

    final lastEvent = records.first;

    switch (lastEvent.eventType) {
      case 'pregnancy':
        if (lastEvent.actualDeliveryDate == null) {
          if (lastEvent.expectedDeliveryDate != null) {
            final daysUntil =
                lastEvent.expectedDeliveryDate!.difference(DateTime.now()).inDays;
            return 'Enceinte - Livraison prévue: ${DateFormat('dd/MM/yyyy').format(lastEvent.expectedDeliveryDate!)} ($daysUntil jours)';
          }
          return 'Enceinte';
        }
        return 'Gestante';
      case 'heat':
        return 'En chaleur (${DateFormat('dd/MM/yyyy').format(lastEvent.eventDate)})';
      case 'mating':
        return 'Accouplée (${DateFormat('dd/MM/yyyy').format(lastEvent.eventDate)})';
      case 'birth':
        final offspring = lastEvent.numberOfOffspring ?? 0;
        return 'Dernière naissance: $offspring petit${offspring != 1 ? 's' : ''} (${DateFormat('dd/MM/yyyy').format(lastEvent.eventDate)})';
      default:
        return 'Suivi actif';
    }
  }

  Widget _buildReproductionCard(
    AnimalReproductionRecord record,
    AnimalReproductionRecord? nextRecord,
  ) {
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
                    color: _getEventTypeColor(record.eventType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getEventTypeIcon(record.eventType),
                    size: 16,
                    color: _getEventTypeColor(record.eventType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getEventTypeDisplay(record.eventType),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(record.eventDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Event details
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.partnerName != null ||
                      record.partnerAnimalId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Partenaire: ${record.partnerName ?? 'ID ${record.partnerAnimalId}'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  if (record.eventType == 'pregnancy') ...[
                    if (record.expectedDeliveryDate != null)
                      Text(
                        'Livraison attendue: ${DateFormat('dd/MM/yyyy').format(record.expectedDeliveryDate!)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (record.actualDeliveryDate != null)
                      Text(
                        'Livraison réelle: ${DateFormat('dd/MM/yyyy').format(record.actualDeliveryDate!)}',
                        style: const TextStyle(fontSize: 11, color: Colors.green),
                      ),
                  ],
                  if (record.eventType == 'birth') ...[
                    if (record.numberOfOffspring != null)
                      Text(
                        'Petits: ${record.numberOfOffspring}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (record.offspringGender != null)
                      Text(
                        'Sexe: ${record.offspringGender}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (record.offspringHealth != null)
                      Text(
                        'Santé: ${record.offspringHealth}',
                        style: const TextStyle(fontSize: 11),
                      ),
                  ],
                  if (record.notes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Notes: ${record.notes}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Timeline indicator if next event exists
            if (nextRecord != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Intervalle: ${record.eventDate.difference(nextRecord.eventDate).inDays.abs()} jours',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddReproductionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddReproductionDialog(
        animalId: widget.animalId,
        animalGender: widget.animalGender,
        onEventAdded: (_) {
          _loadData();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _AddReproductionDialog extends StatefulWidget {
  final int animalId;
  final String animalGender;
  final Function(AnimalReproductionRecord) onEventAdded;

  const _AddReproductionDialog({
    required this.animalId,
    required this.animalGender,
    required this.onEventAdded,
  });

  @override
  State<_AddReproductionDialog> createState() => _AddReproductionDialogState();
}

class _AddReproductionDialogState extends State<_AddReproductionDialog> {
  late String _selectedEventType;
  final _partnerNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _numberOfOffspringController = TextEditingController();
  DateTime? _selectedEventDate;
  DateTime? _selectedExpectedDeliveryDate;
  bool _isLoading = false;

  static const List<String> _eventTypes = [
    'heat',
    'mating',
    'pregnancy',
    'birth',
  ];

  @override
  void initState() {
    super.initState();
    _selectedEventDate = DateTime.now();
    _selectedEventType = widget.animalGender == 'female' ? 'heat' : 'mating';
  }

  @override
  void dispose() {
    _partnerNameController.dispose();
    _notesController.dispose();
    _numberOfOffspringController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    setState(() => _isLoading = true);

    try {
      await AnimalService.addReproductionRecord(
        widget.animalId,
        eventType: _selectedEventType,
        eventDate: _selectedEventDate!,
        partnerName: _partnerNameController.text.isEmpty
            ? null
            : _partnerNameController.text,
        expectedDeliveryDate: _selectedExpectedDeliveryDate,
        numberOfOffspring: _numberOfOffspringController.text.isEmpty
            ? null
            : int.parse(_numberOfOffspringController.text),
        notes:
            _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement créé')),
        );
        widget.onEventAdded(AnimalReproductionRecord(
          id: 0,
          animalId: widget.animalId,
          userId: 0,
          eventType: _selectedEventType,
          eventDate: _selectedEventDate!,
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
                'Ajouter un événement de reproduction',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedEventType,
                decoration: InputDecoration(
                  labelText: 'Type d\'événement',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedEventType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _selectedEventDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (selected != null) {
                    setState(() => _selectedEventDate = selected);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de l\'événement',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedEventDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedEventDate!)
                        : 'Sélectionner une date',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _partnerNameController,
                decoration: InputDecoration(
                  labelText: 'Nom du partenaire (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_selectedEventType == 'pregnancy')
                ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _selectedExpectedDeliveryDate ??
                            DateTime.now().add(const Duration(days: 90)),
                        firstDate: _selectedEventDate ?? DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                      );
                      if (selected != null) {
                        setState(() => _selectedExpectedDeliveryDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date de livraison attendue',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedExpectedDeliveryDate != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_selectedExpectedDeliveryDate!)
                            : 'Sélectionner une date',
                      ),
                    ),
                  ),
                ],
              if (_selectedEventType == 'birth')
                ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _numberOfOffspringController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nombre de petits',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
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
