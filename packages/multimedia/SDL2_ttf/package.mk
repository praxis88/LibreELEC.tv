# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present

PKG_NAME="SDL2_ttf"
PKG_VERSION="2.20.2"
PKG_SHA256="0fe9d587cdc4e6754b647536d0803bea8ca6ac77146c4209e0bed22391cf8241"
PKG_LICENSE="zlib"
PKG_SITE="https://github.com/libsdl-org/SDL_ttf"
PKG_URL="https://github.com/libsdl-org/SDL_ttf/archive/refs/tags/release-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2 freetype"
PKG_LONGDESC="SDL2 TrueType font rendering library (used by moonlight-qt OSD)"

PKG_CMAKE_OPTS_TARGET="-DSDL2TTF_SAMPLES=OFF \
                       -DSDL2TTF_HARFBUZZ=OFF \
                       -DBUILD_SHARED_LIBS=ON"
