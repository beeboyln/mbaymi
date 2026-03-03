"""
Pydantic schémas for individual animal management system.
Contains request/response models for animals, health records, reproduction, production, and care reminders.
"""
from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional, List
from enum import Enum

# ─────────────────────────────────────────────────────────────────────────────
# ENUM SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class AnimalSpeciesEnum(str, Enum):
    CATTLE = "cattle"
    GOAT = "goat"
    SHEEP = "sheep"
    PIG = "pig"
    POULTRY = "poultry"
    HORSE = "horse"
    DONKEY = "donkey"

class AnimalGenderEnum(str, Enum):
    MALE = "male"
    FEMALE = "female"

class HealthStatusEnum(str, Enum):
    HEALTHY = "healthy"
    SICK = "sick"
    TREATED = "treated"
    VACCINATED = "vaccinated"
    ISOLATED = "isolated"

class ReproductiveStatusEnum(str, Enum):
    NOT_BREEDING = "not_breeding"
    IN_CYCLE = "in_cycle"
    PREGNANT = "pregnant"
    LACTATING = "lactating"
    WEANED = "weaned"

class MedicalTypeEnum(str, Enum):
    VACCINATION = "vaccination"
    DEWORMING = "deworming"
    TREATMENT = "treatment"
    CHECKUP = "checkup"
    SURGERY = "surgery"

# ─────────────────────────────────────────────────────────────────────────────
# ANIMAL SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class AnimalCreateRequest(BaseModel):
    """Create a new individual animal record."""
    name: str = Field(..., min_length=1, max_length=100)
    tag_id: Optional[str] = Field(None, max_length=50)
    species: AnimalSpeciesEnum
    breed: Optional[str] = Field(None, max_length=100)
    gender: AnimalGenderEnum
    date_of_birth: date
    
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    color_markings: Optional[str] = Field(None, max_length=200)
    
    health_status: HealthStatusEnum = HealthStatusEnum.HEALTHY
    health_notes: Optional[str] = None
    
    reproductive_status: ReproductiveStatusEnum = ReproductiveStatusEnum.NOT_BREEDING
    
    acquisition_date: Optional[date] = None
    acquisition_cost: Optional[float] = None
    location: Optional[str] = Field(None, max_length=200)
    
    photo_url: Optional[str] = Field(None, max_length=500)
    
    farm_id: Optional[int] = None

class AnimalUpdateRequest(BaseModel):
    """Update an animal record."""
    name: Optional[str] = None
    tag_id: Optional[str] = None
    breed: Optional[str] = None
    gender: Optional[AnimalGenderEnum] = None
    date_of_birth: Optional[date] = None
    
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    color_markings: Optional[str] = None
    
    health_status: Optional[HealthStatusEnum] = None
    health_notes: Optional[str] = None
    reproductive_status: Optional[ReproductiveStatusEnum] = None
    
    location: Optional[str] = None
    photo_url: Optional[str] = None
    is_active: Optional[bool] = None

class AnimalResponse(BaseModel):
    """Animal record response."""
    id: int
    user_id: int
    farm_id: Optional[int] = None
    
    name: str
    tag_id: Optional[str] = None
    species: AnimalSpeciesEnum
    breed: Optional[str] = None
    gender: AnimalGenderEnum
    date_of_birth: date
    
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    color_markings: Optional[str] = None
    
    health_status: HealthStatusEnum
    health_notes: Optional[str] = None
    last_checkup_date: Optional[datetime] = None
    
    reproductive_status: ReproductiveStatusEnum
    
    acquisition_date: Optional[date] = None
    acquisition_cost: Optional[float] = None
    location: Optional[str] = None
    is_active: bool
    
    photo_url: Optional[str] = None
    
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class AnimalDetailedResponse(AnimalResponse):
    """Animal with all related records."""
    health_records: List['AnimalHealthRecordResponse'] = []
    reproduction_records: List['AnimalReproductionResponse'] = []
    production_records: List['AnimalProductionResponse'] = []
    care_reminders: List['AnimalCareReminderResponse'] = []

# ─────────────────────────────────────────────────────────────────────────────
# HEALTH RECORD SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class AnimalHealthRecordCreate(BaseModel):
    """Create a health record (vaccination, treatment, checkup)."""
    record_type: MedicalTypeEnum
    date: date
    
    medical_name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    dosage: Optional[str] = Field(None, max_length=100)
    administered_by: Optional[str] = Field(None, max_length=100)
    cost: Optional[float] = None
    
    next_due_date: Optional[date] = None
    notes: Optional[str] = None

class AnimalHealthRecordResponse(BaseModel):
    """Health record response."""
    id: int
    animal_id: int
    user_id: int
    
    record_type: MedicalTypeEnum
    date: date
    
    medical_name: str
    description: Optional[str] = None
    dosage: Optional[str] = None
    administered_by: Optional[str] = None
    cost: Optional[float] = None
    
    next_due_date: Optional[date] = None
    notes: Optional[str] = None
    
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# ─────────────────────────────────────────────────────────────────────────────
# REPRODUCTION SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class AnimalReproductionCreate(BaseModel):
    """Create a reproduction event record."""
    event_type: str = Field(..., min_length=1)  # heat, mating, pregnancy, birth
    event_date: date
    
    partner_animal_id: Optional[int] = None
    partner_name: Optional[str] = Field(None, max_length=100)
    
    expected_delivery_date: Optional[date] = None
    actual_delivery_date: Optional[date] = None
    number_of_offspring: Optional[int] = None
    offspring_gender: Optional[str] = None
    offspring_health: Optional[str] = None
    
    notes: Optional[str] = None

class AnimalReproductionResponse(BaseModel):
    """Reproduction record response."""
    id: int
    animal_id: int
    user_id: int
    
    event_type: str
    event_date: date
    
    partner_animal_id: Optional[int] = None
    partner_name: Optional[str] = None
    
    expected_delivery_date: Optional[date] = None
    actual_delivery_date: Optional[date] = None
    number_of_offspring: Optional[int] = None
    offspring_gender: Optional[str] = None
    offspring_health: Optional[str] = None
    
    notes: Optional[str] = None
    
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# ─────────────────────────────────────────────────────────────────────────────
# PRODUCTION SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class AnimalProductionCreate(BaseModel):
    """Create a production record (milk, eggs, wool, meat, etc.)."""
    date: date
    
    metric_type: str = Field(..., min_length=1)  # milk, eggs, wool, meat, etc.
    quantity: float = Field(..., gt=0)
    unit: str = Field(..., min_length=1, max_length=20)  # liters, number, kg, etc.
    
    quality_grade: Optional[str] = Field(None, max_length=50)
    notes: Optional[str] = None

class AnimalProductionResponse(BaseModel):
    """Production record response."""
    id: int
    animal_id: int
    user_id: int
    
    date: date
    
    metric_type: str
    quantity: float
    unit: str
    
    quality_grade: Optional[str] = None
    notes: Optional[str] = None
    
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# ─────────────────────────────────────────────────────────────────────────────
# CARE REMINDER SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class AnimalCareReminderCreate(BaseModel):
    """Create a care reminder/calendar event."""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    tag: Optional[str] = Field(None, max_length=50)  # health, reproduction, maintenance, nutrition
    
    due_date: date
    is_recurring: bool = False
    recurrence_interval: Optional[str] = Field(None, max_length=50)  # daily, weekly, monthly, yearly
    
    priority: str = Field("normal", pattern="^(low|normal|high|critical)$")
    notes: Optional[str] = None

class AnimalCareReminderUpdate(BaseModel):
    """Update a care reminder."""
    title: Optional[str] = None
    description: Optional[str] = None
    tag: Optional[str] = None
    due_date: Optional[date] = None
    completed_date: Optional[date] = None
    is_completed: Optional[bool] = None
    is_recurring: Optional[bool] = None
    recurrence_interval: Optional[str] = None
    priority: Optional[str] = None
    notes: Optional[str] = None

class AnimalCareReminderResponse(BaseModel):
    """Care reminder response."""
    id: int
    animal_id: int
    user_id: int
    
    title: str
    description: Optional[str] = None
    tag: Optional[str] = None
    
    due_date: date
    completed_date: Optional[date] = None
    is_completed: bool
    
    is_recurring: bool
    recurrence_interval: Optional[str] = None
    
    priority: str
    notes: Optional[str] = None
    
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# ─────────────────────────────────────────────────────────────────────────────
# STATISTICS & DASHBOARDS
# ─────────────────────────────────────────────────────────────────────────────
class AnimalProductionStatistic(BaseModel):
    """Production statistics for an animal."""
    animal_id: int
    animal_name: str
    metric_type: str
    
    total_quantity: float
    average_per_day: float
    unit: str
    
    best_day_quantity: float
    worst_day_quantity: float
    best_day: date
    worst_day: date
    
    date_from: date
    date_to: date

class AnimalHealthSummary(BaseModel):
    """Health status summary."""
    animal_id: int
    animal_name: str
    current_health_status: HealthStatusEnum
    
    total_health_records: int
    last_checkup_date: Optional[datetime] = None
    days_since_checkup: Optional[int] = None
    
    upcoming_care_count: int
    overdue_care_count: int
    
    recent_vaccinations: int

class AnimalReproductionSummary(BaseModel):
    """Reproduction status summary."""
    animal_id: int
    animal_name: str
    current_status: ReproductiveStatusEnum
    
    total_offspring: Optional[int] = None
    last_breeding_date: Optional[date] = None
    
    if_pregnant: Optional[dict] = None  # { expected_date, days_remaining, etc. }

# ─────────────────────────────────────────────────────────────────────────────
# FOR UPDATING FORWARD REFERENCES
# ─────────────────────────────────────────────────────────────────────────────
AnimalDetailedResponse.model_rebuild()
