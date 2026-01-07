from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.market import MarketPrice
from app.schemas.schemas import MarketPriceResponse

router = APIRouter(prefix="/api/market", tags=["market"])

@router.get("/prices")
def get_all_prices(db: Session = Depends(get_db)):
    prices = db.query(MarketPrice).order_by(MarketPrice.price_date.desc()).all()
    return prices

@router.get("/prices/region/{region}")
def get_prices_by_region(region: str, db: Session = Depends(get_db)):
    prices = db.query(MarketPrice).filter(
        MarketPrice.region == region
    ).order_by(MarketPrice.price_date.desc()).all()
    return prices

@router.get("/prices/{product}")
def get_product_prices(product: str, db: Session = Depends(get_db)):
    prices = db.query(MarketPrice).filter(
        MarketPrice.product_name.ilike(f"%{product}%")
    ).order_by(MarketPrice.price_date.desc()).all()
    return prices
