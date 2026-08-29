"""
Generic pagination schema and utilities for REST APIs.
Supports both offset-based and cursor-based pagination.
"""

from pydantic import BaseModel, Field
from typing import TypeVar, Generic, List, Optional
from sqlalchemy.orm import Query

T = TypeVar('T')

class PaginationParams(BaseModel):
    """Standard pagination parameters"""
    page: int = Field(1, ge=1, description="Page number (1-indexed)")
    limit: int = Field(20, ge=1, le=100, description="Items per page")
    sort_by: Optional[str] = Field("created_at", description="Sort field")
    sort_order: Optional[str] = Field("desc", pattern="^(asc|desc)$", description="Sort order")


class PaginatedResponse(BaseModel, Generic[T]):
    """Generic paginated response wrapper"""
    items: List[T]
    total: int = Field(..., description="Total number of items")
    page: int = Field(..., description="Current page number")
    limit: int = Field(..., description="Items per page")
    total_pages: int = Field(..., description="Total number of pages")
    has_next: bool = Field(..., description="Whether there's a next page")
    has_previous: bool = Field(..., description="Whether there's a previous page")


def paginate_query(
    query: Query,
    page: int = 1,
    limit: int = 20,
    sort_field=None,
    sort_order: str = "desc"
) -> tuple:
    """
    Apply pagination to a SQLAlchemy query.
    
    Returns:
        tuple: (paginated_items, total_count, total_pages, has_next, has_previous)
    """
    # Get total count before pagination
    total = query.count()
    
    # Apply sorting if specified
    if sort_field is not None:
        if sort_order.lower() == "desc":
            query = query.order_by(sort_field.desc())
        else:
            query = query.order_by(sort_field.asc())
    
    # Calculate pagination
    total_pages = (total + limit - 1) // limit  # Ceiling division
    offset = (page - 1) * limit
    
    # Apply pagination
    items = query.offset(offset).limit(limit).all()
    
    # Calculate flags
    has_next = page < total_pages
    has_previous = page > 1
    
    return items, total, total_pages, has_next, has_previous
