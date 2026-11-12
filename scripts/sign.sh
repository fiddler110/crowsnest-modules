#!/bin/sh
# Signs every module (or the folders given), writing module.yaml.sig beside each. Run after every edit.
#   scripts/sign.sh [folder ...]         KEY=path/to/key to pick the key (default keys/publisher.key)
set -eu
. "$(dirname "$0")/common.sh"
[ -f "$KEY" ] || { echo "no signing key at $KEY: run  $CROWSNEST module keygen publisher  and move publisher.key to keys/" >&2; exit 1; }
for d in $(modules "$@"); do "$CROWSNEST" module check "$d" >/dev/null && "$CROWSNEST" module sign "$d/module.yaml" --key "$KEY"; done
