from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.routes.auth import get_current_user_obj
from app.models.user import User
from app.models.farm import Farm
from app.models.farm import Crop
from app.schemas.schemas import InputCreate, InputResponse
from app.services.input_service import InputService

router = APIRouter(prefix="/api/inputs", tags=["inputs"])


@router.post("/", response_model=InputResponse)
def create_input(
    payload: InputCreate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db),
):
    farm = db.query(Farm).filter(Farm.id == payload.farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    if payload.crop_id is None:
        raise HTTPException(status_code=400, detail="crop_id is required")
    crop = db.query(Crop).filter(Crop.id == payload.crop_id, Crop.farm_id == payload.farm_id).first()
    if not crop:
        raise HTTPException(status_code=400, detail="Crop does not belong to this farm")

    item = InputService.create_input(db, payload.model_dump())
    return item


@router.get("/farm/{farm_id}")
def list_inputs(farm_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return InputService.list_inputs_for_farm(db, farm_id)


@router.get("/crop/{crop_id}")
def list_inputs_for_crop(crop_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    crop = db.query(Crop).filter(Crop.id == crop_id).first()
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    farm = db.query(Farm).filter(Farm.id == crop.farm_id).first()
    if not farm or farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return InputService.list_inputs_for_crop(db, crop_id)


@router.get("/{input_id}")
def get_input(input_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    item = InputService.get_input(db, input_id)
    if not item:
        raise HTTPException(status_code=404, detail="Input not found")
    farm = db.query(Farm).filter(Farm.id == item.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return item


@router.patch("/{input_id}")
def update_input(input_id: int, updates: dict, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    item = InputService.get_input(db, input_id)
    if not item:
        raise HTTPException(status_code=404, detail="Input not found")
    farm = db.query(Farm).filter(Farm.id == item.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    updated = InputService.update_input(db, input_id, updates)
    return updated


@router.delete("/{input_id}")
def delete_input(input_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    item = InputService.get_input(db, input_id)
    if not item:
        raise HTTPException(status_code=404, detail="Input not found")
    farm = db.query(Farm).filter(Farm.id == item.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    ok = InputService.delete_input(db, input_id)
    return {"deleted": ok}
