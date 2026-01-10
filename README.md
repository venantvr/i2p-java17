# I2P Docker - Java 17

Docker image for [I2P](https://geti2p.net/) with Java 17 on Debian Bookworm.

Based on [ypopovych/docker-i2p](https://github.com/ypopovych/docker-i2p) with modern updates.

## Features

- **I2P 2.10.0** (latest stable)
- **Java 17** (OpenJDK 17 headless)
- **Debian Bookworm** slim base
- Multi-architecture: `linux/amd64`, `linux/arm64`
- Backward compatible with `ypopovych/i2p` volumes

## Quick Start

```bash
docker run -d \
  --name i2p \
  -p 7657:7657 \
  -p 4444:4444 \
  -v i2p-data:/storage \
  venantvr/i2p-java17:latest
```

Access the I2P console at http://localhost:7657

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | 1000 | User ID for i2p process |
| `PGID` | 1000 | Group ID for i2p process |
| `MEM_MAX` | 256 | Max Java heap memory (MB) |

## Volumes

| Path | Description |
|------|-------------|
| `/storage` | I2P data directory (config in `/storage/.i2p`) |

## Docker Compose

```yaml
services:
  i2p:
    image: venantvr/i2p-java17:latest
    container_name: i2p
    environment:
      - PUID=1000
      - PGID=1000
      - MEM_MAX=256
    ports:
      - "7657:7657"  # Console
      - "4444:4444"  # HTTP Proxy
      - "4445:4445"  # HTTPS Proxy
    volumes:
      - ./i2p-data:/storage
    restart: unless-stopped
```

## Migration from ypopovych/i2p

This image is backward compatible. Keep your existing volumes and the entrypoint will automatically migrate:

```yaml
volumes:
  # Keep legacy volumes
  - /path/to/old/i2p-config:/var/lib/i2p/i2p-config
  - /path/to/old/i2psnark:/var/lib/i2p/i2psnark
  # Add new volume
  - /path/to/new/storage:/storage
```

On first start, you'll see:
```
[i2p] Migration: /var/lib/i2p/i2p-config -> /storage/.i2p
[i2p] Migration terminee
[i2p] Lien i2psnark: /var/lib/i2p/i2psnark -> /storage/.i2p/i2psnark
```

After migration, you can remove the legacy volumes.

## Exposed Ports

| Port | Description |
|------|-------------|
| 4444 | HTTP Proxy |
| 4445 | HTTPS Proxy |
| 6668 | IRC |
| 7654 | I2CP |
| 7656 | SAM |
| 7657 | Router Console |
| 7658 | Eepsite |
| 7659-7660 | Additional services |
| 8998 | Streaming |

## Build

```bash
docker build -t i2p-java17 .
```

Multi-arch build:
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t i2p-java17 .
```

## License

MIT License - See [LICENSE](LICENSE)

Based on work by Yehor Popovych.
