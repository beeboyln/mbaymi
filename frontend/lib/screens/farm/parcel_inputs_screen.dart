import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:intl/intl.dart';

// ─── DESIGN TOKENS ───────────────────────────────────────────────────────────
class _Z {
  static const bg = Color(0xFFF8F8F7);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF767676);
  static const faint = Color(0xFFE2E0D8);
  static const cardBg = Color(0xFFFFFFFF);
  static const expenseAccent = Color(0xFFD9534F);

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
  String _searchQuery = '';
  String _selectedType = 'Tous';

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
    _listFuture = ApiService.listInputsForCrop(widget.cropId);
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

  String _normalizeSearchText(Object? value) {
    return value
        .toString()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppColors.createSnackBar(
        message: msg,
        isError: true,
      ),
    );
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
      child: SingleChildScrollView(
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

            _ZField(controller: typeCtrl, label: 'TYPE', hint: 'Semences, engrais, pesticide…'),
            const SizedBox(height: 14),
            _ZField(controller: nameCtrl, label: 'NOM', hint: "Nom de l'intrant"),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _ZField(controller: qtyCtrl, label: 'QUANTITÉ', hint: '0', numeric: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ZField(controller: unitCtrl, label: 'UNITÉ', hint: 'kg, L…'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ZField(controller: costCtrl, label: 'COÛT (FCFA)', hint: '0', numeric: true),
            const SizedBox(height: 14),
            _ZField(controller: notesCtrl, label: 'NOTES', hint: 'Détails supplémentaires…', maxLines: 2),
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
        backgroundColor: _Z.cardBg,
        title: const Text('SUPPRIMER',
            style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold, color: _Z.ink)),
        content: const Text('Voulez-vous vraiment supprimer cet intrant ?',
            style: TextStyle(color: _Z.muted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER', style: TextStyle(fontSize: 11, color: _Z.muted)),
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
            child: const Text('SUPPRIMER', style: TextStyle(fontSize: 11, color: _Z.expenseAccent)),
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
            style: TextStyle(fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.bold, color: _Z.ink)),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: FutureBuilder<List<dynamic>>(
          future: _listFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _Z.ink, strokeWidth: 1.5));
            }

            final items = snap.data ?? [];

            final types = items
                .map((item) => (item['input_type'] ?? 'Autre').toString())
                .toSet()
                .toList()
              ..sort();
            final query = _normalizeSearchText(_searchQuery);
            final filteredItems = items.where((item) {
              final type = (item['input_type'] ?? 'Autre').toString();
              final searchable = _normalizeSearchText(
                '${item['name'] ?? ''} $type ${item['unit'] ?? ''} ${item['notes'] ?? ''}',
              );
              return (_selectedType == 'Tous' || type == _selectedType) &&
                  (query.isEmpty || searchable.contains(query));
            }).toList();
            final totalCost = items.fold<double>(
              0,
              (sum, item) => sum + ((item['cost'] as num?)?.toDouble() ?? 0),
            );

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _Z.faint),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, size: 28, color: _Z.muted),
                    ),
                    const SizedBox(height: 16),
                    const Text('AUCUN INTRANT',
                        style: TextStyle(fontSize: 10, letterSpacing: 2, color: _Z.muted, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Ajoutez vos premiers intrants',
                        style: TextStyle(fontSize: 13, color: _Z.muted)),
                  ],
                ),
              );
            }

            final filterTypes = ['Tous', ...types];
            final groupedItems = filteredItems;

            // Group by type
            final Map<String, List<dynamic>> grouped = {};
            for (final item in groupedItems) {
              final t = item['input_type'] ?? 'Autre';
              grouped.putIfAbsent(t, () => []).add(item);
            }

            return RefreshIndicator(
              color: _Z.ink,
              backgroundColor: _Z.bg,
              onRefresh: () async => setState(() => _load()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  _buildOverview(totalCost, items.length),
                  _buildFilters(filterTypes),
                  if (groupedItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'AUCUN RÉSULTAT',
                          style: TextStyle(fontSize: 10, letterSpacing: 2, color: _Z.muted),
                        ),
                      ),
                    )
                  else
                    ...grouped.entries.expand((entry) {
                  final type = entry.key;
                  final typeItems = entry.value;
                  final color = _typeColor(type);

                  return [
                    const SizedBox(height: 20),

                    // ── Group header ──────────────────────────────────
                    Row(
                      children: [
                        Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text(
                          type.toUpperCase(),
                          style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, color: color),
                        ),
                        const SizedBox(width: 8),
                        Text('${typeItems.length}',
                            style: const TextStyle(fontSize: 10, color: _Z.muted, fontWeight: FontWeight.bold)),
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
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddInput,
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

  Widget _buildOverview(double totalCost, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _Z.ink, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('INVESTISSEMENT TOTAL', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: Colors.white54)),
            const SizedBox(height: 6),
            Text('${_formatCost(totalCost)} FCFA', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
          ]),
          Text('$count ENREG.', style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildFilters(List<String> types) {
    return Column(
      children: [
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(fontSize: 13, color: _Z.ink),
          decoration: InputDecoration(
            hintText: 'Rechercher un intrant…',
            hintStyle: const TextStyle(color: _Z.muted, fontSize: 13),
            prefixIcon: const Icon(Icons.search, size: 18, color: _Z.muted),
            filled: true,
            fillColor: _Z.cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _Z.faint)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _Z.faint)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, index) {
              final type = types[index];
              final selected = type == _selectedType;
              return ChoiceChip(
                label: Text(type.toUpperCase(), style: TextStyle(fontSize: 9, letterSpacing: 1, color: selected ? Colors.white : _Z.muted)),
                selected: selected,
                onSelected: (_) => setState(() => _selectedType = type),
                selectedColor: _Z.ink,
                backgroundColor: _Z.cardBg,
                side: const BorderSide(color: _Z.faint),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              );
            },
          ),
        ),
      ],
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
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),

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
                        style: const TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w600, color: _Z.ink),
                      ),
                    ),
                    if (formattedCost != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        formattedCost!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _Z.ink),
                      ),
                    ],
                  ],
                ),

                if (hasQty) ...[
                  const SizedBox(height: 2),
                  Text('$qty $unit'.trim(), style: const TextStyle(fontSize: 11, color: _Z.muted)),
                ],

                if ((item['notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item['notes'].toString(),
                    style: const TextStyle(fontSize: 11, color: _Z.muted, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                Row(
                  children: [
                    _MiniAction(label: 'MODIFIER', onTap: onEdit),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: _Z.faint),
                    const SizedBox(width: 8),
                    _MiniAction(label: 'SUPPRIMER', onTap: onDelete, color: _Z.expenseAccent),
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
      child: Text(
        label,
        style: TextStyle(fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: color),
      ),
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