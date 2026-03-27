-- Create service_role role for PostgREST
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
        GRANT ALL ON SCHEMA public TO service_role;
        GRANT ALL ON SCHEMA storage TO service_role;
        GRANT ALL ON SCHEMA auth TO service_role;
    END IF;
END $$;
