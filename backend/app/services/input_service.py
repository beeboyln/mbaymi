from sqlalchemy.orm import Session
from app.models.input import Input
from app.models.finance import FinanceTransaction
from datetime import datetime
from typing import Optional, List


class InputService:
    _finance_marker = '[MBAYMI_INPUT:{input_id}]'

    @classmethod
    def _find_finance_transaction(cls, db: Session, input_id: int) -> Optional[FinanceTransaction]:
        marker = cls._finance_marker.format(input_id=input_id)
        return db.query(FinanceTransaction).filter(
            (FinanceTransaction.input_id == input_id) |
            FinanceTransaction.notes.like(f'{marker}%')
        ).first()

    @staticmethod
    def create_input(db: Session, data: dict) -> Input:
        i = Input(
            farm_id=data.get("farm_id"),
            crop_id=data.get("crop_id"),
            input_type=data.get("input_type"),
            name=data.get("name"),
            quantity=data.get("quantity"),
            reorder_threshold=data.get("reorder_threshold") or (
                data.get("quantity") * 0.2 if data.get("quantity") else 0
            ),
            unit=data.get("unit"),
            applied_date=data.get("applied_date", datetime.utcnow()),
            cost=data.get("cost"),
            notes=data.get("notes"),
            created_at=datetime.utcnow(),
        )
        db.add(i)
        db.flush()
        if i.cost is not None and i.cost > 0:
            db.add(FinanceTransaction(
                farm_id=i.farm_id,
                crop_id=i.crop_id,
                transaction_type='expense',
                category=i.input_type or 'Intrant',
                amount=i.cost,
                input_id=i.id,
                transaction_date=i.applied_date,
                notes=i.notes,
                created_at=datetime.utcnow(),
            ))
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
            if hasattr(i, k) and not (k == "reorder_threshold" and v is None):
                setattr(i, k, v)
        transaction = InputService._find_finance_transaction(db, input_id)
        if transaction:
            transaction.input_id = i.id
            if i.cost is None or i.cost <= 0:
                db.delete(transaction)
            else:
                transaction.amount = i.cost
                transaction.category = i.input_type or 'Intrant'
                transaction.crop_id = i.crop_id
                transaction.transaction_date = i.applied_date
                transaction.notes = i.notes
        elif i.cost is not None and i.cost > 0:
            db.add(FinanceTransaction(
                farm_id=i.farm_id,
                crop_id=i.crop_id,
                transaction_type='expense',
                category=i.input_type or 'Intrant',
                amount=i.cost,
                input_id=i.id,
                transaction_date=i.applied_date,
                notes=i.notes,
                created_at=datetime.utcnow(),
            ))
        db.commit()
        db.refresh(i)
        return i

    @staticmethod
    def delete_input(db: Session, input_id: int) -> bool:
        i = db.query(Input).filter(Input.id == input_id).first()
        if not i:
            return False
        transaction = InputService._find_finance_transaction(db, input_id)
        if transaction:
            db.delete(transaction)
        db.delete(i)
        db.commit()
        return True
