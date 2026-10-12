#!/bin/sh
# Cross-build the kernel for arm64 in a podman container.
# Usage: KSRC=~/linux-7.2.10 KOUT=~/out ./kb.sh <make targets/args>
#   e.g. ./kb.sh olddefconfig; ./kb.sh Image modules dtbs
# Build the image once: podman build -t kbuild-a64 -f Containerfile .
# KOUT/.config: start from this repo's config.
: "${KSRC:?set KSRC to the patched kernel tree}"
: "${KOUT:?set KOUT to the build output dir}"
mkdir -p "$KOUT"
# label=disable: SELinux hosts (Fedora, openSUSE) would block the bind mounts
exec podman run --rm --security-opt label=disable --userns=keep-id \
	-v "$KSRC":/src -v "$KOUT":/out -w /src localhost/kbuild-a64 \
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=/out -j"$(nproc)" LOCALVERSION= "$@"
