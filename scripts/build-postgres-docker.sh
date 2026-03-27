#!/usr/bin/env bash
# Build PostgreSQL Docker image with Supabase + analytical extensions
# Usage: ./scripts/build-postgres-docker.sh [tag]
# Default tag: 17-duckdb-supabase-v2. Run from repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

IMAGE_NAME="${IMAGE_NAME:-casibbald/postgres}"
DEFAULT_TAG="17-duckdb-supabase-v2"
TAG="${1:-${DEFAULT_TAG}}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"
DOCKERFILE="docker/postgres/Dockerfile"

if [[ ! -f "$DOCKERFILE" ]]; then
  echo "Error: Dockerfile not found: $DOCKERFILE" >&2
  exit 1
fi

echo "Building PostgreSQL image: ${FULL_IMAGE_NAME}"
echo "Platform: linux/amd64 (build may take 30+ min for pg_duckdb)"
docker build --platform linux/amd64 -t "${FULL_IMAGE_NAME}" -f "$DOCKERFILE" .
echo "Built: ${FULL_IMAGE_NAME}"
echo "Push with: docker push ${FULL_IMAGE_NAME}"
