/// Animal Detail Screen - Complete profile with tabs
library;
import 'package:flutter/material.dart';
import 'package:mbaymi/models/animal.dart';
import 'package:mbaymi/screens/livestock/animal_health_tab.dart';
import 'package:mbaymi/screens/livestock/animal_production_tab.dart';
import 'package:mbaymi/screens/livestock/animal_reproduction_tab.dart';
import 'package:mbaymi/screens/livestock/animal_reminders_tab.dart';
import 'package:mbaymi/services/animal_service.dart';
import 'package:mbaymi/services/traceability_export_service.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;

  const AnimalDetailScreen({
    super.key,
    required this.animal,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Animal _currentAnimal;
  final bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentAnimal = widget.animal;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getSpeciesDisplay(String species) {
    switch (species) {
      case 'cattle':
        return 'Bovin';
      case 'goat':
        return 'Chèvre';
      case 'sheep':
        return 'Mouton';
      case 'pig':
        return 'Porc';
      case 'poultry':
        return 'Volaille';
      case 'horse':
        return 'Cheval';
      case 'donkey':
        return 'Âne';
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
    final now = DateTime.now();
    final ageMonths = (now.year - _currentAnimal.dateOfBirth.year) * 12 +
        (now.month - _currentAnimal.dateOfBirth.month);
    final ageYears = ageMonths ~/ 12;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAnimal.name),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Télécharger la traçabilité',
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportTraceability,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile header
          Container(
            color: Colors.blue.withOpacity(0.05),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and ID row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentAnimal.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_currentAnimal.tagId != null)
                            Text(
                              'ID: ${_currentAnimal.tagId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getSpeciesDisplay(_currentAnimal.species),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Info grid
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  childAspectRatio: 1.2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _buildInfoCard('Âge', '$ageYears ans'),
                    _buildInfoCard(
                      'Poids',
                      _currentAnimal.weightKg != null
                          ? '${_currentAnimal.weightKg} kg'
                          : '—',
                    ),
                    _buildInfoCard(
                      'Sexe',
                      _currentAnimal.gender == 'male' ? 'M' : 'F',
                    ),
                    _buildInfoCard('Statut', _getHealthStatusDisplay(_currentAnimal.healthStatus)),
                  ],
                ),
              ],
            ),
          ),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.medical_services), text: 'Santé'),
              Tab(icon: Icon(Icons.trending_up), text: 'Production'),
              Tab(icon: Icon(Icons.favorite), text: 'Reproduction'),
              Tab(icon: Icon(Icons.alarm), text: 'Tâches'),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Health tab
                AnimalHealthTab(
                  animalId: _currentAnimal.id,
                ),
                // Production tab
                AnimalProductionTab(
                  animalId: _currentAnimal.id,
                  animalSpecies: _currentAnimal.species,
                ),
                // Reproduction tab
                AnimalReproductionTab(
                  animalId: _currentAnimal.id,
                  animalGender: _currentAnimal.gender,
                ),
                // Reminders tab
                AnimalRemindersTab(
                  animalId: _currentAnimal.id,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getHealthStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return 'Sain';
      case 'sick':
        return 'Malade';
      case 'treated':
        return 'Traité';
      case 'vaccinated':
        return 'Vacciné';
      case 'isolated':
        return 'Isolé';
      default:
        return status;
    }
  }

  Future<void> _exportTraceability() {
    return TraceabilityExportService.showExportMenu(
      context: context,
      title: _currentAnimal.name,
      loadSections: () async {
        final healthSummary = await AnimalService.getHealthSummary(_currentAnimal.id);
        final healthRecords = await AnimalService.getHealthRecords(_currentAnimal.id);
        final productionRecords = await AnimalService.getProductionRecords(_currentAnimal.id);
        final reproductionRecords = await AnimalService.getReproductionRecords(_currentAnimal.id);
        final reminders = await AnimalService.getCareReminders(_currentAnimal.id);

        return [
          TraceabilitySection(
            title: 'Profil de l’animal',
            rows: [
              {'Nom': _currentAnimal.name},
              {'Espèce': _getSpeciesDisplay(_currentAnimal.species)},
              {'Sexe': _currentAnimal.gender == 'male' ? 'Mâle' : 'Femelle'},
              {'Date de naissance': _currentAnimal.dateOfBirth.toIso8601String().split('T')[0]},
              {'Statut de santé': _getHealthStatusDisplay(_currentAnimal.healthStatus)},
              if (_currentAnimal.tagId != null) {'Identifiant': _currentAnimal.tagId},
              if (_currentAnimal.breed != null) {'Race': _currentAnimal.breed},
              if (_currentAnimal.location != null) {'Localisation': _currentAnimal.location},
            ],
          ),
          TraceabilitySection(
            title: 'Résumé de santé',
            rows: [
              {'Animal': healthSummary.animalName},
              {'Statut': _getHealthStatusDisplay(healthSummary.currentHealthStatus)},
              {'Dossiers de santé': healthSummary.totalHealthRecords},
              {'Dernière visite': healthSummary.lastCheckupDate != null ? healthSummary.lastCheckupDate!.toIso8601String().split('T')[0] : 'Aucune'},
              {'Rappels à venir': healthSummary.upcomingCareCount},
              {'Rappels en retard': healthSummary.overdueCareCount},
            ],
          ),
          if (healthRecords.isNotEmpty)
            TraceabilitySection(
              title: 'Suivi médical',
              rows: healthRecords.map((record) => {
                'Date': record.date.toIso8601String().split('T')[0],
                'Type': record.recordType,
                'Traitement': record.medicalName,
                if (record.description != null) 'Description': record.description,
                if (record.dosage != null) 'Dosage': record.dosage,
                if (record.cost != null) 'Coût': record.cost,
              }).toList(),
            ),
          if (productionRecords.isNotEmpty)
            TraceabilitySection(
              title: 'Production',
              rows: productionRecords.map((record) => {
                'Date': record.date.toIso8601String().split('T')[0],
                'Type': record.metricType,
                'Quantité': '${record.quantity} ${record.unit}',
                if (record.qualityGrade != null) 'Qualité': record.qualityGrade,
                if (record.notes != null) 'Notes': record.notes,
              }).toList(),
            ),
          if (reproductionRecords.isNotEmpty)
            TraceabilitySection(
              title: 'Reproduction',
              rows: reproductionRecords.map((record) => {
                'Date': record.eventDate.toIso8601String().split('T')[0],
                'Événement': record.eventType,
                if (record.partnerName != null) 'Partenaire': record.partnerName,
                if (record.numberOfOffspring != null) 'Nombre de petits': record.numberOfOffspring,
                if (record.notes != null) 'Notes': record.notes,
              }).toList(),
            ),
          if (reminders.isNotEmpty)
            TraceabilitySection(
              title: 'Rappels de soins',
              rows: reminders.map((reminder) => {
                'Titre': reminder.title,
                'Date': reminder.dueDate.toIso8601String().split('T')[0],
                'Priorité': reminder.priority,
                'Statut': reminder.isCompleted ? 'Terminé' : 'À faire',
                if (reminder.description != null) 'Description': reminder.description,
              }).toList(),
            ),
        ];
      },
    );
  }
}
