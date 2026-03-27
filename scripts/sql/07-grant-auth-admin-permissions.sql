-- Grant permissions to supabase_auth_admin (GoTrue)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
        GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
        GRANT CREATE ON SCHEMA public TO supabase_auth_admin;
        GRANT ALL ON ALL TABLES IN SCHEMA public TO supabase_auth_admin;
        GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO supabase_auth_admin;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO supabase_auth_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO supabase_auth_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO supabase_auth_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO supabase_auth_admin;
        GRANT USAGE ON SCHEMA auth TO supabase_auth_admin;
        GRANT CREATE ON SCHEMA auth TO supabase_auth_admin;
        ALTER SCHEMA auth OWNER TO supabase_auth_admin;
        GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin;
        GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO supabase_auth_admin;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA auth TO supabase_auth_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON TABLES TO supabase_auth_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON SEQUENCES TO supabase_auth_admin;
        ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON FUNCTIONS TO supabase_auth_admin;
        DO $factor_type$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_type WHERE typname = 'factor_type' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth')) THEN
                CREATE TYPE auth.factor_type AS ENUM ('totp', 'webauthn', 'phone');
                ALTER TYPE auth.factor_type OWNER TO supabase_auth_admin;
            ELSE
                ALTER TYPE auth.factor_type OWNER TO supabase_auth_admin;
            END IF;
        END $factor_type$;
    END IF;
END $$;
