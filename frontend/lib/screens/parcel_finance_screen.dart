import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/utils/app_colors.dart';

// ─── ZARA-STYLE DESIGN TOKENS ───────────────────────────────────────────────
class _Z {
  static const bg = Color(0xFFF7F6F4);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF888888);
  static const faint = Color(0xFFE8E6E1);
  static const expenseAccent = Color(0xFF111111);
  static const incomeAccent = Color(0xFF4A7C59);
  static const cardBg = Color(0xFFFFFFFF);
  static const serif = TextStyle(fontFamily: 'Georgia', color: Color(0xFF111111));
}
// ────────────────────────────────────────────────────────────────────────────

class ParcelFinanceScreen extends StatefulWidget {
  final int farmId;
  const ParcelFinanceScreen({super.key, required this.farmId});

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
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
    _listFuture = ApiService.listTransactionsForFarm(widget.farmId);
    _summaryFuture = ApiService.getFinanceSummary(widget.farmId);
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

  // ─── SHARED BOTTOM SHEET LAYOUT ─────────────────────────────────────────
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
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
              child: Container(
                width: 32,
                height: 2,
                color: _Z.faint,
                margin: const EdgeInsets.only(bottom: 32),
              ),
            ),
            Text(title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                  color: _Z.muted,
                )),
            const SizedBox(height: 24),

            // Type toggle — minimal pill-less version
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? _Z.ink : Colors.transparent,
                        border: Border.all(color: selected ? _Z.ink : _Z.faint),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : _Z.muted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Fields
            _ZField(controller: categoryCtrl, label: 'CATÉGORIE', hint: "Main-d'œuvre, semences…"),
            const SizedBox(height: 16),
            _ZField(controller: amountCtrl, label: 'MONTANT (FCFA)', hint: '0', numeric: true),
            const SizedBox(height: 16),
            _ZField(controller: notesCtrl, label: 'NOTES', hint: 'Détails…', maxLines: 3),
            const SizedBox(height: 32),

            // Action
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
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
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

  // ─── EDIT ────────────────────────────────────────────────────────────────
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
          title: 'Modifier',
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

  // ─── DELETE ──────────────────────────────────────────────────────────────
  Future<void> _deleteTransaction(int id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Z.bg,
        shape: const RoundedRectangleBorder(),
        title: const Text('SUPPRIMER',
            style: TextStyle(fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w500, color: _Z.ink)),
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
                await ApiService.deleteTransaction(id);
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12, letterSpacing: 0.5)),
      backgroundColor: _Z.ink,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(),
    ));
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
        title: const Text(
          'FINANCES',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            children: [
              // ── SUMMARY CARD ──────────────────────────────────────────────
              FutureBuilder<Map<String, dynamic>>(
                future: _summaryFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200,
                        child: Center(child: CircularProgressIndicator(color: _Z.ink, strokeWidth: 1)));
                  }
                  final s = snap.data ?? {};
                  final expenses = s['total_expenses'] ?? 0;
                  final income = s['total_income'] ?? 0;
                  final net = s['net_profit'] ?? 0;
                  final isProfit = (net is num) ? net >= 0 : true;

                  return Container(
                    color: _Z.ink,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SOLDE ACTUEL',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 3,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatAmount(net),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('FCFA',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                )),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 1,
                          color: Colors.white12,
                          margin: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        Row(
                          children: [
                            _SummaryPill(label: 'DÉPENSES', value: _formatAmount(expenses), up: false),
                            const SizedBox(width: 32),
                            _SummaryPill(label: 'REVENUS', value: _formatAmount(income), up: true),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // ── SECTION LABEL ─────────────────────────────────────────────
              const Text('TRANSACTIONS',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 3,
                    color: _Z.muted,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 2),
              Container(height: 1, color: _Z.faint),
              const SizedBox(height: 16),

              // ── LIST ──────────────────────────────────────────────────────
              FutureBuilder<List<dynamic>>(
                future: _listFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: _Z.ink, strokeWidth: 1),
                    ));
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(color: _Z.faint),
                              ),
                              child: const Icon(Icons.receipt_long_outlined, size: 20, color: _Z.muted),
                            ),
                            const SizedBox(height: 16),
                            const Text('AUCUNE TRANSACTION',
                                style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 3,
                                  color: _Z.muted,
                                )),
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
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: _Z.bg,
                            shape: const RoundedRectangleBorder(),
                            builder: (_) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 1,
                                  color: _Z.faint,
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                ),
                                _ActionTile(
                                  icon: Icons.edit_outlined,
                                  label: 'MODIFIER',
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showEditTransaction(it);
                                  },
                                ),
                                Container(height: 1, color: _Z.faint, margin: const EdgeInsets.symmetric(horizontal: 24)),
                                _ActionTile(
                                  icon: Icons.delete_outline,
                                  label: 'SUPPRIMER',
                                  color: Colors.red[700]!,
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deleteTransaction(it['id']);
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              // Type indicator
                              Container(
                                width: 2,
                                height: 36,
                                color: isExpense ? _Z.ink : _Z.incomeAccent,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (it['category'] ?? '-').toString().toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w500,
                                        color: _Z.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(it['transaction_date']),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _Z.muted,
                                        letterSpacing: 0.3,
                                      ),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: isExpense ? _Z.ink : _Z.incomeAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'FCFA',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                      color: _Z.muted,
                                    ),
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
      floatingActionButton: GestureDetector(
        onTap: _showAddTransaction,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          color: _Z.ink,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'AJOUTER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
  final bool up;
  const _SummaryPill({required this.label, required this.value, required this.up});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 9, letterSpacing: 2.5, color: Colors.white38)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              up ? Icons.north : Icons.south,
              size: 10,
              color: up ? const Color(0xFF7EC8A4) : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: up ? const Color(0xFF7EC8A4) : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
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
        Text(label,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 2.5,
              color: _Z.muted,
              fontWeight: FontWeight.w500,
            )),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      leading: Icon(icon, size: 18, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }
}