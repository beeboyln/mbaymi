from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey, String
from app.models.base import Base
from datetime import datetime

class Harvest(Base):
    __tablename__ = "harvests"

    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False)
    crop_id = Column(Integer, ForeignKey("crops.id"), nullable=True)
    estimated_quantity = Column(Float)
    actual_quantity = Column(Float)
    harvest_date = Column(DateTime, default=datetime.utcnow)
    notes = Column(String(1000))
    created_at = Column(DateTime, default=datetime.utcnow)
