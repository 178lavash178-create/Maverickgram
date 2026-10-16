#!/usr/bin/env python
"""Compose the real Aqua viewport, native scroll view and surface into rasters."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
with open(os.path.join(ROOT, 'Sources/UI/TGStatusViewCells.m'), 'rb') as handle:
    cells = handle.read().decode('utf-8')
start = cells.index('@implementation TGScrollSurfaceView')
surface = cells[start:cells.index('\n@end', start) + len('\n@end')]
with open(os.path.join(ROOT, 'Sources/UI/TGStatusWindowController+AquaShell.inc'), 'rb') as handle:
    shell = handle.read().decode('utf-8')
configuration = shell[shell.index('- (void)configureInterfaceDesignControls'):shell.index('- (void)refreshInterfaceDesignControls')]
guard = configuration.index('if (!TGInterfaceDesignIsAqua()) return;')
hook = configuration.index('TGAquaConfigureTranscriptViewport(')
assert hook > guard, 'Transcript viewport changes must be behind the Aqua guard'

harness = r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGAquaChatBackground.h"
#import "TGAquaChatBackgroundClipView.h"
#import "TGStatusViewCells.h"
#include <assert.h>
#include <math.h>
static TGAquaChatBackgroundStore *Store;
static id SharedStore(id object, SEL selector) { (void)object;(void)selector;return Store; }
NSColor *TGClassicTableGridColor(void) { return [NSColor colorWithCalibratedWhite:0.6 alpha:1]; }
void TGThemeDrawRecessedBackgroundInPath(NSBezierPath *path,NSRect rect,BOOL flipped) { (void)rect;(void)flipped;[[NSColor whiteColor] set];[path fill]; }
__SURFACE__
@interface CornerDefaults : NSUserDefaults
@end
@implementation CornerDefaults
- (id)objectForKey:(NSString *)key { (void)key;return nil; }
- (void)setObject:(id)object forKey:(NSString *)key { (void)object;(void)key; }
- (BOOL)synchronize { return YES; }
@end
@interface CornerDocument : NSView
@end
@implementation CornerDocument
- (BOOL)isFlipped { return YES; }
@end
@interface CornerHost : NSView
@end
@implementation CornerHost
- (BOOL)isOpaque { return YES; }
- (void)drawRect:(NSRect)rect { [[NSColor colorWithCalibratedWhite:0.6 alpha:1] set];NSRectFill(rect); }
@end
static NSBitmapImageRep *Bitmap(NSSize size,NSUInteger scale) {
    return [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:size.width*scale pixelsHigh:size.height*scale bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:size.width*scale*4 bitsPerPixel:32] autorelease];
}
static NSBitmapImageRep *PaintHost(CornerHost *host,NSUInteger scale) {
    NSBitmapImageRep *bitmap=Bitmap([host bounds].size,scale);[bitmap setSize:[host bounds].size];
    [host cacheDisplayInRect:[host bounds] toBitmapImageRep:bitmap];return bitmap;
}
static NSBitmapImageRep *PaintClip(TGAquaChatBackgroundClipView *clip,NSUInteger scale) {
    NSRect bounds=[clip bounds];NSBitmapImageRep *bitmap=Bitmap(bounds.size,scale);
    [bitmap setSize:bounds.size];[clip cacheDisplayInRect:bounds toBitmapImageRep:bitmap];return bitmap;
}
static BOOL Near(NSColor *a,NSColor *b) {
    a=[a colorUsingColorSpaceName:NSDeviceRGBColorSpace];b=[b colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    return fabs([a redComponent]-[b redComponent])<0.035 && fabs([a greenComponent]-[b greenComponent])<0.035 && fabs([a blueComponent]-[b blueComponent])<0.035;
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    Store=[[[TGAquaChatBackgroundStore alloc] initWithDefaults:[[[CornerDefaults alloc] init] autorelease] rootDirectory:@"/unused-corner-probe"] autorelease];
    Method shared=class_getClassMethod([TGAquaChatBackgroundStore class],@selector(sharedStore));IMP original=method_setImplementation(shared,(IMP)SharedStore);
    NSWindow *window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,360,240) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[window setReleasedWhenClosed:NO];
    CornerHost *host=[[[CornerHost alloc] initWithFrame:NSMakeRect(0,0,360,240)] autorelease];[window setContentView:host];
    TGScrollSurfaceView *surface=[[[TGScrollSurfaceView alloc] initWithFrame:NSMakeRect(10,10,340,220)] autorelease];[host addSubview:surface];
    NSScrollView *scroll=[[[NSScrollView alloc] initWithFrame:NSInsetRect([surface frame],1,1)] autorelease];
    [scroll setHasVerticalScroller:YES];[scroll setHasHorizontalScroller:NO];[scroll setBorderType:NSNoBorder];[scroll setDrawsBackground:NO];[scroll setScrollerStyle:NSScrollerStyleLegacy];
    TGAquaChatBackgroundClipView *clip=[[[TGAquaChatBackgroundClipView alloc] initWithFrame:[[scroll contentView] frame]] autorelease];[scroll setContentView:clip];
    CornerDocument *document=[[[CornerDocument alloc] initWithFrame:NSMakeRect(0,0,338,3000)] autorelease];[scroll setDocumentView:document];[host addSubview:scroll];[scroll tile];
    assert(![surface squareEdges] && [surface drawsInterior]);
    assert(NSWidth([clip frame])<NSWidth([scroll bounds])); // Reproduces the reserved white right gutter.
    TGAquaConfigureTranscriptViewport(scroll,surface);
    assert([surface squareEdges] && ![surface drawsInterior]);
    assert([scroll scrollerStyle]==NSScrollerStyleOverlay && [scroll autohidesScrollers]);
    assert(NSWidth([clip frame])==NSWidth([scroll bounds]) && NSHeight([clip frame])==NSHeight([scroll bounds]));
    NSUInteger rasters=0,samples=0;
    NSArray *identifiers=[NSArray arrayWithObjects:@"color-sky",@"wallpaper-sea",@"wallpaper-botanical",nil];
    for(NSString *identifier in identifiers) {
        NSDictionary *config=[TGAquaChatBackgroundStore configurationForPresetIdentifier:identifier];
        if(!config && [identifier hasPrefix:@"color"]) config=[NSDictionary dictionaryWithObjectsAndKeys:@"color",@"kind",@"BDD9F7",@"color",nil];
        assert(config && [Store setConfiguration:config forAccountID:nil chatID:nil error:NULL]);
        for(NSUInteger scale=1;scale<=2;scale++) {
          NSData *stationary=nil;
          for(NSUInteger position=0;position<2;position++) {
            [clip setBoundsOrigin:NSMakePoint(0,position?370:0)];
            [host setNeedsDisplay:YES];[clip setNeedsDisplay:YES];
            NSBitmapImageRep *actual=PaintHost(host,scale),*reference=PaintClip(clip,scale);
            NSData *pixels=[NSData dataWithBytes:[reference bitmapData] length:[reference bytesPerRow]*[reference pixelsHigh]];
            if(!position) stationary=pixels; else assert([stationary isEqual:pixels]);
            if([[config objectForKey:@"kind"] isEqualToString:@"wallpaper"]) {
                BOOL varied=NO;const unsigned char *bytes=[reference bitmapData];
                for(NSUInteger pixel=1;pixel<(NSUInteger)[reference pixelsWide]*(NSUInteger)[reference pixelsHigh];pixel++) {
                    if(bytes[pixel*4]!=bytes[0] || bytes[pixel*4+1]!=bytes[1] || bytes[pixel*4+2]!=bytes[2]) { varied=YES;break; }
                }
                assert(varied); // Missing bundled artwork cannot pass as a flat fallback.
            }
            // Check every pixel in 6x6 patches just inside all four corners,
            // including the former native scrollbar gutter on the right.
            NSRect viewport=[scroll frame];
            for(NSUInteger corner=0;corner<4;corner++) for(NSUInteger dx=2;dx<8;dx++) for(NSUInteger dy=2;dy<8;dy++) {
                NSUInteger x=(corner&1)?(NSUInteger)NSWidth(viewport)-1-dx:dx;
                NSUInteger y=(corner&2)?(NSUInteger)NSHeight(viewport)-1-dy:dy;
                NSColor *expected=[reference colorAtX:x*scale y:y*scale];
                NSColor *pixel=[actual colorAtX:((NSUInteger)NSMinX(viewport)+x)*scale y:((NSUInteger)(NSHeight([host bounds])-NSMaxY(viewport))+y)*scale];
                if(!Near(pixel,expected)) {
                    fprintf(stderr,"Corner mismatch %s scale%lu scroll%lu xy%lu,%lu: actual%s expected%s\n",[identifier UTF8String],(unsigned long)scale,(unsigned long)position,(unsigned long)x,(unsigned long)y,[[pixel description] UTF8String],[[expected description] UTF8String]);
                    assert(NO);
                } samples++;
            }
            rasters++;
          }
        }
    }
    // The existing Classic surface remains rounded and filled by default.
    TGScrollSurfaceView *classic=[[[TGScrollSurfaceView alloc] initWithFrame:NSMakeRect(0,0,100,80)] autorelease];
    assert(![classic squareEdges] && [classic drawsInterior]);
    method_setImplementation(shared,original);[window close];
    printf("Aqua composed transcript corners: %lu rasters/%lu actual-vs-wallpaper pixels, color+2bundled images, 1x/2x, scrolling; no reserved gutter, square Aqua rim, Classic defaults preserved PASS.\n",(unsigned long)rasters,(unsigned long)samples);
    [pool drain];return 0;
}
'''.replace('__SURFACE__', surface)
folder = tempfile.mkdtemp(prefix='telegraphica-aqua-corners-')
try:
    app = os.path.join(folder, 'Probe.app')
    macos = os.path.join(app, 'Contents', 'MacOS')
    resources = os.path.join(app, 'Contents', 'Resources')
    os.makedirs(macos)
    os.makedirs(resources)
    shutil.copytree(os.path.join(ROOT, 'Sources', 'Resources', 'Wallpapers'), os.path.join(resources, 'Wallpapers'))
    source = os.path.join(folder, 'corners.m')
    binary = os.path.join(macos, 'corners')
    with open(source, 'wb') as handle:
        handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:] + ['-I'+os.path.join(ROOT, 'Sources', 'UI'), source,
        os.path.join(ROOT, 'Sources', 'UI', 'TGAquaChatBackground.m'),
        os.path.join(ROOT, 'Sources', 'UI', 'TGAquaChatBackgroundClipView.m'),
        '-framework', 'Cocoa', '-framework', 'ImageIO', '-o', binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
