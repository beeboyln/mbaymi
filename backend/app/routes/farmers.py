from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.farm import Farm, Crop
from app.models.photo import FarmPhoto
from app.models.user import User
from app.schemas.schemas import FarmCreate, FarmResponse, CropCreate, CropResponse

router = APIRouter(prefix="/api/farms", tags=["farms"])

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
    
    return new_farm

@router.get("/{farm_id}", response_model=FarmResponse)
def get_farm(farm_id: int, db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    # attach photo URLs
    photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == farm_id).all()
    farm_dict = farm.__dict__.copy()
    farm_dict['photos'] = [{'id': p.id, 'image_url': p.image_url} for p in photos]
    return farm_dict

@router.get("/user/{user_id}")
def get_user_farms(user_id: int, db: Session = Depends(get_db)):
    farms = db.query(Farm).filter(Farm.user_id == user_id).all()
    result = []
    for f in farms:
        photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == f.id).all()
        d = f.__dict__.copy()
        d['photos'] = [{'id': p.id, 'image_url': p.image_url} for p in photos]
        result.append(d)
    return result


@router.put("/{farm_id}", response_model=FarmResponse)
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
    d = existing.__dict__.copy()
    d['photos'] = [p.image_url for p in photos]
    return d


@router.delete("/{farm_id}")
def delete_farm(farm_id: int, db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    # Delete all related photos first
    db.query(FarmPhoto).filter(FarmPhoto.farm_id == farm_id).delete()
    
    # Delete all related crops
    db.query(Crop).filter(Crop.farm_id == farm_id).delete()
    
    # Delete all related harvests
    from app.models.harvest import Harvest
    db.query(Harvest).filter(Harvest.farm_id == farm_id).delete()
    
    # Delete all related sales
    from app.models.sale import Sale
    db.query(Sale).filter(Sale.farm_id == farm_id).delete()
    
    # Delete all related livestock
    from app.models.livestock import Livestock
    db.query(Livestock).filter(Livestock.farm_id == farm_id).delete()
    
    # Delete the farm
    db.delete(farm)
    db.commit()
    
    return {"status": "deleted"}


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
        notes=crop.notes
    )
    
    db.add(new_crop)
    db.commit()
    db.refresh(new_crop)
    
    return new_crop

@router.get("/{farm_id}/crops")
def get_farm_crops(farm_id: int, db: Session = Depends(get_db)):
    crops = db.query(Crop).filter(Crop.farm_id == farm_id).all()
    return crops
@router.post("/{farm_id}/crops/{crop_id}/photo")
def add_crop_photo(farm_id: int, crop_id: int, payload: dict, db: Session = Depends(get_db)):
    """
    📸 Ajouter une photo de profil à une parcelle.
    
    Payload:
    {
        "image_url": "https://cloudinary.../image.jpg"
    }
    """
    crop = db.query(Crop).filter(Crop.id == crop_id, Crop.farm_id == farm_id).first()
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    
    image_url = payload.get("image_url")
    if not image_url:
        raise HTTPException(status_code=400, detail="image_url is required")
    
    crop.image_url = image_url
    db.commit()
    db.refresh(crop)
    
    return {"status": "success", "image_url": crop.image_url}