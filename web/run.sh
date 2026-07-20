#!/usr/bin/env bash
# Host-side wrapper: build abc800c (or override) via Docker + emscripten/emsdk.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SUBTARGET="${SUBTARGET:-abc800c}"
SOURCES="${SOURCES:-src/mame/luxor/abc80x.cpp}"
JOBS="${JOBS:-8}"
OPTIMIZE="${OPTIMIZE:-s}"
ACTION="${1:-build}"

case "$ACTION" in
  build)
    docker compose -f web/docker-compose.yml build
    docker compose -f web/docker-compose.yml run --rm \
      -e SUBTARGET="$SUBTARGET" \
      -e SOURCES="$SOURCES" \
      -e JOBS="$JOBS" \
      -e OPTIMIZE="$OPTIMIZE" \
      mame-wasm bash web/build.sh
    echo
    echo "Done. Serve with:  web/run.sh serve"
    echo "Artifacts:         web/dist/${SUBTARGET}/"
    ;;
  serve)
    PORT="${PORT:-8000}"
    DIST="web/dist/${SUBTARGET}"
    if [[ ! -d "$DIST" ]]; then
      echo "No build at $DIST — run: web/run.sh build" >&2
      exit 1
    fi
    echo "Serving $DIST on http://127.0.0.1:${PORT}/"
    echo "Open index.html (or mame.html). ROMs go in ${DIST}/roms/"
    exec python3 -m http.server "$PORT" --directory "$DIST"
    ;;
  shell)
    docker compose -f web/docker-compose.yml run --rm mame-wasm "bash"
    ;;
  *)
    echo "Usage: $0 {build|serve|shell}" >&2
    exit 1
    ;;
esac
