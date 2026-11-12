# Shared by check.sh and sign.sh. CROWSNEST is the crowsnest binary (default: crowsnest on PATH).
CROWSNEST="${CROWSNEST:-crowsnest}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEY="${KEY:-$ROOT/keys/publisher.key}"
# Module folders: every directory with a module.yaml, except those starting with _ (the template).
modules() {
  if [ "$#" -gt 0 ]; then   # folders given by path or by name
    for a in "$@"; do if [ -d "$a" ]; then (cd "$a" && pwd); else printf '%s\n' "$ROOT/$a"; fi; done
    return
  fi
  for d in "$ROOT"/*/; do
    d="${d%/}"; case "$(basename "$d")" in _*) continue ;; esac
    [ -f "$d/module.yaml" ] && printf '%s\n' "$d"
  done
}
