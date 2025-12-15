# --- Build Stage ---
    FROM rust:1.77-slim-bullseye AS builder

    WORKDIR /usr/src/app

    # Copy files
    COPY . .

    # Build release binary
    # We use --locked to ensure reproducible builds from Cargo.lock
    RUN cargo build --release --locked

    # --- Runtime Stage ---
    FROM debian:bullseye-slim

    # Install minimal runtime dependencies
    RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

    WORKDIR /app

    # Copy the compiled binary and the persistent data directory
    COPY --from=builder /usr/src/app/target/release/asdf-vanity-grinder .

    # Create directory for persistent data (matching Render mount path)
    RUN mkdir -p /data

    # Expose the internal port for the HTTP server
    EXPOSE 8080

    # Command to start the pool server
    # Note: We use environment variables (VANITY_*) which Render will inject.
    CMD ["./asdf-vanity-grinder", "pool", \
         "--port", "8080", \
         "--bind", "0.0.0.0", \
         "--file", "/data/vanity_pool.json", \
         "--min-pool", "${VANITY_MIN_POOL}", \
         "--api-key", "${VANITY_API_KEY}", \
         "--threads", "${VANITY_THREADS}"]
