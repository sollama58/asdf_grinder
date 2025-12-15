# -----------------------------------
# STAGE 1: Builder (Musl Toolchain)
# -----------------------------------
# Use a specific Rust version and install the musl target toolchain
FROM rust:stable AS builder

# Install musl target
RUN rustup target add x86_64-unknown-linux-musl

WORKDIR /usr/src/app

# Copy source code
COPY . .

# Build the release binary targeting musl (static linking)
# This will produce a self-contained executable.
RUN cargo build --release --target x86_64-unknown-linux-musl

# -----------------------------------
# STAGE 2: Final Runtime Image (Minimal)
# -----------------------------------
# Use an extremely small image like Alpine or a minimal scratch-like image
# Alpine is used here for simplicity as it's common for musl builds
FROM alpine:3.18

# Install minimal OS dependencies if needed (Musl libc is included in the binary)
RUN apk add --no-cache openssl-dev

# Set the working directory
WORKDIR /app

# Copy the statically compiled binary from the builder stage
# The path includes the target we compiled for: x86_64-unknown-linux-musl
COPY --from=builder /usr/src/app/target/x86_64-unknown-linux-musl/release/asdf-vanity-grinder .

# Create persistent data directory
RUN mkdir -p /data

# Expose the internal portttt
EXPOSE 8080

# Command to start the pool server
CMD ["./asdf-vanity-grinder", "pool", \
     "--port", "8080", \
     "--bind", "0.0.0.0", \
     "--file", "/data/vanity_pool.json", \
     "--min-pool", "${VANITY_MIN_POOL}", \
     "--api-key", "${VANITY_API_KEY}", \
     "--threads", "${VANITY_THREADS}"]
