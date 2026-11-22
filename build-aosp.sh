#!/usr/bin/env bash
set -eo pipefail
project=$(cd "$(dirname "$0")" && pwd)
volume=${M5_BUILD_ROOT:-/mnt/aosp-m5}
case "${1:-graph}" in
    graph) goal=nothing ;;
    images) goal=droid ;;
    *) echo 'Usage: build-aosp.sh [graph|images]' >&2; exit 2 ;;
esac
case $(findmnt -n -o FSTYPE --target "$volume") in ext4|zfs) ;; *) echo 'Expected an ext4 or ZFS build workspace'; exit 1 ;; esac
cd "$volume/source"
[[ -f build/envsetup.sh && -f vendor/huawei/hi3660/hi3660-vendor.mk ]]
bash "$project/prepare-product.sh" "$PWD"
log="$volume/build-$goal-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$log") 2>&1
export BUILD_USERNAME=${M5_BUILD_USERNAME:-android-build}
export BUILD_HOSTNAME=${M5_BUILD_HOSTNAME:-abfarm662}
build_number=${M5_BUILD_NUMBER:-2026112001}
variant=${M5_VARIANT:-user}
source build/envsetup.sh
lunch "aosp_mediapadm5wifi-$variant"
[[ $TARGET_PRODUCT == aosp_mediapadm5wifi ]]
if [[ $goal == droid ]]; then
    m -j"${M5_JOBS:-4}" installclean
fi
m -j"${M5_JOBS:-4}" "BUILD_NUMBER=$build_number" "$goal"
if [[ $goal == droid ]]; then
    dir=$(get_build_var PRODUCT_OUT)
    for name in system vendor product system_ext odm boot; do
        [[ -s "$dir/$name.img" ]] || { echo "Missing image: $dir/$name.img"; exit 1; }
        sha256sum "$dir/$name.img"
    done
fi
