"""
🔔 Reminder Worker - Checks and sends notifications for due reminders
Runs periodically to check if any reminders are due and creates notifications
"""
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.reminder import Reminder
from app.models.farm import Farm
from app.services.notification_service import NotificationService
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


def check_due_reminders():
    """Check for due reminders and create notifications"""
    db: Session = SessionLocal()
    try:
        # Get all reminders that are due and haven't sent notification yet
        now = datetime.utcnow()
        
        due_reminders = db.query(Reminder).filter(
            Reminder.remind_at <= now,
            Reminder.is_done == False,
            Reminder.notification_sent == False
        ).all()
        
        if not due_reminders:
            logger.debug(f"No due reminders to notify")
            return
            
        logger.info(f"📢 Found {len(due_reminders)} due reminders to notify")
        
        for reminder in due_reminders:
            logger.info(f"📢 Processing due reminder: {reminder.id} - {reminder.title}")
            
            # Get farm and owner
            farm = db.query(Farm).filter(Farm.id == reminder.farm_id).first()
            if not farm:
                logger.warning(f"Farm {reminder.farm_id} not found for reminder {reminder.id}")
                continue
                
            try:
                # Create notification for farm owner
                NotificationService.create_notification(
                    db=db,
                    user_id=farm.user_id,
                    title=f"📋 Rappel: {reminder.title}",
                    description=reminder.description or reminder.title,
                    notification_type="reminder",
                    actor_id=None,
                    actor_name="Rappel",
                    action_url=f"/reminder/{reminder.id}",
                    farm_id=reminder.farm_id,
                    crop_id=reminder.crop_id,
                )
                
                # Mark notification as sent
                reminder.notification_sent = True
                db.commit()
                logger.info(f"✅ Notification created and marked for reminder {reminder.id}")
            except Exception as e:
                logger.error(f"❌ Error creating notification for reminder {reminder.id}: {e}")
                db.rollback()
                
    except Exception as e:
        logger.error(f"❌ Error in check_due_reminders: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    check_due_reminders()
