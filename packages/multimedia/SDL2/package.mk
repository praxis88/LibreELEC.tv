# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present

PKG_NAME="SDL2"
PKG_VERSION="2.30.2"
PKG_SHA256="891d66ac8cae51361d3229e3336ebec1c407a8a2a063b61df14f5fdf3ab5ac31"
PKG_LICENSE="zlib"
PKG_SITE="https://libsdl.org"
PKG_URL="https://github.com/libsdl-org/SDL/releases/download/release-${PKG_VERSION}/SDL2-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain alsa-lib libdrm mesa"
PKG_LONGDESC="Simple DirectMedia Layer - cross-platform multimedia library"

PKG_CMAKE_OPTS_TARGET="-DSDL_SHARED=ON \
                       -DSDL_STATIC=OFF \
                       -DSDL_TEST=OFF \
                       -DSDL_TESTS=OFF \
                       -DSDL_AUDIO=ON \
                       -DSDL_VIDEO=ON \
                       -DSDL_RENDER=ON \
                       -DSDL_EVENTS=ON \
                       -DSDL_JOYSTICK=ON \
                       -DSDL_HAPTIC=ON \
                       -DSDL_POWER=ON \
                       -DSDL_THREADS=ON \
                       -DSDL_TIMERS=ON \
                       -DSDL_LOADSO=ON \
                       -DSDL_CPUINFO=ON \
                       -DSDL_FILESYSTEM=ON \
                       -DSDL_DLOPEN=ON \
                       -DSDL_HIDAPI=ON \
                       -DSDL_HIDAPI_JOYSTICK=ON \
                       -DSDL_SENSOR=OFF \
                       -DSDL_X11=OFF \
                       -DSDL_WAYLAND=OFF \
                       -DSDL_DIRECTFB=OFF \
                       -DSDL_KMSDRM=ON \
                       -DSDL_OPENGL=OFF \
                       -DSDL_OPENGLES=ON \
                       -DSDL_VULKAN=OFF \
                       -DSDL_ALSA=ON \
                       -DSDL_ALSA_SHARED=OFF \
                       -DSDL_PULSEAUDIO=OFF \
                       -DSDL_JACK=OFF \
                       -DSDL_ESD=OFF \
                       -DSDL_PIPEWIRE=OFF \
                       -DSDL_SNDIO=OFF \
                       -DSDL_DBUS=ON \
                       -DSDL_IME=OFF \
                       -DSDL_IBUS=OFF \
                       -DSDL_VIRTUAL_JOYSTICK=OFF"

post_makeinstall_target() {
  # Remove sdl2-config and man pages — not needed at runtime
  rm -f ${INSTALL}/usr/bin/sdl2-config
  rm -rf ${INSTALL}/usr/share/man
  rm -rf ${INSTALL}/usr/share/aclocal
}
