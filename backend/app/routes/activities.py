from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.activity import Activity
from app.models.photo import ActivityPhoto
from app.models.farm import Farm
from app.schemas.schemas import ActivityCreate, ActivityResponse

router = APIRouter(prefix="/api/activities", tags=["activities"])

@router.post("/", response_model=ActivityResponse)
def create_activity(activity: ActivityCreate, db: Session = Depends(get_db)):
    try:
        # Ensure farm exists
        farm = db.query(Farm).filter(Farm.id == activity.farm_id).first()
        if not farm:
            raise HTTPException(status_code=404, detail="Farm not found")

        new_activity = Activity(
            farm_id=activity.farm_id,
            crop_id=activity.crop_id,
            user_id=activity.user_id,
            activity_type=activity.activity_type,
            activity_date=activity.activity_date,
            notes=activity.notes,
        )

        db.add(new_activity)
        db.commit()
        db.refresh(new_activity)

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
        
        db.commit()
        db.refresh(existing)
        
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
        
        # Delete activity
        db.delete(existing)
        db.commit()
        
        return {"message": "Activity deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
