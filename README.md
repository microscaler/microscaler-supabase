# microscaler-supabase

Unified Supabase stack for Microscaler services (RERP, seasame-idam, etc.). Fully externalised; use as a **side clone** (or later as a submodule).

## Contents

- **docker/postgres/** — Dockerfile for Supabase PostgreSQL 17 with pg_duckdb, pgvector, timescaledb.
- **helm/microscaler-supabase/** — Helm chart (preferred install). **Ports / services:** see [helm/microscaler-supabase/README.md](helm/microscaler-supabase/README.md#ports-and-services) (Postgres `5432` / default NodePort `30432`, postgres-meta `7808`, postgres-exporter `9187`, plus infra ConfigMap placeholders for a future full Supabase stack).
- **k8s/data/** — Namespace, deployment-configuration (Supabase-only infra-config + infra-secrets), PVs, PVCs, postgres (Deployment + init ConfigMap + Service), postgres-config, postgres-meta, postgres-exporter, parquet-lake. Optional full stack (gotrue, postgrest, realtime, storage-api, supabase-studio, supavisor, edge-runtime) can be added with more env keys.
- **scripts/** — build-postgres-docker.sh, setup-supabase-users.sh, sql/ (01–11 Supabase roles/schemas).

## Side-clone workflow (current)

Use as a **side clone** next to RERP or seasame-idam:

```bash
cd /path/to/microscaler
git clone <microscaler-supabase-repo-url> microscaler-supabase
cd microscaler-supabase
```

1. **Secrets:** `k8s/data/deployment-configuration/profiles/dev/application.secrets.env` is included with plaintext dev values. For production, replace with SOPS-encrypted or copy from RERP. See `application.secrets.env.example` for required keys.
2. **Node name:** Edit `k8s/data/persistent-volumes.yaml` and set nodeAffinity hostname to your Kind node (e.g. `RERP-control-plane`, `sesame-idam-control-plane`, or `supabase-control-plane`).
3. **Build Postgres:** `just build-postgres` (default image: `casibbald/postgres:17-duckdb-supabase-v2`).
4. **Apply:** `just apply` (or `kubectl apply -k k8s/data`). Ensure Kind is up and host paths for PVs exist.
5. **Optional:** `just setup-supabase-users` to verify SQL roles.

## Overlays (per-consumer)

- **k8s/overlays/seasame-idam** — PVs patched for Kind cluster `sesame-idam` (node `sesame-idam-control-plane`, hostPath `/mnt/sesame-idam-data/postgres` and `parquet-lake`). From seasame-idam run: `just supabase-apply` (applies from this repo with this overlay).

## Consuming from another repo

- **Side clone:** Keep microscaler-supabase as a sibling. From consumer (e.g. seasame-idam): `just supabase-apply` (cd to microscaler-supabase and `kubectl apply -k k8s/overlays/<consumer>`). App config: DB host `postgres.data.svc.cluster.local`.
- **Later (submodule):** `git submodule add <url> microscaler-supabase`; same apply flow.
- Use image `casibbald/postgres:17-duckdb-supabase-v2` or build from this repo.

## Origin

Moved from RERP: docker/postgres, k8s/data (postgres stack, deployment-configuration subset), scripts (build-postgres-docker.sh, setup-supabase-users.sh, sql/).
