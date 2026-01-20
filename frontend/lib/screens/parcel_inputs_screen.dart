import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/utils/app_colors.dart';

class ParcelInputsScreen extends StatefulWidget {
  final int farmId;
  final int cropId;

  const ParcelInputsScreen({Key? key, required this.farmId, required this.cropId}) : super(key: key);

  @override
  State<ParcelInputsScreen> createState() => _ParcelInputsScreenState();
}

class _ParcelInputsScreenState extends State<ParcelInputsScreen> {
  late Future<List<dynamic>> _listFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _listFuture = ApiService.listInputsForFarm(widget.farmId);
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('semence') || t.contains('graine')) return Icons.eco_outlined;
    if (t.contains('engrais') || t.contains('fertilisant')) return Icons.grass_outlined;
    if (t.contains('pesticide') || t.contains('traitement')) return Icons.pest_control_outlined;
    if (t.contains('eau') || t.contains('irrigation')) return Icons.water_drop_outlined;
    if (t.contains('outil') || t.contains('équipement')) return Icons.build_outlined;
    return Icons.inventory_2_outlined;
  }

  Color _getColorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('semence') || t.contains('graine')) return Colors.green;
    if (t.contains('engrais') || t.contains('fertilisant')) return Colors.brown;
    if (t.contains('pesticide') || t.contains('traitement')) return Colors.orange;
    if (t.contains('eau') || t.contains('irrigation')) return Colors.blue;
    if (t.contains('outil') || t.contains('équipement')) return Colors.grey;
    return Colors.purple;
  }

  Future<void> _showAddInput() async {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

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
          child: SingleChildScrollView(
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
                  'Nouvel intrant',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: typeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    hintText: 'Semences, engrais, pesticide...',
                    prefixIcon: const Icon(Icons.category_outlined),
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
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Nom de l\'intrant',
                    prefixIcon: const Icon(Icons.label_outline),
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: InputDecoration(
                          labelText: 'Quantité',
                          prefixIcon: const Icon(Icons.numbers),
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
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: InputDecoration(
                          labelText: 'Unité',
                          hintText: 'kg, L...',
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costCtrl,
                  decoration: InputDecoration(
                    labelText: 'Coût',
                    prefixText: 'FCFA ',
                    prefixIcon: const Icon(Icons.attach_money),
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
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Détails supplémentaires...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes_outlined),
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final payload = {
                      'farm_id': widget.farmId,
                      'crop_id': widget.cropId,
                      'input_type': typeCtrl.text.trim(),
                      'name': nameCtrl.text.trim(),
                      'quantity': double.tryParse(qtyCtrl.text) ?? null,
                      'unit': unitCtrl.text.trim(),
                      'cost': double.tryParse(costCtrl.text) ?? null,
                      'notes': notesCtrl.text.trim(),
                    };
                    try {
                      await ApiService.createInput(payload);
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
                  child: const Text('Ajouter l\'intrant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditInput(Map<String, dynamic> input) async {
    final nameCtrl = TextEditingController(text: input['name'] ?? '');
    final typeCtrl = TextEditingController(text: input['input_type'] ?? '');
    final qtyCtrl = TextEditingController(text: (input['quantity'] ?? '').toString());
    final unitCtrl = TextEditingController(text: input['unit'] ?? '');
    final costCtrl = TextEditingController(text: (input['cost'] ?? '').toString());
    final notesCtrl = TextEditingController(text: input['notes'] ?? '');

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
          child: SingleChildScrollView(
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
                  'Modifier l\'intrant',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: typeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    hintText: 'Semences, engrais, pesticide...',
                    prefixIcon: const Icon(Icons.category_outlined),
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
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Nom de l\'intrant',
                    prefixIcon: const Icon(Icons.label_outline),
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: InputDecoration(
                          labelText: 'Quantité',
                          prefixIcon: const Icon(Icons.numbers),
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
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: InputDecoration(
                          labelText: 'Unité',
                          hintText: 'kg, L...',
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costCtrl,
                  decoration: InputDecoration(
                    labelText: 'Coût',
                    prefixText: 'FCFA ',
                    prefixIcon: const Icon(Icons.attach_money),
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
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Détails supplémentaires...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes_outlined),
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final updates = {
                      'input_type': typeCtrl.text.trim(),
                      'name': nameCtrl.text.trim(),
                      'quantity': double.tryParse(qtyCtrl.text) ?? null,
                      'unit': unitCtrl.text.trim(),
                      'cost': double.tryParse(costCtrl.text) ?? null,
                      'notes': notesCtrl.text.trim(),
                    };
                    try {
                      await ApiService.updateInput(input['id'], updates);
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
          ),
        );
      },
    );
  }

  Future<void> _deleteInput(int inputId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet intrant?'),
        content: const Text('Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteInput(inputId);
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
        title: const Text('Intrants', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucun intrant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez vos premiers intrants',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Group items by type
          final Map<String, List<dynamic>> groupedItems = {};
          for (var item in items) {
            final type = item['input_type'] ?? 'Autre';
            if (!groupedItems.containsKey(type)) {
              groupedItems[type] = [];
            }
            groupedItems[type]!.add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: groupedItems.entries.map((entry) {
              final type = entry.key;
              final typeItems = entry.value;
              final color = _getColorForType(type);
              final icon = _getIconForType(type);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 20, color: color),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          type,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${typeItems.length}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...typeItems.map((it) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        title: Text(
                          it['name'] ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (it['quantity'] != null && it['unit'] != null) ...[
                                Icon(Icons.scale_outlined, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${it['quantity']} ${it['unit']}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                        trailing: it['cost'] != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${it['cost']} F',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.green[700],
                                  ),
                                ),
                              )
                            : null,
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit, color: Colors.blue),
                                    title: const Text('Modifier'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showEditInput(it);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _deleteInput(it['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddInput,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}