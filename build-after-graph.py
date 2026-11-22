"""Start image compilation only if the current graph check ended successfully."""

import os
from pathlib import Path
import re
import select
import sys

pid, log = sys.argv[1:]
try:
    fd = os.pidfd_open(int(pid))
except ProcessLookupError:
    pass
else:
    try:
        select.select([fd], [], [])
    finally:
        os.close(fd)

lines = Path(log).read_text(errors='replace').splitlines()
if not any(re.search(r'#### build completed successfully', line) for line in lines[-20:]):
    sys.exit('Graph check did not report success; image compilation not started.')

script = Path(__file__).resolve().with_name('build-aosp.sh')
os.execv('/bin/bash', ['bash', str(script), 'images'])
