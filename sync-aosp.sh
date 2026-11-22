#!/usr/bin/env bash
set -euo pipefail
project=$(cd "$(dirname "$0")" && pwd)
volume=${M5_BUILD_ROOT:-/mnt/aosp-m5}
mkdir -p "$volume/bin" "$volume/source"
case $(findmnt -n -o FSTYPE --target "$volume") in ext4|zfs) ;; *) echo 'Expected an ext4 or ZFS build workspace'; exit 1 ;; esac
export PATH="$volume/bin:$PATH"
export GIT_TERMINAL_PROMPT=0
if [[ ! -x $volume/bin/repo ]]; then
    curl --fail --location --retry 4 https://storage.googleapis.com/git-repo-downloads/repo -o "$volume/bin/repo.download"
    chmod +x "$volume/bin/repo.download"
    mv "$volume/bin/repo.download" "$volume/bin/repo"
fi
cd "$volume/source"
repo init --manifest-url=https://android.googlesource.com/platform/manifest \
    --manifest-branch=android-13.0.0_r84 --depth=1 --no-tags --no-clone-bundle
install -D -m 0644 "$project/local_manifest.xml" .repo/local_manifests/m5-donors.xml
repo manifest -o "$volume/manifest-resolved.xml"
repo sync -c --no-tags --no-clone-bundle --retry-fetches=3 -j"${M5_SYNC_JOBS:-6}"
