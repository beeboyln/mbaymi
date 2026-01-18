from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey, String
from app.models.base import Base
from datetime import datetime

class Input(Base):
    __tablename__ = "inputs"

    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False)
    crop_id = Column(Integer, ForeignKey("crops.id"), nullable=True)
    input_type = Column(String(50))  # seeds, fertilizer, pesticide, other
    name = Column(String(150))  # e.g., NPK 15-15-15, hybrid maize seeds
    quantity = Column(Float, nullable=True)
    unit = Column(String(50), nullable=True)  # kg, L, g, units
    applied_date = Column(DateTime, default=datetime.utcnow)
    cost = Column(Float, nullable=True)
    notes = Column(String(1000), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
