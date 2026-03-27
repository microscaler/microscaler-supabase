-- PostgreSQL Extension Migration Script
-- Usage: kubectl exec -it <postgres-pod> -n data -- psql -U postgres -d postgres -f /tmp/migrations.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "file_fdw";
CREATE EXTENSION IF NOT EXISTS "postgres_fdw";

DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_duckdb;
    RAISE NOTICE 'pg_duckdb extension enabled';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_duckdb not available - build image from docker/postgres/Dockerfile';
END $$;

SELECT extname, extversion FROM pg_extension
WHERE extname IN ('uuid-ossp', 'pgcrypto', 'file_fdw', 'postgres_fdw', 'pg_duckdb')
ORDER BY extname;
