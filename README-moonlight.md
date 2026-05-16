# moonlight-qt on LibreELEC for RK3399

> **Built on the shoulders of giants.**
> This is a fork of [LibreELEC](https://libreelec.tv) (GPL-2.0) with Kodi
> removed and [moonlight-qt](https://github.com/moonlight-stream/moonlight-qt)
> (GPL-3.0) added in its place. All credit for the underlying OS, kernel
> patches, and hardware support goes to the LibreELEC team. All credit for the
> streaming client goes to the moonlight-stream project.  
> This repo provides only the build glue and Qt6 cross-compilation packages
> needed to wire them together on RK3399 hardware.

Streaming appliance build: LibreELEC without Kodi, boots straight into
moonlight-qt with hardware HEVC decode via rkvdec and direct DRM PRIME display.

Developed on a **RockPro64**, but the build is largely universal across all
RK3399 boards — rkvdec, the VOP display controller, and Panfrost are all
SoC-level hardware shared by every RK3399 device. See
[Board-specific settings](#board-specific-settings) below.

---

## Performance

**1080p60 HEVC @ 20 Mbps — RockPro64 (RK3399, 2016 SBC)**

| Metric | Result |
|---|---|
| Incoming frame rate | 59.67 FPS |
| Decode frame rate | 59.67 FPS |
| Render frame rate | 59.67 FPS |
| Average decode time | **2.70 ms** (rkvdec hardware) |
| Average network latency | **1 ms** (variance: 0 ms) |
| Frames dropped (network) | **0.00%** |
| Frames dropped (jitter) | **0.00%** |
| Average frame queue delay | 0.53 ms |
| Render time (incl. vsync) | 10.00 ms |
| Host processing latency | 3.5 ms avg |

Hardware decode via rkvdec leaves the CPU essentially untouched.
The 10 ms render time is the vsync wait, not actual GPU work.

---

## Repo layout

```
LibreELEC.tv/           LibreELEC build system (forked)
  packages/multimedia/
    qt6-host/           Qt 6.5.3 host tools (moc, qmake6, qsb) — builds on x86_64
    qt6/                Qt 6.5.3 target libs — aarch64, EGLFS+KMS+GBM+GLES2
    qt6-host/
    moonlight-qt/       moonlight-qt 6.1.0 + systemd service
    SDL2/               SDL2 2.30.2 (for gamepad + audio backend)
    SDL2_ttf/           SDL2_ttf 2.20.2 (OSD font rendering)
    moonlight-common-c-qt/  } submodule source packages
    enet-qt/            }   (pinned to moonlight-qt v6.1.0 commits)
    qmdnsengine/        }
    h264bitstream/      }
    SDL_GameControllerDB-qt/ }
  projects/Rockchip/devices/RK3399/options   <- build config

moonlight-qt/           moonlight-qt source (reference/submodule inspection)
moonlight-embedded/     old moonlight-embedded (not used in final image)
Luna/                   Kodi addon (not used — no Kodi in this build)
```

---

## Prerequisites

- Docker installed and running
- ~60 GB disk space (build tree is large)
- The LibreELEC build container image:

```bash
cd LibreELEC.tv
docker build -t libreelec tools/docker/jammy/
```

The jammy Dockerfile was patched to add `libgl1-mesa-dev libgles2-mesa-dev`
(required for Qt6's shader tools to build on the headless build host).

---

## Board-specific settings

The entire hardware decode and display pipeline (rkvdec → DRM PRIME → VOP) is
SoC-level and identical across all RK3399 boards. The board target is specified
via `UBOOT_SYSTEM` in the build command — it controls which U-Boot variant and
device tree blob (DTB) gets used.

**Supported RK3399 boards (`UBOOT_SYSTEM` value):**

| Board | `UBOOT_SYSTEM` |
|---|---|
| Pine64 RockPro64 | `rockpro64` |
| Radxa Rock Pi 4A/B/C | `rock-pi-4` |
| Radxa Rock Pi 4 Plus | `rock-pi-4-plus` |
| Radxa Rock 4C Plus | `rock-4c-plus` |
| FriendlyElec NanoPC-T4 | `nanopc-t4` |
| FriendlyElec NanoPi M4 | `nanopi-m4` |
| Khadas Edge | `khadas-edge` |
| Firefly ROC-RK3399-PC | `roc-pc` |
| Firefly ROC-RK3399-PC Plus | `roc-pc-plus` |
| Vamrs Rock960 | `rock960` |
| Orange Pi RK3399 | `orangepi` |
| Hugsun X99 | `hugsun-x99` |
| Sapphire | `sapphire` |

**Per-board runtime tuning** (no rebuild needed — use a systemd drop-in):

| Setting | Default | Notes |
|---|---|---|
| `AUDIODEV` | `hw:1,0` | Run `aplay -l` on your board to find the right card |
| `QT_SCALE_FACTOR` | `2` | Set to `1` for 1080p displays, `2` for 4K |

See [Configuration](#configuration) for how to apply runtime overrides.

---

## Building the image

Change `UBOOT_SYSTEM` to match your board:

```bash
cd LibreELEC.tv

docker run --name le-build --rm \
  -v "$(pwd)":/build -w /build \
  -e PROJECT=Rockchip \
  -e DEVICE=RK3399 \
  -e ARCH=aarch64 \
  -e UBOOT_SYSTEM=rockpro64 \
  -e MTPROGRESS=yes \
  libreelec \
  make image
```

Output lands in `target/LibreELEC-RK3399.aarch64-12.2-devel-*.img.gz`.

**First build time:** ~2-3 hours (Qt6 host + Qt6 target are the long poles).  
**Incremental builds:** A few minutes — only changed packages rebuild.

To force a single package to rebuild:
```bash
rm -rf build.LibreELEC-RK3399.aarch64-12.2-devel/.stamps/<package-name>
rm -rf build.LibreELEC-RK3399.aarch64-12.2-devel/build/<package-name>-<version>
```

---

## Flashing

```bash
# Decompress and write to SD card or eMMC (replace sdX with your device)
unpigz -c target/LibreELEC-RK3399.aarch64-12.2-devel-*.img.gz | dd of=/dev/sdX bs=4M status=progress
```

Or one-liner:
```bash
zcat target/*.img.gz | dd of=/dev/sdX bs=4M status=progress
```

---

## First boot

- SSH is enabled by default (`ssh` in kernel cmdline): `ssh root@<ip>` password `libreelec`
- moonlight-qt starts automatically via systemd after the network comes up
- Check status: `journalctl -u moonlight-qt -f`
- Save a log: `journalctl -u moonlight-qt -o cat --no-pager > /storage/moonlight-qt.log`

---

## Configuration

**Moonlight settings** are saved by moonlight-qt to `/storage/.config/` on the
STORAGE partition (persists across reflashes).

**Audio device** is hardcoded to `AUDIODEV=hw:1,0` in the service. Check
available devices with `aplay -l` and adjust via systemd drop-in if needed:

```bash
mkdir -p /storage/.config/system.d/moonlight-qt.service.d/
cat > /storage/.config/system.d/moonlight-qt.service.d/override.conf << 'EOF'
[Service]
Environment=AUDIODEV=hw:0,0
EOF
systemctl daemon-reload && systemctl restart moonlight-qt
```

**Display scaling** is set to `QT_SCALE_FACTOR=2` (4K display, UI at 2x).
Adjust in the same drop-in if your display differs.

---

## How it works

### Hardware decode
FFmpeg probes `/dev/media0` (rkvdec via V4L2 Request API) and selects it for
HEVC/H.264 decode. Decoded frames are exported as DRM PRIME dma-bufs (NV12).

### Display
SDL2's DRM renderer takes the dma-bufs from rkvdec and commits them directly
to a KMS overlay plane on `card1` (Rockchip VOP) via atomic modesetting.
Zero copy from decoder to display.

### Qt6 cross-compilation notes
Qt6 needed two packages because the host build (tools) and target build
(libraries) can't share a cmake invocation cleanly:

- **qt6-host**: bypasses LE's cmake toolchain file (it triggers Qt6's
  cross-compilation detection, which creates a circular dependency).
  Builds native x86_64 tools into `${TOOLCHAIN}/bin`.
- **qt6**: standard LE cmake cross-compilation with `QT_HOST_PATH=${TOOLCHAIN}`.
  Key: `PKG_BUILD_FLAGS` must NOT include `-sysroot` or LE won't install Qt6
  headers/libs to the sysroot, breaking downstream packages.

moonlight-qt is a qmake project. Cross-compiling it required a `qt.conf`
written at configure time to redirect qmake6's Qt6 paths from the host build
to the sysroot target build, plus overriding `QMAKE_LIBS_OPENGL` (host qmake6
has desktop GL; target needs GLES2).

---

## Updating moonlight-qt

1. Update `PKG_VERSION` and `PKG_SHA256` in `packages/multimedia/moonlight-qt/package.mk`
2. Check if submodule commit SHAs changed (inspect new release's `.gitmodules`
   and git tree), update the corresponding `*-qt` source packages
3. Rebuild

## Updating Qt6

Update `PKG_VERSION` and `PKG_SHA256` in both `qt6/package.mk` and
`qt6-host/package.mk` (they share the same source tarball from
`download.qt.io`). Clear both package stamps and rebuild.
