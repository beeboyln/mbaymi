from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc, func, text
from app.database import get_db
from app.models.farm_post import FarmImagePost
from app.models.market_trends import MarketTrend
from typing import Optional
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

router = APIRouter(prefix="/market-prices", tags=["market_prices"])


@router.get("/trends")
def get_market_trends(
    product: Optional[str] = None,
    region: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    📊 Récupérer les tendances de prix du marché
    - Optionnel: filtrer par produit et/ou région
    """
    try:
        query = db.query(MarketTrend)
        
        if product:
            query = query.filter(
                func.lower(MarketTrend.product_name).contains(func.lower(product))
            )
        
        if region:
            query = query.filter(
                func.lower(MarketTrend.region).contains(func.lower(region))
            )
        
        trends = query.order_by(desc(MarketTrend.updated_at)).all()
        
        return {
            "count": len(trends),
            "data": [t.to_dict() for t in trends]
        }
    except Exception as e:
        logger.error(f"Erreur récupération tendances: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")


@router.get("/trends/{product}")
def get_product_trends(
    product: str,
    region: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    📈 Récupérer les tendances pour un produit spécifique
    """
    try:
        query = db.query(MarketTrend).filter(
            func.lower(MarketTrend.product_name) == func.lower(product)
        )
        
        if region:
            query = query.filter(
                func.lower(MarketTrend.region) == func.lower(region)
            )
        
        trends = query.order_by(desc(MarketTrend.updated_at)).all()
        
        if not trends:
            raise HTTPException(
                status_code=404,
                detail=f"Aucune donnée de prix pour {product}"
            )
        
        return {
            "product": product,
            "region": region,
            "data": [t.to_dict() for t in trends]
        }
    except Exception as e:
        logger.error(f"Erreur: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")


@router.post("/recalculate")
def recalculate_trends(db: Session = Depends(get_db)):
    """
    🔄 Recalculer les tendances de prix à partir des posts avec prix
    """
    try:
        # Récupérer tous les posts avec prix
        posts_with_prices = db.query(
            FarmImagePost.product_name,
            FarmImagePost.unit,
            func.avg(FarmImagePost.price).label("avg_price"),
            func.min(FarmImagePost.price).label("min_price"),
            func.max(FarmImagePost.price).label("max_price"),
            func.count(FarmImagePost.id).label("count")
        ).filter(
            FarmImagePost.post_intent == "sell",
            FarmImagePost.price.isnot(None)
        ).group_by(
            FarmImagePost.product_name,
            FarmImagePost.unit
        ).all()
        
        updated_count = 0
        
        for post_data in posts_with_prices:
            product_name = post_data.product_name
            unit = post_data.unit
            avg_price = float(post_data.avg_price) if post_data.avg_price else 0
            min_price = float(post_data.min_price) if post_data.min_price else None
            max_price = float(post_data.max_price) if post_data.max_price else None
            count = post_data.count
            
            # Chercher ou créer le trend
            existing_trend = db.query(MarketTrend).filter(
                MarketTrend.product_name == product_name,
                MarketTrend.unit == unit,
                MarketTrend.region == None  # Global trends
            ).first()
            
            if existing_trend:
                existing_trend.avg_price = avg_price
                existing_trend.min_price = min_price
                existing_trend.max_price = max_price
                existing_trend.count = count
            else:
                new_trend = MarketTrend(
                    product_name=product_name,
                    unit=unit,
                    avg_price=avg_price,
                    min_price=min_price,
                    max_price=max_price,
                    count=count
                )
                db.add(new_trend)
            
            updated_count += 1
        
        db.commit()
        
        return {
            "message": "Tendances recalculées",
            "updated_count": updated_count
        }
    except Exception as e:
        db.rollback()
        logger.error(f"Erreur recalcul: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")


@router.get("/products")
def get_available_products(db: Session = Depends(get_db)):
    """
    📋 Récupérer la liste de tous les produits avec prix
    """
    try:
        products = db.query(
            func.distinct(FarmImagePost.product_name)
        ).filter(
            FarmImagePost.post_intent == "sell",
            FarmImagePost.product_name.isnot(None)
        ).all()
        
        product_list = [p[0] for p in products if p[0]]
        
        return {
            "count": len(product_list),
            "products": sorted(product_list)
        }
    except Exception as e:
        logger.error(f"Erreur: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")
