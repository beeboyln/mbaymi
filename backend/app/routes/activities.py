from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.database import get_db
from app.models.activity import Activity
from app.models.photo import ActivityPhoto
from app.models.farm import Farm
from app.schemas.schemas import ActivityCreate, ActivityResponse
from app.models.input import Input
from app.models.notification import Notification
from app.models.finance import FinanceTransaction
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/api/activities", tags=["activities"])

@router.post("/", response_model=ActivityResponse)
def create_activity(activity: ActivityCreate, db: Session = Depends(get_db)):
    try:
        # Ensure farm exists
        farm = db.query(Farm).filter(Farm.id == activity.farm_id).first()
        if not farm:
            raise HTTPException(status_code=404, detail="Farm not found")
        if activity.finance_amount is not None and activity.finance_amount > 0 and activity.finance_type not in ('expense', 'income'):
            raise HTTPException(status_code=400, detail="finance_type must be expense or income")
        input_item = None
        if activity.input_id is not None:
            input_item = db.query(Input).filter(
                Input.id == activity.input_id,
                Input.farm_id == activity.farm_id,
                or_(Input.crop_id == activity.crop_id, Input.crop_id.is_(None)),
            ).first()
            if not input_item:
                raise HTTPException(status_code=400, detail="Input does not belong to this farm or crop")
            if activity.quantity_used is None or activity.quantity_used <= 0:
                raise HTTPException(status_code=400, detail="quantity_used must be greater than zero")
            if input_item.quantity is None or activity.quantity_used > input_item.quantity:
                raise HTTPException(status_code=400, detail="Insufficient input stock")
            input_item.quantity -= activity.quantity_used

        new_activity = Activity(
            farm_id=activity.farm_id,
            crop_id=activity.crop_id,
            user_id=activity.user_id,
            activity_type=activity.activity_type,
            activity_date=activity.activity_date,
            notes=activity.notes,
            input_id=activity.input_id,
            quantity_used=activity.quantity_used,
            finance_type=activity.finance_type,
            finance_amount=activity.finance_amount,
        )

        db.add(new_activity)
        db.commit()
        db.refresh(new_activity)

        if activity.finance_amount is not None and activity.finance_amount > 0:
            db.add(FinanceTransaction(
                farm_id=activity.farm_id,
                crop_id=activity.crop_id,
                activity_id=new_activity.id,
                transaction_type=activity.finance_type,
                category=activity.activity_type,
                amount=activity.finance_amount,
                transaction_date=activity.activity_date,
                notes=activity.notes,
            ))
            db.commit()

        if input_item and input_item.quantity <= (input_item.reorder_threshold or 0):
            existing_notice = db.query(Notification).filter(
                Notification.user_id == farm.user_id,
                Notification.type == 'input_low_stock',
                Notification.crop_id == activity.crop_id,
                Notification.description.like(f'%{input_item.name or input_item.input_type}%'),
            ).first()
            if not existing_notice:
                NotificationService.create_notification(
                    db=db,
                    user_id=farm.user_id,
                    title=f"Stock faible : {input_item.name or input_item.input_type or 'Intrant'}",
                    description=f"Il reste {input_item.quantity:g} {input_item.unit or ''}. Pensez à réapprovisionner.",
                    notification_type='input_low_stock',
                    actor_name='Gestion des stocks',
                    farm_id=activity.farm_id,
                    crop_id=activity.crop_id,
                    action_url=f'/inputs/{input_item.id}',
                )

        # If image URLs were provided, create ActivityPhoto rows
        image_urls = getattr(activity, 'image_urls', None)
        saved_urls = []
        if image_urls:
            for url in image_urls:
                p = ActivityPhoto(activity_id=new_activity.id, image_url=url)
                db.add(p)
                saved_urls.append(url)
            db.commit()

        # Build clean response dict
        resp = {
            'id': new_activity.id,
            'farm_id': new_activity.farm_id,
            'crop_id': new_activity.crop_id,
            'user_id': new_activity.user_id,
            'activity_type': new_activity.activity_type,
            'activity_date': new_activity.activity_date,
            'notes': new_activity.notes,
            'input_id': new_activity.input_id,
            'quantity_used': new_activity.quantity_used,
            'finance_type': new_activity.finance_type,
            'finance_amount': new_activity.finance_amount,
            'created_at': new_activity.created_at,
            'image_urls': saved_urls,
        }
        return resp
    except HTTPException:
        raise
    except Exception as e:
        # Log and return a clear 500 error
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/farm/{farm_id}")
def list_activities_for_farm(farm_id: int, db: Session = Depends(get_db)):
    try:
        activities = db.query(Activity).filter(Activity.farm_id == farm_id).order_by(Activity.activity_date.desc()).all()
        result = []
        for a in activities:
            photos = db.query(ActivityPhoto).filter(ActivityPhoto.activity_id == a.id).all()
            result.append({
                'id': a.id,
                'farm_id': a.farm_id,
                'crop_id': a.crop_id,
                'input_id': a.input_id,
                'quantity_used': a.quantity_used,
                'finance_type': a.finance_type,
                'finance_amount': a.finance_amount,
                'user_id': a.user_id,
                'activity_type': a.activity_type,
                'activity_date': a.activity_date,
                'notes': a.notes,
                'created_at': a.created_at,
                'image_urls': [p.image_url for p in photos],
            })
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/crop/{crop_id}")
def list_activities_for_crop(crop_id: int, db: Session = Depends(get_db)):
    try:
        activities = db.query(Activity).filter(Activity.crop_id == crop_id).order_by(Activity.activity_date.desc()).all()
        result = []
        from app.models.photo import ActivityPhoto
        for a in activities:
            photos = db.query(ActivityPhoto).filter(ActivityPhoto.activity_id == a.id).all()
            result.append({
                'id': a.id,
                'farm_id': a.farm_id,
                'crop_id': a.crop_id,
                'input_id': a.input_id,
                'quantity_used': a.quantity_used,
                'finance_type': a.finance_type,
                'finance_amount': a.finance_amount,
                'user_id': a.user_id,
                'activity_type': a.activity_type,
                'activity_date': a.activity_date,
                'notes': a.notes,
                'created_at': a.created_at,
                'image_urls': [p.image_url for p in photos],
            })
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{activity_id}", response_model=ActivityResponse)
def update_activity(activity_id: int, activity: ActivityCreate, db: Session = Depends(get_db)):
    try:
        # Find existing activity
        existing = db.query(Activity).filter(Activity.id == activity_id).first()
        if not existing:
            raise HTTPException(status_code=404, detail="Activity not found")
        
        # Update fields
        existing.activity_type = activity.activity_type
        existing.activity_date = activity.activity_date
        existing.notes = activity.notes
        existing.input_id = activity.input_id
        existing.quantity_used = activity.quantity_used
        existing.finance_type = activity.finance_type
        existing.finance_amount = activity.finance_amount
        
        db.commit()
        db.refresh(existing)

        transaction = db.query(FinanceTransaction).filter(
            FinanceTransaction.activity_id == existing.id
        ).first()
        if activity.finance_amount is not None and activity.finance_amount > 0:
            if activity.finance_type not in ('expense', 'income'):
                raise HTTPException(status_code=400, detail="finance_type must be expense or income")
            if transaction:
                transaction.transaction_type = activity.finance_type
                transaction.category = activity.activity_type
                transaction.amount = activity.finance_amount
                transaction.transaction_date = activity.activity_date
                transaction.notes = activity.notes
            else:
                db.add(FinanceTransaction(
                    farm_id=existing.farm_id,
                    crop_id=existing.crop_id,
                    activity_id=existing.id,
                    transaction_type=activity.finance_type,
                    category=activity.activity_type,
                    amount=activity.finance_amount,
                    transaction_date=activity.activity_date,
                    notes=activity.notes,
                ))
        elif transaction:
            db.delete(transaction)
        db.commit()
        
        # Update images if provided
        image_urls = getattr(activity, 'image_urls', None)
        saved_urls = []
        if image_urls is not None:
            # Delete existing photos
            db.query(ActivityPhoto).filter(ActivityPhoto.activity_id == existing.id).delete()
            # Add new photos
            for url in image_urls:
                p = ActivityPhoto(activity_id=existing.id, image_url=url)
                db.add(p)
                saved_urls.append(url)
            db.commit()
        else:
            # Keep existing photos if not updating
            photos = db.query(ActivityPhoto).filter(ActivityPhoto.activity_id == existing.id).all()
            saved_urls = [p.image_url for p in photos]
        
        resp = {
            'id': existing.id,
            'farm_id': existing.farm_id,
            'crop_id': existing.crop_id,
            'user_id': existing.user_id,
            'activity_type': existing.activity_type,
            'activity_date': existing.activity_date,
            'notes': existing.notes,
            'input_id': existing.input_id,
            'quantity_used': existing.quantity_used,
            'finance_type': existing.finance_type,
            'finance_amount': existing.finance_amount,
            'created_at': existing.created_at,
            'image_urls': saved_urls,
        }
        return resp
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{activity_id}")
def delete_activity(activity_id: int, db: Session = Depends(get_db)):
    try:
        # Find existing activity
        existing = db.query(Activity).filter(Activity.id == activity_id).first()
        if not existing:
            raise HTTPException(status_code=404, detail="Activity not found")
        
        # Delete associated photos
        db.query(ActivityPhoto).filter(ActivityPhoto.activity_id == existing.id).delete()

        db.query(FinanceTransaction).filter(
            FinanceTransaction.activity_id == existing.id
        ).delete(synchronize_session=False)
        
        # Delete activity
        db.delete(existing)
        db.commit()
        
        return {"message": "Activity deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
