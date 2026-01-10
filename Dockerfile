# Debian Bookworm pour Java 17 et paquets recents
FROM debian:bookworm-slim

LABEL maintainer="venantvr"

ENV I2P_VERSION="2.10.0"
ENV I2P_PREFIX="/opt/i2p"

# Ajout utilisateur i2p
RUN useradd -d /storage -U -m i2p \
    && chown -R i2p:i2p /storage

# Fichiers necessaires pour l'installation
ADD expect /tmp/expect
ADD entrypoint.sh /entrypoint.sh

# Installation avec Java 17
RUN mkdir -p /usr/share/man/man1 \
    && apt-get update && apt-get install -y --no-install-recommends \
       openjdk-17-jre-headless \
       gosu \
       expect \
       wget \
       ca-certificates \
    && wget -O /tmp/i2pinstall.jar https://files.i2p-projekt.de/${I2P_VERSION}/i2pinstall_${I2P_VERSION}.jar \
    && mkdir -p /opt \
    && chown i2p:i2p /opt \
    && chmod u+rw /opt \
    && gosu i2p expect -f /tmp/expect \
    && cd ${I2P_PREFIX} \
    && rm -fr man *.bat *.command *.app Uninstaller /tmp/i2pinstall.jar /tmp/expect \
    && apt-get remove --purge --yes expect wget \
    && apt-get autoremove --purge --yes \
    && apt-get clean autoclean \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ /usr/share/man /var/cache/apt/archives \
    && sed -i 's/127\.0\.0\.1/0.0.0.0/g' ${I2P_PREFIX}/i2ptunnel.config \
    && sed -i 's/::1,127\.0\.0\.1/0.0.0.0/g' ${I2P_PREFIX}/clients.config \
    && printf "i2cp.tcp.bindAllInterfaces=true\n" >> ${I2P_PREFIX}/router.config \
    && printf "i2np.ipv4.firewalled=true\ni2np.ntcp.ipv6=false\n" >> ${I2P_PREFIX}/router.config \
    && printf "i2np.udp.ipv6=false\ni2np.upnp.enable=false\n" >> ${I2P_PREFIX}/router.config \
    && chmod a+x /entrypoint.sh

VOLUME /storage

EXPOSE 4444 4445 6668 7654 7656 7657 7658 7659 7660 8998 15000-20000

ENTRYPOINT [ "/entrypoint.sh" ]