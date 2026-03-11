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

email = 'admin@gmail.com'
password = 'passer'

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
password_hash = pwd_context.hash(password)

with engine.connect() as conn:
    # Update password for admin user
    result = conn.execute(
        text("""
            UPDATE users 
            SET password_hash = :password_hash,
                role = 'admin',
                is_active = true
            WHERE email = :email
        """),
        {
            'email': email,
            'password_hash': password_hash
        }
    )
    conn.commit()
    
    if result.rowcount > 0:
        print(f'✅ Admin user updated successfully!')
        print(f'   Email: {email}')
        print(f'   Password: {password}')
        print(f'   Role: admin')
        print('\n🔐 Now disconnect and login again with these credentials.')
    else:
        print(f'❌ User not found')
        raise SystemExit(1)
