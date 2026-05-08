# 🗄️ SQL Setup Guide - Neon PostgreSQL

## 📋 How to Create Database on Neon

### Step 1: Get SQL File

Le fichier **`database.sql`** contient toutes les requêtes pour créer votre base de données Mbaymi.

Il inclut :
- ✅ 5 tables (users, farms, crops, livestock, market_prices)
- ✅ Tous les indexes pour performance
- ✅ Foreign keys avec CASCADE delete
- ✅ Données d'exemple pour tester

### Step 2: Créer Project sur Neon

1. Go to https://neon.tech
2. Sign up (free account)
3. Create a new project
4. Choose PostgreSQL version (15 or 16)
5. Copy the connection string (DATABASE_URL)

### Step 3: Exécuter SQL sur Neon Editor

#### Option A: Via Neon Web Editor (Recommandé)

1. Go to Neon Dashboard
2. Select your project
3. Click **"SQL Editor"** in the sidebar
4. Paste the entire `database.sql` content
5. Click **"Run"** button

✅ Your tables will be created in seconds!

#### Option B: Via Command Line (psql)

```powershell
# Get connection string from Neon dashboard
$env:DATABASE_URL = "postgresql://user:password@host/dbname"

# Run SQL file
psql $env:DATABASE_URL -f database.sql
```

#### Option C: Using Python

```python
import psycopg2

conn_string = "postgresql://user:password@host/dbname"
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

# Read and execute SQL file
with open('database.sql', 'r') as f:
    sql = f.read()
    cur.execute(sql)

conn.commit()
cur.close()
conn.close()
print("Database created successfully!")
```

## 📊 What Gets Created

### Tables

| Table | Purpose | Records |
|-------|---------|---------|
| `users` | Farmers, breeders, buyers, sellers | 4 sample |
| `farms` | User farms/plots | 3 sample |
| `crops` | Crops planted on farms | 4 sample |
| `livestock` | Animals owned by users | 4 sample |
| `market_prices` | Product prices by region | 7 sample |

### Columns by Table

**users**
```
id, name, email, phone, password_hash, role, region, village, is_active, created_at, updated_at
```

**farms**
```
id, user_id, name, location, size_hectares, soil_type, created_at, updated_at
```

**crops**
```
id, farm_id, crop_name, planted_date, expected_harvest_date, quantity_planted, expected_yield, actual_yield, status, notes, created_at, updated_at
```

**livestock**
```
id, user_id, animal_type, breed, quantity, age_months, weight_kg, health_status, last_vaccination_date, vaccination_type, feeding_type, location, notes, created_at, updated_at
```

**market_prices**
```
id, product_name, region, price_per_kg, currency, unit, price_date, source, notes, created_at
```

## ✅ Verification Queries

After running `database.sql`, test with these queries in SQL Editor:

### Count all records

```sql
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'farms', COUNT(*) FROM farms
UNION ALL
SELECT 'crops', COUNT(*) FROM crops
UNION ALL
SELECT 'livestock', COUNT(*) FROM livestock
UNION ALL
SELECT 'market_prices', COUNT(*) FROM market_prices;
```

Expected output:
```
table_name      | count
----------------+-------
users           | 4
farms           | 3
crops           | 4
livestock       | 4
market_prices   | 7
```

### Get all users

```sql
SELECT id, name, email, role, region FROM users;
```

### Get crops by farm

```sql
SELECT f.name, c.crop_name, c.status, c.expected_harvest_date
FROM crops c
JOIN farms f ON c.farm_id = f.id
ORDER BY f.name;
```

### Get market prices

```sql
SELECT product_name, region, price_per_kg, price_date
FROM market_prices
ORDER BY price_date DESC;
```

### Get user with farms and livestock

```sql
SELECT 
  u.name,
  COUNT(DISTINCT f.id) as farms,
  COUNT(DISTINCT l.id) as livestock_entries
FROM users u
LEFT JOIN farms f ON u.id = f.user_id
LEFT JOIN livestock l ON u.id = l.user_id
GROUP BY u.id, u.name;
```

## 🔧 Database Management

### Reset Database (Start Fresh)

Uncomment at the top of `database.sql`:

```sql
DROP TABLE IF EXISTS crops CASCADE;
DROP TABLE IF EXISTS livestock CASCADE;
DROP TABLE IF EXISTS farms CASCADE;
DROP TABLE IF EXISTS market_prices CASCADE;
DROP TABLE IF EXISTS users CASCADE;
```

Then run the full script again.

### Clear Sample Data Only

```sql
DELETE FROM crops;
DELETE FROM livestock;
DELETE FROM farms;
DELETE FROM market_prices;
DELETE FROM users;
```

### Get Database Info

```sql
-- List all tables
SELECT tablename FROM pg_tables WHERE schemaname='public';

-- List all indexes
SELECT indexname FROM pg_indexes WHERE schemaname='public';

-- Check table sizes
SELECT tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname='public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## 🔐 Important Notes

### Sample Passwords

The sample users have **fake password hashes**. When testing:

```python
# Don't use these in production!
password_hash = '$2b$12$abcdefghijk'  # Not a real hash
```

To create real password hashes:

```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
hash = pwd_context.hash("mypassword")
```

### Foreign Key Constraints

- Deleting a user will cascade delete their farms and livestock
- Deleting a farm will cascade delete its crops
- This is good for data integrity!

### Time Zones

All timestamps use **UTC** (CURRENT_TIMESTAMP).

If you need different timezone:
```sql
created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP AT TIME ZONE 'Africa/Dakar'
```

## 📱 Next Steps

1. ✅ Run `database.sql` on Neon
2. ✅ Copy connection string to backend `.env`
3. ✅ Backend will now connect to your database
4. ✅ Test with API at http://localhost:8000/docs

## 🚨 Troubleshooting

### Error: "relation already exists"

The table already exists. Either:
- Use different database name
- Or run DROP TABLE statements first

### Error: "syntax error"

Check if:
- SQL has proper semicolons
- No special characters encoding issues
- Paste the ENTIRE `database.sql` file

### Connection refused

Check if:
- DATABASE_URL is correct in `.env`
- Network access is allowed on Neon
- Password is correct

### Tables created but data missing

Sample data may not have inserted. Run this to check:

```sql
SELECT COUNT(*) FROM users;
```

If 0, insert data manually or check for errors.

---

**Ready to populate your database!** 🚀
