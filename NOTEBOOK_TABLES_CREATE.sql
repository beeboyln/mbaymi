-- ═══════════════════════════════════════════════════════════════════════════
-- NOTEBOOK TABLES CREATION SCRIPT
-- PostgreSQL 12+
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. PROJECT NOTEBOOKS TABLE (Main table)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS project_notebooks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    farm_id INTEGER NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    created_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category VARCHAR(50) DEFAULT 'general',
    is_public BOOLEAN DEFAULT FALSE,
    sections JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_project_notebooks_farm_id ON project_notebooks(farm_id);
CREATE INDEX IF NOT EXISTS idx_project_notebooks_created_by ON project_notebooks(created_by);
CREATE INDEX IF NOT EXISTS idx_project_notebooks_created_at ON project_notebooks(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. NOTEBOOK SECTIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notebook_sections (
    id SERIAL PRIMARY KEY,
    notebook_id INTEGER NOT NULL REFERENCES project_notebooks(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    "order" INTEGER DEFAULT 0,
    contents JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notebook_sections_notebook_id ON notebook_sections(notebook_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. NOTEBOOK TAGS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notebook_tags (
    id SERIAL PRIMARY KEY,
    notebook_id INTEGER NOT NULL REFERENCES project_notebooks(id) ON DELETE CASCADE,
    tag VARCHAR(100) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notebook_tags_notebook_id ON notebook_tags(notebook_id);
CREATE INDEX IF NOT EXISTS idx_notebook_tags_tag ON notebook_tags(tag);

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. NOTEBOOK COMMENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notebook_comments (
    id SERIAL PRIMARY KEY,
    notebook_id INTEGER NOT NULL REFERENCES project_notebooks(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notebook_comments_notebook_id ON notebook_comments(notebook_id);
CREATE INDEX IF NOT EXISTS idx_notebook_comments_user_id ON notebook_comments(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. NOTEBOOK SHARES TABLE (Partage de cahiers)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notebook_shares (
    id SERIAL PRIMARY KEY,
    notebook_id INTEGER NOT NULL REFERENCES project_notebooks(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(notebook_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_notebook_shares_notebook_id ON notebook_shares(notebook_id);
CREATE INDEX IF NOT EXISTS idx_notebook_shares_user_id ON notebook_shares(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. NOTEBOOK VERSIONS TABLE (Versioning)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notebook_versions (
    id SERIAL PRIMARY KEY,
    notebook_id INTEGER NOT NULL REFERENCES project_notebooks(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    change_description TEXT,
    created_by INTEGER NOT NULL REFERENCES users(id),
    sections_snapshot JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notebook_versions_notebook_id ON notebook_versions(notebook_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- VERIFICATION QUERIES
-- ═══════════════════════════════════════════════════════════════════════════
-- Uncomment to verify tables after creation:
-- \dt project_notebooks notebook_* 
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'notebook%';
