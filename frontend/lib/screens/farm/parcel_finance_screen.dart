import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/utils/app_colors.dart';

// ─── ZARA-STYLE DESIGN TOKENS ───────────────────────────────────────────────
class _Z {
  static const bg = Color(0xFFF8F8F7);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF767676);
  static const faint = Color(0xFFE2E0D8);
  static const expenseAccent = Color(0xFFD9534F);
  static const incomeAccent = Color(0xFF2E7D32);
  static const cardBg = Color(0xFFFFFFFF);
}
// ────────────────────────────────────────────────────────────────────────────

class ParcelFinanceScreen extends StatefulWidget {
  final int farmId;
  final int cropId;
  const ParcelFinanceScreen({super.key, required this.farmId, required this.cropId});

  @override
  State<ParcelFinanceScreen> createState() => _ParcelFinanceScreenState();
}

class _ParcelFinanceScreenState extends State<ParcelFinanceScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _listFuture;
  late Future<Map<String, dynamic>> _summaryFuture;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return '';
    try {
      return DateFormat('d MMM yyyy · HH:mm', 'fr_FR').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  String _formatAmount(dynamic v) {
    if (v == null) return '0';
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    return NumberFormat('#,##0', 'fr_FR').format(n);
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
          _ZField(controller: categoryCtrl, label: 'CATÉGORIE', hint: "Main-d'œuvre, semences…"),
          const SizedBox(height: 14),
          _ZField(controller: amountCtrl, label: 'MONTANT (FCFA)', hint: '0', numeric: true),
          const SizedBox(height: 14),
          _ZField(controller: notesCtrl, label: 'NOTES', hint: 'Détails…', maxLines: 2),
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

  Future<void> _showAddTransaction() async {
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'expense';

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
          onTypeChanged: (t) => setS(() => type = t),
          onSubmit: () async {
            try {
              await ApiService.createTransaction({
                'farm_id': widget.farmId,
                'crop_id': widget.cropId,
                'transaction_type': type,
                'category': categoryCtrl.text.trim(),
                'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                'notes': notesCtrl.text.trim(),
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

  Future<void> _showEditTransaction(Map<String, dynamic> t) async {
    final amountCtrl = TextEditingController(text: (t['amount'] ?? '').toString());
    final categoryCtrl = TextEditingController(text: t['category'] ?? '');
    final notesCtrl = TextEditingController(text: t['notes'] ?? '');
    String type = t['transaction_type'] ?? 'expense';

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
          onTypeChanged: (v) => setS(() => type = v),
          onSubmit: () async {
            try {
              await ApiService.updateTransaction(t['id'], {
                'transaction_type': type,
                'category': categoryCtrl.text.trim(),
                'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                'notes': notesCtrl.text.trim(),
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

  Future<void> _deleteTransaction(int id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Z.cardBg,
        title: const Text('SUPPRIMER',
            style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold, color: _Z.ink)),
        content: const Text('Voulez-vous vraiment supprimer cette transaction ?',
            style: TextStyle(color: _Z.muted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER', style: TextStyle(fontSize: 11, color: _Z.muted)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteTransaction(id);
                Navigator.pop(context);
                setState(() => _load());
              } catch (e) {
                Navigator.pop(context);
                _showError(e.toString());
              }
            },
            child: const Text('SUPPRIMER', style: TextStyle(fontSize: 11, color: _Z.expenseAccent)),
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
                      child: Center(child: CircularProgressIndicator(color: _Z.ink, strokeWidth: 1.5)),
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
                              style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(height: 1, color: Colors.white10),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SummaryPill(label: 'DÉPENSES', value: _formatAmount(expenses), isIncome: false),
                            _SummaryPill(label: 'REVENUS', value: _formatAmount(income), isIncome: true),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── SECTION HEADER ────────────────────────────────────────────
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
              FutureBuilder<List<dynamic>>(
                future: _listFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: _Z.ink, strokeWidth: 1.5)),
                    );
                  }
                  final items = snap.data ?? [];
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
                              child: const Icon(Icons.receipt_long_outlined, size: 24, color: _Z.muted),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'AUCUNE TRANSACTION',
                              style: TextStyle(fontSize: 10, letterSpacing: 2, color: _Z.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Container(height: 1, color: _Z.faint),
                    itemBuilder: (context, i) {
                      final it = items[i] as Map<String, dynamic>;
                      final isExpense = it['transaction_type'] == 'expense';

                      return GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: _Z.cardBg,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            builder: (_) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                Container(width: 32, height: 4, decoration: BoxDecoration(color: _Z.faint, borderRadius: BorderRadius.circular(2))),
                                const SizedBox(height: 12),
                                _ActionTile(
                                  icon: Icons.edit_outlined,
                                  label: 'MODIFIER',
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showEditTransaction(it);
                                  },
                                ),
                                Container(height: 1, color: _Z.faint, margin: const EdgeInsets.symmetric(horizontal: 20)),
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
                                  color: isExpense ? _Z.ink : _Z.incomeAccent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (it['category'] ?? '-').toString().toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w600,
                                        color: _Z.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDate(it['transaction_date']),
                                      style: const TextStyle(fontSize: 11, color: _Z.muted),
                                    ),
                                    if (it['notes'] != null && it['notes'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        it['notes'].toString(),
                                        style: const TextStyle(fontSize: 11, color: _Z.muted, fontStyle: FontStyle.italic),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
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
                                      color: isExpense ? _Z.ink : _Z.incomeAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'FCFA',
                                    style: TextStyle(fontSize: 9, letterSpacing: 1, color: _Z.muted),
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
  const _SummaryPill({required this.label, required this.value, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? const Color(0xFF81C784) : Colors.white70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, letterSpacing: 1.5, color: Colors.white38, fontWeight: FontWeight.bold),
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
          style: const TextStyle(fontSize: 9, letterSpacing: 1.5, color: _Z.muted, fontWeight: FontWeight.bold),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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