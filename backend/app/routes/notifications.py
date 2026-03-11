from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.notification_service import NotificationService
from app.services.jwt_service import verify_token
from typing import Optional
import logging

logger = logging.getLogger(__name__)

# Helper function to extract user_id from Authorization header
def get_current_user(authorization: Optional[str] = Header(None)) -> int:
    """Extract user_id from JWT token in Authorization header."""
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
        logger.debug(f"🔍 Token to verify: {token[:30]}...")
        
        user_id = verify_token(token)
        if user_id is None:
            logger.error(f"❌ Token verification failed")
            raise HTTPException(status_code=401, detail="Invalid or expired token")
        
        logger.debug(f"✅ User {user_id} authenticated successfully")
        return user_id
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Authentication error: {e}")
        raise HTTPException(status_code=401, detail="Authentication failed")

router = APIRouter(prefix="/api/users", tags=["notifications"])

# ✅ MORE SPECIFIC ROUTES FIRST (path with extra segments)

@router.get("/{user_id}/notifications/unread-count")
def get_unread_count(
    user_id: int,
    current_user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Compter les notifications non lues"""
    # ✅ Use the authenticated user's ID, not the URL parameter
    # This prevents 403 errors from authentication mismatches
    count = NotificationService.get_unread_count(db, current_user_id)
    return {"unread_count": count}

@router.put("/{user_id}/notifications/read-all")
def mark_all_notifications_as_read(
    user_id: int,
    current_user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Marquer toutes les notifications comme lues"""
    # ✅ Use the authenticated user's ID, not the URL parameter
    count = NotificationService.mark_all_as_read(db, current_user_id)
    return {"message": f"Marked {count} notifications as read", "count": count}

@router.put("/{user_id}/notifications/{notification_id}/read")
def mark_notification_as_read(
    user_id: int,
    notification_id: int,
    current_user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Marquer une notification comme lue"""
    # ✅ Use the authenticated user's ID, not the URL parameter
    success = NotificationService.mark_as_read(db, notification_id, current_user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )
    
    return {"message": "Notification marked as read"}

@router.delete("/{user_id}/notifications/{notification_id}")
def delete_notification(
    user_id: int,
    notification_id: int,
    current_user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Supprimer une notification"""
    # ✅ Use the authenticated user's ID, not the URL parameter
    success = NotificationService.delete_notification(db, notification_id, current_user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )
    
    return {"message": "Notification deleted"}

# ✅ LESS SPECIFIC ROUTE LAST (generic path)

@router.get("/{user_id}/notifications")
def get_notifications(
    user_id: int,
    skip: int = 0,
    limit: int = 20,
    current_user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer les notifications d'un utilisateur"""
    # ✅ Use the authenticated user's ID, not the URL parameter
    notifications = NotificationService.get_user_notifications(
        db, current_user_id, skip, limit
    )
    
    return {
        "notifications": [n.to_dict() for n in notifications],
        "count": len(notifications),
    }
