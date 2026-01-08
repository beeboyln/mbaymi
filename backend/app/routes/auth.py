from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.schemas.schemas import UserCreate, UserResponse, UserLogin, UserLoginResponse
from passlib.context import CryptContext
from app.services.jwt_service import create_access_token, create_refresh_token, verify_token

router = APIRouter(prefix="/api/auth", tags=["auth"])
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

@router.post("/register", response_model=UserResponse)
def register(user: UserCreate, db: Session = Depends(get_db)):
    # Check if user exists
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create new user
    new_user = User(
        name=user.name,
        email=user.email,
        phone=user.phone,
        password_hash=hash_password(user.password),
        role=user.role,
        region=user.region,
        village=user.village
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

@router.post("/login", response_model=UserLoginResponse)
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    
    if not db_user or not verify_password(user.password, db_user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Generate JWT tokens
    access_token = create_access_token(data={"user_id": db_user.id, "email": db_user.email})
    refresh_token = create_refresh_token(data={"user_id": db_user.id, "email": db_user.email})
    
    return {
        "id": db_user.id,
        "email": db_user.email,
        "name": db_user.name,
        "role": db_user.role,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "message": "Login successful"
    }

@router.post("/refresh")
def refresh_token(data: dict):
    """Refresh access token using refresh token."""
    refresh_token_str = data.get("refresh_token")
    if not refresh_token_str:
        raise HTTPException(status_code=400, detail="Refresh token required")
    
    user_id = verify_token(refresh_token_str)
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    
    # Create new access token
    access_token = create_access_token(data={"user_id": user_id})
    
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }
