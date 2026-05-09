from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.livestock import Livestock
from app.models.user import User
from app.schemas.schemas import LivestockCreate, LivestockResponse

router = APIRouter(prefix="/api/livestock", tags=["livestock"])

@router.post("/", response_model=LivestockResponse)
def add_livestock(livestock: LivestockCreate, user_id: int, db: Session = Depends(get_db)):
    # Check if user exists
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    new_livestock = Livestock(
        user_id=user_id,
        animal_type=livestock.animal_type,
        breed=livestock.breed,
        quantity=livestock.quantity,
        age_months=livestock.age_months,
        weight_kg=livestock.weight_kg,
        health_status=livestock.health_status,
        feeding_type=livestock.feeding_type,
        location=livestock.location,
        notes=livestock.notes,
        image_url=getattr(livestock, 'image_url', None),
        visibility=livestock.visibility
    )
    
    db.add(new_livestock)
    db.commit()
    db.refresh(new_livestock)
    
    return new_livestock

@router.get("/public")
def get_public_livestock(db: Session = Depends(get_db), user_id: int = None):
    """Get all livestock for network display with user info"""
    try:
        from app.models.user import User
        # Only get non-deleted livestock
        livestock_list = db.query(Livestock).filter(Livestock.deleted_at == None).all()
        
        # Enrich with user information
        enriched = []
        for animal in livestock_list:
            user = db.query(User).filter(User.id == animal.user_id).first()
            
            # Check if current user liked this animal
            is_liked = False
            if user_id:
                from sqlalchemy import text
                result = db.execute(text(f"SELECT id FROM livestock_likes WHERE livestock_id = {animal.id} AND user_id = {user_id}"))
                is_liked = result.fetchone() is not None
            
            animal_dict = {
                'id': animal.id,
                'user_id': animal.user_id,
                'user_name': user.name if user else 'Utilisateur',
                'user_profile_image': user.profile_image if user else None,
                'animal_type': animal.animal_type,
                'breed': animal.breed,
                'quantity': animal.quantity,
                'age_months': animal.age_months,
                'weight_kg': animal.weight_kg,
                'health_status': animal.health_status,
                'location': animal.location,
                'notes': animal.notes,
                'image_url': animal.image_url,
                'visibility': animal.visibility,
                'created_at': animal.created_at.isoformat() if animal.created_at else None,
                'updated_at': animal.updated_at.isoformat() if animal.updated_at else None,
                'deleted_at': animal.deleted_at.isoformat() if animal.deleted_at else None,
                'likes_count': animal.likes_count or 0,
                'comments_count': animal.comments_count or 0,
                'shares_count': animal.shares_count or 0,
                'is_liked': is_liked,
            }
            enriched.append(animal_dict)
        
        return enriched
    except Exception as e:
        print(f"Error fetching all livestock: {str(e)}")
        raise HTTPException(status_code=500, detail="Error fetching livestock")

@router.get("/user/{user_id}")
def get_user_livestock(user_id: int, db: Session = Depends(get_db)):
    try:
        # Only get non-deleted livestock
        livestock_list = db.query(Livestock).filter(
            Livestock.user_id == user_id,
            Livestock.deleted_at == None
        ).all()
        return livestock_list
    except Exception as e:
        print(f"Error fetching livestock for user {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Error fetching livestock")

@router.get("/{livestock_id:int}", response_model=LivestockResponse)
def get_livestock(livestock_id: int, db: Session = Depends(get_db)):
    livestock = db.query(Livestock).filter(
        Livestock.id == livestock_id,
        Livestock.deleted_at == None
    ).first()
    if not livestock:
        raise HTTPException(status_code=404, detail="Livestock not found")
    return livestock

@router.put("/{livestock_id}", response_model=LivestockResponse)
def update_livestock(livestock_id: int, livestock: LivestockCreate, db: Session = Depends(get_db)):
    existing = db.query(Livestock).filter(Livestock.id == livestock_id).first()
    if not existing:
        raise HTTPException(status_code=404, detail="Livestock not found")
    
    for key, value in livestock.dict(exclude_unset=True).items():
        setattr(existing, key, value)
    
    # Allow updating image_url if provided
    if hasattr(livestock, 'image_url') and livestock.image_url:
        existing.image_url = livestock.image_url
    
    db.commit()
    db.refresh(existing)
    
    return existing

@router.delete("/{livestock_id}")
def delete_livestock(livestock_id: int, db: Session = Depends(get_db)):
    """Soft delete livestock by setting deleted_at timestamp"""
    livestock = db.query(Livestock).filter(Livestock.id == livestock_id).first()
    if not livestock:
        raise HTTPException(status_code=404, detail="Livestock not found")
    
    # Soft delete: set deleted_at timestamp instead of hard delete
    from datetime import datetime
    livestock.deleted_at = datetime.utcnow()
    db.commit()
    
    return {"message": f"Livestock {livestock_id} deleted successfully"}
