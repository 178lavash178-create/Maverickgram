#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python)"
else
    echo "python3 or python is required to run Telegraphica tests."
    exit 1
fi

ARCH="${TELEGRAPHICA_TEST_ARCH:-x86_64}"
DEPLOYMENT_TARGET="${TELEGRAPHICA_TEST_DEPLOYMENT_TARGET:-10.8}"
SDK_NAME="${TELEGRAPHICA_TEST_SDK:-macosx}"
if xcodebuild -showsdks 2>/dev/null | grep -q "macosx10\.9"; then
    SDK_NAME="${TELEGRAPHICA_TEST_SDK:-macosx10.9}"
fi

CLANG="$(xcrun --sdk "$SDK_NAME" --find clang 2>/dev/null || xcrun -f clang 2>/dev/null || command -v clang || true)"
if [ -z "$CLANG" ]; then
    echo "clang is required to compile Telegraphica test probes."
    exit 1
fi

SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path 2>/dev/null || true)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/telegraphica-tests.XXXXXX")"
TEST_HOME="$BUILD_DIR/home"
mkdir -p "$TEST_HOME"

cleanup() {
    rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

echo "== Telegraphica static compatibility =="
"$PYTHON_BIN" scripts/check_legacy_compat.py
"$PYTHON_BIN" Tests/legacy_include_scanner_probe.py
"$PYTHON_BIN" scripts/test_call_transport_staging.py
"$PYTHON_BIN" scripts/check_free_feature_policy.py
"$PYTHON_BIN" scripts/test_static_project.py
"$PYTHON_BIN" scripts/test_security_hardening.py
"$PYTHON_BIN" Tests/notification_logout_routing_probe.py

echo "== Shell syntax =="
bash -n build_legacy.sh
for script in scripts/*.sh; do
    bash -n "$script"
done

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "== Whitespace =="
    # Unified patch payloads intentionally contain context whitespace.
    git diff --check -- . ':(exclude)Vendor/patches/*.patch'
fi

echo "== Mock TDLib event reducer =="
"$PYTHON_BIN" Tests/mock_tdlib_event_probe.py

echo "== Workshop game logic =="
Tests/Workshop/run_game_tests.sh

echo "== Workshop installer state =="
Tests/Workshop/run_installer_state_tests.sh

echo "== Media Workbench =="
Tests/Workshop/run_media_workbench_tests.sh

echo "== Media preview gate =="
scripts/check_media_item_support.sh "$ARCH" "$BUILD_DIR/media-item-support" "$SDK_NAME"

COMPILE_FLAGS=(
    -arch "$ARCH"
    "-mmacosx-version-min=$DEPLOYMENT_TARGET"
    -fblocks
    -fno-objc-arc
    -I"$ROOT_DIR/Sources/Core"
    -I"$ROOT_DIR/Sources/Media"
    -I"$ROOT_DIR/Sources/Services"
    -I"$ROOT_DIR/Sources/UI"
)
if [ -n "$SDK_PATH" ]; then
    COMPILE_FLAGS+=("-isysroot" "$SDK_PATH")
fi

echo "== Actual theme surface readability =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/theme_readability_probe.m Sources/UI/TGLocalization.m Sources/UI/TGTheme.m Sources/UI/TGInterfaceDesign.m Sources/UI/TGAquaAppearance.m Sources/UI/TGVisualWorldThemeSpec.m -framework Cocoa -o "$BUILD_DIR/theme-readability-probe"
HOME="$TEST_HOME" "$BUILD_DIR/theme-readability-probe"

echo "== Themed controls and utility surfaces =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/utility_surface_contrast_probe.m Sources/UI/TGDownloadProgressWindowController.m Sources/UI/TGThemeTextField.m Sources/Core/TGChatItem.m Sources/Workshop/UI/TGWorkshopModuleCardView.m Sources/Workshop/UI/TGWorkshopButtonCell.m Sources/Workshop/UI/TGWorkshopSurfaceView.m Sources/UI/TGIconAssets.m Sources/UI/TGTheme.m Sources/UI/TGInterfaceDesign.m Sources/UI/TGAquaAppearance.m Sources/UI/TGVisualWorldThemeSpec.m -framework Cocoa -o "$BUILD_DIR/utility-surface-contrast-probe"
HOME="$TEST_HOME" "$BUILD_DIR/utility-surface-contrast-probe"
BUTTON_APP="$BUILD_DIR/ButtonProbe.app"
mkdir -p "$BUTTON_APP/Contents/MacOS" "$BUTTON_APP/Contents/Resources"
cp -R Sources/Resources/Icons "$BUTTON_APP/Contents/Resources/Icons"
cat > "$BUTTON_APP/Contents/Info.plist" <<'BUTTON_PLIST'
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>button-probe</string><key>CFBundleIdentifier</key><string>local.telegraphica.button-probe</string><key>CFBundlePackageType</key><string>APPL</string></dict></plist>
BUTTON_PLIST
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/button_appearance_probe.m Sources/UI/TGStatusButtonCells.m Sources/UI/TGLocalization.m Sources/UI/TGTheme.m Sources/UI/TGInterfaceDesign.m Sources/UI/TGAquaAppearance.m Sources/UI/TGVisualWorldThemeSpec.m -framework Cocoa -o "$BUTTON_APP/Contents/MacOS/button-probe"
HOME="$TEST_HOME" "$BUTTON_APP/Contents/MacOS/button-probe"

echo "== Asynchronous animated image loader =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    Tests/animated_image_loader_probe.m \
    Sources/Media/TGAnimatedImageLoader.m \
    -framework Cocoa \
    -framework ImageIO \
    -o "$BUILD_DIR/animated-image-loader-probe"
HOME="$TEST_HOME" "$BUILD_DIR/animated-image-loader-probe"

echo "== Utility window request lifetime =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    Tests/utility_window_lifetime_probe.m \
    Sources/UI/TGUtilityWindowLifetime.m \
    -framework Foundation \
    -o "$BUILD_DIR/utility-window-lifetime-probe"
HOME="$TEST_HOME" "$BUILD_DIR/utility-window-lifetime-probe"

echo "== Legacy accessibility support =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    Tests/accessibility_support_probe.m \
    Sources/UI/TGAccessibilitySupport.m \
    Sources/UI/TGLocalization.m \
    Sources/Core/TGChatItem.m \
    Sources/Core/TGMessageItem.m \
    -framework Cocoa \
    -o "$BUILD_DIR/accessibility-support-probe"
HOME="$TEST_HOME" "$BUILD_DIR/accessibility-support-probe"

echo "== Persistent download queue =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    Tests/download_queue_store_probe.m \
    Sources/Services/TGDownloadQueueStore.m \
    -framework Foundation \
    -o "$BUILD_DIR/download-queue-store-probe"
HOME="$TEST_HOME" "$BUILD_DIR/download-queue-store-probe"

echo "== Persistent full-file downloads =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/persistent_file_download_probe.m Sources/Core/TGPersistentFileDownload.m -framework Foundation -o "$BUILD_DIR/persistent-file-download-probe"
HOME="$TEST_HOME" "$BUILD_DIR/persistent-file-download-probe"

echo "== Download cancellation and client ownership =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/download_manager_probe.m Sources/Services/TGDownloadManager.m Sources/Services/TGDownloadQueueStore.m -framework Cocoa -o "$BUILD_DIR/download-manager-probe"
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/download_pause_probe.m Sources/Services/TGDownloadManager.m Sources/Services/TGDownloadQueueStore.m -framework Cocoa -o "$BUILD_DIR/download-pause-probe"
HOME="$TEST_HOME" "$BUILD_DIR/download-manager-probe"
HOME="$TEST_HOME" "$BUILD_DIR/download-pause-probe"

echo "== Download identity after restart =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/download_restart_identity_probe.m Sources/Services/TGDownloadManager.m Sources/Services/TGDownloadQueueStore.m -framework Cocoa -o "$BUILD_DIR/download-restart-identity-probe"
HOME="$TEST_HOME" "$BUILD_DIR/download-restart-identity-probe"

echo "== Download manager layout and themes =="
"$CLANG" "${COMPILE_FLAGS[@]}" -I"$ROOT_DIR/Sources/UI" -I"$ROOT_DIR/Sources/Services" -I"$ROOT_DIR/Sources/Media" Tests/download_manager_presentation_probe.m Sources/UI/TGDownloadManagerPresentation.m Sources/UI/TGDownloadManagerWindowController.m Sources/UI/TGLocalization.m Sources/UI/TGTheme.m Sources/UI/TGInterfaceDesign.m Sources/UI/TGAquaAppearance.m Sources/UI/TGVisualWorldThemeSpec.m Sources/UI/TGStatusButtonCells.m Sources/UI/TGButtonAppearance.m Sources/UI/TGIconAssets.m Sources/UI/TGIconDrawing.m -framework Cocoa -framework CoreGraphics -o "$BUILD_DIR/download-manager-presentation-probe"
HOME="$TEST_HOME" "$BUILD_DIR/download-manager-presentation-probe"

echo "== Nonblocking download progress presentation =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/download_progress_presentation_probe.m Sources/UI/TGDownloadProgressWindowController.m -framework Cocoa -o "$BUILD_DIR/download-progress-presentation-probe"
HOME="$TEST_HOME" "$BUILD_DIR/download-progress-presentation-probe"

echo "== Media Center save lifecycle =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/media_center_save_probe.m -framework Cocoa -o "$BUILD_DIR/media-center-save-probe"
HOME="$TEST_HOME" "$BUILD_DIR/media-center-save-probe"

echo "== Guarded modal file export =="
"$CLANG" "${COMPILE_FLAGS[@]}" -I"$ROOT_DIR/Sources/Media" Tests/media_file_guarded_save_probe.m Sources/Media/TGMediaFileActions.m -framework Cocoa -o "$BUILD_DIR/media-file-guarded-save-probe"
HOME="$TEST_HOME" "$BUILD_DIR/media-file-guarded-save-probe"

echo "== TDLib capability registry =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/tdlib_capabilities_probe.m \
    Sources/Core/TGTDLibCapabilities.m \
    -framework Foundation \
    -o "$BUILD_DIR/tdlib_capabilities_probe"

HOME="$TEST_HOME" "$BUILD_DIR/tdlib_capabilities_probe"

echo "== TDLib message search requests =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    -Wno-incomplete-implementation \
    -Wno-objc-protocol-method-implementation \
    Tests/tdlib_search_request_probe.m \
    Sources/Core/TGTDLibClient+Search.m \
    -framework Foundation \
    -o "$BUILD_DIR/tdlib-search-request-probe"
HOME="$TEST_HOME" "$BUILD_DIR/tdlib-search-request-probe"

echo "== Message comments and thread navigation =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    -Wno-incomplete-implementation -Wno-objc-protocol-method-implementation \
    Tests/message_thread_probe.m \
    Sources/Core/TGMessageThreadSupport.m \
    Sources/Core/TGMessageItem.m \
    Sources/Core/TGTDLibClient+MessageThreads.m \
    -framework Foundation -o "$BUILD_DIR/message-thread-probe"
HOME="$TEST_HOME" "$BUILD_DIR/message-thread-probe"

echo "== Open chat subscription lifecycle =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    Tests/chat_open_state_probe.m Sources/Core/TGChatOpenState.m \
    -framework Foundation -o "$BUILD_DIR/chat-open-state-probe"
HOME="$TEST_HOME" "$BUILD_DIR/chat-open-state-probe"

echo "== Message reaction schemas =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    Tests/message_reactions_probe.m Sources/Core/TGMessageReactionParser.m \
    -framework Foundation -o "$BUILD_DIR/message-reactions-probe"
HOME="$TEST_HOME" "$BUILD_DIR/message-reactions-probe"

echo "== Forum refresh navigation =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    Tests/forum_topic_refresh_probe.m Sources/Core/TGChatItem.m \
    -framework Foundation -o "$BUILD_DIR/forum-topic-refresh-probe"
HOME="$TEST_HOME" "$BUILD_DIR/forum-topic-refresh-probe"

echo "== Thumbnail cache eviction recovery =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    Tests/thumbnail_prefetcher_probe.m \
    Sources/Media/TGMessageThumbnailPrefetcher.m Sources/Core/TGMessageItem.m \
    -framework Cocoa -o "$BUILD_DIR/thumbnail-prefetcher-probe"
HOME="$TEST_HOME" "$BUILD_DIR/thumbnail-prefetcher-probe"

echo "== Logger redaction =="
"$CLANG" "${COMPILE_FLAGS[@]}" \
    Tests/logger_redaction_probe.m Sources/Services/TGLogger.m \
    -framework Cocoa -o "$BUILD_DIR/logger-redaction-probe"
HOME="$TEST_HOME" "$BUILD_DIR/logger-redaction-probe"

echo "== TDLib storage requests =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    -Wno-incomplete-implementation \
    -Wno-objc-protocol-method-implementation \
    Tests/tdlib_storage_request_probe.m \
    Sources/Core/TGTDLibClient+Storage.m \
    Sources/Services/TGStorageCleanupPolicy.m \
    -framework Foundation \
    -o "$BUILD_DIR/tdlib-storage-request-probe"
HOME="$TEST_HOME" "$BUILD_DIR/tdlib-storage-request-probe"

echo "== TDLib file requests =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    -Wno-incomplete-implementation \
    -Wno-objc-protocol-method-implementation \
    Tests/tdlib_file_request_probe.m \
    Sources/Core/TGTDLibClient+Files.m \
    Sources/Core/TGPersistentFileDownload.m \
    -framework Foundation \
    -o "$BUILD_DIR/tdlib-file-request-probe"
HOME="$TEST_HOME" "$BUILD_DIR/tdlib-file-request-probe"

echo "== TDLib stable file identity =="
"$CLANG" "${COMPILE_FLAGS[@]}" -I"$ROOT_DIR/Sources/Core" -Wno-incomplete-implementation -Wno-objc-protocol-method-implementation Tests/tdlib_file_identity_probe.m Sources/Core/TGTDLibClient+Files.m Sources/Core/TGPersistentFileDownload.m -framework Foundation -o "$BUILD_DIR/tdlib-file-identity-probe"
HOME="$TEST_HOME" "$BUILD_DIR/tdlib-file-identity-probe"

echo "== TDLib account requests =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    -Wno-incomplete-implementation \
    -Wno-objc-protocol-method-implementation \
    Tests/tdlib_account_request_probe.m \
    Sources/Core/TGTDLibClient+Account.m \
    -framework Foundation \
    -o "$BUILD_DIR/tdlib-account-request-probe"
HOME="$TEST_HOME" "$BUILD_DIR/tdlib-account-request-probe"

echo "== Authorization flow fixtures =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/authorization_flow_probe.m \
    Sources/Core/TGAuthorizationFlow.m \
    -framework Foundation \
    -o "$BUILD_DIR/authorization_flow_probe"

HOME="$TEST_HOME" "$BUILD_DIR/authorization_flow_probe"

echo "== Formatted text codec =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/formatted_text_codec_probe.m \
    Sources/Core/TGFormattedTextCodec.m \
    -framework Foundation \
    -o "$BUILD_DIR/formatted_text_codec_probe"

HOME="$TEST_HOME" "$BUILD_DIR/formatted_text_codec_probe"

echo "== Secret chat key visualization =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/secret_chat_key_probe.m \
    Sources/Core/TGSecretChatKey.m \
    -framework Foundation \
    -o "$BUILD_DIR/secret_chat_key_probe"

HOME="$TEST_HOME" "$BUILD_DIR/secret_chat_key_probe"

echo "== Server reaction catalog =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/reaction_catalog_probe.m \
    Sources/Core/TGReactionCatalog.m \
    -framework Foundation \
    -o "$BUILD_DIR/reaction_catalog_probe"

HOME="$TEST_HOME" "$BUILD_DIR/reaction_catalog_probe"

echo "== Added reaction users =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/added_reactions_probe.m \
    Sources/Core/TGAddedReactionsParser.m \
    -framework Foundation \
    -o "$BUILD_DIR/added_reactions_probe"

HOME="$TEST_HOME" "$BUILD_DIR/added_reactions_probe"

echo "== Cancellable TDLib operation =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/tdlib_operation_probe.m \
    Sources/Core/TGTDLibOperation.m \
    -framework Foundation \
    -o "$BUILD_DIR/tdlib_operation_probe"

HOME="$TEST_HOME" "$BUILD_DIR/tdlib_operation_probe"

echo "== Media image loader =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/media_image_loader_probe.m \
    Sources/Media/TGMediaImageLoader.m \
    Sources/Media/TGMessageThumbnailPrefetcher.m \
    Sources/Core/TGMessageItem.m \
    -framework Cocoa \
    -framework ImageIO \
    -o "$BUILD_DIR/media_image_loader_probe"

HOME="$TEST_HOME" "$BUILD_DIR/media_image_loader_probe"

echo "== Sticker thumbnail pipeline =="
"$PYTHON_BIN" scripts/test_sticker_thumbnail_pipeline.py

echo "== Media playback speed preferences =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/media_playback_preferences_probe.m \
    Sources/Media/TGMediaPlaybackPreferences.m \
    -framework Foundation \
    -o "$BUILD_DIR/media_playback_preferences_probe"
HOME="$TEST_HOME" "$BUILD_DIR/media_playback_preferences_probe"

echo "== Sequential audio playback =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/media_playback_sequence_probe.m \
    Sources/Media/TGMediaPlaybackSequence.m \
    Sources/Core/TGMessageItem.m \
    -framework Foundation \
    -o "$BUILD_DIR/media_playback_sequence_probe"
HOME="$TEST_HOME" "$BUILD_DIR/media_playback_sequence_probe"

echo "== Storage cleanup filters =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/storage_cleanup_policy_probe.m \
    Sources/Services/TGStorageCleanupPolicy.m \
    -framework Foundation \
    -o "$BUILD_DIR/storage_cleanup_policy_probe"
HOME="$TEST_HOME" "$BUILD_DIR/storage_cleanup_policy_probe"

echo "== Custom emoji descriptors =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/custom_emoji_parser_probe.m \
    Sources/Core/TGCustomEmojiParser.m \
    -framework Foundation \
    -o "$BUILD_DIR/custom_emoji_parser_probe"

HOME="$TEST_HOME" "$BUILD_DIR/custom_emoji_parser_probe" Tests/Fixtures/custom_emoji_stickers.json

echo "== Advanced chat folders =="
"$CLANG" \
    "${COMPILE_FLAGS[@]}" \
    Tests/chat_folder_support_probe.m \
    Sources/Core/TGChatFolderSupport.m \
    -framework Foundation \
    -o "$BUILD_DIR/chat_folder_support_probe"

HOME="$TEST_HOME" "$BUILD_DIR/chat_folder_support_probe" Tests/Fixtures/chat_folder_advanced.json

echo "== Composer keyboard and image Escape =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/keyboard_input_probe.m Sources/UI/TGKeyboardInputSupport.m -framework Cocoa -o "$BUILD_DIR/keyboard-input-probe"
HOME="$TEST_HOME" "$BUILD_DIR/keyboard-input-probe"

echo "== Account avatar presentation =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/avatar_image_presentation_probe.m Sources/UI/TGAvatarImagePresentation.m Sources/Media/TGMediaImageLoader.m -framework Cocoa -framework ImageIO -o "$BUILD_DIR/avatar-image-presentation-probe"
HOME="$TEST_HOME" "$BUILD_DIR/avatar-image-presentation-probe"

echo "== Interface motion and transparent spinner =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/interface_motion_probe.m Sources/UI/TGAnimationSupport.m Sources/UI/TGTranscriptMotion.m Sources/UI/TGTransparentSpinnerView.m Sources/Services/TGResourcePolicy.m -framework Cocoa -o "$BUILD_DIR/interface-motion-probe"
HOME="$TEST_HOME" "$BUILD_DIR/interface-motion-probe"

echo "== Main section transitions =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/section_transition_probe.m Sources/UI/TGSectionTransition.m Sources/UI/TGAnimationSupport.m Sources/Services/TGResourcePolicy.m -framework Cocoa -o "$BUILD_DIR/section-transition-probe"
HOME="$TEST_HOME" "$BUILD_DIR/section-transition-probe"

echo "== Visible conversation automatic-read gate =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/conversation_visibility_probe.m Sources/UI/TGConversationVisibility.m -framework Cocoa -o "$BUILD_DIR/conversation-visibility-probe"
HOME="$TEST_HOME" "$BUILD_DIR/conversation-visibility-probe"

echo "== Automatic TDLib read receipts =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/automatic_read_probe.m Sources/Core/TGTDLibClient+ReadReceipts.m Sources/Core/TGChatOpenState.m -framework Foundation -o "$BUILD_DIR/automatic-read-probe"

echo "== Automatic read visibility integration =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/automatic_read_visibility_integration_probe.m Sources/UI/TGConversationVisibility.m -framework Cocoa -o "$BUILD_DIR/automatic-read-visibility-integration-probe"
HOME="$TEST_HOME" "$BUILD_DIR/automatic-read-visibility-integration-probe"

"$BUILD_DIR/automatic-read-probe"

echo "== Notification read cleanup =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/notification_read_state_probe.m Sources/Core/TGNotificationReadState.m Sources/Core/TGChatItem.m Sources/UI/TGNotificationDeliverySupport.m -framework Cocoa -o "$BUILD_DIR/notification-read-state-probe"
HOME="$TEST_HOME" "$BUILD_DIR/notification-read-state-probe"

echo "== Authoritative notification mute policy =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/notification_mute_policy_probe.m Sources/Core/TGNotificationMuteState.m Sources/Core/TGNotificationReadState.m Sources/Core/TGChatItem.m Sources/UI/TGNotificationDeliverySupport.m -framework Cocoa -o "$BUILD_DIR/notification-mute-policy-probe"
HOME="$TEST_HOME" "$BUILD_DIR/notification-mute-policy-probe"

echo "== Chat unread badge contrast =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/chat_unread_badge_probe.m Sources/UI/TGChatUnreadBadgeAppearance.m Sources/UI/TGLocalization.m Sources/UI/TGTheme.m Sources/UI/TGInterfaceDesign.m Sources/UI/TGAquaAppearance.m Sources/UI/TGVisualWorldThemeSpec.m -framework Cocoa -o "$BUILD_DIR/chat-unread-badge-probe"
HOME="$TEST_HOME" "$BUILD_DIR/chat-unread-badge-probe"

echo "== Notification enrichment ownership =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/notification_chat_info_probe.m Sources/Core/TGChatItem.m -framework Foundation -o "$BUILD_DIR/notification-chat-info-probe"
HOME="$TEST_HOME" "$BUILD_DIR/notification-chat-info-probe"

echo "== Notification logout completion ownership =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/notification_logout_completion_probe.m -framework Foundation -o "$BUILD_DIR/notification-logout-completion-probe"
HOME="$TEST_HOME" "$BUILD_DIR/notification-logout-completion-probe"

echo "== Reaction glyph pixel alignment =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/reaction_glyph_alignment_probe.m Sources/UI/TGReactionChipLayout.m -framework Cocoa -o "$BUILD_DIR/reaction-glyph-alignment-probe"
HOME="$TEST_HOME" "$BUILD_DIR/reaction-glyph-alignment-probe"

# Shared production sources for layout/receipt probes.
MESSAGE_PROBE_SOURCES=(
    Sources/Core/TGMessageItem.m
    Sources/Core/TGMessagePollSupport.m
    Sources/Core/TGOutgoingMessageTextChunker.m
    Sources/Core/TGCustomEmojiParser.m
    Sources/Media/TGMediaItemSupport.m
    Sources/Media/TGOpusVoiceTranscoder.m
    Sources/Services/TGLogger.m
    Sources/Services/TGResourcePolicy.m
    Sources/UI/TGChatDisplayPreferences.m
    Sources/UI/TGLocalization.m
    Sources/UI/TGMessageLayoutSupport.m
    Sources/UI/TGMessageFooterAppearance.m
    Sources/UI/TGReactionChipLayout.m
    Sources/UI/TGTheme.m
    Sources/UI/TGInterfaceDesign.m
    Sources/UI/TGAquaAppearance.m
    Sources/UI/TGVisualWorldThemeSpec.m
)

echo "== Core logic probe =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/core_logic_probe.m "${MESSAGE_PROBE_SOURCES[@]}" \
    -framework Cocoa -o "$BUILD_DIR/core_logic_probe"
HOME="$TEST_HOME" "$BUILD_DIR/core_logic_probe"

echo "== Receipt asset raster visibility =="
RECEIPT_PROBE_BUNDLE="$BUILD_DIR/ReceiptRasterProbe.app"
mkdir -p "$RECEIPT_PROBE_BUNDLE/Contents/MacOS" "$RECEIPT_PROBE_BUNDLE/Contents/Resources/Icons"
cp Sources/Resources/Icons/done-mini.png "$RECEIPT_PROBE_BUNDLE/Contents/Resources/Icons/done-mini.png"
cat > "$RECEIPT_PROBE_BUNDLE/Contents/Info.plist" <<'RECEIPT_PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>receipt-raster-probe</string>
<key>CFBundleIdentifier</key><string>local.telegraphica.receipt-raster-probe</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
RECEIPT_PLIST
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/receipt_raster_probe.m "${MESSAGE_PROBE_SOURCES[@]}" \
    Sources/UI/TGIconAssets.m -framework Cocoa -o "$RECEIPT_PROBE_BUNDLE/Contents/MacOS/receipt-raster-probe"
HOME="$TEST_HOME" "$RECEIPT_PROBE_BUNDLE/Contents/MacOS/receipt-raster-probe"


echo "Telegraphica tests passed."

echo "== Interface design restart =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/interface_design_probe.m -framework Cocoa -o "$BUILD_DIR/interface-design-probe"
HOME="$TEST_HOME" "$BUILD_DIR/interface-design-probe"
HOME="$TEST_HOME" "$BUILD_DIR/interface-design-probe" aqua

echo "== Aqua surfaces and footer =="
AQUA_PROBE_BUNDLE="$BUILD_DIR/AquaMaterialProbe.app"
mkdir -p "$AQUA_PROBE_BUNDLE/Contents/MacOS" "$AQUA_PROBE_BUNDLE/Contents/Resources"
cp -R Sources/Resources/Textures "$AQUA_PROBE_BUNDLE/Contents/Resources/"
cat > "$AQUA_PROBE_BUNDLE/Contents/Info.plist" <<'AQUA_PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>aqua-material-probe</string>
<key>CFBundleIdentifier</key><string>local.telegraphica.aqua-material-probe</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
AQUA_PLIST
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/aqua_material_probe.m Sources/UI/TGTheme.m Sources/UI/TGVisualWorldThemeSpec.m Sources/UI/TGAquaAppearance.m Sources/UI/TGInterfaceDesign.m Sources/UI/TGLocalization.m -framework Cocoa -o "$AQUA_PROBE_BUNDLE/Contents/MacOS/aqua-material-probe"
HOME="$TEST_HOME" "$AQUA_PROBE_BUNDLE/Contents/MacOS/aqua-material-probe" -TelegraphicaInterfaceDesign aqua -TelegraphicaThemeIdentifier visual-space-terminal
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/aqua_footer_probe.m "${MESSAGE_PROBE_SOURCES[@]}" Sources/UI/TGIconAssets.m -framework Cocoa -o "$BUILD_DIR/aqua-footer-probe"
HOME="$TEST_HOME" "$BUILD_DIR/aqua-footer-probe" classic
HOME="$TEST_HOME" "$BUILD_DIR/aqua-footer-probe" aqua

echo "== Aqua source list geometry =="
"$PYTHON_BIN" Tests/message_jump_visibility_probe.py "$CLANG" "${COMPILE_FLAGS[@]}"
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/aqua_media_center_layout_probe.m -framework Cocoa -o "$BUILD_DIR/aqua-media-center-layout-probe"
HOME="$TEST_HOME" "$BUILD_DIR/aqua-media-center-layout-probe"
"$PYTHON_BIN" Tests/aqua_section_routing_probe.py "$CLANG" "${COMPILE_FLAGS[@]}"
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/aqua_shell_layout_probe.m Sources/UI/TGAquaShellLayout.m -framework Cocoa -o "$BUILD_DIR/aqua-shell-layout-probe"
HOME="$TEST_HOME" "$BUILD_DIR/aqua-shell-layout-probe"
"$PYTHON_BIN" Tests/aqua_settings_chrome_probe.py "$CLANG" "${COMPILE_FLAGS[@]}"
"$PYTHON_BIN" Tests/aqua_folder_chrome_probe.py "$CLANG" "${COMPILE_FLAGS[@]}"

echo "== Closed-chat suggestions =="
"$CLANG" "${COMPILE_FLAGS[@]}" -ISources/Core Tests/closed_chat_suggestions_probe.m Sources/Core/TGChatItem.m -framework Cocoa -o "$BUILD_DIR/closed_chat_suggestions_probe"
HOME="$TEST_HOME" "$BUILD_DIR/closed_chat_suggestions_probe"

echo "== Account badge bounds =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/account_badge_geometry_probe.m Sources/UI/TGStatusViewComponents.m -framework Cocoa -o "$BUILD_DIR/account_badge_geometry_probe"
HOME="$TEST_HOME" "$BUILD_DIR/account_badge_geometry_probe"

echo "== Aqua local chat backgrounds =="
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/aqua_chat_background_probe.m Sources/UI/TGAquaChatBackground.m -framework Cocoa -framework ImageIO -o "$BUILD_DIR/aqua-chat-background-probe"
HOME="$TEST_HOME" "$BUILD_DIR/aqua-chat-background-probe"
"$PYTHON_BIN" Tests/aqua_background_clip_probe.py "$CLANG" "${COMPILE_FLAGS[@]}"
"$CLANG" "${COMPILE_FLAGS[@]}" Tests/aqua_chat_background_window_probe.m Sources/UI/TGAquaChatBackgroundWindowController.m Sources/UI/TGAquaAppearance.m Sources/UI/TGTheme.m Sources/UI/TGVisualWorldThemeSpec.m Sources/UI/TGInterfaceDesign.m Sources/UI/TGLocalization.m -framework Cocoa -o "$BUILD_DIR/aqua-chat-background-window-probe"
HOME="$TEST_HOME" "$BUILD_DIR/aqua-chat-background-window-probe"
"$PYTHON_BIN" Tests/aqua_background_texture_phase_probe.py "$CLANG" "${COMPILE_FLAGS[@]}"
