from sqlalchemy.orm import Session
from app.models.finance import FinanceTransaction
from datetime import datetime
from typing import Optional, List, Dict


class FinanceService:
    @staticmethod
    def create_transaction(db: Session, data: dict) -> FinanceTransaction:
        t = FinanceTransaction(
            farm_id=data.get("farm_id"),
            crop_id=data.get("crop_id"),
            transaction_type=data.get("transaction_type"),
            category=data.get("category"),
            amount=data.get("amount"),
            transaction_date=data.get("transaction_date", datetime.utcnow()),
            notes=data.get("notes"),
            created_at=datetime.utcnow(),
        )
        db.add(t)
        db.commit()
        db.refresh(t)
        return t

    @staticmethod
    def get_transaction(db: Session, transaction_id: int) -> Optional[FinanceTransaction]:
        return db.query(FinanceTransaction).filter(FinanceTransaction.id == transaction_id).first()

    @staticmethod
    def list_transactions_for_farm(db: Session, farm_id: int, skip: int = 0, limit: int = 100) -> List[FinanceTransaction]:
        return db.query(FinanceTransaction).filter(FinanceTransaction.farm_id == farm_id).order_by(FinanceTransaction.transaction_date.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def list_transactions_for_crop(db: Session, crop_id: int, skip: int = 0, limit: int = 100) -> List[FinanceTransaction]:
        return db.query(FinanceTransaction).filter(FinanceTransaction.crop_id == crop_id).order_by(FinanceTransaction.transaction_date.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def update_transaction(db: Session, transaction_id: int, updates: dict) -> Optional[FinanceTransaction]:
        t = db.query(FinanceTransaction).filter(FinanceTransaction.id == transaction_id).first()
        if not t:
            return None
        for k, v in updates.items():
            if hasattr(t, k):
                setattr(t, k, v)
        db.commit()
        db.refresh(t)
        return t

    @staticmethod
    def delete_transaction(db: Session, transaction_id: int) -> bool:
        t = db.query(FinanceTransaction).filter(FinanceTransaction.id == transaction_id).first()
        if not t:
            return False
        db.delete(t)
        db.commit()
        return True

    @staticmethod
    def summary_for_farm(db: Session, farm_id: int) -> Dict[str, float]:
        """Retourne totals: total_expenses, total_income, net_profit"""
        expenses = db.query(FinanceTransaction).filter(FinanceTransaction.farm_id == farm_id, FinanceTransaction.transaction_type == 'expense').all()
        incomes = db.query(FinanceTransaction).filter(FinanceTransaction.farm_id == farm_id, FinanceTransaction.transaction_type == 'income').all()
        total_expenses = sum([e.amount for e in expenses]) if expenses else 0.0
        total_income = sum([i.amount for i in incomes]) if incomes else 0.0
        return {"total_expenses": total_expenses, "total_income": total_income, "net_profit": total_income - total_expenses}

    @staticmethod
    def summary_for_crop(db: Session, crop_id: int) -> Dict[str, float]:
        transactions = db.query(FinanceTransaction).filter(FinanceTransaction.crop_id == crop_id).all()
        total_expenses = sum(t.amount for t in transactions if t.transaction_type == 'expense')
        total_income = sum(t.amount for t in transactions if t.transaction_type == 'income')
        return {"total_expenses": total_expenses, "total_income": total_income, "net_profit": total_income - total_expenses}
