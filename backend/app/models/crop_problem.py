from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from app.models.base import Base
from datetime import datetime

class CropProblem(Base):
    """
    Modèle pour signaler les maladies, ravageurs, et problèmes de cultures.
    
    Exemple :
    - Jaunissement des feuilles
    - Feuilles trouées (ravageurs)
    - Mauvais rendement
    - Pourriture
    """
    __tablename__ = "crop_problems"
    
    id = Column(Integer, primary_key=True, index=True)
    crop_id = Column(Integer, ForeignKey("crops.id"), nullable=False)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Type de problème
    problem_type = Column(String(100), nullable=False)  # yellowing, leaf_holes, poor_yield, rot, pest, disease, etc.
    description = Column(Text)  # Description détaillée du problème
    
    # Photo du problème
    photo_url = Column(String(500))
    
    # Sévérité
    severity = Column(String(20), default="medium")  # low, medium, high
    
    # Status
    status = Column(String(20), default="reported")  # reported, identified, treated, resolved
    
    # Métadonnées
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Notes sur le traitement
    treatment_notes = Column(Text)
