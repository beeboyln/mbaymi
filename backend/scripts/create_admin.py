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
name = 'Admin'
role = 'admin'

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
password_hash = pwd_context.hash(password)

with engine.connect() as conn:
    # Check if user already exists
    result = conn.execute(text("SELECT id, email FROM users WHERE email = :email"), {'email': email}).fetchone()
    
    if result:
        print(f'❌ User with email {email} already exists (ID: {result[0]})')
        raise SystemExit(1)
    
    # Create the admin user
    try:
        conn.execute(
            text("""
                INSERT INTO users (name, email, password_hash, role, is_active)
                VALUES (:name, :email, :password_hash, :role, :is_active)
            """),
            {
                'name': name,
                'email': email,
                'password_hash': password_hash,
                'role': role,
                'is_active': True
            }
        )
        conn.commit()
        print(f'✅ Admin user created successfully!')
        print(f'   Email: {email}')
        print(f'   Password: {password}')
        print(f'   Role: {role}')
    except Exception as e:
        print(f'❌ Error creating admin user: {e}')
        raise SystemExit(1)
