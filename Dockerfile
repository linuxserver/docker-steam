FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# title
ENV TITLE=Steam \
    PIXELFLUX_WAYLAND=true \
    NO_DECOR=true

RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/steam-logo.png && \
  echo "**** install packages ****" && \
  dpkg --add-architecture i386 && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    gcc-multilib \
    libc6:i386 \
    libegl1:i386 \
    libgbm1:i386 \
    libgl1:i386 \
    libgl1-mesa-dri:i386 \
    mesa-libgallium:i386 \
    mesa-va-drivers:i386 \
    mesa-vulkan-drivers:i386 \
    steam-libs \
    steam-libs-amd64 \
    steam-libs-i386 \
    zenity && \
  echo "**** install steam ****" && \
  curl -o \
    /tmp/steam.deb -L \
    "https://cdn.fastly.steamstatic.com/client/installer/steam.deb" && \
  apt-get install -y \
    /tmp/steam.deb && \
  echo "**** install umu run ****" && \
  UMU_RELEASE=$(curl -sX GET "https://api.github.com/repos/Open-Wine-Components/umu-launcher/releases/latest" \
    | jq -r '.tag_name') && \
  curl -o \
    /tmp/umu.deb -L \
    "https://github.com/Open-Wine-Components/umu-launcher/releases/download/${UMU_RELEASE}/python3-umu-launcher_${UMU_RELEASE}-1_amd64_debian-13.deb" && \
  apt-get install -y \
    /tmp/umu.deb && \
  echo "**** install protonupqt ****" && \
  PRQT_RELEASE=$(curl -sX GET "https://api.github.com/repos/DavidoTek/ProtonUp-Qt/releases/latest" \
    | jq -r '.tag_name') && \
  curl -o \
    /tmp/prqt.app -L \
    "https://github.com/DavidoTek/ProtonUp-Qt/releases/download/${PRQT_RELEASE}/ProtonUp-Qt-$(echo ${PRQT_RELEASE} | sed 's/^v//g')-x86_64.AppImage" && \
  cd /tmp &&  \
  chmod +x prqt.app && \
  ./prqt.app --appimage-extract && \
  mv squashfs-root /opt/protonup-qt && \
  echo "**** install 32 bit interposers ****" && \
  cd /tmp && \
  git clone \
    https://github.com/selkies-project/selkies.git && \
  cd selkies/addons/js-interposer && \
  gcc -m32 -shared -fPIC -ldl \
    -o selkies_joystick_interposer_32.so \
    joystick_interposer.c && \
  mv \
    selkies_joystick_interposer_32.so \
    /usr/lib/selkies_joystick_interposer_32.so && \
  cd ../fake-udev && \
  make CC="gcc -m32" && \
  mv \
    libudev.so.1.0.0-fake \
    /opt/lib/libudev.so.1.0.0-fake_32 && \
  cp \
    /opt/lib/* \
    /usr/lib/ && \
  ldconfig && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3001

VOLUME /config
