#!/bin/bash
# Geometry and mocked scheduled/download APIs only; no account or outgoing work.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROBE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/telegraphica-queue-probe.XXXXXX")"
trap 'rm -rf "$PROBE_DIR"' EXIT
ARCH="${TELEGRAPHICA_TEST_ARCH:-x86_64}"
DEPLOYMENT_TARGET="${TELEGRAPHICA_TEST_DEPLOYMENT_TARGET:-10.8}"
SDK_NAME="${TELEGRAPHICA_TEST_SDK:-macosx}"
CLANG="$(xcrun --sdk "$SDK_NAME" --find clang)"
SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path)"
FLAGS=(-isysroot "$SDK_PATH" -arch "$ARCH" "-mmacosx-version-min=$DEPLOYMENT_TARGET" -fblocks -fno-objc-arc -Wno-deprecated-declarations -I"$ROOT_DIR/Sources/UI" -I"$ROOT_DIR/Sources/Core" -I"$ROOT_DIR/Sources/Services" -I"$ROOT_DIR/Sources/Media")
SOURCES=(Tests/aqua_queue_surfaces_probe.m Sources/UI/TGDownloadCompactPopover.m Sources/UI/TGDownloadManagerPresentation.m Sources/UI/TGDownloadManagerWindowController.m Sources/UI/TGScheduledMessagesShelfView.m Sources/UI/TGScheduledMessagesWindowController.m Sources/Core/TGTDLibClient+ScheduledMessages.m Sources/UI/TGThemeTextField.m Sources/UI/TGAquaShellViews.m Sources/UI/TGLocalization.m Sources/UI/TGTheme.m Sources/UI/TGInterfaceDesign.m Sources/UI/TGDialogPresentation.m Sources/UI/TGAquaAppearance.m Sources/UI/TGVisualWorldThemeSpec.m Sources/UI/TGStatusButtonCells.m Sources/UI/TGButtonAppearance.m Sources/UI/TGIconAssets.m Sources/UI/TGIconDrawing.m Sources/UI/TGAnimationSupport.m Sources/Services/TGResourcePolicy.m)
cd "$ROOT_DIR"
"$CLANG" "${FLAGS[@]}" "${SOURCES[@]}" -framework Cocoa -framework CoreGraphics -o "$PROBE_DIR/probe"
"$PROBE_DIR/probe"
