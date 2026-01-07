import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/map_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class CreateFarmScreen extends StatefulWidget {
  final int? userId;

  const CreateFarmScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _regionCtrl = TextEditingController();
  final TextEditingController _departmentCtrl = TextEditingController();
  final TextEditingController _communeCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _sizeCtrl = TextEditingController();
  String _type = '🌱 Agricole';
  String? _location;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    _departmentCtrl.dispose();
    _communeCtrl.dispose();
    _descCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _location = result);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (picked != null) {
      // Read bytes so we can preview immediately (works on web and mobile)
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur non connecté')));
      return;
    }

    setState(() => _loading = true);
    try {
      String? uploadedUrl;
      double? lat;
      double? lng;
      if (_imageFile != null) {
        // Read bytes for preview and upload (works on web and mobile)
        _imageBytes = await _imageFile!.readAsBytes();
        // Upload to Cloudinary; throw if upload fails so we can show an error
        final url = await ApiService.uploadImageToCloudinary(_imageFile!);
        if (url == null) throw Exception('Échec de l\'upload de l\'image');
        uploadedUrl = url;
      }
      if (_location != null && _location!.contains(',')) {
        final parts = _location!.split(',');
        lat = double.tryParse(parts[0]);
        lng = double.tryParse(parts[1]);
      }
      final res = await ApiService.createFarm(
        userId: widget.userId!,
        name: _nameCtrl.text.trim(),
        location: _location ?? '${_regionCtrl.text} / ${_communeCtrl.text}',
        sizeHectares: _sizeCtrl.text.isNotEmpty ? double.tryParse(_sizeCtrl.text) : null,
        soilType: _type,
        imageUrl: uploadedUrl,
        latitude: lat,
        longitude: lng,
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ferme créée')));
      Navigator.pop(context, res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une ferme'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom de la ferme'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
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
              TextFormField(
                controller: _regionCtrl,
                decoration: const InputDecoration(labelText: 'Région'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentCtrl,
                decoration: const InputDecoration(labelText: 'Département'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _communeCtrl,
                decoration: const InputDecoration(labelText: 'Commune / Village'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description courte'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizeCtrl,
                decoration: const InputDecoration(labelText: 'Superficie (hectares)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(_location == null ? 'Localisation non sélectionnée' : _location!),
                  ),
                  TextButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Sélectionner sur la carte'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _imageBytes == null
                      ? const Expanded(child: Text('Aucune image sélectionnée'))
                      : Expanded(child: Image.memory(_imageBytes!, height: 80)),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Ajouter une photo'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const CircularProgressIndicator() : const Text('Créer la ferme'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
