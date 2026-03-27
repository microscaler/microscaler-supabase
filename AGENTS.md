# microscaler-supabase Agent Notes

## Purpose

Unified Supabase stack (Postgres, postgres-meta, parquet-lake, etc.) for Microscaler services. Use as **side clone** next to PriceWhisperer or seasame-idam; when stable, integrate as a git submodule.

## Layout

- **skaffold.yaml** — Source of truth for Octopilot `detect-contexts`: Postgres image (`docker/postgres` + Dockerfile) and Helm chart (`helm/microscaler-supabase` via `ghcr.io/octopilot/builder-jammy-base` + helm buildpack). CI builds both with `octopilot/actions/integration-build-artifact`. Override image registry prefixes in `skaffold.yaml` if not using `ghcr.io/casibbald/...`.
- **docker/postgres/** — Dockerfile for Postgres 17 with pg_duckdb, pgvector, timescaledb. Image: `casibbald/postgres:17-duckdb-supabase-v2` (local script); CI/Skaffold uses the image name declared in `skaffold.yaml`.
- **helm/microscaler-supabase/** — Preferred install path: Helm chart (values-driven secrets/config, persistence modes `staticPv` / `dynamic` / `existingClaim`). See chart `README.md` and `values-seasame-idam.yaml`.
- **.github/workflows/release.yml** — Manual `workflow_dispatch` release: bumps `helm/microscaler-supabase/Chart.yaml` `version`, commits, tags `v*`, creates GitHub Release (same shape as `octopilot/cronjob-log-monitor` release flow). Requires org/repo secret **`REPO_PAT`** (`contents:write`) so the push triggers CI — same as [octopilot-workflows `workflow-release.yml`](https://github.com/octopilot/octopilot-workflows/blob/main/.github/workflows/workflow-release.yml) (GitHub’s default `GITHUB_TOKEN` push does not re-run workflows).
- **.github/workflows/ci.yml** — Octopilot pipeline: `detect-contexts` → `lint` → `test` (Helm/Kind) → UUID for ttl.sh → integration matrix builds → `merge-build-results` verify. **Dockerfile Skaffold artifacts:** `octopilot/actions/integration-build-artifact` runs `op` inside `docker run`; `op` shells out to `docker build` for Dockerfile contexts, but the `ghcr.io/octopilot/op` image usually has no `docker` binary (only the socket). Chart/Pack builds use the Docker Go client and still go through Octopilot. Postgres image rows use **`docker/setup-buildx-action`** + `docker buildx build --push` on the **ubuntu-latest runner** (same ttl.sh tag shape as `op`). For DinD or runners without a socket, see `docker_host` on `octopilot/actions/octopilot` and cronjob-log-monitor workflow comments.
- **k8s/data/** — Legacy Kustomize base (kept for reference and for consumers that have not switched to Helm yet). Same workload intent as the chart; not deprecated until downstream repos migrate.
- **k8s/overlays/** — Per-consumer Kustomize overlays (e.g. `seasame-idam`) that patch PVs (nodeAffinity, hostPath). Equivalent Helm overrides: use chart values or `-f values-seasame-idam.yaml`.
- **scripts/** — build-postgres-docker.sh, setup-supabase-users.sh, sql/ (Supabase roles/schemas).

## Commands (justfile)

- `just build-postgres` — Build Postgres image (default tag 17-duckdb-supabase-v2).
- `just apply` — Apply base stack: `kubectl apply -k k8s/data`.
- `just apply-minimal` — Namespace + PVs + claims only.
- `just helm-lint` — `helm lint` the chart.
- `just helm-template` — Render chart manifests (namespace `data` by default).
- `just skaffold-build` — `skaffold build` (local parity with CI artifacts; needs Skaffold + Docker).
- `just setup-supabase-users` — Verify Supabase users/roles (postgres must be up).
- `just build-kustomize` — Dry-run kustomize build.
- `just git-init` — Init repo (use side clone until stable, then submodule).

## Consuming from seasame-idam

1. Clone microscaler-supabase as sibling: `../microscaler-supabase`.
2. **Helm (recommended):** from this repo, `helm upgrade --install supabase ./helm/microscaler-supabase -n data --create-namespace -f helm/microscaler-supabase/values-seasame-idam.yaml` (or merge those persistence overrides into your own values).
3. **Kustomize (legacy):** from seasame-idam, `just supabase-apply` (runs `kubectl apply -k k8s/overlays/seasame-idam` from microscaler-supabase). Creates namespace `data`, postgres, etc., with PVs patched for Kind cluster `sesame-idam` (node `sesame-idam-control-plane`, hostPath `/mnt/sesame-idam-data/...`).
4. Then `tilt up` in seasame-idam (loads Redis, tooling). Postgres lives in namespace `data`; app connects to `postgres.data.svc.cluster.local`.

## Secrets

- `k8s/data/deployment-configuration/profiles/dev/application.secrets.env` — Required for kustomize (generates infra-secrets). Copy from `application.secrets.env.example` or from PriceWhisperer. Not committed (in .gitignore).

## Conventions

- No shell scripts for operational flows; use `just` and kubectl. Scripts in `scripts/` are for build/setup only.
- Overlays live in this repo so base path is internal; consumers run apply from this repo (e.g. seasame-idam’s `just supabase-apply` cd’s here).
