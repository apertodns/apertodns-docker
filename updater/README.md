# ApertoDNS Updater

Lightweight Docker image for automatic DDNS updates with [ApertoDNS](https://www.apertodns.com).

[![Docker Image Size](https://img.shields.io/docker/image-size/apertodns/updater/latest)](https://hub.docker.com/r/apertodns/updater)
[![Docker Pulls](https://img.shields.io/docker/pulls/apertodns/updater)](https://hub.docker.com/r/apertodns/updater)

## Features

- **Ultra-lightweight**: <15MB image size (Alpine Linux + pure shell)
- **Multi-architecture**: Supports `amd64`, `arm64`, `arm/v7` (Raspberry Pi)
- **Smart updates**: Only sends updates when IP actually changes
- **IPv4 & IPv6**: Automatic dual-stack support
- **Robust**: Multiple fallback IP detection services
- **Secure**: Runs as non-root user, read-only filesystem compatible
- **Zero dependencies**: No Node.js, Python, or other runtimes

---

## Quick Start

### Basic Usage

```bash
# Test run (see if it works)
docker run --rm \
  -e TOKEN=your_apertodns_token \
  -e DOMAINS=myhost.apertodns.com \
  apertodns/updater

# Production run (background with restart)
docker run -d \
  --name apertodns-updater \
  --restart unless-stopped \
  -e TOKEN=your_apertodns_token \
  -e DOMAINS=myhost.apertodns.com \
  apertodns/updater
```

### With Docker Compose (Recommended)

```yaml
version: '3.8'

services:
  ddns:
    image: apertodns/updater:latest
    container_name: apertodns-updater
    restart: unless-stopped
    environment:
      - TOKEN=your_apertodns_token
      - DOMAINS=myhost.apertodns.com
      - UPDATE_INTERVAL=300
      - TZ=Europe/Rome
    volumes:
      - apertodns_data:/app/data
    # Security hardening
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL

volumes:
  apertodns_data:
```

---

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TOKEN` | **Yes** | - | Your ApertoDNS authentication token |
| `DOMAINS` | **Yes** | - | Comma-separated list of domains to update |
| `UPDATE_INTERVAL` | No | `300` | Seconds between IP checks (minimum: 60) |
| `DETECT_IPV6` | No | `false` | Enable IPv6 detection and updates |
| `LOG_LEVEL` | No | `info` | Log verbosity: `info` or `debug` |
| `TZ` | No | `UTC` | Container timezone (e.g., `Europe/Rome`) |

---

## Platform-Specific Guides

### Portainer

1. Go to **Stacks** → **Add stack**
2. Name: `apertodns-updater`
3. Paste this compose file:

```yaml
version: '3.8'

services:
  apertodns:
    image: apertodns/updater:latest
    container_name: apertodns-updater
    restart: unless-stopped
    environment:
      - TOKEN=your_token_here
      - DOMAINS=myhost.apertodns.com
      - UPDATE_INTERVAL=300
      - TZ=Europe/Rome
    volumes:
      - apertodns_data:/app/data
    read_only: true
    security_opt:
      - no-new-privileges:true

volumes:
  apertodns_data:
```

4. Click **Deploy the stack**

### Unraid

**Via Docker Tab:**

1. Go to **Docker** → **Add Container**
2. Fill in:
   - **Name**: `apertodns-updater`
   - **Repository**: `apertodns/updater:latest`
   - **Network Type**: `bridge`
3. Add variables (click "Add another Path, Port, Variable, Label or Device"):
   - **Variable**: `TOKEN` = `your_token_here`
   - **Variable**: `DOMAINS` = `myhost.apertodns.com`
   - **Variable**: `UPDATE_INTERVAL` = `300`
   - **Variable**: `TZ` = `Europe/Rome`
4. Add volume:
   - **Container Path**: `/app/data`
   - **Host Path**: `/mnt/user/appdata/apertodns/`
5. Click **Apply**

**Via Community Applications:**

Search for "ApertoDNS" in Community Applications (if available).

### Synology NAS (DSM 7.x)

**Via Container Manager:**

1. Open **Container Manager** → **Registry**
2. Search `apertodns/updater` and download
3. Go to **Image** → Select image → **Run**
4. Configure:
   - **Container Name**: `apertodns-updater`
   - **Enable auto-restart**: Yes
5. **Advanced Settings** → **Environment**:
   - Add: `TOKEN` = `your_token_here`
   - Add: `DOMAINS` = `myhost.apertodns.com`
   - Add: `UPDATE_INTERVAL` = `300`
   - Add: `TZ` = `Europe/Rome`
6. **Volume Settings**:
   - Folder: `/docker/apertodns` → Mount: `/app/data`
7. Click **Done**

**Via SSH (docker-compose):**

```bash
# Create directory
mkdir -p /volume1/docker/apertodns

# Create docker-compose.yml
cat > /volume1/docker/apertodns/docker-compose.yml << 'EOF'
version: '3.8'
services:
  apertodns:
    image: apertodns/updater:latest
    container_name: apertodns-updater
    restart: unless-stopped
    environment:
      - TOKEN=your_token_here
      - DOMAINS=myhost.apertodns.com
      - UPDATE_INTERVAL=300
      - TZ=Europe/Rome
    volumes:
      - ./data:/app/data
EOF

# Start
cd /volume1/docker/apertodns
docker-compose up -d
```

### QNAP NAS

1. Open **Container Station**
2. **Create** → **Create Application**
3. Paste the docker-compose.yml content
4. Click **Create**

### TrueNAS SCALE

1. Go to **Apps** → **Discover Apps** → **Custom App**
2. Or use **TrueCharts** if ApertoDNS is available
3. Configure environment variables and storage

---

## Multiple Domains

Update multiple domains with a single container:

```bash
docker run -d \
  --name apertodns-updater \
  --restart unless-stopped \
  -e TOKEN=your_token \
  -e DOMAINS=server.apertodns.com,nas.apertodns.com,vpn.apertodns.com \
  apertodns/updater
```

---

## IPv6 Support

Enable dual-stack (IPv4 + IPv6) updates:

```bash
docker run -d \
  --name apertodns-updater \
  --restart unless-stopped \
  -e TOKEN=your_token \
  -e DOMAINS=myhost.apertodns.com \
  -e DETECT_IPV6=true \
  apertodns/updater
```

---

## Persistent IP Cache

Mount a volume to persist the IP cache across container restarts. This prevents unnecessary API calls when the container restarts but the IP hasn't changed:

```bash
docker run -d \
  --name apertodns-updater \
  --restart unless-stopped \
  -e TOKEN=your_token \
  -e DOMAINS=myhost.apertodns.com \
  -v apertodns_data:/app/data \
  apertodns/updater
```

---

## Debug Mode

Enable verbose logging for troubleshooting:

```bash
docker run -d \
  --name apertodns-updater \
  -e TOKEN=your_token \
  -e DOMAINS=myhost.apertodns.com \
  -e LOG_LEVEL=debug \
  apertodns/updater
```

---

## Health Check

The container includes a built-in health check that verifies:
- The update script is running
- The last update was within expected interval

Check health status:

```bash
docker inspect --format='{{.State.Health.Status}}' apertodns-updater
```

---

## Logs

View container logs:

```bash
# Follow logs
docker logs -f apertodns-updater

# Last 50 lines
docker logs --tail 50 apertodns-updater
```

Example output:

```
[2025-01-15 10:30:00] [INFO] ==========================================
[2025-01-15 10:30:00] [INFO]   ApertoDNS Updater v1.0.0
[2025-01-15 10:30:00] [INFO]   https://www.apertodns.com
[2025-01-15 10:30:00] [INFO] ==========================================
[2025-01-15 10:30:00] [INFO] Configuration validated successfully
[2025-01-15 10:30:00] [INFO] Configuration:
[2025-01-15 10:30:00] [INFO]   - Domains: myhost.apertodns.com
[2025-01-15 10:30:00] [INFO]   - Update interval: 300s
[2025-01-15 10:30:00] [INFO]   - IPv6 detection: false
[2025-01-15 10:30:01] [INFO] Starting update cycle...
[2025-01-15 10:30:01] [INFO] Initial IPv4 detected: 203.0.113.42
[2025-01-15 10:30:02] [INFO] [myhost.apertodns.com] IP updated successfully: 203.0.113.42
[2025-01-15 10:30:02] [INFO] Update cycle completed
```

---

## API Response Codes

The updater handles standard DynDNS2 response codes:

| Response | Meaning | Action |
|----------|---------|--------|
| `good <ip>` | IP updated successfully | Success |
| `nochg <ip>` | IP unchanged | Success (no update needed) |
| `badauth` | Invalid token | Check TOKEN value |
| `nohost` | Domain not found | Check DOMAINS value |
| `notfqdn` | Invalid hostname format | Check domain format |
| `abuse` | Rate limited | Wait before retrying |
| `911` | Server error | Automatic retry |

---

## Security Hardening

For maximum security, use these options:

```yaml
services:
  apertodns:
    image: apertodns/updater:latest
    # Read-only filesystem
    read_only: true
    # Prevent privilege escalation
    security_opt:
      - no-new-privileges:true
    # Drop all capabilities
    cap_drop:
      - ALL
    # Resource limits
    deploy:
      resources:
        limits:
          memory: 32M
          cpus: '0.1'
```

---

## Troubleshooting

### "TOKEN environment variable is required"

You haven't set the TOKEN. Get it from your [ApertoDNS dashboard](https://www.apertodns.com/dashboard).

### "DOMAINS environment variable is required"

You need to specify at least one domain to update.

### "Authentication failed - check your TOKEN"

Your token is invalid or expired. Generate a new one from the dashboard.

### "Domain not found"

The domain doesn't exist in your ApertoDNS account. Create it first at [apertodns.com/dashboard](https://www.apertodns.com/dashboard).

### "Account blocked for abuse"

Too many updates in a short time. The updater uses smart caching to prevent this - make sure you're using a recent version.

### Container keeps restarting

Check the logs for errors:

```bash
docker logs apertodns-updater
```

### IP not detected

The container needs internet access. Check:

1. Network connectivity: `docker exec apertodns-updater curl -s https://api.ipify.org`
2. DNS resolution: `docker exec apertodns-updater nslookup api.ipify.org`

---

## Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apertodns-updater
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apertodns-updater
  template:
    metadata:
      labels:
        app: apertodns-updater
    spec:
      containers:
      - name: updater
        image: apertodns/updater:latest
        env:
        - name: TOKEN
          valueFrom:
            secretKeyRef:
              name: apertodns-secrets
              key: token
        - name: DOMAINS
          value: "myhost.apertodns.com"
        - name: UPDATE_INTERVAL
          value: "300"
        - name: TZ
          value: "Europe/Rome"
        resources:
          limits:
            memory: "32Mi"
            cpu: "100m"
          requests:
            memory: "8Mi"
            cpu: "10m"
        securityContext:
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
        volumeMounts:
        - name: data
          mountPath: /app/data
      volumes:
      - name: data
        emptyDir: {}
```

---

## Supported Architectures

| Architecture | Platforms |
|--------------|-----------|
| `linux/amd64` | Intel/AMD 64-bit (most servers, PCs) |
| `linux/arm64` | ARM 64-bit (Raspberry Pi 4, Apple M1/M2, AWS Graviton) |
| `linux/arm/v7` | ARM 32-bit (Raspberry Pi 2/3, older ARM devices) |

All architectures are available via the `latest` tag with automatic platform selection.

---

## Building Locally

```bash
# Clone the repository
git clone https://github.com/apertodns/apertodns-docker.git
cd apertodns-docker/updater

# Build for current platform
docker build -t apertodns/updater .

# Build multi-arch and push
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t apertodns/updater:latest \
  --push .
```

---

## Links

- [ApertoDNS Website](https://www.apertodns.com)
- [Documentation](https://www.apertodns.com/docs)
- [Docker Hub](https://hub.docker.com/r/apertodns/updater)
- [GitHub Container Registry](https://ghcr.io/apertodns/updater)
- [GitHub](https://github.com/apertodns/apertodns-docker)
- [Report Issues](https://github.com/apertodns/apertodns-docker/issues)

---

## License

MIT License - see [LICENSE](LICENSE) for details.
