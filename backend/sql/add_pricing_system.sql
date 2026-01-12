-- ============================================================================
-- 💰 Migration: Add Pricing System to Farm Posts & Market Trends
-- ============================================================================

-- 1. Add columns to farm_image_posts for pricing
ALTER TABLE farm_image_posts
ADD COLUMN post_intent VARCHAR(20) DEFAULT 'share' NOT NULL,
ADD COLUMN price FLOAT DEFAULT NULL,
ADD COLUMN product_name VARCHAR(100) DEFAULT NULL,
ADD COLUMN unit VARCHAR(20) DEFAULT 'kg' NOT NULL;

-- Create indexes for price queries
CREATE INDEX IF NOT EXISTS idx_farm_posts_post_intent ON farm_image_posts(post_intent);
CREATE INDEX IF NOT EXISTS idx_farm_posts_product_name ON farm_image_posts(product_name);

-- 2. Create market_trends table for aggregated prices
CREATE TABLE IF NOT EXISTS market_trends (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    region VARCHAR(100) DEFAULT NULL,
    avg_price FLOAT DEFAULT 0,
    min_price FLOAT DEFAULT NULL,
    max_price FLOAT DEFAULT NULL,
    count INTEGER DEFAULT 1,
    currency VARCHAR(10) DEFAULT 'CFA',
    unit VARCHAR(20) DEFAULT 'kg',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for market_trends
CREATE INDEX IF NOT EXISTS idx_market_trends_product ON market_trends(product_name);
CREATE INDEX IF NOT EXISTS idx_market_trends_region ON market_trends(region);
CREATE INDEX IF NOT EXISTS idx_market_trends_updated_at ON market_trends(updated_at DESC);
