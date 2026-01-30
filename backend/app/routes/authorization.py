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
    
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"=== Authorization POST endpoint ===")
    logger.info(f"Current user: id={current_user.id}, name={current_user.name}")
    logger.info(f"Auth data received: {auth_data.dict()}")
    logger.info(f"Farm ID: {auth_data.farm_id}")
    logger.info(f"Veterinarian ID: {auth_data.veterinarian_id}")
    logger.info(f"Can view data: {auth_data.can_view_data}")
    logger.info(f"Can give advice: {auth_data.can_give_advice}")
    logger.info(f"Can visit: {auth_data.can_visit}")
    logger.info(f"Reason: {auth_data.authorization_reason}")
    logger.info(f"Livestock IDs: {auth_data.selected_livestock_ids}")
    logger.info(f"Crop IDs: {auth_data.selected_crop_ids}")
    
    # Verify farm exists only if farm_id is provided (for crop authorizations)
    # For livestock-only authorizations, farm_id can be 0/null
    farm = None
    if auth_data.farm_id and auth_data.farm_id > 0:
        farm = db.query(Farm).filter(Farm.id == auth_data.farm_id).first()
        logger.info(f"Farm query result: {farm}")
        if not farm:
            logger.error(f"Farm not found with id={auth_data.farm_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Farm not found"
            )
    elif auth_data.selected_livestock_ids:
        logger.info(f"Livestock-only authorization (no farm required)")
    else:
        logger.warning(f"No farm_id and no livestock_ids provided")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either farm_id or livestock_ids must be provided"
        )
    
    # Always create a new authorization (don't merge with existing ones)
    # This ensures accepted authorizations don't mix with new requests
    logger.info(f"Creating new authorization request")
    
    # Create authorization with 1-year expiration
    new_auth = Authorization(
        farm_id=auth_data.farm_id,
        veterinarian_id=auth_data.veterinarian_id,
        authorized_by=current_user.id,
        can_view_data=auth_data.can_view_data,
        can_give_advice=auth_data.can_give_advice,
        can_visit=auth_data.can_visit,
        authorization_reason=auth_data.authorization_reason,
        selected_livestock_ids=auth_data.selected_livestock_ids,
        selected_crop_ids=auth_data.selected_crop_ids,
        status=AuthorizationStatus.PENDING,
        expires_at=datetime.utcnow() + timedelta(days=365),
    )
    
    db.add(new_auth)
    db.commit()
    db.refresh(new_auth)
    
    logger.info(f"Authorization created successfully: id={new_auth.id}, status={new_auth.status}")
    logger.info(f"=== End authorization POST ===")
    
    return new_auth

@router.get("/pending", response_model=list)
def get_pending_authorizations(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get pending authorizations for current veterinarian with full farm and farmer data"""
    
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"=== GET /pending for vet {current_user.id} ({current_user.name}) ===")
    
    try:
        from app.models.farm import Farm, Crop
        from app.models.livestock import Livestock
        from app.models.photo import FarmPhoto
        
        authorizations = db.query(Authorization).filter(
            Authorization.veterinarian_id == current_user.id,
            Authorization.status == AuthorizationStatus.PENDING,
        ).all()
        
        logger.info(f"Found {len(authorizations)} pending authorizations")
        
        result = []
        for auth in authorizations:
            try:
                # Get farm and farmer data
                farm = db.query(Farm).filter(Farm.id == auth.farm_id).first() if auth.farm_id and auth.farm_id > 0 else None
                
                # For livestock authorization, get farmer from authorized_by
                # For farm authorization, get farmer from farm.user_id
                if farm:
                    farmer = db.query(User).filter(User.id == farm.user_id).first()
                else:
                    farmer = db.query(User).filter(User.id == auth.authorized_by).first()
                
                # Get farm photos and livestocks and crops
                # Note: Livestock uses user_id, not farm_id
                photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == auth.farm_id).all() if farm else []
                
                # Get only selected livestocks
                if farm:
                    all_livestocks = db.query(Livestock).filter(Livestock.user_id == farm.user_id).all()
                else:
                    all_livestocks = db.query(Livestock).filter(Livestock.user_id == auth.authorized_by).all()
                    
                if auth.selected_livestock_ids:
                    selected_ids = [int(x) for x in auth.selected_livestock_ids.split(',')]
                    livestocks = [l for l in all_livestocks if l.id in selected_ids]
                else:
                    livestocks = []
                
                # Get only selected crops
                all_crops = db.query(Crop).filter(Crop.farm_id == auth.farm_id).all() if farm else []
                if auth.selected_crop_ids:
                    selected_ids = [int(x) for x in auth.selected_crop_ids.split(',')]
                    crops = [c for c in all_crops if c.id in selected_ids]
                else:
                    crops = []
                
                logger.info(f"Auth {auth.id}: Found {len(livestocks)} livestock, {len(crops)} crops, {len(photos)} photos")
                logger.info(f"Auth {auth.id}: farm_id={auth.farm_id}, authorized_by={auth.authorized_by}, farmer={farmer.id if farmer else None}")
                
                # Build response with safe attribute access
                auth_dict = {
                    'id': auth.id,
                    'farm_id': auth.farm_id,
                    'veterinarian_id': auth.veterinarian_id,
                    'status': auth.status,
                    'authorization_reason': auth.authorization_reason,
                    'created_at': auth.created_at.isoformat() if auth.created_at else None,
                    'farm': {
                        'id': farm.id if farm else None,
                        'name': farm.name if farm else None,
                        'location': farm.location if farm else None,
                        'image_url': getattr(farm, 'image_url', None) if farm else None,
                        'photos': [
                            {'id': p.id, 'image_url': getattr(p, 'image_url', None)}
                            for p in photos
                        ],
                        'livestocks': [
                            {
                                'id': l.id,
                                'animal_type': getattr(l, 'animal_type', None),
                                'breed': getattr(l, 'breed', None),
                                'quantity': getattr(l, 'quantity', None),
                                'age_months': getattr(l, 'age_months', None),
                                'health_status': getattr(l, 'health_status', None),
                                'image_url': getattr(l, 'image_url', None),
                            }
                            for l in livestocks
                        ],
                        'crops': [
                            {
                                'id': c.id,
                                'crop_name': getattr(c, 'crop_name', None),
                                'variety': getattr(c, 'variety', None),
                                'status': getattr(c, 'status', None),
                                'image_url': getattr(c, 'image_url', None),
                            }
                            for c in crops
                        ],
                    },
                    'farmer': {
                        'id': farmer.id if farmer else None,
                        'name': farmer.name if farmer else None,
                    }
                }
                result.append(auth_dict)
            except Exception as e:
                logger.error(f"Error processing authorization {auth.id}: {str(e)}", exc_info=True)
                # Still add it but with minimal data
                auth_dict = {
                    'id': auth.id,
                    'farm_id': auth.farm_id,
                    'veterinarian_id': auth.veterinarian_id,
                    'status': auth.status,
                    'authorization_reason': auth.authorization_reason,
                    'created_at': auth.created_at.isoformat() if auth.created_at else None,
                    'farm': None,
                    'farmer': None,
                }
                result.append(auth_dict)
        
        logger.info(f"=== Returning {len(result)} authorizations ===")
        return result
        
    except Exception as e:
        logger.error(f"Error in get_pending_authorizations: {str(e)}", exc_info=True)
        raise

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

@router.get("/veterinarian/{veterinarian_id}", response_model=list)
def get_veterinarian_authorizations(
    veterinarian_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all active authorizations for a veterinarian (veterinarian only) with full farm and farmer data"""
    
    if current_user.id != veterinarian_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own authorizations"
        )
    
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"=== GET /veterinarian/{veterinarian_id} ===")
    
    try:
        from app.models.farm import Farm, Crop
        from app.models.livestock import Livestock
        from app.models.photo import FarmPhoto
        
        authorizations = db.query(Authorization).filter(
            Authorization.veterinarian_id == veterinarian_id,
            Authorization.status == AuthorizationStatus.ACCEPTED,
        ).all()
        
        logger.info(f"Found {len(authorizations)} accepted authorizations")
        
        result = []
        for auth in authorizations:
            try:
                # Get farm and farmer data
                farm = db.query(Farm).filter(Farm.id == auth.farm_id).first() if auth.farm_id and auth.farm_id > 0 else None
                
                # For livestock authorization, get farmer from authorized_by
                # For farm authorization, get farmer from farm.user_id
                if farm:
                    farmer = db.query(User).filter(User.id == farm.user_id).first()
                else:
                    farmer = db.query(User).filter(User.id == auth.authorized_by).first()
                
                # Get farm photos and livestocks and crops
                photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == auth.farm_id).all() if farm else []
                
                # Get only selected livestocks
                if farm:
                    all_livestocks = db.query(Livestock).filter(Livestock.user_id == farm.user_id).all()
                else:
                    all_livestocks = db.query(Livestock).filter(Livestock.user_id == auth.authorized_by).all()
                    
                if auth.selected_livestock_ids:
                    selected_ids = [int(x) for x in auth.selected_livestock_ids.split(',')]
                    livestocks = [l for l in all_livestocks if l.id in selected_ids]
                else:
                    livestocks = []
                
                # Get only selected crops
                all_crops = db.query(Crop).filter(Crop.farm_id == auth.farm_id).all() if farm else []
                if auth.selected_crop_ids:
                    selected_ids = [int(x) for x in auth.selected_crop_ids.split(',')]
                    crops = [c for c in all_crops if c.id in selected_ids]
                else:
                    crops = []
                
                logger.info(f"Auth {auth.id}: Found {len(livestocks)} livestock, {len(crops)} crops, {len(photos)} photos")
                
                # Build response with safe attribute access
                auth_dict = {
                    'id': auth.id,
                    'farm_id': auth.farm_id,
                    'veterinarian_id': auth.veterinarian_id,
                    'status': auth.status,
                    'authorization_reason': auth.authorization_reason,
                    'created_at': auth.created_at.isoformat() if auth.created_at else None,
                    'farm': {
                        'id': farm.id if farm else None,
                        'name': farm.name if farm else None,
                        'location': farm.location if farm else None,
                        'image_url': getattr(farm, 'image_url', None) if farm else None,
                        'photos': [
                            {'id': p.id, 'image_url': getattr(p, 'image_url', None)}
                            for p in photos
                        ],
                        'livestocks': [
                            {
                                'id': l.id,
                                'animal_type': getattr(l, 'animal_type', None),
                                'breed': getattr(l, 'breed', None),
                                'quantity': getattr(l, 'quantity', None),
                                'age_months': getattr(l, 'age_months', None),
                                'health_status': getattr(l, 'health_status', None),
                                'image_url': getattr(l, 'image_url', None),
                            }
                            for l in livestocks
                        ],
                        'crops': [
                            {
                                'id': c.id,
                                'crop_name': getattr(c, 'crop_name', None),
                                'variety': getattr(c, 'variety', None),
                                'status': getattr(c, 'status', None),
                                'image_url': getattr(c, 'image_url', None),
                            }
                            for c in crops
                        ],
                    },
                    'farmer': {
                        'id': farmer.id if farmer else None,
                        'name': farmer.name if farmer else None,
                    }
                }
                result.append(auth_dict)
            except Exception as e:
                logger.error(f"Error processing authorization {auth.id}: {str(e)}", exc_info=True)
                # Still add it but with minimal data
                auth_dict = {
                    'id': auth.id,
                    'farm_id': auth.farm_id,
                    'veterinarian_id': auth.veterinarian_id,
                    'status': auth.status,
                    'authorization_reason': auth.authorization_reason,
                    'created_at': auth.created_at.isoformat() if auth.created_at else None,
                    'farm': None,
                    'farmer': None,
                }
                result.append(auth_dict)
        
        logger.info(f"=== Returning {len(result)} authorized farms ===")
        return result
        
    except Exception as e:
        logger.error(f"Error in get_veterinarian_authorizations: {str(e)}", exc_info=True)
        raise
