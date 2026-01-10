from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from app.models.base import Base
from datetime import datetime

class Farm(Base):
    __tablename__ = "farms"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    location = Column(String(200))
    size_hectares = Column(Float)  # Taille en hectares
    soil_type = Column(String(50))  # sandy, loamy, clay
    image_url = Column(String(500))
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Crop(Base):
    __tablename__ = "crops"
    
    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False)
    crop_name = Column(String(100), nullable=False)  # maïs, riz, arachide, millet, etc.
    planted_date = Column(DateTime)
    expected_harvest_date = Column(DateTime)
    quantity_planted = Column(Float)  # en kg
    expected_yield = Column(Float)  # rendement attendu
    status = Column(String(50), default="growing")  # growing, harvested, failed
    notes = Column(String(500))
    image_url = Column(String(500))  # Photo de profil de la parcelle
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
