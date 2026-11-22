#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]]
swap=/var/lib/m5-build.swap
if ! grep -Fq "$swap" /proc/swaps; then
    if [[ ! -e $swap ]]; then
        [[ $(findmnt -n -o FSTYPE --target /var/lib) == ext4 ]]
        draft=$(mktemp /var/lib/m5-build.swap.XXXXXX)
        trap 'rm -f -- "$draft"' EXIT
        fallocate -l 12G "$draft"
        mkswap "$draft"
        mv -nT -- "$draft" "$swap"
    fi
    swapon "$swap"
fi
swapon --show
free -h
