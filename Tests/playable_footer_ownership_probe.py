#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Draw actual bubble/list cells plus actual media renderer; count metadata paints."""
from __future__ import print_function
import os, subprocess, sys, tempfile, shutil, re
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
def read(path):
 with open(os.path.join(root,path),'rb') as f:return f.read().decode('utf-8')
cells=read('Sources/UI/TGStatusViewCells.m')
cells=cells[cells.index('@implementation TGMessageBubbleCell'):]
runner=read('scripts/run_tests.sh')
sources=re.search(r'MESSAGE_PROBE_SOURCES=\((.*?)\n\)',runner,re.S).group(1).split()
harness=r'''
#define main UnusedSharedFooterMain
#include "__SHARED_PROBE__"
#undef main
#import <objc/runtime.h>
#import "TGStatusViewCells.h"
#import "TGAccessibilitySupport.h"
#import "TGTranscriptMotion.h"
static NSMutableArray *PaintedStrings;
@interface NSString (TGSingleFooterProbe)
- (void)tgSingleFooterDrawInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes;
@end
@implementation NSString (TGSingleFooterProbe)
- (void)tgSingleFooterDrawInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes {
 if(PaintedStrings)[PaintedStrings addObject:self];
 [self tgSingleFooterDrawInRect:rect withAttributes:attributes];
}
@end
void TGAccessibilityConfigureContent(id element,NSString *text){(void)element;(void)text;}
NSString *TGAccessibilityDescriptionForMessageItem(TGMessageItem *item){(void)item;return @"Synthetic";}
BOOL TGTranscriptMotionBeginCellDrawing(NSView *view,NSNumber *chat,NSNumber *message){(void)view;(void)chat;(void)message;return NO;}
void TGTranscriptMotionEndCellDrawing(BOOL began){(void)began;}
static void TGDrawMessageTopAccessories(TGMessageItem *item,NSRect frame,BOOL flipped){(void)item;(void)frame;(void)flipped;}
__CELL__
@interface FooterHost:NSView
@property(nonatomic) BOOL flipped;
@end
@implementation FooterHost
@synthesize flipped=_flipped;
- (BOOL)isFlipped{return self.flipped;}
@end
static NSUInteger Occurrences(NSString *wanted){NSUInteger n=0;for(NSString *s in PaintedStrings)if([s isEqual:wanted])n++;return n;}
int main(int argc,const char **argv){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 BOOL aqua=argc>1 && strcmp(argv[1],"aqua")==0;[[NSUserDefaults standardUserDefaults] setObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey];TGSetLanguageCode(@"ru");
 Method original=class_getInstanceMethod([NSString class],@selector(drawInRect:withAttributes:));Method traced=class_getInstanceMethod([NSString class],@selector(tgSingleFooterDrawInRect:withAttributes:));method_exchangeImplementations(original,traced);
 PaintedStrings=[[NSMutableArray alloc] init];
 for(NSUInteger blocks=0;blocks<=1;blocks++)for(NSUInteger flipped=0;flipped<=1;flipped++)for(NSString *type in [NSArray arrayWithObjects:@"messageAudio",@"messageVoiceNote",@"messageDocument",nil])for(NSUInteger reaction=0;reaction<=1;reaction++) {
  TGSetChatMessagesAsBlocksEnabled(blocks);
  TGMessageItem *item=[[[TGMessageItem alloc] initWithChatID:@-42 messageID:@2 date:@1 outgoing:YES preview:@"Audio"] autorelease];[item setContentType:type];[item setMediaDuration:@90];
  if([type isEqual:@"messageDocument"]){[item setMediaMimeType:@"audio/mpeg"];[item setDownloadFileName:@"Synthetic.mp3"];}[item setPinned:YES];[item setMessageViewerCount:@3];[item setMessageThreadReplyCount:@2];
  if(reaction)[item setReactionSummary:@"❤️ 1  👍 2"];
  Require(TGMessageItemIsNonVisualPlayableMedia(item),@"voice/audio/document fixture uses real nonvisual playable path");
  TGMessageBubbleCell *cell=[[[TGMessageBubbleCell alloc] initTextCell:@""] autorelease];[cell setMessageItem:item];
  FooterHost *host=[[[FooterHost alloc] initWithFrame:NSMakeRect(0,0,640,400)] autorelease];host.flipped=flipped;
  NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:640 pixelsHigh:400 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
  memset([bitmap bitmapData],0,[bitmap bytesPerRow]*400);
  [NSGraphicsContext saveGraphicsState];NSGraphicsContext *context=[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];[NSGraphicsContext setCurrentContext:context];
  NSAffineTransform *transform=[NSAffineTransform transform];if(flipped){[transform translateXBy:0 yBy:400];[transform scaleXBy:1 yBy:-1];}[transform concat];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[context graphicsPort] flipped:flipped]];
  // Warm the one-time font/asset metric before measuring footer ownership.
  TGDrawOutgoingStatusDotsForItem(item,NSMakeRect(10,10,30,14),flipped);
  [PaintedStrings removeAllObjects];[cell drawWithFrame:NSMakeRect(0,0,640,350) inView:host];
  [NSGraphicsContext restoreGraphicsState];
  Require(Occurrences(TGShortTimeStringFromDateValue([item date]))==1,@"owning cell paints timestamp exactly once for audio/voice/document with and without reactions");
  Require(Occurrences([NSString stringWithFormat:TGLoc(@"message.views.format"),@"3"])==1,@"owning cell paints readership exactly once, with no doubled pin/footer path");
  NSUInteger ink=0;const unsigned char *pixels=[bitmap bitmapData];for(NSUInteger i=3;i<[bitmap bytesPerRow]*400;i+=4)if(pixels[i]>64)ink++;
  Require(ink>100,@"complete production cell and playback content produce a real nonempty raster");
 }
 [PaintedStrings release];PaintedStrings=nil;method_exchangeImplementations(original,traced);
 printf("Playable footer ownership %s PASS: %lu actual cell/media timestamp/readership paint-count and raster checks.\n",aqua?"Aqua":"Classic",(unsigned long)checks);[pool drain];return 0;}
'''
harness=harness.replace('__SHARED_PROBE__',os.path.join(root,'Tests/aqua_footer_probe.m')).replace('__CELL__',cells)
folder=tempfile.mkdtemp(prefix='telegraphica-playable-footer-')
try:
 bundle=os.path.join(folder,'FooterProbe.app');contents=os.path.join(bundle,'Contents');os.makedirs(os.path.join(contents,'MacOS'));icons=os.path.join(contents,'Resources/Icons');os.makedirs(icons)
 for name in ['play','done-mini','flag-triangle','route-arrow']:
  shutil.copy(os.path.join(root,'Sources/Resources/Icons',name+'.png'),icons)
 with open(os.path.join(contents,'Info.plist'),'w') as f:f.write('<?xml version="1.0"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>probe</string><key>CFBundleIdentifier</key><string>local.telegraphica.single-footer-probe</string><key>CFBundlePackageType</key><string>APPL</string></dict></plist>')
 source=os.path.join(folder,'probe.m');binary=os.path.join(contents,'MacOS/probe')
 with open(source,'wb') as f:f.write(harness.encode('utf-8'))
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(root,'Sources/UI'),'-I'+os.path.join(root,'Sources/Core'),'-I'+os.path.join(root,'Sources/Services'),'-I'+os.path.join(root,'Sources/Media'),source]+[os.path.join(root,p) for p in sources]+[os.path.join(root,'Sources/UI/TGIconAssets.m'),'-framework','Cocoa','-o',binary])
 subprocess.check_call([binary,'classic']);subprocess.check_call([binary,'aqua'])
finally:shutil.rmtree(folder)
