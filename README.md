# AOSP 13 for HUAWEI MediaPad M5 Wi-Fi (`CMR-W09` / `hi3660`)

Clean **AOSP 13 (`android-13.0.0_r84`, `aosp_mediapadm5wifi-user`, `release-keys`)** build patches, scripts, overlays, and prebuilt product configuration for the **HUAWEI MediaPad M5 Wi-Fi (`CMR-W09`)**.

## Repositories

- **Manifest & patches:** [`SuspectWorkers/aosp13-m5`](https://github.com/SuspectWorkers/aosp13-m5)
- **Kernel (v17, BakaSU + SUSFS v2.4.0 + SysMon cert):** [`SuspectWorkers/android_kernel_huawei_hi3660`](https://github.com/SuspectWorkers/android_kernel_huawei_hi3660)
- **Vendor blobs (`hi3660`):** [`SuspectWorkers/android_vendor_huawei_hi3660`](https://github.com/SuspectWorkers/android_vendor_huawei_hi3660)
- **Common device tree (`hi3660`):** [`SuspectWorkers/android_device_huawei_hi3660`](https://github.com/SuspectWorkers/android_device_huawei_hi3660)
- **Device tree (`mediapadm5wifi`):** [`SuspectWorkers/android_device_huawei_mediapadm5wifi`](https://github.com/SuspectWorkers/android_device_huawei_mediapadm5wifi)
- **Compatibility shims (`compat`):** [`SuspectWorkers/android_device_huawei_compat`](https://github.com/SuspectWorkers/android_device_huawei_compat)

## What is included

- **Native `-user` / `release-keys` build:** `build-make-release-keys.patch`, `generate-release-keys.sh`, `system-core-init-permissive-user.patch` (keeps `SELinux Permissive` enabled on `-user` so `/dev/tc_ns_client` TEE stays functional).
- **Camera & HAL compatibility:** `system-core-init-vendor-lib.patch` + `hi3660-init-nul-trim.patch` (`init_hisi`), `system-libhidl-gBnConstructorMap.patch`, `huawei-compat-libui-shim.patch` (`libui_shim.so`), `bionic-libstdc++-vendor.patch`.
- **Product apps & overlays (`product/`):**
  - `Lawnchair 14` + `Lawnfeed 4.0.0` (with privapp & hiddenapi whitelists + Quickstep recents config)
  - `HideLawnchairPillOverlay` & `HideSysUIPillOverlay` (native gesture pill removal)
  - `GoogleCameraGo`, `PrebuiltDeskClockGoogle`, `WebViewGoogle` config (`config_webview_packages.xml`)
  - Camera/Mic privacy toggles (`config_supportsCamToggle`, `config_supportsMicToggle`) & power menu on long press
  - 60Hz SurfaceFlinger / HWUI tuning (`hi3660-perf-and-charger.patch`) and 256 MB `system_ext` headroom for MindTheGapps 13 (`hi3660-system-ext-size.patch`)
- **Automated build pipeline:** `server-pipeline.sh`, `sync-aosp.sh`, `prepare-product.sh`, `build-aosp.sh`, `install-legacy-clang-libs.sh`.

> Note: `WebViewGoogle.apk` (263 MB) exceeds GitHub's 100 MB git object limit and is omitted from git tracking in `product/prebuilt-apps/`.
