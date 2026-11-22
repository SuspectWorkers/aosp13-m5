"""Queue the next build stage behind an existing repo sync process."""

import os
from pathlib import Path
import select
import subprocess
import sys


project = Path(__file__).resolve().parent
root = Path(os.environ['M5_BUILD_ROOT'])
if len(sys.argv) == 2:
    try:
        fd = os.pidfd_open(int(sys.argv[1]))
    except ProcessLookupError:
        pass
    else:
        print(f'Waiting for existing sync PID {sys.argv[1]}', flush=True)
        try:
            select.select([fd], [], [])
        finally:
            os.close(fd)

log = root / 'resume-build.log'
with log.open('a', buffering=1) as output:
    for args in [('sync-aosp.sh',), ('build-aosp.sh', 'graph'), ('build-aosp.sh', 'images')]:
        print('Starting', *args, file=output, flush=True)
        result = subprocess.run(['bash', project / args[0], *args[1:]], stdout=output, stderr=subprocess.STDOUT)
        print('Exit', result.returncode, *args, file=output, flush=True)
        if result.returncode:
            raise SystemExit(result.returncode)
