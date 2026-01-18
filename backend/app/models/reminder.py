from sqlalchemy import Column, Integer, DateTime, ForeignKey, String, Boolean
from app.models.base import Base
from datetime import datetime

class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False)
    crop_id = Column(Integer, ForeignKey("crops.id"), nullable=True)
    title = Column(String(200), nullable=False)
    description = Column(String(1000), nullable=True)
    remind_at = Column(DateTime, nullable=False)
    repeat_rule = Column(String(200), nullable=True)  # e.g., daily, weekly, cron-ish
    is_done = Column(Boolean, default=False)
    notification_sent = Column(Boolean, default=False)  # Track if notification was already sent
    created_at = Column(DateTime, default=datetime.utcnow)
