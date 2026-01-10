from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.pasture_image import PastureImage
from app.models.user import User
from app.schemas.schemas import PastureImageCreate, PastureImageResponse

router = APIRouter(prefix="/api/pasture", tags=["pasture"])

@router.post("/images", response_model=PastureImageResponse)
def add_pasture_image(image: PastureImageCreate, user_id: int, db: Session = Depends(get_db)):
    """Upload an image of the pasture/enclosure"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    new_image = PastureImage(
        user_id=user_id,
        image_url=image.image_url,
        title=image.title,
        description=image.description
    )
    
    db.add(new_image)
    db.commit()
    db.refresh(new_image)
    
    return new_image

@router.get("/images/user/{user_id}")
def get_pasture_images(user_id: int, db: Session = Depends(get_db)):
    """Get all pasture images for a user"""
    try:
        images = db.query(PastureImage).filter(PastureImage.user_id == user_id).order_by(PastureImage.created_at.desc()).all()
        return images
    except Exception as e:
        print(f"Error fetching pasture images for user {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching pasture images: {str(e)}")

@router.get("/images/{image_id}", response_model=PastureImageResponse)
def get_pasture_image(image_id: int, db: Session = Depends(get_db)):
    """Get a specific pasture image"""
    image = db.query(PastureImage).filter(PastureImage.id == image_id).first()
    if not image:
        raise HTTPException(status_code=404, detail="Image not found")
    return image

@router.put("/images/{image_id}", response_model=PastureImageResponse)
def update_pasture_image(image_id: int, image: PastureImageCreate, db: Session = Depends(get_db)):
    """Update pasture image details"""
    existing = db.query(PastureImage).filter(PastureImage.id == image_id).first()
    if not existing:
        raise HTTPException(status_code=404, detail="Image not found")
    
    existing.image_url = image.image_url
    existing.title = image.title
    existing.description = image.description
    
    db.commit()
    db.refresh(existing)
    
    return existing

@router.delete("/images/{image_id}")
def delete_pasture_image(image_id: int, db: Session = Depends(get_db)):
    """Delete a pasture image"""
    image = db.query(PastureImage).filter(PastureImage.id == image_id).first()
    if not image:
        raise HTTPException(status_code=404, detail="Image not found")
    
    db.delete(image)
    db.commit()
    
    return {"detail": "Image deleted successfully"}
