from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional
from typing import List

# User Schemas
class UserCreate(BaseModel):
    name: str
    email: EmailStr
    phone: str
    password: str
    role: str  # farmer, livestock_breeder, buyer, seller
    region: str
    village: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    phone: str
    role: str
    region: str
    village: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserLoginResponse(BaseModel):
    id: int
    email: str
    name: str
    role: str
    token: Optional[str] = None
    message: str

# Farm Schemas
class CropCreate(BaseModel):
    crop_name: str
    planted_date: Optional[datetime] = None
    expected_harvest_date: Optional[datetime] = None
    quantity_planted: Optional[float] = None
    expected_yield: Optional[float] = None
    status: str = "growing"
    notes: Optional[str] = None

class CropResponse(CropCreate):
    id: int
    farm_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class FarmCreate(BaseModel):
    name: str
    location: str
    size_hectares: Optional[float] = None
    soil_type: Optional[str] = None
    image_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class FarmResponse(FarmCreate):
    id: int
    user_id: int
    created_at: datetime
    # photos can be provided separately under a photos endpoint
    photos: Optional[List[str]] = None
    
    class Config:
        from_attributes = True

# Livestock Schemas
class LivestockCreate(BaseModel):
    animal_type: str
    breed: Optional[str] = None
    quantity: int = 1
    age_months: Optional[int] = None
    weight_kg: Optional[float] = None
    health_status: str = "healthy"
    feeding_type: Optional[str] = None
    location: Optional[str] = None
    notes: Optional[str] = None

class LivestockResponse(LivestockCreate):
    id: int
    user_id: int
    last_vaccination_date: Optional[datetime]
    created_at: datetime
    
    class Config:
        from_attributes = True

# Market Schemas
class MarketPriceResponse(BaseModel):
    id: int
    product_name: str
    region: str
    price_per_kg: float
    currency: str
    price_date: datetime
    source: Optional[str]
    
    class Config:
        from_attributes = True

# Activity Schemas
class ActivityCreate(BaseModel):
    farm_id: int
    crop_id: Optional[int] = None
    user_id: Optional[int] = None
    activity_type: str
    activity_date: Optional[datetime] = None
    notes: Optional[str] = None
    image_urls: Optional[List[str]] = None

class ActivityResponse(ActivityCreate):
    id: int
    created_at: datetime
    image_urls: Optional[List[str]] = None

    class Config:
        from_attributes = True

# Harvest Schemas
class HarvestCreate(BaseModel):
    farm_id: int
    crop_id: Optional[int] = None
    estimated_quantity: Optional[float] = None
    actual_quantity: Optional[float] = None
    harvest_date: Optional[datetime] = None
    notes: Optional[str] = None

class HarvestResponse(HarvestCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

# Sale Schemas
class SaleCreate(BaseModel):
    harvest_id: Optional[int] = None
    product_name: str
    quantity: float
    price_per_unit: float
    currency: Optional[str] = "CFA"
    delivery_location: Optional[str] = None
    contact: Optional[str] = None
    user_id: Optional[int] = None

class SaleResponse(SaleCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

# Advice Schema
class AdviceRequest(BaseModel):
    type: str  # "crop" or "livestock"
    topic: str  # crop_name, animal_type, etc.
    region: Optional[str] = None
    context: Optional[str] = None

class AdviceResponse(BaseModel):
    title: str
    advice: str
    tips: list[str]
    warnings: Optional[list[str]] = None
