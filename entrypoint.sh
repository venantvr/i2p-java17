#!/bin/bash
set -e

SGID=$(getent group i2p | cut -d: -f3)
SUID=$(id -u i2p)

# Support ancienne variable RUN_AS_USER (retrocompatibilite)
if [[ -n "$RUN_AS_USER" && -z "$PUID" ]]; then
  echo "[i2p] RUN_AS_USER detecte, utilisez PUID/PGID a l'avenir"
  PUID=$(id -u "$RUN_AS_USER" 2>/dev/null || echo "")
  PGID=$(id -g "$RUN_AS_USER" 2>/dev/null || echo "")
fi

if [[ -n "$PGID" && "$SGID" != "$PGID" ]]; then
  groupmod -g "$PGID" i2p
fi

if [[ -n "$PUID" && "$SUID" != "$PUID" ]]; then
  usermod -u "$PUID" -g "${PGID:-$SGID}" i2p
fi

# Migration automatique des anciens chemins (ypopovych/i2p)
OLD_CONFIG="/var/lib/i2p/i2p-config"
NEW_CONFIG="/storage/.i2p"
OLD_SNARK="/var/lib/i2p/i2psnark"
NEW_SNARK="/storage/.i2p/i2psnark"

# Migration config: seulement si ancien chemin existe et nouveau n'existe pas
if [[ -d "$OLD_CONFIG" ]]; then
  if [[ ! -d "$NEW_CONFIG" ]]; then
    echo "[i2p] Migration: $OLD_CONFIG -> $NEW_CONFIG"
    mkdir -p /storage
    cp -a "$OLD_CONFIG" "$NEW_CONFIG"
    echo "[i2p] Migration terminee"
  else
    echo "[i2p] Config existante dans $NEW_CONFIG (ancien chemin ignore)"
  fi
fi

# Migration i2psnark: lien symbolique si ancien chemin monte
if [[ -d "$OLD_SNARK" ]]; then
  mkdir -p /storage/.i2p
  if [[ ! -e "$NEW_SNARK" ]]; then
    echo "[i2p] Lien i2psnark: $OLD_SNARK -> $NEW_SNARK"
    ln -sf "$OLD_SNARK" "$NEW_SNARK"
  elif [[ ! -L "$NEW_SNARK" ]]; then
    echo "[i2p] i2psnark existe deja dans $NEW_SNARK (ancien chemin ignore)"
  fi
fi

# Memoire par defaut: 256M pour Java 17 (plus efficace)
MEM_MAX="${MEM_MAX:-256}"

sed -i "s/^wrapper\.java\.maxmemory=[0-9]*$/wrapper.java.maxmemory=${MEM_MAX}/g" "$I2P_PREFIX/wrapper.config"

# Ensure user rights
GID_TO_USE="${PGID:-$SGID}"
chown -R i2p:"$GID_TO_USE" /storage
chown -R i2p:"$GID_TO_USE" "$I2P_PREFIX"
chmod -R u+rwx /storage
chmod -R u+rwx "$I2P_PREFIX"

# Permissions sur les anciens chemins si montes
[[ -d "$OLD_SNARK" ]] && chown -R i2p:"$GID_TO_USE" "$OLD_SNARK" || true
[[ -d "$OLD_CONFIG" ]] && chown -R i2p:"$GID_TO_USE" "$OLD_CONFIG" || true

echo "[i2p] Demarrage I2P ${I2P_VERSION:-}..."

exec gosu i2p "$I2P_PREFIX/i2psvc" "$I2P_PREFIX/wrapper.config" \
   wrapper.pidfile=/var/tmp/i2p.pid \
   wrapper.name=i2p \
   wrapper.displayname="I2P Service" \
   wrapper.statusfile=/var/tmp/i2p.status \
   wrapper.java.statusfile=/var/tmp/i2p.java.status \
   wrapper.logfile=
