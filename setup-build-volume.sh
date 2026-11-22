#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]]
image=/mnt/e/AOSP-M5/aosp13-build.ext4
target=/mnt/aosp-m5
mkdir -p "${image%/*}" "$target"
if [[ ! -e $image ]]; then
    (set -o noclobber; : > "$image")
    truncate -s 540G "$image"
    mkfs.ext4 -q -F -m 0 -E nodiscard "$image"
fi
if ! mountpoint -q "$target"; then
    mount -o loop,noatime "$image" "$target"
fi
findmnt --mountpoint "$target" -o SOURCE,FSTYPE,OPTIONS
install -d -o 1000 -g 1000 "$target/source" "$target/bin"
df -h "$target" /mnt/e
