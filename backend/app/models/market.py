from sqlalchemy import Column, Integer, String, Float, DateTime
from app.models.base import Base
from datetime import datetime

class MarketPrice(Base):
    __tablename__ = "market_prices"
    
    id = Column(Integer, primary_key=True, index=True)
    product_name = Column(String(100), nullable=False)  # maïs, riz, arachide, etc.
    region = Column(String(100), nullable=False)
    price_per_kg = Column(Float)
    currency = Column(String(10), default="CFA")
    price_date = Column(DateTime, default=datetime.utcnow)
    source = Column(String(100))  # ministry, market_data, etc.
    created_at = Column(DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f"<MarketPrice {self.product_name} - {self.region}>"
