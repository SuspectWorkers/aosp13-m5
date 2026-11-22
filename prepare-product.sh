#!/usr/bin/env bash
set -euo pipefail
project=$(cd "$(dirname "$0")" && pwd)
source_tree=${1:-/mnt/aosp-m5/source}
device="$source_tree/device/huawei/mediapadm5wifi"
[[ -f "$device/BoardConfig.mk" && -f "$device/AndroidProducts.mk" ]]
[[ $(git -C "$device" rev-parse HEAD) == c8ed806d73aa2d72ed3032b48300f7940bb9e8ee ]]

if ! cmp -s "$project/product/aosp_mediapadm5wifi.mk" "$device/aosp_mediapadm5wifi.mk"; then
    install -m 0644 "$project/product/aosp_mediapadm5wifi.mk" "$device/aosp_mediapadm5wifi.mk"
fi
kernel=${M5_DONOR_KERNEL:-$project/product/aosp-donor-kernel}
[[ -s "$kernel" ]] || { echo "Missing donor kernel: $kernel" >&2; exit 1; }
if ! cmp -s "$kernel" "$device/aosp-donor-kernel"; then
    install -m 0644 "$kernel" "$device/aosp-donor-kernel"
fi
if [[ -d "$project/product/prebuilt-apps" ]]; then
    mkdir -p "$device/prebuilt-apps"
    while IFS= read -r -d '' f; do
        rel=${f#"$project/product/prebuilt-apps/"}
        dst="$device/prebuilt-apps/$rel"
        mkdir -p "$(dirname "$dst")"
        if [[ ! -f "$dst" ]] || ! cmp -s "$f" "$dst"; then
            install -m 0644 "$f" "$dst"
        fi
    done < <(find "$project/product/prebuilt-apps" -type f -print0)
fi
if ! grep -q 'aosp_mediapadm5wifi.mk' "$device/AndroidProducts.mk"; then
    cat >> "$device/AndroidProducts.mk" <<'EOF'

PRODUCT_MAKEFILES += $(LOCAL_DIR)/aosp_mediapadm5wifi.mk
COMMON_LUNCH_CHOICES += aosp_mediapadm5wifi-userdebug aosp_mediapadm5wifi-user
EOF
elif ! grep -q 'aosp_mediapadm5wifi-user\b' "$device/AndroidProducts.mk"; then
    cat >> "$device/AndroidProducts.mk" <<'EOF'
COMMON_LUNCH_CHOICES += aosp_mediapadm5wifi-user
EOF
fi
git -C "$device" diff --check
git -C "$device" status --short
