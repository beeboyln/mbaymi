from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.farm import Crop

router = APIRouter(prefix="/api/crops", tags=["Crops"])

# ═══════════════════════════════════════════════════════════════════════════
# CROP PHOTO ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/{crop_id}/photo")
def add_crop_photo(crop_id: int, payload: dict, db: Session = Depends(get_db)):
    """
    📸 Ajouter une photo de profil à une parcelle.
    
    Payload:
    {
        "image_url": "https://cloudinary.../image.jpg"
    }
    """
    crop = db.query(Crop).filter(Crop.id == crop_id).first()
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    
    image_url = payload.get("image_url")
    if not image_url:
        raise HTTPException(status_code=400, detail="image_url is required")
    
    crop.image_url = image_url
    db.commit()
    db.refresh(crop)
    
    return {"status": "success", "image_url": crop.image_url}
