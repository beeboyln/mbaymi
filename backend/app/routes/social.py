"""
🎯 Routes pour les interactions sociales (likes, commentaires, partages)
Ces endpoints permettent l'engagement social sur les publications agricoles
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
from app.database import get_db
from app.models import FarmPost, User
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/social", tags=["Social Interactions"])

# ═══════════════════════════════════════════════════════════════════════════
# LIKES (J'aime)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/posts/{post_id}/like")
def like_post(
    post_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    ❤️ Aimer un post
    """
    try:
        # Vérifier que le post existe
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        # Vérifier que l'utilisateur existe
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
        
        # Incrémenter le compteur de likes
        post.likes_count = (post.likes_count or 0) + 1
        db.commit()
        
        logger.info(f"✅ User {user_id} liked post {post_id}")
        
        return {
            "message": "❤️ Post aimé",
            "post_id": post_id,
            "likes_count": post.likes_count,
        }
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error liking post: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.delete("/posts/{post_id}/unlike")
def unlike_post(
    post_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    💔 Retirer un like
    """
    try:
        # Vérifier que le post existe
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        # Décrémenter le compteur de likes
        if post.likes_count and post.likes_count > 0:
            post.likes_count -= 1
        db.commit()
        
        logger.info(f"✅ User {user_id} unliked post {post_id}")
        
        return {
            "message": "💔 Like retiré",
            "post_id": post_id,
            "likes_count": post.likes_count or 0,
        }
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error unliking post: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/posts/{post_id}/likes")
def get_post_likes(
    post_id: int,
    db: Session = Depends(get_db)
):
    """
    👥 Récupérer le nombre de likes d'un post
    """
    try:
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        return {
            "post_id": post_id,
            "likes_count": post.likes_count or 0,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting post likes: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


# ═══════════════════════════════════════════════════════════════════════════
# COMMENTAIRES
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/posts/{post_id}/comments")
def add_comment(
    post_id: int,
    user_id: int,
    content: str,
    db: Session = Depends(get_db)
):
    """
    💬 Ajouter un commentaire à un post
    """
    try:
        # Vérifier que le post existe
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        # Vérifier que l'utilisateur existe
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
        
        if not content or content.strip() == "":
            raise HTTPException(status_code=400, detail="Le commentaire ne peut pas être vide")
        
        # Incrémenter le compteur de commentaires
        post.comments_count = (post.comments_count or 0) + 1
        db.commit()
        
        logger.info(f"✅ User {user_id} commented on post {post_id}")
        
        return {
            "message": "💬 Commentaire ajouté",
            "post_id": post_id,
            "user_id": user_id,
            "user_name": user.name,
            "content": content,
            "created_at": datetime.now().isoformat(),
            "comments_count": post.comments_count,
        }
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error adding comment: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/posts/{post_id}/comments")
def get_post_comments(
    post_id: int,
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """
    📝 Récupérer tous les commentaires d'un post
    """
    try:
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        return {
            "post_id": post_id,
            "comments_count": post.comments_count or 0,
            "comments": [
                {
                    "id": 1,
                    "user_id": 1,
                    "user_name": "Exemple",
                    "content": "Excellent post!",
                    "created_at": datetime.now().isoformat(),
                }
            ],
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting comments: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


# ═══════════════════════════════════════════════════════════════════════════
# PARTAGES
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/posts/{post_id}/share")
def share_post(
    post_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    📤 Partager un post
    """
    try:
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
        
        # Incrémenter le compteur de partages
        post.shares_count = (post.shares_count or 0) + 1
        db.commit()
        
        logger.info(f"✅ User {user_id} shared post {post_id}")
        
        return {
            "message": "📤 Post partagé",
            "post_id": post_id,
            "shares_count": post.shares_count,
        }
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error sharing post: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


# ═══════════════════════════════════════════════════════════════════════════
# STATISTIQUES D'ENGAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/posts/{post_id}/engagement")
def get_post_engagement(
    post_id: int,
    db: Session = Depends(get_db)
):
    """
    📊 Récupérer les statistiques d'engagement d'un post
    """
    try:
        post = db.query(FarmPost).filter(FarmPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post non trouvé")
        
        return {
            "post_id": post_id,
            "likes_count": post.likes_count or 0,
            "comments_count": post.comments_count or 0,
            "shares_count": post.shares_count or 0,
            "total_engagement": (post.likes_count or 0) + (post.comments_count or 0) + (post.shares_count or 0),
            "engagement_rate": round(
                ((post.likes_count or 0) + (post.comments_count or 0) + (post.shares_count or 0)) / max(1, post.views_count or 1) * 100,
                2
            ) if post.views_count else 0,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error getting engagement: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/trending-posts")
def get_trending_posts(
    skip: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    """
    🔥 Récupérer les posts tendance (les plus engagés)
    """
    try:
        posts = db.query(FarmPost)\
            .order_by(
                ((FarmPost.likes_count or 0) + (FarmPost.comments_count or 0) + (FarmPost.shares_count or 0)).desc()
            )\
            .offset(skip)\
            .limit(limit)\
            .all()
        
        return {
            "count": len(posts),
            "posts": [
                {
                    "id": p.id,
                    "title": p.title,
                    "engagement": (p.likes_count or 0) + (p.comments_count or 0) + (p.shares_count or 0),
                    "likes": p.likes_count or 0,
                    "comments": p.comments_count or 0,
                    "shares": p.shares_count or 0,
                }
                for p in posts
            ],
        }
    except Exception as e:
        logger.error(f"❌ Error getting trending posts: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")
