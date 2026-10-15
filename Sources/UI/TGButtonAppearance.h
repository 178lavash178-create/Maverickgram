#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, TGButtonSurfaceStyle) {
    TGButtonSurfaceEnamel,
    TGButtonSurfaceSecondary,
    TGButtonSurfaceSettings,
    TGButtonSurfaceSticker
};

// Surface and foreground are a pair: use both so translucent disabled materials
// cannot inherit an unrelated parent's brightness.
void TGDrawReadableButtonSurface(NSBezierPath *path, NSRect rect, TGButtonSurfaceStyle style,
                                 BOOL highlighted, BOOL selected, BOOL enabled, BOOL flipped);
NSColor *TGButtonForegroundColor(TGButtonSurfaceStyle style, BOOL highlighted, BOOL selected, BOOL enabled);
// Retints an already approved monochrome image; never alters sticker/photo content.
void TGDrawButtonTemplateImage(NSImage *image, NSRect rect, NSColor *color, BOOL flipped);
