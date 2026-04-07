# microscaler-supabase

Unified Supabase stack for Microscaler services (RERP, seasame-idam, etc.). Fully externalised; use as a **side clone** (or later as a submodule).

## Why this Postgres image

The database is not stock Postgres. It is **[`supabase/postgres:17.6.1.035`](https://github.com/supabase/postgres)** as the runtime base so you keep the **full Supabase operator surface** (Vault, `pg_cron`, `pg_net`, `pgsodium`, `pg_stat_statements`, `pgaudit`, and the rest of the curated preload set the chart expects), while layering **analytical and ML-friendly extensions** built in a multi-stage image (see [`docker/postgres/Dockerfile`](docker/postgres/Dockerfile)).

That combination matters when you want **one cluster** for product data *and* heavy reads over **Parquet / columnar / time-series** workloads without standing up a separate warehouse, and for **vector search** next to relational Supabase schemas.

| Layer | What is included | Benefit |
|--------|------------------|---------|
| **Base image** | Supabase Postgres 17.6.x image | Same security posture, extensions, and compatibility as managed Supabase Postgres; fits Auth, Studio, and ecosystem tooling. |
| **DuckDB (`pg_duckdb`)** | Extension + **DuckDB 1.4.1** `libduckdb`; `duckdb.enable_optimizer` on; preloaded with Timescale and stats | Run **DuckDB inside Postgres**: analytical SQL, **Parquet-friendly** paths (e.g. with chart-mounted **`/data/parquet`** for lake files), fewer ETL hops to a separate OLAP system. |
| **pgvector** | `vector` extension enabled on init | **Embeddings and similarity search** in the same DB as your app data (RAG, recommendations, semantic search). |
| **TimescaleDB** | Extension enabled on init; preloaded | **Hypertables and time-series** patterns (metrics, events, IoT-style data) with familiar SQL. |
| **Init extensions** | `pgcrypto`, `pg_trgm`, `unaccent` created on first init | Crypto/digest helpers, fuzzy text, and accent-insensitive search for typical app features. |
| **Build toolchain (Arrow/Parquet)** | Apache **Arrow & Parquet** dev libs in the build stage | Supports compiling Parquet-related extension code; final runtime ships the copied extensions above. |
| **Helm stack** | Parquet PVC mounted read-only at `/data/parquet` (optional) | Gives Postgres a stable place for **Hive-style Parquet layouts** to pair with analytical queries. |

**Shipped vs build-only:** only **pg_duckdb**, **pgvector**, and **TimescaleDB** artifacts are copied into the final image. Re-run `just build-postgres` (or CI) after changing [`docker/postgres/Dockerfile`](docker/postgres/Dockerfile); builds are multi-stage and can take a long time on first run.

### Optional extensions not in the runtime image (yet)

The Dockerfile still contains **optional build steps** for **`cstore_fdw`**, **`parquet_fdw`**, and **`pg_hint_plan`**. They are **not** copied into the published image today, and the builds are allowed to fail without failing the whole image (`|| echo "Warning: …"`).

| Extension | Purpose | Value vs what we already ship |
|-----------|---------|-------------------------------|
| **cstore_fdw** | Columnar foreign tables (legacy Citus cstore format). | Largely **superseded** for analytical scans by **pg_duckdb** and for time-oriented data by **TimescaleDB**; upstream is a poor fit for **PostgreSQL 17** without real porting. |
| **parquet_fdw** | FDW to read **Parquet files** as external tables. | **Overlaps** with **pg_duckdb** + **`/data/parquet`**: DuckDB-in-Postgres already targets Parquet and lake-style layouts with a more actively evolved path. |
| **pg_hint_plan** | **Optimizer hints** for bad plans (join order, indexes, etc.). | **Orthogonal** to analytics extensions: occasional **ops** value, not core to the “Supabase + DuckDB + vectors + time-series” story. |

**Policy:** we will **fold these into the runtime image** (enable builds, fix Docker `COPY`, init SQL, and preload policy as needed) **once they are maintained upstream** for our target Postgres major—i.e. reliable **PG 17** (or whatever the Supabase base tracks), clear release branches or tags, and Arrow/API alignment where relevant—so we are not carrying private forks or brittle `sed`-only hacks. Until then, **pg_duckdb**, **TimescaleDB**, and **pgvector** remain the supported analytical surface.

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

- **k8s/overlays/hauliage** — PV `nodeAffinity` for Kind cluster `hauliage` (node `hauliage-control-plane`). Consumed by the Hauliage app repo’s `k8s/data/supabase` kustomization (requires this repo as a side clone next to `ai/`).
- **k8s/overlays/seasame-idam** — PVs patched for Kind cluster `sesame-idam` (node `sesame-idam-control-plane`, hostPath `/mnt/sesame-idam-data/postgres` and `parquet-lake`). From seasame-idam run: `just supabase-apply` (applies from this repo with this overlay).

## Consuming from another repo

- **Side clone:** Keep microscaler-supabase as a sibling of `ai/` (or your monorepo root). Example layout: `microscaler/ai/hauliage` and `microscaler/microscaler-supabase`. Hauliage’s Tiltfile runs `kustomize build k8s/data/supabase`, which points at `k8s/overlays/hauliage` in this repo.
- **Kustomize from consumer:** `kubectl apply -k` on `k8s/overlays/<consumer>` (e.g. `hauliage`, `seasame-idam`, `pricewhisperer`). App config: DB host `postgres.data.svc.cluster.local`.
- **Helm (local chart path):** `helm upgrade --install supabase ./helm/microscaler-supabase -n data --create-namespace` from a checkout of this repo. Values can override `persistence.nodeHostname`, images, and secrets; see [helm/microscaler-supabase/README.md](helm/microscaler-supabase/README.md).
- **Helm from Git (no submodule):** add a chart dependency or CI step that pins a Git ref, e.g. `helm install supabase oci://<registry>/charts/microscaler-supabase` once the chart is published by [Release](.github/workflows/release.yml), or vendor the `helm/microscaler-supabase` directory via submodule / sparse checkout.
- **Later (submodule):** `git submodule add <url> microscaler-supabase`; same apply flow.
- Use image `casibbald/postgres:17-duckdb-supabase-v2` or build from this repo.

## Release

Run [**Release**](.github/workflows/release.yml) from the Actions tab (`workflow_dispatch`, patch/minor/major). It bumps `version` in [`helm/microscaler-supabase/Chart.yaml`](helm/microscaler-supabase/Chart.yaml), pushes a `v*` tag, and opens a GitHub Release. Configure secret **`REPO_PAT`** (`contents:write`) so the version commit retriggers CI (same pattern as [cronjob-log-monitor](https://github.com/octopilot/cronjob-log-monitor/blob/main/.github/workflows/release.yml) / [octopilot-workflows](https://github.com/octopilot/octopilot-workflows/blob/main/.github/workflows/workflow-release.yml)).

## Origin

Moved from RERP: docker/postgres, k8s/data (postgres stack, deployment-configuration subset), scripts (build-postgres-docker.sh, setup-supabase-users.sh, sql/).
