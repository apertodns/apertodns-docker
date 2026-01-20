# ============================================================================
# ApertoDNS Updater - Lightweight DDNS Client
# ============================================================================
# A minimal Docker image for automatic DDNS updates with ApertoDNS
#
# Features:
#   - Ultra-lightweight: <15MB (Alpine Linux + pure shell)
#   - Multi-architecture: linux/amd64, linux/arm64, linux/arm/v7
#   - Security: Runs as non-root user, read-only filesystem compatible
#   - Smart updates: Only sends requests when IP actually changes
#   - DynDNS2 compatible: Works with standard protocol responses
#
# Repository: https://github.com/apertodns/apertodns-docker
# Docker Hub: https://hub.docker.com/r/apertodns/updater
# ============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Final image
# Using Alpine 3.19 for minimal footprint (~7MB base)
# -----------------------------------------------------------------------------
FROM alpine:3.19

# Metadata labels following OCI specification
LABEL maintainer="ApertoDNS <support@apertodns.com>"
LABEL org.opencontainers.image.title="ApertoDNS Updater"
LABEL org.opencontainers.image.description="Lightweight DDNS updater daemon for ApertoDNS"
LABEL org.opencontainers.image.url="https://www.apertodns.com"
LABEL org.opencontainers.image.documentation="https://github.com/apertodns/apertodns-docker"
LABEL org.opencontainers.image.source="https://github.com/apertodns/apertodns-docker"
LABEL org.opencontainers.image.vendor="ApertoDNS"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="2.0.7"

# -----------------------------------------------------------------------------
# Install minimal dependencies
# - curl: HTTP client for IP detection and API calls
# - ca-certificates: HTTPS support
# - tzdata: Timezone support for logging
# -----------------------------------------------------------------------------
RUN apk add --no-cache \
    curl \
    ca-certificates \
    tzdata \
    # Clean up apk cache (already done by --no-cache, but explicit for clarity)
    && rm -rf /var/cache/apk/* /tmp/*

# -----------------------------------------------------------------------------
# Security: Create non-root user
# Using explicit UID/GID for consistency across environments
# -----------------------------------------------------------------------------
RUN addgroup -g 1000 apertodns \
    && adduser -u 1000 -G apertodns -s /bin/sh -D apertodns

# Set working directory
WORKDIR /app

# -----------------------------------------------------------------------------
# Copy update script
# The script handles all DDNS update logic
# -----------------------------------------------------------------------------
COPY update.sh /app/update.sh
RUN chmod 755 /app/update.sh

# -----------------------------------------------------------------------------
# Create data directory for IP cache
# This allows smart updates (only update when IP changes)
# Mount as volume for persistence across container restarts
# -----------------------------------------------------------------------------
RUN mkdir -p /app/data \
    && chown -R apertodns:apertodns /app

# -----------------------------------------------------------------------------
# Switch to non-root user for security
# The container will run entirely as this user
# -----------------------------------------------------------------------------
USER apertodns

# -----------------------------------------------------------------------------
# Environment variables configuration
# See README.md for full documentation
# -----------------------------------------------------------------------------
ENV TOKEN="" \
    DOMAINS="" \
    UPDATE_INTERVAL="300" \
    DETECT_IPV6="false" \
    LOG_LEVEL="info" \
    TZ="UTC"

# -----------------------------------------------------------------------------
# Health check configuration
# Verifies the update loop is running and last update was recent
# - interval: Check every 60 seconds
# - timeout: Fail if check takes >10 seconds
# - start-period: Allow 30s for initial startup
# - retries: Mark unhealthy after 3 consecutive failures
# -----------------------------------------------------------------------------
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD [ -f /app/data/last_update ] && [ $(($(date +%s) - $(cat /app/data/last_update))) -lt $((UPDATE_INTERVAL * 3)) ] || exit 1

# -----------------------------------------------------------------------------
# Container entrypoint
# No CMD needed - script runs indefinitely
# -----------------------------------------------------------------------------
ENTRYPOINT ["/app/update.sh"]
