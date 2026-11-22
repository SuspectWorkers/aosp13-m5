# SPDX-License-Identifier: Apache-2.0

$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, device/huawei/mediapadm5wifi/device.mk)

# AOSP has no Lineage kernel build rule. Use the verified donor Image.gz.
PRODUCT_COPY_FILES += device/huawei/mediapadm5wifi/aosp-donor-kernel:kernel

# Use private release keys generated on the build host instead of testkey.
PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/m5-certs/releasekey

# Custom prebuilt apps replacing stock AOSP Camera, Clock, Launcher3, and WebView.
PRODUCT_PACKAGES += \
    Lawnchair \
    Lawnfeed \
    PrebuiltDeskClockGoogle \
    GoogleCameraGo \
    WebViewGoogle \
    HideLawnchairPillOverlay \
    HideSysUIPillOverlay \
    charger_res_images

PRODUCT_NAME := aosp_mediapadm5wifi
PRODUCT_DEVICE := mediapadm5wifi
PRODUCT_BRAND := HUAWEI
PRODUCT_MANUFACTURER := HUAWEI
PRODUCT_MODEL := CMR-W09
PRODUCT_CHARACTERISTICS := tablet
