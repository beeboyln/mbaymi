-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE LIVESTOCK SOCIAL INTERACTION TABLES
-- ═══════════════════════════════════════════════════════════════════════════
-- Tables for tracking likes, comments, and shares on livestock/animal posts

-- Table for livestock likes
CREATE TABLE IF NOT EXISTS livestock_likes (
    id SERIAL PRIMARY KEY,
    livestock_id INTEGER NOT NULL REFERENCES livestock(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(livestock_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_livestock_likes_livestock_id ON livestock_likes(livestock_id);
CREATE INDEX IF NOT EXISTS idx_livestock_likes_user_id ON livestock_likes(user_id);

-- Table for livestock comments
CREATE TABLE IF NOT EXISTS livestock_comments (
    id SERIAL PRIMARY KEY,
    livestock_id INTEGER NOT NULL REFERENCES livestock(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_livestock_comments_livestock_id ON livestock_comments(livestock_id);
CREATE INDEX IF NOT EXISTS idx_livestock_comments_user_id ON livestock_comments(user_id);

-- Table for livestock shares
CREATE TABLE IF NOT EXISTS livestock_shares (
    id SERIAL PRIMARY KEY,
    livestock_id INTEGER NOT NULL REFERENCES livestock(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_livestock_shares_livestock_id ON livestock_shares(livestock_id);
CREATE INDEX IF NOT EXISTS idx_livestock_shares_user_id ON livestock_shares(user_id);
