from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.schemas.schemas import UserCreate, UserResponse, UserLogin, UserLoginResponse
from passlib.context import CryptContext
from app.services.jwt_service import create_access_token, create_refresh_token, verify_token
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/auth", tags=["auth"])
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

def get_current_user(authorization: Optional[str] = Header(None)) -> int:
    """Extract user_id from Authorization header"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    
    token = authorization.replace("Bearer ", "")
    user_id = verify_token(token)
    
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    
    return user_id

def get_current_user_obj(
    authorization: Optional[str] = Header(None), 
    db: Session = Depends(get_db)
) -> User:
    """Extract user_id from Authorization header and return User object"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    
    token = authorization.replace("Bearer ", "")
    user_id = verify_token(token)
    
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    print(f"✅ get_current_user_obj: Returning User object (id={user.id}, name={user.name})")
    return user

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

@router.post("/register")
def register(user: UserCreate, db: Session = Depends(get_db)):
    # Valider qu'au moins email ou phone est fourni
    if not user.email and not user.phone:
        raise HTTPException(status_code=400, detail="Email ou téléphone requis")
    
    # Si email est fourni, valider le format
    if user.email:
        if '@' not in user.email:
            raise HTTPException(status_code=400, detail="Email invalide")
    
    # Vérifier si l'utilisateur existe déjà
    if user.email:
        existing_user_email = db.query(User).filter(User.email == user.email).first()
        if existing_user_email:
            raise HTTPException(status_code=400, detail="Email déjà enregistré")
    
    if user.phone:
        existing_user_phone = db.query(User).filter(User.phone == user.phone).first()
        if existing_user_phone:
            raise HTTPException(status_code=400, detail="Téléphone déjà enregistré")
    
    # Créer le nouvel utilisateur
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
    
    print(f"✅ USER REGISTERED: email={new_user.email}, phone={new_user.phone}, id={new_user.id}")
    
    # Generate JWT tokens
    access_token = create_access_token(data={"user_id": new_user.id, "email": new_user.email})
    refresh_token = create_refresh_token(data={"user_id": new_user.id, "email": new_user.email})
    
    return {
        "id": new_user.id,
        "email": new_user.email,
        "name": new_user.name,
        "role": new_user.role,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "message": "Registration successful"
    }

@router.post("/login", response_model=UserLoginResponse)
def login(user: UserLogin, db: Session = Depends(get_db)):
    # Chercher par email ou téléphone
    identifier = user.email
    if '@' in identifier:
        db_user = db.query(User).filter(User.email == identifier).first()
    else:
        db_user = db.query(User).filter(User.phone == identifier).first()
    
    if not db_user:
        print(f"❌ USER NOT FOUND: {identifier}")
        raise HTTPException(status_code=401, detail="Identifiants invalides")
    
    if not verify_password(user.password, db_user.password_hash):
        print(f"❌ PASSWORD MISMATCH for {identifier}")
        raise HTTPException(status_code=401, detail="Identifiants invalides")
    
    print(f"✅ LOGIN SUCCESS: {identifier} (email: {db_user.email}, role: {db_user.role})")
    
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

@router.post("/change-password")
def change_password(
    request: ChangePasswordRequest,
    current_user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Change user password"""
    user = db.query(User).filter(User.id == current_user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Verify current password
    if not verify_password(request.current_password, user.password_hash):
        raise HTTPException(status_code=401, detail="Current password is incorrect")
    
    # Validate new password
    if len(request.new_password) < 6:
        raise HTTPException(status_code=400, detail="New password must be at least 6 characters")
    
    # Hash and update password
    user.password_hash = hash_password(request.new_password)
    db.commit()
    
    return {
        "message": "Password changed successfully"
    }

