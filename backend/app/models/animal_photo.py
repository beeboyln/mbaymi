from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from app.models.base import Base
from datetime import datetime

class AnimalPhoto(Base):
    __tablename__ = "animal_photos"
    
    id = Column(Integer, primary_key=True, index=True)
    livestock_id = Column(Integer, ForeignKey("livestock.id", ondelete="CASCADE"), nullable=False)
    image_url = Column(String(500), nullable=False)  # Cloudinary URL
    caption = Column(Text)  # Description/caption de la photo
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
