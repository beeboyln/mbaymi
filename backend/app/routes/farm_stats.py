"""
Aggregation endpoint for farm statistics.
Provides efficient summary data for dashboards and summaries.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models.farm import Farm, Crop
from app.models.livestock import Livestock
from app.models.sale import Sale
from app.models.finance import FinanceTransaction
from datetime import datetime, timedelta
from typing import Optional

router = APIRouter(prefix="/api/farms", tags=["farms-stats"])

@router.get("/{farm_id}/stats")
def get_farm_stats(farm_id: int, db: Session = Depends(get_db)):
    """
    Get aggregated statistics for a farm.
    
    Returns:
    - parcel_count: number of active crops/parcels
    - livestock_count: total livestock quantity
    - total_revenue: sum of sales amounts (last 30 days)
    - total_expenses: sum of expenses (last 30 days)
    - net_income: revenue - expenses
    - market_posts_count: number of sales listings
    - average_parcel_size: average size in hectares
    """
    
    # Check if farm exists
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    # Count active parcels (crops)
    parcel_count = db.query(func.count(Crop.id)).filter(
        Crop.farm_id == farm_id,
        Crop.deleted_at == None
    ).scalar() or 0
    
    # Count livestock
    livestock_count = db.query(func.sum(Livestock.quantity)).filter(
        Livestock.user_id == farm.user_id,
        Livestock.deleted_at == None
    ).scalar() or 0
    
    # Calculate revenue from sales (last 30 days)
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    total_revenue = db.query(func.sum(
        Sale.quantity * Sale.price_per_unit
    )).filter(
        Sale.user_id == farm.user_id,
        Sale.created_at >= thirty_days_ago
    ).scalar() or 0
    
    # Calculate expenses from finance transactions (last 30 days)
    total_expenses = db.query(func.sum(FinanceTransaction.amount)).filter(
        FinanceTransaction.transaction_type == 'EXPENSE',
        FinanceTransaction.farm_id == farm_id,
        FinanceTransaction.created_at >= thirty_days_ago
    ).scalar() or 0
    
    # Count market posts
    market_posts_count = db.query(func.count(Sale.id)).filter(
        Sale.user_id == farm.user_id
    ).scalar() or 0
    
    # Calculate average parcel size
    avg_parcel_size = db.query(func.avg(Crop.size_hectares)).filter(
        Crop.farm_id == farm_id,
        Crop.deleted_at == None
    ).scalar() or 0
    
    # Calculate net income
    net_income = float(total_revenue) - float(total_expenses)
    
    return {
        "farm_id": farm_id,
        "parcel_count": parcel_count,
        "livestock_count": int(livestock_count or 0),
        "total_revenue": float(total_revenue),
        "total_expenses": float(total_expenses),
        "net_income": net_income,
        "market_posts_count": market_posts_count,
        "average_parcel_size": float(avg_parcel_size) if avg_parcel_size else 0,
        "period": "30_days",
        "updated_at": datetime.utcnow().isoformat(),
    }


@router.get("/{farm_id}/financial-summary")
def get_farm_financial_summary(
    farm_id: int,
    db: Session = Depends(get_db),
    days: int = 30,
):
    """
    Get detailed financial summary for a farm.
    
    Returns:
    - revenue_by_category: breakdown of revenue by product category
    - expenses_by_type: breakdown of expenses by transaction type
    - top_products: best selling products
    """
    
    # Check if farm exists
    farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    date_filter = datetime.utcnow() - timedelta(days=days)
    
    # Revenue by category
    revenue_by_category = db.query(
        Sale.category,
        func.sum(Sale.quantity * Sale.price_per_unit).label('total')
    ).filter(
        Sale.user_id == farm.user_id,
        Sale.created_at >= date_filter
    ).group_by(Sale.category).all()
    
    revenue_dict = {
        row[0]: float(row[1]) if row[1] else 0
        for row in revenue_by_category
    }
    
    # Top products
    top_products = db.query(
        Sale.product_name,
        func.sum(Sale.quantity).label('qty'),
        func.sum(Sale.quantity * Sale.price_per_unit).label('revenue')
    ).filter(
        Sale.user_id == farm.user_id,
        Sale.created_at >= date_filter
    ).group_by(Sale.product_name).order_by(
        func.sum(Sale.quantity * Sale.price_per_unit).desc()
    ).limit(5).all()
    
    top_products_list = [
        {
            "product": row[0],
            "quantity": float(row[1] or 0),
            "revenue": float(row[2] or 0)
        }
        for row in top_products
    ]
    
    return {
        "farm_id": farm_id,
        "period_days": days,
        "revenue_by_category": revenue_dict,
        "top_products": top_products_list,
        "updated_at": datetime.utcnow().isoformat(),
    }
