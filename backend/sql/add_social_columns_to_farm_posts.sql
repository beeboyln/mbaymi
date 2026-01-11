-- ═══════════════════════════════════════════════════════════════════════════
-- ADD SOCIAL ENGAGEMENT COLUMNS TO farm_posts TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- This migration adds columns for tracking social engagement on posts
-- (likes, comments, shares, views counts)

ALTER TABLE farm_posts
ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;

ALTER TABLE farm_posts
ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;

ALTER TABLE farm_posts
ADD COLUMN IF NOT EXISTS shares_count INTEGER DEFAULT 0;

ALTER TABLE farm_posts
ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_farm_posts_likes_count ON farm_posts(likes_count DESC);
CREATE INDEX IF NOT EXISTS idx_farm_posts_created_at ON farm_posts(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- ADD SOCIAL ENGAGEMENT COLUMNS TO livestock TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Add engagement tracking for animal listings

ALTER TABLE livestock
ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;

ALTER TABLE livestock
ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;

ALTER TABLE livestock
ADD COLUMN IF NOT EXISTS shares_count INTEGER DEFAULT 0;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_livestock_likes_count ON livestock(likes_count DESC);
CREATE INDEX IF NOT EXISTS idx_livestock_created_at ON livestock(created_at DESC);
