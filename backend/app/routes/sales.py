from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.sale import Sale
from app.schemas.schemas import SaleCreate, SaleResponse
from typing import Optional

SALE_NOT_FOUND = "Sale not found"

router = APIRouter(prefix="/api/sales", tags=["sales"])

@router.post("/", response_model=SaleResponse)
def create_sale(s: SaleCreate, db: Session = Depends(get_db)):
    new_sale = Sale(
        harvest_id=s.harvest_id,
        product_name=s.product_name,
        quantity=s.quantity,
        unit=s.unit,
        price_per_unit=s.price_per_unit,
        currency=s.currency,
        image_url=s.image_url,
        additional_images=s.additional_images,
        category=s.category,
        delivery_location=s.delivery_location,
        contact=s.contact,
        description=s.description,
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


@router.get("/")
def get_all_sales(limit: Optional[int] = 100, db: Session = Depends(get_db)):
    """Récupérer les ventes récentes (accessible à tous, connecté ou non)."""
    items = db.query(Sale).order_by(Sale.created_at.desc()).limit(limit).all()
    return items


@router.get("/{sale_id}", response_model=SaleResponse)
def get_sale(sale_id: int, db: Session = Depends(get_db)):
    sale = db.query(Sale).filter(Sale.id == sale_id).first()
    if not sale:
        raise HTTPException(status_code=404, detail=SALE_NOT_FOUND)
    return sale

@router.get("/harvest/{harvest_id}")
def get_sales_for_harvest(harvest_id: int, db: Session = Depends(get_db)):
    items = db.query(Sale).filter(Sale.harvest_id == harvest_id).order_by(Sale.created_at.desc()).all()
    return items

@router.put("/{sale_id}", response_model=SaleResponse)
def update_sale(sale_id: int, s: SaleCreate, db: Session = Depends(get_db)):
    sale = db.query(Sale).filter(Sale.id == sale_id).first()
    
    if not sale:
        raise HTTPException(status_code=404, detail=SALE_NOT_FOUND)
    
    sale.product_name = s.product_name
    sale.quantity = s.quantity
    sale.unit = s.unit
    sale.price_per_unit = s.price_per_unit
    sale.currency = s.currency
    sale.image_url = s.image_url
    sale.additional_images = s.additional_images
    sale.category = s.category
    sale.delivery_location = s.delivery_location
    sale.contact = s.contact
    sale.description = s.description
    
    db.commit()
    db.refresh(sale)
    
    return sale

@router.delete("/{sale_id}")
def delete_sale(sale_id: int, db: Session = Depends(get_db)):
    sale = db.query(Sale).filter(Sale.id == sale_id).first()
    
    if not sale:
        raise HTTPException(status_code=404, detail=SALE_NOT_FOUND)
    
    db.delete(sale)
    db.commit()
    
    return {"message": "Sale deleted successfully"}