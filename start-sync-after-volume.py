import os
import select
import sys
from pathlib import Path

try:
    fd = os.pidfd_open(int(sys.argv[1]))
except ProcessLookupError:
    pass
else:
    try:
        select.select([fd], [], [])
    finally:
        os.close(fd)

script = Path(__file__).resolve().with_name('sync-aosp.sh')
os.execv('/bin/bash', ['bash', str(script)])
