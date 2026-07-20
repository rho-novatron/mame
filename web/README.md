# ABC 800 C — MAME JavaScript / WebAssembly build

Dockerized Emscripten build for a small MAME subset that includes **abc800c**
(and the other drivers in `src/mame/luxor/abc80x.cpp`: abc800m, abc802, abc806, …).

Uses the official [`emscripten/emsdk`](https://hub.docker.com/r/emscripten/emsdk) image
(pinned to **3.1.74**, which satisfies MAME’s ≥ 3.1.35 requirement).

## Quick start

From the MAME repo root (Docker Desktop running):

```bash
chmod +x web/run.sh web/build.sh
web/run.sh build          # ~tens of minutes first time (SDL ports + compile)
web/run.sh serve          # http://127.0.0.1:8000/
```

Open the page, place `roms/abc800c.zip` under `web/dist/abc800c/roms/`, reload.

## What you get

```
web/dist/abc800c/
  abc800c.html   # Emscripten shell (also usable)
  abc800c.js
  abc800c.wasm
  index.html     # Small custom launcher (defaults to abc800c)
  mame.js / mame.wasm / mame.html   # stable aliases
  roms/          # drop ZIP ROMs here
```

## Other machines from the same sources

```bash
SUBTARGET=abc806 web/run.sh build
SOURCES=src/mame/luxor/abc80x.cpp SUBTARGET=abc800m web/run.sh build
```

## Manual Docker

```bash
docker compose -f web/docker-compose.yml build
docker compose -f web/docker-compose.yml run --rm \
  -e SUBTARGET=abc800c \
  -e SOURCES=src/mame/luxor/abc80x.cpp \
  -e JOBS=8 -e OPTIMIZE=s \
  mame-wasm "web/build.sh"
```

On Apple Silicon the compose file forces `platform: linux/amd64` (emsdk image).

## Notes

- First build downloads SDL2 via Emscripten ports into a named volume `emsdk-cache`.
- `OPTIMIZE=s` keeps the `.wasm` smaller; use `OPTIMIZE=2` for speed.
- Do not open the HTML as a `file://` URL — browsers block WASM that way; use `web/run.sh serve`.
- Official MAME docs: [Emscripten Javascript and HTML](https://docs.mamedev.org/initialsetup/compilingmame.html#emscripten-javascript-and-html).
