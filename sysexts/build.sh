#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-rocm}"

cd "$(dirname -- "${BASH_SOURCE[0]}")"

EXT_DIR="mkosi.output/$NAME"
OUT_FILE="../output/sysexts/$NAME.raw"

mkdir -p "$(dirname "$OUT_FILE")"

mkosi --force build

# Apply host SELinux contexts. Without this, the overlay's files have no
# security.selinux xattrs and SELinux silently denies kscreenlocker/polkit/
# local-tty PAM stacks — locking the user out while SSH still works.
sudo setfiles -F -r "$EXT_DIR" \
    /etc/selinux/targeted/contexts/files/file_contexts "$EXT_DIR"

rm -f "$OUT_FILE"
sudo mksquashfs "$EXT_DIR" "$OUT_FILE" \
    -all-root -xattrs -comp zstd -Xcompression-level 19 -noappend
sudo chown "$(id -u):$(id -g)" "$OUT_FILE"

echo "Built: $OUT_FILE ($(du -h "$OUT_FILE" | cut -f1))"
