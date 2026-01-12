-- Add visibility column to livestock table
ALTER TABLE livestock
ADD COLUMN visibility VARCHAR(20) DEFAULT 'PRIVATE' NOT NULL;

-- Add index for visibility queries
CREATE INDEX idx_livestock_visibility ON livestock(visibility);
