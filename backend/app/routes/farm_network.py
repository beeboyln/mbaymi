from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
from app.database import get_db
from app.models import Farm, FarmProfile, FarmPost, FarmFollowing, User, Crop
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

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
    q: Optional[str] = Query(None),
    specialty: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """
    🔍 Rechercher des fermes publiques.
    
    Exemple : /profiles/search?specialty=tomate
    """
    try:
        query = db.query(FarmProfile, Farm).join(Farm, FarmProfile.farm_id == Farm.id).filter(FarmProfile.is_public == True)
        
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
        posts = db.query(FarmPost, Farm, User).join(Farm, FarmPost.farm_id == Farm.id).join(User, Farm.user_id == User.id)\
            .filter(FarmPost.farm_id.in_(farm_ids))\
            .order_by(FarmPost.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
        
        return {
            "count": len(posts),
            "posts": [
                {
                    "id": post.id,
                    "farm_id": post.farm_id,
                    "farm_name": farm.name,
                    "owner_name": user.name,
                    "title": post.title,
                    "description": post.description,
                    "photo_url": post.photo_url,
                    "post_type": post.post_type,
                    "created_at": post.created_at.isoformat(),
                }
                for post, farm, user in posts
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
        print(f'➕ Follow request: farm_id={farm_id}, user_id={user_id}')
        
        # Vérifier que la ferme existe
        farm = db.query(Farm).filter(Farm.id == farm_id).first()
        if not farm:
            print(f'❌ Farm {farm_id} not found')
            raise HTTPException(status_code=404, detail="Ferme non trouvée")
        
        # Vérifier que l'utilisateur existe
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            print(f'❌ User {user_id} not found')
            raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
        
        # Vérifier qu'on ne suit pas déjà
        existing = db.query(FarmFollowing).filter(
            FarmFollowing.follower_id == user_id,
            FarmFollowing.farm_id == farm_id
        ).first()
        if existing:
            print(f'⚠️ User {user_id} already follows farm {farm_id}')
            return {"message": "✅ Ferme suivie"}  # Retourner 200 au lieu de 400
        
        # Créer la relation
        following = FarmFollowing(follower_id=user_id, farm_id=farm_id)
        db.add(following)
        
        # Incrémenter le compteur dans FarmProfile
        profile = db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id).first()
        if profile:
            profile.total_followers += 1
            print(f'✅ Updated followers count for farm {farm_id}: {profile.total_followers}')
        else:
            print(f'⚠️ No FarmProfile found for farm {farm_id}')
        
        db.commit()
        print(f'✅ Farm {farm_id} followed by user {user_id}')
        
        return {"message": "✅ Ferme suivie"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f'❌ Error following farm: {str(e)}')
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.delete("/follow/{farm_id}")
def unfollow_farm(farm_id: int, user_id: int, db: Session = Depends(get_db)):
    """
    ➖ Arrêter de suivre une ferme.
    """
    try:
        print(f'➖ Unfollow request: farm_id={farm_id}, user_id={user_id}')
        
        following = db.query(FarmFollowing).filter(
            FarmFollowing.follower_id == user_id,
            FarmFollowing.farm_id == farm_id
        ).first()
        if not following:
            print(f'⚠️ User {user_id} is not following farm {farm_id}')
            return {"message": "❌ Ferme non suivie"}  # Retourner 200 au lieu de 404
        
        db.delete(following)
        
        # Décrémenter le compteur
        profile = db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id).first()
        if profile and profile.total_followers > 0:
            profile.total_followers -= 1
            print(f'✅ Updated followers count for farm {farm_id}: {profile.total_followers}')
        
        db.commit()
        print(f'✅ Farm {farm_id} unfollowed by user {user_id}')
        
        return {"message": "❌ Ferme non suivie"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f'❌ Error unfollowing farm: {str(e)}')
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/following/{user_id}")
def get_user_following(user_id: int, db: Session = Depends(get_db)):
    """
    📋 Récupérer les fermes suivies par un utilisateur.
    """
    try:
        following = db.query(FarmFollowing, Farm).join(Farm, FarmFollowing.farm_id == Farm.id)\
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

@router.get("/details/{farm_id}")
def get_farm_details(farm_id: int, db: Session = Depends(get_db)):
    """
    📋 Récupérer les détails complets d'une ferme publique avec crops et photos.
    """
    try:
        # Vérifier que c'est une ferme publique
        profile = db.query(FarmProfile).filter(
            FarmProfile.farm_id == farm_id,
            FarmProfile.is_public == True
        ).first()
        
        if not profile:
            raise HTTPException(status_code=404, detail="Ferme non trouvée ou privée")
        
        # Récupérer la ferme et l'utilisateur
        farm = db.query(Farm).filter(Farm.id == farm_id).first()
        user = db.query(User).filter(User.id == farm.user_id).first()
        
        if not farm:
            raise HTTPException(status_code=404, detail="Ferme non trouvée")
        
        # Récupérer les crops
        crops = db.query(Crop).filter(Crop.farm_id == farm_id).all()
        crops_data = [
            {
                "id": c.id,
                "farm_id": c.farm_id,
                "crop_name": c.crop_name,
                "planted_date": c.planted_date,
                "expected_harvest_date": c.expected_harvest_date,
                "quantity_planted": c.quantity_planted,
                "expected_yield": c.expected_yield,
                "status": c.status,
                "notes": c.notes,
                "created_at": c.created_at,
                "updated_at": c.updated_at,
            }
            for c in crops
        ]
        
        # Récupérer les photos de la ferme
        from app.models.photo import FarmPhoto
        photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == farm_id).all()
        photos_data = [
            {
                "id": p.id,
                "image_url": p.image_url,
                "created_at": p.created_at,
            }
            for p in photos
        ]
        
        return {
            "farm_id": farm.id,
            "farm_name": farm.name,
            "location": farm.location,
            "owner_name": user.name if user else "Agriculteur",
            "owner_id": farm.user_id,
            "description": profile.description,
            "specialties": profile.specialties.split(",") if profile.specialties else [],
            "followers": profile.total_followers,
            "is_public": profile.is_public,
            "crops": crops_data,
            "photos": photos_data,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [get_farm_details] ERREUR: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/public-farms")
def get_public_farms(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    """
    🌾 Récupérer les fermes publiques (à découvrir).
    
    Affiche les fermes qui ont été rendues publiques par leurs propriétaires.
    """
    logger.info(f"📍 [get_public_farms] Début - skip={skip}, limit={limit}")
    try:
        # Vérifier les tables existent
        logger.debug("🔍 [get_public_farms] Vérification des tables...")
        farm_profile_count = db.query(FarmProfile).count()
        logger.info(f"✅ [get_public_farms] farm_profiles table existe - {farm_profile_count} lignes")
        
        farm_count = db.query(Farm).count()
        logger.info(f"✅ [get_public_farms] farms table existe - {farm_count} lignes")
        
        user_count = db.query(User).count()
        logger.info(f"✅ [get_public_farms] users table existe - {user_count} lignes")
        
        # Récupérer les profils publics
        logger.debug("🔍 [get_public_farms] Exécution de la query...")
        profiles = db.query(FarmProfile, Farm, User)\
            .join(Farm, FarmProfile.farm_id == Farm.id)\
            .join(User, Farm.user_id == User.id)\
            .filter(FarmProfile.is_public == True)\
            .order_by(FarmProfile.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
        
        logger.info(f"✅ [get_public_farms] Query réussie - {len(profiles)} fermes trouvées")
        
        # Transformer les résultats
        farms_list = []
        for idx, (profile, farm, user) in enumerate(profiles):
            logger.debug(f"  📦 Traitement ferme {idx+1}/{len(profiles)}: farm_id={farm.id}, farm_name={farm.name}")
            farm_data = {
                "farm_id": farm.id,
                "farm_name": farm.name,
                "location": farm.location,
                "owner_name": user.name,
                "description": profile.description,
                "specialties": profile.specialties.split(",") if profile.specialties else [],
                "followers": profile.total_followers,
            }
            farms_list.append(farm_data)
        
        result = {
            "count": len(farms_list),
            "farms": farms_list
        }
        logger.info(f"✅ [get_public_farms] Succès - Retour {len(farms_list)} fermes")
        return result
        
    except Exception as e:
        logger.error(f"❌ [get_public_farms] ERREUR: {type(e).__name__}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")