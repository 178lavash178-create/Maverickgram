#import <Cocoa/Cocoa.h>
#import "TGThemeContrast.h"

// Materials only: all icons continue to come from the approved project assets.
void TGAquaDrawSurfaceInPath(NSBezierPath *path, NSRect rect, TGThemeSurfaceRole role, BOOL flipped);
void TGAquaDrawConversationBackground(NSRect rect, BOOL flipped);
void TGAquaDrawButtonInPath(NSBezierPath *path, NSRect rect, BOOL highlighted, BOOL accented, BOOL enabled, BOOL flipped);
NSColor *TGAquaMessageFooterColor(BOOL outgoing, BOOL flipped);
