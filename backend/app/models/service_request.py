from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from app.models.base import Base
from datetime import datetime
import enum

class ServiceType(str, enum.Enum):
    ANIMAL_PROBLEM = "animal_problem"
    CROP_PROBLEM = "crop_problem"
    GENERAL_ADVICE = "general_advice"

class ConsultationType(str, enum.Enum):
    WRITTEN_ADVICE = "written_advice"
    WHATSAPP_CALL = "whatsapp_call"
    ON_SITE_VISIT = "on_site_visit"
    VIDEO_CALL = "video_call"

class RequestStatus(str, enum.Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    ASSIGNED = "assigned"
    COMPLETED = "completed"
    CLOSED = "closed"
    CANCELLED = "cancelled"

class ServiceRequest(Base):
    __tablename__ = "service_requests"
    
    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, nullable=False, index=True)
    created_by = Column(Integer, nullable=False)  # Farmer user_id
    assigned_veterinarian_id = Column(Integer, index=True)  # Veterinarian user_id
    
    # Request details
    service_type = Column(SQLEnum(ServiceType), nullable=False)
    animal_id = Column(Integer)  # Reference to Livestock.id if animal_problem
    crop_id = Column(Integer)  # Reference to Crop.id if crop_problem
    
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    symptoms = Column(Text)  # Detailed symptoms
    
    # Media
    photos = Column(String(2000))  # JSON list of photo URLs
    
    # Status
    status = Column(SQLEnum(RequestStatus), default=RequestStatus.OPEN)
    priority = Column(String(20), default="normal")  # "low", "normal", "urgent"
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    assigned_at = Column(DateTime)
    completed_at = Column(DateTime)
    
    def __repr__(self):
        return f"<ServiceRequest {self.id} - {self.service_type}>"


class Consultation(Base):
    __tablename__ = "consultations"
    
    id = Column(Integer, primary_key=True, index=True)
    service_request_id = Column(Integer, nullable=False, index=True)
    veterinarian_id = Column(Integer, nullable=False, index=True)
    
    consultation_type = Column(SQLEnum(ConsultationType), nullable=False)
    
    # Content
    advice = Column(Text)  # Written advice/prescription
    notes = Column(Text)
    recommendations = Column(Text)  # Treatment/management recommendations
    
    # Scheduling
    date_scheduled = Column(DateTime)
    completed_at = Column(DateTime)
    
    # Cost (if applicable)
    cost = Column(Integer)  # Cost in cents
    payment_status = Column(String(20), default="pending")  # pending, completed
    
    # Feedback
    farmer_rating = Column(Integer)  # 1-5 stars
    farmer_feedback = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<Consultation {self.id} - {self.consultation_type}>"
