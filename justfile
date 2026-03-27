# microscaler-supabase justfile
# Usage: just <recipe>
# Side-clone workflow: use this repo next to PriceWhisperer/seasame-idam; when stable, add as submodule.

default:
    just --list

# Build Postgres Docker image (default tag 17-duckdb-supabase-v2)
build-postgres tag="17-duckdb-supabase-v2":
    ./scripts/build-postgres-docker.sh "{{tag}}"

# Verify Supabase users/roles (run after postgres is up)
setup-supabase-users:
    ./scripts/setup-supabase-users.sh

# Apply full stack (namespace, deployment-config, PVs, claims, postgres, postgres-meta, postgres-exporter, parquet-lake)
apply:
    kubectl apply -k k8s/data

# Apply only namespace + PVs + claims (no postgres yet)
apply-minimal:
    kubectl apply -f k8s/data/namespace.yaml
    kubectl apply -f k8s/data/persistent-volumes.yaml
    kubectl apply -f k8s/data/claims.yaml

# Kustomize build (dry-run; check generated manifests)
build-kustomize:
    kubectl kustomize k8s/data

# Helm chart lint
helm-lint:
    helm lint helm/microscaler-supabase

# Helm template (dry-run render; set ns= for another namespace)
helm-template ns="data":
    helm template test helm/microscaler-supabase -n "{{ns}}"

# Skaffold build (Postgres image + Helm chart OCI via Octopilot buildpacks); requires skaffold + docker
skaffold-build:
    skaffold build

# Initialize git repo (run once when creating the repo; use side clone until stable, then submodule)
git-init:
    git init
    git add .
    echo "Add remote and push when ready. Use as side clone until stable, then: git submodule add <url> microscaler-supabase"
