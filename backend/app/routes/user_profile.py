from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Farm, FarmProfile, FarmPost
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/users", tags=["User Profile"])

# ═══════════════════════════════════════════════════════════════════════════
# USER PROFILE (Profil personnel)
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/{user_id}/profile")
def get_user_profile(user_id: int, db: Session = Depends(get_db)):
    """
    👤 Récupérer le profil personnel d'un utilisateur.
    """
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
        
        # Récupérer toutes les fermes de l'utilisateur
        farms = db.query(Farm).filter(Farm.user_id == user_id).all()
        
        # Récupérer les profils publics de l'utilisateur (via Farm.user_id)
        farm_ids = [f.id for f in farms]
        profiles = db.query(FarmProfile).filter(FarmProfile.farm_id.in_(farm_ids)).all() if farm_ids else []
        
        # Compter les followers totaux
        total_followers = sum(p.total_followers for p in profiles)
        
        # Compter les posts totaux
        total_posts = db.query(FarmPost).filter(FarmPost.user_id == user_id).count()
        
        return {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "phone": getattr(user, 'phone', None),
            "profile_image": getattr(user, 'profile_image', None),
            "total_farms": len(farms),
            "total_followers": total_followers,
            "total_posts": total_posts,
            "farms": [
                {
                    "id": f.id,
                    "name": f.name,
                    "location": f.location,
                    "is_public": db.query(FarmProfile).filter(FarmProfile.farm_id == f.id).first().is_public if db.query(FarmProfile).filter(FarmProfile.farm_id == f.id).first() else False,
                }
                for f in farms
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.put("/{user_id}/profile")
def update_user_profile(
    user_id: int,
    name: str = None,
    email: str = None,
    profile_image: str = None,
    db: Session = Depends(get_db)
):
    """
    ✏️ Mettre à jour le profil utilisateur (nom, email et photo de profil).
    """
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
        
        # Valider et mettre à jour le nom
        if name:
            name = name.strip()
            if len(name) < 2:
                raise HTTPException(status_code=400, detail="Le nom doit contenir au moins 2 caractères")
            user.name = name
        
        # Valider et mettre à jour l'email
        if email:
            email = email.strip().lower()
            # Vérifier que l'email n'existe pas déjà (sauf pour cet utilisateur)
            existing_user = db.query(User).filter(
                User.email == email,
                User.id != user_id
            ).first()
            if existing_user:
                raise HTTPException(status_code=400, detail="Cet email est déjà utilisé")
            user.email = email
        
        # Mettre à jour la photo de profil si fournie
        if profile_image:
            profile_image = profile_image.strip()
            user.profile_image = profile_image
        
        db.commit()
        db.refresh(user)
        
        return {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "profile_image": getattr(user, 'profile_image', None),
            "success": True,
            "message": "Profil mis à jour avec succès"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/{user_id}/posts")
def get_user_posts(user_id: int, skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    """
    📰 Récupérer tous les posts d'un utilisateur.
    """
    try:
        # Récupérer les fermes de l'utilisateur
        farms = db.query(Farm).filter(Farm.user_id == user_id).all()
        farm_ids = [f.id for f in farms]
        
        if not farm_ids:
            return {"count": 0, "posts": []}
        
        # Récupérer les posts des fermes
        posts = db.query(FarmPost).filter(FarmPost.farm_id.in_(farm_ids))\
            .order_by(FarmPost.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
        
        posts_data = []
        for post in posts:
            farm = db.query(Farm).filter(Farm.id == post.farm_id).first()
            posts_data.append({
                "id": post.id,
                "farm_id": post.farm_id,
                "farm_name": farm.name if farm else "Unknown",
                "title": post.title,
                "description": post.description,
                "photo_url": post.photo_url,
                "post_type": post.post_type,
                "created_at": post.created_at.isoformat() if post.created_at else None,
            })
        
        return {
            "count": len(posts_data),
            "posts": posts_data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.put("/{user_id}/farms/{farm_id}/visibility")
def toggle_farm_visibility(user_id: int, farm_id: int, is_public: bool, db: Session = Depends(get_db)):
    """
    🔒 Rendre une ferme publique ou privée dans le réseau agricole.
    
    Exemple :
    PUT /api/users/1/farms/5/visibility?is_public=true
    """
    try:
        # Vérifier que la ferme appartient à l'utilisateur
        farm = db.query(Farm).filter(Farm.id == farm_id, Farm.user_id == user_id).first()
        if not farm:
            raise HTTPException(status_code=404, detail="Ferme non trouvée")
        
        # Récupérer ou créer le profil de la ferme
        profile = db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id).first()
        
        if not profile:
            # Créer un profil par défaut
            profile = FarmProfile(
                farm_id=farm_id,
                user_id=user_id,
                is_public=is_public,
                description="",
                specialties="",
            )
            db.add(profile)
        else:
            # Mettre à jour la visibilité
            profile.is_public = is_public
        
        db.commit()
        db.refresh(profile)
        
        return {
            "farm_id": farm_id,
            "is_public": profile.is_public,
            "message": f"Ferme {'✅ rendue publique' if is_public else '🔒 rendue privée'}"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")



