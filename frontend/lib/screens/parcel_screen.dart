import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/screens/activity_screen.dart';

class ParcelScreen extends StatefulWidget {
  final int farmId;
  final int userId;

  const ParcelScreen({Key? key, required this.farmId, required this.userId}) : super(key: key);

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  late Future<List<dynamic>> _parcelsFuture;
  bool _loadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _parcelsFuture = ApiService.getFarmCrops(widget.farmId);
  }

  Future<void> _refresh() async {
    // Avoid returning a Future from the setState callback — assign synchronously inside a block
    setState(() {
      _parcelsFuture = ApiService.getFarmCrops(widget.farmId);
    });
  }

  void _showAddParcel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final _nameCtrl = TextEditingController();
        final _seededCtrl = TextEditingController();
        final _sizeCtrl = TextEditingController();
        String _status = 'En préparation';

        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom de la parcelle')),
                const SizedBox(height: 8),
                TextField(controller: _sizeCtrl, decoration: const InputDecoration(labelText: 'Superficie (ha)'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'En préparation', child: Text('En préparation')),
                    DropdownMenuItem(value: 'Semé', child: Text('Semé')),
                    DropdownMenuItem(value: 'En croissance', child: Text('En croissance')),
                    DropdownMenuItem(value: 'Récolté', child: Text('Récolté')),
                  ],
                  onChanged: (v) => _status = v ?? _status,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = _nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          await ApiService.addCrop(farmId: widget.farmId, cropName: name, status: _status);
                          Navigator.pop(context);
                          _refresh();
                        },
                        child: const Text('Ajouter la parcelle'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addFarmPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(maxWidth: 1600);
    if (picked == null || picked.isEmpty) return;
    setState(() => _loadingPhotos = true);
    try {
      for (final file in picked) {
        final url = await ApiService.uploadImageToCloudinary(file);
        if (url != null) {
          await ApiService.addFarmPhoto(farmId: widget.farmId, imageUrl: url);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photos ajoutées')));
      _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur ajout photos: $e')));
    } finally {
      if (mounted) setState(() => _loadingPhotos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parcelles'), actions: [
        IconButton(onPressed: _showAddParcel, icon: const Icon(Icons.add)),
        IconButton(onPressed: _addFarmPhotos, icon: _loadingPhotos ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.photo_library)),
      ]),
      body: FutureBuilder<List<dynamic>>(
        future: _parcelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
          final parcels = snapshot.data ?? [];
          if (parcels.isEmpty) return const Center(child: Text('Aucune parcelle trouvée'));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: parcels.length,
              itemBuilder: (context, index) {
                final p = parcels[index] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: FutureBuilder<List<dynamic>>(
                      future: ApiService.getActivitiesForCrop(p['id'] as int),
                      builder: (context, snap) {
                        // show small placeholder while loading
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: const Center(child: SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2))),
                          );
                        }

                        if (snap.hasError) {
                          return Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.grass, color: Color(0xFF6B8E23)),
                          );
                        }

                        if (snap.hasData && (snap.data?.isNotEmpty ?? false)) {
                          final activities = (snap.data! as List<dynamic>).cast<Map<String, dynamic>>();
                          // filter activities that have images
                          final withImages = activities.where((a) => ((a['image_urls'] as List?)?.isNotEmpty ?? false)).toList();
                          if (withImages.isNotEmpty) {
                            // pick the most recent activity by activity_date
                            withImages.sort((a, b) {
                              final da = DateTime.tryParse(a['activity_date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                              final db = DateTime.tryParse(b['activity_date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                              return db.compareTo(da);
                            });
                            final latest = withImages.first;
                            final imgUrl = (latest['image_urls'] as List).first as String;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(imgUrl, width: 56, height: 56, fit: BoxFit.cover),
                            );
                          }
                        }

                        // default placeholder
                        return Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.grass, color: Color(0xFF6B8E23)),
                        );
                      },
                    ),
                    title: Text(p['crop_name'] ?? 'Parcelle'),
                    subtitle: Text('Statut: ${p['status'] ?? ''} • Semé: ${p['planted_date'] ?? '-'}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ActivityScreen(farmId: widget.farmId, cropId: p['id'] as int, userId: widget.userId)),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.note_add_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ActivityScreen(farmId: widget.farmId, cropId: p['id'] as int, userId: widget.userId)),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
