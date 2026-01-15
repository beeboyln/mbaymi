from sqlalchemy import Column, Integer, DateTime, Boolean, String, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.orm import relationship
from app.models.base import Base
from datetime import datetime, timedelta
import enum

class AuthorizationStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    REVOKED = "revoked"

class Authorization(Base):
    __tablename__ = "authorizations"
    
    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, nullable=False, index=True)  # Reference to Farm.id
    veterinarian_id = Column(Integer, nullable=False, index=True)  # Reference to User.id
    authorized_by = Column(Integer, nullable=False)  # Farmer user_id
    
    # Permissions
    can_view_data = Column(Boolean, default=True)
    can_give_advice = Column(Boolean, default=True)
    can_visit = Column(Boolean, default=False)
    
    # Status
    status = Column(SQLEnum(AuthorizationStatus), default=AuthorizationStatus.PENDING)
    authorization_reason = Column(Text)  # Why they need access
    
    # Expiration
    expires_at = Column(DateTime, default=lambda: datetime.utcnow() + timedelta(days=365))
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    revoked_at = Column(DateTime)
    
    def __repr__(self):
        return f"<Authorization farm={self.farm_id} vet={self.veterinarian_id}>"
