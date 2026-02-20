from pydantic import BaseModel, EmailStr, field_validator
from datetime import datetime
from typing import Optional
from typing import List
import json

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
    access_token: str
    refresh_token: str
    message: str

# Farm Schemas
class CropCreate(BaseModel):
    crop_name: str
    planted_date: Optional[datetime] = None
    expected_harvest_date: Optional[datetime] = None
    quantity_planted: Optional[float] = None
    expected_yield: Optional[float] = None
    variety: Optional[str] = None
    cycle_duration_days: Optional[int] = None
    objective: str = "consumption"
    status: str = "growing"
    notes: Optional[str] = None
    area: Optional[float] = None  # Surface en m² ou hectares
    coordinates: Optional[List[List[float]]] = None  # [[lat, lon], [lat, lon], ...]

class CropResponse(CropCreate):
    id: int
    farm_id: int
    created_at: datetime
    image_url: Optional[str] = None
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
    image_url: Optional[str] = None
    visibility: str = "PRIVATE"

class LivestockResponse(LivestockCreate):
    id: int
    user_id: int
    last_vaccination_date: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Animal Photo Schemas
class AnimalPhotoCreate(BaseModel):
    livestock_id: int
    image_url: str
    caption: Optional[str] = None

class AnimalPhotoResponse(AnimalPhotoCreate):
    id: int
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
    destination: Optional[str] = None  # sold / stored / consumed
    sale_price: Optional[float] = None

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
    unit: Optional[str] = "kg"
    price_per_unit: float
    currency: Optional[str] = "CFA"
    image_url: Optional[str] = None
    additional_images: Optional[list] = None
    category: Optional[str] = None
    delivery_location: Optional[str] = None
    contact: Optional[str] = None
    description: Optional[str] = None
    user_id: Optional[int] = None

class SaleResponse(SaleCreate):
    id: int
    created_at: datetime
    
    @field_validator('additional_images', mode='before')
    @classmethod
    def parse_additional_images(cls, v):
        """Parse JSON string to list if needed"""
        if isinstance(v, str):
            try:
                return json.loads(v)
            except (json.JSONDecodeError, TypeError):
                return []
        return v or []

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

# Pasture Image Schemas
class PastureImageCreate(BaseModel):
    image_url: str
    title: Optional[str] = None
    description: Optional[str] = None

class PastureImageResponse(PastureImageCreate):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class FarmPostCreate(BaseModel):
    farm_id: Optional[int] = None
    livestock_id: Optional[int] = None
    image_url: str
    caption: Optional[str] = None
    post_intent: str = "share"  # "sell" ou "share"
    price: Optional[float] = None  # Prix si vente
    product_name: Optional[str] = None  # Produit vendu
    unit: str = "kg"  # Unité de mesure


# Input (Intrants) Schemas
class InputCreate(BaseModel):
    farm_id: int
    crop_id: Optional[int] = None
    input_type: Optional[str] = None
    name: Optional[str] = None
    quantity: Optional[float] = None
    unit: Optional[str] = None
    applied_date: Optional[datetime] = None
    cost: Optional[float] = None
    notes: Optional[str] = None

class InputResponse(InputCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# Finance Schemas
class FinanceTransactionCreate(BaseModel):
    farm_id: int
    crop_id: Optional[int] = None
    transaction_type: str  # expense / income
    category: Optional[str] = None
    amount: float
    transaction_date: Optional[datetime] = None
    notes: Optional[str] = None

class FinanceTransactionResponse(FinanceTransactionCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# Reminder Schemas
class ReminderCreate(BaseModel):
    farm_id: int
    crop_id: Optional[int] = None
    title: str
    description: Optional[str] = None
    remind_at: datetime
    repeat_rule: Optional[str] = None

class ReminderResponse(ReminderCreate):
    id: int
    is_done: bool
    created_at: datetime

    class Config:
        from_attributes = True