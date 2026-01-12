from sqlalchemy import Column, Integer, String, Float, DateTime, Index
from datetime import datetime
from app.models.base import Base


class MarketTrend(Base):
    __tablename__ = "market_trends"

    id = Column(Integer, primary_key=True, index=True)
    product_name = Column(String(100), nullable=False, index=True)
    region = Column(String(100), nullable=True, index=True)
    avg_price = Column(Float, default=0)
    min_price = Column(Float, nullable=True)
    max_price = Column(Float, nullable=True)
    count = Column(Integer, default=1)
    currency = Column(String(10), default="CFA")
    unit = Column(String(20), default="kg")
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<MarketTrend(product={self.product_name}, region={self.region}, avg_price={self.avg_price})>"

    def to_dict(self):
        return {
            "id": self.id,
            "product_name": self.product_name,
            "region": self.region,
            "avg_price": self.avg_price,
            "min_price": self.min_price,
            "max_price": self.max_price,
            "count": self.count,
            "currency": self.currency,
            "unit": self.unit,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
