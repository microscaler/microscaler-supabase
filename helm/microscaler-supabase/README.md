# microscaler-supabase Helm chart

Helm packaging for the Kubernetes stack previously defined under `k8s/data` (Postgres with Supabase-oriented init SQL, postgres-meta, postgres-exporter, optional parquet lake PVC).

## Prerequisites

- Kubernetes 1.24+
- Helm 3.14+ (recommended for `values.schema.json` validation)
- For `persistence.mode=staticPv`: a node whose `kubernetes.io/hostname` matches `persistence.nodeHostname`, with writable host paths

## Quick install

```bash
helm upgrade --install supabase ./helm/microscaler-supabase -n data --create-namespace
```

Service DNS (in-cluster): `postgres.<namespace>.svc.cluster.local:5432`.

The default `infraConfig.data` entries use the placeholder `NAMESPACE` in hostnames; the chart replaces it with `Release.Namespace` when rendering the `infra-config` ConfigMap.

## Persistence modes

| Mode | PV | PVC | Use case |
|------|----|-----|----------|
| `staticPv` | Yes (hostPath + nodeAffinity) | Yes | Parity with legacy `k8s/data` / Kind |
| `dynamic` | No | Yes | Cluster default `StorageClass` / provisioner |
| `existingClaim` | No | No (chart) | Pre-created claims; set `persistence.existingClaim.postgres` (and `parquet` if you mount parquet) |

With `existingClaim`, set `persistence.existingClaim.postgres` to the PVC name. If `parquetLake.enabled` is true and you want the parquet mount, set `persistence.existingClaim.parquet` as well; otherwise omit `parquet` to skip the parquet volume.

## Secrets

### Chart-managed secret (`secret.create: true`, default)

The chart creates `infra-secrets` with keys used by workloads, plus **`POSTGRES_EXPORTER_DATA_SOURCE_URI`** (built from `secret.data` and `postgresExporter.connection`). **Dev defaults in `values.yaml` are insecure**; override for any real environment.

### Existing secret (`secret.create: false`)

Set `secret.existingSecret` to the Secret name. The Secret must include at least:

- `POSTGRES_USER`, `POSTGRES_PASSWORD`
- `POSTGRES_META_DB_PASSWORD`, `POSTGRES_META_DB_PASSWORD_ENCRYPTION_KEY`
- `POSTGRES_EXPORTER_DATA_SOURCE_URI` (or the key name in `secret.existingSecretKeys.postgresExporterDataSourceUri`)

When not using `secret.create`, set **`postgres.initPasswords.default`** to the password used for Supabase roles in `postgres-init` SQL (must align with your DB, typically the same as the superuser / role passwords you configure).

## Kustomize to Helm mapping

| Kustomize | Helm |
|-----------|------|
| `kubectl apply -k k8s/data` | `helm upgrade --install ... ./helm/microscaler-supabase -n data` |
| `k8s/overlays/seasame-idam` PV patches | `-f values-seasame-idam.yaml` (or your own values for `persistence.nodeHostname`, `hostPath`) |
| `application.properties` | `infraConfig.data` + `infraConfig.extra` |
| `application.secrets.env` | `secret.data` or external Secret |

## Optional components

- `postgresMeta.enabled`
- `postgresExporter.enabled`
- `parquetLake.enabled` and `parquetLake.createConfigMap`

## Upgrades and uninstall

- Changing PVC size may require provider-specific steps.
- PVs use `Retain` by default in `staticPv`; `helm uninstall` does not delete retained PVs—clean them up manually if needed.

## Lint / template

```bash
helm lint ./helm/microscaler-supabase
helm template test ./helm/microscaler-supabase -n data
```

## CI (GitHub Actions + Octopilot)

The repo root [`skaffold.yaml`](../../skaffold.yaml) lists the Postgres image (`docker/postgres`) and this chart (`helm/microscaler-supabase`). GitHub Actions uses [`octopilot/actions`](https://github.com/octopilot/actions): `detect-contexts`, `lint`, `test`, `integration-build-artifact`, and `merge-build-results` (same pattern as `octopilot/cronjob-log-monitor`). Chart packages are built with the Octopilot Jammy base builder and helm buildpack; integration pushes use ephemeral `ttl.sh` refs from a generated UUID.

## Examples

- Kind / sesame-idam-style paths: see `values-seasame-idam.yaml`.
