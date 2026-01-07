from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.advice_service import AdviceService
from app.schemas.schemas import AdviceRequest, AdviceResponse

router = APIRouter(prefix="/api/advice", tags=["advice"])

@router.post("/", response_model=AdviceResponse)
def get_advice(request: AdviceRequest, db: Session = Depends(get_db)):
    advice_service = AdviceService()
    
    if request.type == "crop":
        return advice_service.get_crop_advice(request.topic, request.region)
    elif request.type == "livestock":
        return advice_service.get_livestock_advice(request.topic, request.region)
    else:
        return {"title": "Unknown type", "advice": "Please specify crop or livestock"}
