#!/usr/bin/env bash
set -euo pipefail
base=/raid/aosp-m5
project=$base/scripts
export M5_BUILD_ROOT=$base/work
if [[ $EUID == 0 ]]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends bc bison build-essential ca-certificates cpio curl flex fontconfig git gperf libasound2t64 libfreetype6 libx11-6 libxext6 libxi6 libxrender1 libxtst6 libxml2-utils lz4 python3 rsync unzip xsltproc zip zlib1g-dev
    id m5build >/dev/null 2>&1 || useradd --system --create-home --home-dir "$base/home" --shell /bin/bash m5build
    install -d -o m5build -g "$(id -gn m5build)" "$M5_BUILD_ROOT"
    install -d -m 0700 -o m5build -g "$(id -gn m5build)" "$base/release-keys"
    exec runuser -u m5build -- env HOME="$base/home" bash "$0" "$@"
fi
export M5_SYNC_JOBS=10 M5_JOBS=14
if [[ ${1:-} != resume ]]; then
    bash "$project/sync-aosp.sh"
fi

apply_series() {
    local rel="$1"
    shift
    local dir="$M5_BUILD_ROOT/source/$rel"
    local patches=("$@")
    local last="${patches[${#patches[@]}-1]}"
    if ! git -C "$dir" apply --reverse --check "$project/$last" 2>/dev/null; then
        git -C "$dir" checkout -- .
        if [[ "$rel" == "device/huawei/mediapadm5wifi" ]]; then
            rm -f "$dir/overlay/frameworks/base/core/res/res/xml/config_webview_packages.xml"
        elif [[ "$rel" == "device/huawei/compat" ]]; then
            rm -rf "$dir/libui_shim"
        fi
        for p in "${patches[@]}"; do
            git -C "$dir" apply --check "$project/$p"
            git -C "$dir" apply "$project/$p"
        done
    fi
    git -C "$dir" diff --check
}

apply_series "device/huawei/compat" \
    "huawei-compat.patch" \
    "huawei-compat-libui-shim.patch"

apply_series "device/huawei/hi3660" \
    "hi3660-aosp.patch" \
    "hi3660-init-nul-trim.patch" \
    "hi3660-system-ext-size.patch" \
    "hi3660-perf-and-charger.patch"

apply_series "device/huawei/mediapadm5wifi" \
    "mediapadm5wifi-power-menu.patch" \
    "mediapadm5wifi-features.patch" \
    "mediapadm5wifi-webview-overlay.patch"

apply_series "vendor/huawei/hi3660" \
    "vendor-hi3660-aosp.patch"

apply_series "bionic" \
    "bionic-libstdc++-vendor.patch"

apply_series "system/libhidl" \
    "system-libhidl-gBnConstructorMap.patch"

apply_series "system/core" \
    "system-core-init-vendor-lib.patch" \
    "system-core-init-permissive-user.patch"

apply_series "build/make" \
    "build-make-release-keys.patch" \
    "build-make-custom-apps.patch"

bash "$project/generate-release-keys.sh" "$M5_BUILD_ROOT/source" "$base/release-keys"
bash "$project/build-aosp.sh" graph
bash "$project/build-aosp.sh" images
