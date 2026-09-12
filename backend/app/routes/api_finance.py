from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.routes.auth import get_current_user_obj
from app.models.user import User
from app.models.farm import Farm
from app.models.farm import Crop
from app.models.activity import Activity
from app.schemas.schemas import FinanceTransactionCreate, FinanceTransactionResponse
from app.services.finance_service import FinanceService

router = APIRouter(prefix="/api/finance", tags=["finance"])


@router.post("/transactions/", response_model=FinanceTransactionResponse)
def create_transaction(
    payload: FinanceTransactionCreate,
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
    if payload.activity_id is not None:
        activity = db.query(Activity).filter(
            Activity.id == payload.activity_id,
            Activity.crop_id == payload.crop_id,
        ).first()
        if not activity:
            raise HTTPException(status_code=400, detail="Activity does not belong to this crop")

    t = FinanceService.create_transaction(db, payload.model_dump())
    return t


@router.get("/transactions/farm/{farm_id}")
def list_transactions(farm_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return FinanceService.list_transactions_for_farm(db, farm_id)


@router.get("/transactions/crop/{crop_id}")
def list_transactions_for_crop(crop_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    crop = db.query(Crop).filter(Crop.id == crop_id).first()
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    farm = db.query(Farm).filter(Farm.id == crop.farm_id).first()
    if not farm or farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return FinanceService.list_transactions_for_crop(db, crop_id)


@router.get("/transactions/{transaction_id}")
def get_transaction(transaction_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    t = FinanceService.get_transaction(db, transaction_id)
    if not t:
        raise HTTPException(status_code=404, detail="Transaction not found")
    farm = db.query(Farm).filter(Farm.id == t.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return t


@router.patch("/transactions/{transaction_id}")
def update_transaction(transaction_id: int, updates: dict, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    t = FinanceService.get_transaction(db, transaction_id)
    if not t:
        raise HTTPException(status_code=404, detail="Transaction not found")
    farm = db.query(Farm).filter(Farm.id == t.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    if "activity_id" in updates and updates["activity_id"] is not None:
        activity = db.query(Activity).filter(
            Activity.id == updates["activity_id"],
            Activity.crop_id == t.crop_id,
        ).first()
        if not activity:
            raise HTTPException(status_code=400, detail="Activity does not belong to this crop")
    return FinanceService.update_transaction(db, transaction_id, updates)


@router.delete("/transactions/{transaction_id}")
def delete_transaction(transaction_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    t = FinanceService.get_transaction(db, transaction_id)
    if not t:
        raise HTTPException(status_code=404, detail="Transaction not found")
    farm = db.query(Farm).filter(Farm.id == t.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    ok = FinanceService.delete_transaction(db, transaction_id)
    return {"deleted": ok}


@router.get("/summary/crop/{crop_id}")
def summary_for_crop(crop_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    crop = db.query(Crop).filter(Crop.id == crop_id).first()
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    farm = db.query(Farm).filter(Farm.id == crop.farm_id).first()
    if not farm or farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return FinanceService.summary_for_crop(db, crop_id)


@router.get("/summary/{farm_id}")
def summary(farm_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return FinanceService.summary_for_farm(db, farm_id)
