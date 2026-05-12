from fastapi import APIRouter, Depends, HTTPException, Query, Header
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime
from typing import Optional
from app.database import get_db
from app.models import Farm, FarmProfile, FarmPost, FarmFollowing, UserFollowing, User, Crop
from app.services.jwt_service import verify_token
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

router = APIRouter(prefix="/api/farm-network", tags=["Farm Network"])

# Helper function to extract user_id from Authorization header
def get_current_user(authorization: Optional[str] = Header(None)) -> int:
    """Extract user_id from JWT token in Authorization header."""
    if not authorization:
        logger.error("No authorization header provided")
        raise HTTPException(status_code=401, detail="Unauthorized - No authorization header")
    
    try:
        # Format: "Bearer <token>"
        parts = authorization.split()
        if len(parts) != 2:
            logger.error(f"Invalid authorization header format: {len(parts)} parts")
            raise HTTPException(status_code=401, detail="Invalid authorization header format")
        
        if parts[0].lower() != "bearer":
            logger.error(f"Invalid authorization scheme: {parts[0]}")
            raise HTTPException(status_code=401, detail="Invalid authorization scheme")
        
        token = parts[1]
        logger.debug(f"Attempting to verify token: {token[:20]}...")
        
        user_id = verify_token(token)
        if user_id is None:
            logger.error(f"Token verification failed for token: {token[:20]}...")
            raise HTTPException(status_code=401, detail="Invalid or expired token")
        
        logger.debug(f"✅ User {user_id} authenticated successfully")
        return user_id
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Auth error: {str(e)}")
        raise HTTPException(status_code=401, detail="Unauthorized")

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
        
        # Compter les followers depuis FarmFollowing
        followers_count = db.query(FarmFollowing).filter(FarmFollowing.farm_id == farm_id).count()
        
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
            "total_followers": followers_count,
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
    logger.info(f"🔍 search_farm_profiles called with q='{q}'")
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
            
            # Compter les followers depuis FarmFollowing
            followers_count = db.query(FarmFollowing).filter(FarmFollowing.farm_id == farm.id).count()
            
            farms_data.append({
                "farm_id": farm.id,
                "farm_name": farm.name,
                "location": farm.location,
                "specialties": specialties,
                "followers": followers_count,
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
        
        posts_list = []
        for post, farm, user in posts:
            # Check if current user liked this post
            is_liked = db.execute(text(f"SELECT id FROM post_likes WHERE post_id = {post.id} AND user_id = {user_id}")).fetchone() is not None
            
            posts_list.append({
                "id": post.id,
                "farm_id": post.farm_id,
                "farm_name": farm.name,
                "owner_name": user.name,
                "title": post.title,
                "description": post.description,
                "photo_url": post.photo_url,
                "post_type": post.post_type,
                "created_at": post.created_at.isoformat(),
                "likes_count": post.likes_count or 0,
                "comments_count": post.comments_count or 0,
                "shares_count": post.shares_count or 0,
                "is_liked": is_liked,
            })
        
        return {
            "count": len(posts_list),
            "posts": posts_list
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
        
        # 🔔 Créer une notification pour l'utilisateur suivi
        try:
            from app.services.notification_service import NotificationService
            NotificationService.create_notification(
                db=db,
                user_id=user_id_to_follow,
                notification_type='follow',
                title=f'{follower.name} vous suit',
                description=f'{follower.name} a commencé à vous suivre',
                actor_id=user_id,
                actor_name=follower.name,
                actor_image=follower.profile_image,
                action_url=f'/user-profile/{user_id}'
            )
        except Exception as e:
            print(f'⚠️ Failed to create notification: {str(e)}')
            # Ne pas échouer la requête si la notification échoue
        
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


@router.post("/follow-farm/{farm_id}")
def follow_farm(farm_id: int, user_id: int, db: Session = Depends(get_db)):
    """
    🌾 Suivre une ferme spécifique.
    """
    try:
        # 1. Check if already following
        existing = db.query(FarmFollowing).filter(
            FarmFollowing.follower_id == user_id,
            FarmFollowing.farm_id == farm_id
        ).first()
        
        if existing:
            return {"message": "Déjà suivi"}
        
        # 2. Ensure FarmProfile exists (create if missing)
        profile = db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id).first()
        if not profile:
            print(f'⚠️  Creating missing FarmProfile for farm {farm_id}')
            profile = FarmProfile(
                farm_id=farm_id,
                user_id=0,  # Set to 0 since we don't know the farm owner in this context
                is_public=True,
                description="",
                specialties="",
                total_followers=0
            )
            db.add(profile)
            db.flush()  # Flush to ensure profile has an ID
        
        # 3. Create FarmFollowing record
        following = FarmFollowing(follower_id=user_id, farm_id=farm_id)
        db.add(following)
        db.flush()  # Ensure the record is in the session
        
        # 4. Increment total_followers
        profile.total_followers = (profile.total_followers or 0) + 1
        db.commit()
        
        print(f'✅ User {user_id} following farm {farm_id}. New followers: {profile.total_followers}')
        return {"message": "Ferme suivie", "total_followers": profile.total_followers}
    except Exception as e:
        db.rollback()
        print(f'❌ Error following farm: {str(e)}')
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.delete("/follow-farm/{farm_id}")
def unfollow_farm(farm_id: int, user_id: int, db: Session = Depends(get_db)):
    """
    🌾 Arrêter de suivre une ferme.
    """
    try:
        # 1. Find the follow record
        following = db.query(FarmFollowing).filter(
            FarmFollowing.follower_id == user_id,
            FarmFollowing.farm_id == farm_id
        ).first()
        
        if not following:
            print(f'⚠️ User {user_id} is not following farm {farm_id}')
            return {"message": "Ferme non suivie"}
        
        # 2. Delete the follow record
        db.delete(following)
        db.flush()  # Ensure the deletion is in the session
        
        # 3. Get or create FarmProfile
        profile = db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id).first()
        if not profile:
            print(f'⚠️ Creating missing FarmProfile for farm {farm_id}')
            profile = FarmProfile(
                farm_id=farm_id,
                user_id=0,
                is_public=True,
                description="",
                specialties="",
                total_followers=0
            )
            db.add(profile)
            db.flush()
        
        # 4. Decrement total_followers
        profile.total_followers = max(0, (profile.total_followers or 1) - 1)
        db.commit()
        
        print(f'✅ User {user_id} unfollowed farm {farm_id}. New followers: {profile.total_followers}')
        return {"message": "Ferme non suivie", "total_followers": profile.total_followers}
    except Exception as e:
        db.rollback()
        print(f'❌ Error unfollowing farm: {str(e)}')
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/farm-following/{user_id}")
def get_farm_following_ids(user_id: int, db: Session = Depends(get_db)):
    """
    🌾 Récupérer la liste des fermes qu'un user suit.
    """
    try:
        following = db.query(FarmFollowing).filter(FarmFollowing.follower_id == user_id).all()
        
        return {
            "count": len(following),
            "farm_ids": [f.farm_id for f in following],
            "following": [
                {
                    "farm_id": f.farm_id,
                }
                for f in following
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/user-following/{user_id}")
def get_users_following(user_id: int, db: Session = Depends(get_db)):
    """
    👥 Récupérer la liste des utilisateurs qu'un user suit (UserFollowing).
    Retourne les IDs des utilisateurs suivis pour les fermes publiques.
    """
    try:
        # Récupérer tous les enregistrements UserFollowing où ce user est le follower
        following = db.query(UserFollowing).filter(UserFollowing.follower_id == user_id).all()
        
        return {
            "count": len(following),
            "following_ids": [f.following_id for f in following],
            "following": [
                {
                    "following_id": f.following_id,
                }
                for f in following
            ]
        }
    except Exception as e:
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
        
        # Compter les followers depuis FarmFollowing
        followers_count = db.query(FarmFollowing).filter(FarmFollowing.farm_id == farm_id).count()
        
        return {
            "farm_id": farm.id,
            "farm_name": farm.name,
            "location": farm.location,
            "owner_name": user.name if user else "Agriculteur",
            "owner_id": farm.user_id,
            "description": profile.description or "",
            "specialties": specialties,
            "followers": followers_count,
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
    try:
        # Récupérer les profils publics avec jointures optimisées
        profiles = db.query(FarmProfile, Farm, User)\
            .join(Farm, FarmProfile.farm_id == Farm.id)\
            .join(User, Farm.user_id == User.id)\
            .filter(FarmProfile.is_public == True)\
            .order_by(FarmProfile.created_at.desc())\
            .offset(skip)\
            .limit(limit)\
            .all()
        
        # Transformer les résultats
        farms_list = []
        for profile, farm, user in profiles:
            # Traiter les spécialités de manière sûre
            specialties = []
            if profile.specialties:
                try:
                    specialties = [s.strip() for s in profile.specialties.split(",") if s.strip()]
                except:
                    specialties = []
            
            # Compter les followers depuis FarmFollowing
            followers_count = db.query(FarmFollowing).filter(FarmFollowing.farm_id == farm.id).count()
            
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
                "followers": followers_count,
            }
            farms_list.append(farm_data)
        
        return {
            "count": len(farms_list),
            "farms": farms_list
        }
        
    except Exception as e:
        logger.error(f"❌ [get_public_farms] ERREUR: {type(e).__name__}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/public-farms/{farm_id}/crops")
def get_public_farm_crops(farm_id: int, db: Session = Depends(get_db)):
    """
    🌿 Récupérer les cultures/parcelles d'une ferme publique (sans authentification requise).
    
    Permet aux utilisateurs non-authentifiés de voir les cultures d'une ferme publique.
    """
    try:
        # Vérifier que la ferme est publique
        farm_profile = db.query(FarmProfile).filter(
            FarmProfile.farm_id == farm_id,
            FarmProfile.is_public == True
        ).first()
        
        if not farm_profile:
            # Farm doesn't exist or is not public
            return []
        
        # Récupérer les cultures de cette ferme
        crops = db.query(Crop).filter(
            Crop.farm_id == farm_id
        ).all()
        
        crops_list = []
        for crop in crops:
            crop_data = {
                "id": crop.id,
                "farm_id": crop.farm_id,
                "crop_name": crop.crop_name,
                "status": crop.status,
                "planted_date": crop.planted_date.isoformat() if crop.planted_date else None,
                "expected_harvest_date": crop.expected_harvest_date.isoformat() if crop.expected_harvest_date else None,
                "area": crop.area,
                "image_url": crop.image_url,
            }
            crops_list.append(crop_data)
        
        return crops_list
        
    except Exception as e:
        logger.error(f"❌ [get_public_farm_crops] ERREUR: {type(e).__name__}: {str(e)}", exc_info=True)
        return []  # Return empty list instead of error for graceful degradation


# ═══════════════════════════════════════════════════════════════════════════
# SOCIAL INTERACTIONS - Likes, Comments, Shares
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/posts/{post_id}/like")
def like_post(post_id: int, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    ❤️ Aimer un post.
    """
    try:
        # Vérifier que le post existe
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        # Vérifier qu'on n'a pas déjà aimé
        existing_like = db.execute(
            f"SELECT id FROM post_likes WHERE post_id = {post_id} AND user_id = {user_id}"
        ).first()
        
        if existing_like:
            return {"message": "✅ Déjà aimé"}
        
        # Ajouter le like
        db.execute(
            f"INSERT INTO post_likes (post_id, user_id, created_at) VALUES ({post_id}, {user_id}, NOW())"
        )
        
        # Incrémenter le compteur
        db.query(FarmPost).filter(FarmPost.id == post_id).update(
            {FarmPost.likes_count: FarmPost.likes_count + 1}
        )
        
        db.commit()
        return {"message": "❤️ Vous aimez ce post"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error liking post: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.delete("/posts/{post_id}/like")
def unlike_post(post_id: int, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    🤍 Retirer un like d'un post.
    """
    try:
        # Vérifier que le post existe
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        # Supprimer le like
        db.execute(
            f"DELETE FROM post_likes WHERE post_id = {post_id} AND user_id = {user_id}"
        )
        
        # Décrémenter le compteur
        db.query(FarmPost).filter(FarmPost.id == post_id).update(
            {FarmPost.likes_count: FarmPost.likes_count - 1}
        )
        
        db.commit()
        return {"message": "🤍 Like retiré"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error unliking post: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/posts/{post_id}/comments")
def get_post_comments(post_id: int, db: Session = Depends(get_db)):
    """
    💬 Récupérer les commentaires d'un post.
    """
    try:
        # Vérifier que le post existe
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        # Récupérer les commentaires
        comments = db.execute(
            f"""
            SELECT c.id, c.content, c.user_id, u.name as user_name, c.created_at
            FROM post_comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.post_id = {post_id}
            ORDER BY c.created_at DESC
            """
        ).fetchall()
        
        comments_data = [
            {
                "id": c[0],
                "content": c[1],
                "user_id": c[2],
                "user_name": c[3],
                "created_at": c[4].isoformat() if c[4] else None,
            }
            for c in comments
        ]
        
        return {"count": len(comments_data), "comments": comments_data}
        
    except Exception as e:
        logger.error(f"❌ Error getting comments: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.post("/posts/{post_id}/comment")
def comment_on_post(
    post_id: int,
    request_body: dict,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    💬 Commenter un post.
    Expects: {"content": "Votre commentaire"}
    """
    try:
        content = request_body.get("content", "").strip()
        if not content:
            raise HTTPException(status_code=400, detail="Contenu du commentaire vide")
        
        # Vérifier que le post existe
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        # Ajouter le commentaire
        db.execute(
            f"INSERT INTO post_comments (post_id, user_id, content, created_at) VALUES ({post_id}, {user_id}, '{content.replace(chr(39), chr(39)*2)}', NOW())"
        )
        
        # Incrémenter le compteur
        db.query(FarmPost).filter(FarmPost.id == post_id).update(
            {FarmPost.comments_count: FarmPost.comments_count + 1}
        )
        
        db.commit()
        return {"message": "💬 Commentaire ajouté"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error commenting: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.post("/posts/{post_id}/share")
def share_post(post_id: int, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    📤 Partager un post.
    """
    try:
        # Vérifier que le post existe
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        # Ajouter le partage
        db.execute(
            f"INSERT INTO post_shares (post_id, user_id, created_at) VALUES ({post_id}, {user_id}, NOW())"
        )
        
        # Incrémenter le compteur
        db.query(FarmPost).filter(FarmPost.id == post_id).update(
            {FarmPost.shares_count: FarmPost.shares_count + 1}
        )
        
        db.commit()
        return {"message": "📤 Post partagé"}
        
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error sharing post: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


# ═══════════════════════════════════════════════════════════════════════════
# LIVESTOCK SOCIAL INTERACTIONS - Likes, Comments, Shares for Animals
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/livestock/{livestock_id}/like")
def like_livestock(livestock_id: int, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    ❤️ Aimer un animal (livestock).
    """
    try:
        # Import here to avoid circular imports
        from app.models.livestock import Livestock
        
        # Vérifier que l'animal existe
        livestock = db.query(Livestock).filter(Livestock.id == livestock_id).first()
        if not livestock:
            raise HTTPException(status_code=404, detail="Animal non trouvé")
        
        # Vérifier qu'on n'a pas déjà aimé
        existing_like = db.execute(
            text(f"SELECT id FROM livestock_likes WHERE livestock_id = {livestock_id} AND user_id = {user_id}")
        ).first()
        
        if existing_like:
            return {"message": "✅ Déjà aimé"}
        
        # Ajouter le like
        db.execute(
            text(f"INSERT INTO livestock_likes (livestock_id, user_id, created_at) VALUES ({livestock_id}, {user_id}, NOW())")
        )
        
        # Incrémenter le compteur
        db.query(Livestock).filter(Livestock.id == livestock_id).update(
            {Livestock.likes_count: Livestock.likes_count + 1}
        )
        
        db.commit()
        return {"message": "❤️ Vous aimez cet animal"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error liking livestock: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.delete("/livestock/{livestock_id}/like")
def unlike_livestock(livestock_id: int, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    🤍 Retirer un like d'un animal.
    """
    try:
        from app.models.livestock import Livestock
        
        # Vérifier que l'animal existe
        livestock = db.query(Livestock).filter(Livestock.id == livestock_id).first()
        if not livestock:
            raise HTTPException(status_code=404, detail="Animal non trouvé")
        
        # Supprimer le like
        db.execute(
            text(f"DELETE FROM livestock_likes WHERE livestock_id = {livestock_id} AND user_id = {user_id}")
        )
        
        # Décrémenter le compteur
        db.query(Livestock).filter(Livestock.id == livestock_id).update(
            {Livestock.likes_count: Livestock.likes_count - 1}
        )
        
        db.commit()
        return {"message": "🤍 Like retiré"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error unliking livestock: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")
