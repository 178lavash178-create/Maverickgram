#import <Cocoa/Cocoa.h>
#import "TGStatusViewComponents.h"
#import "TGAvatarImagePresentation.h"
#import "TGTheme.h"
#import "TGThemeContrast.h"
static BOOL Aqua = YES;
static NSRect LastAvatarRect;
static NSUInteger AvatarCalls;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
NSColor *TGColorFromHex(NSUInteger rgb) {
    return [NSColor colorWithCalibratedRed:((rgb>>16)&255)/255.0 green:((rgb>>8)&255)/255.0 blue:(rgb&255)/255.0 alpha:1];
}
#define INK(name) NSColor *name(void) { return [NSColor grayColor]; }
INK(TGClassicCardInkColor) INK(TGClassicCardMutedInkColor) INK(TGClassicMutedInkColor)
INK(TGClassicPanelStrokeColor) INK(TGClassicRailStrokeColor) INK(TGClassicSelectedRowTextColor)
INK(TGClassicTableGridColor) INK(TGClassicWindowBottomColor)
NSColor *TGClassicNavigationSelectedColor(CGFloat alpha) { return [[NSColor grayColor] colorWithAlphaComponent:alpha]; }
NSColor *TGClassicNavigationSelectedStrokeColor(CGFloat alpha) { return [[NSColor grayColor] colorWithAlphaComponent:alpha]; }
NSColor *TGThemeReadableInk(NSColor *ink,NSColor *surface,CGFloat minimum) { (void)surface;(void)minimum;return ink; }
void TGAquaDrawConversationBackground(NSRect rect,BOOL flipped) { (void)rect;(void)flipped; }
void TGAquaDrawVerticalSeam(NSRect rect) { (void)rect; }
void TGThemeDrawWindowBackgroundInRect(NSRect rect,BOOL flipped) { (void)rect;(void)flipped; }
#define SURFACE(name) void name(NSBezierPath *path,NSRect rect,BOOL flipped) { (void)path;(void)rect;(void)flipped; }
SURFACE(TGThemeDrawGroupedCardInPath) SURFACE(TGThemeDrawPanelBackgroundInPath) SURFACE(TGThemeDrawRailBackgroundInPath)
void TGDrawTemplateIconAsset(NSString *name,NSRect rect,NSColor *color,CGFloat alpha,BOOL flipped) {
    (void)name;(void)rect;(void)color;(void)alpha;(void)flipped;
}
// Record the actual production drawRect/helper boundary. Circular image masking
// belongs to the unchanged shared helper; this fixture supplies a solid circle.
void TGDrawAvatarImageInRect(NSImage *image,NSString *title,NSRect rect,BOOL selected,BOOL flipped) {
    (void)image;(void)title;(void)selected;(void)flipped;
    LastAvatarRect=rect; AvatarCalls++;
    [[NSColor redColor] set]; [[NSBezierPath bezierPathWithOvalInRect:rect] fill];
}
@implementation TGAvatarImagePresentation
- (id)initWithView:(NSView *)view { (void)view;return [super init]; }
- (void)setPath:(NSString *)path { (void)path; }
- (NSImage *)imageForDrawing { return nil; }
@end
static void Require(BOOL ok,const char *message) { if(!ok){fprintf(stderr,"Account badge: %s\n",message);exit(1);} }
static void Check(NSSize size) {
    TGAccountBadgeView *view=[[[TGAccountBadgeView alloc] initWithFrame:NSMakeRect(0,0,size.width,size.height)] autorelease];
    view.connected=YES; view.displayName=@"Test";
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:96 pixelsHigh:96 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    NSAffineTransform *offset=[NSAffineTransform transform]; [offset translateXBy:20 yBy:20]; [offset concat];
    NSUInteger previous=AvatarCalls; [view drawRect:[view bounds]];
    [NSGraphicsContext restoreGraphicsState];
    if (Aqua && MIN(size.width,size.height)<=4) { Require(AvatarCalls==previous,"tiny badge safely skips drawing");return; }
    Require(AvatarCalls==previous+1,"one shared avatar draw");
    if(Aqua) {
        Require(NSContainsRect(NSInsetRect([view bounds],1,1),LastAvatarRect),"Aqua avatar plus rim fits bounds");
        Require(NSWidth(LastAvatarRect)==NSHeight(LastAvatarRect),"avatar remains circular");
        if(size.width==32 && size.height==34) {
            Require(NSEqualRects(LastAvatarRect,NSMakeRect(2,3,28,28)),"toolbar avatar is 28pt inside 32x34");
            NSInteger minX=96,maxX=-1,minY=96,maxY=-1; NSUInteger greenPixels=0;
            for(NSInteger y=0;y<96;y++) for(NSInteger x=0;x<96;x++) {
                NSColor *c=[[bitmap colorAtX:x y:y] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
                if([c alphaComponent]>0.05) {
                    minX=MIN(minX,x);maxX=MAX(maxX,x);minY=MIN(minY,y);maxY=MAX(maxY,y);
                    if([c greenComponent]>0.6 && [c redComponent]<0.3 && [c blueComponent]<0.4) greenPixels++;
                }
            }
            Require(maxX>=minX && maxX-minX+1<=32 && maxY-minY+1<=34,"rendered rim/avatar/status stay within badge extent");
            Require(greenPixels>8,"connected status dot is visible");
        }
    } else Require(NSWidth(LastAvatarRect)==44 && NSHeight(LastAvatarRect)==44,"Classic stays 44pt");
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    CGFloat widths[]={0,3,5,12,24,32,44,60}; CGFloat heights[]={0,3,5,14,24,34,44,60};
    for(NSUInteger w=0;w<8;w++) for(NSUInteger h=0;h<8;h++) Check(NSMakeSize(widths[w],heights[h]));
    Aqua=NO;Check(NSMakeSize(60,60));Check(NSMakeSize(32,34));
    puts("Account badge PASS: 64 Aqua bounds, 32x34 production draw/rim/status raster, Classic 44pt");
    [pool drain];return 0;
}
