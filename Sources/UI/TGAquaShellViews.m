#import "TGAquaShellViews.h"
#import "TGAquaAppearance.h"
#import "TGIconAssets.h"
#import "TGTheme.h"
#include <math.h>

@implementation TGAquaMetalView
@synthesize dividerX = _dividerX;
- (void)setDividerX:(CGFloat)dividerX {
    if (_dividerX == dividerX) return;
    _dividerX = dividerX;
    [self setNeedsDisplay:YES];
}
- (BOOL)isOpaque { return YES; }
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSRect rect = [self bounds];
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:rect], rect, TGThemeSurfaceHeader, [self isFlipped]);
    if (self.dividerX > 0 && self.dividerX < NSWidth(rect)) {
        CGFloat x = floor(self.dividerX);
        [TGColorFromHex(0x9FA8B2) set]; NSRectFill(NSMakeRect(x,0,1,NSHeight(rect)));
        [[NSColor colorWithCalibratedWhite:1 alpha:0.75] set]; NSRectFill(NSMakeRect(x+1,0,1,NSHeight(rect)));
    }
}
@end

// The sidebar utility is a toolbar segment, with the existing settings asset.
@implementation TGAquaUtilityButtonCell
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    BOOL selected = [self state] == NSOnState;
    if ([self isHighlighted] || selected) {
        NSRect inset = NSInsetRect(frame,6,1);
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:inset xRadius:5 yRadius:5];
        TGAquaDrawButtonInPath(path,inset,[self isHighlighted],selected,[self isEnabled],[view isFlipped]);
    }
    NSColor *ink = selected ? [NSColor whiteColor] : TGColorFromHex(0x273847);
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:13],NSFontAttributeName,ink,NSForegroundColorAttributeName,nil];
    NSString *title = [self title] ? [self title] : @"";
    NSSize size = [title sizeWithAttributes:attrs];
    CGFloat badgeWidth = [self.badgeText length] ? ceil([self.badgeText sizeWithAttributes:attrs].width)+10 : 0;
    CGFloat groupWidth = 20+8+size.width+(badgeWidth ? badgeWidth+8 : 0);
    CGFloat left = floor(NSMidX(frame)-groupWidth/2);
    TGDrawTemplateIconAsset(@"settings",NSMakeRect(left,floor(NSMidY(frame)-10),20,20),ink,1,[view isFlipped]);
    [title drawAtPoint:NSMakePoint(left+28,floor(NSMidY(frame)-size.height/2)) withAttributes:attrs];
    if (badgeWidth > 0) {
        NSRect badge = NSMakeRect(left+28+size.width+8,floor(NSMidY(frame)-9),badgeWidth,18);
        [TGColorFromHex(0xAE2931) set];
        [[NSBezierPath bezierPathWithRoundedRect:badge xRadius:9 yRadius:9] fill];
        NSDictionary *badgeAttrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:11],NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,nil];
        NSSize badgeSize = [self.badgeText sizeWithAttributes:badgeAttrs];
        [self.badgeText drawAtPoint:NSMakePoint(floor(NSMidX(badge)-badgeSize.width/2),floor(NSMidY(badge)-badgeSize.height/2)) withAttributes:badgeAttrs];
    }
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

// Source-list headings are quiet text controls, not selected navigation tabs.
@implementation TGAquaSectionButtonCell
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    BOOL heading = [self alignment] == NSLeftTextAlignment;
    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setAlignment:[self alignment]];
    [paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
    NSColor *ink = heading ? TGColorFromHex(0x445568) : TGColorFromHex([self isHighlighted] ? 0x163D66 : 0x295782);
    NSShadow *emboss = [[[NSShadow alloc] init] autorelease];
    [emboss setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.85]];
    [emboss setShadowOffset:NSMakeSize(0, [view isFlipped] ? -1 : 1)];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
        heading ? [NSFont boldSystemFontOfSize:11] : [NSFont systemFontOfSize:12], NSFontAttributeName,
        ink, NSForegroundColorAttributeName, paragraph, NSParagraphStyleAttributeName,
        emboss, NSShadowAttributeName, nil];
    NSString *title = [self title] ? [self title] : @"";
    CGFloat height = ceil([title sizeWithAttributes:attrs].height);
    [title drawInRect:NSMakeRect(NSMinX(frame)+4, floor(NSMidY(frame)-height/2), MAX(0,NSWidth(frame)-8), height) withAttributes:attrs];
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
    NSRect bounds = [self bounds];
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:bounds], bounds, TGThemeSurfaceHeader, [self isFlipped]);
    // Recessed horizontal grooves are part of the splitter material.
    CGFloat x = floor(NSMidX(bounds)-22), y = floor(NSMidY(bounds)-3);
    NSUInteger row;
    for (row=0; row<3; row++) {
        [TGColorFromHex(0x939CA6) set]; NSRectFill(NSMakeRect(x,y+row*3,44,1));
        [[NSColor colorWithCalibratedWhite:1 alpha:0.8] set]; NSRectFill(NSMakeRect(x,y+row*3+1,44,1));
    }
}
- (void)mouseDown:(NSEvent *)event { _initialY = [event locationInWindow].y; _dragDelta = 0.0; }
- (void)mouseDragged:(NSEvent *)event {
    CGFloat y = [event locationInWindow].y;
    _dragDelta = _initialY - y;
    _initialY = y;
    [NSApp sendAction:self.action to:self.target from:self];
}
@end
