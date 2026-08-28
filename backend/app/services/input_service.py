from sqlalchemy.orm import Session
from app.models.input import Input
from datetime import datetime
from typing import Optional, List


class InputService:
    @staticmethod
    def create_input(db: Session, data: dict) -> Input:
        i = Input(
            farm_id=data.get("farm_id"),
            crop_id=data.get("crop_id"),
            input_type=data.get("input_type"),
            name=data.get("name"),
            quantity=data.get("quantity"),
            unit=data.get("unit"),
            applied_date=data.get("applied_date", datetime.utcnow()),
            cost=data.get("cost"),
            notes=data.get("notes"),
            created_at=datetime.utcnow(),
        )
        db.add(i)
        db.commit()
        db.refresh(i)
        return i

    @staticmethod
    def get_input(db: Session, input_id: int) -> Optional[Input]:
        return db.query(Input).filter(Input.id == input_id).first()

    @staticmethod
    def list_inputs_for_farm(db: Session, farm_id: int, skip: int = 0, limit: int = 100) -> List[Input]:
        return db.query(Input).filter(Input.farm_id == farm_id).order_by(Input.applied_date.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def list_inputs_for_crop(db: Session, crop_id: int, skip: int = 0, limit: int = 100) -> List[Input]:
        return db.query(Input).filter(Input.crop_id == crop_id).order_by(Input.applied_date.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def update_input(db: Session, input_id: int, updates: dict) -> Optional[Input]:
        i = db.query(Input).filter(Input.id == input_id).first()
        if not i:
            return None
        for k, v in updates.items():
            if hasattr(i, k):
                setattr(i, k, v)
        db.commit()
        db.refresh(i)
        return i

    @staticmethod
    def delete_input(db: Session, input_id: int) -> bool:
        i = db.query(Input).filter(Input.id == input_id).first()
        if not i:
            return False
        db.delete(i)
        db.commit()
        return True
