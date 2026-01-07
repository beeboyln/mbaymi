from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.sale import Sale
from app.schemas.schemas import SaleCreate, SaleResponse

router = APIRouter(prefix="/api/sales", tags=["sales"])

@router.post("/", response_model=SaleResponse)
def create_sale(s: SaleCreate, db: Session = Depends(get_db)):
    new_sale = Sale(
        harvest_id=s.harvest_id,
        product_name=s.product_name,
        quantity=s.quantity,
        price_per_unit=s.price_per_unit,
        currency=s.currency,
        delivery_location=s.delivery_location,
        contact=s.contact,
        user_id=s.user_id,
    )

    db.add(new_sale)
    db.commit()
    db.refresh(new_sale)

    return new_sale

@router.get("/user/{user_id}")
def get_sales_by_user(user_id: int, db: Session = Depends(get_db)):
    items = db.query(Sale).filter(Sale.user_id == user_id).order_by(Sale.created_at.desc()).all()
    return items

@router.get("/harvest/{harvest_id}")
def get_sales_for_harvest(harvest_id: int, db: Session = Depends(get_db)):
    items = db.query(Sale).filter(Sale.harvest_id == harvest_id).order_by(Sale.created_at.desc()).all()
    return items
