-- Grant permissions to supabase_storage_admin (Storage API)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        GRANT CREATE ON DATABASE postgres TO supabase_storage_admin;
        GRANT USAGE ON SCHEMA storage TO supabase_storage_admin;
        GRANT CREATE ON SCHEMA storage TO supabase_storage_admin;
        ALTER SCHEMA storage OWNER TO supabase_storage_admin;
        GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
        GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA storage TO supabase_storage_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON TABLES TO supabase_storage_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON SEQUENCES TO supabase_storage_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON FUNCTIONS TO supabase_storage_admin;
    END IF;
END $$;
