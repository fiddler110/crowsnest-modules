#!/bin/sh
# Checks every module (or the folders given): valid, replays sample.log, and its .sig matches the current file.
#   scripts/check.sh [folder ...]        CROWSNEST=/path/to/crowsnest to pick the binary
set -u
. "$(dirname "$0")/common.sh"
fail=0
for d in $(modules "$@"); do
  id="$(basename "$d")"
  echo "== $id"
  if [ -f "$d/sample.log" ]; then "$CROWSNEST" module check "$d" --log "$d/sample.log" || fail=1
  else echo "warn  no sample.log: nothing proves the ready line and player patterns match"; "$CROWSNEST" module check "$d" || fail=1; fi
  if [ ! -f "$d/module.yaml.sig" ]; then echo "FAIL  not signed (run scripts/sign.sh $id)"; fail=1; continue; fi
  # ed25519 is deterministic, so signing again must reproduce the published signature byte for byte.
  tmp="$(mktemp -d)"; cp "$d/module.yaml" "$tmp/module.yaml"
  if [ -f "$KEY" ] && "$CROWSNEST" module sign "$tmp/module.yaml" --key "$KEY" >/dev/null 2>&1; then
    if cmp -s "$tmp/module.yaml.sig" "$d/module.yaml.sig"; then echo "ok    signature matches the file"
    else echo "FAIL  module.yaml changed since it was signed (run scripts/sign.sh $id)"; fail=1; fi
  else echo "skip  signature not re-verified (no usable key at $KEY, or the file is invalid)"; fi
  rm -rf "$tmp"
done
exit $fail
