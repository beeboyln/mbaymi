import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ActivityScreen extends StatefulWidget {
  final int farmId;
  final int cropId;
  final int userId;

  const ActivityScreen({Key? key, required this.farmId, required this.cropId, required this.userId}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _typeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _date;
  bool _loading = false;
  List<XFile> _imageFiles = [];
  List<Uint8List> _imageBytes = [];
  late Future<List<dynamic>> _activitiesFuture;

  @override
  void dispose() {
    _typeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _activitiesFuture = ApiService.getActivitiesForFarm(widget.farmId);
  }

  Future<void> _refreshActivities() async {
    setState(() {
      _activitiesFuture = ApiService.getActivitiesForCrop(widget.cropId);
    });
  }

  Future<void> _submit() async {
    if (_typeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      // If images selected, upload them first
      List<String> uploadedUrls = [];
      for (final f in _imageFiles) {
        final url = await ApiService.uploadImageToCloudinary(f);
        if (url != null) uploadedUrls.add(url);
      }

      await ApiService.createActivity(
        farmId: widget.farmId,
        cropId: widget.cropId,
        userId: widget.userId,
        activityType: _typeCtrl.text.trim(),
        activityDate: _date,
        notes: _notesCtrl.text.trim(),
        imageUrls: uploadedUrls,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activité enregistrée')));
        Navigator.pop(context);
      }
      // Refresh activities after submit
      await _refreshActivities();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(maxWidth: 1600);
    if (picked == null || picked.isEmpty) return;
    final bytesList = <Uint8List>[];
    for (final p in picked) {
      final b = await p.readAsBytes();
      bytesList.add(b);
    }
    setState(() {
      _imageFiles.addAll(picked);
      _imageBytes.addAll(bytesList);
    });
  }

  Widget _buildActivityCard(Map<String, dynamic> a) {
    final imgs = (a['image_urls'] as List?) ?? [];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(a['activity_type'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(a['activity_date'] != null ? DateTime.tryParse(a['activity_date'].toString())?.toLocal().toString().split('.')[0] ?? '' : '' , style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            if ((a['notes'] ?? '').toString().isNotEmpty) Text(a['notes'] ?? ''),
            if (imgs.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: imgs.map<Widget>((u) => Padding(padding: const EdgeInsets.only(right:8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(u, width: 120, height: 80, fit: BoxFit.cover)))).toList(),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une activité')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Type d\'activité (labour, arrosage...)')),
            const SizedBox(height: 8),
            // Image previews
            if (_imageBytes.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageBytes.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.memory(_imageBytes[i], width: 80, height: 80, fit: BoxFit.cover),
                  ),
                ),
              ),
            Row(
              children: [
                TextButton.icon(onPressed: _pickImages, icon: const Icon(Icons.photo_library_outlined), label: const Text('Ajouter photos')),
              ],
            ),
            TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(_date == null ? 'Date non sélectionnée' : _date.toString()),
                const Spacer(),
                TextButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d!=null) setState(()=>_date=d); }, child: const Text('Choisir la date')),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('Enregistrer l\'activité'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
