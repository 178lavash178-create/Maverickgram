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
    NSMutableDictionary *directions=[NSMutableDictionary dictionary];
    NSUInteger scale,flip,pressed,heightIndex,accented,enabled;
    const CGFloat heights[]={24.0,32.0,40.0,64.0};
    for(scale=1;scale<=2;scale++) for(flip=0;flip<2;flip++) for(pressed=0;pressed<2;pressed++) for(heightIndex=0;heightIndex<4;heightIndex++) for(accented=0;accented<2;accented++) for(enabled=0;enabled<2;enabled++) {
        CGFloat height=heights[heightIndex];
        NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:160*scale pixelsHigh:(NSInteger)(height*scale) bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
        NSAffineTransform *transform=[NSAffineTransform transform];[transform scaleBy:scale];[transform concat];
        NSRect rect=NSMakeRect(0,0,160,height);
        TGAquaDrawButtonInPath([NSBezierPath bezierPathWithRoundedRect:rect xRadius:6 yRadius:6],rect,pressed!=0,accented!=0,enabled!=0,flip!=0);
        [NSGraphicsContext restoreGraphicsState];
        NSColor *ink=enabled ? (accented ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.12 alpha:1.0]) : [NSColor colorWithCalibratedWhite:0.40 alpha:1.0];
        CGFloat contrast=21.0; NSInteger x,y;
        // Sample every interior pixel through the continuous curved light profile.
        // Six points also exclude the rounded corner and its antialiasing.
        for(y=3*scale;y<(NSInteger)((height-3)*scale);y++) for(x=6*scale;x<(NSInteger)(154*scale);x++) {
            contrast=MIN(contrast,TGThemeContrastRatio(ink,[bitmap colorAtX:x y:y]));
        }
        NSString *directionKey=[NSString stringWithFormat:@"%lu:%lu:%lu:%lu:%lu",(unsigned long)scale,(unsigned long)pressed,(unsigned long)heightIndex,(unsigned long)accented,(unsigned long)enabled];
        NSData *raster=[NSData dataWithBytes:[bitmap bitmapData] length:[bitmap bytesPerRow]*[bitmap pixelsHigh]];
        if(!flip) [directions setObject:raster forKey:directionKey];
        else {
            const unsigned char *normal=[[directions objectForKey:directionKey] bytes],*reverse=[raster bytes];
            NSInteger stride=[bitmap bytesPerRow],pixelsHigh=[bitmap pixelsHigh],channel;
            NSUInteger maximumDifference=0,unmirroredDifference=0;
            for(y=3*scale;y<pixelsHigh-(NSInteger)(3*scale);y++) for(x=6*scale;x<(NSInteger)(154*scale);x++) for(channel=0;channel<4;channel++) {
                NSInteger difference=abs((int)normal[y*stride+x*4+channel]-(int)reverse[(pixelsHigh-1-y)*stride+x*4+channel]);
                maximumDifference=MAX(maximumDifference,(NSUInteger)difference);
                NSInteger wrongDirection=abs((int)normal[y*stride+x*4+channel]-(int)reverse[y*stride+x*4+channel]);
                unmirroredDifference=MAX(unmirroredDifference,(NSUInteger)wrongDirection);
            }
            // Mavericks dithers NSGradient at 8-bit output: standalone AppKit
            // +/-90-degree draws show channel rounding differences after reflection.
            // The additional translucent bitmap finish introduces one more
            // 8-bit rounding step: allow four levels, while constraining each
            // row's mean separately so a systematic lighting shift cannot hide
            // inside that pixel tolerance. The unreflected image is a negative
            // control for a genuinely reversed light source.
            CGFloat maximumRowMeanDifference=0.0;
            for(y=3*scale;y<pixelsHigh-(NSInteger)(3*scale);y++) for(channel=0;channel<3;channel++) {
                NSInteger signedSum=0;
                for(x=6*scale;x<(NSInteger)(154*scale);x++) {
                    signedSum+=(NSInteger)normal[y*stride+x*4+channel]-(NSInteger)reverse[(pixelsHigh-1-y)*stride+x*4+channel];
                }
                maximumRowMeanDifference=MAX(maximumRowMeanDifference,fabs((double)signedSum)/(148.0*scale));
            }
            if(maximumRowMeanDifference>1.5) { fprintf(stderr,"Aqua flipped mean light profile mismatch: %.3f channel levels\n",(double)maximumRowMeanDifference);failures++; }
            if(maximumDifference>4) { fprintf(stderr,"Aqua flipped light profile mismatch: %lu channel levels\n",(unsigned long)maximumDifference);failures++; }
            if(unmirroredDifference<=4) { fprintf(stderr,"Aqua orientation negative control is indistinguishable\n");failures++; }
        }
        minimum=MIN(minimum,contrast);checks++;
        if(contrast<4.5) { fprintf(stderr,"Aqua button title contrast scale%lu flip%lu pressed%lu height%.0f %.3f\n",(unsigned long)scale,(unsigned long)flip,(unsigned long)pressed,(double)height,(double)contrast);failures++; }
    }
    printf("Aqua buttons: %lu actual rasters, minimum title contrast %.2f:1, %lu failures.\n",(unsigned long)checks,(double)minimum,(unsigned long)failures);
    return failures;
}

static void TGWriteAquaMaterialPreview(NSString *output) {
    if(![output length]) return;
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:1000 pixelsHigh:660 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    [[NSColor colorWithCalibratedWhite:0.90 alpha:1] set];NSRectFill(NSMakeRect(0,0,1000,660));
    NSDictionary *label=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:15],NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil];
    [@"Actual Aqua materials — licensed linen / aluminium" drawAtPoint:NSMakePoint(24,625) withAttributes:label];
    NSUInteger row,col;
    for(row=0;row<2;row++) for(col=0;col<3;col++) {
        NSRect rect=NSMakeRect(24+col*325,425-row*140,300,115);
        TGThemeSurfaceRole role=row==0 ? (col==0 ? TGThemeSurfaceHeader : col==1 ? TGThemeSurfaceRail : TGThemeSurfaceRecessed) : (col==0 ? TGThemeSurfaceOutgoing : TGThemeSurfaceIncoming);
        if(row==1 && col==2) TGAquaDrawConversationBackground(rect,NO);
        else TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRoundedRect:rect xRadius:8 yRadius:8],rect,role,NO);
        NSArray *names=[NSArray arrayWithObjects:@"Brushed aluminium",@"Linen source list",@"Inset field",@"Outgoing pearl blue",@"Incoming pearl",@"Linen conversation",nil];
        [[names objectAtIndex:row*3+col] drawAtPoint:NSMakePoint(NSMinX(rect),NSMaxY(rect)+8) withAttributes:label];
    }
    for(row=0;row<2;row++) for(col=0;col<3;col++) {
        BOOL accented=row==0,pressed=col==1,enabled=col!=2;
        NSRect rect=NSMakeRect(50+col*325,155-row*80,230,40);
        TGAquaDrawButtonInPath([NSBezierPath bezierPathWithRoundedRect:rect xRadius:6 yRadius:6],rect,pressed,accented,enabled,NO);
        NSColor *ink=enabled ? (accented ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.12 alpha:1]) : [NSColor colorWithCalibratedWhite:0.40 alpha:1];
        NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:13],NSFontAttributeName,ink,NSForegroundColorAttributeName,nil];
        NSString *title=col==0 ? @"Normal — Настройки" : col==1 ? @"Pressed — Настройки" : @"Disabled — Настройки";
        NSSize size=[title sizeWithAttributes:attrs];
        [title drawAtPoint:NSMakePoint(NSMidX(rect)-size.width/2,NSMidY(rect)-size.height/2) withAttributes:attrs];
    }
    [NSGraphicsContext restoreGraphicsState];
    [[bitmap representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:output atomically:YES];
}

int main(int argc, const char *argv[]) {
    (void)argc;(void)argv;
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    if(!TGInterfaceDesignIsAqua()) { fprintf(stderr,"Run with -MaverickgramInterfaceDesign aqua\n"); [pool drain]; return 1; }
    for(NSString *texture in [NSArray arrayWithObjects:@"black-Linen",@"brushed_alu",@"brushed",nil]) {
        NSString *path=[[NSBundle mainBundle] pathForResource:texture ofType:@"png" inDirectory:@"Textures"];
        NSImage *image=path ? [[[NSImage alloc] initWithContentsOfFile:path] autorelease] : nil;
        if(!image || [image size].width<=0 || [image size].height<=0) { fprintf(stderr,"Missing/invalid bundled Aqua texture: %s\n",[texture UTF8String]);[pool drain];return 1; }
    }
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
    TGWriteAquaMaterialPreview([[[NSProcessInfo processInfo] environment] objectForKey:@"TG_AQUA_PREVIEW_PATH"]);
    [pool drain];return failures?1:0;
}
