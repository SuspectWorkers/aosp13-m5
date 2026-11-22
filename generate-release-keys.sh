#!/usr/bin/env bash
set -euo pipefail
source_tree=${1:?usage: generate-release-keys.sh <source_tree> <key_dir>}
key_dir=${2:?usage: generate-release-keys.sh <source_tree> <key_dir>}
command -v openssl >/dev/null

install -d -m 0700 "$key_dir"
subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
for name in releasekey platform shared media networkstack sdk_sandbox bluetooth cts_uicc_2021 verity; do
    if [[ ! -s $key_dir/$name.pk8 || ! -s $key_dir/$name.x509.pem ]]; then
        tmp=$(mktemp "$key_dir/$name.tmp.XXXXXX")
        trap 'rm -f -- "$tmp"' EXIT
        openssl genrsa -f4 2048 > "$tmp" 2>/dev/null
        openssl req -new -x509 -sha256 -key "$tmp" -out "$key_dir/$name.x509.pem" -days 10000 -subj "$subject"
        openssl pkcs8 -in "$tmp" -topk8 -outform DER -out "$key_dir/$name.pk8" -nocrypt
        rm -f -- "$tmp"
        trap - EXIT
    fi
done
# system/sepolicy/private/keys.conf expands $DEFAULT_SYSTEM_DEV_CERTIFICATE/testkey.x509.pem.
cp -f "$key_dir/releasekey.pk8" "$key_dir/testkey.pk8"
cp -f "$key_dir/releasekey.x509.pem" "$key_dir/testkey.x509.pem"
chmod 0600 "$key_dir"/*.pk8
chmod 0644 "$key_dir"/*.x509.pem

dest=$source_tree/vendor/m5-certs
install -d -m 0700 "$dest"
for f in "$key_dir"/*.pk8 "$key_dir"/*.x509.pem; do
    base=${f##*/}
    if [[ ! -f $dest/$base ]] || ! cmp -s "$f" "$dest/$base"; then
        cp -f "$f" "$dest/$base"
    fi
done
chmod 0600 "$dest"/*.pk8
chmod 0644 "$dest"/*.x509.pem
echo "Release keys ready in $key_dir (synced to $dest)"
