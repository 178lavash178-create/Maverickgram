#import <Cocoa/Cocoa.h>
#import "TGThemeContrast.h"
#include <math.h>
#include <assert.h>
static BOOL Aqua;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
NSColor *TGColorFromHex(NSUInteger hex) { return [NSColor colorWithCalibratedRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1]; }
NSColor *TGClassicSelectedRowTextColor(void) { return [NSColor whiteColor]; }
NSColor *TGClassicPanelStrokeColor(void) { return TGColorFromHex(0x606870); }
#include "TGThemeContrast.inc"
__PRODUCTION_AVATAR__

/* Frozen renderer from 9e61303, before the Aqua-only contrast correction.
 * Compare actual pixels to retain Classic's previous shape, color and text. */
static void LegacyAvatar(NSString *title,NSRect rect,BOOL selected) {
 NSBezierPath *path=[NSBezierPath bezierPathWithOvalInRect:rect];
 [(selected ? TGClassicSelectedRowTextColor() : TGAvatarColorForTitle(title)) set];[path fill];
 NSString *initials=TGInitialsForTitle(title);
 NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:10],NSFontAttributeName,[NSColor colorWithCalibratedWhite:1 alpha:0.96],NSForegroundColorAttributeName,nil];
 NSSize size=[initials sizeWithAttributes:attrs];
 [initials drawInRect:NSMakeRect(NSMidX(rect)-floor(size.width/2),NSMidY(rect)-floor(size.height/2)-1,size.width,size.height) withAttributes:attrs];
 [TGClassicPanelStrokeColor() set];[path setLineWidth:1];[path stroke];
}
static NSBitmapImageRep *Draw(NSString *title,BOOL selected,BOOL flipped,NSUInteger scale,BOOL legacy) {
 NSUInteger side=48*scale;
 NSBitmapImageRep *rep=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:side pixelsHigh:side bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
 memset([rep bitmapData],0,[rep bytesPerRow]*[rep pixelsHigh]);
 [NSGraphicsContext saveGraphicsState];NSGraphicsContext *context=[NSGraphicsContext graphicsContextWithBitmapImageRep:rep];[NSGraphicsContext setCurrentContext:context];
 NSAffineTransform *transform=[NSAffineTransform transform];if(flipped)[transform translateXBy:0 yBy:side];[transform scaleXBy:scale yBy:flipped ? -(CGFloat)scale : scale];[transform concat];
 [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[context graphicsPort] flipped:flipped]];
 if(legacy)LegacyAvatar(title,NSMakeRect(8,8,32,32),selected);else TGDrawAvatarImageInRect(nil,title,NSMakeRect(8,8,32,32),selected,flipped);
 [NSGraphicsContext restoreGraphicsState];return rep;
}
static NSColor *Pixel(NSBitmapImageRep *rep,NSInteger x,NSInteger y) {
 NSUInteger p[4];[rep getPixel:p atX:x y:y];return [NSColor colorWithCalibratedRed:p[0]/255.0 green:p[1]/255.0 blue:p[2]/255.0 alpha:p[3]/255.0];
}
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 NSMutableArray *titles=[NSMutableArray arrayWithObjects:@"",@"A",@"Ю",@"Alpha Beta",@"Юра Мак",nil];NSMutableSet *colors=[NSMutableSet set];
 for(NSUInteger i=0;i<1000 && [colors count]<8;i++) {
  NSString *title=[NSString stringWithFormat:@"Alpha%lu Beta",(unsigned long)i];NSString *color=[TGAvatarColorForTitle(title) description];
  if(![colors containsObject:color]) { [colors addObject:color];[titles addObject:title]; }
 }
 assert([colors count]==8);NSUInteger cases=0;
 for(NSString *title in titles)for(NSUInteger scale=1;scale<=2;scale++)for(NSUInteger flipped=0;flipped<2;flipped++)for(NSUInteger selected=0;selected<2;selected++) {
  Aqua=NO;NSBitmapImageRep *classic=Draw(title,selected,flipped,scale,NO),*baseline=Draw(title,selected,flipped,scale,YES);
  assert([classic bytesPerRow]==[baseline bytesPerRow] && memcmp([classic bitmapData],[baseline bitmapData],[classic bytesPerRow]*[classic pixelsHigh])==0);
  Aqua=YES;NSBitmapImageRep *image=Draw(title,selected,flipped,scale,NO);
  NSColor *surface=Pixel(image,24*scale,12*scale);NSUInteger visible=0;
  for(NSInteger x=14*scale;x<34*scale;x++)for(NSInteger y=16*scale;y<32*scale;y++)
   if(TGThemeContrastRatio(Pixel(image,x,y),surface)>=3.0)visible++;
  assert(visible>=2*scale); /* Actual antialiased initials remain visible. */
  NSColor *fill=TGAvatarColorForTitle(title);NSColor *ink=TGThemeReadableInk([NSColor colorWithCalibratedWhite:1 alpha:0.96],fill,4.5);
  assert(TGThemeContrastRatio(ink,fill)>=4.5);
  NSBitmapImageRep *other=Draw(title,!selected,flipped,scale,NO);
  assert(memcmp([image bitmapData],[other bitmapData],[image bytesPerRow]*[image pixelsHigh])==0);
  cases++;
 }
 printf("PASS: %lu actual missing-avatar raster cases, all 8 fills, empty/one/two initials, 1x/2x, both orientations; Aqua contrast and Classic byte-identical\n",(unsigned long)cases);
 [pool drain];return 0;
}
