-- Create authenticated role (used by Supabase auth)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN NOINHERIT;
        GRANT USAGE ON SCHEMA public TO authenticated;
        GRANT USAGE ON SCHEMA storage TO authenticated;
        GRANT USAGE ON SCHEMA auth TO authenticated;
    END IF;
END $$;
