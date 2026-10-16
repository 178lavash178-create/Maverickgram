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
        TGAquaDrawVerticalSeam(NSMakeRect(self.dividerX - 3.0, NSMinY(rect), 6.0, NSHeight(rect)));
    }
}
@end

// Toolbar navigation uses only the existing approved template assets.
@implementation TGAquaUtilityButtonCell
@synthesize iconAssetName = _iconAssetName;
- (void)dealloc { [_iconAssetName release]; [super dealloc]; }
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    BOOL selected = [self isHighlighted] || ([self showsStateBy] != 0 && [self state] == NSOnState);
    NSRect inset = NSInsetRect(frame,1,1);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:inset xRadius:5 yRadius:5];
    TGAquaDrawButtonInPath(path,inset,[self isHighlighted],selected,[self isEnabled],[view isFlipped]);
    NSColor *ink = ![self isEnabled] ? TGColorFromHex(0x666666) : (selected ? [NSColor whiteColor] : TGColorFromHex(0x273847));
    if (self.iconOnly) {
        BOOL hasBadge = [self.badgeText length] > 0;
        CGFloat iconX = floor(NSMidX(frame) - 10.0);
        TGDrawTemplateIconAsset(self.iconAssetName ? self.iconAssetName : @"settings", NSMakeRect(iconX, floor(NSMidY(frame)-10),20,20), ink, 1.0, [view isFlipped]);
        if (hasBadge) {
            NSDictionary *badgeAttrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:10], NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil];
            NSString *badgeText = [self.badgeText length] > 3 ? @"99+" : self.badgeText;
            NSSize size = [badgeText sizeWithAttributes:badgeAttrs];
            CGFloat badgeWidth = MAX(16.0, ceil(size.width) + 6.0);
            NSRect badge = NSMakeRect(NSMaxX(frame)-badgeWidth-2.0, NSMaxY(frame)-17.0, badgeWidth, 16.0);
            [TGColorFromHex(0xAE2931) set];
            [[NSBezierPath bezierPathWithRoundedRect:badge xRadius:8 yRadius:8] fill];
            [badgeText drawAtPoint:NSMakePoint(floor(NSMidX(badge)-size.width/2.0),floor(NSMidY(badge)-size.height/2.0)) withAttributes:badgeAttrs];
        }
        return;
    }
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

NSRect TGAquaToolbarItemIconFrame(NSRect frame, BOOL flipped) {
    return NSMakeRect(floor(NSMidX(frame)-13),flipped ? NSMinY(frame)+4 : NSMaxY(frame)-30,26,26);
}
NSRect TGAquaToolbarItemLabelFrame(NSRect frame, BOOL flipped) {
    return NSMakeRect(NSMinX(frame)+2,flipped ? NSMaxY(frame)-17 : NSMinY(frame)+2,MAX(0,NSWidth(frame)-4),15);
}
NSRect TGAquaToolbarItemBadgeFrame(NSRect frame, CGFloat badgeWidth, BOOL flipped) {
    NSRect icon=TGAquaToolbarItemIconFrame(frame,flipped);
    return NSMakeRect(NSMidX(frame)+4,flipped ? NSMinY(icon)-2 : NSMaxY(icon)-13,MIN(28,MAX(15,badgeWidth)),15);
}

@implementation TGAquaToolbarItemCell
@synthesize selectedIconAssetName=_selectedIconAssetName, usesOriginalIconColors=_usesOriginalIconColors;
- (void)dealloc { [_selectedIconAssetName release];[super dealloc]; }
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    BOOL enabled=[self isEnabled];
    BOOL selected=[self isHighlighted] || ([self showsStateBy]!=0 && [self state]==NSOnState);
    BOOL flipped=[view isFlipped];
    NSColor *ink=TGColorFromHex(!enabled ? 0x737B83 : (selected ? 0x1469A6 : 0x47515D));
    NSString *asset=(selected && [_selectedIconAssetName length]) ? _selectedIconAssetName : self.iconAssetName;
    NSRect icon=TGAquaToolbarItemIconFrame(frame,flipped);
    NSImage *image=(selected && [self alternateImage]) ? [self alternateImage] : [self image];
    if(_usesOriginalIconColors) {
        [image drawInRect:icon fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:enabled ? 1.0 : 0.45 respectFlipped:flipped hints:nil];
    } else if([asset length]) {
        TGDrawTemplateIconAsset(asset,icon,ink,1,flipped);
    }
    NSMutableParagraphStyle *paragraph=[[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setAlignment:NSCenterTextAlignment];[paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
    NSShadow *emboss=[[[NSShadow alloc] init] autorelease];[emboss setShadowColor:[NSColor colorWithCalibratedWhite:1 alpha:0.72]];[emboss setShadowOffset:NSMakeSize(0,flipped ? -1:1)];
    NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11],NSFontAttributeName,
        TGColorFromHex(!enabled ? 0x737B83 : (selected ? 0x145A93 : 0x2E353D)),NSForegroundColorAttributeName,
        paragraph,NSParagraphStyleAttributeName,emboss,NSShadowAttributeName,nil];
    [[self title] drawInRect:TGAquaToolbarItemLabelFrame(frame,flipped) withAttributes:attrs];
    if([self.badgeText length]) {
        NSString *text=[self.badgeText length]>3 ? @"99+" : self.badgeText;
        NSDictionary *badgeAttrs=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:10],NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,nil];
        NSSize size=[text sizeWithAttributes:badgeAttrs];
        NSRect badge=TGAquaToolbarItemBadgeFrame(frame,ceil(size.width)+6,flipped);
        [TGColorFromHex(0xB52E35) set];[[NSBezierPath bezierPathWithRoundedRect:badge xRadius:7.5 yRadius:7.5] fill];
        [text drawAtPoint:NSMakePoint(floor(NSMidX(badge)-size.width/2),floor(NSMidY(badge)-size.height/2)) withAttributes:badgeAttrs];
    }
}
@end

@implementation TGAquaTextButtonCell
@synthesize accented = _accented;
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    NSRect rect = NSInsetRect(frame, 1.0, 1.0);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:6.0 yRadius:6.0];
    // Momentary AppKit cells may keep On internally after sending their action.
    // Only cells configured to show persistent state are selected when idle.
    BOOL blue = self.accented || [self isHighlighted] || ([self showsStateBy] != 0 && [self state] == NSOnState);
    TGAquaDrawButtonInPath(path, rect, [self isHighlighted], blue, [self isEnabled], [view isFlipped]);
    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setAlignment:NSCenterTextAlignment];
    [paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
    NSColor *ink = [self isEnabled] ? (blue ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.12 alpha:1.0]) : [NSColor colorWithCalibratedWhite:0.40 alpha:1.0];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12.0], NSFontAttributeName, ink, NSForegroundColorAttributeName, paragraph, NSParagraphStyleAttributeName, nil];
    NSString *title = [self title] ? [self title] : @"";
    CGFloat height = ceil([title sizeWithAttributes:attrs].height);
    CGFloat badgeWidth = [self.badgeText length] ? MIN(30.0, ceil([self.badgeText sizeWithAttributes:attrs].width)+6) : 0;
    NSRect titleRect = NSMakeRect(NSMinX(rect)+6, floor(NSMidY(rect)-height/2), MAX(0.0, NSWidth(rect)-12-badgeWidth), height);
    NSImage *image = [self image];
    if (image) {
        CGFloat imageSide = MIN(16.0, MAX(0.0, NSWidth(titleRect)));
        CGFloat titleWidth = MIN([title sizeWithAttributes:attrs].width, MAX(0.0, NSWidth(titleRect)-imageSide-6.0));
        CGFloat groupWidth = imageSide+6.0+titleWidth;
        CGFloat groupX = floor(NSMidX(titleRect)-groupWidth/2.0);
        NSRect imageRect = NSMakeRect(groupX, floor(NSMidY(rect)-imageSide/2.0), imageSide, imageSide);
        // Only explicit monochrome templates follow the label's state ink.
        // Callers keep full-color artwork by leaving AppKit's template flag off.
        BOOL templateImage=[image isTemplate];
        if (templateImage) {
            [NSGraphicsContext saveGraphicsState];
            CGContextRef context=(CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
            CGContextBeginTransparencyLayer(context,NULL);
            [image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver
                     fraction:1.0 respectFlipped:[view isFlipped] hints:nil];
            [ink set];NSRectFillUsingOperation(imageRect,NSCompositeSourceIn);
            CGContextEndTransparencyLayer(context);[NSGraphicsContext restoreGraphicsState];
        } else {
            [image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver
                     fraction:[self isEnabled] ? 1.0 : 0.55 respectFlipped:[view isFlipped] hints:nil];
        }
        titleRect.origin.x = groupX+imageSide+6.0;
        titleRect.size.width = titleWidth;
    }
    [title drawInRect:titleRect withAttributes:attrs];
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
    [TGColorFromHex(0xE1E8F0) set]; NSRectFill(frame);
    if (selected || [self isHighlighted]) {
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:TGColorFromHex(0x316DA9) endingColor:TGColorFromHex(0x214B78)] autorelease];
        NSRect selection = NSInsetRect(frame, 4.0, 2.0);
        NSBezierPath *outline = [NSBezierPath bezierPathWithRoundedRect:selection xRadius:4 yRadius:4];
        [gradient drawInBezierPath:outline angle:[view isFlipped] ? 90 : -90];
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
