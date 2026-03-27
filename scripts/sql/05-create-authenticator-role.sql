-- Create authenticator role for PostgREST
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticator') THEN
        CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'postgres';
        GRANT anon TO authenticator;
        GRANT service_role TO authenticator;
    ELSE
        ALTER ROLE authenticator WITH PASSWORD 'postgres';
    END IF;
END $$;
