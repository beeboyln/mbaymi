from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from app.database import get_db
from app.models.farm import Farm, Crop
from app.models.photo import FarmPhoto
from app.models.user import User
from app.models.livestock import Livestock
from app.models.farm_network import FarmProfile
from app.models.crop_problem import CropProblem
from app.schemas.schemas import FarmCreate, FarmResponse, CropCreate, CropResponse
from app.schemas.pagination import paginate_query, PaginatedResponse
from app.routes.auth import get_current_user_obj
from typing import Optional

router = APIRouter(tags=["farms"])

@router.get("/", response_model=list)
def get_current_user_farms(
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """✅ OPTIMIZED: Get all farms for the authenticated user with their livestock (N+1 fixed)"""
    # Also get user's livestock
    livestocks = db.query(Livestock).filter(
        Livestock.user_id == current_user.id,
        Livestock.deleted_at.is_(None),
    ).all()
    livestock_list = [
        {
            'id': l.id,
            'user_id': l.user_id,
            'animal_type': l.animal_type,
            'breed': l.breed,
            'quantity': l.quantity,
            'age_months': l.age_months,
            'weight_kg': l.weight_kg,
            'health_status': l.health_status,
            'last_vaccination_date': l.last_vaccination_date,
            'feeding_type': l.feeding_type,
            'location': l.location,
            'notes': l.notes,
            'image_url': l.image_url,
            'created_at': l.created_at,
            'updated_at': l.updated_at,
        }
        for l in livestocks
    ]
    
    # ✅ OPTIMIZATION: Load farms with photos and crops in ONE query instead of N+1
    farms = db.query(Farm)\
        .filter(Farm.user_id == current_user.id)\
        .options(
            joinedload(Farm.photos),
            joinedload(Farm.crops)
        )\
        .all()
    
    result = []
    for f in farms:
        d = {
            'id': f.id,
            'user_id': f.user_id,
            'name': f.name,
            'location': f.location,
            'size_hectares': f.size_hectares,
            'soil_type': f.soil_type,
            'image_url': f.image_url,
            'latitude': f.latitude,
            'longitude': f.longitude,
            'created_at': f.created_at,
            'updated_at': f.updated_at,
            'photos': [{'id': p.id, 'image_url': p.image_url} for p in f.photos],
            'crops': [
                {
                    'id': c.id,
                    'crop_name': c.crop_name,
                    'variety': c.variety,
                    'status': c.status,
                    'image_url': c.image_url,
                }
                for c in f.crops
            ],
            'livestocks': livestock_list  # Include all user's livestocks
        }
        result.append(d)
    
    # If user has no farms, return a single entry with their livestock info
    if not result:
        result = [{
            'id': None,
            'user_id': current_user.id,
            'name': None,
            'location': None,
            'size_hectares': None,
            'soil_type': None,
            'image_url': None,
            'latitude': None,
            'longitude': None,
            'created_at': None,
            'updated_at': None,
            'photos': [],
            'livestocks': livestock_list
        }]
    
    return result

@router.post("/", response_model=FarmResponse)
def create_farm(farm: FarmCreate, user_id: int, db: Session = Depends(get_db)):
    # Check if user exists
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    new_farm = Farm(
        user_id=user_id,
        name=farm.name,
        location=farm.location,
        size_hectares=farm.size_hectares,
        soil_type=farm.soil_type
        ,
        image_url=farm.image_url,
        latitude=farm.latitude,
        longitude=farm.longitude
    )
    
    db.add(new_farm)
    db.commit()
    db.refresh(new_farm)
    
    # Automatically create a FarmProfile for the new farm
    farm_profile = FarmProfile(
        farm_id=new_farm.id,
        user_id=user_id,
        is_public=True,  # Default to public
        description="",
        specialties="",
    )
    db.add(farm_profile)
    db.commit()
    
    return new_farm

@router.get("/{farm_id}")
def get_farm(farm_id: int, db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    # attach photo URLs
    photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == farm_id).all()
    return {
        'id': farm.id,
        'user_id': farm.user_id,
        'name': farm.name,
        'location': farm.location,
        'size_hectares': farm.size_hectares,
        'soil_type': farm.soil_type,
        'image_url': farm.image_url,
        'latitude': farm.latitude,
        'longitude': farm.longitude,
        'created_at': farm.created_at,
        'updated_at': farm.updated_at,
        'photos': [{'id': p.id, 'image_url': p.image_url} for p in photos]
    }

@router.get("/user/{user_id}")
def get_user_farms(
    user_id: int,
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    location: Optional[str] = Query(None),
):
    """Get paginated farms for a specific user with optional location filtering"""
    query = db.query(Farm).filter(Farm.user_id == user_id)
    
    # Apply location filter if provided
    if location and location != "Tous":
        query = query.filter(Farm.location == location)
    
    # Load photos with joinedload for efficiency
    query = query.options(joinedload(Farm.photos))
    
    items, total, total_pages, has_next, has_previous = paginate_query(
        query, page, limit, Farm.created_at, "desc"
    )
    
    result = []
    for f in items:
        d = {
            'id': f.id,
            'user_id': f.user_id,
            'name': f.name,
            'location': f.location,
            'size_hectares': f.size_hectares,
            'soil_type': f.soil_type,
            'image_url': f.image_url,
            'latitude': f.latitude,
            'longitude': f.longitude,
            'created_at': f.created_at,
            'updated_at': f.updated_at,
            'photos': [{'id': p.id, 'image_url': p.image_url} for p in f.photos]
        }
        result.append(d)
    
    return {
        "items": result,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": total_pages,
        "has_next": has_next,
        "has_previous": has_previous,
    }


@router.put("/{farm_id}")
def update_farm(farm_id: int, farm: FarmCreate, db: Session = Depends(get_db)):
    existing = db.query(Farm).filter(Farm.id == farm_id).first()
    if not existing:
        raise HTTPException(status_code=404, detail="Farm not found")
    existing.name = farm.name
    existing.location = farm.location
    existing.size_hectares = farm.size_hectares
    existing.soil_type = farm.soil_type
    existing.image_url = farm.image_url
    existing.latitude = farm.latitude
    existing.longitude = farm.longitude
    db.add(existing)
    db.commit()
    db.refresh(existing)
    photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == farm_id).all()
    return {
        'id': existing.id,
        'user_id': existing.user_id,
        'name': existing.name,
        'location': existing.location,
        'size_hectares': existing.size_hectares,
        'soil_type': existing.soil_type,
        'image_url': existing.image_url,
        'latitude': existing.latitude,
        'longitude': existing.longitude,
        'created_at': existing.created_at,
        'updated_at': existing.updated_at,
        'photos': [{'id': p.id, 'image_url': p.image_url} for p in photos]
    }


@router.delete("/{farm_id}")
def delete_farm(
    farm_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    # Check authorization - only farm owner can delete
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this farm")
    
    try:
        # Import all models that need to be deleted
        from app.models.input import Input
        from app.models.harvest import Harvest
        from app.models.activity import Activity
        from app.models.reminder import Reminder
        from app.models.finance import FinanceTransaction
        from app.models.crop_problem import CropProblem
        from app.models.farm_post import FarmImagePost
        from app.models.farm_network import FarmProfile, FarmPost, FarmFollowing
        from app.models.authorization import Authorization
        from app.models.service_request import ServiceRequest
        
        # Delete in correct order to avoid foreign key violations:
        # 1. Delete farm posts
        db.query(FarmImagePost).filter(FarmImagePost.farm_id == farm_id).delete()
        db.query(FarmPost).filter(FarmPost.farm_id == farm_id).delete()
        
        # 2. Delete farm profile
        db.query(FarmProfile).filter(FarmProfile.farm_id == farm_id).delete()
        
        # 3. Delete farm following records
        db.query(FarmFollowing).filter(FarmFollowing.farm_id == farm_id).delete()
        
        # 4. Delete authorization records
        db.query(Authorization).filter(Authorization.farm_id == farm_id).delete()
        
        # 5. Delete service requests
        db.query(ServiceRequest).filter(ServiceRequest.farm_id == farm_id).delete()
        
        # 6. Delete inputs (references crops and farm)
        db.query(Input).filter(Input.farm_id == farm_id).delete()
        
        # 7. Delete crop-related records that reference crops in this farm
        crop_ids = db.query(Crop.id).filter(Crop.farm_id == farm_id).all()
        crop_ids_list = [c[0] for c in crop_ids]
        
        if crop_ids_list:
            db.query(CropProblem).filter(CropProblem.crop_id.in_(crop_ids_list)).delete()
            db.query(Activity).filter(Activity.crop_id.in_(crop_ids_list)).delete()
            db.query(Reminder).filter(Reminder.crop_id.in_(crop_ids_list)).delete()
            db.query(FinanceTransaction).filter(FinanceTransaction.crop_id.in_(crop_ids_list)).delete()
            db.query(Harvest).filter(Harvest.crop_id.in_(crop_ids_list)).delete()
        
        # 8. Delete farm-level records
        db.query(CropProblem).filter(CropProblem.farm_id == farm_id).delete()
        db.query(Activity).filter(Activity.farm_id == farm_id).delete()
        db.query(Reminder).filter(Reminder.farm_id == farm_id).delete()
        db.query(FinanceTransaction).filter(FinanceTransaction.farm_id == farm_id).delete()
        db.query(Harvest).filter(Harvest.farm_id == farm_id).delete()
        
        # 9. Delete farm photos
        db.query(FarmPhoto).filter(FarmPhoto.farm_id == farm_id).delete()
        
        # 10. Delete crops
        db.query(Crop).filter(Crop.farm_id == farm_id).delete()
        
        # 11. Delete the farm itself
        db.delete(farm)
        db.commit()
        
        return {"status": "deleted", "message": "Farm and all related data deleted successfully"}
    except Exception as e:
        db.rollback()
        print(f"Error deleting farm {farm_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error deleting farm: {str(e)}")


@router.post("/{farm_id}/photos")
def add_farm_photo(farm_id: int, payload: dict, db: Session = Depends(get_db)):
    # payload should contain 'image_url'
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    url = payload.get('image_url')
    if not url:
        raise HTTPException(status_code=400, detail="image_url required")
    photo = FarmPhoto(farm_id=farm_id, image_url=url)
    db.add(photo)
    db.commit()
    db.refresh(photo)
    return {"id": photo.id, "image_url": photo.image_url}


@router.get("/{farm_id}/photos")
def list_farm_photos(farm_id: int, db: Session = Depends(get_db)):
    photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == farm_id).order_by(FarmPhoto.created_at.desc()).all()
    return [{"id": p.id, "image_url": p.image_url, "created_at": p.created_at} for p in photos]


@router.delete("/{farm_id}/photos/{photo_id}")
def delete_farm_photo(farm_id: int, photo_id: int, db: Session = Depends(get_db)):
    photo = db.query(FarmPhoto).filter(FarmPhoto.id == photo_id, FarmPhoto.farm_id == farm_id).first()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    db.delete(photo)
    db.commit()
    return {"status": "deleted"}


@router.delete("/{farm_id}/profile")
def delete_farm_profile(farm_id: int, db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    # Clear the profile image_url
    farm.image_url = None
    db.add(farm)
    db.commit()
    db.refresh(farm)
    return {"status": "deleted", "image_url": None}

@router.post("/{farm_id}/crops", response_model=CropResponse)
def add_crop(farm_id: int, crop: CropCreate, db: Session = Depends(get_db)):
    # Check if farm exists
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    new_crop = Crop(
        farm_id=farm_id,
        crop_name=crop.crop_name,
        planted_date=crop.planted_date,
        expected_harvest_date=crop.expected_harvest_date,
        quantity_planted=crop.quantity_planted,
        expected_yield=crop.expected_yield,
        status=crop.status,
        notes=crop.notes,
        area=crop.area,
    )
    
    db.add(new_crop)
    db.commit()
    db.refresh(new_crop)
    
    return new_crop

@router.get("/{farm_id}/crops")
def get_farm_crops(farm_id: int, db: Session = Depends(get_db)):
    """Get all crops for a farm with their associated problems (unresolved only)"""
    crops = db.query(Crop).filter(Crop.farm_id == farm_id).all()
    
    result = []
    for crop in crops:
        # Get unresolved problems for this crop
        problems = db.query(CropProblem).filter(
            CropProblem.crop_id == crop.id,
            CropProblem.status != 'resolved'
        ).all()
        
        # Convert crop to dict
        crop_dict = {
            'id': crop.id,
            'farm_id': crop.farm_id,
            'crop_name': crop.crop_name,
            'planted_date': crop.planted_date,
            'expected_harvest_date': crop.expected_harvest_date,
            'quantity_planted': crop.quantity_planted,
            'expected_yield': crop.expected_yield,
            'status': crop.status,
            'notes': crop.notes,
            'image_url': crop.image_url,
            'variety': crop.variety,
            'objective': crop.objective,
            'area': crop.area,
            'created_at': crop.created_at,
            'updated_at': crop.updated_at,
            'problems': [
                {
                    'id': p.id,
                    'problem_type': p.problem_type,
                    'description': p.description,
                    'photo_url': p.photo_url,
                    'severity': p.severity,
                    'status': p.status,
                    'created_at': p.created_at.isoformat() if p.created_at else None,
                }
                for p in problems
            ]
        }
        result.append(crop_dict)
    
    return result
