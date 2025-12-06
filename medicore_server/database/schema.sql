-- MediCore PostgreSQL Database Schema
-- Server-side database for multi-PC synchronization

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    role VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    percentage DECIMAL(5,2),
    is_template_user BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Sync fields
    last_synced_at TIMESTAMP WITH TIME ZONE,
    sync_version INTEGER DEFAULT 1,
    needs_sync BOOLEAN DEFAULT FALSE
);

-- Templates table
CREATE TABLE IF NOT EXISTS templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    percentage DECIMAL(5,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Sync fields
    last_synced_at TIMESTAMP WITH TIME ZONE,
    sync_version INTEGER DEFAULT 1,
    needs_sync BOOLEAN DEFAULT FALSE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_sync ON users(needs_sync, updated_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_templates_role ON templates(role) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_templates_sync ON templates(needs_sync, updated_at) WHERE deleted_at IS NULL;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_templates_updated_at BEFORE UPDATE ON templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default admin user
INSERT INTO users (id, name, role, password_hash, is_template_user, needs_sync)
VALUES (
    'admin'::uuid,
    'Administrateur',
    'Administrateur',
    '1234',  -- TODO: Hash in production
    FALSE,
    FALSE
) ON CONFLICT (id) DO NOTHING;
