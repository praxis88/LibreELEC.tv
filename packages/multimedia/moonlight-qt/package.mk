# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present

PKG_NAME="moonlight-qt"
PKG_VERSION="6.1.0"
PKG_SHA256="da41de33363cdbe9d9b04d4eab26ee6121d5aae11c052faaed9dccf07a8b1270"
PKG_LICENSE="GPL-3.0"
PKG_SITE="https://github.com/moonlight-stream/moonlight-qt"
PKG_URL="https://github.com/moonlight-stream/moonlight-qt/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain qt6 qt6-host:host ffmpeg opus alsa-lib openssl libdrm avahi SDL2 SDL2_ttf libxkbcommon libinput"
PKG_DEPENDS_UNPACK="moonlight-common-c-qt enet-qt qmdnsengine h264bitstream SDL_GameControllerDB-qt"
PKG_LONGDESC="Moonlight game streaming client with Qt6 UI and DRM PRIME video rendering"
PKG_BUILD_FLAGS="-sysroot"
PKG_TOOLCHAIN="manual"

post_unpack() {
  # moonlight-common-c submodule
  rm -rf "${PKG_BUILD}/moonlight-common-c/moonlight-common-c"
  ln -sf "$(get_build_dir moonlight-common-c-qt)" "${PKG_BUILD}/moonlight-common-c/moonlight-common-c"

  # enet is a nested submodule inside moonlight-common-c
  rm -rf "${PKG_BUILD}/moonlight-common-c/moonlight-common-c/enet"
  ln -sf "$(get_build_dir enet-qt)" "${PKG_BUILD}/moonlight-common-c/moonlight-common-c/enet"

  # qmdnsengine submodule
  rm -rf "${PKG_BUILD}/qmdnsengine/qmdnsengine"
  ln -sf "$(get_build_dir qmdnsengine)" "${PKG_BUILD}/qmdnsengine/qmdnsengine"

  # h264bitstream submodule
  rm -rf "${PKG_BUILD}/h264bitstream/h264bitstream"
  ln -sf "$(get_build_dir h264bitstream)" "${PKG_BUILD}/h264bitstream/h264bitstream"

  # SDL_GameControllerDB submodule
  rm -rf "${PKG_BUILD}/app/SDL_GameControllerDB"
  ln -sf "$(get_build_dir SDL_GameControllerDB-qt)" "${PKG_BUILD}/app/SDL_GameControllerDB"

  # libs submodule (prebuilts — not needed on Linux, create empty placeholder)
  mkdir -p "${PKG_BUILD}/libs"
}

configure_target() {
  cd "${PKG_BUILD}"

  # Write a qt.conf that redirects HOST qmake6 to use TARGET Qt6 from the sysroot.
  # Without this, qmake uses HOST Qt6 paths (toolchain/include, toolchain/lib)
  # and the cross-linker can't resolve aarch64 symbols from x86_64 .so files.
  cat > "${PKG_BUILD}/.qt.conf" << QTCONF
[Paths]
Prefix=${SYSROOT_PREFIX}/usr
Headers=include
Libraries=lib
Plugins=plugins
QmlImports=qml
Mkspecs=mkspecs
HostPrefix=${TOOLCHAIN}
HostBinaries=bin
HostLibraries=lib
HostData=.
Sysroot=${SYSROOT_PREFIX}
SysrootifiedPrefix=/usr
QTCONF

  "${TOOLCHAIN}/bin/qmake6" \
    -qtconf "${PKG_BUILD}/.qt.conf" \
    "QMAKE_CC=${CC}" \
    "QMAKE_CXX=${CXX}" \
    "QMAKE_LINK=${CXX}" \
    "QMAKE_AR=${AR} cqs" \
    "QMAKE_OBJCOPY=${OBJCOPY}" \
    "QMAKE_NM=${NM} -P" \
    "QMAKE_STRIP=${STRIP}" \
    "QMAKE_CFLAGS+=${CFLAGS}" \
    "QMAKE_CXXFLAGS+=${CXXFLAGS}" \
    "QMAKE_LFLAGS+=${LDFLAGS} -Wl,--sysroot=${SYSROOT_PREFIX}" \
    "QMAKE_LIBS_OPENGL=-lGLESv2 -lEGL" \
    "QMAKE_LIBS_OPENGL_ES2=-lGLESv2 -lEGL" \
    "CONFIG+=embedded" \
    "CONFIG-=import_plugins" \
    "PREFIX=/usr" \
    moonlight-qt.pro
}

make_target() {
  make -C "${PKG_BUILD}" ${MAKE_OPTS} release
}

makeinstall_target() {
  # Copy the compiled binary directly — qmake's generated install Makefile
  # doesn't propagate INSTALL_ROOT through subdir chains.
  mkdir -p "${INSTALL}/usr/bin"
  cp "${PKG_BUILD}/app/moonlight" "${INSTALL}/usr/bin/moonlight"

  # Systemd autostart service
  mkdir -p "${INSTALL}/usr/lib/systemd/system"
  cat > "${INSTALL}/usr/lib/systemd/system/moonlight-qt.service" << 'EOF'
[Unit]
Description=Moonlight Qt Game Streaming
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=HOME=/storage
Environment=QT_QPA_PLATFORM=eglfs
Environment=QT_QPA_EGLFS_INTEGRATION=eglfs_kms
Environment=QT_QPA_EGLFS_KMS_ATOMIC=1
Environment=QT_QPA_EGLFS_KMS_CONFIG=/storage/.config/moonlight-kms.json
Environment=QT_PLUGIN_PATH=/usr/plugins
Environment=QML_IMPORT_PATH=/usr/qml
Environment=QML2_IMPORT_PATH=/usr/qml
Environment=QT_QPA_FONTDIR=/usr/share/fonts/liberation
Environment=QT_SCALE_FACTOR=2
Environment=AUDIODEV=hw:1,0
Environment=SDL_VIDEODRIVER=offscreen
ExecStartPre=/bin/sh -c 'mkdir -p /storage/.config && [ -f /storage/.config/moonlight-kms.json ] || echo "{}" > /storage/.config/moonlight-kms.json'
ExecStart=/usr/bin/moonlight
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  mkdir -p "${INSTALL}/usr/lib/systemd/system/multi-user.target.wants"
  ln -sf ../moonlight-qt.service \
    "${INSTALL}/usr/lib/systemd/system/multi-user.target.wants/moonlight-qt.service"

  # CEC listener: power off board when TV sends standby broadcast
  cat > "${INSTALL}/usr/bin/cec-listen" << 'EOF'
#!/bin/sh
cec-ctl -d /dev/cec0 --playback >/dev/null 2>&1
cec-ctl -d /dev/cec0 --monitor 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *"STANDBY"*)
            logger -t cec-listen "TV standby received, powering off"
            systemctl poweroff
            ;;
    esac
done
EOF
  chmod 755 "${INSTALL}/usr/bin/cec-listen"

  cat > "${INSTALL}/usr/lib/systemd/system/cec-listen.service" << 'EOF'
[Unit]
Description=CEC standby listener - powers off board when TV turns off
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/cec-listen
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  mkdir -p "${INSTALL}/usr/lib/systemd/system/multi-user.target.wants"
  ln -sf ../cec-listen.service \
    "${INSTALL}/usr/lib/systemd/system/multi-user.target.wants/cec-listen.service"
}
