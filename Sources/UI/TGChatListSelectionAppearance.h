#import <Cocoa/Cocoa.h>
#import "TGInterfaceDesign.h"
#import "TGTheme.h"

// Explicit blue list selections pair their surface with opaque white text in
// Aqua. Keep other controls and all Classic materials on their existing path.
static inline NSColor *TGListSelectionBackground(void) {
    // The calibrated AppKit colour becomes lighter in the actual bitmap. Use
    // the same deeper cobalt as Aqua's buttons so white small text remains
    // readable after colour-space conversion, not only in source RGB values.
    return TGInterfaceDesignIsAqua() ? TGColorFromHex(0x235DA5) : TGClassicSelectedRowColor();
}
static inline NSColor *TGListSelectionForeground(void) {
    return TGInterfaceDesignIsAqua() ? [NSColor whiteColor] : TGClassicSelectedRowTextColor();
}
static inline NSColor *TGChatListSelectionBackground(void) {
    return TGListSelectionBackground();
}
static inline NSColor *TGChatListSelectionForeground(void) {
    return TGListSelectionForeground();
}
