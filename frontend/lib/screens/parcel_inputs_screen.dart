import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:intl/intl.dart';

// ─── DESIGN TOKENS ───────────────────────────────────────────────────────────
class _Z {
  static const bg = Color(0xFFF7F6F4);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF888888);
  static const faint = Color(0xFFE8E6E1);
  static const cardBg = Color(0xFFFFFFFF);

  // Type accents sobres
  static const seedColor = Color(0xFF4A7C59);
  static const fertColor = Color(0xFF7B5E3A);
  static const pestColor = Color(0xFF8B6914);
  static const waterColor = Color(0xFF3A6B8B);
  static const toolColor = Color(0xFF5A5A6E);
  static const otherColor = Color(0xFF6B4A7C);
}
// ─────────────────────────────────────────────────────────────────────────────

class ParcelInputsScreen extends StatefulWidget {
  final int farmId;
  final int cropId;

  const ParcelInputsScreen({super.key, required this.farmId, required this.cropId});

  @override
  State<ParcelInputsScreen> createState() => _ParcelInputsScreenState();
}

class _ParcelInputsScreenState extends State<ParcelInputsScreen>
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
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _load() {
    _listFuture = ApiService.listInputsForFarm(widget.farmId);
  }

  Color _typeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('semence') || t.contains('graine')) return _Z.seedColor;
    if (t.contains('engrais') || t.contains('fertilisant')) return _Z.fertColor;
    if (t.contains('pesticide') || t.contains('traitement')) return _Z.pestColor;
    if (t.contains('eau') || t.contains('irrigation')) return _Z.waterColor;
    if (t.contains('outil') || t.contains('équipement')) return _Z.toolColor;
    return _Z.otherColor;
  }

  String _formatCost(dynamic v) {
    if (v == null) return '';
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    return NumberFormat('#,##0', 'fr_FR').format(n);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12, letterSpacing: 0.5)),
      backgroundColor: _Z.ink,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(),
    ));
  }

  // ─── SHARED BOTTOM SHEET ─────────────────────────────────────────────────
  Widget _buildSheet({
    required BuildContext ctx,
    required String title,
    required String actionLabel,
    required TextEditingController typeCtrl,
    required TextEditingController nameCtrl,
    required TextEditingController qtyCtrl,
    required TextEditingController unitCtrl,
    required TextEditingController costCtrl,
    required TextEditingController notesCtrl,
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
            Center(
              child: Container(
                width: 32, height: 2, color: _Z.faint,
                margin: const EdgeInsets.only(bottom: 32),
              ),
            ),
            Text(title.toUpperCase(),
                style: const TextStyle(fontSize: 11, letterSpacing: 3,
                    fontWeight: FontWeight.w500, color: _Z.muted)),
            const SizedBox(height: 24),

            _ZField(controller: typeCtrl, label: 'TYPE',
                hint: 'Semences, engrais, pesticide…'),
            const SizedBox(height: 16),
            _ZField(controller: nameCtrl, label: 'NOM', hint: "Nom de l'intrant"),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _ZField(controller: qtyCtrl, label: 'QUANTITÉ',
                      hint: '0', numeric: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ZField(controller: unitCtrl, label: 'UNITÉ', hint: 'kg, L…'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ZField(controller: costCtrl, label: 'COÛT (FCFA)',
                hint: '0', numeric: true),
            const SizedBox(height: 16),
            _ZField(controller: notesCtrl, label: 'NOTES',
                hint: 'Détails supplémentaires…', maxLines: 3),
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
                  style: const TextStyle(color: Colors.white, fontSize: 11,
                      letterSpacing: 3, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADD ─────────────────────────────────────────────────────────────────
  Future<void> _showAddInput() async {
    final typeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx: ctx,
        title: "Nouvel intrant",
        actionLabel: "Ajouter",
        typeCtrl: typeCtrl,
        nameCtrl: nameCtrl,
        qtyCtrl: qtyCtrl,
        unitCtrl: unitCtrl,
        costCtrl: costCtrl,
        notesCtrl: notesCtrl,
        onSubmit: () async {
          try {
            await ApiService.createInput({
              'farm_id': widget.farmId,
              'crop_id': widget.cropId,
              'input_type': typeCtrl.text.trim(),
              'name': nameCtrl.text.trim(),
              'quantity': double.tryParse(qtyCtrl.text),
              'unit': unitCtrl.text.trim(),
              'cost': double.tryParse(costCtrl.text),
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
    );
  }

  // ─── EDIT ────────────────────────────────────────────────────────────────
  Future<void> _showEditInput(Map<String, dynamic> input) async {
    final typeCtrl = TextEditingController(text: input['input_type'] ?? '');
    final nameCtrl = TextEditingController(text: input['name'] ?? '');
    final qtyCtrl = TextEditingController(text: (input['quantity'] ?? '').toString());
    final unitCtrl = TextEditingController(text: input['unit'] ?? '');
    final costCtrl = TextEditingController(text: (input['cost'] ?? '').toString());
    final notesCtrl = TextEditingController(text: input['notes'] ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx: ctx,
        title: "Modifier l'intrant",
        actionLabel: "Enregistrer",
        typeCtrl: typeCtrl,
        nameCtrl: nameCtrl,
        qtyCtrl: qtyCtrl,
        unitCtrl: unitCtrl,
        costCtrl: costCtrl,
        notesCtrl: notesCtrl,
        onSubmit: () async {
          try {
            await ApiService.updateInput(input['id'], {
              'input_type': typeCtrl.text.trim(),
              'name': nameCtrl.text.trim(),
              'quantity': double.tryParse(qtyCtrl.text),
              'unit': unitCtrl.text.trim(),
              'cost': double.tryParse(costCtrl.text),
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
    );
  }

  // ─── DELETE ──────────────────────────────────────────────────────────────
  Future<void> _deleteInput(int id) async {
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
                await ApiService.deleteInput(id);
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
        title: const Text('INTRANTS',
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
                      width: 64, height: 64,
                      decoration: BoxDecoration(border: Border.all(color: _Z.faint)),
                      child: const Icon(Icons.inventory_2_outlined,
                          size: 28, color: _Z.muted),
                    ),
                    const SizedBox(height: 20),
                    const Text('AUCUN INTRANT',
                        style: TextStyle(fontSize: 9, letterSpacing: 3, color: _Z.muted)),
                    const SizedBox(height: 8),
                    const Text('Ajoutez vos premiers intrants',
                        style: TextStyle(fontSize: 13, color: _Z.muted)),
                  ],
                ),
              );
            }

            // Group by type
            final Map<String, List<dynamic>> grouped = {};
            for (final item in items) {
              final t = item['input_type'] ?? 'Autre';
              grouped.putIfAbsent(t, () => []).add(item);
            }

            return RefreshIndicator(
              color: _Z.ink,
              backgroundColor: _Z.bg,
              onRefresh: () async => setState(() => _load()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                children: grouped.entries.expand((entry) {
                  final type = entry.key;
                  final typeItems = entry.value;
                  final color = _typeColor(type);

                  return [
                    const SizedBox(height: 24),

                    // ── Group header ──────────────────────────────────
                    Row(
                      children: [
                        Container(width: 2, height: 14, color: color),
                        const SizedBox(width: 10),
                        Text(
                          type.toUpperCase(),
                          style: TextStyle(fontSize: 9, letterSpacing: 3,
                              fontWeight: FontWeight.w600, color: color),
                        ),
                        const SizedBox(width: 8),
                        Text('${typeItems.length}',
                            style: const TextStyle(fontSize: 9, color: _Z.muted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: _Z.faint),
                    const SizedBox(height: 4),

                    // ── Items ─────────────────────────────────────────
                    ...typeItems.asMap().entries.map((e) {
                      final i = e.key;
                      final it = e.value as Map<String, dynamic>;
                      final isLast = i == typeItems.length - 1;

                      return Column(
                        children: [
                          _InputRow(
                            item: it,
                            color: color,
                            formattedCost: it['cost'] != null
                                ? '${_formatCost(it['cost'])} FCFA'
                                : null,
                            onEdit: () => _showEditInput(it),
                            onDelete: () => _deleteInput(it['id'] as int),
                          ),
                          if (!isLast) Container(height: 1, color: _Z.faint),
                        ],
                      );
                    }),
                  ];
                }).toList(),
              ),
            );
          },
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _showAddInput,
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

// ─── INPUT ROW ───────────────────────────────────────────────────────────────
class _InputRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color color;
  final String? formattedCost;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InputRow({
    required this.item,
    required this.color,
    required this.formattedCost,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final qty = item['quantity'];
    final unit = item['unit'] ?? '';
    final hasQty = qty != null && qty.toString().isNotEmpty && qty != 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 2, height: 52, color: color.withOpacity(0.4)),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + cost
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        (item['name'] ?? '-').toString().toUpperCase(),
                        style: const TextStyle(fontSize: 13, letterSpacing: 1.5,
                            fontWeight: FontWeight.w500, color: _Z.ink),
                      ),
                    ),
                    if (formattedCost != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        formattedCost!,
                        style: const TextStyle(fontSize: 13, letterSpacing: 0.5,
                            fontWeight: FontWeight.w600, color: _Z.ink),
                      ),
                    ],
                  ],
                ),

                if (hasQty) ...[
                  const SizedBox(height: 5),
                  Text('$qty $unit'.trim(),
                      style: const TextStyle(fontSize: 12, color: _Z.muted)),
                ],

                if ((item['notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item['notes'].toString(),
                      style: const TextStyle(fontSize: 11, color: _Z.muted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],

                const SizedBox(height: 10),

                Row(
                  children: [
                    _MiniAction(label: 'MODIFIER', onTap: onEdit),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: _Z.faint),
                    const SizedBox(width: 8),
                    _MiniAction(label: 'SUPPRIMER', onTap: onDelete,
                        color: const Color(0xFF9E3A3A)),
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

  const _MiniAction({required this.label, required this.onTap, this.color = _Z.muted});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: TextStyle(fontSize: 9, letterSpacing: 1.5,
              fontWeight: FontWeight.w500, color: color)),
    );
  }
}

// ─── SHARED FIELD ────────────────────────────────────────────────────────────
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
            border: const OutlineInputBorder(
                borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: _Z.faint)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: _Z.ink, width: 1)),
          ),
        ),
      ],
    );
  }
}