# ============================================================================
# ApertoDNS CLI - Docker Container
# ============================================================================
# Run the official ApertoDNS CLI without installing Node.js locally
# Perfect for one-off commands, scripting, and CI/CD automation
#
# Features:
#   - No local Node.js installation required
#   - Multi-architecture: linux/amd64, linux/arm64
#   - Persistent config support via volume mount
#   - API key authentication for stateless operations
#   - All CLI commands available (--setup, --domains, --force, --update, etc.)
#
# Repository: https://github.com/apertodns/apertodns
# Docker Hub: https://hub.docker.com/r/apertodns/cli
# ============================================================================

# -----------------------------------------------------------------------------
# Base image: Node.js 22 on Alpine for minimal size
# Alpine provides ~50MB smaller image than debian-based
# -----------------------------------------------------------------------------
FROM node:22-alpine

# Metadata labels following OCI specification
LABEL maintainer="ApertoDNS <support@apertodns.com>"
LABEL org.opencontainers.image.title="ApertoDNS CLI"
LABEL org.opencontainers.image.description="Official ApertoDNS CLI tool in a Docker container"
LABEL org.opencontainers.image.url="https://www.apertodns.com"
LABEL org.opencontainers.image.documentation="https://github.com/apertodns/apertodns"
LABEL org.opencontainers.image.source="https://github.com/apertodns/apertodns"
LABEL org.opencontainers.image.vendor="ApertoDNS"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="2.0.3"

# -----------------------------------------------------------------------------
# SECURITY FIX: Update npm to patch CVE vulnerabilities
# - CVE-2024-21538 (cross-spawn 7.0.3 -> 7.0.5+)
# - glob 10.4.2 -> 10.5.0+ (HIGH severity)
# - brace-expansion 2.0.1 -> 2.0.2+ (LOW severity)
# -----------------------------------------------------------------------------
RUN npm install -g npm@latest

# -----------------------------------------------------------------------------
# Install ApertoDNS CLI globally from npm
# Clean npm cache to reduce image size
# -----------------------------------------------------------------------------
RUN npm install -g apertodns@latest \
    && npm cache clean --force \
    && rm -rf /tmp/*

# -----------------------------------------------------------------------------
# Create directories for config persistence
# The CLI stores configuration at ~/.config/apertodns/config.json
# -----------------------------------------------------------------------------
RUN mkdir -p /root/.config/apertodns

# Set working directory
WORKDIR /app

# -----------------------------------------------------------------------------
# Environment variables
# APERTODNS_API_KEY: Optional API key for stateless authentication
# (alternative to using --setup with persistent config)
# -----------------------------------------------------------------------------
ENV APERTODNS_API_KEY=""

# -----------------------------------------------------------------------------
# Container entrypoint
# All arguments are passed directly to the apertodns CLI
# Default: show help if no arguments provided
# -----------------------------------------------------------------------------
ENTRYPOINT ["apertodns"]
CMD ["--help"]
