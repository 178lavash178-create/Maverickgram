#import "TGAquaAppearance.h"
#include <math.h>

static NSColor *TGAquaColor(NSUInteger hex) {
    return [NSColor colorWithCalibratedRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1.0];
}

static NSGradient *TGAquaGradient(NSUInteger top, NSUInteger bottom) {
    static NSCache *cache = nil;
    if (!cache) { cache=[[NSCache alloc] init]; [cache setCountLimit:32]; }
    NSString *key=[NSString stringWithFormat:@"%lx:%lx",(unsigned long)top,(unsigned long)bottom];
    NSGradient *gradient=[cache objectForKey:key];
    if (!gradient) {
        gradient=[[[NSGradient alloc] initWithStartingColor:TGAquaColor(top) endingColor:TGAquaColor(bottom)] autorelease];
        [cache setObject:gradient forKey:key];
    }
    return gradient;
}

// Two tiny reusable material tiles. No per-frame random work, timers or layers.
// Both are low-amplitude surface grain, never icon artwork.
static NSColor *TGAquaGrain(BOOL linen) {
    static NSColor *metalColor=nil, *linenColor=nil;
    NSColor *cached=linen ? linenColor : metalColor;
    if (cached) return cached;
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:128 pixelsHigh:128 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    NSInteger x,y;
    for(y=0;y<128;y++) for(x=0;x<128;x++) {
        NSUInteger noise=((NSUInteger)x*37+(NSUInteger)y*131+((NSUInteger)x*(NSUInteger)y)%17)%19;
        CGFloat white,alpha;
        if(linen) {
            white=((x%4)==0 || (y%4)==1) ? 1.0 : 0.0;
            alpha=((x%4)==0 || (y%4)==1) ? 0.065 : 0.025;
            alpha+=(noise/18.0)*0.012;
        } else {
            white=((y%3)==0) ? 1.0 : 0.0;
            alpha=((y%3)==0 ? 0.075 : 0.022)+(noise/18.0)*0.012;
        }
        [bitmap setColor:[NSColor colorWithCalibratedWhite:white alpha:alpha] atX:x y:y];
    }
    NSImage *image=[[[NSImage alloc] initWithSize:NSMakeSize(128,128)] autorelease];
    [image addRepresentation:bitmap];
    cached=[[NSColor colorWithPatternImage:image] retain];
    if(linen) linenColor=cached; else metalColor=cached;
    return cached;
}

static void TGAquaEdge(NSRect rect, BOOL top, BOOL flipped, NSColor *color) {
    CGFloat y=(top != flipped) ? NSMaxY(rect)-1.0 : NSMinY(rect);
    [color set]; NSRectFillUsingOperation(NSMakeRect(NSMinX(rect),y,NSWidth(rect),1.0),NSCompositeSourceOver);
}

void TGAquaDrawSurfaceInPath(NSBezierPath *path, NSRect rect, TGThemeSurfaceRole role, BOOL flipped) {
    if(NSIsEmptyRect(rect)) return;
    NSUInteger top=0xF5F6F7,bottom=0xD4D7DB;
    BOOL metal=NO,linen=NO;
    switch(role) {
        case TGThemeSurfaceWindow: top=0xECEEEF;bottom=0xBFC3C8;metal=YES;break;
        case TGThemeSurfaceHeader: top=0xF5F6F6;bottom=0xC9CDD2;metal=YES;break;
        case TGThemeSurfacePanel: top=0xF5F6F8;bottom=0xDFE3E8;break;
        case TGThemeSurfaceRail: top=0xE2E9F1;bottom=0xC8D3E0;linen=YES;break;
        case TGThemeSurfaceRecessed: top=0xE7E9EC;bottom=0xFFFFFF;break;
        case TGThemeSurfaceCard: top=0xFFFFFF;bottom=0xF0F2F5;break;
        case TGThemeSurfaceOutgoing: top=0xDDEEFF;bottom=0xBCD9F6;break;
        case TGThemeSurfaceIncoming: top=0xFFFFFF;bottom=0xECEFF2;break;
        case TGThemeSurfaceTable: top=0xF7F9FC;bottom=0xF7F9FC;break;
    }
    [NSGraphicsContext saveGraphicsState];
    [path addClip];
    [TGAquaGradient(top,bottom) drawInRect:rect angle:flipped ? 90.0 : -90.0];
    if(metal || linen) {
        [TGAquaGrain(linen) set]; NSRectFillUsingOperation(rect,NSCompositeSourceOver);
    }
    if(role==TGThemeSurfaceRecessed) {
        TGAquaEdge(rect,YES,flipped,[NSColor colorWithCalibratedWhite:0.0 alpha:0.18]);
        TGAquaEdge(NSInsetRect(rect,0,1),YES,flipped,[NSColor colorWithCalibratedWhite:0.0 alpha:0.05]);
        TGAquaEdge(rect,NO,flipped,[NSColor colorWithCalibratedWhite:1.0 alpha:0.85]);
    } else {
        TGAquaEdge(rect,YES,flipped,[NSColor colorWithCalibratedWhite:1.0 alpha:0.65]);
        if(metal) TGAquaEdge(rect,NO,flipped,[NSColor colorWithCalibratedWhite:0.0 alpha:0.20]);
    }
    [NSGraphicsContext restoreGraphicsState];
}

void TGAquaDrawConversationBackground(NSRect rect, BOOL flipped) {
    (void)flipped;
    [TGAquaColor(0xD8E0E8) set]; NSRectFill(rect);
    [TGAquaGrain(YES) set]; NSRectFillUsingOperation(rect,NSCompositeSourceOver);
}

void TGAquaDrawButtonInPath(NSBezierPath *path, NSRect rect, BOOL highlighted, BOOL accented, BOOL enabled, BOOL flipped) {
    if(NSIsEmptyRect(rect)) return;
    NSUInteger top,bottom;
    // Keep the glossy upper half dark enough for the shell's white title.
    if(accented) { top=highlighted ? 0x235B9E : 0x2B65AC;bottom=highlighted ? 0x143E7A : 0x174C94; }
    else { top=highlighted ? 0xC2C7CD : 0xFFFFFF;bottom=highlighted ? 0xE4E7EB : 0xC9CDD2; }
    if(!enabled) { top=0xE6E8EB;bottom=0xCDD1D6; }
    [NSGraphicsContext saveGraphicsState]; [path addClip];
    [TGAquaGradient(top,bottom) drawInRect:rect angle:flipped ? 90.0 : -90.0];
    if(!highlighted && enabled) {
        NSRect sheen=rect; sheen.size.height=floor(NSHeight(rect)*0.48);
        if(!flipped) sheen.origin.y=NSMaxY(rect)-NSHeight(sheen);
        [[NSColor colorWithCalibratedWhite:1.0 alpha:accented ? 0.08 : 0.22] set];
        NSRectFillUsingOperation(sheen,NSCompositeSourceOver);
    }
    TGAquaEdge(NSInsetRect(rect,1,1),YES,flipped,[NSColor colorWithCalibratedWhite:1.0 alpha:accented ? 0.45 : 0.9]);
    TGAquaEdge(rect,NO,flipped,[NSColor colorWithCalibratedWhite:0.0 alpha:0.18]);
    [NSGraphicsContext restoreGraphicsState];
}

NSColor *TGAquaMessageFooterColor(BOOL outgoing, BOOL flipped) {
    (void)flipped; // The material is oriented consistently in either coordinate system.
    return [TGAquaGradient(outgoing ? 0xDDEEFF : 0xFFFFFF,outgoing ? 0xBCD9F6 : 0xECEFF2) interpolatedColorAtLocation:0.92];
}
