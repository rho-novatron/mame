# ABC 800 C — MAME JavaScript / WebAssembly build

Emscripten build for a small MAME subset that includes **abc800c**
(and the other drivers in `src/mame/luxor/abc80x.cpp`: abc800m, abc802, abc806, …).

Two ways to build:

1. **Docker** — official [`emscripten/emsdk`](https://hub.docker.com/r/emscripten/emsdk) **3.1.74**
2. **Native emsdk** — same version, much faster on Apple Silicon (avoids `linux/amd64` QEMU)

## Quick start

From the MAME repo root:

```bash
chmod +x web/run.sh web/build.sh

# Preferred on Apple Silicon / when emsdk is installed locally:
USE_NATIVE=1 web/run.sh build
# or:  web/run.sh native

# Or Docker (works everywhere Docker can run linux/amd64):
web/run.sh build

web/run.sh serve          # http://127.0.0.1:8000/
```

Copy ROMs into the serve tree (not repo-root `roms/`):

```bash
web/sync-roms.sh          # copies roms/*.zip → web/dist/abc800c/roms/
web/run.sh serve
```

Required ZIPs for **abc800c**: `abc800c.zip`, `saa5052.zip`, `abc800kb.zip`, `abc830.zip`
(the driver defaults to an abc830 floppy on the ABC bus). The page loader fetches
these over HTTP into Emscripten's virtual `roms/` folder before MAME starts.

### Native emsdk setup (once)

```bash
git clone https://github.com/emscripten-core/emsdk.git ~/emsdk
cd ~/emsdk && ./emsdk install 3.1.74 && ./emsdk activate 3.1.74
source ~/emsdk/emsdk_env.sh
```

`web/run.sh` also looks for `/tmp/emsdk` and `$EMSDK`.

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

Verified smoke build: ~22 MB `abc800c.wasm`, drivers from `abc80x.cpp`.

## Other machines from the same sources

```bash
SUBTARGET=abc806 USE_NATIVE=1 web/run.sh build
SOURCES=src/mame/luxor/abc80x.cpp SUBTARGET=abc800m USE_NATIVE=1 web/run.sh build
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
That works but is slow under QEMU — use `USE_NATIVE=1` instead.

## Notes

- First build downloads SDL2 via Emscripten ports (Docker: named volume `emsdk-cache`).
- `OPTIMIZE=s` keeps the `.wasm` smaller; use `OPTIMIZE=2` for speed.
- Do not open the HTML as a `file://` URL — browsers block WASM that way; use `web/run.sh serve`.
- If you switch between Docker and native builds, wipe `build/projects/sdl/mameabc800c` and `build/asmjs` so Genie does not reuse absolute paths from the other environment.
- Official MAME docs: [Emscripten Javascript and HTML](https://docs.mamedev.org/initialsetup/compilingmame.html#emscripten-javascript-and-html).
