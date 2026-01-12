from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import Optional
from app.database import get_db
from app.models.farm_post import FarmImagePost, FarmPostLike, FarmPostComment, FarmPostShare
from app.models.farm import Farm
from app.models.user import User
from app.schemas.schemas import FarmPostCreate
from app.services.jwt_service import verify_token
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

router = APIRouter(prefix="/farm-posts", tags=["farm_posts"])

# Helper function to extract user_id from Authorization header
def get_current_user(authorization: Optional[str] = Header(None)) -> int:
    """Extract user_id from JWT token in Authorization header."""
    logger.info(f"🔍 get_current_user called with authorization header: {authorization[:50] if authorization else 'NONE'}...")
    
    if not authorization:
        logger.error("❌ No authorization header provided")
        raise HTTPException(status_code=401, detail="Unauthorized - No authorization header")
    
    try:
        # Format: "Bearer <token>"
        parts = authorization.split()
        if len(parts) != 2:
            logger.error(f"❌ Invalid authorization header format: {len(parts)} parts")
            raise HTTPException(status_code=401, detail="Invalid authorization header format")
        
        if parts[0].lower() != "bearer":
            logger.error(f"❌ Invalid authorization scheme: {parts[0]}")
            raise HTTPException(status_code=401, detail="Invalid authorization scheme")
        
        token = parts[1]
        logger.debug(f"🔑 Token received: {token[:20]}...")
        
        # verify_token returns int (user_id) or None
        user_id = verify_token(token)
        
        if not user_id:
            logger.error("❌ Token verification failed or no user_id in token")
            raise HTTPException(status_code=401, detail="Invalid token")
        
        logger.info(f"✅ User authenticated: {user_id}")
        return user_id
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Token verification failed: {str(e)}")
        raise HTTPException(status_code=401, detail=f"Unauthorized: {str(e)}")


@router.post("/", response_model=dict)
def create_farm_post(farm_post: FarmPostCreate, user_id: int, db: Session = Depends(get_db)):
    """Créer un nouveau post image pour une ferme"""
    farm = db.query(Farm).filter(Farm.id == farm_post.farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Ferme non trouvée")
    
    if farm.user_id != user_id:
        raise HTTPException(status_code=403, detail="Vous n'êtes pas le propriétaire de cette ferme")
    
    new_post = FarmImagePost(
        farm_id=farm_post.farm_id,
        user_id=user_id,
        image_url=farm_post.image_url,
        caption=farm_post.caption,
    )
    
    db.add(new_post)
    db.commit()
    db.refresh(new_post)
    
    return {
        "id": new_post.id,
        "farm_id": new_post.farm_id,
        "image_url": new_post.image_url,
        "caption": new_post.caption,
        "likes_count": 0,
        "comments_count": 0,
        "shares_count": 0,
        "created_at": new_post.created_at.isoformat(),
    }


@router.get("/feed")
def get_farm_posts_feed(user_id: int = None, db: Session = Depends(get_db)):
    """Récupérer tous les farm posts pour le feed social"""
    posts = db.query(FarmImagePost).order_by(desc(FarmImagePost.created_at)).all()
    
    result = []
    for post in posts:
        farm = db.query(Farm).filter(Farm.id == post.farm_id).first()
        user = db.query(User).filter(User.id == post.user_id).first()
        
        is_liked = False
        if user_id and user_id > 0:
            like = db.query(FarmPostLike).filter(
                FarmPostLike.farm_post_id == post.id,
                FarmPostLike.user_id == user_id
            ).first()
            is_liked = like is not None
        
        result.append({
            "id": post.id,
            "farm_id": post.farm_id,
            "farm_name": farm.name if farm else "Ferme inconnue",
            "owner_name": user.name if user else "Utilisateur",
            "owner_profile_image": user.profile_image if user else None,
            "user_id": post.user_id,
            "image_url": post.image_url,
            "caption": post.caption,
            "likes_count": post.likes_count,
            "comments_count": post.comments_count,
            "shares_count": post.shares_count,
            "created_at": post.created_at.isoformat(),
            "is_liked": is_liked,
        })
    
    return result


@router.get("/{farm_id}")
def get_farm_posts(farm_id: int, user_id: int = None, db: Session = Depends(get_db)):
    """Récupérer tous les posts d'une ferme spécifique"""
    posts = db.query(FarmImagePost).filter(FarmImagePost.farm_id == farm_id).order_by(desc(FarmImagePost.created_at)).all()
    
    result = []
    for post in posts:
        is_liked = False
        if user_id and user_id > 0:
            like = db.query(FarmPostLike).filter(
                FarmPostLike.farm_post_id == post.id,
                FarmPostLike.user_id == user_id
            ).first()
            is_liked = like is not None

        user = db.query(User).filter(User.id == post.user_id).first()

        result.append({
            "id": post.id,
            "farm_id": post.farm_id,
            "owner_name": user.name if user else "Utilisateur",
            "owner_profile_image": user.profile_image if user else None,
            "user_id": post.user_id,
            "image_url": post.image_url,
            "caption": post.caption,
            "likes_count": post.likes_count,
            "comments_count": post.comments_count,
            "shares_count": post.shares_count,
            "created_at": post.created_at.isoformat(),
            "is_liked": is_liked,
        })
    
    return result


@router.post("/{post_id}/like")
def like_farm_post(post_id: int, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """Liker un post"""
    post = db.query(FarmImagePost).filter(FarmImagePost.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post non trouvé")
    
    existing_like = db.query(FarmPostLike).filter(
        FarmPostLike.farm_post_id == post_id,
        FarmPostLike.user_id == user_id
    ).first()
    
    if existing_like:
        raise HTTPException(status_code=400, detail="Déjà likké")
    
    new_like = FarmPostLike(farm_post_id=post_id, user_id=user_id)
    db.add(new_like)
    post.likes_count += 1
    db.commit()
    
    return {"success": True, "likes_count": post.likes_count}


@router.delete("/{post_id}/like")
def unlike_farm_post(post_id: int, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    """Retirer un like"""
    post = db.query(FarmImagePost).filter(FarmImagePost.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post non trouvé")
    
    like = db.query(FarmPostLike).filter(
        FarmPostLike.farm_post_id == post_id,
        FarmPostLike.user_id == user_id
    ).first()
    
    if not like:
        raise HTTPException(status_code=400, detail="Pas likké")
    
    db.delete(like)
    post.likes_count = max(post.likes_count - 1, 0)
    db.commit()
    
    return {"success": True, "likes_count": post.likes_count}


@router.post("/{post_id}/share")
def share_farm_post(post_id: int, user_id: int, db: Session = Depends(get_db)):
    """Partager un post"""
    post = db.query(FarmImagePost).filter(FarmImagePost.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post non trouvé")
    
    new_share = FarmPostShare(farm_post_id=post_id, user_id=user_id)
    db.add(new_share)
    post.shares_count += 1
    db.commit()
    
    return {"success": True, "shares_count": post.shares_count}


@router.delete("/{post_id}")
def delete_farm_post(post_id: int, user_id: int, db: Session = Depends(get_db)):
    """Supprimer un post de ferme. Autorisé si l'utilisateur est l'auteur du post ou le propriétaire de la ferme."""
    post = db.query(FarmImagePost).filter(FarmImagePost.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post non trouvé")

    # Vérifier la ferme associée
    farm = db.query(Farm).filter(Farm.id == post.farm_id).first()

    # Autoriser si user est l'auteur du post ou propriétaire de la ferme
    if not (post.user_id == user_id or (farm and farm.user_id == user_id)):
        raise HTTPException(status_code=403, detail="Non autorisé à supprimer ce post")

    # Supprimer le post (les contraintes FK doivent nettoyer likes/comments/shares si définies)
    try:
        db.delete(post)
        db.commit()
        return {"success": True, "message": "Post supprimé"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur suppression: {e}")

