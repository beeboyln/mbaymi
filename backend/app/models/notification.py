from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class Notification(Base):
    """🔔 Modèle de notification"""
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    type = Column(String(50), nullable=False)  # 'follow', 'comment', 'like', etc.
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    action_url = Column(String(500), nullable=True)  # URL pour naviguer
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # ID de l'utilisateur qui a déclenché
    actor_name = Column(String(255), nullable=True)  # Nom de la personne qui a déclenché la notif
    actor_image = Column(String(500), nullable=True)  # Image de la personne
    is_read = Column(Boolean, default=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)

    # Relations
    user = relationship("User", foreign_keys=[user_id], viewonly=True)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'type': self.type,
            'title': self.title,
            'description': self.description,
            'action_url': self.action_url,
            'actor_id': self.actor_id,
            'actor_name': self.actor_name,
            'actor_image': self.actor_image,
            'is_read': self.is_read,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
