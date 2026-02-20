from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, func, Float
from datetime import datetime
from app.models.base import Base


class FarmImagePost(Base):
    __tablename__ = "farm_image_posts"

    id = Column(Integer, primary_key=True)
    farm_id = Column(Integer, ForeignKey("farms.id", ondelete="CASCADE"), nullable=True)
    livestock_id = Column(Integer, ForeignKey("livestock.id", ondelete="CASCADE"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    image_url = Column(String(500))
    caption = Column(Text)
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    shares_count = Column(Integer, default=0)
    
    # 💰 PRIX & VENTE
    post_intent = Column(String(20), default="share")  # "sell" ou "share"
    price = Column(Float, nullable=True)  # Prix optionnel
    product_name = Column(String(100), nullable=True)  # Nom du produit vendu
    unit = Column(String(20), default="kg")  # kg, litre, pièce, etc.
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<FarmImagePost(id={self.id}, farm_id={self.farm_id}, caption={self.caption[:50]})>"

    def to_dict(self):
        return {
            "id": self.id,
            "farm_id": self.farm_id,
            "user_id": self.user_id,
            "image_url": self.image_url,
            "caption": self.caption,
            "likes_count": self.likes_count,
            "comments_count": self.comments_count,
            "shares_count": self.shares_count,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }


class FarmPostLike(Base):
    __tablename__ = "farm_post_likes"

    id = Column(Integer, primary_key=True)
    farm_post_id = Column(Integer, ForeignKey("farm_image_posts.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<FarmPostLike(farm_post_id={self.farm_post_id}, user_id={self.user_id})>"


class FarmPostComment(Base):
    __tablename__ = "farm_post_comments"

    id = Column(Integer, primary_key=True)
    farm_post_id = Column(Integer, ForeignKey("farm_image_posts.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    parent_id = Column(Integer, ForeignKey("farm_post_comments.id", ondelete="CASCADE"), nullable=True)
    comment = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<FarmPostComment(farm_post_id={self.farm_post_id}, user_id={self.user_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "farm_post_id": self.farm_post_id,
            "user_id": self.user_id,
            "comment": self.comment,
            "parent_id": self.parent_id,
            "created_at": self.created_at.isoformat(),
        }


class FarmPostShare(Base):
    __tablename__ = "farm_post_shares"

    id = Column(Integer, primary_key=True)
    farm_post_id = Column(Integer, ForeignKey("farm_image_posts.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<FarmPostShare(farm_post_id={self.farm_post_id}, user_id={self.user_id})>"
