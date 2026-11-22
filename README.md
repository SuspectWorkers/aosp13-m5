# AOSP 13 for MediaPad M5 Wi-Fi (CMR-W09)

Base: `android-13.0.0_r84` of `https://android.googlesource.com/platform/manifest` (peeled commit `45b33a9a1241420dd45e562da0798f3f8e971f3b`). `local_manifest.xml` pins donor repos and a compatibility candidate; it does not describe a buildable product yet. Vendor blobs and the compatibility tree have not been validated against the installed build.

The Wi-Fi device tree's default branch is a README stub. Use the pinned `android@13` commits, and use the Huawei-Dev `hi3660` tree, not `hisi-oss/hi3660-common` as a drop-in replacement. The donor's dynamic group is `5083496448 - 4194304 = 5079302144` bytes, matching the known OTA. That match alone does not verify the full physical extent layout or live compatibility.

First milestone: resolve the vendor and compatibility dependencies, add an AOSP tablet product without `vendor/lineage` inheritance, then get product configuration and the build graph to resolve. Review LiveDisplay, Touch and Trust alongside the VINTF manifest, init scripts, SELinux policy and overlays; don't remove a package without reviewing its paired configuration. Keep the current v17 kernel and recovery as independent known-good artifacts for eventual hardware testing; do not assume an AOSP image will boot with the existing ramdisk or preserve `/data` without testing.

Full source sync and build require a Linux filesystem with enough **physical** host space. Current Debian WSL disk resides on `C:`; its virtual free space is not the available host space. Put the full checkout on a Linux filesystem backed by a larger drive before syncing. Do not change the tablet, its partition layout or its boot chain during host preflight.

## Build on this host

Use the `Ubuntu-M5` WSL2 distribution at `E:\AOSP-M5\Ubuntu-M5`. Its native VHDX holds `/home/aosp/m5-build/source`. The old `/mnt/aosp-m5` loop-file experiment on Windows DrvFs stalled during formatting; do not reuse that image. Run `setup-ubuntu.sh` as root in `Ubuntu-M5` to install build dependencies and start sync as user `aosp`. Use `M5_BUILD_ROOT=/home/aosp/m5-build` when running the build scripts as `aosp`.

1. `sync-aosp.sh` syncs the pinned AOSP release and donor repositories.
2. `build-aosp.sh graph` registers `aosp_mediapadm5wifi-userdebug` and runs the build-graph check (`m nothing`). Fix AOSP/Lineage compatibility issues here before starting a full build.
3. `build-aosp.sh images` runs `m droid` and checks and hashes the expected partition images. The output is a host artifact, not authorization to flash it.

Build logs are written under `M5_BUILD_ROOT` (`/home/aosp/m5-build` in `Ubuntu-M5`). The product-definition smoke test only checks registration in a disposable donor checkout and `git diff --check`; it does not prove Soong compatibility.

### First device build: compatibility changes

The local `device/huawei/compat` checkout excludes the unused `libshim_emcom`, `libshim_hwcam` and `guivnd` module definitions: their dependencies are absent from AOSP 13, and the checked Huawei product makefiles do not select them. It also drops the unused Lineage HAL `file_contexts` entries, maps `vendor.huawei.hardware.tp::ITouchscreen` in `hwservice_contexts` to `hal_touchscreen_hwservice`, relabels `/odm/etc/audio/volume/volume_point.xml` to `vendor_configs_file`, and drops the legacy non-vendor `/data/` context lines so AOSP `sepolicy_test` passes. The AOSP target also excludes the Lineage LiveDisplay, glove-mode Touch and Trust extensions and the Lineage-only resource overlay, omits `BOARD_*IMAGE_EXTFS_INODE_COUNT := -1` in `BoardConfigCommon.mk` so AOSP `build_image.py` auto-sizes ext4 inodes, and supplies the donor OTA `Image.gz` via `extract-donor-kernel.py` (`PRODUCT_COPY_FILES += ...:kernel`).

Additional AOSP platform patches and release configuration:
- `system-core-init-vendor-lib.patch`: links `//device/huawei/hi3660/resources:init_hisi` into `libinit` and calls `vendor_load_properties()` in `PropertyLoadBootDefaults()`, setting `ro.product.camera_product=CMR`, `ro.product.model=CMR-W09`, and 4 GB Dalvik heap properties for `CameraDaemon`.
- `system-core-init-permissive-user.patch`: sets `-DALLOW_PERMISSIVE_SELINUX=1` in `system/core/init/Android.bp` so `-user` builds continue honoring `androidboot.selinux=permissive` needed by `teecd` (`/dev/tc_ns_client`) and `hi3660` vendor services while keeping `ro.build.type=user`, `ro.debuggable=0`, and `ro.adb.secure=1`.
- `hi3660-init-nul-trim.patch`: trims trailing NUL bytes read from `/sys/firmware/devicetree/base/hisi,product_name` in `libinit_variants.cpp`.
- `hi3660-system-ext-size.patch`: raises `BOARD_SYSTEM_EXTIMAGE_PARTITION_RESERVED_SIZE` to `268435456` (256 MiB) so MindTheGapps `system_ext` payloads (`GoogleServicesFramework`, `GoogleFeedback`, `SetupWizard`) fit without running out of space.
- `huawei-compat-libui-shim.patch`: adds `libui_shim` (`vendor_available: true`) exporting `android::Fence::~Fence()`, `android::GraphicBuffer::lock(uint32_t, void**)`, and `android::GraphicBufferMapper::lock(...)` needed by `/vendor/lib64/libcamera_algo.so`.
- `bionic-libstdc++-vendor.patch`: adds `vendor_available: true` to `libstdc++` in `bionic/libc/Android.bp` so `libstdc++.vendor` builds and installs `/vendor/lib{,64}/libstdc++.so` required by `libcamera_omron.so`, `libSmartAE.so`, and 40+ prebuilt Huawei camera/ISP libraries.
- `system-libhidl-gBnConstructorMap.patch`: exports legacy `gBnConstructorMap` and `gBsConstructorMap` symbols in `libhidlbase.so` with fallback in `HidlBinderSupport` / `HidlPassthroughSupport` required by prebuilt `/vendor/lib64/hwcam/hwcam.services.so`.
- `build-make-release-keys.patch` + `generate-release-keys.sh`: builds the `aosp_mediapadm5wifi-user` variant signed with private release keys (`vendor/m5-certs/releasekey`, generated into `/raid/aosp-m5/release-keys` outside the workspace), `BUILD_KEYS := release-keys`, `BUILD_USERNAME=android-build`, `BUILD_HOSTNAME=abfarm662`, and numeric `BUILD_NUMBER` (`2026111901`) so `test-keys`, `userdebug`, and `eng.*` tags are absent from all partition build properties.
- `mediapadm5wifi-power-menu.patch`: device overlay patch setting `config_longPressOnPowerBehavior=1` (Power/Restart menu on power-button long press instead of Assistant).
- `mediapadm5wifi-webview-overlay.patch`: device overlay adding `com.google.android.webview` (with Google's signing certificate) to `config_webview_packages.xml` so Play Store updates to Android System WebView become active for apps like SysMon WebUI.

The changes are saved as `huawei-compat.patch`, `huawei-compat-libui-shim.patch`, `bionic-libstdc++-vendor.patch`, `hi3660-aosp.patch`, `hi3660-init-nul-trim.patch`, `hi3660-system-ext-size.patch`, `system-core-init-vendor-lib.patch`, `system-core-init-permissive-user.patch`, `system-libhidl-gBnConstructorMap.patch`, `build-make-release-keys.patch`, `mediapadm5wifi-power-menu.patch`, and `mediapadm5wifi-webview-overlay.patch`. `export-donor-patches.sh` verifies the device donor diffs before saving them.

## LAN build server

The remote pipeline uses `/raid/aosp-m5` on the server's ZFS volume. `install-legacy-clang-libs.sh` supplies Debian 12 ABI-5 `libncurses.so.5` and `libtinfo.so.5` for AOSP's legacy RenderScript toolchain (`clang-3289846` and `bcc_strip_attr`), and `server-pipeline.sh` installs host build and JDK font/AWT dependencies (`libfreetype6`, `fontconfig`, X11/ALSA libs). `start-server-build.sh` starts a detached worker, and `server-pipeline.sh` switches to the dedicated `m5build` account before syncing sources, applying the donor patches, and running the graph and image builds. The worker writes `/raid/aosp-m5/pipeline.log`; build logs and outputs live under `/raid/aosp-m5/work`. A failed graph check stops the pipeline before the image stage. No script flashes the tablet.
