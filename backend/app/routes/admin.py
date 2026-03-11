from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from pydantic import BaseModel

from app.database import get_db
from app.models.user import User
from app.models.veterinarian import VeterinarianProfile, VerificationStatus
from app.models.authorization import Authorization, AuthorizationStatus
from app.models.farm import Farm
from app.schemas.veterinarian import VeterinarianProfileResponse
from app.routes.auth import get_current_user_obj, hash_password


# Schemas for user management
class CreateUserRequest(BaseModel):
    name: str
    email: str
    password: str
    role: str


class UpdateUserRoleRequest(BaseModel):
    role: str

router = APIRouter(prefix="/api/admin", tags=["admin"])

# ═══════════════════════════════════════════════════════════════════════════
# VETERINARIAN VERIFICATION ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/veterinarians/pending", response_model=List[dict])
def get_pending_veterinarians(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all pending veterinarian profiles awaiting verification"""
    
    # Check if user is admin
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"Admin {current_user.id} fetching pending veterinarians")
    
    pending_vets = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.verification_status == VerificationStatus.PENDING
    ).all()
    
    result = []
    for vet in pending_vets:
        user = db.query(User).filter(User.id == vet.user_id).first()
        if user:
            result.append({
                "id": vet.id,
                "user_id": vet.user_id,
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "specialty": vet.specialty,
                "zone": vet.zone,
                "experience_years": vet.experience_years,
                "bio": vet.bio,
                "certificate_url": vet.certificate_url,
                "certificate_filename": vet.certificate_filename,
                "contact_preference": vet.contact_preference,
                "whatsapp_number": vet.whatsapp_number,
                "verification_status": vet.verification_status,
                "created_at": vet.created_at,
                "total_consultations": vet.total_consultations,
                "average_rating": vet.average_rating,
            })
    
    logger.info(f"Found {len(result)} pending veterinarians")
    return result


@router.get("/veterinarians/verified", response_model=List[dict])
def get_verified_veterinarians(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all verified veterinarians"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    verified_vets = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.verification_status == VerificationStatus.VERIFIED
    ).all()
    
    result = []
    for vet in verified_vets:
        user = db.query(User).filter(User.id == vet.user_id).first()
        if user:
            result.append({
                "id": vet.id,
                "user_id": vet.user_id,
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "specialty": vet.specialty,
                "zone": vet.zone,
                "experience_years": vet.experience_years,
                "bio": vet.bio,
                "is_verified": vet.is_verified,
                "verified_at": vet.verified_at,
                "verified_by_admin": vet.verified_by_admin,
                "total_consultations": vet.total_consultations,
                "average_rating": vet.average_rating,
            })
    
    return result


@router.get("/veterinarians/rejected", response_model=List[dict])
def get_rejected_veterinarians(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all rejected veterinarians"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    rejected_vets = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.verification_status == VerificationStatus.REJECTED
    ).all()
    
    result = []
    for vet in rejected_vets:
        user = db.query(User).filter(User.id == vet.user_id).first()
        if user:
            result.append({
                "id": vet.id,
                "user_id": vet.user_id,
                "name": user.name,
                "email": user.email,
                "specialty": vet.specialty,
                "zone": vet.zone,
                "verification_status": vet.verification_status,
                "created_at": vet.created_at,
            })
    
    return result


@router.patch("/veterinarians/{veterinarian_id}/verify")
def verify_veterinarian(
    veterinarian_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Verify a veterinarian profile"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can verify veterinarians"
        )
    
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"Admin {current_user.id} verifying veterinarian {veterinarian_id}")
    
    vet = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.id == veterinarian_id
    ).first()
    
    if not vet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinarian profile not found"
        )
    
    vet.verification_status = VerificationStatus.VERIFIED
    vet.is_verified = True
    vet.verified_at = datetime.utcnow()
    vet.verified_by_admin = current_user.id
    
    # Also update the user role to "veterinarian" if not already
    user = db.query(User).filter(User.id == vet.user_id).first()
    if user and user.role != "veterinarian":
        user.role = "veterinarian"
    
    db.commit()
    db.refresh(vet)
    
    logger.info(f"Veterinarian {veterinarian_id} verified successfully")
    
    return {
        "message": "Veterinarian verified successfully",
        "veterinarian_id": vet.id,
        "verification_status": vet.verification_status,
        "verified_at": vet.verified_at,
    }


@router.patch("/veterinarians/{veterinarian_id}/reject")
def reject_veterinarian(
    veterinarian_id: int,
    reason: str = None,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Reject a veterinarian profile"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can reject veterinarians"
        )
    
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"Admin {current_user.id} rejecting veterinarian {veterinarian_id}")
    
    vet = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.id == veterinarian_id
    ).first()
    
    if not vet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinarian profile not found"
        )
    
    vet.verification_status = VerificationStatus.REJECTED
    vet.is_verified = False
    vet.verified_by_admin = current_user.id
    
    db.commit()
    db.refresh(vet)
    
    logger.info(f"Veterinarian {veterinarian_id} rejected")
    
    return {
        "message": "Veterinarian rejected",
        "veterinarian_id": vet.id,
        "verification_status": vet.verification_status,
        "reason": reason,
    }


# ═══════════════════════════════════════════════════════════════════════════
# AUTHORIZATION MANAGEMENT ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/authorizations/pending", response_model=List[dict])
def get_pending_authorizations_admin(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all pending authorization requests"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"Admin {current_user.id} fetching pending authorizations")
    
    pending_auths = db.query(Authorization).filter(
        Authorization.status == AuthorizationStatus.PENDING
    ).all()
    
    result = []
    for auth in pending_auths:
        vet_user = db.query(User).filter(User.id == auth.veterinarian_id).first()
        farmer_user = db.query(User).filter(User.id == auth.authorized_by).first()
        farm = db.query(Farm).filter(Farm.id == auth.farm_id).first() if auth.farm_id else None
        
        result.append({
            "id": auth.id,
            "farm_id": auth.farm_id,
            "farm_name": farm.name if farm else None,
            "veterinarian_id": auth.veterinarian_id,
            "veterinarian_name": vet_user.name if vet_user else None,
            "veterinarian_email": vet_user.email if vet_user else None,
            "authorized_by": auth.authorized_by,
            "farmer_name": farmer_user.name if farmer_user else None,
            "farmer_email": farmer_user.email if farmer_user else None,
            "can_view_data": auth.can_view_data,
            "can_give_advice": auth.can_give_advice,
            "can_visit": auth.can_visit,
            "authorization_reason": auth.authorization_reason,
            "status": auth.status,
            "created_at": auth.created_at,
            "livestock_count": len(auth.selected_livestock_ids) if auth.selected_livestock_ids else 0,
        })
    
    logger.info(f"Found {len(result)} pending authorizations")
    return result


@router.get("/authorizations/active", response_model=List[dict])
def get_active_authorizations_admin(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all active (accepted) authorizations"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    active_auths = db.query(Authorization).filter(
        Authorization.status == AuthorizationStatus.ACCEPTED
    ).all()
    
    result = []
    for auth in active_auths:
        vet_user = db.query(User).filter(User.id == auth.veterinarian_id).first()
        farmer_user = db.query(User).filter(User.id == auth.authorized_by).first()
        farm = db.query(Farm).filter(Farm.id == auth.farm_id).first() if auth.farm_id else None
        
        result.append({
            "id": auth.id,
            "farm_id": auth.farm_id,
            "farm_name": farm.name if farm else None,
            "veterinarian_id": auth.veterinarian_id,
            "veterinarian_name": vet_user.name if vet_user else None,
            "authorized_by": auth.authorized_by,
            "farmer_name": farmer_user.name if farmer_user else None,
            "can_view_data": auth.can_view_data,
            "can_give_advice": auth.can_give_advice,
            "can_visit": auth.can_visit,
            "status": auth.status,
            "accepted_at": auth.status,
            "created_at": auth.created_at,
        })
    
    return result


@router.patch("/authorizations/{authorization_id}/revoke")
def revoke_authorization_admin(
    authorization_id: int,
    reason: str = None,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Admin revokes an authorization"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can revoke authorizations"
        )
    
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"Admin {current_user.id} revoking authorization {authorization_id}")
    
    auth = db.query(Authorization).filter(Authorization.id == authorization_id).first()
    
    if not auth:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Authorization not found"
        )
    
    auth.status = AuthorizationStatus.REVOKED
    db.commit()
    db.refresh(auth)
    
    logger.info(f"Authorization {authorization_id} revoked by admin")
    
    return {
        "message": "Authorization revoked",
        "authorization_id": auth.id,
        "status": auth.status,
        "reason": reason,
    }


# ═══════════════════════════════════════════════════════════════════════════
# ADMIN STATISTICS ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/statistics")
def get_admin_statistics(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get admin dashboard statistics"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"Fetching admin statistics")
    
    pending_vets = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.verification_status == VerificationStatus.PENDING
    ).count()
    
    verified_vets = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.verification_status == VerificationStatus.VERIFIED
    ).count()
    
    rejected_vets = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.verification_status == VerificationStatus.REJECTED
    ).count()
    
    pending_auths = db.query(Authorization).filter(
        Authorization.status == AuthorizationStatus.PENDING
    ).count()
    
    active_auths = db.query(Authorization).filter(
        Authorization.status == AuthorizationStatus.ACCEPTED
    ).count()
    
    return {
        "veterinarians": {
            "pending": pending_vets,
            "verified": verified_vets,
            "rejected": rejected_vets,
            "total": pending_vets + verified_vets + rejected_vets,
        },
        "authorizations": {
            "pending": pending_auths,
            "active": active_auths,
            "total": pending_auths + active_auths,
        }
    }


# ═══════════════════════════════════════════════════════════════════════════
# USER MANAGEMENT ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/users", response_model=List[dict])
def get_all_users(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all users (admin only)"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    users = db.query(User).all()
    
    result = []
    for user in users:
        result.append({
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "role": user.role,
            "is_active": user.is_active,
            "created_at": user.created_at,
            "updated_at": user.updated_at,
        })
    
    return result


@router.get("/users/{user_id}", response_model=dict)
def get_user_details(
    user_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get user details (admin only)"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "role": user.role,
        "is_active": user.is_active,
        "created_at": user.created_at,
        "updated_at": user.updated_at,
    }


@router.post("/users", response_model=dict)
def create_user(
    user_data: CreateUserRequest,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Create new user (admin only)"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    # Check if email already exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already in use"
        )
    
    # Create new user
    new_user = User(
        name=user_data.name,
        email=user_data.email,
        password_hash=hash_password(user_data.password),
        role=user_data.role,
        is_active=True,
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return {
        "id": new_user.id,
        "name": new_user.name,
        "email": new_user.email,
        "phone": new_user.phone,
        "role": new_user.role,
        "is_active": new_user.is_active,
        "created_at": new_user.created_at,
        "updated_at": new_user.updated_at,
    }


@router.delete("/users/{user_id}", response_model=dict)
def delete_user(
    user_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Delete user (admin only)"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    db.delete(user)
    db.commit()
    
    return {"message": "User deleted successfully"}


@router.patch("/users/{user_id}/role", response_model=dict)
def update_user_role(
    user_id: int,
    role_data: UpdateUserRoleRequest,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Update user role (admin only)"""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can access this endpoint"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Validate role
    valid_roles = ["admin", "farmer", "veterinarian", "user"]
    if role_data.role not in valid_roles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid role. Must be one of: {', '.join(valid_roles)}"
        )
    
    user.role = role_data.role
    user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(user)
    
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "role": user.role,
        "is_active": user.is_active,
        "created_at": user.created_at,
        "updated_at": user.updated_at,
    }
