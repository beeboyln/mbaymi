/// Animal Reminders Tab - Care calendar and task management
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/models/animal.dart';
import 'package:mbaymi/services/animal_service.dart';

class AnimalRemindersTab extends StatefulWidget {
  final int animalId;

  const AnimalRemindersTab({
    super.key,
    required this.animalId,
  });

  @override
  State<AnimalRemindersTab> createState() => _AnimalRemindersTabState();
}

class _AnimalRemindersTabState extends State<AnimalRemindersTab> {
  late Future<List<AnimalCareReminder>> _reminders;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _reminders = AnimalService.getCareReminders(
        widget.animalId,
        isCompleted: _showCompleted ? null : false,
      );
    });
  }

  String _getPriorityDisplay(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Basse';
      case 'normal':
        return 'Normale';
      case 'high':
        return 'Haute';
      case 'critical':
        return 'Critique';
      default:
        return priority;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.grey;
      case 'normal':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTagDisplay(String? tag) {
    switch (tag) {
      case 'health':
        return '🏥 Santé';
      case 'reproduction':
        return '❤️ Reproduction';
      case 'maintenance':
        return '🔧 Maintenance';
      case 'nutrition':
        return '🍽️ Nutrition';
      default:
        return tag ?? 'Tâche';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: FutureBuilder<List<AnimalCareReminder>>(
        future: _reminders,
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

          final reminders = snapshot.data ?? [];
          final pending = reminders.where((r) => !r.isCompleted).toList();
          final completed = reminders.where((r) => r.isCompleted).toList();
          final overdue =
              pending.where((r) => r.daysUntilDue < 0).toList();
          final dueToday = pending.where((r) => r.isDueToday).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatusCard(
                    'En attente',
                    pending.length.toString(),
                    Colors.blue,
                  ),
                  _buildStatusCard(
                    'En retard',
                    overdue.length.toString(),
                    Colors.red,
                  ),
                  _buildStatusCard(
                    'Aujourd\'hui',
                    dueToday.length.toString(),
                    Colors.orange,
                  ),
                  _buildStatusCard(
                    'Terminés',
                    completed.length.toString(),
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Add reminder button
              ElevatedButton.icon(
                onPressed: () => _showAddReminderDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une tâche'),
              ),
              const SizedBox(height: 16),

              // Overdue reminders
              if (overdue.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ Tâches en retard',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...overdue
                          .map((reminder) => _buildReminderRow(reminder)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Today's reminders
              if (dueToday.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📅 Aujourd\'hui',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...dueToday
                          .map((reminder) => _buildReminderRow(reminder)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // All pending reminders
              if (pending.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tâches en attente',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _showCompleted = !_showCompleted);
                            _loadData();
                          },
                          child: Text(
                            _showCompleted
                                ? 'Masquer terminées'
                                : 'Montrer terminées',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pending.map((reminder) {
                      if (!overdue.contains(reminder) &&
                          !dueToday.contains(reminder)) {
                        return _buildReminderCard(reminder);
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Aucune tâche en attente',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

              // Completed reminders
              if (_showCompleted && completed.isNotEmpty) ...[
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terminées',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...completed.map((reminder) => _buildReminderCard(reminder)),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, Color color) {
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

  Widget _buildReminderRow(AnimalCareReminder reminder) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              reminder.title,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            DateFormat('dd/MM').format(reminder.dueDate),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(AnimalCareReminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!reminder.isCompleted)
                  GestureDetector(
                    onTap: () => _completeReminder(reminder.id),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _getPriorityColor(reminder.priority),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: reminder.isCompleted
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: _getPriorityColor(reminder.priority),
                            )
                          : null,
                    ),
                  )
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: reminder.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Row(
                        children: [
                          if (reminder.tag != null) ...[
                            Text(
                              _getTagDisplay(reminder.tag),
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            DateFormat('dd/MM/yyyy').format(reminder.dueDate),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(reminder.priority)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    _getPriorityDisplay(reminder.priority),
                    style: TextStyle(
                      fontSize: 9,
                      color: _getPriorityColor(reminder.priority),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (reminder.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  reminder.description!,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _completeReminder(int reminderId) async {
    try {
      await AnimalService.completeReminder(reminderId);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tâche marquée comme terminée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showAddReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddReminderDialog(
        animalId: widget.animalId,
        onReminderAdded: (_) {
          _loadData();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _AddReminderDialog extends StatefulWidget {
  final int animalId;
  final Function(AnimalCareReminder) onReminderAdded;

  const _AddReminderDialog({
    required this.animalId,
    required this.onReminderAdded,
  });

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedTag = 'health';
  String _selectedPriority = 'normal';
  bool _isRecurring = false;
  String? _recurrenceInterval;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  static const List<String> _tags = [
    'health',
    'reproduction',
    'maintenance',
    'nutrition',
  ];

  static const List<String> _priorities = [
    'low',
    'normal',
    'high',
    'critical',
  ];

  static const List<String> _intervals = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDueDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un titre')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AnimalService.createReminder(
        widget.animalId,
        title: _titleController.text,
        dueDate: _selectedDueDate!,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        tag: _selectedTag,
        priority: _selectedPriority,
        isRecurring: _isRecurring,
        recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tâche créée')),
        );
        widget.onReminderAdded(AnimalCareReminder(
          id: 0,
          animalId: widget.animalId,
          userId: 0,
          title: _titleController.text,
          dueDate: _selectedDueDate!,
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
                'Ajouter une tâche de soins',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Ex: Vaccination',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _selectedDueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selected != null) {
                    setState(() => _selectedDueDate = selected);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date limite',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDueDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!)
                        : 'Sélectionner une date',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedTag,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _tags.map((tag) {
                  return DropdownMenuItem(value: tag, child: Text(tag));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTag = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priorité',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPriority = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Tâche récurrente'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() => _isRecurring = value ?? false);
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              if (_isRecurring)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _recurrenceInterval,
                    decoration: InputDecoration(
                      labelText: 'Intervalle de récurrence',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _intervals.map((interval) {
                      return DropdownMenuItem(
                        value: interval,
                        child: Text(interval),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _recurrenceInterval = value);
                    },
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
                        : const Text('Créer'),
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
