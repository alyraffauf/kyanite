#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-rocm}"

cd "$(dirname -- "${BASH_SOURCE[0]}")"

EXT_DIR="mkosi.output/$NAME"
OUT_FILE="../output/sysexts/$NAME.raw"

mkdir -p "$(dirname "$OUT_FILE")"

mkosi --force build

# Without SELinux relabel here, missing security.selinux xattrs silently
# break screen-unlock / sudo / polkit (SSH-side PAM is unaffected).
sudo setfiles -F -r "$EXT_DIR" \
    /etc/selinux/targeted/contexts/files/file_contexts "$EXT_DIR"

rm -f "$OUT_FILE"
sudo mksquashfs "$EXT_DIR" "$OUT_FILE" \
    -all-root -xattrs -comp zstd -Xcompression-level 19 -noappend
sudo chown "$(id -u):$(id -g)" "$OUT_FILE"

echo "Built: $OUT_FILE ($(du -h "$OUT_FILE" | cut -f1))"
