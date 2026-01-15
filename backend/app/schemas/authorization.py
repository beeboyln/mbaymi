from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from enum import Enum

class AuthorizationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    REVOKED = "revoked"

class AuthorizationCreate(BaseModel):
    farm_id: int
    veterinarian_id: int
    can_view_data: bool = True
    can_give_advice: bool = True
    can_visit: bool = False
    authorization_reason: Optional[str] = None

class AuthorizationUpdate(BaseModel):
    can_view_data: Optional[bool] = None
    can_give_advice: Optional[bool] = None
    can_visit: Optional[bool] = None
    status: Optional[AuthorizationStatus] = None

class AuthorizationResponse(BaseModel):
    id: int
    farm_id: int
    veterinarian_id: int
    authorized_by: int
    can_view_data: bool
    can_give_advice: bool
    can_visit: bool
    status: AuthorizationStatus
    authorization_reason: Optional[str]
    expires_at: datetime
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
