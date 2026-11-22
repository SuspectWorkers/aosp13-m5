#!/usr/bin/env bash
set -euo pipefail
project=$(cd "$(dirname "$0")" && pwd)
source_tree=${M5_BUILD_ROOT:-/home/aosp/m5-build}/source
for pair in 'compat:huawei-compat' 'hi3660:hi3660-aosp'; do
    repo="$source_tree/device/huawei/${pair%%:*}"
    patch="$project/${pair#*:}.patch"
    git -C "$repo" diff --check
    draft=$(mktemp "$patch.XXXXXX")
    trap 'rm -f -- "$draft"' EXIT
    git -C "$repo" diff --binary HEAD > "$draft"
    [[ -s "$draft" ]]
    git -C "$repo" apply --reverse --check "$draft"
    mv -- "$draft" "$patch"
    trap - EXIT
    sha256sum "$patch"
done
