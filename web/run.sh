#!/usr/bin/env bash
# Host-side wrapper: build abc800c (or override) via Docker or native emsdk.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SUBTARGET="${SUBTARGET:-abc800c}"
SOURCES="${SOURCES:-src/mame/luxor/abc80x.cpp}"
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 8)}"
OPTIMIZE="${OPTIMIZE:-s}"
ACTION="${1:-build}"

# Prefer Docker unless USE_NATIVE=1 or action is "native".
# On Apple Silicon, native emsdk is much faster than linux/amd64 under QEMU.
use_native() {
  [[ "${USE_NATIVE:-0}" == "1" ]] || [[ "$ACTION" == "native" ]]
}

find_emsdk_env() {
  local candidates=(
    "${EMSDK:-}/emsdk_env.sh"
    "${HOME}/emsdk/emsdk_env.sh"
    /opt/emsdk/emsdk_env.sh
    /tmp/emsdk/emsdk_env.sh
  )
  local c
  for c in "${candidates[@]}"; do
    if [[ -n "$c" && -f "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

do_native_build() {
  local envsh
  if ! envsh="$(find_emsdk_env)"; then
    echo "No emsdk found. Install one, e.g.:" >&2
    echo "  git clone https://github.com/emscripten-core/emsdk.git ~/emsdk" >&2
    echo "  cd ~/emsdk && ./emsdk install 3.1.74 && ./emsdk activate 3.1.74" >&2
    echo "Then:  source ~/emsdk/emsdk_env.sh && USE_NATIVE=1 web/run.sh build" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$envsh"
  export SUBTARGET SOURCES JOBS OPTIMIZE
  export OUT_DIR="web/dist/${SUBTARGET}"
  bash web/build.sh
}

do_docker_build() {
  docker compose -f web/docker-compose.yml build
  docker compose -f web/docker-compose.yml run --rm \
    -e SUBTARGET="$SUBTARGET" \
    -e SOURCES="$SOURCES" \
    -e JOBS="$JOBS" \
    -e OPTIMIZE="$OPTIMIZE" \
    mame-wasm bash web/build.sh
}

case "$ACTION" in
  build|native)
    if use_native; then
      echo "==> Native emsdk build (USE_NATIVE=1)"
      do_native_build
    else
      echo "==> Docker emsdk build"
      echo "    Tip: on Apple Silicon, USE_NATIVE=1 web/run.sh build is much faster."
      do_docker_build
    fi
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
    echo "Usage: $0 {build|native|serve|shell}" >&2
    echo "  USE_NATIVE=1  force host emsdk instead of Docker" >&2
    exit 1
    ;;
esac
