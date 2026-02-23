# I2P Docker - Java 17

Image Docker pour [I2P](https://geti2p.net/) avec Java 17 sur Debian Bookworm.

Basée sur [ypopovych/docker-i2p](https://github.com/ypopovych/docker-i2p) avec des mises à jour modernes.

## Fonctionnalités

- **I2P 2.10.0** (dernière version stable)
- **Java 17** (OpenJDK 17 headless)
- **Debian Bookworm** slim base
- Multi-architecture : `linux/amd64`, `linux/arm64`
- Rétrocompatible avec les volumes `ypopovych/i2p`

## Démarrage rapide

```bash
docker run -d \
  --name i2p \
  -p 7657:7657 \
  -p 4444:4444 \
  -v i2p-data:/storage \
  venantvr/i2p-java17:latest
```

Accédez à la console I2P sur http://localhost:7657

## Variables d'environnement

| Variable | Défaut | Description |
|----------|--------|-------------|
| `PUID` | 1000 | User ID pour le processus i2p |
| `PGID` | 1000 | Group ID pour le processus i2p |
| `MEM_MAX` | 256 | Mémoire heap Java max (MB) |

## Volumes

| Chemin | Description |
|--------|-------------|
| `/storage` | Répertoire de données I2P (config dans `/storage/.i2p`) |

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

## Migration depuis ypopovych/i2p

Cette image est rétrocompatible. Gardez vos volumes existants et l'entrypoint migrera automatiquement :

```yaml
volumes:
  # Gardez les anciens volumes
  - /path/to/old/i2p-config:/var/lib/i2p/i2p-config
  - /path/to/old/i2psnark:/var/lib/i2p/i2psnark
  # Ajoutez le nouveau volume
  - /path/to/new/storage:/storage
```

Au premier démarrage, vous verrez :
```
[i2p] Migration: /var/lib/i2p/i2p-config -> /storage/.i2p
[i2p] Migration terminée
[i2p] Lien i2psnark: /var/lib/i2p/i2psnark -> /storage/.i2p/i2psnark
```

Après la migration, vous pouvez supprimer les anciens volumes.

## Ports exposés

| Port | Description |
|------|-------------|
| 4444 | HTTP Proxy |
| 4445 | HTTPS Proxy |
| 6668 | IRC |
| 7654 | I2CP |
| 7656 | SAM |
| 7657 | Router Console |
| 7658 | Eepsite |
| 7659-7660 | Services additionnels |
| 8998 | Streaming |

## Build

```bash
docker build -t i2p-java17 .
```

Build multi-arch :
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t i2p-java17 .
```

## Licence

MIT License - Voir [LICENSE](LICENSE)

Basé sur le travail de Yehor Popovych.

## Stack

[![Stack](https://skillicons.dev/icons?i=bash,docker,linux,dotnet,java&theme=dark)](https://skillicons.dev)
