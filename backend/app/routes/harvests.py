from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.harvest import Harvest
from app.models.farm import Farm
from app.schemas.schemas import HarvestCreate, HarvestResponse

router = APIRouter(prefix="/api/harvests", tags=["harvests"])

@router.post("/", response_model=HarvestResponse)
def create_harvest(h: HarvestCreate, db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == h.farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")

    new_h = Harvest(
        farm_id=h.farm_id,
        crop_id=h.crop_id,
        estimated_quantity=h.estimated_quantity,
        actual_quantity=h.actual_quantity,
        harvest_date=h.harvest_date,
        notes=h.notes,
    )

    db.add(new_h)
    db.commit()
    db.refresh(new_h)

    return new_h

@router.get("/farm/{farm_id}")
def get_harvests_for_farm(farm_id: int, db: Session = Depends(get_db)):
    items = db.query(Harvest).filter(Harvest.farm_id == farm_id).order_by(Harvest.harvest_date.desc()).all()
    return items

@router.get("/crop/{crop_id}")
def get_harvests_for_crop(crop_id: int, db: Session = Depends(get_db)):
    items = db.query(Harvest).filter(Harvest.crop_id == crop_id).order_by(Harvest.harvest_date.desc()).all()
    return items
