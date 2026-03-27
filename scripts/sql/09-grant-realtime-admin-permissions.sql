-- Grant permissions to supabase_admin for realtime schemas
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        GRANT USAGE ON SCHEMA realtime TO supabase_admin;
        GRANT CREATE ON SCHEMA realtime TO supabase_admin;
        GRANT ALL ON ALL TABLES IN SCHEMA realtime TO supabase_admin;
        GRANT ALL ON ALL SEQUENCES IN SCHEMA realtime TO supabase_admin;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA realtime TO supabase_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA realtime GRANT ALL ON TABLES TO supabase_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA realtime GRANT ALL ON SEQUENCES TO supabase_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA realtime GRANT ALL ON FUNCTIONS TO supabase_admin;
        GRANT USAGE ON SCHEMA _realtime TO supabase_admin;
        GRANT CREATE ON SCHEMA _realtime TO supabase_admin;
        GRANT ALL ON ALL TABLES IN SCHEMA _realtime TO supabase_admin;
        GRANT ALL ON ALL SEQUENCES IN SCHEMA _realtime TO supabase_admin;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA _realtime TO supabase_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA _realtime GRANT ALL ON TABLES TO supabase_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA _realtime GRANT ALL ON SEQUENCES TO supabase_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA _realtime GRANT ALL ON FUNCTIONS TO supabase_admin;
    END IF;
END $$;
