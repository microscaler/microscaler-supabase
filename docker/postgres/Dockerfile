# Custom PostgreSQL image: Supabase base + analytical extensions
# Multi-stage build: compile extensions in postgres:17, then add to Supabase image
# Extensions: pg_duckdb, pgvector, cstore_fdw, parquet_fdw, pg_hint_plan, timescaledb
# Source: PriceWhisperer/docker/postgres/Dockerfile (moved to microscaler-supabase)

# Stage 1: Builder base with all dependencies
FROM postgres:17 AS builder

# Install build dependencies and libraries
# Add Apache Arrow APT repository for libarrow-dev and libparquet-dev
RUN apt-get update && apt-get install -y \
    ca-certificates \
    lsb-release \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Add Apache Arrow APT repository (for Debian/Ubuntu)
# See: https://arrow.apache.org/install/
RUN apt-get update && \
    wget https://packages.apache.org/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb && \
    apt-get install -y -V ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb && \
    rm -f ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb && \
    rm -rf /var/lib/apt/lists/*

# Install all build dependencies including Apache Arrow libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    ninja-build \
    python3 \
    postgresql-server-dev-all \
    postgresql-contrib \
    pkg-config \
    wget \
    unzip \
    ca-certificates \
    zlib1g-dev \
    liblz4-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libzstd-dev \
    liblzma-dev \
    libbz2-dev \
    libsnappy-dev \
    libbrotli-dev \
    libsqlite3-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libxml2-dev \
    libgeos-dev \
    libproj-dev \
    libgdal-dev \
    libfftw3-dev \
    libarrow-dev \
    libparquet-dev \
    && rm -rf /var/lib/apt/lists/*

# Set build directory
WORKDIR /tmp

# Install DuckDB library (amd64)
RUN echo "Installing DuckDB library for linux-amd64" && \
    wget --no-check-certificate -q https://github.com/duckdb/duckdb/releases/download/v1.4.1/libduckdb-linux-amd64.zip -O /tmp/duckdb.zip && \
    unzip -q /tmp/duckdb.zip -d /tmp/duckdb && \
    mkdir -p /usr/local/lib && \
    cp /tmp/duckdb/libduckdb.so /usr/local/lib/libduckdb.so && \
    chmod 755 /usr/local/lib/libduckdb.so && \
    rm -rf /tmp/duckdb /tmp/duckdb.zip && \
    ldconfig || true

# ======================================================
# Stage 1a: Build pg_duckdb extension
# ======================================================
RUN git clone --depth 1 --recursive https://github.com/duckdb/pg_duckdb.git /tmp/pg_duckdb && \
    cd /tmp/pg_duckdb && \
    export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH && \
    export DUCKDB_LIBRARY_PATH=/usr/local/lib/libduckdb.so && \
    PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config && \
    if [ ! -f "$PG_CONFIG" ]; then \
        PG_CONFIG=$(which pg_config || find /usr -name pg_config 2>/dev/null | head -1); \
    fi && \
    echo "Using PG_CONFIG: $PG_CONFIG" && \
    $PG_CONFIG --version && \
    sed -i '/^PG_CXXFLAGS/s|$| -I/usr/include/unicode|' Makefile.global || \
    echo "PG_CXXFLAGS += -I/usr/include/unicode" >> Makefile.global || true && \
    sed -i '/^SHLIB_LINK/s|$| -licuuc -licudata|' Makefile.global || \
    echo "SHLIB_LINK += -licuuc -licudata" >> Makefile.global || true && \
    export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc) && \
    export DUCKDB_EXTENSION_VERBOSE=1 && \
    make PG_CONFIG=$PG_CONFIG VERBOSE=1 && \
    make PG_CONFIG=$PG_CONFIG install && \
    cd / && \
    rm -rf /tmp/pg_duckdb

# ======================================================
# Stage 1b: Build pgvector
# ======================================================
RUN git clone --depth 1 https://github.com/pgvector/pgvector.git /tmp/pgvector && \
    cd /tmp/pgvector && \
    PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config && \
    make PG_CONFIG=$PG_CONFIG && \
    make PG_CONFIG=$PG_CONFIG install && \
    cd / && \
    rm -rf /tmp/pgvector

# ======================================================
# Stage 1c: Build cstore_fdw (optional)
# ======================================================
RUN git clone --depth 1 https://github.com/citusdata/cstore_fdw.git /tmp/cstore_fdw && \
    cd /tmp/cstore_fdw && \
    PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config && \
    sed -i 's/PostgreSQL 9.3 to 13 is required/PostgreSQL 9.3 to 17 is required/' Makefile || true && \
    sed -i '/^PG_MINVERSION/s/13/17/' Makefile || true && \
    sed -i '/^PG_MAXVERSION/s/13/17/' Makefile || true && \
    (make PG_CONFIG=$PG_CONFIG && make PG_CONFIG=$PG_CONFIG install || echo "Warning: cstore_fdw build failed") && \
    cd / && \
    rm -rf /tmp/cstore_fdw || true

# ======================================================
# Stage 1d: Build parquet_fdw (optional)
# ======================================================
RUN git clone --depth 1 https://github.com/adjust/parquet_fdw.git /tmp/parquet_fdw && \
    cd /tmp/parquet_fdw && \
    PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config && \
    sed -i 's/context->methods->alloc(context, size)/context->methods->alloc(context, size, 0)/' src/common.cpp || true && \
    (make PG_CONFIG=$PG_CONFIG && make PG_CONFIG=$PG_CONFIG install || echo "Warning: parquet_fdw build failed") && \
    cd / && \
    rm -rf /tmp/parquet_fdw || true

# ======================================================
# Stage 1e: Build pg_hint_plan (optional)
# ======================================================
RUN git clone --depth 1 https://github.com/ossc-db/pg_hint_plan.git /tmp/pg_hint_plan && \
    cd /tmp/pg_hint_plan && \
    PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config && \
    (make PG_CONFIG=$PG_CONFIG && make PG_CONFIG=$PG_CONFIG install || echo "Warning: pg_hint_plan build failed") && \
    cd / && \
    rm -rf /tmp/pg_hint_plan || true

# ======================================================
# Stage 1f: Build timescaledb
# ======================================================
RUN git clone --depth 1 https://github.com/timescale/timescaledb.git /tmp/timescaledb && \
    cd /tmp/timescaledb && \
    ./bootstrap -DCMAKE_BUILD_TYPE=Release && \
    cd build && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/timescaledb

# ======================================================
# Stage 2: Supabase PostgreSQL runtime image
# ======================================================
FROM supabase/postgres:17.6.1.035

# Copy DuckDB library from builder
COPY --from=builder /usr/local/lib/libduckdb.so /usr/local/lib/libduckdb.so
RUN ldconfig || true

# Copy all extension files from builder
COPY --from=builder /usr/lib/postgresql/17/lib/pg_duckdb.so /usr/lib/postgresql/17/lib/
COPY --from=builder /usr/lib/postgresql/17/lib/vector.so /usr/lib/postgresql/17/lib/
COPY --from=builder /usr/lib/postgresql/17/lib/timescaledb*.so /usr/lib/postgresql/17/lib/
COPY --from=builder /usr/share/postgresql/17/extension/pg_duckdb.control /usr/share/postgresql/17/extension/
COPY --from=builder /usr/share/postgresql/17/extension/pg_duckdb*.sql /usr/share/postgresql/17/extension/
COPY --from=builder /usr/share/postgresql/17/extension/vector.control /usr/share/postgresql/17/extension/
COPY --from=builder /usr/share/postgresql/17/extension/vector*.sql /usr/share/postgresql/17/extension/
COPY --from=builder /usr/share/postgresql/17/extension/timescaledb*.control /usr/share/postgresql/17/extension/
COPY --from=builder /usr/share/postgresql/17/extension/timescaledb*.sql /usr/share/postgresql/17/extension/

# ======================================================
# Stage 3: Initialization Scripts
# ======================================================
RUN echo '#!/bin/bash\n\
set -e\n\
POSTGRES_USER="${POSTGRES_USER:-postgres}"\n\
POSTGRES_DB="${POSTGRES_DB:-${POSTGRES_USER:-postgres}}"\n\
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL\n\
    CREATE EXTENSION IF NOT EXISTS pg_duckdb;\n\
    CREATE EXTENSION IF NOT EXISTS vector;\n\
    CREATE EXTENSION IF NOT EXISTS timescaledb;\n\
    CREATE EXTENSION IF NOT EXISTS pgcrypto;\n\
    CREATE EXTENSION IF NOT EXISTS pg_trgm;\n\
    CREATE EXTENSION IF NOT EXISTS unaccent;\n\
    ALTER DATABASE "$POSTGRES_DB" SET duckdb.enable_optimizer = on;\n\
EOSQL\n\
' > /docker-entrypoint-initdb.d/01-enable-extensions.sh && \
    chmod +x /docker-entrypoint-initdb.d/01-enable-extensions.sh

RUN echo "shared_preload_libraries = 'pg_duckdb,pg_stat_statements,timescaledb'" >> /usr/share/postgresql/17/postgresql.conf.sample && \
    echo "duckdb.enable_optimizer = on" >> /usr/share/postgresql/17/postgresql.conf.sample && \
    echo "pg_stat_statements.track = all" >> /usr/share/postgresql/17/postgresql.conf.sample

ENV LD_LIBRARY_PATH=/usr/local/lib

LABEL maintainer="microscaler-supabase"
LABEL description="Supabase PostgreSQL 17 with pg_duckdb, pgvector, timescaledb"
LABEL base_image="supabase/postgres:17.6.1.035"
