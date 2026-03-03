# Registration Flow Test Guide

## Current Status: ✅ READY FOR TESTING

### Database Migration: ✅ COMPLETE
- ✅ Email column made nullable
- ✅ Phone column made nullable  
- ✅ Unique constraints removed on email/phone
- ✅ init_db() now handles these updates automatically

### Backend Schema: ✅ UPDATED
- ✅ UserCreate now has `email: Optional[str] = None`
- ✅ UserCreate now has `phone: Optional[str] = None`
- ✅ Register endpoint validates: email OR phone (not both required)
- ✅ Register endpoint rejects if NEITHER provided
- ✅ Login endpoint accepts email OR phone username

### Frontend API Service: ✅ FIXED
- ✅ Sends `null` instead of empty strings for optional fields
- ✅ Login detects identifier type (email vs phone)
- ✅ Register sends proper JSON with null values

## Test Cases to Execute

### Test 1: Email-Only Registration
```
POST /api/auth/register
{
  "name": "Farmer Test Email",
  "email": "farmer.email@test.com",
  "phone": null,
  "password": "Test123!",
  "role": "farmer",
  "region": "Bamako",
  "village": null
}
Expected: 200 OK with JWT tokens
```

### Test 2: Phone-Only Registration
```
POST /api/auth/register
{
  "name": "Farmer Test Phone",
  "email": null,
  "phone": "+223 75 123 456",
  "password": "Test123!",
  "role": "farmer",
  "region": "Koulikoro",
  "village": null
}
Expected: 200 OK with JWT tokens
```

### Test 3: Email + Phone Registration
```
POST /api/auth/register
{
  "name": "Farmer Test Both",
  "email": "farmer.both@test.com",
  "phone": "+223 75 987 654",
  "password": "Test123!",
  "role": "farmer",
  "region": "Ségou",
  "village": null
}
Expected: 200 OK with JWT tokens
```

### Test 4: Neither Email Nor Phone (Should Fail)
```
POST /api/auth/register
{
  "name": "Farmer Test Invalid",
  "email": null,
  "phone": null,
  "password": "Test123!",
  "role": "farmer",
  "region": "Mopti",
  "village": null
}
Expected: 400 Bad Request - "Email ou téléphone requis"
```

### Test 5: Email-Only Login
```
POST /api/auth/login
{
  "email": "farmer.email@test.com",
  "phone": null,
  "password": "Test123!"
}
Expected: 200 OK with JWT tokens
```

### Test 6: Phone-Only Login
```
POST /api/auth/login
{
  "email": "+223 75 123 456",
  "phone": null,
  "password": "Test123!"
}
Expected: 200 OK with JWT tokens
```

## End-to-End Flow Test (Flutter App)

1. **Open Flutter Web App**
   - Navigate to login screen

2. **Test Email Registration**
   - Click Register
   - Toggle to Email mode (if not default)
   - Enter: name="Test Farmer", email="test.farmer@mbaymi.ml", password="Test123!"
   - Verify: Success message, redirected to home, JWT token stored

3. **Test Phone Registration**
   - Click Register
   - Toggle to Phone mode
   - Enter: name="Test Farmer 2", phone="+223 75 555 555", password="Test123!"
   - Verify: Success message, redirected to home, JWT token stored

4. **Test Email Login**
   - Click Login
   - Toggle to Email mode
   - Enter: email="test.farmer@mbaymi.ml", password="Test123!"
   - Verify: Success message, redirected to home

5. **Test Phone Login**
   - Click Login
   - Toggle to Phone mode
   - Enter: phone="+223 75 555 555", password="Test123!"
   - Verify: Success message, redirected to home

## Database Verification

Run these SQL queries to verify nullable columns:

### Check users table structure
```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('email', 'phone');
```

Expected output:
```
Column      | Type    | Nullable
email       | varchar | YES
phone       | varchar | YES
```

### Check existing users
```sql
SELECT id, name, email, phone, role FROM users LIMIT 10;
```

Should show rows where email OR phone can be NULL.

## Common Issues & Fixes

### Issue: "Email ou téléphone requis" - Both null
**Fix**: Ensure frontend sends `null` (not empty string "") for unselected fields

### Issue: "400 Bad Request" after fix
**Cause**: Database still has NOT NULL constraint
**Fix**: Run migration script in init_db() or execute SQL directly:
```sql
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;
ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;
```

### Issue: Unique constraint violation
**Cause**: Duplicate email or phone in database
**Fix**: Data migration can allow NULL but must still check for duplicates
```sql
-- Drop unique constraints
ALTER TABLE users DROP CONSTRAINT users_email_key;
ALTER TABLE users DROP CONSTRAINT users_phone_key;
```

### Issue: SQLite (development)
**Cause**: SQLite doesn't support ALTER TABLE DROP NOT NULL
**Fix**: Recreate table or use PostgreSQL for development

## Success Criteria

- ✅ Email-only users can register
- ✅ Phone-only users can register  
- ✅ Email-only users can login
- ✅ Phone-only users can login
- ✅ Invalid requests (neither email nor phone) rejected with 400
- ✅ No "400 Bad Request" errors for valid requests
- ✅ JWT tokens generated correctly
- ✅ All data persists in database correctly

## Next Steps After Verification

1. **Order Placement**: Create `/api/orders` endpoint
2. **Cart Checkout**: Implement order confirmation screen
3. **Email/SMS Verification**: Add verification endpoints
4. **Admin Dashboard**: Veterinarian dashboard for farm management
