# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="wireguard-tools"
PKG_VERSION="1.0.20250521"
PKG_SHA256="aa502f511aa3ce8b5e79b86f21a0e7b8589591d142b28d2b26cf1996f725cd69"
PKG_LICENSE="GPLv2"
PKG_SITE="https://www.wireguard.com"
PKG_URL="https://github.com/WireGuard/wireguard-tools/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain linux"
PKG_NEED_UNPACK="${LINUX_DEPENDS}"
PKG_LONGDESC="WireGuard VPN userspace tools"
PKG_TOOLCHAIN="manual"
PKG_IS_KERNEL_PKG="yes"

pre_make_target() {
  unset LDFLAGS
}

make_target() {
  kernel_make KERNELDIR=$(kernel_path) -C src/ wg
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/wg-keygen ${INSTALL}/usr/bin
    cp ${PKG_BUILD}/src/wg ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr
    cp -R ${PKG_DIR}/config ${INSTALL}/usr
}
