#import <Cocoa/Cocoa.h>
#import "TGInterfaceDesign.h"
#import "TGAquaAppearance.h"
#import "TGTheme.h"
#include <stdio.h>

static NSBitmapImageRep *TGMaterialBitmap(TGThemeSurfaceRole role, BOOL flipped) {
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:128 pixelsHigh:64 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    NSRect rect=NSMakeRect(0,0,128,64);
    [TGClassicTablePaperColor() set]; NSRectFill(rect);
    NSBezierPath *path=[NSBezierPath bezierPathWithRect:rect];
    switch(role) {
        case TGThemeSurfaceWindow: TGThemeDrawWindowBackgroundInRect(rect,flipped); break;
        case TGThemeSurfaceHeader: TGThemeDrawHeaderBackgroundInRect(rect,flipped); break;
        case TGThemeSurfacePanel: TGThemeDrawPanelBackgroundInPath(path,rect,flipped); break;
        case TGThemeSurfaceRail: TGThemeDrawRailBackgroundInPath(path,rect,flipped); break;
        case TGThemeSurfaceCard: TGThemeDrawGroupedCardInPath(path,rect,flipped); break;
        case TGThemeSurfaceRecessed: TGThemeDrawRecessedBackgroundInPath(path,rect,flipped); break;
        case TGThemeSurfaceOutgoing: TGThemeDrawMessageBubbleInPath(path,rect,YES,flipped); break;
        case TGThemeSurfaceIncoming: TGThemeDrawMessageBubbleInPath(path,rect,NO,flipped); break;
        default: break;
    }
    [NSGraphicsContext restoreGraphicsState];
    return bitmap;
}

// Measure the composited gradient and sheen, not their source colors. The
// inset one-point highlight is decorative and outside the centered title band.
static NSUInteger TGCheckAquaButtonMaterials(void) {
    NSUInteger failures=0,checks=0;
    CGFloat minimum=21.0;
    NSUInteger scale,flip,pressed,heightIndex;
    const CGFloat heights[]={24.0,32.0,40.0,64.0};
    for(scale=1;scale<=2;scale++) for(flip=0;flip<2;flip++) for(pressed=0;pressed<2;pressed++) for(heightIndex=0;heightIndex<4;heightIndex++) {
        CGFloat height=heights[heightIndex];
        NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:160*scale pixelsHigh:(NSInteger)(height*scale) bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
        NSAffineTransform *transform=[NSAffineTransform transform];[transform scaleBy:scale];[transform concat];
        NSRect rect=NSMakeRect(0,0,160,height);
        TGAquaDrawButtonInPath([NSBezierPath bezierPathWithRoundedRect:rect xRadius:6 yRadius:6],rect,pressed!=0,YES,YES,flip!=0);
        [NSGraphicsContext restoreGraphicsState];
        CGFloat contrast=21.0; NSInteger x,y;
        // Sample every interior pixel, including both sides of the gloss seam.
        // Six points also exclude the rounded corner and its antialiasing.
        for(y=2*scale;y<(NSInteger)((height-2)*scale);y++) for(x=6*scale;x<(NSInteger)(154*scale);x++) {
            contrast=MIN(contrast,TGThemeContrastRatio([NSColor whiteColor],[bitmap colorAtX:x y:y]));
        }
        minimum=MIN(minimum,contrast);checks++;
        if(contrast<4.5) { fprintf(stderr,"Aqua button white title contrast scale%lu flip%lu pressed%lu height%.0f %.3f\n",(unsigned long)scale,(unsigned long)flip,(unsigned long)pressed,(double)height,(double)contrast);failures++; }
    }
    printf("Aqua cobalt buttons: %lu actual rasters, minimum white title contrast %.2f:1, %lu failures.\n",(unsigned long)checks,(double)minimum,(unsigned long)failures);
    return failures;
}

int main(int argc, const char *argv[]) {
    (void)argc;(void)argv;
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    if(!TGInterfaceDesignIsAqua()) { fprintf(stderr,"Run with -TelegraphicaInterfaceDesign aqua\n"); [pool drain]; return 1; }
    id savedTheme=[[[NSUserDefaults standardUserDefaults] objectForKey:TGThemeDefaultsKey] retain];
    NSMutableArray *reference=[NSMutableArray array];
    NSUInteger failures=TGCheckAquaButtonMaterials(),checks=0;
    CGFloat minimum=21.0;
    for(NSString *theme in TGThemeIdentifiers()) {
        TGSetActiveThemeIdentifier(theme);
        if(![TGCurrentThemeIdentifier() isEqual:theme] || TGThemeIsVisualWorld() || TGThemeIsFrutigerAero() || TGThemeIsExperimental2000s()) failures++;
        NSUInteger role;
        for(role=0;role<9;role++) {
            NSUInteger flip;
            for(flip=0;flip<2;flip++) {
                // Sampling paints at 256x128. Mavericks' NSGradient raises its
                // internal raster precision after that larger draw, shifting a
                // subsequent 128x64 draw by one channel level. Prepare the
                // production samples before capturing the strict pixel baseline.
                NSColor *ink=TGThemeSurfaceInkColor(TGClassicMutedInkColor(),(TGThemeSurfaceRole)role,4.5);
                NSBitmapImageRep *bitmap=TGMaterialBitmap((TGThemeSurfaceRole)role,flip!=0);
                NSData *pixels=[NSData dataWithBytes:[bitmap bitmapData] length:[bitmap bytesPerRow]*[bitmap pixelsHigh]];
                NSUInteger slot=role*2+flip;
                if([reference count]<=slot) [reference addObject:pixels];
                else if(![pixels isEqual:[reference objectAtIndex:slot]]) { fprintf(stderr,"Aqua changed with saved classic theme %s role%lu\n",[theme UTF8String],(unsigned long)role); failures++; }
                CGFloat contrast=21.0; NSInteger x,y;
                for(y=5;y<59;y+=3) for(x=5;x<123;x+=3) contrast=MIN(contrast,TGThemeContrastRatio(ink,[bitmap colorAtX:x y:y]));
                minimum=MIN(minimum,contrast);checks++;
                if(contrast<4.45) { fprintf(stderr,"Aqua contrast %s role%lu flip%lu %.2f\n",[theme UTF8String],(unsigned long)role,(unsigned long)flip,(double)contrast); failures++; }
            }
        }
    }
    id after=[[NSUserDefaults standardUserDefaults] objectForKey:TGThemeDefaultsKey];
    if(savedTheme ? ![savedTheme isEqual:after] : after!=nil) { fprintf(stderr,"Aqua overwrote saved classic preference\n"); failures++; }
    [savedTheme release];
    printf("Aqua materials: %lu actual surfaces, fixed palette across29saved themes, preference preserved, minimum%.2f:1, %lu failures.\n",(unsigned long)checks,(double)minimum,(unsigned long)failures);
    [pool drain];return failures?1:0;
}
