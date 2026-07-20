# Emscripten SDK image used for MAME → JS/WASM builds.
# Official docs: Emscripten 3.1.35+. Pin a known-good tag.
FROM emscripten/emsdk:3.1.74

# Native genie / python bits expect a few host tools; emsdk image is Debian-based.
USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3 \
        python-is-python3 \
        git \
        pkg-config \
        libsdl2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
# Keep default emsdk entrypoint out of the way; compose/run pass an explicit command.
ENTRYPOINT []
CMD ["bash"]
