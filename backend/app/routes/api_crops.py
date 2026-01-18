from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.routes.auth import get_current_user_obj
from app.models.user import User
from app.models.farm import Farm
from app.schemas.schemas import CropCreate, CropResponse
from app.services.crop_service import CropService

router = APIRouter(prefix="/api/crops", tags=["crops"])


@router.post("/", response_model=CropResponse)
def create_crop(farm_id: int, payload: CropCreate, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")

    data = payload.model_dump()
    data["farm_id"] = farm_id
    crop = CropService.create_crop(db, farm_id, data)
    return crop


@router.get("/{crop_id}")
def get_crop(crop_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    c = CropService.get_crop(db, crop_id)
    if not c:
        raise HTTPException(status_code=404, detail="Crop not found")
    farm = db.query(Farm).filter(Farm.id == c.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return c


@router.get("/farm/{farm_id}")
def list_crops(farm_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return CropService.list_crops_for_farm(db, farm_id)


@router.patch("/{crop_id}")
def update_crop(crop_id: int, updates: dict, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    c = CropService.get_crop(db, crop_id)
    if not c:
        raise HTTPException(status_code=404, detail="Crop not found")
    farm = db.query(Farm).filter(Farm.id == c.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return CropService.update_crop(db, crop_id, updates)


@router.delete("/{crop_id}")
def delete_crop(crop_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    c = CropService.get_crop(db, crop_id)
    if not c:
        raise HTTPException(status_code=404, detail="Crop not found")
    farm = db.query(Farm).filter(Farm.id == c.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    ok = CropService.delete_crop(db, crop_id)
    return {"deleted": ok}
