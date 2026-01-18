from sqlalchemy.orm import Session
from app.models.harvest import Harvest
from datetime import datetime
from typing import Optional, List


class HarvestService:
    @staticmethod
    def create_harvest(db: Session, data: dict) -> Harvest:
        h = Harvest(
            farm_id=data.get("farm_id"),
            crop_id=data.get("crop_id"),
            estimated_quantity=data.get("estimated_quantity"),
            actual_quantity=data.get("actual_quantity"),
            harvest_date=data.get("harvest_date", datetime.utcnow()),
            notes=data.get("notes"),
            destination=data.get("destination"),
            sale_price=data.get("sale_price"),
            created_at=datetime.utcnow(),
        )
        db.add(h)
        db.commit()
        db.refresh(h)
        return h

    @staticmethod
    def get_harvest(db: Session, harvest_id: int) -> Optional[Harvest]:
        return db.query(Harvest).filter(Harvest.id == harvest_id).first()

    @staticmethod
    def list_harvests_for_farm(db: Session, farm_id: int, skip: int = 0, limit: int = 100) -> List[Harvest]:
        return db.query(Harvest).filter(Harvest.farm_id == farm_id).order_by(Harvest.harvest_date.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def update_harvest(db: Session, harvest_id: int, updates: dict) -> Optional[Harvest]:
        h = db.query(Harvest).filter(Harvest.id == harvest_id).first()
        if not h:
            return None
        for k, v in updates.items():
            if hasattr(h, k):
                setattr(h, k, v)
        db.commit()
        db.refresh(h)
        return h

    @staticmethod
    def delete_harvest(db: Session, harvest_id: int) -> bool:
        h = db.query(Harvest).filter(Harvest.id == harvest_id).first()
        if not h:
            return False
        db.delete(h)
        db.commit()
        return True
