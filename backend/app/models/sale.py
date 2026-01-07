from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey, String
from app.models.base import Base
from datetime import datetime

class Sale(Base):
    __tablename__ = "sales"

    id = Column(Integer, primary_key=True, index=True)
    harvest_id = Column(Integer, ForeignKey("harvests.id"), nullable=True)
    product_name = Column(String(200), nullable=False)
    quantity = Column(Float, nullable=False)
    price_per_unit = Column(Float, nullable=False)
    currency = Column(String(10), default="CFA")
    delivery_location = Column(String(200))
    contact = Column(String(100))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
