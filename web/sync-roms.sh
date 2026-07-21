#!/usr/bin/env bash
# Copy ROM ZIPs from repo-root roms/ into the WASM serve directory.
# Native ./abc uses roms/ at the repo root; the browser build serves web/dist/<subtarget>/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUBTARGET="${SUBTARGET:-abc800c}"
SRC="${ROM_SRC:-$ROOT/roms}"
DST="$ROOT/web/dist/${SUBTARGET}/roms"

if [[ ! -d "$SRC" ]]; then
  echo "No source ROM directory: $SRC" >&2
  exit 1
fi

mkdir -p "$DST"
shopt -s nullglob
zips=("$SRC"/*.zip)
if [[ ${#zips[@]} -eq 0 ]]; then
  echo "No .zip files in $SRC" >&2
  exit 1
fi

for z in "${zips[@]}"; do
  cp -v "$z" "$DST/"
done

echo
echo "Synced ${#zips[@]} zip(s) to $DST"
echo "Required for abc800c: abc800c.zip saa5052.zip abc800kb.zip abc830.zip"
echo "Serve: web/run.sh serve"
