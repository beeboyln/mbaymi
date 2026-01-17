from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.advice_service import AdviceService
from app.schemas.schemas import AdviceRequest, AdviceResponse

router = APIRouter(prefix="/api/advice", tags=["advice"])

@router.post("/", response_model=AdviceResponse)
def get_advice(request: AdviceRequest, db: Session = Depends(get_db)):
    advice_service = AdviceService()
    # Basic validation: topic must be provided
    if not request.topic or not request.topic.strip():
        raise HTTPException(status_code=400, detail="Missing 'topic' in request")

    try:
        if request.type == "crop":
            return advice_service.get_crop_advice(request.topic, request.region)
        elif request.type == "livestock":
            return advice_service.get_livestock_advice(request.topic, request.region)
        else:
            raise HTTPException(status_code=400, detail="Unknown type; use 'crop' or 'livestock'")
    except HTTPException:
        raise
    except Exception as e:
        # Unexpected error -> return 500 with detail
        raise HTTPException(status_code=500, detail=str(e))
