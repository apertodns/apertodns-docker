# ApertoDNS CLI Docker Image

Run the official ApertoDNS CLI without installing Node.js locally. Perfect for one-off commands, scripting, and automation.

[![Docker Image Size](https://img.shields.io/docker/image-size/apertodns/cli/latest)](https://hub.docker.com/r/apertodns/cli)
[![Docker Pulls](https://img.shields.io/docker/pulls/apertodns/cli)](https://hub.docker.com/r/apertodns/cli)
[![npm version](https://img.shields.io/npm/v/apertodns)](https://www.npmjs.com/package/apertodns)

## Alternative: Native npm Install

If you prefer to install the CLI directly without Docker:

```bash
# Install globally
npm install -g apertodns

# Use directly
apertodns --setup
apertodns --domains
apertodns --force
```

See the [npm package](https://www.npmjs.com/package/apertodns) for more details.

---

## Features

- **No Node.js required**: Run the CLI directly from Docker
- **Multi-architecture**: Supports `amd64` and `arm64`
- **Persistent config**: Store credentials via volume mount
- **API key support**: Use environment variables for CI/CD
- **All CLI features**: Full access to ApertoDNS CLI commands

## Quick Start

### Interactive Setup (First Time)

```bash
docker run -it -v apertodns_config:/root/.config/apertodns apertodns/cli --setup
```

This will prompt you to enter your ApertoDNS credentials and save them to the persistent volume.

### List Your Domains

```bash
docker run -v apertodns_config:/root/.config/apertodns apertodns/cli --domains
```

### Force Update

```bash
docker run -v apertodns_config:/root/.config/apertodns apertodns/cli --force
```

### Standalone Update (No Config Required)

```bash
# Update DNS directly with token (no saved config needed)
docker run --rm apertodns/cli --update --domain myhost.apertodns.com --token YOUR_TOKEN

# Specify custom IP
docker run --rm apertodns/cli --update --domain myhost.apertodns.com --token YOUR_TOKEN --ip 1.2.3.4
```

## Using API Key (No Setup Required)

If you have an API key, you can skip the setup and use it directly:

```bash
# Via command line argument
docker run apertodns/cli --api-key ak_your_api_key_here --domains

# Via environment variable
docker run -e APERTODNS_API_KEY=ak_your_api_key_here apertodns/cli --domains
```

## All CLI Commands

| Command | Description |
|---------|-------------|
| `--setup` | Interactive configuration wizard |
| `--domains` | List all your domains |
| `--dashboard` | Show dashboard with statistics |
| `--force` | Force update all domains (requires saved config) |
| `--update` | Standalone DynDNS2 update (with `--domain` and `--token`) |
| `--json` | Output in JSON format (combine with other commands) |
| `--help` | Show all available options |

## Docker Compose

Create a `docker-compose.yml` for easy access:

```yaml
version: '3.8'

services:
  apertodns:
    image: apertodns/cli:latest
    volumes:
      - apertodns_config:/root/.config/apertodns

volumes:
  apertodns_config:
```

Then use:

```bash
# Setup
docker compose run --rm apertodns --setup

# List domains
docker compose run --rm apertodns --domains

# Force update
docker compose run --rm apertodns --force
```

## Shell Alias

Add this to your `.bashrc` or `.zshrc` for convenient access:

```bash
alias apertodns='docker run -v apertodns_config:/root/.config/apertodns apertodns/cli'
```

Then use it like a native command:

```bash
apertodns --domains
apertodns --force
apertodns --dashboard
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Update DDNS
  run: |
    docker run \
      -e APERTODNS_API_KEY=${{ secrets.APERTODNS_API_KEY }} \
      apertodns/cli --force
```

### GitLab CI

```yaml
update_dns:
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker run -e APERTODNS_API_KEY=$APERTODNS_API_KEY apertodns/cli --force
```

### Jenkins Pipeline

```groovy
stage('Update DNS') {
    steps {
        sh '''
        docker run \
            -e APERTODNS_API_KEY=${APERTODNS_API_KEY} \
            apertodns/cli --force
        '''
    }
}
```

## Scripting Examples

### Get domains as JSON

```bash
docker run -v apertodns_config:/root/.config/apertodns apertodns/cli --domains --json | jq '.domains[].hostname'
```

### Check specific domain

```bash
docker run -e APERTODNS_API_KEY=ak_xxx apertodns/cli --domains --json | jq '.domains[] | select(.hostname=="myhost.apertodns.com")'
```

### Cron job for periodic updates

```bash
# Add to crontab
*/5 * * * * docker run --rm -v apertodns_config:/root/.config/apertodns apertodns/cli --force >> /var/log/apertodns.log 2>&1
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `APERTODNS_API_KEY` | API key for authentication (bypasses config file) |

## Volume Mount

The config file is stored at `/root/.config/apertodns/config.json` inside the container. Mount a named volume or host path to persist credentials:

```bash
# Named volume (recommended)
-v apertodns_config:/root/.config/apertodns

# Host path
-v ~/.config/apertodns:/root/.config/apertodns
```

## Supported Architectures

| Architecture | Tag |
|--------------|-----|
| x86-64 | `amd64` |
| ARM64 | `arm64` |

All architectures are available via the `latest` tag with automatic platform selection.

## Building Locally

```bash
# Clone the repository
git clone https://github.com/apertodns/apertodns-docker.git
cd apertodns-docker/cli

# Build for current platform
docker build -t apertodns/cli .

# Build multi-arch
docker buildx build --platform linux/amd64,linux/arm64 \
  -t apertodns/cli:latest --push .
```

## Comparison with Native CLI

| Feature | Docker | Native (npm) |
|---------|--------|--------------|
| Node.js required | No | Yes |
| Installation | `docker pull` | `npm install -g` |
| Updates | `docker pull` | `npm update -g` |
| Config location | Volume mount | `~/.config/apertodns` |
| Startup time | ~100ms | Instant |
| Best for | CI/CD, containers | Local development |

## Troubleshooting

### Permission denied

If you get permission errors with volume mounts:

```bash
# Fix permissions
sudo chown -R $(id -u):$(id -g) ~/.config/apertodns
```

### Config not persisting

Make sure you're using the same volume name:

```bash
# Check volumes
docker volume ls | grep apertodns

# Inspect volume
docker volume inspect apertodns_config
```

### Interactive mode not working

For interactive commands like `--setup`, use `-it` flags:

```bash
docker run -it -v apertodns_config:/root/.config/apertodns apertodns/cli --setup
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [ApertoDNS Website](https://www.apertodns.com)
- [CLI Documentation](https://www.apertodns.com/docs)
- [npm Package](https://www.npmjs.com/package/apertodns)
- [Docker Hub](https://hub.docker.com/r/apertodns/cli)
- [GitHub Container Registry](https://ghcr.io/apertodns/cli)
- [GitHub](https://github.com/apertodns/apertodns-docker)
