import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';

class ServiceRequestCreationScreen extends StatefulWidget {
  final int? animalId;
  final int? cropId;

  const ServiceRequestCreationScreen({
    Key? key,
    this.animalId,
    this.cropId,
  }) : super(key: key);

  @override
  State<ServiceRequestCreationScreen> createState() =>
      _ServiceRequestCreationScreenState();
}

class _ServiceRequestCreationScreenState
    extends State<ServiceRequestCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _symptomsController = TextEditingController();

  String _serviceType = 'animal_problem';
  String _priority = 'medium';

  static const Color _primaryColor = Colors.brown;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.createServiceRequest(
        serviceType: _serviceType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        symptoms: _symptomsController.text.trim().isEmpty
            ? null
            : _symptomsController.text.trim(),
        animalId: _serviceType == 'animal_problem' ? widget.animalId : null,
        cropId: _serviceType == 'crop_problem' ? widget.cropId : null,
        priority: _priority,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande créée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      border: const UnderlineInputBorder(),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE8E2D8)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        foregroundColor: textColor,
        title: const Text(
          'Nouvelle Demande',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Service Type Selection
                Text(
                  'Type de demande',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'animal_problem',
                      label: Text('Animal'),
                    ),
                    ButtonSegment<String>(
                      value: 'crop_problem',
                      label: Text('Culture'),
                    ),
                    ButtonSegment<String>(
                      value: 'general_advice',
                      label: Text('Conseil'),
                    ),
                  ],
                  selected: <String>{_serviceType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _serviceType = newSelection.first);
                  },
                ),
                const SizedBox(height: 32),

                // Title
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Titre'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Titre requis' : null,
                ),
                const SizedBox(height: 24),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(color: textColor),
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Description du problème',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE8E2D8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE8E2D8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: _primaryColor),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Description requise' : null,
                ),
                const SizedBox(height: 24),

                // Symptoms (optional)
                TextFormField(
                  controller: _symptomsController,
                  style: TextStyle(color: textColor),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Symptômes observés (optionnel)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE8E2D8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE8E2D8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: _primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Priority
                Text(
                  'Priorité',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _priority,
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Priorité'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Basse')),
                    DropdownMenuItem(value: 'medium', child: Text('Moyen')),
                    DropdownMenuItem(value: 'high', child: Text('Haute')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'CRÉER LA DEMANDE',
                            style: TextStyle(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
