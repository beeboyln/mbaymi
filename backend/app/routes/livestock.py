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
        notes=livestock.notes
    )
    
    db.add(new_livestock)
    db.commit()
    db.refresh(new_livestock)
    
    return new_livestock

@router.get("/{livestock_id}", response_model=LivestockResponse)
def get_livestock(livestock_id: int, db: Session = Depends(get_db)):
    livestock = db.query(Livestock).filter(Livestock.id == livestock_id).first()
    if not livestock:
        raise HTTPException(status_code=404, detail="Livestock not found")
    return livestock

@router.get("/user/{user_id}")
def get_user_livestock(user_id: int, db: Session = Depends(get_db)):
    livestock_list = db.query(Livestock).filter(Livestock.user_id == user_id).all()
    return livestock_list

@router.put("/{livestock_id}", response_model=LivestockResponse)
def update_livestock(livestock_id: int, livestock: LivestockCreate, db: Session = Depends(get_db)):
    existing = db.query(Livestock).filter(Livestock.id == livestock_id).first()
    if not existing:
        raise HTTPException(status_code=404, detail="Livestock not found")
    
    for key, value in livestock.dict(exclude_unset=True).items():
        setattr(existing, key, value)
    
    db.commit()
    db.refresh(existing)
    
    return existing
