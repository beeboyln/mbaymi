import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/services/traceability_export_service.dart';

// ─── ZARA-STYLE DESIGN TOKENS ───────────────────────────────────────────────
class _Z {
  static const bg = Color(0xFFF8F8F7);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF767676);
  static const faint = Color(0xFFE2E0D8);
  static const expenseAccent = Color(0xFFD9534F);
  static const incomeAccent = Color(0xFF2E7D32);
  static const inputAccent = Color(0xFFB7791F);
  static const cardBg = Color(0xFFFFFFFF);
}
// ────────────────────────────────────────────────────────────────────────────

class ParcelFinanceScreen extends StatefulWidget {
  final int farmId;
  final int cropId;
  const ParcelFinanceScreen(
      {super.key, required this.farmId, required this.cropId});

  @override
  State<ParcelFinanceScreen> createState() => _ParcelFinanceScreenState();
}

class _ParcelFinanceScreenState extends State<ParcelFinanceScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _listFuture;
  late Future<Map<String, dynamic>> _summaryFuture;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Future<List<dynamic>> _activitiesFuture;
  late Future<List<Map<String, dynamic>>> _profitabilityFuture;
  late Future<List<Map<String, dynamic>>> _displayTransactionsFuture;
  String _searchQuery = '';
  String _selectedType = 'Tous';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _load() {
    _listFuture = ApiService.listTransactionsForCrop(widget.cropId);
    _summaryFuture = ApiService.getFinanceSummaryForCrop(widget.cropId);
    _activitiesFuture = ApiService.getActivitiesForCrop(widget.cropId);
    _profitabilityFuture = _loadProfitability();
    _displayTransactionsFuture = _loadDisplayTransactions();
  }

  Future<List<Map<String, dynamic>>> _loadDisplayTransactions() async {
    final results =
        await Future.wait<dynamic>([_listFuture, _activitiesFuture]);
    final activities = <int, Map<String, dynamic>>{};
    for (final rawActivity in results[1] as List) {
      if (rawActivity is! Map || rawActivity['id'] is! num) continue;
      final activity = Map<String, dynamic>.from(rawActivity);
      activities[(activity['id'] as num).toInt()] = activity;
    }

    return (results[0] as List).whereType<Map>().map((rawTransaction) {
      final transaction = Map<String, dynamic>.from(rawTransaction);
      final activityId = (transaction['activity_id'] as num?)?.toInt();
      final activity = activityId == null ? null : activities[activityId];
      transaction['activity_name'] = activity == null
          ? null
          : (activity['activity_type'] ?? 'Activité').toString();
      return transaction;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _loadProfitability() async {
    final results =
        await Future.wait<dynamic>([_listFuture, _activitiesFuture]);
    final transactions = (results[0] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final activities = (results[1] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final groups = <int?, Map<String, dynamic>>{};
    for (final activity in activities) {
      final activityId = activity['id'] as int?;
      if (activityId == null) continue;
      groups[activityId] = {
        'name': (activity['activity_type'] ?? 'Activité').toString(),
        'activity': activity,
        'transactions': <Map<String, dynamic>>[],
        'expenses': 0.0,
        'income': 0.0,
      };
    }
    for (final transaction in transactions) {
      final activityId = transaction['activity_id'] as int?;
      final group = groups.putIfAbsent(
          activityId,
          () => {
                'name': activityId == null ? 'Dépenses générales' : 'Activité',
                'transactions': <Map<String, dynamic>>[],
                'expenses': 0.0,
                'income': 0.0,
              });
      group['transactions'] = [
        ...(group['transactions'] as List<Map<String, dynamic>>),
        transaction,
      ];
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      if (transaction['transaction_type'] == 'income') {
        group['income'] = (group['income'] as double) + amount;
      } else {
        group['expenses'] = (group['expenses'] as double) + amount;
      }
    }
    return groups.values
        .map((group) => {
              ...group,
              'net':
                  (group['income'] as double) - (group['expenses'] as double),
            })
        .toList();
  }

  Widget _buildProfitabilityGroup(Map<String, dynamic> group) {
    final net = group['net'] as double;
    final positive = net >= 0;
    final activity = group['activity'] as Map<String, dynamic>?;
    final photos = (activity?['image_urls'] as List?)
            ?.whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        const <String>[];
    final date = activity?['activity_date']?.toString();
    final notes = activity?['notes']?.toString().trim() ?? '';
    final quantity = activity?['quantity_used'];
    final inputId = activity?['input_id'];
    final transactions =
        (group['transactions'] as List<Map<String, dynamic>>?) ??
            const <Map<String, dynamic>>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _Z.cardBg,
        border: Border.all(color: _Z.faint),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: photos.isEmpty
            ? Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _Z.bg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.agriculture_outlined,
                    size: 20, color: _Z.muted),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.network(
                  photos.first,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _Z.bg,
                    width: 42,
                    height: 42,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 18, color: _Z.muted),
                  ),
                ),
              ),
        title: Text(
          (group['name'] ?? 'Activité').toString().toUpperCase(),
          style: const TextStyle(
              fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${positive ? '+' : '−'}${_formatAmount(net.abs())} FCFA',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: positive ? _Z.incomeAccent : _Z.expenseAccent),
        ),
        trailing: Text(
          'Dép. ${_formatAmount(group['expenses'])}\nRev. ${_formatAmount(group['income'])}',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 9, height: 1.5, color: _Z.muted),
        ),
        children: [
          if (activity != null) ...[
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 14, color: _Z.muted),
                const SizedBox(width: 6),
                Text(_formatDate(date),
                    style: const TextStyle(fontSize: 11, color: _Z.muted)),
                if (inputId != null) ...[
                  const SizedBox(width: 14),
                  const Icon(Icons.inventory_2_outlined,
                      size: 14, color: _Z.inputAccent),
                  const SizedBox(width: 4),
                  Text(
                    quantity == null
                        ? 'Intrant utilisé'
                        : 'Intrant · $quantity',
                    style: const TextStyle(fontSize: 11, color: _Z.inputAccent),
                  ),
                ],
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(notes,
                  style: const TextStyle(
                      fontSize: 11,
                      color: _Z.muted,
                      fontStyle: FontStyle.italic)),
            ],
            if (photos.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      photos[index],
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 58,
                        height: 58,
                        color: _Z.bg,
                        child: const Icon(Icons.broken_image_outlined,
                            size: 16, color: _Z.muted),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            _buildTransactionsSection(transactions),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddTransaction(
                    initialActivityId: activity['id'] as int?),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('AJOUTER UNE FINANCE À CETTE ACTIVITÉ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Z.ink,
                  side: const BorderSide(color: _Z.faint),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  textStyle: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            const Text('Transaction générale, sans activité associée.',
                style: TextStyle(fontSize: 11, color: _Z.muted)),
            _buildTransactionsSection(transactions),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Aucune finance détaillée pour le moment.',
              style: TextStyle(fontSize: 11, color: _Z.muted)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FINANCES ASSOCIÉES',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      color: _Z.muted,
                      fontWeight: FontWeight.bold)),
              Text(
                  '${transactions.length} opération${transactions.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 9, color: _Z.muted)),
            ],
          ),
          const SizedBox(height: 8),
          ...transactions.map(_buildActivityTransaction),
        ],
      ),
    );
  }

  Widget _buildActivityTransaction(Map<String, dynamic> transaction) {
    final isIncome = transaction['transaction_type'] == 'income';
    final color = isIncome ? _Z.incomeAccent : _Z.expenseAccent;
    final category = transaction['category']?.toString().trim() ?? '';
    final notes = transaction['notes']?.toString().trim() ?? '';
    final date = transaction['transaction_date']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
      decoration: BoxDecoration(
        color: _Z.bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _Z.faint),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isIncome ? Icons.south_west : Icons.north_east,
                        size: 13, color: color),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        category.isEmpty ? 'Sans catégorie' : category,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _Z.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                        '${isIncome ? '+' : '−'}${_formatAmount(transaction['amount'])} FCFA',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(_formatDate(date),
                    style: const TextStyle(fontSize: 9, color: _Z.muted)),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10,
                          color: _Z.muted,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert, size: 18, color: _Z.muted),
            onSelected: (action) {
              if (action == 'edit') {
                _showEditTransaction(transaction);
              } else if (action == 'delete') {
                _deleteTransaction(transaction['id'] as int);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return '';
    try {
      return DateFormat('d MMM yyyy · HH:mm', 'fr_FR')
          .format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  String _formatAmount(dynamic v) {
    if (v == null) return '0';
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    return NumberFormat('#,##0', 'fr_FR').format(n);
  }

  Future<void> _exportTraceability() {
    return TraceabilityExportService.showExportMenu(
      context: context,
      title: 'Traçabilité financière',
      loadSections: () async {
        final transactions = await _listFuture;
        final summary = await _summaryFuture;
        return [
          TraceabilitySection(title: 'Résumé financier', rows: [summary]),
          TraceabilitySection(
            title: 'Transactions de la parcelle',
            rows: transactions
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList(),
          ),
        ];
      },
    );
  }

  // ─── BOTTOM SHEET TRANSACTIONS ───────────────────────────────────────────
  Widget _buildBottomSheet({
    required BuildContext ctx,
    required String title,
    required String actionLabel,
    required String type,
    required TextEditingController categoryCtrl,
    required TextEditingController amountCtrl,
    required TextEditingController notesCtrl,
    required List<dynamic> activities,
    required int? activityId,
    required void Function(int?) onActivityChanged,
    required void Function(String) onTypeChanged,
    required VoidCallback onSubmit,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: _Z.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        top: 20,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _Z.faint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: _Z.ink,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: ['expense', 'income'].map((t) {
              final selected = type == t;
              final label = t == 'expense' ? 'DÉPENSE' : 'REVENU';
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTypeChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: t == 'expense' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? _Z.ink : Colors.transparent,
                      border: Border.all(color: selected ? _Z.ink : _Z.faint),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : _Z.muted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _ZField(
              controller: categoryCtrl,
              label: 'CATÉGORIE',
              hint: "Main-d'œuvre, semences…"),
          const SizedBox(height: 14),
          if (activities.isNotEmpty) ...[
            _buildActivitySelector(
              ctx: ctx,
              activities: activities,
              activityId: activityId,
              onChanged: onActivityChanged,
            ),
            const SizedBox(height: 14),
          ],
          _ZField(
              controller: amountCtrl,
              label: 'MONTANT (FCFA)',
              hint: '0',
              numeric: true),
          const SizedBox(height: 14),
          _ZField(
              controller: notesCtrl,
              label: 'NOTES',
              hint: 'Détails…',
              maxLines: 2),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _Z.ink,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                actionLabel.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySelector({
    required BuildContext ctx,
    required List<dynamic> activities,
    required int? activityId,
    required void Function(int?) onChanged,
  }) {
    Map<String, dynamic>? selected;
    for (final raw in activities) {
      if (raw is Map && raw['id'] == activityId) {
        selected = Map<String, dynamic>.from(raw);
        break;
      }
    }
    final selectedPhotos = (selected?['image_urls'] as List?)
            ?.whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        const <String>[];

    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet<void>(
          context: ctx,
          backgroundColor: _Z.bg,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (choiceContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: _Z.faint,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('LIER LA FINANCE À UNE ACTIVITÉ',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.bold,
                          color: _Z.ink)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: const CircleAvatar(
                      backgroundColor: _Z.faint,
                      child: Icon(Icons.all_inclusive, color: _Z.ink, size: 18),
                    ),
                    title: const Text('Dépense générale',
                        style: TextStyle(fontSize: 12, color: _Z.ink)),
                    subtitle: const Text('Sans activité associée',
                        style: TextStyle(fontSize: 10, color: _Z.muted)),
                    trailing: activityId == null
                        ? const Icon(Icons.check, color: _Z.incomeAccent)
                        : null,
                    onTap: () {
                      onChanged(null);
                      Navigator.pop(choiceContext);
                    },
                  ),
                  const Divider(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: activities.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 64),
                      itemBuilder: (_, index) {
                        final activity =
                            Map<String, dynamic>.from(activities[index] as Map);
                        final photos = (activity['image_urls'] as List?)
                                ?.whereType<String>()
                                .where((url) => url.isNotEmpty)
                                .toList() ??
                            const <String>[];
                        final id = activity['id'] as int?;
                        final activityNotes =
                            activity['notes']?.toString().trim() ?? '';
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading: _buildActivityThumbnail(photos, size: 46),
                          title: Text(
                              (activity['activity_type'] ?? 'Activité')
                                  .toString()
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${_formatDate(activity['activity_date']?.toString())}${activityNotes.isEmpty ? '' : ' · $activityNotes'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 10, color: _Z.muted),
                          ),
                          trailing: id == activityId
                              ? const Icon(Icons.check, color: _Z.incomeAccent)
                              : null,
                          onTap: () {
                            onChanged(id);
                            Navigator.pop(choiceContext);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _Z.cardBg,
          border: Border.all(color: _Z.faint),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            selected == null
                ? const CircleAvatar(
                    radius: 18,
                    backgroundColor: _Z.faint,
                    child: Icon(Icons.all_inclusive, color: _Z.ink, size: 16),
                  )
                : _buildActivityThumbnail(selectedPhotos, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: selected == null
                  ? const Text('DÉPENSE GÉNÉRALE',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: _Z.ink))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ACTIVITÉ LIÉE',
                            style: TextStyle(
                                fontSize: 8,
                                letterSpacing: 1.4,
                                color: _Z.muted,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(
                            (selected['activity_type'] ?? 'Activité')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _Z.ink)),
                        Text(_formatDate(selected['activity_date']?.toString()),
                            style:
                                const TextStyle(fontSize: 10, color: _Z.muted)),
                      ],
                    ),
            ),
            const Icon(Icons.unfold_more, size: 18, color: _Z.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityThumbnail(List<String> photos, {double size = 42}) {
    if (photos.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: _Z.faint, borderRadius: BorderRadius.circular(5)),
        child: Icon(Icons.agriculture_outlined,
            size: size * 0.45, color: _Z.muted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.network(
        photos.first,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: _Z.faint,
          child: Icon(Icons.broken_image_outlined,
              size: size * 0.4, color: _Z.muted),
        ),
      ),
    );
  }

  Future<void> _showAddTransaction({int? initialActivityId}) async {
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'expense';
    int? activityId = initialActivityId;
    final activities = await _activitiesFuture;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildBottomSheet(
          ctx: ctx,
          title: 'Nouvelle transaction',
          actionLabel: 'Ajouter',
          type: type,
          categoryCtrl: categoryCtrl,
          amountCtrl: amountCtrl,
          notesCtrl: notesCtrl,
          activities: activities,
          activityId: activityId,
          onActivityChanged: (value) => setS(() => activityId = value),
          onTypeChanged: (t) => setS(() => type = t),
          onSubmit: () async {
            try {
              await ApiService.createTransaction({
                'farm_id': widget.farmId,
                'crop_id': widget.cropId,
                'activity_id': activityId,
                'transaction_type': type,
                'category': categoryCtrl.text.trim(),
                'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                'notes': notesCtrl.text.trim(),
              });
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() => _load());
            } catch (e) {
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              _showError(e.toString());
            }
          },
        ),
      ),
    );
  }

  Future<void> _showEditTransaction(Map<String, dynamic> t) async {
    final amountCtrl =
        TextEditingController(text: (t['amount'] ?? '').toString());
    final categoryCtrl = TextEditingController(text: t['category'] ?? '');
    final notesCtrl = TextEditingController(text: t['notes'] ?? '');
    String type = t['transaction_type'] ?? 'expense';
    int? activityId = t['activity_id'] as int?;
    final activities = await _activitiesFuture;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _buildBottomSheet(
          ctx: ctx,
          title: 'Modifier transaction',
          actionLabel: 'Enregistrer',
          type: type,
          categoryCtrl: categoryCtrl,
          amountCtrl: amountCtrl,
          notesCtrl: notesCtrl,
          activities: activities,
          activityId: activityId,
          onActivityChanged: (value) => setS(() => activityId = value),
          onTypeChanged: (v) => setS(() => type = v),
          onSubmit: () async {
            try {
              await ApiService.updateTransaction(t['id'], {
                'transaction_type': type,
                'category': categoryCtrl.text.trim(),
                'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                'notes': notesCtrl.text.trim(),
                'activity_id': activityId,
              });
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() => _load());
            } catch (e) {
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              _showError(e.toString());
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(int id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Z.cardBg,
        title: const Text('SUPPRIMER',
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: _Z.ink)),
        content: const Text(
            'Voulez-vous vraiment supprimer cette transaction ?',
            style: TextStyle(color: _Z.muted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER',
                style: TextStyle(fontSize: 11, color: _Z.muted)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteTransaction(id);
                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                setState(() => _load());
              } catch (e) {
                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                _showError(e.toString());
              }
            },
            child: const Text('SUPPRIMER',
                style: TextStyle(fontSize: 11, color: _Z.expenseAccent)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppColors.createSnackBar(message: msg, isError: true),
    );
  }

  Widget _buildFilters(List<String> filters) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(fontSize: 13, color: _Z.ink),
            decoration: InputDecoration(
              hintText: 'Rechercher une transaction…',
              hintStyle: const TextStyle(color: _Z.muted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18, color: _Z.muted),
              filled: true,
              fillColor: _Z.cardBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: _Z.faint)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: _Z.faint)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: filters.map((filter) {
              final selected = filter == _selectedType;
              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: filter == filters.last ? 0 : 6),
                  child: ChoiceChip(
                    label: SizedBox(
                        width: double.infinity,
                        child: Text(filter.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1,
                                color: selected ? Colors.white : _Z.muted))),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedType = filter),
                    selectedColor: _Z.ink,
                    backgroundColor: _Z.cardBg,
                    side: const BorderSide(color: _Z.faint),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

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
        title: const Text(
          'FINANCES',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
            color: _Z.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Télécharger la traçabilité',
            icon: const Icon(Icons.download_outlined, size: 20, color: _Z.ink),
            onPressed: _exportTraceability,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          color: _Z.ink,
          backgroundColor: _Z.bg,
          onRefresh: () async => setState(() => _load()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              // ── SUMMARY CARD ──────────────────────────────────────────────
              FutureBuilder<Map<String, dynamic>>(
                future: _summaryFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 160,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: _Z.ink, strokeWidth: 1.5)),
                    );
                  }
                  final s = snap.data ?? {};
                  final expenses = s['total_expenses'] ?? 0;
                  final income = s['total_income'] ?? 0;
                  final net = s['net_profit'] ?? 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: _Z.ink,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SOLDE NET',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatAmount(net),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'FCFA',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  letterSpacing: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(height: 1, color: Colors.white10),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SummaryPill(
                                label: 'DÉPENSES',
                                value: _formatAmount(expenses),
                                isIncome: false),
                            _SummaryPill(
                                label: 'REVENUS',
                                value: _formatAmount(income),
                                isIncome: true),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── SECTION HEADER ────────────────────────────────────────────
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _profitabilityFuture,
                builder: (context, snap) {
                  final groups = snap.data ?? const <Map<String, dynamic>>[];
                  if (groups.isEmpty) return const SizedBox.shrink();
                  final totalNet = groups.fold<double>(
                      0, (total, group) => total + (group['net'] as double));
                  final totalPositive = totalNet >= 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _Z.cardBg,
                          border: Border.all(color: _Z.faint),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          title: const Text('RENTABILITÉ PAR ACTIVITÉ',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: _Z.ink,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${groups.length} activité${groups.length > 1 ? 's' : ''} · ${totalPositive ? '+' : '−'}${_formatAmount(totalNet.abs())} FCFA net',
                            style: TextStyle(
                                fontSize: 11,
                                color: totalPositive
                                    ? _Z.incomeAccent
                                    : _Z.expenseAccent),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                              child: Column(
                                children: groups
                                    .map(_buildProfitabilityGroup)
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'TRANSACTIONS',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: _Z.muted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: _Z.faint),
              const SizedBox(height: 12),

              // ── TRANSACTION LIST ──────────────────────────────────────────
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _displayTransactionsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: _Z.ink, strokeWidth: 1.5)),
                    );
                  }
                  final items = snap.data ?? const <Map<String, dynamic>>[];
                  final query = _searchQuery.trim().toLowerCase();
                  final filteredItems = items.where((item) {
                    final type = item['transaction_type'] == 'income'
                        ? 'Revenu'
                        : 'Dépense';
                    final searchable =
                        '${item['category'] ?? ''} ${item['notes'] ?? ''} ${item['activity_name'] ?? ''}'
                            .toLowerCase();
                    return (_selectedType == 'Tous' || type == _selectedType) &&
                        (query.isEmpty || searchable.contains(query));
                  }).toList();
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _Z.faint),
                              ),
                              child: const Icon(Icons.receipt_long_outlined,
                                  size: 24, color: _Z.muted),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'AUCUNE TRANSACTION',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: _Z.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final filters = ['Tous', 'Dépense', 'Revenu'];

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        filteredItems.isEmpty ? 2 : filteredItems.length + 1,
                    separatorBuilder: (_, __) =>
                        Container(height: 1, color: _Z.faint),
                    itemBuilder: (context, i) {
                      if (i == 0) return _buildFilters(filters);
                      if (filteredItems.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(
                              'AUCUN RÉSULTAT',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: _Z.muted),
                            ),
                          ),
                        );
                      }
                      final it = filteredItems[i - 1];
                      final isExpense = it['transaction_type'] == 'expense';
                      final isInputExpense =
                          isExpense && it['input_id'] != null;
                      final transactionColor = isInputExpense
                          ? _Z.inputAccent
                          : isExpense
                              ? _Z.ink
                              : _Z.incomeAccent;
                      final visibleNotes = it['notes']?.toString().trim() ?? '';
                      final activityName =
                          it['activity_name']?.toString().trim();
                      final isGeneralFinance =
                          activityName == null || activityName.isEmpty;

                      return GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: _Z.cardBg,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            builder: (_) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                    width: 32,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: _Z.faint,
                                        borderRadius:
                                            BorderRadius.circular(2))),
                                const SizedBox(height: 12),
                                _ActionTile(
                                  icon: Icons.edit_outlined,
                                  label: 'MODIFIER',
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showEditTransaction(it);
                                  },
                                ),
                                Container(
                                    height: 1,
                                    color: _Z.faint,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 20)),
                                _ActionTile(
                                  icon: Icons.delete_outline,
                                  label: 'SUPPRIMER',
                                  color: _Z.expenseAccent,
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deleteTransaction(it['id']);
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: transactionColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (isInputExpense) ...[
                                          const Icon(Icons.inventory_2_outlined,
                                              size: 14, color: _Z.inputAccent),
                                          const SizedBox(width: 6),
                                        ],
                                        Expanded(
                                          child: Text(
                                            (it['category'] ?? '-')
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              letterSpacing: 1,
                                              fontWeight: FontWeight.w600,
                                              color: isInputExpense
                                                  ? _Z.inputAccent
                                                  : _Z.ink,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isInputExpense) ...[
                                          const SizedBox(width: 8),
                                          const Text(
                                            'INTRANT',
                                            style: TextStyle(
                                                fontSize: 8,
                                                letterSpacing: 1,
                                                color: _Z.inputAccent),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDate(it['transaction_date']),
                                      style: const TextStyle(
                                          fontSize: 11, color: _Z.muted),
                                    ),
                                    if (visibleNotes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        visibleNotes,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: _Z.muted,
                                            fontStyle: FontStyle.italic),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          isGeneralFinance
                                              ? Icons.layers_clear_outlined
                                              : Icons.agriculture_outlined,
                                          size: 12,
                                          color: isGeneralFinance
                                              ? _Z.muted
                                              : _Z.inputAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            isGeneralFinance
                                                ? 'FINANCE GÉNÉRALE'
                                                : 'ACTIVITÉ · ${activityName.toUpperCase()}',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 9,
                                              letterSpacing: 0.7,
                                              fontWeight: FontWeight.w600,
                                              color: isGeneralFinance
                                                  ? _Z.muted
                                                  : _Z.inputAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isExpense ? "−" : "+"}${_formatAmount(it['amount'])}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: transactionColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'FCFA',
                                    style: TextStyle(
                                        fontSize: 9,
                                        letterSpacing: 1,
                                        color: _Z.muted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransaction,
        backgroundColor: _Z.ink,
        elevation: 2,
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: const Text(
          'AJOUTER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── HELPER WIDGETS ──────────────────────────────────────────────────────────

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isIncome;
  const _SummaryPill(
      {required this.label, required this.value, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? const Color(0xFF81C784) : Colors.white70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.5,
              color: Colors.white38,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isIncome ? Icons.north_east : Icons.south_west,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
        Text(
          label,
          style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.5,
              color: _Z.muted,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 13, color: _Z.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _Z.muted, fontSize: 13),
            filled: true,
            fillColor: _Z.cardBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _Z.faint),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _Z.ink, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _Z.ink,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(icon, size: 18, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }
}
