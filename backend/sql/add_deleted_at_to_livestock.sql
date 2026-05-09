-- Add soft delete timestamp to livestock table
ALTER TABLE livestock ADD COLUMN deleted_at TIMESTAMP NULL;

-- Index for efficient filtering
CREATE INDEX idx_livestock_deleted_at ON livestock(deleted_at);
