import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/local_notification_service.dart';
import 'package:mbaymi/utils/app_colors.dart';

class ParcelRemindersScreen extends StatefulWidget {
  final int farmId;
  final int cropId;

  const ParcelRemindersScreen({super.key, required this.farmId, required this.cropId});

  @override
  State<ParcelRemindersScreen> createState() => _ParcelRemindersScreenState();
}

class _ParcelRemindersScreenState extends State<ParcelRemindersScreen> {
  late Future<List<dynamic>> _listFuture;

  @override
  void initState() {
    super.initState();
    _load();
    // Initialize local notifications
    LocalNotificationService.init();
  }

  void _load() {
    _listFuture = ApiService.listRemindersForFarm(widget.farmId);
  }

  String _getRepeatLabel(String repeat) {
    switch (repeat) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      default:
        return 'Une fois';
    }
  }

  IconData _getRepeatIcon(String repeat) {
    switch (repeat) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.date_range;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.event;
    }
  }

  Color _getStatusColor(Map<String, dynamic> reminder) {
    final remindAt = DateTime.tryParse(reminder['remind_at'] ?? '');
    if (remindAt == null) return Colors.grey;
    
    final now = DateTime.now();
    final diff = remindAt.difference(now);
    
    if (diff.isNegative) return Colors.red; // Passé
    if (diff.inHours < 24) return Colors.orange; // Moins de 24h
    return Colors.green; // Plus de 24h
  }

  String _getTimeRemaining(DateTime remindAt) {
    final now = DateTime.now();
    final diff = remindAt.difference(now);
    
    if (diff.isNegative) return 'Expiré';
    if (diff.inDays > 0) return 'Dans ${diff.inDays}j';
    if (diff.inHours > 0) return 'Dans ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Dans ${diff.inMinutes}min';
    return 'Maintenant';
  }

  Future<void> _showAddReminder() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime remindAt = DateTime.now().add(const Duration(days: 1));
    String repeatRule = 'none';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Nouveau rappel',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Titre',
                        hintText: 'Ex: Arroser les plants',
                        prefixIcon: const Icon(Icons.title_outlined),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Détails du rappel...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.description_outlined),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.access_time, color: Colors.blue[700], size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date et heure',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${remindAt.day}/${remindAt.month}/${remindAt.year} à ${remindAt.hour.toString().padLeft(2, '0')}:${remindAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: remindAt,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (date == null) return;
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(remindAt),
                              );
                              if (time == null) return;
                              setModalState(() {
                                remindAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                              });
                            },
                            icon: Icon(Icons.edit_calendar, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: repeatRule,
                        decoration: const InputDecoration(
                          labelText: 'Répétition',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('Aucune répétition')),
                          DropdownMenuItem(value: 'daily', child: Text('Quotidien')),
                          DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                        ],
                        onChanged: (v) => setModalState(() => repeatRule = v ?? 'none'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Le titre est requis'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }

                        final payload = {
                          'farm_id': widget.farmId,
                          'crop_id': widget.cropId,
                          'title': title,
                          'description': descCtrl.text.trim(),
                          'remind_at': remindAt.toIso8601String(),
                          'repeat_rule': repeatRule,
                        };

                        try {
                          final result = await ApiService.createReminder(payload);
                          Navigator.pop(context);
                          setState(() => _load());

                          // Schedule local notification
                          final int notifId = (result['id'] as int?) ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
                          await LocalNotificationService.scheduleNotification(
                            id: notifId,
                            title: title,
                            body: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Rappel agricole',
                            scheduledDate: remindAt,
                          );
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Créer le rappel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showEditReminder(Map<String, dynamic> reminder) async {
    final titleCtrl = TextEditingController(text: reminder['title'] ?? '');
    final descCtrl = TextEditingController(text: reminder['description'] ?? '');
    DateTime remindAt = DateTime.tryParse(reminder['remind_at'] ?? '') ?? DateTime.now();
    String repeatRule = reminder['repeat_rule'] ?? 'none';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Modifier le rappel',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Titre',
                        hintText: 'Ex: Arroser les plants',
                        prefixIcon: const Icon(Icons.title_outlined),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Détails supplémentaires',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.description_outlined),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: remindAt,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(remindAt),
                                  );
                                  if (time != null) {
                                    setModalState(() {
                                      remindAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                    });
                                  }
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date et heure',
                                    style: TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${remindAt.day}/${remindAt.month}/${remindAt.year} ${remindAt.hour.toString().padLeft(2, '0')}:${remindAt.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: repeatRule,
                      decoration: InputDecoration(
                        labelText: 'Répétition',
                        prefixIcon: const Icon(Icons.repeat_outlined),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('Aucune répétition')),
                        DropdownMenuItem(value: 'daily', child: Text('Quotidien')),
                        DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                      ],
                      onChanged: (v) => setModalState(() => repeatRule = v ?? 'none'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Le titre est requis'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }

                        final updates = {
                          'title': title,
                          'description': descCtrl.text.trim(),
                          'remind_at': remindAt.toIso8601String(),
                          'repeat_rule': repeatRule,
                        };

                        try {
                          await ApiService.updateReminder(reminder['id'], updates);
                          Navigator.pop(context);
                          setState(() => _load());
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Modifier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteReminder(int reminderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce rappel?'),
        content: const Text('Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteReminder(reminderId);
                Navigator.pop(context);
                setState(() => _load());
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Rappels', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _listFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucun rappel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre premier rappel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i] as Map<String, dynamic>;
              final remindAt = DateTime.tryParse(it['remind_at'] ?? '');
              final statusColor = _getStatusColor(it);
              final repeatRule = it['repeat_rule'] ?? 'none';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.notifications_active, color: statusColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it['title'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (it['description']?.toString().isNotEmpty ?? false) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        it['description'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule, size: 16, color: statusColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        remindAt != null ? _getTimeRemaining(remindAt) : '-',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 13,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getRepeatIcon(repeatRule), size: 16, color: Colors.grey[700]),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getRepeatLabel(repeatRule),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w300,
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (remindAt != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  '${remindAt.day}/${remindAt.month}/${remindAt.year} à ${remindAt.hour.toString().padLeft(2, '0')}:${remindAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _showEditReminder(it);
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Modifier'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue[700],
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                try {
                                  await ApiService.markReminderDone(it['id'] as int);
                                  setState(() => _load());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Rappel marqué comme terminé'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Terminé'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.green[700],
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: const Text('Supprimer le rappel ?'),
                                    content: const Text('Cette action est irréversible.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                                try {
                                  await ApiService.deleteReminder(it['id'] as int);
                                  setState(() => _load());
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Supprimer'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red[700],
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminder,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}