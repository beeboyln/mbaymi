from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from app.database import get_db
from app.models.user import User
from app.models.service_request import ServiceRequest, Consultation, RequestStatus
from app.models.farm import Farm
from app.models.authorization import Authorization, AuthorizationStatus
from app.schemas.service_request import (
    ServiceRequestCreate,
    ServiceRequestUpdate,
    ServiceRequestResponse,
    ConsultationCreate,
    ConsultationResponse,
)
from app.routes.auth import get_current_user_obj

router = APIRouter(prefix="/api/service-requests", tags=["service-requests"])

@router.post("/", response_model=ServiceRequestResponse)
def create_service_request(
    request_data: ServiceRequestCreate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Create a new service request"""
    
    # Get user's farm (assume first farm for now)
    farm = db.query(Farm).filter(Farm.user_id == current_user.id).first()
    if not farm:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="You need to create a farm first"
        )
    
    new_request = ServiceRequest(
        farm_id=farm.id,
        created_by=current_user.id,
        service_type=request_data.service_type,
        title=request_data.title,
        description=request_data.description,
        symptoms=request_data.symptoms,
        animal_id=request_data.animal_id,
        crop_id=request_data.crop_id,
        priority=request_data.priority,
        status=RequestStatus.OPEN,
        photos=request_data.photos,
    )
    
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    
    return new_request

@router.get("/my-requests", response_model=List[ServiceRequestResponse])
def get_my_requests(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all service requests created by current user"""
    
    requests = db.query(ServiceRequest).filter(
        ServiceRequest.created_by == current_user.id
    ).order_by(ServiceRequest.created_at.desc()).all()
    
    return requests

@router.get("/available-for-me", response_model=List[ServiceRequestResponse])
def get_available_requests(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get service requests available for current veterinarian based on zone/specialty"""
    
    # Get veterinarian's info
    from app.models.veterinarian import VeterinarianProfile
    vet_profile = db.query(VeterinarianProfile).filter(
        VeterinarianProfile.user_id == current_user.id
    ).first()
    
    if not vet_profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinarian profile not found"
        )
    
    # Get requests from farms by farm owner's region matching vet's zone
    # Join: ServiceRequest -> Farm -> User
    requests = db.query(ServiceRequest).join(
        Farm, ServiceRequest.farm_id == Farm.id
    ).join(
        User, Farm.user_id == User.id
    ).filter(
        User.region == vet_profile.zone,
        ServiceRequest.status == RequestStatus.OPEN,
    ).order_by(ServiceRequest.priority.desc()).all()
    
    return requests

@router.get("/{request_id}", response_model=ServiceRequestResponse)
def get_service_request(
    request_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get a specific service request"""
    
    service_request = db.query(ServiceRequest).filter(
        ServiceRequest.id == request_id
    ).first()
    
    if not service_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service request not found"
        )
    
    # Check permissions
    farm = db.query(Farm).filter(Farm.id == service_request.farm_id).first()
    is_farm_owner = farm and farm.user_id == current_user.id
    
    # Check if veterinarian has authorization
    has_auth = db.query(Authorization).filter(
        Authorization.farm_id == service_request.farm_id,
        Authorization.veterinarian_id == current_user.id,
        Authorization.status == AuthorizationStatus.ACCEPTED,
        Authorization.can_view_data == True,
    ).first() is not None
    
    if not is_farm_owner and not has_auth:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to view this request"
        )
    
    return service_request

@router.patch("/{request_id}", response_model=ServiceRequestResponse)
def update_service_request(
    request_id: int,
    request_data: ServiceRequestUpdate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Update a service request (farmer only)"""
    
    service_request = db.query(ServiceRequest).filter(
        ServiceRequest.id == request_id,
        ServiceRequest.created_by == current_user.id,
    ).first()
    
    if not service_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service request not found"
        )
    
    if request_data.title:
        service_request.title = request_data.title
    if request_data.description:
        service_request.description = request_data.description
    if request_data.symptoms:
        service_request.symptoms = request_data.symptoms
    if request_data.status:
        service_request.status = request_data.status
    if request_data.priority:
        service_request.priority = request_data.priority
    
    db.commit()
    db.refresh(service_request)
    
    return service_request

@router.post("/{request_id}/assign", response_model=ServiceRequestResponse)
def assign_request_to_veterinarian(
    request_id: int,
    veterinarian_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Assign a service request to a veterinarian"""
    
    service_request = db.query(ServiceRequest).filter(
        ServiceRequest.id == request_id
    ).first()
    
    if not service_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service request not found"
        )
    
    # Verify farm owner is making this request
    farm = db.query(Farm).filter(Farm.id == service_request.farm_id).first()
    if not farm or farm.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only assign requests for your farm"
        )
    
    service_request.assigned_to = veterinarian_id
    service_request.status = RequestStatus.ASSIGNED
    
    db.commit()
    db.refresh(service_request)
    
    return service_request

@router.post("/{request_id}/consultations", response_model=ConsultationResponse)
def create_consultation(
    request_id: int,
    consultation_data: ConsultationCreate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Create a consultation response to a service request"""
    
    service_request = db.query(ServiceRequest).filter(
        ServiceRequest.id == request_id
    ).first()
    
    if not service_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service request not found"
        )
    
    # Verify veterinarian has authorization
    auth = db.query(Authorization).filter(
        Authorization.farm_id == service_request.farm_id,
        Authorization.veterinarian_id == current_user.id,
        Authorization.status == AuthorizationStatus.ACCEPTED,
        Authorization.can_give_advice == True,
    ).first()
    
    if not auth:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to give advice on this farm"
        )
    
    new_consultation = Consultation(
        service_request_id=request_id,
        veterinarian_id=current_user.id,
        consultation_type=consultation_data.consultation_type,
        advice=consultation_data.advice,
        recommendations=consultation_data.recommendations,
        scheduling=consultation_data.scheduling,
        cost=consultation_data.cost,
        payment_status=consultation_data.payment_status,
    )
    
    # Update request status
    service_request.status = RequestStatus.COMPLETED
    
    db.add(new_consultation)
    db.commit()
    db.refresh(new_consultation)
    
    return new_consultation

@router.get("/{request_id}/consultations", response_model=List[ConsultationResponse])
def get_consultations(
    request_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Get all consultations for a service request"""
    
    service_request = db.query(ServiceRequest).filter(
        ServiceRequest.id == request_id
    ).first()
    
    if not service_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service request not found"
        )
    
    # Check permissions
    farm = db.query(Farm).filter(Farm.id == service_request.farm_id).first()
    is_farm_owner = farm and farm.user_id == current_user.id
    
    has_auth = db.query(Authorization).filter(
        Authorization.farm_id == service_request.farm_id,
        Authorization.veterinarian_id == current_user.id,
        Authorization.status == AuthorizationStatus.ACCEPTED,
        Authorization.can_view_data == True,
    ).first() is not None
    
    if not is_farm_owner and not has_auth:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to view these consultations"
        )
    
    consultations = db.query(Consultation).filter(
        Consultation.service_request_id == request_id
    ).all()
    
    return consultations

@router.post("/{request_id}/rate", response_model=ConsultationResponse)
def rate_consultation(
    request_id: int,
    rating: int,
    feedback: str = None,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    """Rate a consultation"""
    
    service_request = db.query(ServiceRequest).filter(
        ServiceRequest.id == request_id,
        ServiceRequest.created_by == current_user.id,
    ).first()
    
    if not service_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service request not found"
        )
    
    consultation = db.query(Consultation).filter(
        Consultation.service_request_id == request_id
    ).first()
    
    if not consultation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consultation not found"
        )
    
    if rating < 1 or rating > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5"
        )
    
    consultation.farmer_rating = rating
    consultation.farmer_feedback = feedback
    
    db.commit()
    db.refresh(consultation)
    
    return consultation
