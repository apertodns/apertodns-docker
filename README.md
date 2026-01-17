# ApertoDNS Docker Images

Official Docker images for [ApertoDNS](https://apertodns.com) - Free Dynamic DNS Service.

[![Docker Hub - Updater](https://img.shields.io/docker/v/apertodns/updater?label=updater&logo=docker)](https://hub.docker.com/r/apertodns/updater)
[![Docker Hub - CLI](https://img.shields.io/docker/v/apertodns/cli?label=cli&logo=docker)](https://hub.docker.com/r/apertodns/cli)
[![License](https://img.shields.io/github/license/apertodns/apertodns-docker)](LICENSE)

## Available Images

| Image | Description | Size | Architectures |
|-------|-------------|------|---------------|
| [apertodns/updater](https://hub.docker.com/r/apertodns/updater) | Lightweight DDNS daemon | ~15MB | amd64, arm64, arm/v7 |
| [apertodns/cli](https://hub.docker.com/r/apertodns/cli) | CLI tool container | ~150MB | amd64, arm64 |

## Quick Start

### Updater (DDNS Daemon)

Keep your DNS records automatically updated:

```bash
docker run -d \
  --name apertodns-updater \
  --restart unless-stopped \
  -e TOKEN=your_token_here \
  -e DOMAINS=myhost.apertodns.com \
  apertodns/updater:latest
```

### CLI Tool

Run CLI commands without installing Node.js:

```bash
# Show help
docker run --rm apertodns/cli --help

# Interactive setup
docker run --rm -it -v apertodns_config:/root/.config/apertodns apertodns/cli --setup

# List domains
docker run --rm -v apertodns_config:/root/.config/apertodns apertodns/cli --domains

# Standalone update (no config required)
docker run --rm apertodns/cli --update --domain myhost.apertodns.com --token YOUR_TOKEN

# TXT record for ACME DNS-01 (Let's Encrypt)
docker run --rm -e APERTODNS_API_KEY="your-key" apertodns/cli --txt-set myhost.apertodns.com _acme-challenge "token"
```

## Documentation

- **[Updater Documentation](./updater/README.md)** - Full guide for the DDNS daemon
- **[CLI Documentation](./cli/README.md)** - Full guide for the CLI container
- **[ApertoDNS Docs](https://apertodns.com/docs)** - Main documentation

## Getting Your Token

1. Register at [apertodns.com](https://apertodns.com/register)
2. Create a domain in the dashboard
3. Copy the token from Domain Settings

## Registry Mirrors

Images are available from both Docker Hub and GitHub Container Registry:

```bash
# Docker Hub
docker pull apertodns/updater:latest
docker pull apertodns/cli:latest

# GitHub Container Registry
docker pull ghcr.io/apertodns/apertodns-updater:latest
docker pull ghcr.io/apertodns/apertodns-cli:latest
```

## Platform Support

### Updater
- **Raspberry Pi** (all models) - arm/v7, arm64
- **Linux servers** - amd64
- **NAS devices** - Synology, QNAP
- **Cloud instances** - AWS, GCP, Azure

### CLI
- **Linux** - amd64, arm64
- **macOS** - via Rosetta 2 (arm64)
- **Windows** - via WSL2 (amd64)

## Links

- **Website**: [apertodns.com](https://apertodns.com)
- **Dashboard**: [apertodns.com/dashboard](https://apertodns.com/dashboard)
- **CLI on npm**: [npmjs.com/package/apertodns](https://npmjs.com/package/apertodns)
- **CLI on GitHub**: [github.com/apertodns/apertodns](https://github.com/apertodns/apertodns)

## Support

- **Issues**: [GitHub Issues](https://github.com/apertodns/apertodns-docker/issues)
- **Email**: support@apertodns.com

## License

MIT - [Aperto Network](https://apertodns.com)
