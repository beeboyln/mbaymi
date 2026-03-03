-- Create tables for individual animal management system
-- Generated for livestock management upgrade

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMALS TABLE (Individual animal records)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS animals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_id INTEGER REFERENCES farms(id) ON DELETE SET NULL,
    
    name VARCHAR(100) NOT NULL,
    tag_id VARCHAR(50) UNIQUE,
    species VARCHAR(50) NOT NULL,  -- cattle, goat, sheep, pig, poultry, horse, donkey
    breed VARCHAR(100),
    gender VARCHAR(20) NOT NULL,  -- male, female
    date_of_birth DATE NOT NULL,
    
    weight_kg NUMERIC,
    height_cm NUMERIC,
    color_markings VARCHAR(200),
    
    health_status VARCHAR(50) DEFAULT 'healthy',  -- healthy, sick, treated, vaccinated, isolated
    health_notes TEXT,
    last_checkup_date TIMESTAMP,
    
    reproductive_status VARCHAR(50) DEFAULT 'not_breeding',  -- not_breeding, in_cycle, pregnant, lactating, weaned
    
    acquisition_date DATE,
    acquisition_cost NUMERIC,
    location VARCHAR(200),
    is_active BOOLEAN DEFAULT true,
    
    photo_url VARCHAR(500),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (user_id),
    INDEX idx_farm_id (farm_id),
    INDEX idx_species (species),
    INDEX idx_is_active (is_active)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMAL_HEALTH_RECORDS TABLE (Vaccinations, treatments, checkups)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS animal_health_records (
    id SERIAL PRIMARY KEY,
    animal_id INTEGER NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    record_type VARCHAR(50) NOT NULL,  -- vaccination, deworming, treatment, checkup, surgery
    date DATE NOT NULL,
    
    medical_name VARCHAR(200) NOT NULL,
    description TEXT,
    dosage VARCHAR(100),
    administered_by VARCHAR(100),
    cost NUMERIC,
    
    next_due_date DATE,
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_animal_id (animal_id),
    INDEX idx_user_id (user_id),
    INDEX idx_date (date),
    INDEX idx_next_due_date (next_due_date)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMAL_REPRODUCTION TABLE (Breeding cycles, gestation, births)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS animal_reproduction (
    id SERIAL PRIMARY KEY,
    animal_id INTEGER NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    event_type VARCHAR(50) NOT NULL,  -- heat, mating, pregnancy, birth
    event_date DATE NOT NULL,
    
    partner_animal_id INTEGER REFERENCES animals(id) ON DELETE SET NULL,
    partner_name VARCHAR(100),
    
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    number_of_offspring INTEGER,
    offspring_gender VARCHAR(50),
    offspring_health TEXT,
    
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_animal_id (animal_id),
    INDEX idx_user_id (user_id),
    INDEX idx_event_date (event_date),
    INDEX idx_event_type (event_type)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMAL_PRODUCTION TABLE (Daily/periodic production records)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS animal_production (
    id SERIAL PRIMARY KEY,
    animal_id INTEGER NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    date DATE NOT NULL,
    
    metric_type VARCHAR(50) NOT NULL,  -- milk, eggs, wool, meat, etc.
    quantity NUMERIC NOT NULL,
    unit VARCHAR(20) NOT NULL,  -- liters, number, kg, etc.
    
    quality_grade VARCHAR(50),
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_animal_id (animal_id),
    INDEX idx_user_id (user_id),
    INDEX idx_date (date),
    INDEX idx_metric_type (metric_type)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMAL_CARE_REMINDERS TABLE (Calendar events for care tasks)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS animal_care_reminders (
    id SERIAL PRIMARY KEY,
    animal_id INTEGER NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    title VARCHAR(200) NOT NULL,
    description TEXT,
    tag VARCHAR(50),  -- health, reproduction, maintenance, nutrition
    
    due_date DATE NOT NULL,
    completed_date DATE,
    is_completed BOOLEAN DEFAULT false,
    
    is_recurring BOOLEAN DEFAULT false,
    recurrence_interval VARCHAR(50),  -- daily, weekly, monthly, yearly
    
    priority VARCHAR(20) DEFAULT 'normal',  -- low, normal, high, critical
    
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_animal_id (animal_id),
    INDEX idx_user_id (user_id),
    INDEX idx_due_date (due_date),
    INDEX idx_is_completed (is_completed),
    INDEX idx_priority (priority)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- MIGRATION NOTES
-- ─────────────────────────────────────────────────────────────────────────────
-- This migration creates the new individual animal management system
-- Existing livestock group records remain unchanged for backward compatibility
--
-- Key relationships:
-- - animals.user_id → users (each farmer has multiple animals)
-- - animals.farm_id → farms (animals belong to a farm)
-- - health_records, reproduction, production, reminders all reference animals
--
-- Next steps:
-- 1. Run this migration against PostgreSQL
-- 2. Frontend can fetch individual animals and their related data
-- 3. Existing group livestock tracking continues to work as before
