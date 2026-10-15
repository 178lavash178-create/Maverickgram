#!/usr/bin/env python
"""Paint the real selected Aqua folder cell below the production caption geometry."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
with open(os.path.join(ROOT,'Sources','UI','TGAquaShellViews.m'),'rb') as handle:
    source=handle.read().decode('utf-8')
start=source.index('@implementation TGAquaFolderButtonCell\n')
end=source.index('\n@end',start)+len('\n@end')
cell=source[start:end]
harness=r'''
#import <Cocoa/Cocoa.h>
#import "TGAquaShellViews.h"
#include <assert.h>
#include <math.h>
NSColor *TGColorFromHex(NSUInteger hex) {
 return [NSColor colorWithCalibratedRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1];
}
void TGDrawTemplateIconAsset(NSString *name,NSRect rect,NSColor *ink,CGFloat alpha,BOOL flipped) {
 (void)rect;(void)ink;(void)alpha;(void)flipped;
 assert([name isEqual:@"folder"] || [name isEqual:@"archive"]);
}
@implementation TGNavigationButtonCell
@synthesize badgeText=_badgeText,iconOnly=_iconOnly;
- (void)dealloc { [_badgeText release];[super dealloc]; }
@end
__CELL__
static NSBitmapImageRep *Bitmap(NSUInteger width,NSUInteger height) {
 return [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:width*4 bitsPerPixel:32] autorelease];
}
static BOOL Blue(NSColor *color) {
 NSColor *rgb=[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
 return [rgb blueComponent]>[rgb redComponent]+0.12 && [rgb blueComponent]>[rgb greenComponent]+0.05;
}
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 NSUInteger checks=0;
 for(NSUInteger scale=1;scale<=2;scale++) for(NSUInteger hover=0;hover<2;hover++) {
  NSButton *button=[[[NSButton alloc] initWithFrame:NSMakeRect(0,0,292,32)] autorelease];
  TGAquaFolderButtonCell *cell=[[[TGAquaFolderButtonCell alloc] initTextCell:@"All chats"] autorelease];
  [cell setState:hover ? NSOffState : NSOnState];[cell setHighlighted:hover];
  [button setCell:cell];
  NSBitmapImageRep *bitmap=Bitmap(292*scale,32*scale);
  [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
  NSAffineTransform *transform=[NSAffineTransform transform];[transform scaleBy:scale];[transform concat];
  [cell drawWithFrame:[button bounds] inView:button];[NSGraphicsContext restoreGraphicsState];
  NSUInteger blue=0;
  for(NSUInteger y=0;y<32*scale;y++) for(NSUInteger x=0;x<292*scale;x++) if(Blue([bitmap colorAtX:x y:y])) {
   assert(x>=4*scale && x<288*scale && y>=2*scale && y<30*scale);blue++;
  }
  assert(blue>2000*scale*scale);
  for(NSUInteger folders=1;folders<=20;folders+=19) {
   NSRect sidebar=NSMakeRect(0,0,292,640);
   TGAquaSourceListGeometry geometry=TGAquaSourceListFrames(sidebar,0,210,folders,NO);
   CGFloat captionBottom=NSMaxY(sidebar)-30;
   assert(captionBottom-NSMaxY(geometry.folders)==6);
   assert(NSHeight(geometry.folders)==MIN(folders*32.0,210.0));
   // Clip the first row exactly as NSClipView does, including a negative
   // overscroll origin. The unchanged caption and six-point gap stay outside.
   CGFloat origins[]={-12,0,16};
   for(NSUInteger i=0;i<3;i++) {
    NSBitmapImageRep *paint=Bitmap(292*scale,80*scale);
    [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:paint]];
    NSAffineTransform *scaleTransform=[NSAffineTransform transform];[scaleTransform scaleBy:scale];[scaleTransform concat];
    [[NSColor whiteColor] set];NSRectFill(NSMakeRect(0,0,292,80));
    [NSGraphicsContext saveGraphicsState];NSRectClip(NSMakeRect(0,24,292,32));
    NSAffineTransform *scroll=[NSAffineTransform transform];[scroll translateXBy:0 yBy:-origins[i]];[scroll concat];
    [cell drawWithFrame:NSMakeRect(0,24,292,32) inView:button];
    [NSGraphicsContext restoreGraphicsState];[NSGraphicsContext restoreGraphicsState];
    // Centering the clip in the bitmap makes this assertion independent of
    // AppKit bitmap row orientation: all header/gap pixels must stay white.
    for(NSUInteger y=0;y<80*scale;y++) for(NSUInteger x=0;x<292*scale;x++) if(Blue([paint colorAtX:x y:y]))
     assert(y>=24*scale && y<56*scale);
    checks++;
   }
  }
 }
 printf("Aqua selected folder: 4pt caption inset,4x2pt selection inset,unchanged32pt hit row,capped counts,negative-origin clip PASS (%lu renders).\n",(unsigned long)checks);
 [pool drain];return 0;
}
'''.replace('__CELL__',cell)
folder=tempfile.mkdtemp(prefix='telegraphica-aqua-folder-chrome-')
try:
    source=os.path.join(folder,'probe.m')
    binary=os.path.join(folder,'probe')
    with open(source,'wb') as handle:handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources','UI'),source,os.path.join(ROOT,'Sources','UI','TGAquaShellLayout.m'),'-framework','Cocoa','-o',binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
