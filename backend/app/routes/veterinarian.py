from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from app.database import get_db
from app.models.user import User
from app.models.veterinarian import VeterinarianProfile, VerificationStatus, AvailabilityStatus
from app.schemas.veterinarian import (
    VeterinarianProfileCreate,
    VeterinarianProfileUpdate,
    VeterinarianProfileResponse,
)
from app.routes.auth import get_current_user_obj

router = APIRouter(prefix="/api/veterinarians", tags=["veterinarians"])

@router.post("/profile", response_model=VeterinarianProfileResponse)
def create_veterinarian_profile(
    profile_data: VeterinarianProfileCreate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Create a new veterinarian profile"""
    
    # Check if user already has a veterinarian profile
    existing_profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == current_user.id
    ).first()
    
    if existing_profile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already has a veterinarian profile"
        )
    
    # Create new profile
    new_profile = VeterinarianProfile(
        user_id=current_user.id,
        specialty=profile_data.specialty,
        zone=profile_data.zone,
        distance_max=profile_data.distance_max,
        bio=profile_data.bio,
        experience_years=profile_data.experience_years,
        contact_preference=profile_data.contact_preference,
        verification_status=VerificationStatus.PENDING,
        availability_status=AvailabilityStatus.AVAILABLE,
    )
    
    db.add(new_profile)
    db.commit()
    db.refresh(new_profile)
    
    return new_profile

@router.get("/my-profile", response_model=VeterinarianProfileResponse)
def get_my_profile(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get current user's veterinarian profile"""
    
    profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == current_user.id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinarian profile not found"
        )
    
    return profile

@router.get("/profile/{veterinarian_id}", response_model=VeterinarianProfileResponse)
def get_veterinarian_profile(
    veterinarian_id: int,
    db: Session = Depends(get_db),
):
    """Get veterinarian profile by ID (user_id)"""
    
    # Chercher le profil vétérinaire pour cet utilisateur
    profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == veterinarian_id
    ).first()
    
    if not profile:
        # Vérifier si l'utilisateur existe et a le rôle "veterinarian"
        user = db.query(User).filter(User.id == veterinarian_id).first()
        if user and user.role == "veterinarian":
            # L'utilisateur existe avec le rôle vétérinaire mais n'a pas créé de profil
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cet utilisateur n'a pas terminé son profil vétérinaire"
            )
        else:
            # L'utilisateur n'existe pas ou n'est pas un vétérinaire
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profil vétérinaire non trouvé"
            )
    
    return profile

@router.patch("/profile", response_model=VeterinarianProfileResponse)
def update_veterinarian_profile(
    profile_data: VeterinarianProfileUpdate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Update veterinarian profile"""
    
    profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == current_user.id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinarian profile not found"
        )
    
    # Update fields if provided
    if profile_data.specialty:
        profile.specialty = profile_data.specialty
    if profile_data.zone:
        profile.zone = profile_data.zone
    if profile_data.distance_max is not None:
        profile.distance_max = profile_data.distance_max
    if profile_data.bio:
        profile.bio = profile_data.bio
    if profile_data.experience_years is not None:
        profile.experience_years = profile_data.experience_years
    if profile_data.contact_preference:
        profile.contact_preference = profile_data.contact_preference
    if profile_data.availability_status:
        profile.availability_status = profile_data.availability_status
    
    db.commit()
    db.refresh(profile)
    
    return profile

@router.post("/upload-certificate")
def upload_certificate(
    certificate: UploadFile = File(...),
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Upload veterinarian certificate"""
    
    profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == current_user.id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinarian profile not found"
        )
    
    # TODO: Upload to Cloudinary and store URL
    # For now, store filename
    profile.certificate_url = certificate.filename
    profile.verification_status = VerificationStatus.PENDING
    
    db.commit()
    db.refresh(profile)
    
    return {"message": "Certificate uploaded successfully", "profile": profile}

@router.patch("/availability/{status}")
def update_availability_status(
    status: AvailabilityStatus,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Update availability status"""
    
    profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == current_user.id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinarian profile not found"
        )
    
    profile.availability_status = status
    db.commit()
    db.refresh(profile)
    
    return {"message": f"Availability status updated to {status}", "profile": profile}

@router.get("/verified", response_model=List[VeterinarianProfileResponse])
def get_verified_veterinarians(
    db: Session = Depends(get_db),
):
    """Get all verified veterinarians"""
    
    profiles = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.verification_status == VerificationStatus.VERIFIED
    ).all()
    
    return profiles

@router.get("/by-zone/{zone}", response_model=List[VeterinarianProfileResponse])
def get_veterinarians_by_zone(
    zone: str,
    db: Session = Depends(get_db),
):
    """Get veterinarians by zone"""
    
    profiles = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.zone == zone,
    ).all()
    
    return profiles

@router.get("/by-specialty/{specialty}", response_model=List[VeterinarianProfileResponse])
def get_veterinarians_by_specialty(
    specialty: str,
    db: Session = Depends(get_db),
):
    """Get veterinarians by specialty"""
    
    profiles = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.specialty == specialty,
    ).all()
    
    return profiles
