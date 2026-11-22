#!/usr/bin/env bash
set -euo pipefail
base=/raid/aosp-m5
dir=$base/legacy-host-libs
install -d "$dir"
cd "$dir"
# Debian 12 retained ncurses ABI 5; keep it private to the build instead of
# replacing libraries installed on the Debian 13 host.
for package in libncurses5 libtinfo5; do
    file=${package}_6.4-4_amd64.deb
    curl -fsSL --retry 3 "https://deb.debian.org/debian/pool/main/n/ncurses/$file" -o "$file"
    [[ $(dpkg-deb -f "$file" Package) == "$package" ]]
    [[ $(dpkg-deb -f "$file" Architecture) == amd64 ]]
    dpkg-deb -x "$file" "$dir"
done
libdir="$dir/lib/x86_64-linux-gnu:$dir/usr/lib/x86_64-linux-gnu"
clang="$base/work/source/prebuilts/clang/host/linux-x86/clang-3289846/bin/clang.real"
LD_LIBRARY_PATH="$libdir" "$clang" --version
# Install the genuine ABI 5 libraries beside the prebuilt, which already has
# an ELF search path for its own lib64. Ninja need not inherit LD_LIBRARY_PATH.
target=${clang%/bin/clang.real}/lib64
host_lib64=$base/work/source/out/host/linux-x86/lib64
install -d -o m5build -g "$(id -gn m5build)" "$host_lib64"
for lib in libncurses.so.5 libtinfo.so.5; do
    origin=$(find "$dir" -name "$lib" -print -quit)
    [[ -n $origin ]]
    for dest in "$target" "$host_lib64"; do
        if [[ ! -e $dest/$lib ]]; then
            install -o m5build -g "$(id -gn m5build)" -m 0644 "$origin" "$dest/$lib"
        fi
    done
done
printf '%s\n' "$dir/lib/x86_64-linux-gnu" > /etc/ld.so.conf.d/aosp-ncurses5.conf
ldconfig
"$clang" --version
if [[ -x $base/work/source/out/host/linux-x86/bin/bcc_strip_attr ]]; then
    ! ldd "$base/work/source/out/host/linux-x86/bin/bcc_strip_attr" | grep -F 'not found'
fi
