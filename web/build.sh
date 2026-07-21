#!/usr/bin/env bash
# Build a MAME SUBTARGET to JavaScript/WebAssembly via Emscripten (emmake).
# Intended to run inside the web/Dockerfile container (cwd = MAME repo root).
set -euo pipefail

# emscripten/emsdk image: activate toolchain when entrypoint was cleared.
if [[ -f /emsdk/emsdk_env.sh ]]; then
  # shellcheck disable=SC1091
  source /emsdk/emsdk_env.sh
fi
export EMSCRIPTEN="${EMSCRIPTEN:-/emsdk/upstream/emscripten}"

SUBTARGET="${SUBTARGET:-abc800c}"
SOURCES="${SOURCES:-src/mame/luxor/abc80x.cpp}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"
OPTIMIZE="${OPTIMIZE:-s}"
OUT_DIR="${OUT_DIR:-web/dist/${SUBTARGET}}"

echo "==> Emscripten build"
echo "    SUBTARGET=${SUBTARGET}"
echo "    SOURCES=${SOURCES}"
echo "    OPTIMIZE=${OPTIMIZE}  JOBS=${JOBS}"
echo "    EMSCRIPTEN=${EMSCRIPTEN}"
emcc -v 2>&1 | head -3

# Genie needs a writable tree; keep REGENIE=1 so asmjs project files regenerate.
emmake make \
  -j"${JOBS}" \
  SUBTARGET="${SUBTARGET}" \
  SOURCES="${SOURCES}" \
  REGENIE=1 \
  WEBASSEMBLY=1 \
  TOOLS=0 \
  OPTIMIZE="${OPTIMIZE}" \
  NOWERROR=1

# emmake places ${SUBTARGET}.{html,js,wasm} (and possibly .worker.js) in the repo root.
mkdir -p "${OUT_DIR}"
shopt -s nullglob
for f in \
  "${SUBTARGET}.html" \
  "${SUBTARGET}.js" \
  "${SUBTARGET}.wasm" \
  "${SUBTARGET}.worker.js" \
  "${SUBTARGET}.js.mem"
do
  if [[ -f "$f" ]]; then
    cp -v "$f" "${OUT_DIR}/"
  fi
done

# Convenience copies with a stable "mame" basename for simple loaders.
if [[ -f "${OUT_DIR}/${SUBTARGET}.js" ]]; then
  cp -f "${OUT_DIR}/${SUBTARGET}.js" "${OUT_DIR}/mame.js"
fi
if [[ -f "${OUT_DIR}/${SUBTARGET}.wasm" ]]; then
  cp -f "${OUT_DIR}/${SUBTARGET}.wasm" "${OUT_DIR}/mame.wasm"
fi
if [[ -f "${OUT_DIR}/${SUBTARGET}.html" ]]; then
  cp -f "${OUT_DIR}/${SUBTARGET}.html" "${OUT_DIR}/mame.html"
fi

# Drop a tiny launcher that defaults to abc800c and points at ./roms
cp -f web/public/index.html "${OUT_DIR}/index.html"
mkdir -p "${OUT_DIR}/roms"
if [[ ! -f "${OUT_DIR}/roms/README.txt" ]]; then
  cat > "${OUT_DIR}/roms/README.txt" <<'EOF'
WASM ROM folder (served over HTTP, then mounted into the browser build).

This is NOT the same as repo-root roms/ used by native ./abc.
Run:  web/sync-roms.sh

Required for abc800c:
  abc800c.zip   system ROMs
  saa5052.zip   teletext character generator (device)
  abc800kb.zip  keyboard MCU (device)
  abc830.zip    default floppy controller on ABC bus (device)
EOF
fi
# Convenience: if repo-root roms/ exists, refresh the serve copy.
if [[ -d roms ]] && compgen -G "roms/*.zip" > /dev/null; then
  echo "==> Syncing roms/*.zip from repo root into ${OUT_DIR}/roms/"
  cp -f roms/*.zip "${OUT_DIR}/roms/"
fi

echo "==> Artifacts in ${OUT_DIR}:"
ls -lh "${OUT_DIR}"
