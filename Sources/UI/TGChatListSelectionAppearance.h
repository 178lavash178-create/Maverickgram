#import <Cocoa/Cocoa.h>
#import "TGInterfaceDesign.h"
#import "TGTheme.h"

// Explicit blue list selections pair their surface with opaque white text in
// Aqua. Keep other controls and all Classic materials on their existing path.
static inline NSColor *TGListSelectionBackground(void) {
    return TGInterfaceDesignIsAqua() ? TGColorFromHex(0x2D73C4) : TGClassicSelectedRowColor();
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
