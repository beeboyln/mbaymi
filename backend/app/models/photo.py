from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from app.models.base import Base
from datetime import datetime


class FarmPhoto(Base):
    __tablename__ = 'farm_photos'

    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, ForeignKey('farms.id', ondelete='CASCADE'), nullable=False)
    image_url = Column(String(500), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class ActivityPhoto(Base):
    __tablename__ = 'activity_photos'

    id = Column(Integer, primary_key=True, index=True)
    activity_id = Column(Integer, ForeignKey('activities.id', ondelete='CASCADE'), nullable=False)
    image_url = Column(String(500), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
