#!/usr/bin/env bash
set -euo pipefail
base=/raid/aosp-m5
cd "$base"
if [[ ${1:-} == worker ]]; then
    set +e
    bash scripts/server-pipeline.sh "${2:-}"
    rc=$?
    printf 'pipeline_exit=%s\n' "$rc"
    exit "$rc"
fi
if [[ -s pipeline.pid ]] && kill -0 "$(cat pipeline.pid)" 2>/dev/null; then
    echo 'Build pipeline already running'
    exit 1
fi
bash -n scripts/server-pipeline.sh
nohup bash scripts/start-server-build.sh worker "${1:-}" >> pipeline.log 2>&1 </dev/null &
printf '%s\n' "$!" > pipeline.pid
printf 'Build pipeline PID: %s\n' "$!"
