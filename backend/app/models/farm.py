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
    farm_id = Column(Integer, ForeignKey("farms.id", ondelete="CASCADE"), nullable=False)
    crop_name = Column(String(100), nullable=False)  # maïs, riz, arachide, millet, etc.
    planted_date = Column(DateTime)
    expected_harvest_date = Column(DateTime)
    quantity_planted = Column(Float)  # en kg
    expected_yield = Column(Float)  # rendement attendu
    variety = Column(String(100), nullable=True)
    cycle_duration_days = Column(Integer, nullable=True)  # Durée estimée du cycle en jours
    objective = Column(String(50), default="consumption")  # consumption / sale
    status = Column(String(50), default="growing")  # growing, harvested, failed
    notes = Column(String(500))
    image_url = Column(String(500))  # Photo de profil de la parcelle
    
    # Géométrie : polygone de la parcelle
    # Format JSON : [[lat1, lon1], [lat2, lon2], [lat3, lon3], ...]
    # Coordonnées en WGS84 (GPS standard)
    coordinates = Column(String(2000), nullable=True)  # JSON stringified polygon
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
