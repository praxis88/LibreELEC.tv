# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present

PKG_NAME="qt6-host"
PKG_VERSION="6.5.3"
PKG_SHA256="7cda4d119aad27a3887329cfc285f2aba5da85601212bcb0aea27bd6b7b544cb"
PKG_LICENSE="LGPL"
PKG_SITE="https://qt.io"
PKG_URL="https://download.qt.io/archive/qt/6.5/6.5.3/single/qt-everywhere-src-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="toolchain cmake:host ninja:host Python3:host"
PKG_LONGDESC="Qt6 host build tools (moc, rcc, qmake6, qsb, qmlimportscanner) for cross-compiling"
PKG_BUILD_FLAGS="-sysroot"
PKG_TOOLCHAIN="manual"

configure_host() {
  # LE's cmake toolchain file sets CMAKE_SYSTEM_NAME which Qt6 interprets as
  # cross-compilation and demands QT_HOST_PATH — circular for a native build.
  # Call cmake directly without the toolchain file; cmake auto-detects host platform.
  # libgl1-mesa-dev + libgles2-mesa-dev must be in the Docker image (jammy Dockerfile)
  # so qtshadertools can build the qsb shader-baker tool.
  # SHARED_LIBS=ON is required: tools like qmltime are only built with shared libs.
  cmake "${PKG_BUILD}" \
    -B "${PKG_BUILD}/.host" \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${TOOLCHAIN}" \
    -DQT_BUILD_SUBMODULES="qtbase;qtshadertools;qtdeclarative" \
    -DBUILD_SHARED_LIBS=ON \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF \
    -DFEATURE_dbus=OFF \
    -DFEATURE_glib=OFF \
    -DFEATURE_icu=OFF \
    -DFEATURE_sql=OFF \
    -DFEATURE_accessibility=OFF \
    -DFEATURE_xcb=OFF \
    -DFEATURE_linuxfb=OFF \
    -DFEATURE_network=ON \
    -DFEATURE_ssl=ON \
    -DINPUT_openssl=linked \
    -DOPENSSL_ROOT_DIR="${TOOLCHAIN}" \
    -DFEATURE_dtls=OFF \
    -DFEATURE_ocsp=OFF \
    -DFEATURE_zstd=OFF
}

make_host() {
  cmake --build "${PKG_BUILD}/.host" --parallel
}

makeinstall_host() {
  cmake --install "${PKG_BUILD}/.host"
}
