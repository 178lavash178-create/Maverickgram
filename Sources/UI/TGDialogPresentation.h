#import <Cocoa/Cocoa.h>

// Aqua uses a native window-attached sheet. Classic retains AppKit's original
// application-modal presentation. A nil parent resolves the key/main window;
// an unavailable explicit parent or an already attached sheet cancels safely.
NSInteger TGRunAlert(NSAlert *alert, NSWindow *preferredParent);
NSInteger TGRunFilePanel(NSSavePanel *panel, NSWindow *preferredParent);

// Ordinary auxiliary windows, excluding native sheets, drawers and media stages.
// Fixed forms keep their natural document size in a scrolling viewport only
// when the current screen cannot accommodate their safe minimum.
NSView *TGUtilityWindowContentView(NSWindow *window);
NSRect TGUtilityWindowFrameFittingVisibleFrame(NSRect frame, NSRect visibleFrame);
void TGFitUtilityWindowToVisibleFrame(NSWindow *window, NSRect visibleFrame);
void TGFitUtilityWindowToVisibleScreen(NSWindow *window);
