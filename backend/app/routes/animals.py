"""
API endpoints for individual animal management system.
Handles animals, health records, reproduction, production, and care calendar.
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc
from datetime import date, datetime, timedelta
from typing import List, Optional
from app.database import get_db
from app.models.animal import (
    Animal, AnimalHealthRecord, AnimalReproduction, 
    AnimalProduction, AnimalCareReminder
)
from app.models.user import User
from app.schemas.animal_schemas import (
    AnimalCreateRequest, AnimalUpdateRequest, AnimalResponse, AnimalDetailedResponse,
    AnimalHealthRecordCreate, AnimalHealthRecordResponse,
    AnimalReproductionCreate, AnimalReproductionResponse,
    AnimalProductionCreate, AnimalProductionResponse,
    AnimalCareReminderCreate, AnimalCareReminderUpdate, AnimalCareReminderResponse,
    AnimalProductionStatistic, AnimalHealthSummary, AnimalReproductionSummary
)

router = APIRouter(prefix="/api/animals", tags=["livestock_animals"])

# ═════════════════════════════════════════════════════════════════════════════
# ANIMAL MANAGEMENT ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/", response_model=AnimalResponse, status_code=status.HTTP_201_CREATED)
def create_animal(
    animal: AnimalCreateRequest,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Create a new individual animal record."""
    # Verify user exists
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    new_animal = Animal(
        user_id=user_id,
        farm_id=animal.farm_id,
        name=animal.name,
        tag_id=animal.tag_id,
        species=animal.species,
        breed=animal.breed,
        gender=animal.gender,
        date_of_birth=animal.date_of_birth,
        weight_kg=animal.weight_kg,
        height_cm=animal.height_cm,
        color_markings=animal.color_markings,
        health_status=animal.health_status,
        health_notes=animal.health_notes,
        reproductive_status=animal.reproductive_status,
        acquisition_date=animal.acquisition_date,
        acquisition_cost=animal.acquisition_cost,
        location=animal.location,
        photo_url=animal.photo_url,
    )
    
    db.add(new_animal)
    db.commit()
    db.refresh(new_animal)
    
    return new_animal

@router.get("/", response_model=List[AnimalResponse])
def list_animals(
    user_id: int,
    farm_id: Optional[int] = Query(None),
    species: Optional[str] = Query(None),
    is_active: Optional[bool] = Query(True),
    db: Session = Depends(get_db)
):
    """List all animals for a user, with optional filters."""
    query = db.query(Animal).filter(Animal.user_id == user_id)
    
    if farm_id:
        query = query.filter(Animal.farm_id == farm_id)
    if species:
        query = query.filter(Animal.species == species)
    if is_active is not None:
        query = query.filter(Animal.is_active == is_active)
    
    animals = query.order_by(Animal.name).all()
    return animals

@router.get("/{animal_id}", response_model=AnimalDetailedResponse)
def get_animal_details(
    animal_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get detailed information about a single animal."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    return animal

@router.put("/{animal_id}", response_model=AnimalResponse)
def update_animal(
    animal_id: int,
    animal_update: AnimalUpdateRequest,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Update an animal record."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    # Update only provided fields
    update_data = animal_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(animal, key, value)
    
    animal.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(animal)
    
    return animal

@router.delete("/{animal_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_animal(
    animal_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Soft delete (archive) an animal."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    animal.is_active = False
    animal.updated_at = datetime.utcnow()
    db.commit()

# ═════════════════════════════════════════════════════════════════════════════
# HEALTH RECORD ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/{animal_id}/health-records", response_model=AnimalHealthRecordResponse, status_code=status.HTTP_201_CREATED)
def add_health_record(
    animal_id: int,
    record: AnimalHealthRecordCreate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Add a health record (vaccination, treatment, checkup) for an animal."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    new_record = AnimalHealthRecord(
        animal_id=animal_id,
        user_id=user_id,
        record_type=record.record_type,
        date=record.date,
        medical_name=record.medical_name,
        description=record.description,
        dosage=record.dosage,
        administered_by=record.administered_by,
        cost=record.cost,
        next_due_date=record.next_due_date,
        notes=record.notes,
    )
    
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    
    return new_record

@router.get("/{animal_id}/health-records", response_model=List[AnimalHealthRecordResponse])
def get_health_records(
    animal_id: int,
    user_id: int,
    record_type: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """Get all health records for an animal."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    query = db.query(AnimalHealthRecord).filter(AnimalHealthRecord.animal_id == animal_id)
    
    if record_type:
        query = query.filter(AnimalHealthRecord.record_type == record_type)
    
    records = query.order_by(desc(AnimalHealthRecord.date)).all()
    return records

@router.delete("/health-records/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_health_record(
    record_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Delete a health record."""
    record = db.query(AnimalHealthRecord).filter(
        AnimalHealthRecord.id == record_id
    ).first()
    
    if not record or record.user_id != user_id:
        raise HTTPException(status_code=404, detail="Health record not found")
    
    db.delete(record)
    db.commit()

# ═════════════════════════════════════════════════════════════════════════════
# REPRODUCTION ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/{animal_id}/reproduction", response_model=AnimalReproductionResponse, status_code=status.HTTP_201_CREATED)
def add_reproduction_record(
    animal_id: int,
    record: AnimalReproductionCreate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Add a reproduction event (heat, mating, pregnancy, birth)."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    new_record = AnimalReproduction(
        animal_id=animal_id,
        user_id=user_id,
        event_type=record.event_type,
        event_date=record.event_date,
        partner_animal_id=record.partner_animal_id,
        partner_name=record.partner_name,
        expected_delivery_date=record.expected_delivery_date,
        actual_delivery_date=record.actual_delivery_date,
        number_of_offspring=record.number_of_offspring,
        offspring_gender=record.offspring_gender,
        offspring_health=record.offspring_health,
        notes=record.notes,
    )
    
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    
    return new_record

@router.get("/{animal_id}/reproduction", response_model=List[AnimalReproductionResponse])
def get_reproduction_records(
    animal_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get all reproduction records for an animal."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    records = db.query(AnimalReproduction).filter(
        AnimalReproduction.animal_id == animal_id
    ).order_by(desc(AnimalReproduction.event_date)).all()
    
    return records

# ═════════════════════════════════════════════════════════════════════════════
# PRODUCTION ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/{animal_id}/production", response_model=AnimalProductionResponse, status_code=status.HTTP_201_CREATED)
def add_production_record(
    animal_id: int,
    record: AnimalProductionCreate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Add a production record (milk, eggs, wool, meat, etc.)."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    new_record = AnimalProduction(
        animal_id=animal_id,
        user_id=user_id,
        date=record.date,
        metric_type=record.metric_type,
        quantity=record.quantity,
        unit=record.unit,
        quality_grade=record.quality_grade,
        notes=record.notes,
    )
    
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    
    return new_record

@router.get("/{animal_id}/production", response_model=List[AnimalProductionResponse])
def get_production_records(
    animal_id: int,
    user_id: int,
    metric_type: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    db: Session = Depends(get_db)
):
    """Get production records for an animal."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    query = db.query(AnimalProduction).filter(AnimalProduction.animal_id == animal_id)
    
    if metric_type:
        query = query.filter(AnimalProduction.metric_type == metric_type)
    if date_from:
        query = query.filter(AnimalProduction.date >= date_from)
    if date_to:
        query = query.filter(AnimalProduction.date <= date_to)
    
    records = query.order_by(desc(AnimalProduction.date)).all()
    return records

@router.get("/{animal_id}/production/stats", response_model=AnimalProductionStatistic)
def get_production_statistics(
    animal_id: int,
    user_id: int,
    metric_type: str = Query(...),
    days: int = Query(30),
    db: Session = Depends(get_db)
):
    """Get production statistics for a specific metric (milk, eggs, etc.)."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    date_from = date.today() - timedelta(days=days)
    records = db.query(AnimalProduction).filter(
        and_(
            AnimalProduction.animal_id == animal_id,
            AnimalProduction.metric_type == metric_type,
            AnimalProduction.date >= date_from
        )
    ).all()
    
    if not records:
        raise HTTPException(status_code=404, detail="No production records found")
    
    quantities = [r.quantity for r in records]
    total = sum(quantities)
    avg_per_day = total / len(records)
    best = max(records, key=lambda x: x.quantity)
    worst = min(records, key=lambda x: x.quantity)
    
    return AnimalProductionStatistic(
        animal_id=animal_id,
        animal_name=animal.name,
        metric_type=metric_type,
        total_quantity=total,
        average_per_day=avg_per_day,
        unit=records[0].unit,
        best_day_quantity=best.quantity,
        worst_day_quantity=worst.quantity,
        best_day=best.date,
        worst_day=worst.date,
        date_from=date_from,
        date_to=date.today(),
    )

# ═════════════════════════════════════════════════════════════════════════════
# CARE REMINDER / CALENDAR ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@router.post("/{animal_id}/reminders", response_model=AnimalCareReminderResponse, status_code=status.HTTP_201_CREATED)
def add_care_reminder(
    animal_id: int,
    reminder: AnimalCareReminderCreate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Create a care reminder/calendar event."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    new_reminder = AnimalCareReminder(
        animal_id=animal_id,
        user_id=user_id,
        title=reminder.title,
        description=reminder.description,
        tag=reminder.tag,
        due_date=reminder.due_date,
        is_recurring=reminder.is_recurring,
        recurrence_interval=reminder.recurrence_interval,
        priority=reminder.priority,
        notes=reminder.notes,
    )
    
    db.add(new_reminder)
    db.commit()
    db.refresh(new_reminder)
    
    return new_reminder

@router.get("/{animal_id}/reminders", response_model=List[AnimalCareReminderResponse])
def get_care_reminders(
    animal_id: int,
    user_id: int,
    is_completed: Optional[bool] = Query(None),
    tag: Optional[str] = Query(None),
    priority: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """Get care reminders for an animal."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    query = db.query(AnimalCareReminder).filter(AnimalCareReminder.animal_id == animal_id)
    
    if is_completed is not None:
        query = query.filter(AnimalCareReminder.is_completed == is_completed)
    if tag:
        query = query.filter(AnimalCareReminder.tag == tag)
    if priority:
        query = query.filter(AnimalCareReminder.priority == priority)
    
    reminders = query.order_by(AnimalCareReminder.due_date).all()
    return reminders

@router.get("/upcoming", response_model=List[AnimalCareReminderResponse])
def get_upcoming_reminders(
    user_id: int,
    days_ahead: int = Query(7),
    db: Session = Depends(get_db)
):
    """Get upcoming reminders for all animals."""
    today = date.today()
    end_date = today + timedelta(days=days_ahead)
    
    reminders = db.query(AnimalCareReminder).filter(
        and_(
            AnimalCareReminder.user_id == user_id,
            AnimalCareReminder.is_completed == False,
            AnimalCareReminder.due_date >= today,
            AnimalCareReminder.due_date <= end_date,
        )
    ).order_by(AnimalCareReminder.due_date).all()
    
    return reminders

@router.patch("/reminders/{reminder_id}", response_model=AnimalCareReminderResponse)
def update_care_reminder(
    reminder_id: int,
    update: AnimalCareReminderUpdate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Update a care reminder."""
    reminder = db.query(AnimalCareReminder).filter(
        AnimalCareReminder.id == reminder_id
    ).first()
    
    if not reminder or reminder.user_id != user_id:
        raise HTTPException(status_code=404, detail="Reminder not found")
    
    update_data = update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(reminder, key, value)
    
    reminder.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(reminder)
    
    return reminder

@router.delete("/reminders/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_care_reminder(
    reminder_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Delete a care reminder."""
    reminder = db.query(AnimalCareReminder).filter(
        AnimalCareReminder.id == reminder_id
    ).first()
    
    if not reminder or reminder.user_id != user_id:
        raise HTTPException(status_code=404, detail="Reminder not found")
    
    db.delete(reminder)
    db.commit()

# ═════════════════════════════════════════════════════════════════════════════
# SUMMARY & DASHBOARD ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@router.get("/{animal_id}/health-summary", response_model=AnimalHealthSummary)
def get_health_summary(
    animal_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get a health status summary for an animal."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    total_records = db.query(AnimalHealthRecord).filter(
        AnimalHealthRecord.animal_id == animal_id
    ).count()
    
    vaccinations = db.query(AnimalHealthRecord).filter(
        and_(
            AnimalHealthRecord.animal_id == animal_id,
            AnimalHealthRecord.record_type == "vaccination"
        )
    ).count()
    
    upcoming = db.query(AnimalCareReminder).filter(
        and_(
            AnimalCareReminder.animal_id == animal_id,
            AnimalCareReminder.is_completed == False,
            AnimalCareReminder.due_date >= date.today(),
        )
    ).count()
    
    overdue = db.query(AnimalCareReminder).filter(
        and_(
            AnimalCareReminder.animal_id == animal_id,
            AnimalCareReminder.is_completed == False,
            AnimalCareReminder.due_date < date.today(),
        )
    ).count()
    
    days_since = None
    if animal.last_checkup_date:
        days_since = (datetime.utcnow() - animal.last_checkup_date).days
    
    return AnimalHealthSummary(
        animal_id=animal_id,
        animal_name=animal.name,
        current_health_status=animal.health_status,
        total_health_records=total_records,
        last_checkup_date=animal.last_checkup_date,
        days_since_checkup=days_since,
        upcoming_care_count=upcoming,
        overdue_care_count=overdue,
        recent_vaccinations=vaccinations,
    )

@router.get("/{animal_id}/reproduction-summary", response_model=AnimalReproductionSummary)
def get_reproduction_summary(
    animal_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get a reproduction status summary."""
    animal = db.query(Animal).filter(
        and_(Animal.id == animal_id, Animal.user_id == user_id)
    ).first()
    
    if not animal:
        raise HTTPException(status_code=404, detail="Animal not found")
    
    total_offspring = db.query(AnimalReproduction).filter(
        and_(
            AnimalReproduction.animal_id == animal_id,
            AnimalReproduction.number_of_offspring.isnot(None),
        )
    ).with_entities(db.func.sum(AnimalReproduction.number_of_offspring)).scalar() or 0
    
    last_breeding = db.query(AnimalReproduction).filter(
        AnimalReproduction.animal_id == animal_id
    ).order_by(desc(AnimalReproduction.event_date)).first()
    
    return AnimalReproductionSummary(
        animal_id=animal_id,
        animal_name=animal.name,
        current_status=animal.reproductive_status,
        total_offspring=int(total_offspring),
        last_breeding_date=last_breeding.event_date if last_breeding else None,
    )
