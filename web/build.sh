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
Place abc800c.zip (and any needed device ROMs) here.
See hash/abc800.xml / the driver's ROM definitions for required files.
EOF
fi

echo "==> Artifacts in ${OUT_DIR}:"
ls -lh "${OUT_DIR}"
