/// Animal List Screen - Display all animals with filters and actions
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/models/animal.dart';
import 'package:mbaymi/services/animal_service.dart';
import 'package:mbaymi/widgets/app_button.dart';
import 'package:mbaymi/screens/livestock/animal_detail_screen.dart';
import 'package:mbaymi/screens/livestock/add_animal_dialog.dart';

class AnimalListScreen extends StatefulWidget {
  final int? farmId;

  const AnimalListScreen({
    super.key,
    this.farmId,
  });

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  late Future<List<Animal>> _animals;
  String _selectedSpecies = 'all';
  bool _showOnlyActive = true;

  static const List<String> _speciesOptions = [
    'all',
    'cattle',
    'goat',
    'sheep',
    'pig',
    'poultry',
    'horse',
    'donkey',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  void _loadAnimals() {
    setState(() {
      _animals = AnimalService.getAnimals(
        farmId: widget.farmId,
        species: _selectedSpecies == 'all' ? null : _selectedSpecies,
        isActive: _showOnlyActive ? true : null,
      );
    });
  }

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

  String _getHealthStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return '✓ Sain';
      case 'sick':
        return '⚠ Malade';
      case 'treated':
        return '→ Traité';
      case 'vaccinated':
        return '✓ Vacciné';
      case 'isolated':
        return '⌀ Isolé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Animaux'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnimals,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Species filter
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSpecies,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSpecies = value);
                      _loadAnimals();
                    }
                  },
                  items: _speciesOptions.map((species) {
                    final display = species == 'all' ? 'Toutes les espèces' : _getSpeciesDisplay(species);
                    return DropdownMenuItem(
                      value: species,
                      child: Text(display),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Show active toggle
                CheckboxListTile(
                  title: const Text('Afficher uniquement les animaux actifs'),
                  value: _showOnlyActive,
                  onChanged: (value) {
                    setState(() => _showOnlyActive = value ?? true);
                    _loadAnimals();
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          // Animal list
          Expanded(
            child: FutureBuilder<List<Animal>>(
              future: _animals,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAnimals,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final animals = snapshot.data ?? [];
                if (animals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pets, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Aucun animal trouvé'),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddAnimalDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un animal'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return _buildAnimalCard(context, animal);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAnimalDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel animal'),
      ),
    );
  }

  Widget _buildAnimalCard(BuildContext context, Animal animal) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnimalDetailScreen(
              animal: animal,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and ID
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (animal.tagId != null)
                          Text(
                            'ID: ${animal.tagId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getSpeciesDisplay(animal.species),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${animal.ageInYears} an${animal.ageInYears == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  if (animal.weightKg != null)
                    Text(
                      '${animal.weightKg} kg',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  Flexible(
                    child: Text(
                      _getHealthStatusColor(animal.healthStatus),
                      style: TextStyle(
                        fontSize: 12,
                        color: animal.healthStatus == 'healthy'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (animal.location != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Emplacement: ${animal.location}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAnimalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddAnimalDialog(
        farmId: widget.farmId,
        onAnimalAdded: (_) {
          _loadAnimals();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
