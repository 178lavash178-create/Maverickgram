#import <Cocoa/Cocoa.h>
#import "TGInterfaceDesign.h"
#import "TGTheme.h"

// Scope this finish to chat rows: folders and other selected controls retain
// their own approved material. The cobalt stays dark enough for white text.
static inline NSColor *TGChatListSelectionBackground(void) {
    return TGInterfaceDesignIsAqua() ? TGColorFromHex(0x2D73C4) : TGClassicSelectedRowColor();
}
static inline NSColor *TGChatListSelectionForeground(void) {
    return TGInterfaceDesignIsAqua() ? [NSColor whiteColor] : TGClassicSelectedRowTextColor();
}
