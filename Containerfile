# Cross-build environment for kb.sh: podman build -t kbuild-a64 -f Containerfile .
FROM docker.io/library/debian:trixie
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-aarch64-linux-gnu make bc flex bison libssl-dev libelf-dev python3 \
    cpio kmod zstd rsync device-tree-compiler gcc libc6-dev \
 && rm -rf /var/lib/apt/lists/*
