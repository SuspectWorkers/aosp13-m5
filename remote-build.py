"""Run commands or upload build inputs on the authorized LAN build host."""
import hashlib
from pathlib import Path
import shlex
import sys

import paramiko

HOST = '192.168.2.165'
BASE = '/raid/aosp-m5'


class PinnedHost(paramiko.MissingHostKeyPolicy):
    def missing_host_key(self, client, hostname, key):
        if hashlib.md5(key.asbytes(), usedforsecurity=False).hexdigest() != 'b0f900a01173db79a947d87db9b2da29':
            raise paramiko.SSHException('Unexpected build server host key')


with paramiko.SSHClient() as client:
    client.set_missing_host_key_policy(PinnedHost())
    client.connect(HOST, username='root', password=sys.stdin.readline().strip(),
                   look_for_keys=False, allow_agent=False, timeout=10)
    if sys.argv[1] == 'upload':
        with client.open_sftp() as sftp:
            def ensure_remote_dir(rdir):
                parts = rdir.strip('/').split('/')
                cur = ''
                for p in parts:
                    cur += '/' + p
                    try:
                        sftp.stat(cur)
                    except IOError:
                        sftp.mkdir(cur)

            def upload_one(path, remote_dir):
                ensure_remote_dir(remote_dir)
                sftp.put(str(path), remote_dir + '/' + path.name)

            for path in map(Path, sys.argv[2:]):
                if path.is_dir():
                    for f in path.rglob('*'):
                        if f.is_file():
                            parts = f.parts
                            if 'product' in parts:
                                idx = parts.index('product')
                                rel = '/'.join(parts[idx:-1])
                                upload_one(f, BASE + '/scripts/' + rel)
                            else:
                                upload_one(f, BASE + '/scripts')
                else:
                    parts = path.parts
                    if 'product' in parts:
                        idx = parts.index('product')
                        rel = '/'.join(parts[idx:-1])
                        upload_one(path, BASE + '/scripts/' + rel)
                    else:
                        upload_one(path, BASE + '/scripts')
    else:
        command = sys.argv[2] if sys.argv[1] == 'run' else ' '.join(map(shlex.quote, sys.argv[1:]))
        _, stdout, _ = client.exec_command(command)
        stdout.channel.set_combine_stderr(True)
        for line in stdout:
            print(line.rstrip('\n'), flush=True)
        sys.exit(stdout.channel.recv_exit_status())
