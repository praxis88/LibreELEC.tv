# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present

PKG_NAME="qt6"
PKG_VERSION="6.5.3"
PKG_SHA256="7cda4d119aad27a3887329cfc285f2aba5da85601212bcb0aea27bd6b7b544cb"
PKG_LICENSE="LGPL"
PKG_SITE="https://qt.io"
PKG_URL="https://download.qt.io/archive/qt/6.5/6.5.3/single/qt-everywhere-src-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain qt6-host:host mesa libdrm openssl zlib freetype"
PKG_LONGDESC="Qt6 framework with EGLFS/KMS/GBM display support for aarch64"

# LE's TARGET_CMAKE_OPTS already adds:
#   -DCMAKE_TOOLCHAIN_FILE=<aarch64 toolchain conf>
#   -DCMAKE_INSTALL_PREFIX=/usr
#   -DCMAKE_BUILD_TYPE=MinSizeRel
# The toolchain conf sets: CMAKE_SYSTEM_NAME=Linux, CMAKE_SYSTEM_PROCESSOR=aarch64,
# cross-compiler paths, CMAKE_FIND_ROOT_PATH=sysroot (so libdrm/EGL/GLES2 are found).
PKG_CMAKE_OPTS_TARGET="-DQT_HOST_PATH=${TOOLCHAIN} \
                       -DQT_HOST_PATH_CMAKE_DIR=${TOOLCHAIN}/lib/cmake \
                       -DQT_BUILD_SUBMODULES='qtbase;qtshadertools;qtdeclarative;qtsvg' \
                       -DBUILD_SHARED_LIBS=ON \
                       -DQT_BUILD_EXAMPLES=OFF \
                       -DQT_BUILD_TESTS=OFF \
                       -DINPUT_opengl=es2 \
                       -DFEATURE_egl=ON \
                       -DFEATURE_eglfs=ON \
                       -DFEATURE_eglfs_kms=ON \
                       -DFEATURE_eglfs_kms_egldevice=OFF \
                       -DFEATURE_gbm=ON \
                       -DFEATURE_kms=ON \
                       -DFEATURE_xcb=OFF \
                       -DFEATURE_linuxfb=OFF \
                       -DFEATURE_vnc=OFF \
                       -DFEATURE_dbus=OFF \
                       -DFEATURE_glib=OFF \
                       -DFEATURE_icu=OFF \
                       -DFEATURE_fontconfig=OFF \
                       -DFEATURE_freetype=ON \
                       -DFEATURE_system_freetype=OFF \
                       -DFEATURE_harfbuzz=OFF \
                       -DFEATURE_sql=OFF \
                       -DFEATURE_accessibility=OFF \
                       -DFEATURE_system_tiff=OFF \
                       -DFEATURE_imageformat_tiff=OFF \
                       -DFEATURE_system_webp=OFF \
                       -DFEATURE_network=ON \
                       -DFEATURE_ssl=ON \
                       -DINPUT_openssl=linked \
                       -DQT_QPA_DEFAULT_PLATFORM=eglfs \
                       -DQT_QPA_DEFAULT_EGLFS_INTEGRATION=eglfs_kms"
