from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from app.models.base import Base
from datetime import datetime

class Activity(Base):
    __tablename__ = "activities"

    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False)
    crop_id = Column(Integer, ForeignKey("crops.id"), nullable=True)
    input_id = Column(Integer, ForeignKey("inputs.id", ondelete="SET NULL"), nullable=True)
    quantity_used = Column(Float, nullable=True)
    finance_type = Column(String(20), nullable=True)
    finance_amount = Column(Float, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    activity_type = Column(String(100), nullable=False)  # labour, sowing, watering, treatment, harvest
    activity_date = Column(DateTime, default=datetime.utcnow)
    notes = Column(String(1000))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
