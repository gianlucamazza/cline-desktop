# cline-desktop (unofficial AUR package)

**Not affiliated with Cline.** This repository is only the Arch packaging for
upstream [Cline for Desktop](https://cline.bot/desktop)
([cline/cline](https://github.com/cline/cline)). Cline is Apache-2.0; the
PKGBUILD files here are MIT.

Upstream currently publishes **macOS and Windows** binaries. This package
builds the same `desktop-v*` source tag (Tauri 2 + Bun sidecar) on Linux. The
in-app updater is disabled: Linux is not on the official feed, and upgrades
go through pacman / an AUR helper.

Does **not** conflict with [`cline-cli`](https://aur.archlinux.org/packages/cline-cli).
The desktop binary is `/usr/bin/cline-desktop`.

## Install

```bash
yay -S cline-desktop
# or
git clone https://aur.archlinux.org/cline-desktop.git
cd cline-desktop && makepkg -si
```

First build compiles the whole Cline monorepo. It needs network in `prepare()`
(`bun install`, `cargo fetch`).

## Maintainer

Bump when upstream cuts a new `desktop-vX.Y.Z` tag. CI (`bump.yml`) checks
every 6h and opens a PR; **do not auto-merge** — confirm a local `makepkg -s`
first.

```bash
# after merging the bump PR
./scripts/publish-aur.sh
# or: gh workflow run aur.yml
```

AUR git holds only `PKGBUILD`, `.SRCINFO`, and `cline-desktop.desktop`.

## Troubleshooting

### Blank window on KDE Wayland + NVIDIA

WebKitGTK's DMABUF renderer often fails on NVIDIA under Wayland (`Gdk Protocol error 71` on native Wayland, or `Failed to create GBM buffer` on XWayland). Menu launches set `WEBKIT_DISABLE_DMABUF_RENDERER=1` automatically. If the window is still blank, also force the X11 backend:

```bash
WEBKIT_DISABLE_DMABUF_RENDERER=1 GDK_BACKEND=x11 cline-desktop
```

See the [AUR package comments](https://aur.archlinux.org/packages/cline-desktop) and [issue #1](https://github.com/gianlucamazza/cline-desktop/issues/1).
