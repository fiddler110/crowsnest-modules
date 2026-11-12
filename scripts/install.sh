#!/bin/sh
# Copies one or more modules from this folder into a CrowsNest modules_dir (the "by hand" install).
#   scripts/install.sh <modules_dir> <module> [module ...]
# These copies are not hash-pinned or signature-checked (you read the file, you trusted it). To get the pinning and
# the signature check, install from the module's https address with  crowsnest module install  instead.
set -eu
. "$(dirname "$0")/common.sh"
[ "$#" -ge 2 ] || { echo "usage: $0 <modules_dir> <module> [module ...]" >&2; exit 2; }
dest="$1"; shift
[ -d "$dest" ] || { echo "$dest is not a folder (this is modules_dir from config.yaml, as the panel sees it)" >&2; exit 1; }
for d in $(modules "$@"); do
  id="$(basename "$d")"
  "$CROWSNEST" module check "$d" >/dev/null
  mkdir -p "$dest/$id" && cp "$d/module.yaml" "$dest/$id/module.yaml"
  echo "copied $id to $dest/$id (restart CrowsNest to load it)"
done
