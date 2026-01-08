-- Ajouter les tables pour le réseau agricole
-- Exécute ce script après redéploiement du backend

-- 1. Table des profils publics de fermes
CREATE TABLE IF NOT EXISTS farm_profiles (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL UNIQUE REFERENCES farms(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_public BOOLEAN DEFAULT TRUE,
    description TEXT,
    specialties VARCHAR(500),
    total_followers INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Table des posts de fermes
CREATE TABLE IF NOT EXISTS farm_posts (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    crop_id INTEGER REFERENCES crops(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    photo_url VARCHAR(500),
    post_type VARCHAR(50) DEFAULT 'crop_update',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Table des relations de suivi
CREATE TABLE IF NOT EXISTS farm_following (
    id SERIAL PRIMARY KEY,
    follower_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_id INTEGER NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, farm_id)
);

-- Créer les indices pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_farm_profiles_farm_id ON farm_profiles(farm_id);
CREATE INDEX IF NOT EXISTS idx_farm_profiles_user_id ON farm_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_farm_posts_farm_id ON farm_posts(farm_id);
CREATE INDEX IF NOT EXISTS idx_farm_posts_user_id ON farm_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_farm_following_follower_id ON farm_following(follower_id);
CREATE INDEX IF NOT EXISTS idx_farm_following_farm_id ON farm_following(farm_id);
