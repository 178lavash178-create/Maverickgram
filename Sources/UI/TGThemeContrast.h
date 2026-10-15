#import <Cocoa/Cocoa.h>

// Explicit surface-based colors for legacy AppKit controls. Returned ink is opaque.
NSColor *TGThemeCompositeColor(NSColor *foreground, NSColor *background);
CGFloat TGThemeContrastRatio(NSColor *ink, NSColor *surface);
NSColor *TGThemeReadableInk(NSColor *preferred, NSColor *surface, CGFloat minimum);
NSColor *TGThemeReadableInkOnSurfaces(NSColor *preferred, NSArray *surfaces, CGFloat minimum);

typedef enum {
    TGThemeSurfaceHeader, TGThemeSurfaceCard, TGThemeSurfaceTable,
    TGThemeSurfacePanel, TGThemeSurfaceRail, TGThemeSurfaceOutgoing, TGThemeSurfaceIncoming, TGThemeSurfaceWindow, TGThemeSurfaceRecessed
} TGThemeSurfaceRole;
NSColor *TGThemeSurfaceInkColor(NSColor *preferred, TGThemeSurfaceRole role, CGFloat minimum);
