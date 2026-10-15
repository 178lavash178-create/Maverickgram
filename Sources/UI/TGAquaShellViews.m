#import "TGAquaShellViews.h"
#import "TGAquaAppearance.h"
#import "TGIconAssets.h"
#import "TGTheme.h"
#include <math.h>

@implementation TGAquaMetalView
- (BOOL)isOpaque { return YES; }
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSRect rect = [self bounds];
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:rect], rect, TGThemeSurfaceHeader, [self isFlipped]);
}
@end

@implementation TGAquaTextButtonCell
@synthesize accented = _accented;
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    NSRect rect = NSInsetRect(frame, 1.0, 1.0);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:6.0 yRadius:6.0];
    BOOL blue = self.accented || [self state] == NSOnState;
    TGAquaDrawButtonInPath(path, rect, [self isHighlighted], blue, [self isEnabled], [view isFlipped]);
    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setAlignment:NSCenterTextAlignment];
    [paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
    NSColor *ink = [self isEnabled] ? (blue ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.12 alpha:1.0]) : [NSColor colorWithCalibratedWhite:0.40 alpha:1.0];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12.0], NSFontAttributeName, ink, NSForegroundColorAttributeName, paragraph, NSParagraphStyleAttributeName, nil];
    NSString *title = [self title] ? [self title] : @"";
    CGFloat height = ceil([title sizeWithAttributes:attrs].height);
    CGFloat badgeWidth = [self.badgeText length] ? MIN(30.0, ceil([self.badgeText sizeWithAttributes:attrs].width)+6) : 0;
    [title drawInRect:NSMakeRect(NSMinX(rect)+6, floor(NSMidY(rect)-height/2), MAX(0.0, NSWidth(rect)-12-badgeWidth), height) withAttributes:attrs];
    if (badgeWidth) [self.badgeText drawInRect:NSMakeRect(NSMaxX(rect)-badgeWidth-3, floor(NSMidY(rect)-height/2), badgeWidth, height) withAttributes:attrs];
}
@end

@implementation TGAquaFolderButtonCell
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    BOOL selected = [self state] == NSOnState;
    if (selected || [self isHighlighted]) {
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:TGColorFromHex(0x316DA9) endingColor:TGColorFromHex(0x214B78)] autorelease];
        [gradient drawInRect:frame angle:[view isFlipped] ? 90 : -90];
    } else {
        [TGColorFromHex(0xE1E8F0) set]; NSRectFill(frame);
    }
    NSColor *ink = (selected || [self isHighlighted]) ? [NSColor whiteColor] : TGColorFromHex(0x203145);
    TGDrawTemplateIconAsset([(NSControl *)view tag] == -2 ? @"archive" : @"folder", NSMakeRect(NSMinX(frame)+12, floor(NSMidY(frame)-8), 16, 16), ink, [self isEnabled] ? 1.0 : 0.55, [view isFlipped]);
    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:13], NSFontAttributeName, ink, NSForegroundColorAttributeName, paragraph, NSParagraphStyleAttributeName, nil];
    CGFloat badgeWidth = [self.badgeText length] ? MIN(54.0, ceil([self.badgeText sizeWithAttributes:attrs].width)) : 0.0;
    CGFloat y = floor(NSMidY(frame)-8);
    [[self title] drawInRect:NSMakeRect(NSMinX(frame)+38, y, MAX(0.0, NSWidth(frame)-52-badgeWidth), 18) withAttributes:attrs];
    if (badgeWidth > 0) [self.badgeText drawInRect:NSMakeRect(NSMaxX(frame)-badgeWidth-8, y, badgeWidth, 18) withAttributes:attrs];
}
@end

@implementation TGAquaFolderDivider
@synthesize target = _target, action = _action;
- (CGFloat)dragDelta { return _dragDelta; }
- (void)resetCursorRects { [self addCursorRect:[self bounds] cursor:[NSCursor resizeUpDownCursor]]; }
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:TGColorFromHex(0xEEEEEE) endingColor:TGColorFromHex(0xBBBBBB)] autorelease];
    [gradient drawInRect:[self bounds] angle:-90];
    [TGColorFromHex(0x888888) set];
    NSRectFill(NSMakeRect(NSMidX([self bounds])-14, 4, 28, 1));
    NSRectFill(NSMakeRect(NSMidX([self bounds])-14, 6, 28, 1));
}
- (void)mouseDown:(NSEvent *)event { _initialY = [event locationInWindow].y; _dragDelta = 0.0; }
- (void)mouseDragged:(NSEvent *)event {
    CGFloat y = [event locationInWindow].y;
    _dragDelta = _initialY - y;
    _initialY = y;
    [NSApp sendAction:self.action to:self.target from:self];
}
@end
