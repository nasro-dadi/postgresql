-- Initial database setup script
-- This script will be executed when the PostgreSQL container starts for the first time

-- Create additional databases if needed
-- CREATE DATABASE app_test;
-- CREATE DATABASE app_staging;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Add your production database schema here
-- Example:
-- CREATE TABLE your_table_name (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     -- Add your columns here
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
--     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );