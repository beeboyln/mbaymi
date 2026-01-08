from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Farm, FarmProfile, FarmPost

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
        
        # Récupérer les profils publics de l'utilisateur
        profiles = db.query(FarmProfile).filter(FarmProfile.user_id == user_id).all()
        
        # Compter les followers totaux
        total_followers = sum(p.total_followers for p in profiles)
        
        # Compter les posts totaux
        total_posts = db.query(FarmPost).filter(FarmPost.user_id == user_id).count()
        
        return {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "phone": getattr(user, 'phone', None),
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


@router.get("/{user_id}/posts")
def get_user_posts(user_id: int, skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    """
    📰 Récupérer tous les posts d'un utilisateur.
    """
    try:
        posts = db.query(FarmPost, Farm).join(Farm).filter(FarmPost.user_id == user_id)\
            .order_by(FarmPost.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
        
        return {
            "count": len(posts),
            "posts": [
                {
                    "id": p.FarmPost.id,
                    "farm_id": p.FarmPost.farm_id,
                    "farm_name": p.Farm.name,
                    "title": p.FarmPost.title,
                    "description": p.FarmPost.description,
                    "photo_url": p.FarmPost.photo_url,
                    "post_type": p.FarmPost.post_type,
                    "created_at": p.FarmPost.created_at.isoformat(),
                }
                for p in posts
            ]
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
