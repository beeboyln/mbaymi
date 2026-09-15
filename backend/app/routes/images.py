from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile

from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/images", tags=["images"])
IMAGE_DIR = Path("uploads") / "images"
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}


@router.post("/upload")
async def upload_image(
    request: Request,
    image: UploadFile = File(...),
    current_user: int = Depends(get_current_user),
):
    if image.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=415, detail="Format d'image non pris en charge.")

    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    suffix = Path(image.filename or "image").suffix.lower() or ".jpg"
    filename = f"{current_user}_{uuid4().hex}{suffix}"
    destination = IMAGE_DIR / filename
    destination.write_bytes(await image.read())

    return {"url": f"{str(request.base_url).rstrip('/')}/uploads/images/{filename}"}