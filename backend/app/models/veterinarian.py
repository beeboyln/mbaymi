from sqlalchemy import Column, Integer, String, DateTime, Boolean, Float, Text, Enum as SQLEnum
from sqlalchemy.orm import relationship
from app.models.base import Base
from datetime import datetime
import enum

class VerificationStatus(str, enum.Enum):
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"

class AvailabilityStatus(str, enum.Enum):
    AVAILABLE = "available"
    BUSY = "busy"
    OFFLINE = "offline"

class VeterinarianProfile(Base):
    __tablename__ = "veterinarian_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)  # Reference to User.id
    specialty = Column(String(200), nullable=False)  # e.g., "Élevage bovin", "Volaille", "Aquaculture"
    zone = Column(String(200), nullable=False)  # Geographic zone/region
    distance_max = Column(Float, default=50)  # Max service distance in km
    bio = Column(Text)  # Professional biography
    experience_years = Column(Integer)  # Years of experience
    
    # Verification
    is_verified = Column(Boolean, default=False)
    verification_status = Column(SQLEnum(VerificationStatus), default=VerificationStatus.PENDING)
    certificate_url = Column(String(500))  # URL to uploaded certificate/diploma
    certificate_filename = Column(String(200))  # Original filename
    verified_at = Column(DateTime)
    verified_by_admin = Column(Integer)  # Admin user_id who verified
    
    # Availability
    availability_status = Column(SQLEnum(AvailabilityStatus), default=AvailabilityStatus.AVAILABLE)
    contact_preference = Column(String(50))  # "whatsapp", "call", "both", "visit"
    whatsapp_number = Column(String(20))  # Optional WhatsApp contact
    
    # Statistics
    total_consultations = Column(Integer, default=0)
    average_rating = Column(Float, default=0.0)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<VeterinarianProfile {self.specialty}>"
