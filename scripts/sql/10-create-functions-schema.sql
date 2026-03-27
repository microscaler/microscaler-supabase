-- Create supabase_functions schema for Edge Functions webhooks
CREATE SCHEMA IF NOT EXISTS supabase_functions;
ALTER SCHEMA supabase_functions OWNER TO postgres;
GRANT USAGE ON SCHEMA supabase_functions TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA supabase_functions GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA supabase_functions GRANT ALL ON FUNCTIONS TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA supabase_functions GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
GRANT ALL ON SCHEMA supabase_functions TO supabase_functions_admin;
