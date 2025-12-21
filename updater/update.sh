#!/bin/sh
# ============================================================================
# ApertoDNS Updater - DDNS Update Daemon v2.0.0
# ============================================================================
# Pure POSIX shell script for minimal Docker image size
# No bash, Node.js, or Python required
#
# This script:
#   1. Detects the current public IP (IPv4 and optionally IPv6)
#   2. Compares with cached IP to avoid unnecessary updates
#   3. Updates ApertoDNS via DynDNS2 compatible API
#   4. Parses response codes and logs appropriately
#   5. Loops indefinitely with configurable interval
#
# Environment Variables:
#   TOKEN          - ApertoDNS authentication token (required)
#   DOMAINS        - Comma-separated list of domains (required)
#   UPDATE_INTERVAL- Seconds between IP checks (default: 300, min: 60)
#   DETECT_IPV6    - Enable IPv6 detection (default: false)
#   LOG_LEVEL      - Logging verbosity: info|debug (default: info)
#   TZ             - Timezone for log timestamps (default: UTC)
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration Constants
# ============================================================================

# ApertoDNS API endpoint (DynDNS2 compatible)
API_URL="https://api.apertodns.com/nic/update"

# File paths for IP caching (allows smart updates)
IP_CACHE_FILE="/app/data/current_ip"      # Cached IPv4 address
IP6_CACHE_FILE="/app/data/current_ip6"    # Cached IPv6 address
LAST_UPDATE_FILE="/app/data/last_update"  # Timestamp for healthcheck

# Minimum allowed update interval (prevents API abuse)
MIN_INTERVAL=60

# IP Detection Services - Multiple fallbacks for reliability
# These services return plain text IP addresses
IPV4_SERVICES="
https://api.ipify.org
https://ipv4.icanhazip.com
https://ifconfig.me/ip
https://checkip.amazonaws.com
https://ip.seeip.org
"

IPV6_SERVICES="
https://api6.ipify.org
https://ipv6.icanhazip.com
https://ifconfig.co
"

# ============================================================================
# Logging Functions
# Uses ANSI color codes for terminal output
# IMPORTANT: All log output goes to stderr (>&2) to avoid polluting stdout
# ============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color (reset)

# Main logging function
# Arguments: $1=level, $2=message
# CRITICAL: Output to stderr (>&2) to avoid polluting stdout for subshells
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""

    # Select color based on log level
    case "$level" in
        "INFO")  color="$GREEN" ;;
        "WARN")  color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
        "DEBUG") color="$CYAN" ;;
        *)       color="$NC" ;;
    esac

    # Skip debug messages unless LOG_LEVEL=debug
    if [ "$level" = "DEBUG" ] && [ "$LOG_LEVEL" != "debug" ]; then
        return
    fi

    # Output formatted log line to STDERR
    printf "${color}[%s] [%s]${NC} %s\n" "$timestamp" "$level" "$message" >&2
}

# ============================================================================
# Configuration Validation
# Ensures all required settings are present and valid
# ============================================================================

validate_config() {
    # TOKEN is required for API authentication
    if [ -z "$TOKEN" ]; then
        log "ERROR" "TOKEN environment variable is required"
        log "ERROR" "Get your token from: https://www.apertodns.com/tokens"
        exit 1
    fi

    # DOMAINS is required - must have at least one domain to update
    if [ -z "$DOMAINS" ]; then
        log "ERROR" "DOMAINS environment variable is required"
        log "ERROR" "Example: DOMAINS=myhost.apertodns.com"
        exit 1
    fi

    # Enforce minimum interval to prevent API abuse
    if [ "$UPDATE_INTERVAL" -lt "$MIN_INTERVAL" ]; then
        log "WARN" "UPDATE_INTERVAL ($UPDATE_INTERVAL) is below minimum ($MIN_INTERVAL)"
        log "WARN" "Using minimum interval: ${MIN_INTERVAL}s"
        UPDATE_INTERVAL=$MIN_INTERVAL
    fi

    log "INFO" "Configuration validated successfully"
}

# ============================================================================
# IP Detection Functions
# Uses multiple services with fallback for reliability
# ============================================================================

# Detect current public IPv4 address
# Returns: IPv4 address on stdout, or error code 1
detect_ipv4() {
    local ip=""

    # Try each service until one works
    for service in $IPV4_SERVICES; do
        log "DEBUG" "Trying IPv4 service: $service"

        # Fetch IP with timeout (5s connect, 10s total)
        ip=$(curl -4 -s --connect-timeout 5 --max-time 10 "$service" 2>/dev/null | tr -d '[:space:]')

        # Validate IPv4 format (basic regex check)
        if echo "$ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
            log "DEBUG" "IPv4 detected via $service: $ip"
            echo "$ip"
            return 0
        fi
    done

    log "ERROR" "Failed to detect IPv4 address from all services"
    return 1
}

# Detect current public IPv6 address (if enabled)
# Returns: IPv6 address on stdout, or error code 1
detect_ipv6() {
    local ip=""

    # Skip if IPv6 detection is disabled
    if [ "$DETECT_IPV6" != "true" ]; then
        return 1
    fi

    # Try each IPv6 service
    for service in $IPV6_SERVICES; do
        log "DEBUG" "Trying IPv6 service: $service"

        ip=$(curl -6 -s --connect-timeout 5 --max-time 10 "$service" 2>/dev/null | tr -d '[:space:]')

        # Validate IPv6 format (simplified check for hex and colons)
        if echo "$ip" | grep -qE '^[0-9a-fA-F:]+$'; then
            log "DEBUG" "IPv6 detected via $service: $ip"
            echo "$ip"
            return 0
        fi
    done

    log "DEBUG" "Failed to detect IPv6 address (may not be available)"
    return 1
}

# Read cached IP from file
# Arguments: $1=cache file path
# Returns: Cached IP on stdout (empty if no cache)
get_cached_ip() {
    local cache_file="$1"
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    else
        echo ""
    fi
}

# Save IP to cache file
# Arguments: $1=cache file path, $2=IP address
save_cached_ip() {
    local cache_file="$1"
    local ip="$2"
    echo "$ip" > "$cache_file"
}

# ============================================================================
# DynDNS2 Response Parser
# Handles standard DynDNS2 protocol responses
# ============================================================================

# Parse API response and log appropriate message
# Arguments: $1=response string, $2=domain name
# Returns: 0 for success responses, 1 for errors
parse_response() {
    local response="$1"
    local domain="$2"

    # DynDNS2 response codes:
    # https://help.dyn.com/remote-access-api/return-codes/
    case "$response" in
        good\ *|good)
            # Success: IP was updated
            log "INFO" "[$domain] IP updated successfully: ${response#good }"
            return 0
            ;;
        nochg\ *|nochg)
            # Success: IP unchanged (no update needed)
            log "INFO" "[$domain] IP unchanged: ${response#nochg }"
            return 0
            ;;
        badauth)
            # Error: Authentication failed
            log "ERROR" "[$domain] Authentication failed - check your TOKEN"
            log "ERROR" "Get a new token from: https://www.apertodns.com/tokens"
            return 1
            ;;
        nohost)
            # Error: Hostname not found in user's account
            log "ERROR" "[$domain] Domain not found - check your DOMAINS configuration"
            log "ERROR" "Create the domain at: https://www.apertodns.com/domains"
            return 1
            ;;
        notfqdn)
            # Error: Invalid hostname format
            log "ERROR" "[$domain] Invalid hostname format - must be a fully qualified domain"
            return 1
            ;;
        abuse)
            # Error: Too many requests, account blocked
            log "ERROR" "[$domain] Account blocked for abuse - too many updates"
            log "ERROR" "Wait before retrying. Contact support if issue persists."
            return 1
            ;;
        911)
            # Error: Server-side error
            log "ERROR" "[$domain] Server error (911) - will retry later"
            return 1
            ;;
        dnserr)
            # Error: DNS propagation error
            log "ERROR" "[$domain] DNS error on server side"
            return 1
            ;;
        *)
            # Unknown response
            log "WARN" "[$domain] Unknown response: $response"
            return 1
            ;;
    esac
}

# ============================================================================
# Domain Update Function
# Sends update request to ApertoDNS API
# ============================================================================

# Update a single domain with current IP
# Arguments: $1=domain, $2=IPv4 (optional), $3=IPv6 (optional)
# Returns: 0 on success, 1 on failure
update_domain() {
    local domain="$1"
    local ipv4="$2"
    local ipv6="$3"

    # Build API URL with query parameters
    local url="${API_URL}?hostname=${domain}"

    # Add IPv4 if available
    if [ -n "$ipv4" ]; then
        url="${url}&myip=${ipv4}"
    fi

    # Add IPv6 if available and detection is enabled
    if [ -n "$ipv6" ] && [ "$DETECT_IPV6" = "true" ]; then
        url="${url}&myipv6=${ipv6}"
    fi

    log "DEBUG" "Updating $domain via: $url"

    # Make API request with Basic Auth
    # Authentication: TOKEN as both username and password
    local response=$(curl -s --connect-timeout 10 --max-time 30 \
        -u "${TOKEN}:${TOKEN}" \
        "$url" 2>/dev/null)

    # Handle empty response (network error)
    if [ -z "$response" ]; then
        log "ERROR" "[$domain] Empty response from server - network issue?"
        return 1
    fi

    # Parse and handle the response
    parse_response "$response" "$domain"
    return $?
}

# ============================================================================
# Main Update Cycle
# Detects IPs and updates all configured domains
# ============================================================================

run_update_cycle() {
    local current_ipv4=""
    local current_ipv6=""
    local cached_ipv4=""
    local cached_ipv6=""
    local ip_changed=0

    log "INFO" "Starting update cycle..."

    # Step 1: Detect current public IPs
    current_ipv4=$(detect_ipv4) || true

    if [ "$DETECT_IPV6" = "true" ]; then
        current_ipv6=$(detect_ipv6) || true
    fi

    # Abort if no IP detected
    if [ -z "$current_ipv4" ] && [ -z "$current_ipv6" ]; then
        log "ERROR" "Failed to detect any IP address - check network connectivity"
        return 1
    fi

    # Step 2: Compare with cached IPs
    cached_ipv4=$(get_cached_ip "$IP_CACHE_FILE")
    cached_ipv6=$(get_cached_ip "$IP6_CACHE_FILE")

    # Check for IPv4 change
    if [ "$current_ipv4" != "$cached_ipv4" ]; then
        if [ -n "$cached_ipv4" ]; then
            log "INFO" "IPv4 changed: $cached_ipv4 -> $current_ipv4"
        else
            log "INFO" "Initial IPv4 detected: $current_ipv4"
        fi
        ip_changed=1
    fi

    # Check for IPv6 change
    if [ "$DETECT_IPV6" = "true" ] && [ "$current_ipv6" != "$cached_ipv6" ]; then
        if [ -n "$cached_ipv6" ]; then
            log "INFO" "IPv6 changed: $cached_ipv6 -> $current_ipv6"
        else
            log "INFO" "Initial IPv6 detected: $current_ipv6"
        fi
        ip_changed=1
    fi

    # Step 3: Skip update if no change (smart update)
    if [ "$ip_changed" -eq 0 ] && [ -n "$cached_ipv4" ]; then
        log "INFO" "No IP change detected, skipping update (IPv4: $current_ipv4)"
        date +%s > "$LAST_UPDATE_FILE"
        return 0
    fi

    # Step 4: Update each domain
    log "INFO" "Updating domains: $DOMAINS"

    # Parse comma-separated domains and update each
    echo "$DOMAINS" | tr ',' '\n' | while read -r domain; do
        # Trim whitespace
        domain=$(echo "$domain" | tr -d '[:space:]')

        if [ -n "$domain" ]; then
            update_domain "$domain" "$current_ipv4" "$current_ipv6" || true
        fi
    done

    # Step 5: Cache current IPs for next cycle
    if [ -n "$current_ipv4" ]; then
        save_cached_ip "$IP_CACHE_FILE" "$current_ipv4"
    fi
    if [ -n "$current_ipv6" ]; then
        save_cached_ip "$IP6_CACHE_FILE" "$current_ipv6"
    fi

    # Update timestamp for healthcheck
    date +%s > "$LAST_UPDATE_FILE"

    log "INFO" "Update cycle completed"
    return 0
}

# ============================================================================
# Signal Handlers (Graceful Shutdown)
# Allows container to stop cleanly
# ============================================================================

shutdown_handler() {
    log "INFO" "Received shutdown signal, exiting gracefully..."
    exit 0
}

# Trap SIGTERM (docker stop) and SIGINT (Ctrl+C)
trap shutdown_handler SIGTERM SIGINT

# ============================================================================
# Main Function
# Entry point and main loop
# ============================================================================

main() {
    # Print startup banner
    log "INFO" "=========================================="
    log "INFO" "  ApertoDNS Updater v2.0.0"
    log "INFO" "  https://www.apertodns.com"
    log "INFO" "=========================================="

    # Validate configuration before starting
    validate_config

    # Print configuration summary
    log "INFO" "Configuration:"
    log "INFO" "  - Domains: $DOMAINS"
    log "INFO" "  - Update interval: ${UPDATE_INTERVAL}s"
    log "INFO" "  - IPv6 detection: $DETECT_IPV6"
    log "INFO" "  - Log level: $LOG_LEVEL"
    log "INFO" "  - Timezone: $TZ"
    log "INFO" ""

    # Run initial update immediately
    run_update_cycle || true

    # Main loop: sleep then update
    while true; do
        # Sleep in background to allow signal handling
        sleep "$UPDATE_INTERVAL" &
        wait $!

        # Run update cycle
        run_update_cycle || true
    done
}

# Start the daemon
main "$@"
