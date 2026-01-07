-- ====================================
-- Mbaymi Database Schema
-- PostgreSQL SQL for Neon DB
-- ====================================

-- DROP TABLES IF EXISTS (optional - for fresh start)
-- DROP TABLE IF EXISTS crops CASCADE;
-- DROP TABLE IF EXISTS livestock CASCADE;
-- DROP TABLE IF EXISTS farms CASCADE;
-- DROP TABLE IF EXISTS market_prices CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;

-- ====================================
-- 1. USERS TABLE
-- ====================================
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL,
  region VARCHAR(100),
  village VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_region ON users(region);

-- ====================================
-- 2. FARMS TABLE
-- ====================================
CREATE TABLE farms (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  location VARCHAR(200),
  size_hectares FLOAT,
  soil_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for farms
CREATE INDEX idx_farms_user_id ON farms(user_id);
CREATE INDEX idx_farms_location ON farms(location);

-- ====================================
-- 3. CROPS TABLE
-- ====================================
CREATE TABLE crops (
  id SERIAL PRIMARY KEY,
  farm_id INTEGER NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  crop_name VARCHAR(100) NOT NULL,
  planted_date TIMESTAMP,
  expected_harvest_date TIMESTAMP,
  quantity_planted FLOAT,
  expected_yield FLOAT,
  actual_yield FLOAT,
  status VARCHAR(50) DEFAULT 'growing',
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for crops
CREATE INDEX idx_crops_farm_id ON crops(farm_id);
CREATE INDEX idx_crops_status ON crops(status);
CREATE INDEX idx_crops_crop_name ON crops(crop_name);

-- ====================================
-- 4. LIVESTOCK TABLE
-- ====================================
CREATE TABLE livestock (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  animal_type VARCHAR(50) NOT NULL,
  breed VARCHAR(100),
  quantity INTEGER DEFAULT 1,
  age_months INTEGER,
  weight_kg FLOAT,
  health_status VARCHAR(50) DEFAULT 'healthy',
  last_vaccination_date TIMESTAMP,
  vaccination_type VARCHAR(100),
  feeding_type VARCHAR(100),
  location VARCHAR(200),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for livestock
CREATE INDEX idx_livestock_user_id ON livestock(user_id);
CREATE INDEX idx_livestock_animal_type ON livestock(animal_type);
CREATE INDEX idx_livestock_health_status ON livestock(health_status);

-- ====================================
-- 5. MARKET PRICES TABLE
-- ====================================
CREATE TABLE market_prices (
  id SERIAL PRIMARY KEY,
  product_name VARCHAR(100) NOT NULL,
  region VARCHAR(100) NOT NULL,
  price_per_kg FLOAT NOT NULL,
  currency VARCHAR(10) DEFAULT 'CFA',
  unit VARCHAR(50) DEFAULT 'kg',
  price_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  source VARCHAR(100),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for market_prices
CREATE INDEX idx_market_prices_product ON market_prices(product_name);
CREATE INDEX idx_market_prices_region ON market_prices(region);
CREATE INDEX idx_market_prices_price_date ON market_prices(price_date);
CREATE UNIQUE INDEX idx_market_prices_unique 
  ON market_prices(product_name, region, DATE(price_date));

-- ====================================
-- SAMPLE DATA (Optional - for testing)
-- ====================================

-- Insert sample users
INSERT INTO users (name, email, phone, password_hash, role, region, village)
VALUES 
  ('Moussa Sow', 'moussa@example.com', '221701234567', '$2b$12$abcdefghijk', 'farmer', 'Dakar', 'Parcelles Assainies'),
  ('Aïssatou Diallo', 'aissatou@example.com', '221702345678', '$2b$12$lmnopqrstuv', 'livestock_breeder', 'Kaolack', 'Kaolack-ville'),
  ('Ibrahima Ba', 'ibrahima@example.com', '221703456789', '$2b$12$wxyzabcdefg', 'buyer', 'Tambacounda', 'Tambacounda-centre'),
  ('Fatou Ndiaye', 'fatou@example.com', '221704567890', '$2b$12$hijklmnopqr', 'farmer', 'Kolda', 'Kolda-ville');

-- Insert sample farms
INSERT INTO farms (user_id, name, location, size_hectares, soil_type)
VALUES 
  (1, 'Ferme Sow', 'Parcelles Assainies, Dakar', 2.5, 'sandy'),
  (1, 'Champ Nord', 'Pikine, Dakar', 1.5, 'loamy'),
  (4, 'Ferme Kolda', 'Kolda-ville', 3.0, 'clay');

-- Insert sample crops
INSERT INTO crops (farm_id, crop_name, planted_date, expected_harvest_date, quantity_planted, expected_yield, status)
VALUES 
  (1, 'maïs', '2025-06-01', '2025-09-15', 100, 450, 'growing'),
  (1, 'arachide', '2025-06-15', '2025-10-01', 80, 320, 'growing'),
  (2, 'riz', '2025-05-20', '2025-09-01', 150, 750, 'growing'),
  (3, 'millet', '2025-07-01', '2025-10-15', 120, 480, 'growing');

-- Insert sample livestock
INSERT INTO livestock (user_id, animal_type, breed, quantity, age_months, health_status, feeding_type, location)
VALUES 
  (2, 'cattle', 'N\'Dama', 5, 36, 'healthy', 'grass', 'Kaolack-ville'),
  (2, 'goat', 'Local', 15, 18, 'healthy', 'mixed', 'Kaolack-ville'),
  (4, 'sheep', 'Peul', 8, 24, 'healthy', 'grass', 'Kolda-ville'),
  (4, 'poultry', 'Local', 50, 4, 'vaccinated', 'grains', 'Kolda-ville');

-- Insert sample market prices
INSERT INTO market_prices (product_name, region, price_per_kg, currency, source)
VALUES 
  ('maïs', 'Dakar', 250, 'CFA', 'ministry'),
  ('maïs', 'Kaolack', 220, 'CFA', 'ministry'),
  ('riz', 'Dakar', 400, 'CFA', 'ministry'),
  ('arachide', 'Kaolack', 350, 'CFA', 'ministry'),
  ('millet', 'Kolda', 300, 'CFA', 'ministry'),
  ('tomate', 'Dakar', 500, 'CFA', 'market_data'),
  ('oignon', 'Tambacounda', 180, 'CFA', 'market_data');

-- ====================================
-- VERIFICATION QUERIES (Run these to check)
-- ====================================

-- Check all tables created
-- SELECT tablename FROM pg_tables WHERE schemaname='public';

-- Count records in each table
-- SELECT 'users' as table_name, COUNT(*) as count FROM users
-- UNION ALL
-- SELECT 'farms', COUNT(*) FROM farms
-- UNION ALL
-- SELECT 'crops', COUNT(*) FROM crops
-- UNION ALL
-- SELECT 'livestock', COUNT(*) FROM livestock
-- UNION ALL
-- SELECT 'market_prices', COUNT(*) FROM market_prices;

-- Get all users with their farms
-- SELECT u.name, u.email, u.role, COUNT(f.id) as farm_count
-- FROM users u
-- LEFT JOIN farms f ON u.id = f.user_id
-- GROUP BY u.id, u.name, u.email, u.role;

-- Get latest market prices
-- SELECT product_name, region, price_per_kg, currency, price_date
-- FROM market_prices
-- ORDER BY price_date DESC
-- LIMIT 10;
