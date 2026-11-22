"""Extract the compressed ARM64 kernel from the local donor OTA."""
import gzip
import hashlib
import struct
import sys
import zipfile
from pathlib import Path

ota, destination = map(Path, sys.argv[1:])
with zipfile.ZipFile(ota) as z:
    metadata = z.read('META-INF/com/android/metadata').splitlines()
    if b'pre-device=mediapadm5wifi' not in metadata:
        raise SystemExit('Unexpected donor OTA target')
    boot = z.read('boot.img')
size, address = struct.unpack_from('<II', boot, 8)
page, version = struct.unpack_from('<II', boot, 36)
if boot[:8] != b'ANDROID!' or version != 1 or page != 2048 or address != 0x80000:
    raise SystemExit('Unexpected donor boot image header')
kernel = boot[page:page + size]
with gzip.GzipFile(fileobj=__import__('io').BytesIO(kernel)) as stream:
    header = stream.read(64)
if len(kernel) != size or header[56:60] != b'ARM\x64':
    raise SystemExit('Donor payload is not a complete compressed ARM64 Image')
destination.write_bytes(kernel)
print(f'{len(kernel)} bytes; SHA-256 {hashlib.sha256(kernel).hexdigest()}')
