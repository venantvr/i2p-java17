# I2P Docker Modernization - Summary

## Objectif

Moderniser l'image Docker I2P de `ypopovych/i2p` (Java 11, I2P 1.9.0) vers une version moderne avec Java 17 et I2P 2.10.0, tout en maintenant la retrocompatibilite avec les installations existantes.

## Probleme Initial

L'image `ypopovych/i2p:latest` utilisait :
- `debian:stable-slim` avec `default-jre-headless` (Java 11)
- I2P 1.9.0 (obsolete)
- Avertissement dans l'interface I2P concernant Java 11

## Solution Implementee

### 1. Mise a jour du Dockerfile

| Element | Avant | Apres |
|---------|-------|-------|
| Base image | `debian:stable-slim` | `debian:bookworm-slim` |
| Java | `default-jre-headless` (Java 11) | `openjdk-17-jre-headless` |
| I2P | 1.9.0 | 2.10.0 |
| Optimisation | - | `--no-install-recommends`, cleanup `/var/cache/apt` |

### 2. Migration Retrocompatible (entrypoint.sh)

Le script `entrypoint.sh` gere automatiquement la migration depuis l'ancienne image :

#### Variables d'environnement
- Support de `RUN_AS_USER` (ancien) converti en `PUID`/`PGID` (nouveau)
- `MEM_MAX` : memoire Java, defaut passe de 128M a 256M

#### Chemins de donnees
| Ancien chemin (ypopovych) | Nouveau chemin |
|---------------------------|----------------|
| `/var/lib/i2p/i2p-config` | `/storage/.i2p` |
| `/var/lib/i2p/i2psnark` | `/storage/.i2p/i2psnark` (lien symbolique) |

#### Logique de migration
1. Si ancien config existe et nouveau n'existe pas → copie automatique
2. Si ancien i2psnark monte → creation lien symbolique
3. Si aucun ancien chemin → installation fresh normale
4. Tolerant aux erreurs (continue si anciens chemins absents)

### 3. GitHub Actions (build.yml)

Mise a jour des actions vers les dernieres versions :

| Action | Avant | Apres |
|--------|-------|-------|
| checkout | v2 | v4 |
| setup-qemu-action | v1 | v3 |
| setup-buildx-action | v1 | v3 |
| login-action | v1 | v3 |
| build-push-action | v2 | v6 |

#### Fonctionnalites ajoutees
- `workflow_dispatch` : lancement manuel du build
- `push: ${{ github.event_name != 'pull_request' }}` : ne push que sur les vrais commits
- Cache GitHub Actions (`type=gha`) pour builds plus rapides
- Multi-architecture : `linux/amd64` + `linux/arm64`

### 4. Images Docker

- **Nom final** : `venantvr/i2p-java17` (sans `-arm64` car multi-arch)
- **Tags** : `latest`, `2.10.0`
- **Architectures** : amd64 (PC), arm64 (Raspberry Pi 4, Apple Silicon)

## Migration CasaOS

### Configuration originale
```yaml
image: ypopovych/i2p:latest
environment:
  - RUN_AS_USER=rvv
volumes:
  - /DATA/AppData/i2p/var/lib/i2p/i2p-config:/var/lib/i2p/i2p-config
  - /media/devmon/.../i2psnark:/var/lib/i2p/i2psnark
```

### Configuration mise a jour
```yaml
image: venantvr/i2p-java17:latest
environment:
  - RUN_AS_USER=rvv  # Toujours supporte (retrocompat)
volumes:
  - /DATA/AppData/i2p/var/lib/i2p/i2p-config:/var/lib/i2p/i2p-config  # Ancien
  - /media/devmon/.../i2psnark:/var/lib/i2p/i2psnark  # Ancien
  - /DATA/AppData/i2p/storage:/storage  # NOUVEAU - requis
```

### Avant de demarrer
```bash
mkdir -p /DATA/AppData/i2p/storage
```

### Logs attendus au premier demarrage
```
[i2p] RUN_AS_USER detecte, utilisez PUID/PGID a l'avenir
[i2p] Migration: /var/lib/i2p/i2p-config -> /storage/.i2p
[i2p] Migration terminee
[i2p] Lien i2psnark: /var/lib/i2p/i2psnark -> /storage/.i2p/i2psnark
[i2p] Demarrage I2P 2.10.0...
```

### Apres migration reussie
Les anciens volumes peuvent etre retires et la config simplifiee :
```yaml
image: venantvr/i2p-java17:latest
environment:
  - PUID=1000
  - PGID=1000
  - MEM_MAX=256
volumes:
  - /DATA/AppData/i2p/storage:/storage
  - /media/devmon/.../i2psnark:/storage/.i2p/i2psnark  # Optionnel si externe
```

## Tests Effectues

1. **Build local** : OK
2. **Nouvelle installation** (sans anciens chemins) : OK
3. **Migration** (avec anciens chemins montes) : OK
4. **Fresh install** (volume /storage vide) : OK
5. **Build GitHub Actions multi-arch** : OK

## Fichiers Modifies

| Fichier | Description |
|---------|-------------|
| `Dockerfile` | Base Bookworm, Java 17, I2P 2.10.0 |
| `entrypoint.sh` | Migration retrocompatible, support PUID/PGID |
| `.github/workflows/build.yml` | Actions v4/v6, cache, multi-arch |
| `README.md` | Documentation complete |
| `Claude.md` | Ce fichier de resume |

## Avantages

1. **Performance** : Java 17 plus efficace que Java 11, surtout sur ARM64
2. **Securite** : Debian Bookworm avec derniers patchs
3. **Compatibilite** : Migration transparente depuis ypopovych/i2p
4. **Simplicite** : Un seul volume `/storage` a gerer
5. **Multi-arch** : Fonctionne sur PC et Raspberry Pi sans configuration
