from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from app.database import get_db
from app.models import Farm, FarmProfile, FarmPost, FarmFollowing, User

router = APIRouter(prefix="/api/farm-network", tags=["Farm Network"])

# ═══════════════════════════════════════════════════════════════════════════
# FARM PROFILES (Profils publics des fermes)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/profiles/{farm_id}")
def create_farm_profile(
    farm_id: int,
    user_id: int,
    description: str = "",
    specialties: str = "",  # "tomate,oignon,carotte"
    is_public: bool = True,
    db: Session = Depends(get_db)
):
    """
    🌾 Créer un profil public pour une ferme.
    
    Specialties format : "tomate,riz,mil" (séparé par virgules)
    """
    try:
        # Vérifier que la ferme existe et appartient à l'utilisateur
        farm = db.query(Farm).filter(Farm.id == farm_id, Farm.user_id == user_id).first()
        if not farm:
            raise HTTPException(status_code=404, detail="Ferme non trouvée")
        
        # Vérifier qu'un profil n'existe pas déjà
        existing = db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="Profil déjà créé pour cette ferme")
        
        profile = FarmProfile(
            farm_id=farm_id,
            user_id=user_id,
            description=description,
            specialties=specialties,
            is_public=is_public,
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
        
        return {
            "id": profile.id,
            "farm_id": profile.farm_id,
            "description": profile.description,
            "specialties": profile.specialties.split(",") if profile.specialties else [],
            "is_public": profile.is_public,
            "total_followers": profile.total_followers,
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/profiles/{farm_id}")
def get_farm_profile(farm_id: int, db: Session = Depends(get_db)):
    """
    📋 Récupérer le profil public d'une ferme.
    """
    try:
        profile = db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id, FarmProfile.is_public == True).first()
        if not profile:
            raise HTTPException(status_code=404, detail="Profil non trouvé")
        
        farm = db.query(Farm).filter(Farm.id == farm_id).first()
        user = db.query(User).filter(User.id == farm.user_id).first()
        
        return {
            "id": profile.id,
            "farm_id": profile.farm_id,
            "farm_name": farm.name,
            "farm_location": farm.location,
            "owner_name": user.name if user else "Agriculteur",
            "description": profile.description,
            "specialties": profile.specialties.split(",") if profile.specialties else [],
            "is_public": profile.is_public,
            "total_followers": profile.total_followers,
            "created_at": profile.created_at.isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/profiles/search")
def search_farm_profiles(
    q: str | None = None,  # Recherche par nom, région, spécialité
    specialty: str | None = None,
    db: Session = Depends(get_db)
):
    """
    🔍 Rechercher des fermes publiques.
    
    Exemple : /profiles/search?specialty=tomate
    """
    try:
        query = db.query(FarmProfile, Farm).join(Farm).filter(FarmProfile.is_public == True)
        
        if q and q.strip():
            query = query.filter(
                (Farm.name.ilike(f"%{q}%")) | 
                (Farm.location.ilike(f"%{q}%"))
            )
        
        if specialty and specialty.strip():
            query = query.filter(FarmProfile.specialties.ilike(f"%{specialty}%"))
        
        results = query.all()
        
        return {
            "count": len(results),
            "farms": [
                {
                    "farm_id": farm.id,
                    "farm_name": farm.name,
                    "location": farm.location,
                    "specialties": profile.specialties.split(",") if profile.specialties else [],
                    "followers": profile.total_followers,
                }
                for profile, farm in results
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


# ═══════════════════════════════════════════════════════════════════════════
# FARM POSTS (Publications de cultures)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/posts")
def create_farm_post(
    farm_id: int,
    user_id: int,
    title: str,
    description: str = "",
    photo_url: str = None,
    post_type: str = "crop_update",  # crop_update, harvest_result, problem_report, tip
    crop_id: int = None,
    db: Session = Depends(get_db)
):
    """
    📸 Publier une mise à jour sur une culture.
    
    Types de post :
    - crop_update : Mise à jour de culture
    - harvest_result : Résultat de récolte
    - problem_report : Signalement de problème
    - tip : Conseil/astuce agricole
    """
    try:
        farm = db.query(Farm).filter(Farm.id == farm_id, Farm.user_id == user_id).first()
        if not farm:
            raise HTTPException(status_code=404, detail="Ferme non trouvée")
        
        post = FarmPost(
            farm_id=farm_id,
            user_id=user_id,
            crop_id=crop_id,
            title=title,
            description=description,
            photo_url=photo_url,
            post_type=post_type,
        )
        db.add(post)
        db.commit()
        db.refresh(post)
        
        return {
            "id": post.id,
            "farm_id": post.farm_id,
            "title": post.title,
            "post_type": post.post_type,
            "created_at": post.created_at.isoformat(),
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/posts/farm/{farm_id}")
def get_farm_posts(farm_id: int, skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    """
    📺 Récupérer tous les posts d'une ferme.
    """
    try:
        posts = db.query(FarmPost).filter(FarmPost.farm_id == farm_id)\
            .order_by(FarmPost.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
        
        return {
            "count": len(posts),
            "posts": [
                {
                    "id": p.id,
                    "title": p.title,
                    "description": p.description,
                    "photo_url": p.photo_url,
                    "post_type": p.post_type,
                    "created_at": p.created_at.isoformat(),
                }
                for p in posts
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/feed")
def get_farm_feed(user_id: int, skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    """
    📰 Récupérer le fil d'actualité (posts des fermes suivies).
    """
    try:
        # Récupérer les fermes que l'utilisateur suit
        following = db.query(FarmFollowing.farm_id).filter(FarmFollowing.follower_id == user_id).all()
        farm_ids = [f[0] for f in following]
        
        if not farm_ids:
            return {"count": 0, "posts": []}
        
        # Récupérer les posts de ces fermes
        posts = db.query(FarmPost, Farm, User).join(Farm).join(User, Farm.user_id == User.id)\
            .filter(FarmPost.farm_id.in_(farm_ids))\
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
                    "owner_name": p.User.name,
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


# ═══════════════════════════════════════════════════════════════════════════
# FARM FOLLOWING (Suivre des fermes)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/follow/{farm_id}")
def follow_farm(farm_id: int, user_id: int, db: Session = Depends(get_db)):
    """
    ➕ Suivre une ferme.
    """
    try:
        farm = db.query(Farm).filter(Farm.id == farm_id).first()
        if not farm:
            raise HTTPException(status_code=404, detail="Ferme non trouvée")
        
        # Vérifier qu'on ne suit pas déjà
        existing = db.query(FarmFollowing).filter(
            FarmFollowing.follower_id == user_id,
            FarmFollowing.farm_id == farm_id
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="Vous suivez déjà cette ferme")
        
        # Créer la relation
        following = FarmFollowing(follower_id=user_id, farm_id=farm_id)
        db.add(following)
        
        # Incrémenter le compteur
        profile = db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id).first()
        if profile:
            profile.total_followers += 1
        
        db.commit()
        
        return {"message": "✅ Ferme suivie"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.delete("/follow/{farm_id}")
def unfollow_farm(farm_id: int, user_id: int, db: Session = Depends(get_db)):
    """
    ➖ Arrêter de suivre une ferme.
    """
    try:
        following = db.query(FarmFollowing).filter(
            FarmFollowing.follower_id == user_id,
            FarmFollowing.farm_id == farm_id
        ).first()
        if not following:
            raise HTTPException(status_code=404, detail="Vous ne suivez pas cette ferme")
        
        db.delete(following)
        
        # Décrémenter le compteur
        profile = db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id).first()
        if profile and profile.total_followers > 0:
            profile.total_followers -= 1
        
        db.commit()
        
        return {"message": "❌ Ferme non suivie"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/following/{user_id}")
def get_user_following(user_id: int, db: Session = Depends(get_db)):
    """
    📋 Récupérer les fermes suivies par un utilisateur.
    """
    try:
        following = db.query(FarmFollowing, Farm).join(Farm)\
            .filter(FarmFollowing.follower_id == user_id)\
            .all()
        
        return {
            "count": len(following),
            "farms": [
                {
                    "farm_id": farm.id,
                    "farm_name": farm.name,
                    "location": farm.location,
                }
                for _, farm in following
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")

@router.get("/public-farms")
def get_public_farms(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    """
    🌾 Récupérer les fermes publiques (à découvrir).
    
    Affiche les fermes qui ont été rendues publiques par leurs propriétaires.
    """
    try:
        profiles = db.query(FarmProfile, Farm, User)\
            .join(Farm)\
            .join(User, Farm.user_id == User.id)\
            .filter(FarmProfile.is_public == True)\
            .order_by(FarmProfile.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
        
        return {
            "count": len(profiles),
            "farms": [
                {
                    "farm_id": p.Farm.id,
                    "farm_name": p.Farm.name,
                    "location": p.Farm.location,
                    "owner_name": p.User.name,
                    "description": p.FarmProfile.description,
                    "specialties": p.FarmProfile.specialties.split(",") if p.FarmProfile.specialties else [],
                    "followers": p.FarmProfile.total_followers,
                }
                for p, farm, user in profiles
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")