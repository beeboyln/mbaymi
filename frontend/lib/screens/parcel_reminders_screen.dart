import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/local_notification_service.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:intl/intl.dart';

// ─── DESIGN TOKENS (identiques au ParcelFinanceScreen) ───────────────────────
class _Z {
  static const bg = Color(0xFFF7F6F4);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF888888);
  static const faint = Color(0xFFE8E6E1);
  static const cardBg = Color(0xFFFFFFFF);

  // Statuts rappels
  static const past = Color(0xFF9E3A3A);
  static const soon = Color(0xFF8B6914);
  static const ok = Color(0xFF4A7C59);

  static const pastBg = Color(0xFFF5EDED);
  static const soonBg = Color(0xFFF5F0E8);
  static const okBg = Color(0xFFEDF5F0);
}
// ─────────────────────────────────────────────────────────────────────────────

class ParcelRemindersScreen extends StatefulWidget {
  final int farmId;
  final int cropId;

  const ParcelRemindersScreen({super.key, required this.farmId, required this.cropId});

  @override
  State<ParcelRemindersScreen> createState() => _ParcelRemindersScreenState();
}

class _ParcelRemindersScreenState extends State<ParcelRemindersScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _listFuture;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
    _fadeCtrl.forward();
    LocalNotificationService.init();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _load() {
    _listFuture = ApiService.listRemindersForFarm(widget.farmId);
  }

  String _repeatLabel(String r) {
    switch (r) {
      case 'daily': return 'QUOTIDIEN';
      case 'weekly': return 'HEBDO';
      case 'monthly': return 'MENSUEL';
      default: return 'UNE FOIS';
    }
  }

  // Couleur & fond selon statut
  Color _statusColor(Map<String, dynamic> r) {
    final dt = DateTime.tryParse(r['remind_at'] ?? '');
    if (dt == null) return _Z.muted;
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return _Z.past;
    if (diff.inHours < 24) return _Z.soon;
    return _Z.ok;
  }

  Color _statusBg(Map<String, dynamic> r) {
    final dt = DateTime.tryParse(r['remind_at'] ?? '');
    if (dt == null) return _Z.faint;
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return _Z.pastBg;
    if (diff.inHours < 24) return _Z.soonBg;
    return _Z.okBg;
  }

  String _timeRemaining(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'EXPIRÉ';
    if (diff.inDays > 0) return 'DANS ${diff.inDays}J';
    if (diff.inHours > 0) return 'DANS ${diff.inHours}H';
    if (diff.inMinutes > 0) return 'DANS ${diff.inMinutes}MIN';
    return 'MAINTENANT';
  }

  String _formatDt(DateTime dt) =>
      DateFormat("d MMM yyyy · HH'h'mm", 'fr_FR').format(dt);

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppColors.createSnackBar(
        message: msg,
        isError: true,
      ),
    );
  }

  // ─── BOTTOM SHEET PARTAGÉ ─────────────────────────────────────────────────
  Widget _buildSheet({
    required BuildContext ctx,
    required String title,
    required String actionLabel,
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required DateTime remindAt,
    required String repeatRule,
    required void Function(DateTime) onDateChanged,
    required void Function(String) onRepeatChanged,
    required VoidCallback onSubmit,
  }) {
    return Container(
      decoration: const BoxDecoration(color: _Z.bg),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        top: 32,
        left: 28,
        right: 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(width: 32, height: 2, color: _Z.faint,
                  margin: const EdgeInsets.only(bottom: 32)),
            ),

            Text(title.toUpperCase(),
                style: const TextStyle(fontSize: 11, letterSpacing: 3,
                    fontWeight: FontWeight.w500, color: _Z.muted)),
            const SizedBox(height: 24),

            _ZField(controller: titleCtrl, label: 'TITRE', hint: 'Ex: Arroser les plants'),
            const SizedBox(height: 16),
            _ZField(controller: descCtrl, label: 'DESCRIPTION', hint: 'Détails…', maxLines: 3),
            const SizedBox(height: 24),

            // Date picker row
            const Text('DATE & HEURE',
                style: TextStyle(fontSize: 9, letterSpacing: 2.5,
                    color: _Z.muted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: ctx,
                  initialDate: remindAt,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: const ColorScheme.light(primary: _Z.ink),
                    ),
                    child: child!,
                  ),
                );
                if (date == null) return;
                final time = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(remindAt),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: const ColorScheme.light(primary: _Z.ink),
                    ),
                    child: child!,
                  ),
                );
                if (time == null) return;
                onDateChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _Z.cardBg,
                  border: Border.all(color: _Z.faint),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: _Z.muted),
                    const SizedBox(width: 12),
                    Text(
                      _formatDt(remindAt),
                      style: const TextStyle(fontSize: 14, color: _Z.ink, letterSpacing: 0.3),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 16, color: _Z.muted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Repeat selector
            const Text('RÉPÉTITION',
                style: TextStyle(fontSize: 9, letterSpacing: 2.5,
                    color: _Z.muted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: ['none', 'daily', 'weekly'].map((r) {
                final label = r == 'none' ? 'UNE FOIS' : r == 'daily' ? 'QUOTIDIEN' : 'HEBDO';
                final selected = repeatRule == r;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onRepeatChanged(r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: r != 'weekly' ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? _Z.ink : Colors.transparent,
                        border: Border.all(color: selected ? _Z.ink : _Z.faint),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : _Z.muted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            GestureDetector(
              onTap: onSubmit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                color: _Z.ink,
                child: Text(
                  actionLabel.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 11,
                    letterSpacing: 3, fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADD ─────────────────────────────────────────────────────────────────
  Future<void> _showAddReminder() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime remindAt = DateTime.now().add(const Duration(days: 1));
    String repeatRule = 'none';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildSheet(
          ctx: ctx,
          title: 'Nouveau rappel',
          actionLabel: 'Créer',
          titleCtrl: titleCtrl,
          descCtrl: descCtrl,
          remindAt: remindAt,
          repeatRule: repeatRule,
          onDateChanged: (d) => setS(() => remindAt = d),
          onRepeatChanged: (r) => setS(() => repeatRule = r),
          onSubmit: () async {
            final t = titleCtrl.text.trim();
            if (t.isEmpty) { _showError('Le titre est requis'); return; }
            try {
              final result = await ApiService.createReminder({
                'farm_id': widget.farmId,
                'crop_id': widget.cropId,
                'title': t,
                'description': descCtrl.text.trim(),
                'remind_at': remindAt.toIso8601String(),
                'repeat_rule': repeatRule,
              });
              Navigator.pop(ctx);
              setState(() => _load());
              final int notifId = (result['id'] as int?) ??
                  DateTime.now().millisecondsSinceEpoch.remainder(100000);
              await LocalNotificationService.scheduleNotification(
                id: notifId,
                title: t,
                body: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Rappel agricole',
                scheduledDate: remindAt,
              );
            } catch (e) {
              Navigator.pop(ctx);
              _showError(e.toString());
            }
          },
        ),
      ),
    );
  }

  // ─── EDIT ────────────────────────────────────────────────────────────────
  Future<void> _showEditReminder(Map<String, dynamic> r) async {
    final titleCtrl = TextEditingController(text: r['title'] ?? '');
    final descCtrl = TextEditingController(text: r['description'] ?? '');
    DateTime remindAt = DateTime.tryParse(r['remind_at'] ?? '') ?? DateTime.now();
    String repeatRule = r['repeat_rule'] ?? 'none';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildSheet(
          ctx: ctx,
          title: 'Modifier le rappel',
          actionLabel: 'Enregistrer',
          titleCtrl: titleCtrl,
          descCtrl: descCtrl,
          remindAt: remindAt,
          repeatRule: repeatRule,
          onDateChanged: (d) => setS(() => remindAt = d),
          onRepeatChanged: (v) => setS(() => repeatRule = v),
          onSubmit: () async {
            final t = titleCtrl.text.trim();
            if (t.isEmpty) { _showError('Le titre est requis'); return; }
            try {
              await ApiService.updateReminder(r['id'], {
                'title': t,
                'description': descCtrl.text.trim(),
                'remind_at': remindAt.toIso8601String(),
                'repeat_rule': repeatRule,
              });
              Navigator.pop(ctx);
              setState(() => _load());
            } catch (e) {
              Navigator.pop(ctx);
              _showError(e.toString());
            }
          },
        ),
      ),
    );
  }

  // ─── DELETE ──────────────────────────────────────────────────────────────
  Future<void> _deleteReminder(int id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Z.bg,
        shape: const RoundedRectangleBorder(),
        title: const Text('SUPPRIMER',
            style: TextStyle(fontSize: 11, letterSpacing: 3,
                fontWeight: FontWeight.w500, color: _Z.ink)),
        content: const Text('Cette action est irréversible.',
            style: TextStyle(color: _Z.muted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER',
                style: TextStyle(fontSize: 10, letterSpacing: 2, color: _Z.muted)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteReminder(id);
                Navigator.pop(context);
                setState(() => _load());
              } catch (e) {
                Navigator.pop(context);
                _showError(e.toString());
              }
            },
            child: const Text('SUPPRIMER',
                style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Z.bg,
      appBar: AppBar(
        backgroundColor: _Z.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: _Z.ink),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('RAPPELS',
            style: TextStyle(fontSize: 11, letterSpacing: 4,
                fontWeight: FontWeight.w500, color: _Z.ink)),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: FutureBuilder<List<dynamic>>(
          future: _listFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _Z.ink, strokeWidth: 1));
            }

            final items = snap.data ?? [];

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(border: Border.all(color: _Z.faint)),
                      child: const Icon(Icons.notifications_none_outlined,
                          size: 28, color: _Z.muted),
                    ),
                    const SizedBox(height: 20),
                    const Text('AUCUN RAPPEL',
                        style: TextStyle(fontSize: 9, letterSpacing: 3, color: _Z.muted)),
                    const SizedBox(height: 8),
                    const Text('Créez votre premier rappel',
                        style: TextStyle(fontSize: 13, color: _Z.muted)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: _Z.ink,
              backgroundColor: _Z.bg,
              onRefresh: () async => setState(() => _load()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                children: [
                  const Text('PROGRAMMÉS',
                      style: TextStyle(fontSize: 9, letterSpacing: 3,
                          color: _Z.muted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Container(height: 1, color: _Z.faint),
                  const SizedBox(height: 16),

                  ...items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final it = entry.value as Map<String, dynamic>;
                    final dt = DateTime.tryParse(it['remind_at'] ?? '');
                    final color = _statusColor(it);
                    final bgColor = _statusBg(it);
                    final repeat = it['repeat_rule'] ?? 'none';
                    final isLast = i == items.length - 1;

                    return Column(
                      children: [
                        _ReminderRow(
                          item: it,
                          dt: dt,
                          color: color,
                          bgColor: bgColor,
                          repeatLabel: _repeatLabel(repeat),
                          timeRemaining: dt != null ? _timeRemaining(dt) : '–',
                          formattedDate: dt != null ? _formatDt(dt) : '–',
                          onEdit: () => _showEditReminder(it),
                          onDone: () async {
                            try {
                              await ApiService.markReminderDone(it['id'] as int);
                              setState(() => _load());
                            } catch (e) {
                              _showError(e.toString());
                            }
                          },
                          onDelete: () => _deleteReminder(it['id'] as int),
                        ),
                        if (!isLast) Container(height: 1, color: _Z.faint),
                      ],
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _showAddReminder,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          color: _Z.ink,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('AJOUTER',
                  style: TextStyle(color: Colors.white, fontSize: 10,
                      letterSpacing: 3, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── REMINDER ROW ─────────────────────────────────────────────────────────────
class _ReminderRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final DateTime? dt;
  final Color color;
  final Color bgColor;
  final String repeatLabel;
  final String timeRemaining;
  final String formattedDate;
  final VoidCallback onEdit;
  final VoidCallback onDone;
  final VoidCallback onDelete;

  const _ReminderRow({
    required this.item,
    required this.dt,
    required this.color,
    required this.bgColor,
    required this.repeatLabel,
    required this.timeRemaining,
    required this.formattedDate,
    required this.onEdit,
    required this.onDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar
          Container(width: 2, height: 72, color: color),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + time badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        (item['title'] ?? '-').toString().toUpperCase(),
                        style: const TextStyle(fontSize: 13, letterSpacing: 1.5,
                            fontWeight: FontWeight.w500, color: _Z.ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: color.withOpacity(0.1),
                      child: Text(
                        timeRemaining,
                        style: TextStyle(fontSize: 9, letterSpacing: 1.5,
                            fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ],
                ),

                // Description
                if ((item['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item['description'].toString(),
                    style: const TextStyle(fontSize: 12, color: _Z.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Meta row
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 11, color: _Z.muted),
                    const SizedBox(width: 4),
                    Text(formattedDate,
                        style: const TextStyle(fontSize: 11, color: _Z.muted, letterSpacing: 0.2)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(border: Border.all(color: _Z.faint)),
                      child: Text(repeatLabel,
                          style: const TextStyle(fontSize: 8, letterSpacing: 1.5,
                              color: _Z.muted, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    _MiniAction(label: 'MODIFIER', onTap: onEdit),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: _Z.faint),
                    const SizedBox(width: 8),
                    _MiniAction(label: 'TERMINÉ', onTap: onDone, color: _Z.ok),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: _Z.faint),
                    const SizedBox(width: 8),
                    _MiniAction(label: 'SUPPRIMER', onTap: onDelete, color: _Z.past),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MiniAction({
    required this.label,
    required this.onTap,
    this.color = _Z.muted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ─── SHARED FIELD ─────────────────────────────────────────────────────────────
class _ZField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool numeric;

  const _ZField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 9, letterSpacing: 2.5,
                color: _Z.muted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14, color: _Z.ink, letterSpacing: 0.3),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _Z.muted, fontSize: 14),
            filled: true,
            fillColor: _Z.cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: _Z.faint),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: _Z.ink, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}