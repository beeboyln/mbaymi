from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from app.models.base import Base
from datetime import datetime

class PastureImage(Base):
    __tablename__ = "pasture_images"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    image_url = Column(String(500), nullable=False)  # Cloudinary URL
    title = Column(String(200))  # Nom du pâturage/enclos
    description = Column(Text)  # Description de la photo
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
