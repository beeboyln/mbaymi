from sqlalchemy import Column, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from .base import Base
from datetime import datetime

class UserFollowing(Base):
    """
    Relation de suivi entre utilisateurs (propriétaires de fermes).
    Un utilisateur peut suivre un autre utilisateur.
    """
    __tablename__ = "user_following"

    id = Column(Integer, primary_key=True, index=True)
    follower_id = Column(Integer, ForeignKey("users.id"), nullable=False)  # Qui suit
    following_id = Column(Integer, ForeignKey("users.id"), nullable=False)  # Qui est suivi
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relations optionnelles
    follower = relationship("User", foreign_keys=[follower_id], backref="following")
    following = relationship("User", foreign_keys=[following_id], backref="followers")
