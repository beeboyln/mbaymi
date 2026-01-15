from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta

from app.database import get_db
from app.models.user import User
from app.models.authorization import Authorization, AuthorizationStatus
from app.models.farm import Farm
from app.schemas.authorization import (
    AuthorizationCreate,
    AuthorizationUpdate,
    AuthorizationResponse,
)
from app.routes.auth import get_current_user_obj

router = APIRouter(prefix="/api/authorizations", tags=["authorizations"])

@router.post("/", response_model=AuthorizationResponse)
def create_authorization(
    auth_data: AuthorizationCreate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Create new authorization for veterinarian to access farm data"""
    
    # Verify farm exists and belongs to current user
    farm = db.query(Farm).filter(Farm.id == auth_data.farm_id).first()
    if not farm or farm.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found or you don't have permission"
        )
    
    # Check if authorization already exists
    existing = db.query(Authorization).filter(
        Authorization.farm_id == auth_data.farm_id,
        Authorization.veterinarian_id == auth_data.veterinarian_id,
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Authorization already exists for this veterinarian"
        )
    
    # Create authorization with 1-year expiration
    new_auth = Authorization(
        farm_id=auth_data.farm_id,
        veterinarian_id=auth_data.veterinarian_id,
        authorized_by=current_user.id,
        can_view_data=auth_data.can_view_data,
        can_give_advice=auth_data.can_give_advice,
        can_visit=auth_data.can_visit,
        authorization_reason=auth_data.authorization_reason,
        status=AuthorizationStatus.PENDING,
        expires_at=datetime.utcnow() + timedelta(days=365),
    )
    
    db.add(new_auth)
    db.commit()
    db.refresh(new_auth)
    
    return new_auth

@router.get("/pending", response_model=List[AuthorizationResponse])
def get_pending_authorizations(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get pending authorizations for current veterinarian"""
    
    authorizations = db.query(Authorization).filter(
        Authorization.veterinarian_id == current_user.id,
        Authorization.status == AuthorizationStatus.PENDING,
    ).all()
    
    return authorizations

@router.post("/{authorization_id}/accept", response_model=AuthorizationResponse)
def accept_authorization(
    authorization_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Accept authorization request"""
    
    auth = db.query(Authorization).filter(
        Authorization.id == authorization_id,
        Authorization.veterinarian_id == current_user.id,
    ).first()
    
    if not auth:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Authorization not found"
        )
    
    auth.status = AuthorizationStatus.ACCEPTED
    db.commit()
    db.refresh(auth)
    
    return auth

@router.post("/{authorization_id}/reject", response_model=AuthorizationResponse)
def reject_authorization(
    authorization_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Reject authorization request"""
    
    auth = db.query(Authorization).filter(
        Authorization.id == authorization_id,
        Authorization.veterinarian_id == current_user.id,
    ).first()
    
    if not auth:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Authorization not found"
        )
    
    auth.status = AuthorizationStatus.REJECTED
    db.commit()
    db.refresh(auth)
    
    return auth

@router.post("/{authorization_id}/revoke", response_model=AuthorizationResponse)
def revoke_authorization(
    authorization_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Revoke authorization (farmer only)"""
    
    auth = db.query(Authorization).filter(
        Authorization.id == authorization_id,
        Authorization.authorized_by == current_user.id,
    ).first()
    
    if not auth:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Authorization not found"
        )
    
    auth.status = AuthorizationStatus.REVOKED
    auth.revoked_at = datetime.utcnow()
    db.commit()
    db.refresh(auth)
    
    return auth

@router.get("/farm/{farm_id}", response_model=List[AuthorizationResponse])
def get_farm_authorizations(
    farm_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all authorizations for a farm (farmer only)"""
    
    # Verify farm belongs to current user
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm or farm.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to view these authorizations"
        )
    
    authorizations = db.query(Authorization).filter(
        Authorization.farm_id == farm_id
    ).all()
    
    return authorizations

@router.get("/veterinarian/{veterinarian_id}", response_model=List[AuthorizationResponse])
def get_veterinarian_authorizations(
    veterinarian_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all active authorizations for a veterinarian (veterinarian only)"""
    
    if current_user.id != veterinarian_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own authorizations"
        )
    
    authorizations = db.query(Authorization).filter(
        Authorization.veterinarian_id == veterinarian_id,
        Authorization.status == AuthorizationStatus.ACCEPTED,
    ).all()
    
    return authorizations
