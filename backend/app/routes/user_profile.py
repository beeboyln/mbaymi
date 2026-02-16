from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.models import User, Farm, FarmPost, Crop, Livestock, UserFollowing
from app.models.farm_post import FarmPostLike
from app.models.farm_network import FarmProfile
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/users", tags=["User Profile"])

# ═══════════════════════════════════════════════════════════════════════════
# USER PROFILE (Profil personnel)
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/{user_id}/profile")
def get_user_profile(user_id: int, viewer_id: Optional[int] = None, db: Session = Depends(get_db)):
    """
    👤 Récupérer le profil personnel d'un utilisateur.
    """
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
        
        # Récupérer toutes les fermes de l'utilisateur
        farms = db.query(Farm).filter(Farm.user_id == user_id).all()
        farm_ids = [f.id for f in farms]
        
        # Compter les posts totaux
        total_posts = db.query(FarmPost).filter(FarmPost.user_id == user_id).count() if farm_ids else 0
        
        # Récupérer tous les crops d'une seule requête
        all_crops = db.query(Crop).filter(Crop.farm_id.in_(farm_ids)).all() if farm_ids else []
        
        # Récupérer tous les livestock par user_id
        all_livestock = db.query(Livestock).filter(Livestock.user_id == user_id).all()
        
        # Créer des dictionnaires pour compter
        crops_by_farm = {}
        for crop in all_crops:
            crops_by_farm[crop.farm_id] = crops_by_farm.get(crop.farm_id, 0) + 1
        
        # Pour livestock, on met juste le total (pas associé à une ferme spécifique)
        livestock_count = len(all_livestock)
        
        # Calculer le nombre total de followers depuis la table UserFollowing
        try:
            total_followers = db.query(UserFollowing).filter(UserFollowing.following_id == user_id).count()
        except Exception:
            total_followers = 0

        # Déterminer si le viewer courant suit cet utilisateur
        followed_by_user = False
        if viewer_id:
            followed_by_user = db.query(UserFollowing).filter(
                UserFollowing.follower_id == viewer_id,
                UserFollowing.following_id == user_id
            ).first() is not None

        return {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "phone": getattr(user, 'phone', None),
            "profile_image": getattr(user, 'profile_image', None),
            "total_farms": len(farms),
            "total_followers": total_followers,
            "followed_by_user": followed_by_user,
            "total_posts": total_posts,
            "farms": [
                {
                    "id": f.id,
                    "name": f.name,
                    "location": f.location,
                    "image_url": f.image_url,
                    "crops_count": crops_by_farm.get(f.id, 0),
                    "livestock_count": livestock_count,
                    "is_public": False,
                }
                for f in farms
            ]
        }
    except Exception as e:
        logger.error(f"Erreur dans get_user_profile pour user_id={user_id}: {str(e)}", exc_info=True)
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
def get_user_posts(user_id: int, skip: int = 0, limit: int = 20, viewer_id: Optional[int] = None, db: Session = Depends(get_db)):
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
            # likes count from post
            likes_count = getattr(post, 'likes_count', 0) if hasattr(post, 'likes_count') else 0
            liked_by_user = False
            if viewer_id:
                liked = db.query(FarmPostLike).filter(
                    FarmPostLike.farm_post_id == post.id,
                    FarmPostLike.user_id == viewer_id
                ).first()
                liked_by_user = liked is not None

            posts_data.append({
                "id": post.id,
                "farm_id": post.farm_id,
                "farm_name": farm.name if farm else "Unknown",
                "title": post.title,
                "description": post.description,
                "photo_url": post.photo_url,
                "post_type": post.post_type,
                "created_at": post.created_at.isoformat() if post.created_at else None,
                "likes_count": likes_count,
                "liked_by_user": liked_by_user,
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
            db.flush()  # Flush to ensure the object has an ID before commit
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
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        import traceback
        error_detail = f"Error toggling visibility: {str(e)} | {traceback.format_exc()}"
        raise HTTPException(status_code=500, detail=error_detail)



