import os
from sqlalchemy import create_engine, text
from passlib.context import CryptContext
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))

DATABASE_URL = os.getenv('DATABASE_URL')
if not DATABASE_URL:
    print('DATABASE_URL not set')
    raise SystemExit(1)

engine = create_engine(DATABASE_URL)

email = 'd@gmail.com'
password = 'passer'

with engine.connect() as conn:
    result = conn.execute(text("SELECT id, email, role, password_hash FROM users WHERE email = :email"), {'email': email}).fetchone()
    if not result:
        print(f'User with email {email} not found')
        raise SystemExit(0)

    user_id, user_email, user_role, password_hash = result
    print(f'Found user: id={user_id}, email={user_email}, role={user_role}')

    pwd_ctx = CryptContext(schemes=["argon2"], deprecated="auto")
    try:
        ok = pwd_ctx.verify(password, password_hash)
    except Exception as e:
        print('Password verification failed:', e)
        raise

    if ok:
        print('Password match: ✅')
    else:
        print('Password match: ❌')
