# Système de Gestion des Animaux Individuels - Mbaymi Élevage

## Vue d'Ensemble

Le système de gestion des animaux individuels remplace le suivi par groupe avec un système complet de suivi animal à niveau individuel. Chaque animal a ses propres dossiers de santé, reproduction, production, et calendrier de soins.

## Architecture

### Modèles de Base de Données

```
animals (table principale)
├── animal_health_records (vaccinations, traitements)
├── animal_reproduction (cycles, gestations, naissances)
├── animal_production (lait, œufs, laine, viande, etc.)
└── animal_care_reminders (calendrier de soins)
```

### Entités Principales

#### 1. **Animal** (Enregistrement Individual)
- **Identité**: Nom, ID de tag (boucle), espèce, race
- **Attributs Physiques**: Poids, hauteur, marquages de couleur
- **Gestion**: Date d'acquisition, coût, localisation
- **Santé**: État sanitaire, notes, dernière visite
- **Reproduction**: État reproductif actuel

```json
{
  "id": 1,
  "user_id": 123,
  "farm_id": 5,
  "name": "Amina",
  "tag_id": "CATTLE-001",
  "species": "cattle",
  "breed": "N'Dama",
  "gender": "female",
  "date_of_birth": "2020-03-15",
  "weight_kg": 450,
  "health_status": "healthy",
  "reproductive_status": "lactating",
  "location": "Pâturage Nord",
  "is_active": true,
  "created_at": "2024-02-26T10:00:00",
  "updated_at": "2024-02-26T10:00:00"
}
```

#### 2. **Dossier de Santé** (AnimalHealthRecord)
- **Vaccinations**: Type, date, prochaine date
- **Traitements**: Nom, dosage, date
- **Visites Vétérinaires**: Checkups, observations
- **Coûts**: Frais vétérinaires

```json
{
  "id": 1,
  "animal_id": 1,
  "record_type": "vaccination",
  "date": "2024-02-20",
  "medical_name": "Vaccin FMD",
  "dosage": "5ml",
  "administered_by": "Dr. Diallo",
  "next_due_date": "2025-02-20",
  "cost": 2500
}
```

#### 3. **Suivi de Reproduction** (AnimalReproduction)
- **Événements**: Chaleurs, accouplement, gestation, mise bas
- **Dates**: Date de l'événement, date attendue/réelle de mise bas
- **Partenaire**: Animal partenaire ou nom externe
- **Descendance**: Nombre, sexe, santé des jeunes

```json
{
  "id": 1,
  "animal_id": 1,
  "event_type": "pregnancy",
  "event_date": "2024-01-15",
  "partner_animal_id": 5,
  "expected_delivery_date": "2024-10-15",
  "number_of_offspring": 2,
  "offspring_gender": "mixed"
}
```

#### 4. **Suivi de Production** (AnimalProduction)
- **Produits**: Lait, œufs, laine, viande
- **Métriques**: Quantité, unité, qualité
- **Historique**: Enregistrements quotidiens/périodiques

```json
{
  "id": 1,
  "animal_id": 1,
  "date": "2024-02-26",
  "metric_type": "milk",
  "quantity": 12.5,
  "unit": "liters",
  "quality_grade": "A"
}
```

#### 5. **Calendrier de Soins** (AnimalCareReminder)
- **Événements**: Vaccination, vermifugation, traitement, visite farrier
- **Planification**: Date due, fréquence (récurrent/unique)
- **Priorité**: Critique, haute, normale, basse
- **Statut**: Complété ou en attente

```json
{
  "id": 1,
  "animal_id": 1,
  "title": "Vaccination Annuelle",
  "tag": "health",
  "due_date": "2025-02-20",
  "is_recurring": true,
  "recurrence_interval": "yearly",
  "priority": "high",
  "is_completed": false
}
```

## API Endpoints

### Gestion des Animaux

#### Créer un nouvel animal
```
POST /api/animals
Content-Type: application/json
Authorization: Bearer {token}

{
  "name": "Amina",
  "species": "cattle",
  "breed": "N'Dama",
  "gender": "female",
  "date_of_birth": "2020-03-15",
  "weight_kg": 450,
  "farm_id": 5,
  "location": "Pâturage Nord"
}
```

#### Lister tous les animaux de l'utilisateur
```
GET /api/animals?farm_id=5&species=cattle&is_active=true
Authorization: Bearer {token}
```

#### Obtenir les détails complets d'un animal
```
GET /api/animals/{animal_id}
Authorization: Bearer {token}

Retourne:
- Données de l'animal
- Tous les dossiers de santé
- Historique de reproduction
- Records de production
- Reminders de soins
```

#### Mettre à jour un animal
```
PUT /api/animals/{animal_id}
Content-Type: application/json
Authorization: Bearer {token}

{
  "weight_kg": 460,
  "health_status": "vaccinated",
  "location": "Pâturage Sud"
}
```

#### Archiver un animal (soft delete)
```
DELETE /api/animals/{animal_id}
Authorization: Bearer {token}
```

### Dossiers de Santé

#### Ajouter un dossier de santé
```
POST /api/animals/{animal_id}/health-records
Content-Type: application/json
Authorization: Bearer {token}

{
  "record_type": "vaccination",
  "date": "2024-02-26",
  "medical_name": "Vaccin FMD",
  "dosage": "5ml",
  "administered_by": "Dr. Diallo",
  "next_due_date": "2025-02-26",
  "cost": 2500
}
```

#### Obtenir les dossiers de santé
```
GET /api/animals/{animal_id}/health-records?record_type=vaccination
Authorization: Bearer {token}
```

#### Résumé de santé
```
GET /api/animals/{animal_id}/health-summary
Authorization: Bearer {token}

Retourne:
{
  "current_health_status": "healthy",
  "total_health_records": 15,
  "last_checkup_date": "2024-02-20",
  "days_since_checkup": 6,
  "upcoming_care_count": 3,
  "overdue_care_count": 1,
  "recent_vaccinations": 5
}
```

### Suivi de Reproduction

#### Enregistrer un événement de reproduction
```
POST /api/animals/{animal_id}/reproduction
Content-Type: application/json
Authorization: Bearer {token}

{
  "event_type": "pregnancy",
  "event_date": "2024-01-15",
  "partner_animal_id": 5,
  "expected_delivery_date": "2024-10-15",
  "notes": "Première gestation"
}
```

#### Récupérer l'historique de reproduction
```
GET /api/animals/{animal_id}/reproduction
Authorization: Bearer {token}
```

#### Résumé de reproduction
```
GET /api/animals/{animal_id}/reproduction-summary
Authorization: Bearer {token}

Retourne:
{
  "current_status": "lactating",
  "total_offspring": 8,
  "last_breeding_date": "2024-01-15"
}
```

### Suivi de Production

#### Enregistrer une donnée de production
```
POST /api/animals/{animal_id}/production
Content-Type: application/json
Authorization: Bearer {token}

{
  "date": "2024-02-26",
  "metric_type": "milk",
  "quantity": 12.5,
  "unit": "liters",
  "quality_grade": "A"
}
```

#### Récupérer les records de production
```
GET /api/animals/{animal_id}/production?metric_type=milk&date_from=2024-02-01&date_to=2024-02-26
Authorization: Bearer {token}
```

#### Statistiques de production
```
GET /api/animals/{animal_id}/production/stats?metric_type=milk&days=30
Authorization: Bearer {token}

Retourne:
{
  "total_quantity": 375.5,
  "average_per_day": 12.5,
  "best_day_quantity": 14.2,
  "worst_day_quantity": 10.5,
  "best_day": "2024-02-15",
  "worst_day": "2024-02-22",
  "date_from": "2024-01-27",
  "date_to": "2024-02-26"
}
```

### Calendrier de Soins

#### Créer un reminder de soin
```
POST /api/animals/{animal_id}/reminders
Content-Type: application/json
Authorization: Bearer {token}

{
  "title": "Vaccination Annuelle",
  "tag": "health",
  "due_date": "2025-02-26",
  "is_recurring": true,
  "recurrence_interval": "yearly",
  "priority": "high"
}
```

#### Récupérer les reminders d'un animal
```
GET /api/animals/{animal_id}/reminders?is_completed=false&priority=high
Authorization: Bearer {token}
```

#### Récupérer les reminders à venir
```
GET /api/animals/upcoming?days_ahead=7
Authorization: Bearer {token}

Retourne tous les reminders des 7 prochains jours
```

#### Marquer un reminder comme complété
```
PATCH /api/reminders/{reminder_id}
Content-Type: application/json
Authorization: Bearer {token}

{
  "is_completed": true,
  "completed_date": "2024-02-26"
}
```

## Cas d'Utilisation en France

### Élevage de Bovins Laitiers (Normande, Holstein)
1. **Création**: Ajouter chaque vache avec poids, race, date de naissance
2. **Santé**: Vaccins (BVD, IBR), vermifugation, inspections vétérinaires
3. **Reproduction**: Cycles d'œstrus, insémination, gestation, mise bas
4. **Production**: Enregistrements de lait quotidiens (liters)
5. **Reminders**: Notifications pour vaccinations, traitements antiparasitaires, visites vétérinaires régulières

### Élevage de Chèvres (Saanen, Alpine)
1. **Création**: Enregistrer chaque chèvre avec race, sexe, DOB
2. **Santé**: Vaccins, contrôle parasitaire, traitement des mammites
3. **Reproduction**: Cycles de chaleur, période d'accouplement, lactation
4. **Production**: Enregistrements quotidiens de lait pour chaque chèvre
5. **Reminders**: Sevrage des jeunes, retour aux cycles de reproduction

### Élevage de Volailles (Poules, Canards)
1. **Création**: Enregistrer par groupe/enclos avec espèce, race
2. **Santé**: Vaccins aviaires, traitement parasitaire
3. **Production**: Enregistrements quotidiens d'œufs
4. **Reminders**: Changement de litière, inspections sanitaires

## Installation et Déploiement

### 1. Ajouter au Modèle SQLAlchemy
✅ Fichiers créés:
- `backend/app/models/animal.py` - Modèles SQLAlchemy
- `backend/app/schemas/animal_schemas.py` - Schémas Pydantic
- `backend/app/routes/animals.py` - Endpoints API
- `backend/sql/007_create_animal_management_system.sql` - Migration SQL

### 2. Exécuter la Migration

```bash
# Avec psql
psql -U utilisateur -d mbaymi < backend/sql/007_create_animal_management_system.sql

# Ou via Alembic (si disponible)
alembic upgrade head
```

### 3. Vérifier les Routes Enregistrées

```bash
python backend/app/main.py
# Chercher dans les logs pour confirmer tous les endpoints
# GET /api/animals
# POST /api/animals
# GET /api/animals/{animal_id}
# etc.
```

### 4. Tester les Endpoints

```bash
# Créer un animal
curl -X POST http://localhost:8000/api/animals \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bessie",
    "species": "cattle",
    "breed": "Holstein",
    "gender": "female",
    "date_of_birth": "2020-01-15",
    "farm_id": 1
  }'

# Lister les animaux
curl http://localhost:8000/api/animals?farm_id=1 \
  -H "Authorization: Bearer {token}"
```

## Frontend Integration (Flutter)

### 1. Créer l'écran de gestion des animaux

```dart
class AnimalManagementScreen extends StatefulWidget {
  final int farmId;
  const AnimalManagementScreen({required this.farmId});
  
  @override
  State<AnimalManagementScreen> createState() => _AnimalManagementScreenState();
}

class _AnimalManagementScreenState extends State<AnimalManagementScreen> {
  late Future<List<Animal>> _animalsFuture;
  
  @override
  void initState() {
    super.initState();
    _animalsFuture = ApiService.getAnimals(farmId: widget.farmId);
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Animal>>(
      future: _animalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final animals = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: animals.length,
          itemBuilder: (context, index) {
            final animal = animals[index];
            return _AnimalCard(animal: animal);
          },
        );
      },
    );
  }
}
```

### 2. Modèle Animal (Flutter)

```dart
class Animal {
  final int id;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final DateTime dateOfBirth;
  final double? weightKg;
  final String healthStatus;
  final String reproductiveStatus;
  final String location;
  
  Animal({
    required this.id,
    required this.name,
    required this.species,
    // ...
  });
  
  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'],
      name: json['name'],
      species: json['species'],
      breed: json['breed'],
      gender: json['gender'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      weightKg: json['weight_kg'],
      healthStatus: json['health_status'],
      reproductiveStatus: json['reproductive_status'],
      location: json['location'],
    );
  }
}
```

### 3. Service API (Flutter)

```dart
class AnimalService {
  static const String _baseUrl = '/api/animals';
  
  static Future<List<Animal>> getAnimals({
    int? farmId,
    String? species,
  }) async {
    final params = <String, dynamic>{
      if (farmId != null) 'farm_id': farmId,
      if (species != null) 'species': species,
    };
    
    final response = await ApiService.get(
      '$_baseUrl',
      queryParams: params,
    );
    
    return (response as List)
      .map((json) => Animal.fromJson(json))
      .toList();
  }
  
  static Future<AnimalDetailed> getAnimalDetails(int animalId) async {
    final response = await ApiService.get('$_baseUrl/$animalId');
    return AnimalDetailed.fromJson(response);
  }
  
  static Future<Animal> createAnimal(AnimalCreateRequest request) async {
    final response = await ApiService.post(_baseUrl, request.toJson());
    return Animal.fromJson(response);
  }
  
  static Future<void> addHealthRecord(
    int animalId,
    HealthRecordCreate record,
  ) async {
    await ApiService.post(
      '$_baseUrl/$animalId/health-records',
      record.toJson(),
    );
  }
  
  static Future<ProductionStatistic> getProductionStats(
    int animalId,
    String metricType, {
    int days = 30,
  }) async {
    final response = await ApiService.get(
      '$_baseUrl/$animalId/production/stats',
      queryParams: {'metric_type': metricType, 'days': days},
    );
    return ProductionStatistic.fromJson(response);
  }
}
```

## Avantages du Nouveau Système

✅ **Suivi Individual**: Chaque animal a son propre dossier médical et nutritionnel
✅ **Efficacité**: Rappels automatiques pour vaccinations et soins
✅ **Productions**: Graphiques et statistiques en temps réel
✅ **Reproductions**: Suivi des cycles, gestations, naissances
✅ **Coûts**: Enregistrement des dépenses vétérinaires par animal
✅ **Historique Complet**: Archive de tous les événements pour chaque animal
✅ **Conformité**: Documentation complète pour certifications (bio, etc.)

##$ Prochaines Étapes

1. **📱 Screen Animal Details**: Afficher fiche complète avec tous les records
2. **📊 Dashboard Livestock**: Overview santé, production, calendrier
3. **📈 Analytics**: Graphiques de production, tendances de santé
4. **🔔 Notifications**: Rappels push pour events importants
5. **📥 Import/Export**: CSV import pour migrations existantes
6. **🤖 IA Suggestions**: Recommandations basées sur patterns
