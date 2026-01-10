from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
from app.database import get_db
from app.models import Farm, FarmProfile, FarmPost, FarmFollowing, UserFollowing, User, Crop
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
        
        # Safe specialties handling
        specialties = []
        if profile.specialties:
            try:
                specialties = [s.strip() for s in profile.specialties.split(",") if s.strip()]
            except Exception:
                specialties = []
        
        return {
            "id": profile.id,
            "farm_id": profile.farm_id,
            "description": profile.description or "",
            "specialties": specialties,
            "is_public": profile.is_public,
            "total_followers": profile.total_followers or 0,
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
        
        # Safe specialties handling
        specialties = []
        if profile.specialties:
            try:
                specialties = [s.strip() for s in profile.specialties.split(",") if s.strip()]
            except Exception:
                specialties = []
        
        return {
            "id": profile.id,
            "farm_id": profile.farm_id,
            "farm_name": farm.name,
            "farm_location": farm.location,
            "owner_name": user.name if user else "Agriculteur",
            "description": profile.description or "",
            "specialties": specialties,
            "is_public": profile.is_public,
            "total_followers": profile.total_followers or 0,
            "created_at": profile.created_at.isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/profiles/search")
def search_farm_profiles(
    q: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """
    🔍 Rechercher des fermes publiques par nom ou localisation.
    
    Exemple : /profiles/search?q=tomate
    """
    try:
        query = db.query(FarmProfile, Farm).join(Farm, FarmProfile.farm_id == Farm.id).filter(FarmProfile.is_public == True)
        
        if q and q.strip():
            search_term = f"%{q.strip()}%"
            query = query.filter(
                (Farm.name.ilike(search_term)) | 
                (Farm.location.ilike(search_term))
            )
        
        results = query.all()
        
        farms_data = []
        for profile, farm in results:
            # Safe specialties handling
            specialties = []
            if profile.specialties:
                try:
                    specialties = [s.strip() for s in profile.specialties.split(",") if s.strip()]
                except Exception:
                    specialties = []
            
            farms_data.append({
                "farm_id": farm.id,
                "farm_name": farm.name,
                "location": farm.location,
                "specialties": specialties,
                "followers": profile.total_followers or 0,
            })
        
        return {
            "count": len(farms_data),
            "farms": farms_data
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
    📰 Récupérer le fil d'actualité (posts des utilisateurs suivis).
    """
    try:
        # Récupérer les utilisateurs que l'utilisateur suit
        following = db.query(UserFollowing.following_id).filter(UserFollowing.follower_id == user_id).all()
        following_ids = [f[0] for f in following]
        
        if not following_ids:
            return {"count": 0, "posts": []}
        
        # Récupérer les posts de ces utilisateurs (via leurs fermes)
        posts = db.query(FarmPost, Farm, User).join(Farm, FarmPost.farm_id == Farm.id).join(User, Farm.user_id == User.id)\
            .filter(Farm.user_id.in_(following_ids))\
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
# SUIVRE DES UTILISATEURS (Propriétaires de fermes)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/follow-user/{user_id_to_follow}")
def follow_user(user_id_to_follow: int, user_id: int, db: Session = Depends(get_db)):
    """
    ➕ Suivre un utilisateur (propriétaire de ferme).
    """
    try:
        print(f'➕ Follow user request: following_id={user_id_to_follow}, follower_id={user_id}')
        
        # Vérifier qu'on ne se suit pas soi-même
        if user_id == user_id_to_follow:
            print(f'⚠️ User {user_id} cannot follow themselves')
            return {"message": "Vous ne pouvez pas vous suivre vous-même"}
        
        # Vérifier que l'utilisateur suivi existe
        user_to_follow = db.query(User).filter(User.id == user_id_to_follow).first()
        if not user_to_follow:
            print(f'❌ User {user_id_to_follow} not found')
            raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
        
        # Vérifier que le follower existe
        follower = db.query(User).filter(User.id == user_id).first()
        if not follower:
            print(f'❌ Follower user {user_id} not found')
            raise HTTPException(status_code=404, detail="Utilisateur courant non trouvé")
        
        # Vérifier qu'on ne suit pas déjà
        existing = db.query(UserFollowing).filter(
            UserFollowing.follower_id == user_id,
            UserFollowing.following_id == user_id_to_follow
        ).first()
        if existing:
            print(f'⚠️ User {user_id} already follows user {user_id_to_follow}')
            return {"message": "✅ Utilisateur suivi"}
        
        # Créer la relation
        following = UserFollowing(follower_id=user_id, following_id=user_id_to_follow)
        db.add(following)
        db.commit()
        
        print(f'✅ User {user_id_to_follow} followed by user {user_id}')
        
        return {"message": "✅ Utilisateur suivi"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f'❌ Error following user: {str(e)}')
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.delete("/follow-user/{user_id_to_unfollow}")
def unfollow_user(user_id_to_unfollow: int, user_id: int, db: Session = Depends(get_db)):
    """
    ➖ Arrêter de suivre un utilisateur.
    """
    try:
        print(f'➖ Unfollow user request: following_id={user_id_to_unfollow}, follower_id={user_id}')
        
        following = db.query(UserFollowing).filter(
            UserFollowing.follower_id == user_id,
            UserFollowing.following_id == user_id_to_unfollow
        ).first()
        if not following:
            print(f'⚠️ User {user_id} is not following user {user_id_to_unfollow}')
            return {"message": "❌ Utilisateur non suivi"}
        
        db.delete(following)
        db.commit()
        
        print(f'✅ User {user_id_to_unfollow} unfollowed by user {user_id}')
        
        return {"message": "❌ Utilisateur non suivi"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f'❌ Error unfollowing user: {str(e)}')
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
        crops_data = []
        for c in crops:
            crop_dict = {
                "id": c.id,
                "farm_id": c.farm_id,
                "crop_name": c.crop_name,
                "planted_date": c.planted_date.isoformat() if c.planted_date else None,
                "expected_harvest_date": c.expected_harvest_date.isoformat() if c.expected_harvest_date else None,
                "quantity_planted": c.quantity_planted,
                "expected_yield": c.expected_yield,
                "status": c.status,
                "notes": c.notes,
                "created_at": c.created_at.isoformat() if c.created_at else None,
                "updated_at": c.updated_at.isoformat() if c.updated_at else None,
            }
            # Safely add image_url if it exists
            try:
                crop_dict["image_url"] = c.image_url
            except AttributeError:
                crop_dict["image_url"] = None
            crops_data.append(crop_dict)
        
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
        
        # Safe specialties handling
        specialties = []
        if profile.specialties:
            try:
                specialties = [s.strip() for s in profile.specialties.split(",") if s.strip()]
            except Exception:
                specialties = []
        
        return {
            "farm_id": farm.id,
            "farm_name": farm.name,
            "location": farm.location,
            "owner_name": user.name if user else "Agriculteur",
            "owner_id": farm.user_id,
            "description": profile.description or "",
            "specialties": specialties,
            "followers": profile.total_followers or 0,
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
            
            # Traiter les spécialités de manière sûre
            specialties = []
            if profile.specialties:
                try:
                    specialties = [s.strip() for s in profile.specialties.split(",") if s.strip()]
                except Exception as e:
                    logger.warning(f"  ⚠️ Erreur en traitant specialties: {e}")
                    specialties = []
            
            farm_data = {
                "farm_id": farm.id,
                "farm_name": farm.name,
                "location": farm.location,
                "user_id": user.id,
                "owner_name": user.name,
                "profile_image": getattr(user, 'profile_image', None),
                "profile_image_farm": farm.image_url,
                "description": profile.description or "",
                "specialties": specialties,
                "followers": profile.total_followers or 0,
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