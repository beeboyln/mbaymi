import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class EditFarmScreen extends StatefulWidget {
  final Map<String, dynamic> farm;
  final int? userId;

  const EditFarmScreen({Key? key, required this.farm, this.userId}) : super(key: key);

  @override
  State<EditFarmScreen> createState() => _EditFarmScreenState();
}

class _EditFarmScreenState extends State<EditFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _sizeCtrl;
  String _type = '🌱 Agricole';
  XFile? _profileFile;
  Uint8List? _profileBytes;
  List<XFile> _newPhotos = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.farm['name'] ?? '');
    _locationCtrl = TextEditingController(text: widget.farm['location'] ?? '');
    _sizeCtrl = TextEditingController(text: widget.farm['size_hectares']?.toString() ?? '');
    if ((widget.farm['soil_type'] ?? '').isNotEmpty) _type = widget.farm['soil_type'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfile() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (p == null) return;
    final b = await p.readAsBytes();
    setState(() {
      _profileFile = p;
      _profileBytes = b;
    });
  }

  Future<void> _pickNewPhotos() async {
    final picked = await ImagePicker().pickMultiImage(maxWidth: 1600);
    if (picked == null || picked.isEmpty) return;
    setState(() => _newPhotos.addAll(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? profileUrl = widget.farm['image_url'] ?? widget.farm['imageUrl'];
      if (_profileFile != null) {
        final u = await ApiService.uploadImageToCloudinary(_profileFile!);
        if (u != null) profileUrl = u;
      }

      final updated = await ApiService.updateFarm(
        farmId: widget.farm['id'] as int,
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        sizeHectares: _sizeCtrl.text.isNotEmpty ? double.tryParse(_sizeCtrl.text) : null,
        soilType: _type,
        imageUrl: profileUrl,
      );

      // Upload any new photos and attach
      for (final p in _newPhotos) {
        final u = await ApiService.uploadImageToCloudinary(p);
        if (u != null) await ApiService.addFarmPhoto(farmId: widget.farm['id'] as int, imageUrl: u);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ferme mise à jour')));
      Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = (widget.farm['photos'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Éditer la ferme')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom'), validator: (v) => (v==null||v.trim().isEmpty)?'Nom requis':null),
              const SizedBox(height: 12),
              TextFormField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Localisation')),
              const SizedBox(height: 12),
              TextFormField(controller: _sizeCtrl, decoration: const InputDecoration(labelText: 'Superficie (ha)'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: '🌱 Agricole', child: Text('🌱 Agricole')),
                  DropdownMenuItem(value: '🐄 Élevage', child: Text('🐄 Élevage')),
                  DropdownMenuItem(value: '🌾 Mixte', child: Text('🌾 Mixte')),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
                decoration: const InputDecoration(labelText: 'Type de ferme'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _profileBytes == null
                        ? _buildProfileDisplay()
                        : Stack(
                            children: [
                              Image.memory(_profileBytes!, height: 80, width: double.infinity, fit: BoxFit.cover),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _profileFile = null;
                                      _profileBytes = null;
                                    });
                                  },
                                  child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                                ),
                              ),
                            ],
                          ),
                  ),
                  TextButton.icon(onPressed: _pickProfile, icon: const Icon(Icons.photo), label: const Text('Changer photo')),
                ],
              ),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: const Text('Galerie existante')),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: photos.map<Widget>((p) {
                    final id = p is Map ? p['id'] : null;
                    final url = p is Map ? p['image_url'] : p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, width: 120, height: 80, fit: BoxFit.cover)),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Supprimer la photo'),
                                    content: const Text('Supprimer cette photo de la galerie ?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                                    ],
                                  ),
                                );
                                if (ok == true && id != null) {
                                  try {
                                    await ApiService.deleteFarmPhoto(farmId: widget.farm['id'] as int, photoId: id as int);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo supprimée')));
                                    // Refresh the screen by popping and returning an update, or simply reload
                                    final updated = await ApiService.getFarm(widget.farm['id'] as int);
                                    if (!mounted) return;
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => EditFarmScreen(farm: updated, userId: widget.userId)));
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.delete, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () async {
                                        try {
                                          final farmId = widget.farm['id'] as int;
                                          final name = widget.farm['name'] ?? '';
                                          final location = widget.farm['location'] ?? '';
                                          final sizeVal = widget.farm['size_hectares'];
                                          final size = sizeVal != null ? double.tryParse(sizeVal.toString()) : null;
                                          final soil = widget.farm['soil_type'] ?? widget.farm['soilType'];
                                          final updated = await ApiService.updateFarm(
                                            farmId: farmId,
                                            name: name,
                                            location: location,
                                            sizeHectares: size,
                                            soilType: soil,
                                            imageUrl: url,
                                          );
                                          // Update local farm map and UI
                                          widget.farm['image_url'] = url;
                                          widget.farm['imageUrl'] = url;
                                          setState(() {
                                            _profileBytes = null;
                                            _profileFile = null;
                                          });
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo définie comme profil')));
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.person, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _pickNewPhotos, icon: const Icon(Icons.photo_library), label: const Text('Ajouter des photos')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _loading?null:_save, child: _loading?const CircularProgressIndicator():const Text('Enregistrer')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDisplay() {
    final url = (widget.farm['photos'] != null && (widget.farm['photos'] as List).isNotEmpty) ? (widget.farm['photos'] as List).first : (widget.farm['image_url'] ?? widget.farm['imageUrl']);
    if (url == null) return const Text('Aucune image');
    return Stack(
      children: [
        Image.network(url, height: 80, width: double.infinity, fit: BoxFit.cover),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Supprimer la photo de profil'),
                  content: const Text('Voulez-vous supprimer la photo de profil de cette ferme ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                  ],
                ),
              );
              if (ok == true) {
                try {
                  await ApiService.deleteFarmProfilePhoto(farmId: widget.farm['id'] as int);
                  // Update local farm map
                  widget.farm['image_url'] = null;
                  widget.farm['imageUrl'] = null;
                  setState(() {
                    _profileBytes = null;
                    _profileFile = null;
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo de profil supprimée')));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
                }
              }
            },
            child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete, color: Colors.white, size: 16)),
          ),
        ),
      ],
    );
  }

  Widget profileImageWidget(Map<String, dynamic> farm) {
    final url = (farm['photos'] != null && (farm['photos'] as List).isNotEmpty) ? (farm['photos'] as List).first : (farm['image_url'] ?? farm['imageUrl']);
    if (url == null) return const Expanded(child: Text('Aucune image'));
    return Expanded(child: Image.network(url, height: 80));
  }
}
