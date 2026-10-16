#!/usr/bin/env python
"""Exercise the production viewport and table background hooks without account data."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
with open(os.path.join(ROOT, 'Sources/UI/TGStatusViewComponents.m'), 'rb') as handle:
    table_source = handle.read().decode('utf-8')
start = table_source.index('@implementation TGMessageTableView\n')
end = table_source.index('@synthesize dropOverlayTarget', start)
table_background = table_source[start:end] + '\n@end\n'
harness = r'''
#import <Cocoa/Cocoa.h>
#import "TGAquaChatBackgroundClipView.h"
#import "TGAquaChatBackground.h"
#include <assert.h>
static BOOL Aqua = YES;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
NSString * const TGAquaChatBackgroundDidChangeNotification = @"ProbeBackgroundChanged";
static NSRect LastViewport, LastDirty;
static NSNumber *LastAccount, *LastChat;
static NSUInteger DrawCalls;
@implementation TGAquaChatBackgroundStore
+ (TGAquaChatBackgroundStore *)sharedStore {
    static TGAquaChatBackgroundStore *store=nil;
    if(!store) store=[[self alloc] init];
    return store;
}
- (void)drawBackgroundInClipRect:(NSRect)dirty viewportRect:(NSRect)viewport flipped:(BOOL)flipped accountID:(NSNumber *)account chatID:(NSNumber *)chat {
    (void)flipped; LastViewport=viewport; LastDirty=dirty; LastAccount=account; LastChat=chat; DrawCalls++;
    [NSGraphicsContext saveGraphicsState]; NSRectClip(dirty);
    [[NSColor redColor] set]; NSRectFill(viewport);
    [[NSColor blueColor] set]; NSRectFill(NSMakeRect(NSMidX(viewport),NSMinY(viewport),NSWidth(viewport)/2,NSHeight(viewport)));
    [NSGraphicsContext restoreGraphicsState];
}
@end
@interface TGMessageTableView : NSTableView
@end
__TABLE_BACKGROUND__
static NSUInteger ClipInvalidations, DocumentInvalidations;
@interface ClipProbe : TGAquaChatBackgroundClipView
@end
@implementation ClipProbe
- (void)setNeedsDisplay:(BOOL)value { if(value) ClipInvalidations++; [super setNeedsDisplay:value]; }
@end
@interface DocumentProbe : NSView
@end
@implementation DocumentProbe
- (void)setNeedsDisplay:(BOOL)value { if(value) DocumentInvalidations++; [super setNeedsDisplay:value]; }
@end
static NSBitmapImageRep *Bitmap(NSUInteger width, NSUInteger height) {
    return [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
}
static NSData *Paint(TGAquaChatBackgroundClipView *clip) {
    NSRect viewport=[clip bounds];
    NSBitmapImageRep *bitmap=Bitmap(NSWidth(viewport),NSHeight(viewport));
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    NSAffineTransform *transform=[NSAffineTransform transform];
    [transform translateXBy:-NSMinX(viewport) yBy:-NSMinY(viewport)]; [transform concat];
    [clip drawRect:viewport];
    [NSGraphicsContext restoreGraphicsState];
    assert(NSEqualRects(LastViewport,viewport) && NSEqualRects(LastDirty,viewport));
    assert([[bitmap colorAtX:8 y:8] alphaComponent]>0.99);
    assert([[bitmap colorAtX:NSWidth(viewport)-8 y:NSHeight(viewport)-8] alphaComponent]>0.99);
    return [NSData dataWithBytes:[bitmap bitmapData] length:[bitmap bytesPerRow]*[bitmap pixelsHigh]];
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    TGAquaChatBackgroundClipView *clip=[[[ClipProbe alloc] initWithFrame:NSMakeRect(0,0,120,80)] autorelease];
    assert([clip isOpaque] && [clip drawsBackground] && ![clip copiesOnScroll]);
    // Empty viewport and short transcript must still fill the complete visible area.
    NSData *empty=Paint(clip);
    NSView *document=[[[DocumentProbe alloc] initWithFrame:NSMakeRect(0,0,120,20)] autorelease];
    [clip setDocumentView:document];
    assert([empty isEqualToData:Paint(clip)]);
    [document setFrameSize:NSMakeSize(120,2000)];
    NSData *first=Paint(clip);
    for(NSUInteger y=0;y<=1500;y+=125) {
        [clip setNeedsDisplay:NO]; [document setNeedsDisplay:NO]; ClipInvalidations=DocumentInvalidations=0;
        [clip setBoundsOrigin:NSMakePoint(0,y)];
        if(y>0) assert(ClipInvalidations>0 && DocumentInvalidations>0);
        assert([first isEqualToData:Paint(clip)]);
    }
    [clip setNeedsDisplay:NO]; [document setNeedsDisplay:NO]; ClipInvalidations=DocumentInvalidations=0;
    [clip setFrameSize:NSMakeSize(160,100)];
    assert(ClipInvalidations>0 && DocumentInvalidations>0); Paint(clip);
    [clip setBackgroundAccountID:@11 chatID:@-99];
    Paint(clip); assert([LastAccount isEqual:@11] && [LastChat isEqual:@-99]);
    [clip setNeedsDisplay:NO]; [document setNeedsDisplay:NO]; ClipInvalidations=DocumentInvalidations=0;
    [clip setBackgroundAccountID:[NSNumber numberWithInt:11] chatID:[NSNumber numberWithInt:-99]];
    assert(ClipInvalidations==0 && DocumentInvalidations==0);
    [[NSNotificationCenter defaultCenter] postNotificationName:TGAquaChatBackgroundDidChangeNotification object:nil];
    assert(ClipInvalidations>0 && DocumentInvalidations>0);
    [clip setBackgroundAccountID:@22 chatID:@-99]; Paint(clip);
    assert([LastAccount isEqual:@22] && [LastChat isEqual:@-99]);
    [clip setBackgroundAccountID:nil chatID:nil]; Paint(clip); assert(!LastAccount && !LastChat);
    [clip setNeedsDisplay:NO]; [document setNeedsDisplay:NO]; ClipInvalidations=DocumentInvalidations=0;
    [clip drawRect:NSMakeRect(0,0,12,12)];
    assert(NSEqualRects(LastDirty,NSMakeRect(0,0,12,12)));
    TGMessageTableView *table=[[[TGMessageTableView alloc] initWithFrame:NSMakeRect(0,0,120,80)] autorelease];
    for(NSUInteger mode=0;mode<2;mode++) {
        Aqua=mode; NSBitmapImageRep *bitmap=Bitmap(120,80);
        [table setBackgroundColor:[NSColor greenColor]];
        [NSGraphicsContext saveGraphicsState]; [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
        [table drawBackgroundInClipRect:[table bounds]];
        [NSGraphicsContext restoreGraphicsState];
        if(Aqua) assert(![table isOpaque] && [[bitmap colorAtX:8 y:8] alphaComponent]==0);
        else assert([[bitmap colorAtX:8 y:8] alphaComponent]>0.99);
    }
    printf("Aqua viewport background: empty/short transcript, stationary scrolling, resize, scope/notification invalidation; actual table hooks preserve Aqua transparency/Classic paint PASS (%lu draws).\n",(unsigned long)DrawCalls);
    [pool drain]; return 0;
}
'''.replace('__TABLE_BACKGROUND__', table_background)
folder = tempfile.mkdtemp(prefix='telegraphica-aqua-background-clip-')
try:
    source=os.path.join(folder,'probe.m')
    binary=os.path.join(folder,'probe')
    with open(source,'wb') as handle:
        handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+['-Wno-incomplete-implementation','-I'+os.path.join(ROOT,'Sources/UI'),source,os.path.join(ROOT,'Sources/UI/TGAquaChatBackgroundClipView.m'),'-framework','Cocoa','-o',binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
