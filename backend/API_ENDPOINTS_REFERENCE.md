# API Endpoints Reference - Livestock Management

## Authentication
All endpoints require `Authorization: Bearer {token}` header and `user_id` parameter

## ANIMALS - Core Management

### CREATE ANIMAL
```
POST /api/animals
Authorization: Bearer {token}

Request Body:
{
  "name": "Amina",                          # Required
  "tag_id": "CATTLE-001",                   # Optional, unique
  "species": "cattle",                      # Required: cattle|goat|sheep|pig|poultry|horse|donkey
  "breed": "N'Dama",                        # Optional
  "gender": "female",                       # Required: male|female
  "date_of_birth": "2020-03-15",            # Required: YYYY-MM-DD
  "weight_kg": 450,                         # Optional
  "height_cm": 150,                         # Optional
  "color_markings": "Brown with white",     # Optional
  "health_status": "healthy",               # Optional: healthy|sick|treated|vaccinated|isolated
  "health_notes": "No issues",              # Optional
  "reproductive_status": "not_breeding",    # Optional
  "acquisition_date": "2020-03-15",         # Optional
  "acquisition_cost": 500000,               # Optional (in currency)
  "location": "Northern Pasture",           # Optional
  "photo_url": "https://...",               # Optional
  "farm_id": 5                              # Optional
}

Response: 201 Created
{
  "id": 1,
  "user_id": 123,
  "farm_id": 5,
  "name": "Amina",
  ...
  "created_at": "2024-02-26T10:00:00",
  "updated_at": "2024-02-26T10:00:00"
}
```

### LIST ANIMALS
```
GET /api/animals?farm_id=5&species=cattle&is_active=true
Authorization: Bearer {token}

Query Parameters:
- farm_id (optional): Filter by farm
- species (optional): Filter by species (cattle|goat|sheep|pig|poultry|horse|donkey)
- is_active (optional): true|false

Response: 200 OK
[
  {
    "id": 1,
    "name": "Amina",
    "species": "cattle",
    ...
  }
]
```

### GET ANIMAL DETAILS
```
GET /api/animals/{animal_id}
Authorization: Bearer {token}

Path Parameters:
- animal_id (required): ID of animal

Response: 200 OK
{
  "id": 1,
  "name": "Amina",
  "species": "cattle",
  ...
  "health_records": [...],
  "reproduction_records": [...],
  "production_records": [...],
  "care_reminders": [...]
}
```

### UPDATE ANIMAL
```
PUT /api/animals/{animal_id}
Authorization: Bearer {token}

Request Body (all optional):
{
  "name": "Amina Updated",
  "weight_kg": 460,
  "health_status": "vaccinated",
  "reproductive_status": "lactating",
  "location": "Southern Pasture",
  "is_active": true
}

Response: 200 OK
{...updated animal...}
```

### DELETE ANIMAL (Soft Delete)
```
DELETE /api/animals/{animal_id}
Authorization: Bearer {token}

Response: 204 No Content
(Sets is_active to false, no data deleted)
```

---

## HEALTH RECORDS - Vaccinations & Treatments

### ADD HEALTH RECORD
```
POST /api/animals/{animal_id}/health-records
Authorization: Bearer {token}

Request Body:
{
  "record_type": "vaccination",                # Required: vaccination|deworming|treatment|checkup|surgery
  "date": "2024-02-26",                        # Required: YYYY-MM-DD
  "medical_name": "FMD Vaccine",               # Required
  "description": "Annual FMD vaccination",     # Optional
  "dosage": "5ml",                             # Optional
  "administered_by": "Dr. Soumare",            # Optional
  "cost": 2500,                                # Optional
  "next_due_date": "2025-02-26",               # Optional: for recurring treatments
  "notes": "Administered in left shoulder"     # Optional
}

Response: 201 Created
{
  "id": 1,
  "animal_id": {animal_id},
  "record_type": "vaccination",
  "date": "2024-02-26",
  ...
}
```

### GET HEALTH RECORDS
```
GET /api/animals/{animal_id}/health-records?record_type=vaccination
Authorization: Bearer {token}

Query Parameters:
- record_type (optional): vaccination|deworming|treatment|checkup|surgery

Response: 200 OK
[
  {
    "id": 1,
    "animal_id": {animal_id},
    "record_type": "vaccination",
    "medical_name": "FMD Vaccine",
    ...
  }
]
```

### GET HEALTH SUMMARY
```
GET /api/animals/{animal_id}/health-summary
Authorization: Bearer {token}

Response: 200 OK
{
  "animal_id": 1,
  "animal_name": "Amina",
  "current_health_status": "healthy",
  "total_health_records": 15,
  "last_checkup_date": "2024-02-20T00:00:00",
  "days_since_checkup": 6,
  "upcoming_care_count": 3,
  "overdue_care_count": 1,
  "recent_vaccinations": 5
}
```

### DELETE HEALTH RECORD
```
DELETE /api/health-records/{record_id}
Authorization: Bearer {token}

Response: 204 No Content
```

---

## PRODUCTION - Milk, Eggs, Wool, etc.

### ADD PRODUCTION RECORD
```
POST /api/animals/{animal_id}/production
Authorization: Bearer {token}

Request Body:
{
  "date": "2024-02-26",                   # Required: YYYY-MM-DD
  "metric_type": "milk",                  # Required: milk|eggs|wool|meat|etc.
  "quantity": 12.5,                       # Required: positive number
  "unit": "liters",                       # Required: liters|kg|units|etc.
  "quality_grade": "A",                   # Optional: A|B|C|etc.
  "notes": "From morning milking"         # Optional
}

Response: 201 Created
{
  "id": 1,
  "animal_id": {animal_id},
  "date": "2024-02-26",
  "metric_type": "milk",
  "quantity": 12.5,
  "unit": "liters",
  ...
}
```

### GET PRODUCTION RECORDS
```
GET /api/animals/{animal_id}/production?metric_type=milk&date_from=2024-02-01&date_to=2024-02-26
Authorization: Bearer {token}

Query Parameters:
- metric_type (optional): milk|eggs|wool|meat|etc.
- date_from (optional): YYYY-MM-DD
- date_to (optional): YYYY-MM-DD

Response: 200 OK
[
  {
    "id": 1,
    "animal_id": {animal_id},
    "date": "2024-02-26",
    "metric_type": "milk",
    "quantity": 12.5,
    "unit": "liters"
  }
]
```

### GET PRODUCTION STATISTICS
```
GET /api/animals/{animal_id}/production/stats?metric_type=milk&days=30
Authorization: Bearer {token}

Query Parameters:
- metric_type (required): milk|eggs|wool|meat|etc.
- days (optional, default 30): Number of days to analyze

Response: 200 OK
{
  "animal_id": 1,
  "animal_name": "Amina",
  "metric_type": "milk",
  "total_quantity": 375.5,
  "average_per_day": 12.5,
  "unit": "liters",
  "best_day_quantity": 14.2,
  "worst_day_quantity": 10.5,
  "best_day": "2024-02-15",
  "worst_day": "2024-02-22",
  "date_from": "2024-01-27",
  "date_to": "2024-02-26"
}
```

---

## REPRODUCTION - Breeding, Pregnancy, Birth

### ADD REPRODUCTION EVENT
```
POST /api/animals/{animal_id}/reproduction
Authorization: Bearer {token}

Request Body:
{
  "event_type": "pregnancy",                   # Required: heat|mating|pregnancy|birth
  "event_date": "2024-01-15",                  # Required: YYYY-MM-DD
  "partner_animal_id": 5,                      # Optional: ID of sire/dam
  "partner_name": "Bull Name",                 # Optional: if external animal
  "expected_delivery_date": "2024-10-15",      # Optional
  "actual_delivery_date": "2024-10-25",        # Optional
  "number_of_offspring": 1,                    # Optional
  "offspring_gender": "female",                # Optional: male|female|mixed
  "offspring_health": "Healthy and strong",    # Optional
  "notes": "First pregnancy"                   # Optional
}

Response: 201 Created
{
  "id": 1,
  "animal_id": {animal_id},
  "event_type": "pregnancy",
  "event_date": "2024-01-15",
  ...
}
```

### GET REPRODUCTION RECORDS
```
GET /api/animals/{animal_id}/reproduction
Authorization: Bearer {token}

Response: 200 OK
[
  {
    "id": 1,
    "animal_id": {animal_id},
    "event_type": "pregnancy",
    "event_date": "2024-01-15",
    ...
  }
]
```

### GET REPRODUCTION SUMMARY
```
GET /api/animals/{animal_id}/reproduction-summary
Authorization: Bearer {token}

Response: 200 OK
{
  "animal_id": 1,
  "animal_name": "Amina",
  "current_status": "pregnant",
  "total_offspring": 8,
  "last_breeding_date": "2024-01-15"
}
```

---

## CARE REMINDERS - Calendar & Task Management

### CREATE REMINDER
```
POST /api/animals/{animal_id}/reminders
Authorization: Bearer {token}

Request Body:
{
  "title": "Annual Vaccination",              # Required
  "description": "FMD and similar vaccines",  # Optional
  "tag": "health",                            # Optional: health|reproduction|maintenance|nutrition
  "due_date": "2025-02-26",                   # Required: YYYY-MM-DD
  "is_recurring": true,                       # Optional, default false
  "recurrence_interval": "yearly",            # Optional: daily|weekly|monthly|yearly
  "priority": "high",                         # Optional: low|normal|high|critical
  "notes": "Must do before breeding season"   # Optional
}

Response: 201 Created
{
  "id": 1,
  "animal_id": {animal_id},
  "title": "Annual Vaccination",
  "due_date": "2025-02-26",
  "is_completed": false,
  ...
}
```

### GET ANIMAL REMINDERS
```
GET /api/animals/{animal_id}/reminders?is_completed=false&priority=high
Authorization: Bearer {token}

Query Parameters:
- is_completed (optional): true|false
- tag (optional): health|reproduction|maintenance|nutrition
- priority (optional): low|normal|high|critical

Response: 200 OK
[
  {
    "id": 1,
    "animal_id": {animal_id},
    "title": "Annual Vaccination",
    "due_date": "2025-02-26",
    "is_completed": false,
    "priority": "high"
  }
]
```

### GET UPCOMING REMINDERS (All Animals)
```
GET /api/animals/upcoming?days_ahead=7
Authorization: Bearer {token}

Query Parameters:
- days_ahead (optional, default 7): Number of days ahead to check

Response: 200 OK
[
  {
    "id": 1,
    "animal_id": 1,
    "animal_name": "Amina",
    "title": "Annual Vaccination",
    "due_date": "2024-03-01",
    "priority": "high"
  }
]
```

### UPDATE REMINDER
```
PATCH /api/reminders/{reminder_id}
Authorization: Bearer {token}

Request Body (all optional):
{
  "title": "Updated Title",
  "is_completed": true,
  "completed_date": "2024-02-26",
  "priority": "normal",
  "due_date": "2025-03-01"
}

Response: 200 OK
{...updated reminder...}
```

### DELETE REMINDER
```
DELETE /api/reminders/{reminder_id}
Authorization: Bearer {token}

Response: 204 No Content
```

---

## EXAMPLE CURL COMMANDS

### Create an animal
```bash
curl -X POST http://localhost:8000/api/animals \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJ..." \
  -d '{
    "name": "Bessie",
    "species": "cattle",
    "breed": "Holstein",
    "gender": "female",
    "date_of_birth": "2020-01-15",
    "farm_id": 1
  }'
```

### Add a vaccination
```bash
curl -X POST http://localhost:8000/api/animals/1/health-records \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJ..." \
  -d '{
    "record_type": "vaccination",
    "date": "2024-02-26",
    "medical_name": "FMD Vaccine",
    "next_due_date": "2025-02-26"
  }'
```

### Record daily milk production
```bash
curl -X POST http://localhost:8000/api/animals/1/production \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJ..." \
  -d '{
    "date": "2024-02-26",
    "metric_type": "milk",
    "quantity": 18.5,
    "unit": "liters"
  }'
```

### Get production statistics
```bash
curl http://localhost:8000/api/animals/1/production/stats?metric_type=milk&days=30 \
  -H "Authorization: Bearer eyJ..."
```

### Get upcoming reminders for next 7 days
```bash
curl http://localhost:8000/api/animals/upcoming?days_ahead=7 \
  -H "Authorization: Bearer eyJ..."
```

---

## Error Responses

### 404 Not Found
```json
{
  "detail": "Animal not found"
}
```

### 400 Bad Request
```json
{
  "detail": "Invalid date format (use YYYY-MM-DD)"
}
```

### 401 Unauthorized
```json
{
  "detail": "Not authenticated"
}
```

### 422 Unprocessable Entity
```json
{
  "detail": [
    {
      "loc": ["body", "name"],
      "msg": "Field required",
      "type": "value_error.missing"
    }
  ]
}
```
