-- Create anon role for PostgREST
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN NOINHERIT;
        GRANT USAGE ON SCHEMA public TO anon;
        GRANT USAGE ON SCHEMA storage TO anon;
        GRANT USAGE ON SCHEMA auth TO anon;
    END IF;
END $$;
