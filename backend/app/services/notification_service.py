from sqlalchemy.orm import Session
from app.models.notification import Notification
from datetime import datetime
from typing import Optional

class NotificationService:
    """🔔 Service pour gérer les notifications"""

    @staticmethod
    def create_notification(
        db: Session,
        user_id: int,
        notification_type: str,
        title: str,
        description: str,
        action_url: Optional[str] = None,
        actor_id: Optional[int] = None,
        actor_name: Optional[str] = None,
        actor_image: Optional[str] = None,
    ) -> Notification:
        """Créer une nouvelle notification"""
        notification = Notification(
            user_id=user_id,
            type=notification_type,
            title=title,
            description=description,
            action_url=action_url,
            actor_id=actor_id,
            actor_name=actor_name,
            actor_image=actor_image,
            is_read=False,
            created_at=datetime.utcnow(),
        )
        db.add(notification)
        db.commit()
        db.refresh(notification)
        return notification

    @staticmethod
    def get_user_notifications(
        db: Session,
        user_id: int,
        skip: int = 0,
        limit: int = 20,
    ) -> list:
        """Récupérer les notifications d'un utilisateur"""
        notifications = db.query(Notification)\
            .filter(Notification.user_id == user_id)\
            .order_by(Notification.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
        return notifications

    @staticmethod
    def get_unread_count(db: Session, user_id: int) -> int:
        """Compter les notifications non lues"""
        count = db.query(Notification)\
            .filter(
                Notification.user_id == user_id,
                Notification.is_read == False
            )\
            .count()
        return count

    @staticmethod
    def mark_as_read(db: Session, notification_id: int, user_id: int) -> bool:
        """Marquer une notification comme lue"""
        notification = db.query(Notification)\
            .filter(
                Notification.id == notification_id,
                Notification.user_id == user_id
            )\
            .first()
        
        if not notification:
            return False
        
        notification.is_read = True
        db.commit()
        return True

    @staticmethod
    def mark_all_as_read(db: Session, user_id: int) -> int:
        """Marquer toutes les notifications comme lues"""
        count = db.query(Notification)\
            .filter(
                Notification.user_id == user_id,
                Notification.is_read == False
            )\
            .update({"is_read": True})
        db.commit()
        return count

    @staticmethod
    def delete_notification(db: Session, notification_id: int, user_id: int) -> bool:
        """Supprimer une notification"""
        notification = db.query(Notification)\
            .filter(
                Notification.id == notification_id,
                Notification.user_id == user_id
            )\
            .first()
        
        if not notification:
            return False
        
        db.delete(notification)
        db.commit()
        return True

    @staticmethod
    def delete_old_notifications(db: Session, days: int = 30) -> int:
        """Supprimer les notifications de plus de X jours (entretien)"""
        from datetime import timedelta
        threshold = datetime.utcnow() - timedelta(days=days)
        count = db.query(Notification)\
            .filter(Notification.created_at < threshold)\
            .delete()
        db.commit()
        return count
