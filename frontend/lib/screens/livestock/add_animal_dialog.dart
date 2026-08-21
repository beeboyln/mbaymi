/// Add Animal Dialog - Create new animal
library;
import 'package:flutter/material.dart';
import 'package:mbaymi/models/animal.dart';
import 'package:mbaymi/services/animal_service.dart';

class AddAnimalDialog extends StatefulWidget {
  final int? farmId;
  final Function(Animal) onAnimalAdded;

  const AddAnimalDialog({
    super.key,
    this.farmId,
    required this.onAnimalAdded,
  });

  @override
  State<AddAnimalDialog> createState() => _AddAnimalDialogState();
}

class _AddAnimalDialogState extends State<AddAnimalDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _tagController;
  late final TextEditingController _weightController;
  late final TextEditingController _breedController;
  late final TextEditingController _locationController;

  String _selectedSpecies = 'cattle';
  String _selectedGender = 'male';
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  static const List<String> _species = [
    'cattle',
    'goat',
    'sheep',
    'pig',
    'poultry',
    'horse',
    'donkey',
  ];

  static const List<String> _genders = ['male', 'female'];

  String _getSpeciesDisplay(String species) {
    switch (species) {
      case 'cattle':
        return 'Bovins';
      case 'goat':
        return 'Chèvres';
      case 'sheep':
        return 'Moutons';
      case 'pig':
        return 'Porcs';
      case 'poultry':
        return 'Volailles';
      case 'horse':
        return 'Chevaux';
      case 'donkey':
        return 'Ânes';
      default:
        return species;
    }
  }

  String _getGenderDisplay(String gender) {
    return gender == 'male' ? 'Mâle' : 'Femelle';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _tagController = TextEditingController();
    _weightController = TextEditingController();
    _breedController = TextEditingController();
    _locationController = TextEditingController();
    _selectedBirthDate = DateTime.now().subtract(const Duration(days: 365));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _selectBirthDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() => _selectedBirthDate = selected);
    }
  }

  void _submitForm() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le nom de l\'animal')),
      );
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la date de naissance')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final animal = await AnimalService.createAnimal(
        name: _nameController.text,
        species: _selectedSpecies,
        gender: _selectedGender,
        dateOfBirth: _selectedBirthDate!,
        tagId: _tagController.text.isEmpty ? null : _tagController.text,
        breed: _breedController.text.isEmpty ? null : _breedController.text,
        weightKg: _weightController.text.isEmpty ? null : double.parse(_weightController.text),
        location: _locationController.text.isEmpty ? null : _locationController.text,
        farmId: widget.farmId,
      );

      widget.onAnimalAdded(animal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal créé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Ajouter un nouvel animal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Required fields section
              const Text(
                'Informations requises',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              // Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'animal',
                  hintText: 'Ex: Lola, Bessie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Species
              DropdownButtonFormField<String>(
                initialValue: _selectedSpecies,
                decoration: InputDecoration(
                  labelText: 'Espèce',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _species.map((species) {
                  return DropdownMenuItem(
                    value: species,
                    child: Text(_getSpeciesDisplay(species)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSpecies = value);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Gender
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Sexe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _genders.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(_getGenderDisplay(gender)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Birth date
              GestureDetector(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de naissance',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedBirthDate != null
                        ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                        : 'Sélectionner une date',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Optional fields section
              const Text(
                'Informations optionnelles',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              // Tag/ID
              TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  labelText: 'Identifiant (puce, collier)',
                  hintText: 'Ex: EAR-001',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Breed
              TextField(
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: 'Race',
                  hintText: 'Ex: Holstein, Normande',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Weight
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Poids (kg)',
                  hintText: 'Ex: 500',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Location
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Emplacement',
                  hintText: 'Ex: Enclos A, Étable 1',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ajouter l\'animal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
