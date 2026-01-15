-- 🏥 Veterinarian/Expert System Migration
-- Creates tables for professional services: veterinarians, authorizations, and service requests

-- 1️⃣ Veterinarian Profiles Table
CREATE TABLE IF NOT EXISTS veterinarian_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    specialty VARCHAR(100) NOT NULL,
    zone VARCHAR(100) NOT NULL,
    distance_max INTEGER,
    bio TEXT,
    experience_years INTEGER,
    certificate_url VARCHAR(500),
    contact_preference VARCHAR(50),
    verification_status VARCHAR(50) DEFAULT 'pending',
    availability_status VARCHAR(50) DEFAULT 'available',
    total_consultations INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 2️⃣ Authorization Table
-- Farmers grant permission to veterinarians to access farm data
CREATE TABLE IF NOT EXISTS authorizations (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL,
    veterinarian_id INTEGER NOT NULL,
    authorized_by INTEGER NOT NULL,
    can_view_data BOOLEAN DEFAULT true,
    can_give_advice BOOLEAN DEFAULT true,
    can_visit BOOLEAN DEFAULT false,
    status VARCHAR(50) DEFAULT 'pending',
    authorization_reason TEXT,
    expires_at TIMESTAMP,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE,
    FOREIGN KEY (veterinarian_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (authorized_by) REFERENCES users(id),
    UNIQUE(farm_id, veterinarian_id)
);

-- 3️⃣ Service Requests Table
-- Farmers request help for animal/crop problems
CREATE TABLE IF NOT EXISTS service_requests (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL,
    created_by INTEGER NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    symptoms TEXT,
    animal_id INTEGER,
    crop_id INTEGER,
    priority VARCHAR(50) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'open',
    photos JSON,
    assigned_to INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (animal_id) REFERENCES livestock(id) ON DELETE SET NULL,
    FOREIGN KEY (crop_id) REFERENCES crops(id) ON DELETE SET NULL
);

-- 4️⃣ Consultations Table
-- Veterinarians provide consultations/advice for service requests
CREATE TABLE IF NOT EXISTS consultations (
    id SERIAL PRIMARY KEY,
    service_request_id INTEGER NOT NULL UNIQUE,
    veterinarian_id INTEGER NOT NULL,
    consultation_type VARCHAR(50) NOT NULL,
    advice TEXT NOT NULL,
    recommendations TEXT,
    scheduling VARCHAR(255),
    cost DECIMAL(10,2),
    payment_status VARCHAR(50) DEFAULT 'pending',
    farmer_rating INTEGER,
    farmer_feedback TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (service_request_id) REFERENCES service_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (veterinarian_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 5️⃣ Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_veterinarian_zone ON veterinarian_profiles(zone);
CREATE INDEX IF NOT EXISTS idx_veterinarian_specialty ON veterinarian_profiles(specialty);
CREATE INDEX IF NOT EXISTS idx_veterinarian_verification ON veterinarian_profiles(verification_status);
CREATE INDEX IF NOT EXISTS idx_authorization_farm ON authorizations(farm_id);
CREATE INDEX IF NOT EXISTS idx_authorization_veterinarian ON authorizations(veterinarian_id);
CREATE INDEX IF NOT EXISTS idx_authorization_status ON authorizations(status);
CREATE INDEX IF NOT EXISTS idx_service_request_farm ON service_requests(farm_id);
CREATE INDEX IF NOT EXISTS idx_service_request_status ON service_requests(status);
CREATE INDEX IF NOT EXISTS idx_service_request_priority ON service_requests(priority);
CREATE INDEX IF NOT EXISTS idx_consultation_veterinarian ON consultations(veterinarian_id);

-- ✅ Migration complete
COMMENT ON TABLE veterinarian_profiles IS 'Stores professional veterinarian/expert profiles with credentials and verification';
COMMENT ON TABLE authorizations IS 'Tracks farm access permissions granted by farmers to veterinarians';
COMMENT ON TABLE service_requests IS 'Farmer requests for help with animal or crop problems';
COMMENT ON TABLE consultations IS 'Professional consultations provided by veterinarians to farmers';
