from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone
import os
import shutil
from pathlib import Path

from app.database import get_db
from app.models.user import User
from app.models.veterinarian import VeterinarianProfile, VerificationStatus, AvailabilityStatus
from app.schemas.veterinarian import (
    VeterinarianProfileCreate,
    VeterinarianProfileUpdate,
    VeterinarianProfileResponse,
)
from app.routes.auth import get_current_user_obj

# Create certificates directory if it doesn't exist
CERTIFICATES_DIR = Path(__file__).parent.parent.parent / "uploads" / "certificates"
CERTIFICATES_DIR.mkdir(parents=True, exist_ok=True)

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
        certificate_url=profile_data.certificate_url,
        certificate_filename=profile_data.certificate_filename,
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
    
    try:
        # Create a unique filename using user_id and timestamp
        file_extension = os.path.splitext(certificate.filename)[1]
        unique_filename = f"cert_{current_user.id}_{int(datetime.now(timezone.utc).timestamp())}{file_extension}"
        
        # Save the file to disk
        file_path = CERTIFICATES_DIR / unique_filename
        with open(file_path, "wb") as f:
            f.write(certificate.file.read())
        
        # Save the filename in database
        profile.certificate_filename = certificate.filename
        profile.certificate_url = unique_filename
        profile.verification_status = VerificationStatus.PENDING
        
        db.commit()
        db.refresh(profile)
        
        return {
            "message": "Certificate uploaded successfully",
            "filename": certificate.filename,
            "stored_as": unique_filename,
            "profile": profile
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading certificate: {str(e)}"
        )

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

@router.get("/certificate/{vet_id}")
def get_veterinarian_certificate(
    vet_id: int,
    db: Session = Depends(get_db),
):
    """Get veterinarian certificate info by veterinarian user ID"""
    
    profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == vet_id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinarian profile not found"
        )
    
    if not profile.certificate_url:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No certificate found for this veterinarian"
        )
    
    # Return certificate info for display
    return {
        "filename": profile.certificate_filename or profile.certificate_url,
        "url": profile.certificate_url,
        "uploaded_at": profile.created_at,
        "verified": profile.verification_status == VerificationStatus.VERIFIED,
    }

@router.get("/download-certificate/{vet_id}")
def download_veterinarian_certificate(
    vet_id: int,
    db: Session = Depends(get_db),
):
    """Download veterinarian certificate file"""
    
    profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == vet_id
    ).first()
    
    if not profile or not profile.certificate_url:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Certificate not found"
        )
    
    # Build the path to the certificate file using the constant CERTIFICATES_DIR
    cert_path = CERTIFICATES_DIR / profile.certificate_url
    
    if not cert_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Certificate file not found on server"
        )
    
    # Determine media type based on file extension
    file_ext = os.path.splitext(profile.certificate_url)[1].lower()
    media_type_map = {
        '.pdf': 'application/pdf',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.doc': 'application/msword',
        '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    }
    media_type = media_type_map.get(file_ext, 'application/octet-stream')
    
    return FileResponse(
        cert_path,
        filename=profile.certificate_filename or profile.certificate_url,
        media_type=media_type
    )

@router.get("/view-certificate/{vet_id}")
def view_veterinarian_certificate(
    vet_id: int,
    db: Session = Depends(get_db),
):
    """View/display veterinarian certificate file in browser"""
    
    profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == vet_id
    ).first()
    
    if not profile or not profile.certificate_url:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Certificate not found"
        )
    
    cert_path = CERTIFICATES_DIR / profile.certificate_url
    
    if not cert_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Certificate file not found on server"
        )
    
    # Determine media type for proper display
    file_ext = os.path.splitext(profile.certificate_url)[1].lower()
    media_type_map = {
        '.pdf': 'application/pdf',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
    }
    media_type = media_type_map.get(file_ext, 'application/octet-stream')
    
    return FileResponse(
        cert_path,
        media_type=media_type
    )
