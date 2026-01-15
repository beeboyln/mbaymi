from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List
from enum import Enum

class VerificationStatus(str, Enum):
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"

class AvailabilityStatus(str, Enum):
    AVAILABLE = "available"
    BUSY = "busy"
    OFFLINE = "offline"

class VeterinarianProfileCreate(BaseModel):
    specialty: str
    zone: str
    distance_max: float = 50
    bio: Optional[str] = None
    experience_years: Optional[int] = None
    contact_preference: str = "both"
    whatsapp_number: Optional[str] = None

class VeterinarianProfileUpdate(BaseModel):
    specialty: Optional[str] = None
    zone: Optional[str] = None
    distance_max: Optional[float] = None
    bio: Optional[str] = None
    experience_years: Optional[int] = None
    contact_preference: Optional[str] = None
    whatsapp_number: Optional[str] = None
    availability_status: Optional[AvailabilityStatus] = None

class VeterinarianProfileResponse(BaseModel):
    id: int
    user_id: int
    specialty: str
    zone: str
    distance_max: float
    bio: Optional[str]
    experience_years: Optional[int]
    is_verified: bool
    verification_status: VerificationStatus
    certificate_url: Optional[str]
    availability_status: AvailabilityStatus
    contact_preference: str
    whatsapp_number: Optional[str]
    total_consultations: int
    average_rating: float
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
