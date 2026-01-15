import jwt
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

SECRET_KEY = "your-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 480  # 8 heures au lieu de 30 minutes
REFRESH_TOKEN_EXPIRE_DAYS = 30  # 30 jours au lieu de 7

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: Dict[str, Any]) -> str:
    """Create a JWT refresh token with longer expiration."""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_token(token: str) -> Optional[Dict[str, Any]]:
    """Decode and validate a JWT token."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        logger.debug(f"✅ Token decoded successfully: user_id={payload.get('user_id')}")
        return payload
    except jwt.ExpiredSignatureError:
        logger.warning("⚠️ Token has expired")
        return None
    except jwt.InvalidTokenError as e:
        logger.warning(f"⚠️ Invalid token: {e}")
        return None
    except Exception as e:
        logger.error(f"❌ Token decoding error: {e}")
        return None

def verify_token(token: str) -> Optional[int]:
    """Verify token and return user_id if valid."""
    payload = decode_token(token)
    if payload and "user_id" in payload:
        logger.debug(f"✅ Token verified: user_id={payload['user_id']}")
        return payload["user_id"]
    logger.warning(f"⚠️ Token verification failed: payload={payload}")
    return None
