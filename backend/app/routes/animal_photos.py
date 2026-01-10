from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.animal_photo import AnimalPhoto
from app.models.livestock import Livestock
from app.schemas.schemas import AnimalPhotoCreate, AnimalPhotoResponse

router = APIRouter(prefix="/api/animal-photos", tags=["animal_photos"])

@router.post("/", response_model=AnimalPhotoResponse)
def add_animal_photo(photo: AnimalPhotoCreate, db: Session = Depends(get_db)):
    """Add a photo to an animal"""
    # Verify livestock exists
    livestock = db.query(Livestock).filter(Livestock.id == photo.livestock_id).first()
    if not livestock:
        raise HTTPException(status_code=404, detail="Livestock not found")
    
    new_photo = AnimalPhoto(
        livestock_id=photo.livestock_id,
        image_url=photo.image_url,
        caption=photo.caption
    )
    
    db.add(new_photo)
    db.commit()
    db.refresh(new_photo)
    
    return new_photo

@router.get("/livestock/{livestock_id}")
def get_animal_photos(livestock_id: int, db: Session = Depends(get_db)):
    """Get all photos for an animal"""
    photos = db.query(AnimalPhoto).filter(AnimalPhoto.livestock_id == livestock_id).order_by(AnimalPhoto.created_at.desc()).all()
    print(f"📸 Found {len(photos)} photos for livestock {livestock_id}: {[p.id for p in photos]}")
    return photos

@router.delete("/{photo_id}")
def delete_animal_photo(photo_id: int, db: Session = Depends(get_db)):
    """Delete a photo"""
    print(f"🗑️ Attempting to delete photo with id: {photo_id}")
    photo = db.query(AnimalPhoto).filter(AnimalPhoto.id == photo_id).first()
    if not photo:
        print(f"❌ Photo {photo_id} not found in database")
        raise HTTPException(status_code=404, detail=f"Photo with id {photo_id} not found")
    
    print(f"✅ Found photo {photo_id}, deleting...")
    db.delete(photo)
    db.commit()
    print(f"✅ Photo {photo_id} deleted successfully")
    
    return {"detail": "Photo deleted successfully", "status": 200}
