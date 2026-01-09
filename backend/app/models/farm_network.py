from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, Boolean
from app.models.base import Base
from datetime import datetime

class FarmProfile(Base):
    """
    Profil public d'une ferme pour le réseau agricole.
    Permet aux agriculteurs de partager et apprendre des autres.
    """
    __tablename__ = "farm_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False, unique=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Visibilité
    is_public = Column(Boolean, default=True)  # Visible dans le réseau agricole ?
    
    # Description de la ferme
    description = Column(Text)  # "Ferme familiale spécialisée en cultures maraîchères"
    
    # Tags/spécialités
    specialties = Column(String(500))  # "tomate,oignon,carotte" (séparés par virgules)
    
    # Statistiques
    total_followers = Column(Integer, default=0)
    
    # Métadonnées
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class FarmPost(Base):
    """
    Posts d'une ferme : partage de photos de cultures, résultats, expériences.
    """
    __tablename__ = "farm_posts"
    
    id = Column(Integer, primary_key=True, index=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    crop_id = Column(Integer, ForeignKey("crops.id"), nullable=True)  # Post lié à une culture
    
    # Contenu
    title = Column(String(200), nullable=False)  # "Récolte réussie de tomates"
    description = Column(Text)
    photo_url = Column(String(500))
    
    # Type de post
    post_type = Column(String(50), default="crop_update")  # crop_update, harvest_result, problem_report, tip, etc.
    
    # Métadonnées
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class FarmFollowing(Base):
    """
    Relation de suivi entre agriculteurs.
    DEPRECATED: Utilisez UserFollowing à la place.
    Un utilisateur suit maintenant un autre utilisateur (propriétaire de ferme) au lieu de suivre une ferme.
    """
    __tablename__ = "farm_following"
    
    id = Column(Integer, primary_key=True, index=True)
    follower_id = Column(Integer, ForeignKey("users.id"), nullable=False)  # Qui suit
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False)  # Quelle ferme
    
    # Métadonnées
    created_at = Column(DateTime, default=datetime.utcnow)

