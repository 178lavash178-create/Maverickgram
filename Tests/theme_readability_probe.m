#import <Cocoa/Cocoa.h>
#import "TGTheme.h"
#import "TGThemeContrast.h"
#include <stdio.h>
int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    NSUInteger failures=0, checks=0;
    CGFloat worst=21;
    NSArray *themes=TGThemeIdentifiers();
    NSBitmapImageRep *sheet=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:920 pixelsHigh:([themes count]*70)
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    NSUInteger row=0;
    for (NSString *theme in themes) {
        TGSetActiveThemeIdentifier(theme);
        NSUInteger role;
        for(role=0;role<9;role++) {
            NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:96 pixelsHigh:48 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
            NSRect r=NSMakeRect(0,0,96,48); NSBezierPath *path=[NSBezierPath bezierPathWithRect:r];
            [TGClassicTablePaperColor() set];NSRectFill(r);
            switch(role) {
                case TGThemeSurfaceRecessed: TGThemeDrawRecessedBackgroundInPath(path,r,NO);break;
                case TGThemeSurfaceWindow: TGThemeDrawWindowBackgroundInRect(r,NO);break;
                case TGThemeSurfaceHeader: TGThemeDrawHeaderBackgroundInRect(r,NO);break;
                case TGThemeSurfaceCard: TGThemeDrawGroupedCardInPath(path,r,NO);break;
                case TGThemeSurfacePanel: TGThemeDrawPanelBackgroundInPath(path,r,NO);break;
                case TGThemeSurfaceRail: TGThemeDrawRailBackgroundInPath(path,r,NO);break;
                case TGThemeSurfaceOutgoing: TGThemeDrawMessageBubbleInPath(path,r,YES,NO);break;
                case TGThemeSurfaceIncoming: TGThemeDrawMessageBubbleInPath(path,r,NO,NO);break;
                default:break;
            }
            NSColor *ink=TGThemeSurfaceInkColor(TGClassicMutedInkColor(),(TGThemeSurfaceRole)role,4.5);
            CGFloat minimum=21;NSInteger x,y;
            for(y=5;y<43;y+=3) for(x=5;x<91;x+=3) minimum=MIN(minimum,TGThemeContrastRatio(ink,[bitmap colorAtX:x y:y]));
            checks++;worst=MIN(worst,minimum);
            if(minimum<4.45) { fprintf(stderr,"FAIL %s role%lu contrast %.2f\n",[theme UTF8String],(unsigned long)role,(double)minimum);failures++; }
            [@"Текст 123" drawAtPoint:NSMakePoint(8,18) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12],NSFontAttributeName,ink,NSForegroundColorAttributeName,nil]];
            [NSGraphicsContext restoreGraphicsState];
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:sheet]];
            [bitmap drawInRect:NSMakeRect(role*102,row*70,96,48)];
            if(role==0) [theme drawAtPoint:NSMakePoint(0,row*70+49) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11],NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]];
            [NSGraphicsContext restoreGraphicsState];
        }
        row++;
    }
    if(argc>1) [[sheet representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:[NSString stringWithUTF8String:argv[1]] atomically:YES];
    printf("Theme surfaces: %lu checks, %lu failures, minimum %.2f\n",(unsigned long)checks,(unsigned long)failures,(double)worst);
    [pool drain];return failures?1:0;
}
