from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.sale import Sale
from app.models.finance import FinanceTransaction
from app.models.farm import Farm, Crop
from app.schemas.schemas import SaleCreate, SaleResponse
from app.schemas.pagination import paginate_query, PaginatedResponse
from typing import Optional

SALE_NOT_FOUND = "Sale not found"

router = APIRouter(prefix="/api/sales", tags=["sales"])

@router.post("/", response_model=SaleResponse)
def create_sale(s: SaleCreate, db: Session = Depends(get_db)):
    if s.crop_id is not None:
        crop = db.query(Crop).filter(Crop.id == s.crop_id).first()
        if not crop or (s.farm_id is not None and crop.farm_id != s.farm_id):
            raise HTTPException(status_code=400, detail="Crop does not belong to this farm")
        farm_id = crop.farm_id
    else:
        farm_id = s.farm_id
    if farm_id is not None and not db.query(Farm).filter(Farm.id == farm_id).first():
        raise HTTPException(status_code=400, detail="Farm not found")

    new_sale = Sale(
        harvest_id=s.harvest_id,
        farm_id=farm_id,
        crop_id=s.crop_id,
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
    db.flush()

    if farm_id is not None and s.crop_id is not None:
        db.add(FinanceTransaction(
            farm_id=farm_id,
            crop_id=s.crop_id,
            sale_id=new_sale.id,
            transaction_type='income',
            category=f'Vente - {s.product_name}',
            amount=s.quantity * s.price_per_unit,
            notes=s.description,
            transaction_date=new_sale.created_at,
        ))
        db.commit()
    else:
        db.commit()

    return new_sale

@router.get("/user/{user_id}")
def get_sales_by_user(
    user_id: int,
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    category: Optional[str] = Query(None),
):
    """Get paginated sales for a specific user with optional category filtering"""
    query = db.query(Sale).filter(Sale.user_id == user_id)
    
    # Apply category filter if provided
    if category and category != "Tous":
        query = query.filter(Sale.category == category)
    
    items, total, total_pages, has_next, has_previous = paginate_query(
        query, page, limit, Sale.created_at, "desc"
    )
    
    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": total_pages,
        "has_next": has_next,
        "has_previous": has_previous,
    }


@router.get("/")
def get_all_sales(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    category: Optional[str] = Query(None),
    location: Optional[str] = Query(None),
):
    """Récupérer les ventes récentes avec pagination et filtres (accessible à tous)"""
    query = db.query(Sale)
    
    # Apply category filter
    if category and category != "Tous":
        query = query.filter(Sale.category == category)
    
    # Apply location filter
    if location and location != "Tous":
        query = query.filter(Sale.delivery_location == location)
    
    items, total, total_pages, has_next, has_previous = paginate_query(
        query, page, limit, Sale.created_at, "desc"
    )
    
    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": total_pages,
        "has_next": has_next,
        "has_previous": has_previous,
    }


@router.get("/{sale_id}", response_model=SaleResponse)
def get_sale(sale_id: int, db: Session = Depends(get_db)):
    sale = db.query(Sale).filter(Sale.id == sale_id).first()
    if not sale:
        raise HTTPException(status_code=404, detail=SALE_NOT_FOUND)
    return sale

@router.get("/harvest/{harvest_id}")
def get_sales_for_harvest(
    harvest_id: int,
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    """Get paginated sales for a specific harvest"""
    query = db.query(Sale).filter(Sale.harvest_id == harvest_id)
    
    items, total, total_pages, has_next, has_previous = paginate_query(
        query, page, limit, Sale.created_at, "desc"
    )
    
    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": total_pages,
        "has_next": has_next,
        "has_previous": has_previous,
    }

@router.put("/{sale_id}", response_model=SaleResponse)
def update_sale(sale_id: int, s: SaleCreate, db: Session = Depends(get_db)):
    sale = db.query(Sale).filter(Sale.id == sale_id).first()
    
    if not sale:
        raise HTTPException(status_code=404, detail=SALE_NOT_FOUND)

    if s.crop_id is not None:
        crop = db.query(Crop).filter(Crop.id == s.crop_id).first()
        if not crop or (s.farm_id is not None and crop.farm_id != s.farm_id):
            raise HTTPException(status_code=400, detail="Crop does not belong to this farm")
    
    sale.product_name = s.product_name
    sale.farm_id = s.farm_id
    sale.crop_id = s.crop_id
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

    transaction = db.query(FinanceTransaction).filter(
        FinanceTransaction.sale_id == sale.id
    ).first()
    if transaction:
        transaction.farm_id = s.farm_id or sale.farm_id
        transaction.category = f'Vente - {s.product_name}'
        transaction.amount = s.quantity * s.price_per_unit
        transaction.notes = s.description
        transaction.crop_id = s.crop_id
    elif sale.farm_id is not None and sale.crop_id is not None:
        db.add(FinanceTransaction(
            farm_id=sale.farm_id,
            crop_id=sale.crop_id,
            sale_id=sale.id,
            transaction_type='income',
            category=f'Vente - {s.product_name}',
            amount=s.quantity * s.price_per_unit,
            notes=s.description,
            transaction_date=sale.created_at,
        ))
    
    db.commit()
    db.refresh(sale)
    
    return sale

@router.delete("/{sale_id}")
def delete_sale(sale_id: int, db: Session = Depends(get_db)):
    sale = db.query(Sale).filter(Sale.id == sale_id).first()
    
    if not sale:
        raise HTTPException(status_code=404, detail=SALE_NOT_FOUND)
    
    db.query(FinanceTransaction).filter(FinanceTransaction.sale_id == sale.id).delete()
    db.delete(sale)
    db.commit()
    
    return {"message": "Sale deleted successfully"}