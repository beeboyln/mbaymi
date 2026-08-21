from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import desc
from typing import Optional
from pydantic import BaseModel
from app.database import get_db
from app.models.farm_post import FarmImagePost, FarmPostLike, FarmPostComment, FarmPostShare
from app.models.farm import Farm
from app.models.user import User
from app.models.user_following import UserFollowing
from app.models.livestock import Livestock
from app.schemas.schemas import FarmPostCreate
from app.services.jwt_service import verify_token
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# ═══════════════════════════════════════════════════════════════════════════
# SCHEMAS
# ═══════════════════════════════════════════════════════════════════════════

class AddCommentRequest(BaseModel):
    comment_text: str
    user_id: int
    parent_id: Optional[int] = None

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
    """Créer un nouveau post image pour une ferme ou un animal"""
    
    # Vérifier farm_id OU livestock_id
    farm_id = getattr(farm_post, 'farm_id', None)
    livestock_id = getattr(farm_post, 'livestock_id', None)
    
    if farm_id:
        farm = db.query(Farm).filter(Farm.id == farm_id).first()
        if not farm:
            raise HTTPException(status_code=404, detail="Ferme non trouvée")
        
        if farm.user_id != user_id:
            raise HTTPException(status_code=403, detail="Vous n'êtes pas le propriétaire de cette ferme")
    
    if livestock_id:
        from app.models.livestock import Livestock
        livestock = db.query(Livestock).filter(Livestock.id == livestock_id).first()
        if not livestock:
            raise HTTPException(status_code=404, detail="Animal non trouvé")
        
        if livestock.user_id != user_id:
            raise HTTPException(status_code=403, detail="Vous n'êtes pas le propriétaire de cet animal")
    
    if not farm_id and not livestock_id:
        raise HTTPException(status_code=400, detail="farm_id ou livestock_id requis")
    
    new_post = FarmImagePost(
        farm_id=farm_id,
        livestock_id=livestock_id,
        user_id=user_id,
        image_url=farm_post.image_url,
        caption=farm_post.caption,
        post_intent=getattr(farm_post, 'post_intent', 'share'),
        price=getattr(farm_post, 'price', None),
        product_name=getattr(farm_post, 'product_name', None),
        unit=getattr(farm_post, 'unit', 'kg'),
    )
    
    db.add(new_post)
    db.commit()
    db.refresh(new_post)
    
    return {
        "id": new_post.id,
        "farm_id": new_post.farm_id,
        "livestock_id": new_post.livestock_id,
        "image_url": new_post.image_url,
        "caption": new_post.caption,
        "post_intent": new_post.post_intent,
        "price": new_post.price,
        "unit": new_post.unit,
        "likes_count": 0,
        "comments_count": 0,
        "shares_count": 0,
        "created_at": new_post.created_at.isoformat(),
    }


@router.get("/feed")
def get_farm_posts_feed(user_id: int = None, db: Session = Depends(get_db)):
    """Récupérer tous les farm posts pour le feed social"""
    try:
        # Get all posts, ordered by newest first
        posts = db.query(FarmImagePost)\
            .order_by(desc(FarmImagePost.created_at))\
            .all()
        
        result = []
        # Pre-fetch likes for current user (if any) - single query
        user_likes = {}
        if user_id and user_id > 0 and posts:
            post_ids = [p.id for p in posts]
            likes = db.query(FarmPostLike.farm_post_id).filter(
                FarmPostLike.user_id == user_id,
                FarmPostLike.farm_post_id.in_(post_ids)
            ).all()
            user_likes = {like[0]: True for like in likes}
        
        for post in posts:
            # Load relations for each post
            farm = db.query(Farm).filter(Farm.id == post.farm_id).first() if post.farm_id else None
            user = db.query(User).filter(User.id == post.user_id).first()
            livestock = db.query(Livestock).filter(Livestock.id == post.livestock_id).first() if post.livestock_id else None

            if post.livestock_id and (livestock is None or livestock.deleted_at is not None):
                continue
            
            # Get farm or livestock name
            if farm:
                farm_name = farm.name
            elif livestock:
                farm_name = f"{livestock.animal_type.title() if livestock.animal_type else 'Animal'} - {livestock.breed or 'Sans race'}"
            else:
                farm_name = "Ferme inconnue"
            
            result.append({
                "id": post.id,
                "farm_id": post.farm_id,
                "livestock_id": post.livestock_id,
                "farm_name": farm_name,
                "owner_name": user.name if user else "Utilisateur",
                "owner_profile_image": user.profile_image if user else None,
                "user_id": post.user_id,
                "image_url": post.image_url,
                "caption": post.caption,
                "likes_count": post.likes_count,
                "comments_count": post.comments_count,
                "shares_count": post.shares_count,
                "created_at": post.created_at.isoformat(),
                "is_liked": user_likes.get(post.id, False),
                "post_intent": post.post_intent,
                "price": post.price,
                "unit": post.unit,
            })
        
        return result
    except Exception as e:
        logger.exception(f"❌ Error in get_farm_posts_feed")
        raise HTTPException(status_code=500, detail=f"Erreur lecture posts: {str(e)}")


@router.get("/subscriptions-feed/{user_id}")
def get_subscriptions_feed(user_id: int, db: Session = Depends(get_db)):
    """Get posts from users that this user follows"""
    try:
        # Get the users this user is following
        following = db.query(UserFollowing.following_id).filter(
            UserFollowing.follower_id == user_id
        ).all()
        following_ids = [f[0] for f in following]
        
        if not following_ids:
            return []
        
        # Get posts from following users
        posts = db.query(FarmImagePost)\
            .filter(FarmImagePost.user_id.in_(following_ids))\
            .order_by(desc(FarmImagePost.created_at))\
            .all()
        
        # Pre-fetch likes for current user - single query
        user_likes = {}
        if posts:
            post_ids = [p.id for p in posts]
            likes = db.query(FarmPostLike.farm_post_id).filter(
                FarmPostLike.user_id == user_id,
                FarmPostLike.farm_post_id.in_(post_ids)
            ).all()
            user_likes = {like[0]: True for like in likes}
        
        result = []
        for post in posts:
            # Load relations for each post
            farm = db.query(Farm).filter(Farm.id == post.farm_id).first() if post.farm_id else None
            user = db.query(User).filter(User.id == post.user_id).first()
            livestock = db.query(Livestock).filter(Livestock.id == post.livestock_id).first() if post.livestock_id else None

            if post.livestock_id and (livestock is None or livestock.deleted_at is not None):
                continue
            
            # Get farm or livestock name
            if farm:
                farm_name = farm.name
            elif livestock:
                farm_name = f"{livestock.animal_type.title() if livestock.animal_type else 'Animal'} - {livestock.breed or 'Sans race'}"
            else:
                farm_name = "Farm Unknown"
            
            result.append({
                "id": post.id,
                "farm_id": post.farm_id,
                "livestock_id": post.livestock_id,
                "farm_name": farm_name,
                "owner_name": user.name if user else "User",
                "owner_profile_image": user.profile_image if user else None,
                "user_id": post.user_id,
                "image_url": post.image_url,
                "caption": post.caption,
                "likes_count": post.likes_count,
                "comments_count": post.comments_count,
                "shares_count": post.shares_count,
                "created_at": post.created_at.isoformat(),
                "is_liked": user_likes.get(post.id, False),
                "post_intent": post.post_intent,
                "price": post.price,
                "unit": post.unit,
            })
        
        return result
    except Exception as e:
        logger.exception(f"❌ Error in get_subscriptions_feed")
        raise HTTPException(status_code=500, detail=f"Error loading feed: {str(e)}")


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


@router.get("/livestock/{livestock_id}")
def get_livestock_posts(livestock_id: int, user_id: int = None, db: Session = Depends(get_db)):
    """Récupérer tous les posts d'un animal (livestock) spécifique"""
    livestock = db.query(Livestock).filter(
        Livestock.id == livestock_id,
        Livestock.deleted_at == None,
    ).first()
    if not livestock:
        return []

    posts = db.query(FarmImagePost).filter(FarmImagePost.livestock_id == livestock_id).order_by(desc(FarmImagePost.created_at)).all()
    
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
            "livestock_id": post.livestock_id,
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


# ===== COMMENTAIRES =====

@router.get("/{post_id}/comments")
def get_post_comments(post_id: int, db: Session = Depends(get_db)):
    """Récupérer tous les commentaires d'un post"""
    try:
        print(f"[DEBUG] Loading comments for post_id={post_id}")
        comments = db.query(FarmPostComment).filter(
            FarmPostComment.farm_post_id == post_id
        ).order_by(FarmPostComment.created_at).all()
        
        print(f"[DEBUG] Found {len(comments)} comments")
        
        result = []
        for comment in comments:
            print(f"[DEBUG] Processing comment id={comment.id}, parent_id={comment.parent_id}")
            user = db.query(User).filter(User.id == comment.user_id).first()
            comment_dict = {
                "id": comment.id,
                "farm_post_id": comment.farm_post_id,
                "user_id": comment.user_id,
                "user_name": user.name if user else "Utilisateur",
                "user_profile_image": user.profile_image if user else None,
                "comment": comment.comment,
                "parent_id": comment.parent_id,  # Direct access, should work now
                "created_at": comment.created_at.isoformat(),
            }
            result.append(comment_dict)
            print(f"[DEBUG] Added comment: {comment_dict}")
        
        print(f"[DEBUG] Returning {len(result)} comments")
        return result
    except Exception as e:
        print(f"[ERROR] Exception getting comments for post {post_id}: {str(e)}")
        import traceback
        traceback.print_exc()
        logger.error(f"Error getting comments for post {post_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.post("/{post_id}/comments")
def add_comment(
    post_id: int,
    data: AddCommentRequest,
    db: Session = Depends(get_db)
):
    """Ajouter un commentaire à un post (optionnellement en réponse à un autre commentaire)"""
    try:
        print(f"[DEBUG] Adding comment to post_id={post_id}, user_id={data.user_id}, parent_id={data.parent_id}")
        
        # Vérifier que le post existe
        post = db.query(FarmImagePost).filter(FarmImagePost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        # Si parent_id est fourni, vérifier que le commentaire parent existe
        if data.parent_id:
            parent_comment = db.query(FarmPostComment).filter(FarmPostComment.id == data.parent_id).first()
            if not parent_comment:
                raise HTTPException(status_code=404, detail="Commentaire parent non trouvé")
        
        # Créer le commentaire
        new_comment = FarmPostComment(
            farm_post_id=post_id,
            user_id=data.user_id,
            parent_id=data.parent_id,
            comment=data.comment_text.strip()
        )
        print(f"[DEBUG] Created comment object: id will be auto-assigned")
        db.add(new_comment)
        
        # Incrémenter le compteur
        post.comments_count = (post.comments_count or 0) + 1
        
        db.commit()
        db.refresh(new_comment)
        
        print(f"[DEBUG] Committed comment with id={new_comment.id}")
        
        user = db.query(User).filter(User.id == data.user_id).first()
        return {
            "id": new_comment.id,
            "farm_post_id": new_comment.farm_post_id,
            "user_id": new_comment.user_id,
            "user_name": user.name if user else "Utilisateur",
            "user_profile_image": user.profile_image if user else None,
            "comment": new_comment.comment,
            "parent_id": new_comment.parent_id,
            "created_at": new_comment.created_at.isoformat(),
        }
    except HTTPException as he:
        db.rollback()
        raise he
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Exception adding comment to post {post_id}: {str(e)}")
        import traceback
        traceback.print_exc()
        logger.error(f"Error adding comment: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")
        
        user = db.query(User).filter(User.id == user_id).first()
        return {
            "id": new_comment.id,
            "farm_post_id": new_comment.farm_post_id,
            "user_id": new_comment.user_id,
            "user_name": user.name if user else "Utilisateur",
            "user_profile_image": user.profile_image if user else None,
            "comment": new_comment.comment,
            "parent_id": new_comment.parent_id,
            "created_at": new_comment.created_at.isoformat(),
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur ajout commentaire: {e}")


@router.delete("/{post_id}/comments/{comment_id}")
def delete_comment(post_id: int, comment_id: int, user_id: int, db: Session = Depends(get_db)):
    """Supprimer un commentaire"""
    # Vérifier que le commentaire existe
    comment = db.query(FarmPostComment).filter(
        FarmPostComment.id == comment_id,
        FarmPostComment.farm_post_id == post_id
    ).first()
    
    if not comment:
        raise HTTPException(status_code=404, detail="Commentaire non trouvé")
    
    # Autoriser si user est l'auteur du commentaire
    if comment.user_id != user_id:
        raise HTTPException(status_code=403, detail="Non autorisé à supprimer ce commentaire")
    
    try:
        # Récupérer le post pour décrémenter le compteur
        post = db.query(FarmImagePost).filter(FarmImagePost.id == post_id).first()
        if post:
            post.comments_count = max(0, (post.comments_count or 1) - 1)
        
        db.delete(comment)
        db.commit()
        
        return {"success": True, "message": "Commentaire supprimé"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur suppression: {e}")
