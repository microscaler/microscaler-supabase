-- Ensure postgres superuser password is set
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'postgres') THEN
        ALTER ROLE postgres WITH PASSWORD 'postgres';
    END IF;
END $$;
