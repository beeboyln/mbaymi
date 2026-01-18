from sqlalchemy.orm import Session
from app.models.farm import Crop
from datetime import datetime
from typing import Optional, List


class CropService:
    @staticmethod
    def create_crop(db: Session, farm_id: int, data: dict) -> Crop:
        crop = Crop(
            farm_id=farm_id,
            crop_name=data.get("crop_name"),
            planted_date=data.get("planted_date"),
            expected_harvest_date=data.get("expected_harvest_date"),
            quantity_planted=data.get("quantity_planted"),
            expected_yield=data.get("expected_yield"),
            variety=data.get("variety"),
            cycle_duration_days=data.get("cycle_duration_days"),
            objective=data.get("objective", "consumption"),
            status=data.get("status", "growing"),
            notes=data.get("notes"),
            image_url=data.get("image_url"),
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(crop)
        db.commit()
        db.refresh(crop)
        return crop

    @staticmethod
    def get_crop(db: Session, crop_id: int) -> Optional[Crop]:
        return db.query(Crop).filter(Crop.id == crop_id).first()

    @staticmethod
    def list_crops_for_farm(db: Session, farm_id: int, skip: int = 0, limit: int = 100) -> List[Crop]:
        return db.query(Crop).filter(Crop.farm_id == farm_id).offset(skip).limit(limit).all()

    @staticmethod
    def update_crop(db: Session, crop_id: int, updates: dict) -> Optional[Crop]:
        crop = db.query(Crop).filter(Crop.id == crop_id).first()
        if not crop:
            return None
        for k, v in updates.items():
            if hasattr(crop, k):
                setattr(crop, k, v)
        crop.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(crop)
        return crop

    @staticmethod
    def delete_crop(db: Session, crop_id: int) -> bool:
        crop = db.query(Crop).filter(Crop.id == crop_id).first()
        if not crop:
            return False
        db.delete(crop)
        db.commit()
        return True
