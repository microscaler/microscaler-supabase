#!/bin/bash
# Verify Supabase PostgreSQL users and databases (roles created by postgres init ConfigMap).
# Run after PostgreSQL is up. Uses scripts/sql/*.sql if init did not run.
# NAMESPACE defaults to data. POSTGRES_PASSWORD defaults to postgres.

set -e

NAMESPACE="${NAMESPACE:-data}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="${SCRIPT_DIR}/sql"

echo "Waiting for PostgreSQL pod (namespace=$NAMESPACE)..."
POD=""
for i in $(seq 1 30); do
  POD=$(kubectl get pod -n "$NAMESPACE" -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [ -n "$POD" ]; then
    READY=$(kubectl get pod -n "$NAMESPACE" "$POD" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)
    [ "$READY" = "True" ] && break
  fi
  sleep 2
done

if [ -z "$POD" ] || [ "$READY" != "True" ]; then
  echo "ERROR: PostgreSQL pod not ready"
  exit 1
fi

exec_sql_file() {
  local db=$1
  local f=$2
  kubectl exec -n "$NAMESPACE" "$POD" -i -- env PGPASSWORD="$POSTGRES_PASSWORD" psql -U postgres -h 127.0.0.1 -d "$db" < "$f" 2>&1 | grep -v "Defaulted container" | grep -v "NOTICE:" || true
}

if [ -d "$SQL_DIR" ]; then
  for f in "$SQL_DIR"/??-*.sql; do
    [ -f "$f" ] && echo "Running $(basename "$f")..." && exec_sql_file postgres "$f"
  done
fi

echo "Verifying roles..."
kubectl exec -n "$NAMESPACE" "$POD" -- env PGPASSWORD="$POSTGRES_PASSWORD" psql -U postgres -h 127.0.0.1 -d postgres -tAc "SELECT COUNT(*) FROM pg_roles WHERE rolname IN ('anon','service_role','authenticated','authenticator');" 2>/dev/null
echo "Supabase PostgreSQL setup complete."
