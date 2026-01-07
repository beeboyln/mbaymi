import 'package:flutter/material.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({Key? key}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _useLocation() {
    final lat = _latCtrl.text.trim();
    final lng = _lngCtrl.text.trim();
    if (lat.isEmpty || lng.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrez latitude et longitude')));
      return;
    }
    Navigator.pop(context, '$lat,$lng');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sélectionner la localisation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Entrez manuellement la latitude et la longitude, ou implémentez la carte plus tard.'),
            const SizedBox(height: 12),
            TextField(
              controller: _latCtrl,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lngCtrl,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _useLocation,
              icon: const Icon(Icons.check),
              label: const Text('Utiliser cette localisation'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
