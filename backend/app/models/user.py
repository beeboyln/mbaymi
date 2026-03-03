from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.orm import relationship
from app.models.base import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=True, index=True)  # Optional si phone utilisé
    phone = Column(String(20), unique=True, nullable=True)  # Optional si email utilisé
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)  # farmer, livestock_breeder, buyer, seller
    region = Column(String(100))
    village = Column(String(100))
    profile_image = Column(String(500))  # URL de la photo de profil
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relations
    # Import Notification at the bottom to avoid circular imports
    # notifications relationship is defined in Notification model to avoid circular dependency
    
    def __repr__(self):
        return f"<User {self.email}>"

