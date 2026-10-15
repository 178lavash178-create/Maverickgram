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

// Original, licensed Subtle Patterns tiles; attribution ships beside the PNGs.
// Decode each image once. Missing optional artwork falls back to the base finish.
static NSColor *TGAquaTexture(BOOL linen) {
    static NSColor *metalColor=nil, *linenColor=nil;
    static BOOL metalLoaded=NO, linenLoaded=NO;
    if(linen ? linenLoaded : metalLoaded) return linen ? linenColor : metalColor;
    NSString *name=linen ? @"black-Linen" : @"brushed_alu";
    NSString *path=[[NSBundle mainBundle] pathForResource:name ofType:@"png" inDirectory:@"Textures"];
    NSImage *image=path ? [[[NSImage alloc] initWithContentsOfFile:path] autorelease] : nil;
    NSColor *pattern=image ? [[NSColor colorWithPatternImage:image] retain] : nil;
    if(linen) { linenLoaded=YES;linenColor=pattern; }
    else { metalLoaded=YES;metalColor=pattern; }
    return pattern;
}

static void TGAquaDrawTexture(NSRect rect, BOOL linen, CGFloat opacity) {
    NSColor *texture=TGAquaTexture(linen);
    if(!texture) return;
    [NSGraphicsContext saveGraphicsState];
    CGContextSetAlpha((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],opacity);
    [texture set];NSRectFillUsingOperation(rect,NSCompositeSourceOver);
    [NSGraphicsContext restoreGraphicsState];
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
        TGAquaDrawTexture(rect,linen,linen ? 0.13 : 0.42);
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
    TGAquaDrawTexture(rect,YES,0.14);
}

static NSGradient *TGAquaButtonFinish(BOOL highlighted, BOOL accented, BOOL enabled) {
    static NSGradient *finishes[8]={nil,nil,nil,nil,nil,nil,nil,nil};
    NSUInteger slot=(highlighted ? 1 : 0)|(accented ? 2 : 0)|(enabled ? 4 : 0);
    if(!finishes[slot]) {
        NSUInteger top,shoulder,lower,bottom;
        if(!enabled) { top=0xF4F5F6;shoulder=0xEEF0F2;lower=0xE7E9EC;bottom=0xF0F2F4; }
        else if(accented && highlighted) { top=0x17447B;shoulder=0x205798;lower=0x225C9E;bottom=0x2C66A7; }
        else if(accented) { top=0x3A70B0;shoulder=0x235DA5;lower=0x174B92;bottom=0x2D6AAC; }
        else if(highlighted) { top=0xADB6C0;shoulder=0xCCD2D9;lower=0xD7DCE1;bottom=0xDEE3E8; }
        else { top=0xFFFFFF;shoulder=0xF1F3F5;lower=0xD8DDE3;bottom=0xF0F3F6; }
        NSArray *colors=[NSArray arrayWithObjects:TGAquaColor(top),TGAquaColor(shoulder),TGAquaColor(lower),TGAquaColor(bottom),nil];
        CGFloat locations[]={0.0,0.38,0.68,1.0};
        finishes[slot]=[[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace genericRGBColorSpace]];
    }
    return finishes[slot];
}

void TGAquaDrawButtonInPath(NSBezierPath *path, NSRect rect, BOOL highlighted, BOOL accented, BOOL enabled, BOOL flipped) {
    if(NSIsEmptyRect(rect)) return;
    [NSGraphicsContext saveGraphicsState];[path addClip];
    // A continuous curved light profile, with a lower reflection and an inset
    // pressed finish. No rectangular white overlay across the label.
    [TGAquaButtonFinish(highlighted,accented,enabled) drawInRect:rect angle:flipped ? 90.0 : -90.0];
    NSBezierPath *rim=[[path copy] autorelease];
    [(enabled && accented ? TGAquaColor(0x123F78) : TGAquaColor(enabled ? 0x8A939E : 0xB5BBC2)) set];
    [rim setLineWidth:2.0];[rim stroke];
    NSBezierPath *bevel=[[path copy] autorelease];
    NSAffineTransform *inset=[NSAffineTransform transform];
    [inset translateXBy:NSMinX(rect)+1.5 yBy:NSMinY(rect)+1.5];
    [inset scaleXBy:MAX(0.01,(NSWidth(rect)-3.0)/NSWidth(rect)) yBy:MAX(0.01,(NSHeight(rect)-3.0)/NSHeight(rect))];
    [inset translateXBy:-NSMinX(rect) yBy:-NSMinY(rect)];
    [bevel transformUsingAffineTransform:inset];
    [[NSColor colorWithCalibratedWhite:highlighted ? 0.0 : 1.0 alpha:highlighted ? 0.13 : (accented ? 0.22 : 0.72)] set];
    [bevel setLineWidth:1.0];[bevel stroke];
    [NSGraphicsContext restoreGraphicsState];
}

NSColor *TGAquaMessageFooterColor(BOOL outgoing, BOOL flipped) {
    (void)flipped; // The material is oriented consistently in either coordinate system.
    return [TGAquaGradient(outgoing ? 0xDDEEFF : 0xFFFFFF,outgoing ? 0xBCD9F6 : 0xECEFF2) interpolatedColorAtLocation:0.92];
}
