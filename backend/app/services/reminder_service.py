from sqlalchemy.orm import Session
from app.models.reminder import Reminder
from datetime import datetime
from typing import Optional, List
from app.services.notification_service import NotificationService


class ReminderService:
    @staticmethod
    def create_reminder(db: Session, data: dict) -> Reminder:
        r = Reminder(
            farm_id=data.get("farm_id"),
            crop_id=data.get("crop_id"),
            title=data.get("title"),
            description=data.get("description"),
            remind_at=data.get("remind_at"),
            repeat_rule=data.get("repeat_rule"),
            is_done=False,
            created_at=datetime.utcnow(),
        )
        db.add(r)
        db.commit()
        db.refresh(r)

        # Optionally create an in-app notification for the owner (best-effort)
        try:
            # If farm owner user_id is known elsewhere, integration would go here.
            pass
        except Exception:
            pass

        return r

    @staticmethod
    def get_reminder(db: Session, reminder_id: int) -> Optional[Reminder]:
        return db.query(Reminder).filter(Reminder.id == reminder_id).first()

    @staticmethod
    def list_reminders_for_farm(db: Session, farm_id: int, skip: int = 0, limit: int = 100) -> List[Reminder]:
        return db.query(Reminder).filter(Reminder.farm_id == farm_id).order_by(Reminder.remind_at.asc()).offset(skip).limit(limit).all()

    @staticmethod
    def list_reminders_for_crop(db: Session, crop_id: int, skip: int = 0, limit: int = 100) -> List[Reminder]:
        return db.query(Reminder).filter(Reminder.crop_id == crop_id).order_by(Reminder.remind_at.asc()).offset(skip).limit(limit).all()

    @staticmethod
    def mark_done(db: Session, reminder_id: int) -> Optional[Reminder]:
        r = db.query(Reminder).filter(Reminder.id == reminder_id).first()
        if not r:
            return None
        r.is_done = True
        db.commit()
        db.refresh(r)
        return r

    @staticmethod
    def update_reminder(db: Session, reminder_id: int, updates: dict) -> Optional[Reminder]:
        r = db.query(Reminder).filter(Reminder.id == reminder_id).first()
        if not r:
            return None
        for k, v in updates.items():
            if hasattr(r, k):
                setattr(r, k, v)
        db.commit()
        db.refresh(r)
        return r

    @staticmethod
    def delete_reminder(db: Session, reminder_id: int) -> bool:
        r = db.query(Reminder).filter(Reminder.id == reminder_id).first()
        if not r:
            return False
        db.delete(r)
        db.commit()
        return True
