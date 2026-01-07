from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from app.models.base import Base
from datetime import datetime

class Livestock(Base):
    __tablename__ = "livestock"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    animal_type = Column(String(50), nullable=False)  # cattle, goat, sheep, poultry, pig
    breed = Column(String(100))
    quantity = Column(Integer, default=1)
    age_months = Column(Integer)
    weight_kg = Column(Float)
    health_status = Column(String(50), default="healthy")  # healthy, sick, vaccinated
    last_vaccination_date = Column(DateTime)
    feeding_type = Column(String(100))  # grass, grains, mixed
    location = Column(String(200))
    notes = Column(String(500))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
