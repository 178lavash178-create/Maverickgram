#import <Cocoa/Cocoa.h>
#import "TGThemeContrast.h"

// Materials only: all icons continue to come from the approved project assets.
void TGAquaDrawSurfaceInPath(NSBezierPath *path, NSRect rect, TGThemeSurfaceRole role, BOOL flipped);
// Fine two-point edge inside the unchanged six-point resize target.
void TGAquaDrawVerticalSeam(NSRect rect);
void TGAquaDrawConversationBackground(NSRect rect, BOOL flipped);
void TGAquaDrawButtonInPath(NSBezierPath *path, NSRect rect, BOOL highlighted, BOOL accented, BOOL enabled, BOOL flipped);
NSColor *TGAquaMessageFooterColor(BOOL outgoing, BOOL flipped);

// Shared casework for Aqua utility forms. Controls belong to the controller;
// this view supplies only the quiet body, metal rails and one-point dividers.
@interface TGAquaUtilityWindowView : NSView {
    CGFloat _headerHeight;
    CGFloat _footerHeight;
}
@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) CGFloat footerHeight;
@end
