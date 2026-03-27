-- Create Supabase admin users
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        CREATE ROLE supabase_admin WITH LOGIN PASSWORD 'postgres' SUPERUSER CREATEDB CREATEROLE;
    ELSE
        ALTER ROLE supabase_admin WITH PASSWORD 'postgres';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
        CREATE ROLE supabase_auth_admin WITH LOGIN PASSWORD 'postgres';
    ELSE
        ALTER ROLE supabase_auth_admin WITH PASSWORD 'postgres';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        CREATE ROLE supabase_storage_admin WITH LOGIN PASSWORD 'postgres';
    ELSE
        ALTER ROLE supabase_storage_admin WITH PASSWORD 'postgres';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_functions_admin') THEN
        CREATE ROLE supabase_functions_admin WITH LOGIN PASSWORD 'postgres' NOINHERIT CREATEROLE;
    ELSE
        ALTER ROLE supabase_functions_admin WITH PASSWORD 'postgres';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pgbouncer') THEN
        CREATE ROLE pgbouncer WITH LOGIN PASSWORD 'postgres';
    ELSE
        ALTER ROLE pgbouncer WITH PASSWORD 'postgres';
    END IF;
END $$;
