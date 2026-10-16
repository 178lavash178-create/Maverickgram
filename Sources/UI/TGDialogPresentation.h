#import <Cocoa/Cocoa.h>

// Aqua uses a native window-attached sheet. Classic retains AppKit's original
// application-modal presentation. A nil parent resolves the key/main window;
// an unavailable explicit parent or an already attached sheet cancels safely.
NSInteger TGRunAlert(NSAlert *alert, NSWindow *preferredParent);
NSInteger TGRunFilePanel(NSSavePanel *panel, NSWindow *preferredParent);
