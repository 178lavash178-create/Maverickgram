#!/bin/bash
# Synthetic large JPEG only; no account data, screenshots, TDLib or network.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BENCH_DIR="$(mktemp -d "${TMPDIR:-/tmp}/telegraphica-gallery-bench.XXXXXX")"
trap 'rm -rf "$BENCH_DIR"' EXIT
ARCH="${TELEGRAPHICA_TEST_ARCH:-x86_64}"
DEPLOYMENT_TARGET="${TELEGRAPHICA_TEST_DEPLOYMENT_TARGET:-10.8}"
SDK_NAME="${TELEGRAPHICA_TEST_SDK:-macosx}"
CLANG="$(xcrun --sdk "$SDK_NAME" --find clang)"
SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path)"
FLAGS=(-isysroot "$SDK_PATH" -arch "$ARCH" "-mmacosx-version-min=$DEPLOYMENT_TARGET" -fblocks -fno-objc-arc -I"$ROOT_DIR/Sources/Media")
"$CLANG" "${FLAGS[@]}" -DCGImageSourceCreateThumbnailAtIndex=TGProbeCreateThumbnail -DCGImageSourceCreateImageAtIndex=TGProbeCreateImage -DCGContextDrawImage=TGProbeDrawImage -c "$ROOT_DIR/Sources/Media/TGMediaImageLoader.m" -o "$BENCH_DIR/loader.o"
"$CLANG" "${FLAGS[@]}" "$ROOT_DIR/Tests/gallery_image_loader_probe.m" "$BENCH_DIR/loader.o" -framework Cocoa -framework ImageIO -framework CoreGraphics -o "$BENCH_DIR/probe"
"$BENCH_DIR/probe"
