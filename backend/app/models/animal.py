"""
Individual Animal Models for detailed livestock management.
Replaces group-based tracking with individual animal records.
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, Boolean, Date, Enum as SQLEnum
from sqlalchemy.orm import relationship
from app.models.base import Base
from datetime import datetime
import enum

# ─────────────────────────────────────────────────────────────────────────────
# ENUMS
# ─────────────────────────────────────────────────────────────────────────────
class AnimalSpecies(str, enum.Enum):
    CATTLE = "cattle"
    GOAT = "goat"
    SHEEP = "sheep"
    PIG = "pig"
    POULTRY = "poultry"
    HORSE = "horse"
    DONKEY = "donkey"

class AnimalGender(str, enum.Enum):
    MALE = "male"
    FEMALE = "female"

class HealthStatus(str, enum.Enum):
    HEALTHY = "healthy"
    SICK = "sick"
    TREATED = "treated"
    VACCINATED = "vaccinated"
    ISOLATED = "isolated"

class ReproductiveStatus(str, enum.Enum):
    NOT_BREEDING = "not_breeding"
    IN_CYCLE = "in_cycle"
    PREGNANT = "pregnant"
    LACTATING = "lactating"
    WEANED = "weaned"

class MedicalType(str, enum.Enum):
    VACCINATION = "vaccination"
    DEWORMING = "deworming"
    TREATMENT = "treatment"
    CHECKUP = "checkup"
    SURGERY = "surgery"

# ─────────────────────────────────────────────────────────────────────────────
# INDIVIDUAL ANIMAL MODEL
# ─────────────────────────────────────────────────────────────────────────────
class Animal(Base):
    """Individual animal record with complete tracking information."""
    __tablename__ = "animals"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=True)
    
    # ── Identity ────────────────────────────────────────────────────────────
    name = Column(String(100), nullable=False)
    tag_id = Column(String(50), unique=True, nullable=True)  # Ear tag, RFID, etc.
    species = Column(SQLEnum(AnimalSpecies), nullable=False)  # cattle, goat, sheep, etc.
    breed = Column(String(100), nullable=True)
    gender = Column(SQLEnum(AnimalGender), nullable=False)
    date_of_birth = Column(Date, nullable=False)
    
    # ── Physical Attributes ─────────────────────────────────────────────────
    weight_kg = Column(Float, nullable=True)
    height_cm = Column(Float, nullable=True)  # Height at shoulder
    color_markings = Column(String(200), nullable=True)  # Description for identification
    
    # ── Health Status ───────────────────────────────────────────────────────
    health_status = Column(SQLEnum(HealthStatus), default=HealthStatus.HEALTHY)
    health_notes = Column(Text, nullable=True)
    last_checkup_date = Column(DateTime, nullable=True)
    
    # ── Reproduction ────────────────────────────────────────────────────────
    reproductive_status = Column(SQLEnum(ReproductiveStatus), default=ReproductiveStatus.NOT_BREEDING)
    
    # ── Management ──────────────────────────────────────────────────────────
    acquisition_date = Column(Date, nullable=True)
    acquisition_cost = Column(Float, nullable=True)
    location = Column(String(200), nullable=True)  # Pasture, barn section, etc.
    is_active = Column(Boolean, default=True)  # Soft delete / archived
    
    # ── Media ───────────────────────────────────────────────────────────────
    photo_url = Column(String(500), nullable=True)  # Cloudinary URL
    
    # ── Metadata ────────────────────────────────────────────────────────────
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # ── Relationships ───────────────────────────────────────────────────────
    health_records = relationship("AnimalHealthRecord", back_populates="animal", cascade="all, delete-orphan", foreign_keys="AnimalHealthRecord.animal_id")
    reproduction_records = relationship("AnimalReproduction", back_populates="animal", cascade="all, delete-orphan", foreign_keys="AnimalReproduction.animal_id")
    production_records = relationship("AnimalProduction", back_populates="animal", cascade="all, delete-orphan", foreign_keys="AnimalProduction.animal_id")
    care_reminders = relationship("AnimalCareReminder", back_populates="animal", cascade="all, delete-orphan", foreign_keys="AnimalCareReminder.animal_id")

# ─────────────────────────────────────────────────────────────────────────────
# HEALTH TRACKING MODEL
# ─────────────────────────────────────────────────────────────────────────────
class AnimalHealthRecord(Base):
    """Vaccination, medical treatments, and health events."""
    __tablename__ = "animal_health_records"
    
    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animals.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # ── Record Details ──────────────────────────────────────────────────────
    record_type = Column(SQLEnum(MedicalType), nullable=False)  # vaccination, treatment, etc.
    date = Column(Date, nullable=False)
    
    # ── Medical Information ─────────────────────────────────────────────────
    medical_name = Column(String(200), nullable=False)  # e.g., "FMD Vaccine", "Antibiotic XYZ"
    description = Column(Text, nullable=True)
    dosage = Column(String(100), nullable=True)
    administered_by = Column(String(100), nullable=True)  # Vet name or farmer name
    cost = Column(Float, nullable=True)
    
    # ── Follow-up ───────────────────────────────────────────────────────────
    next_due_date = Column(Date, nullable=True)  # For recurring treatments
    notes = Column(Text, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # ── Relationships ───────────────────────────────────────────────────────
    animal = relationship("Animal", back_populates="health_records")

# ─────────────────────────────────────────────────────────────────────────────
# REPRODUCTION TRACKING MODEL
# ─────────────────────────────────────────────────────────────────────────────
class AnimalReproduction(Base):
    """Breeding cycles, gestation, and birth records."""
    __tablename__ = "animal_reproduction"
    
    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animals.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # ── Breeding Event ──────────────────────────────────────────────────────
    event_type = Column(String(50), nullable=False)  # heat, mating, pregnancy, birth
    event_date = Column(Date, nullable=False)
    
    # ── Mating Information ──────────────────────────────────────────────────
    partner_animal_id = Column(Integer, ForeignKey("animals.id"), nullable=True)  # ID of male/sire
    partner_name = Column(String(100), nullable=True)  # Name if external animal
    
    # ── Pregnancy Tracking ──────────────────────────────────────────────────
    expected_delivery_date = Column(Date, nullable=True)
    actual_delivery_date = Column(Date, nullable=True)
    number_of_offspring = Column(Integer, nullable=True)
    offspring_gender = Column(String(50), nullable=True)  # male, female, mixed
    offspring_health = Column(Text, nullable=True)
    
    # ── Notes ───────────────────────────────────────────────────────────────
    notes = Column(Text, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # ── Relationships ───────────────────────────────────────────────────────
    animal = relationship("Animal", back_populates="reproduction_records", foreign_keys=[animal_id])

# ─────────────────────────────────────────────────────────────────────────────
# PRODUCTION TRACKING MODEL
# ─────────────────────────────────────────────────────────────────────────────
class AnimalProduction(Base):
    """Daily/periodic production records: milk, eggs, meat, wool, etc."""
    __tablename__ = "animal_production"
    
    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animals.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # ── Production Date ─────────────────────────────────────────────────────
    date = Column(Date, nullable=False)
    
    # ── Production Metrics (one per record, or use JSON for flexibility) ────
    metric_type = Column(String(50), nullable=False)  # milk, eggs, wool, meat, etc.
    quantity = Column(Float, nullable=False)
    unit = Column(String(20), nullable=False)  # liters, number, kg, etc.
    
    # ── Quality Data ────────────────────────────────────────────────────────
    quality_grade = Column(String(50), nullable=True)  # A, B, etc.
    notes = Column(Text, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # ── Relationships ───────────────────────────────────────────────────────
    animal = relationship("Animal", back_populates="production_records")

# ─────────────────────────────────────────────────────────────────────────────
# CARE REMINDER / CALENDAR MODEL
# ─────────────────────────────────────────────────────────────────────────────
class AnimalCareReminder(Base):
    """Calendar events for care tasks: vaccinations, farrier visits, etc."""
    __tablename__ = "animal_care_reminders"
    
    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animals.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # ── Event Details ───────────────────────────────────────────────────────
    title = Column(String(200), nullable=False)  # "Annual vaccination", "Hoof trim", etc.
    description = Column(Text, nullable=True)
    tag = Column(String(50), nullable=True)  # health, reproduction, maintenance, nutrition
    
    # ── Scheduling ──────────────────────────────────────────────────────────
    due_date = Column(Date, nullable=False)
    completed_date = Column(Date, nullable=True)
    is_completed = Column(Boolean, default=False)
    
    # ── Frequency ───────────────────────────────────────────────────────────
    is_recurring = Column(Boolean, default=False)
    recurrence_interval = Column(String(50), nullable=True)  # daily, weekly, monthly, yearly
    
    # ── Priority ────────────────────────────────────────────────────────────
    priority = Column(String(20), default="normal")  # low, normal, high, critical
    
    notes = Column(Text, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # ── Relationships ───────────────────────────────────────────────────────
    animal = relationship("Animal", back_populates="care_reminders")
