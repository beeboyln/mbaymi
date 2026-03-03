# Quick Setup Guide - Livestock Management System

## What's Been Created

Created a complete individual animal management system with 4 new database tables and 30+ API endpoints:

- ✅ `animals` - Individual animal records
- ✅ `animal_health_records` - Vaccinations, treatments, checkups  
- ✅ `animal_reproduction` - Breeding, gestation, births
- ✅ `animal_production` - Milk, eggs, wool, meat tracking
- ✅ `animal_care_reminders` - Calendar of care tasks

## Files Created

**Backend**:
- `app/models/animal.py` - SQLAlchemy models with all relationships
- `app/schemas/animal_schemas.py` - Pydantic request/response schemas
- `app/routes/animals.py` - 30+ complete API endpoints  
- `sql/007_create_animal_management_system.sql` - Database migration
- `LIVESTOCK_MANAGEMENT_SYSTEM.md` - Full documentation

**Data Models** (Enums for type safety):
- `AnimalSpecies`: cattle, goat, sheep, pig, poultry, horse, donkey
- `AnimalGender`: male, female
- `HealthStatus`: healthy, sick, treated, vaccinated, isolated
- `ReproductiveStatus`: not_breeding, in_cycle, pregnant, lactating, weaned
- `MedicalType`: vaccination, deworming, treatment, checkup, surgery

## Step 1: Run Database Migration

```bash
# Using psql directly
psql -U postgres -d mbaymi < backend/sql/007_create_animal_management_system.sql

# Or (if using environment variables)
psql -U $DB_USER -d $DB_NAME < backend/sql/007_create_animal_management_system.sql
```

Verify tables were created:
```bash
psql -U postgres -d mbaymi
\dt animals
\dt animal_health_records
\dt animal_reproduction
\dt animal_production
\dt animal_care_reminders
```

## Step 2: Verify Routes Registered

```bash
cd backend
python -m uvicorn app.main:app --reload
```

Look for log output showing all `/api/animals` routes registered.

## Step 3: Create Your First Animal

```bash
# Using curl
curl -X POST http://localhost:8000/api/animals \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "Amina",
    "species": "cattle",
    "breed": "N'\''Dama",
    "gender": "female",
    "date_of_birth": "2020-03-15",
    "weight_kg": 450,
    "farm_id": 1,
    "location": "Northern Pasture"
  }'
```

## API Quick Reference

### Core Animals

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/animals` | POST | Create new animal |
| `/api/animals` | GET | List all animals (with filters) |
| `/api/animals/{id}` | GET | Get animal + all related records |
| `/api/animals/{id}` | PUT | Update animal |
| `/api/animals/{id}` | DELETE | Archive animal |

### Health Management

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/animals/{id}/health-records` | POST | Add vaccination/treatment |
| `/api/animals/{id}/health-records` | GET | List health records |
| `/api/animals/{id}/health-summary` | GET | Health overview (status, upcoming care) |

### Production Tracking

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/animals/{id}/production` | POST | Record milk/eggs/wool etc. |
| `/api/animals/{id}/production` | GET | List production records |
| `/api/animals/{id}/production/stats` | GET | Statistics (avg, min, max, timeline) |

### Reproduction

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/animals/{id}/reproduction` | POST | Record heat/mating/pregnancy/birth |
| `/api/animals/{id}/reproduction` | GET | List breeding events |
| `/api/animals/{id}/reproduction-summary` | GET | Breeding status overview |

### Care Reminders

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/animals/{id}/reminders` | POST | Create care task reminder |
| `/api/animals/{id}/reminders` | GET | List reminders (with filters) |
| `/api/animals/upcoming` | GET | Upcoming reminders (all animals) |
| `/api/reminders/{id}` | PATCH | Mark as completed |

## Example Workflows

### Workflow 1: Annual Vaccination Cycle

```bash
# 1. Create animal
POST /api/animals
{
  "name": "Bessie",
  "species": "cattle",
  "breed": "Holstein",
  "gender": "female",
  "date_of_birth": "2020-01-15"
}

# 2. Add vaccination record
POST /api/animals/1/health-records
{
  "record_type": "vaccination",
  "date": "2024-02-26",
  "medical_name": "FMD Vaccine",
  "dosage": "5ml",
  "administered_by": "Dr. Soumare",
  "next_due_date": "2025-02-26"
}

# 3. Create reminder for next year
POST /api/animals/1/reminders
{
  "title": "Annual FMD Vaccination",
  "tag": "health",
  "due_date": "2025-02-26",
  "is_recurring": true,
  "recurrence_interval": "yearly",
  "priority": "high"
}
```

### Workflow 2: Track Milk Production

```bash
# 1. Create dairy cow
POST /api/animals
{
  "name": "Nene",
  "species": "cattle",
  "breed": "Normande",
  "gender": "female",
  "date_of_birth": "2019-06-10"
}

# 2. Record daily milk production
POST /api/animals/2/production
{
  "date": "2024-02-26",
  "metric_type": "milk",
  "quantity": 18.5,
  "unit": "liters",
  "quality_grade": "A"
}

# 3. Get monthly statistics
GET /api/animals/2/production/stats?metric_type=milk&days=30

# Response:
{
  "total_quantity": 540,
  "average_per_day": 18,
  "best_day_quantity": 20.2,
  "worst_day_quantity": 15.5
}
```

### Workflow 3: Monitor Pregnancy

```bash
# 1. Record mating date
POST /api/animals/1/reproduction
{
  "event_type": "mating",
  "event_date": "2024-01-10",
  "partner_animal_id": 3
}

# 2. Record pregnancy confirmation
POST /api/animals/1/reproduction
{
  "event_type": "pregnancy",
  "event_date": "2024-01-25",
  "expected_delivery_date": "2024-10-25"
}

# 3. Get breeding status
GET /api/animals/1/reproduction-summary

# Response:
{
  "current_status": "pregnant",
  "last_breeding_date": "2024-01-10"
}

# 4. Record birth
POST /api/animals/1/reproduction
{
  "event_type": "birth",
  "event_date": "2024-10-25",
  "actual_delivery_date": "2024-10-25",
  "number_of_offspring": 1,
  "offspring_gender": "female"
}
```

## Frontend Integration Steps

### 1. Create Animal Service (Flutter)

```dart
class AnimalService {
  static Future<List<Animal>> getAnimals({int? farmId}) async {
    final response = await ApiService.get(
      '/api/animals',
      queryParams: {'farm_id': farmId},
    );
    return (response as List)
        .map((json) => Animal.fromJson(json))
        .toList();
  }
  
  static Future<Animal> createAnimal(String name, String species, DateTime dob) async {
    return await ApiService.post('/api/animals', {
      'name': name,
      'species': species,
      'gender': 'female',
      'date_of_birth': dob.toIso8601String(),
    });
  }
}
```

### 2. Create Animal Cards UI

- Display animal photo, name, species, age
- Quick access to: Health status, Last production, Upcoming care
- Tap to view detailed profile

### 3. Create Detailed Animal Screen

- Tabs: Overview | Health | Production | Reproduction | Reminders
- Each tab shows relevant data and allows adding new records

### 4. Add Reminder Notifications

- Daily check: `GET /api/animals/upcoming?days_ahead=1`
- Show in dashboard: "3 care tasks due today"

## Backward Compatibility

✅ Existing `livestock` table and group-based tracking **still works**
✅ Old endpoints for group animals remain functional
✅ Can run both systems in parallel during transition
✅ No breaking changes to existing API

## Troubleshooting

**Error: "relation 'animals' does not exist"**
→ Migration hasn't been run. Execute `007_create_animal_management_system.sql`

**404 on /api/animals**
→ Routes not registered. Ensure `animals.router` is included in `main.py`

**Foreign key errors**
→ Ensure `farms` and `users` tables exist and user_id/farm_id are valid

## Next: Frontend Development

Once backend is running:

1. Create `AnimalListScreen` - List all animals with filters
2. Create `AnimalDetailScreen` - Complete animal profile
3. Create `AddAnimalDialog` - Form to create new animal
4. Create `HealthRecordForm` - Add vaccinations/treatments
5. Create `ProductionRecordForm` - Daily/periodic production logging
6. Create `MonthlyDashboard` - Overview of farm's animals
7. Add `ReminderNotifications` - Push notifications for care tasks

See `LIVESTOCK_MANAGEMENT_SYSTEM.md` for complete implementation details.

## Support & Questions

- For schema questions: See `animal_schemas.py` for all field definitions
- For relation questions: See `animal.py` for relationship definitions  
- For endpoint specifics: See `animals.py` route file with full docstrings
- For usage examples: Check Swift examples above or `LIVESTOCK_MANAGEMENT_SYSTEM.md`
