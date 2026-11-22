#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]]
project=$(cd "$(dirname "$0")" && pwd)
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    bc bison build-essential ca-certificates cpio curl flex git gperf \
    libncurses5 libxml2-utils lz4 python3 rsync unzip xsltproc zip zlib1g-dev
if ! id aosp >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash aosp
fi
runuser -u aosp -- env M5_BUILD_ROOT=/home/aosp/m5-build bash "$project/sync-aosp.sh"
