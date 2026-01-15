from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List
from enum import Enum

class ServiceType(str, Enum):
    ANIMAL_PROBLEM = "animal_problem"
    CROP_PROBLEM = "crop_problem"
    GENERAL_ADVICE = "general_advice"

class RequestStatus(str, Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    ASSIGNED = "assigned"
    COMPLETED = "completed"
    CLOSED = "closed"
    CANCELLED = "cancelled"

class Priority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

class ConsultationType(str, Enum):
    WRITTEN_ADVICE = "written_advice"
    WHATSAPP_CALL = "whatsapp_call"
    ON_SITE_VISIT = "on_site_visit"
    VIDEO_CALL = "video_call"

class PaymentStatus(str, Enum):
    PENDING = "pending"
    PAID = "paid"
    FREE = "free"

class ServiceRequestCreate(BaseModel):
    service_type: ServiceType
    title: str
    description: str
    symptoms: Optional[str] = None
    animal_id: Optional[int] = None
    crop_id: Optional[int] = None
    priority: Priority = Priority.MEDIUM
    photos: Optional[List[str]] = None  # Cloudinary URLs

class ServiceRequestUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    symptoms: Optional[str] = None
    status: Optional[RequestStatus] = None
    priority: Optional[Priority] = None

class ServiceRequestResponse(BaseModel):
    id: int
    farm_id: int
    created_by: int
    service_type: ServiceType
    title: str
    description: str
    symptoms: Optional[str]
    animal_id: Optional[int]
    crop_id: Optional[int]
    priority: Priority
    status: RequestStatus
    photos: Optional[List[str]]
    assigned_to: Optional[int]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ConsultationCreate(BaseModel):
    service_request_id: int
    consultation_type: ConsultationType
    advice: str
    recommendations: Optional[str] = None
    scheduling: Optional[str] = None
    cost: Optional[float] = None
    payment_status: PaymentStatus = PaymentStatus.PENDING

class ConsultationResponse(BaseModel):
    id: int
    service_request_id: int
    veterinarian_id: int
    consultation_type: ConsultationType
    advice: str
    recommendations: Optional[str]
    scheduling: Optional[str]
    cost: Optional[float]
    payment_status: PaymentStatus
    farmer_rating: Optional[int]
    farmer_feedback: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
