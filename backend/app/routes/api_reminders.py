from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.routes.auth import get_current_user_obj
from app.models.user import User
from app.models.farm import Farm
from app.schemas.schemas import ReminderCreate, ReminderResponse
from app.services.reminder_service import ReminderService

router = APIRouter(prefix="/api/reminders", tags=["reminders"])


@router.post("/", response_model=ReminderResponse)
def create_reminder(payload: ReminderCreate, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == payload.farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    r = ReminderService.create_reminder(db, payload.model_dump())
    return r


@router.get("/farm/{farm_id}")
def list_reminders(farm_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return ReminderService.list_reminders_for_farm(db, farm_id)


@router.get("/{reminder_id}")
def get_reminder(reminder_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    r = ReminderService.get_reminder(db, reminder_id)
    if not r:
        raise HTTPException(status_code=404, detail="Reminder not found")
    farm = db.query(Farm).filter(Farm.id == r.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return r


@router.patch("/{reminder_id}")
def update_reminder(reminder_id: int, updates: dict, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    r = ReminderService.get_reminder(db, reminder_id)
    if not r:
        raise HTTPException(status_code=404, detail="Reminder not found")
    farm = db.query(Farm).filter(Farm.id == r.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return ReminderService.update_reminder(db, reminder_id, updates)


@router.post("/{reminder_id}/done/")
def mark_done(reminder_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    r = ReminderService.get_reminder(db, reminder_id)
    if not r:
        raise HTTPException(status_code=404, detail="Reminder not found")
    farm = db.query(Farm).filter(Farm.id == r.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    return ReminderService.mark_done(db, reminder_id)


@router.delete("/{reminder_id}")
def delete_reminder(reminder_id: int, current_user: User = Depends(get_current_user_obj), db: Session = Depends(get_db)):
    r = ReminderService.get_reminder(db, reminder_id)
    if not r:
        raise HTTPException(status_code=404, detail="Reminder not found")
    farm = db.query(Farm).filter(Farm.id == r.farm_id).first()
    if farm.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You don't own this farm")
    ok = ReminderService.delete_reminder(db, reminder_id)
    return {"deleted": ok}
