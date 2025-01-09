FROM         --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim
# 使用 caddy:builder 作为基础镜像，这个镜像包含了 Caddy 的构建工具 xcaddy
FROM caddy:builder AS builder

# 使用 xcaddy build 命令构建 Caddy，并添加阿里 DNS Module
RUN xcaddy build \
    --with github.com/caddy-dns/alidns

# 使用最新的 caddy 镜像作为基础镜像
FROM caddy:latest

# 从 builder 阶段复制构建好的 Caddy 二进制文件到当前镜像中
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

LABEL        author="GenesisMiuss" maintainer="developer@ocent.net"

LABEL        org.opencontainers.image.source="https://github.com/ocent-network/stardew-valley-server"
LABEL        org.opencontainers.image.licenses=MIT

ENV          DEBIAN_FRONTEND=noninteractive

RUN          useradd -m -d /home/container -s /bin/bash container

RUN          ln -s /home/container/ /nonexistent

ENV          USER=container HOME=/home/container

## Update base packages
RUN          apt update \
             && apt upgrade -y

## Install dependencies
RUN         apt install -y gcc g++ libgcc-12-dev libc++-dev gdb libc6 git wget curl tar zip unzip binutils xz-utils liblzo2-2 cabextract iproute2 net-tools netcat-traditional telnet libatomic1 libsdl1.2debian libsdl2-2.0-0 \
            libfontconfig1 icu-devtools libunwind8 libssl-dev sqlite3 libsqlite3-dev libmariadb-dev-compat libduktape207 locales ffmpeg gnupg2 apt-transport-https software-properties-common ca-certificates \
            liblua5.3-0 libz3-dev libzadc4 rapidjson-dev tzdata libevent-dev libzip4 libprotobuf32 libfluidsynth3 procps libstdc++6 tini ca-certificates x11vnc i3 xvfb socat

# Temp fix for libicu66.1 for RAGE-MP and libssl1.1 for fivem and many more
RUN         if [ "$(uname -m)" = "x86_64" ]; then \
                wget http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu66_66.1-2ubuntu2.1_amd64.deb && \
                wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
                dpkg -i libicu66_66.1-2ubuntu2.1_amd64.deb && \
                dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
                rm libicu66_66.1-2ubuntu2.1_amd64.deb libssl1.1_1.1.0g-2ubuntu4_amd64.deb; \
            fi
# ARM64
RUN         if [ ! "$(uname -m)" = "x86_64" ]; then \
                wget http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_arm64.deb && \
                dpkg -i libssl1.1_1.1.1f-1ubuntu2_arm64.deb && \
                rm libssl1.1_1.1.1f-1ubuntu2_arm64.deb; \
            fi

## Configure locale
RUN          update-locale lang=en_US.UTF-8 \
             && dpkg-reconfigure --frontend noninteractive locales


WORKDIR     /home/container

STOPSIGNAL SIGINT

COPY        --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT    ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
