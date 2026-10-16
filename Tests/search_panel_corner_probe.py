#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Raster the production grouped-card path, including its opt-in search corners."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
with open(os.path.join(ROOT, 'Sources/UI/TGStatusViewCells.m'), 'rb') as handle:
    source = handle.read().decode('utf-8')
start = source.index('@implementation TGGroupedCardView\n')
implementation = source[start:source.index('\n@end', start) + len('\n@end')]
harness = r'''
#import <Cocoa/Cocoa.h>
#import "TGStatusViewCells.h"
#include <assert.h>
#include <math.h>
#include <string.h>
NSColor *TGClassicTableGridColor(void) { return [NSColor colorWithCalibratedWhite:0.5 alpha:1]; }
void TGThemeDrawGroupedCardInPath(NSBezierPath *path,NSRect rect,BOOL flipped) {
    (void)rect;(void)flipped;[[NSColor whiteColor] set];[path fill];
}
__IMPLEMENTATION__
@interface CornerProbeCard : TGGroupedCardView { BOOL _probeFlipped; }
@property(nonatomic,assign) BOOL probeFlipped;
@end
@implementation CornerProbeCard
@synthesize probeFlipped=_probeFlipped;
- (BOOL)isFlipped { return _probeFlipped; }
@end
static NSBitmapImageRep *Paint(CornerProbeCard *view,NSUInteger scale,BOOL marker) {
    NSRect bounds=[view bounds];NSInteger w=lround(NSWidth(bounds)*scale),h=lround(NSHeight(bounds)*scale);
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:w*4 bitsPerPixel:32] autorelease];
    NSGraphicsContext *base=[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *context=[NSGraphicsContext graphicsContextWithGraphicsPort:[base graphicsPort] flipped:[view isFlipped]];
    [NSGraphicsContext setCurrentContext:context];
    [[NSColor blackColor] set];NSRectFill(NSMakeRect(0,0,w,h));
    NSAffineTransform *transform=[NSAffineTransform transform];[transform scaleBy:scale];
    if([view isFlipped]) { [transform translateXBy:0 yBy:NSHeight(bounds)];[transform scaleXBy:1 yBy:-1]; }
    [transform translateXBy:-NSMinX(bounds) yBy:-NSMinY(bounds)];[transform concat];
    if(marker) {
        /* Determine the bitmap's row orientation independently of the tested
         * rounded path; no assumptions about native backing-store row order. */
        [[NSColor whiteColor] set];
        NSRect top=NSMakeRect(NSMinX(bounds),[view isFlipped] ? NSMinY(bounds) : NSMidY(bounds),NSWidth(bounds),NSHeight(bounds)/2);
        NSRectFill(top);
    } else [view drawRect:bounds];
    [NSGraphicsContext restoreGraphicsState];return bitmap;
}
static CGFloat White(NSBitmapImageRep *bitmap,NSInteger x,NSInteger y) {
    NSColor *color=[[bitmap colorAtX:x y:y] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    assert([color alphaComponent]>0.99);return [color redComponent];
}
static NSUInteger Check(CornerProbeCard *view,NSUInteger scale) {
    NSUInteger checks=0;
    NSBitmapImageRep *marker=Paint(view,scale,YES);
    NSInteger width=[marker pixelsWide],height=[marker pixelsHigh];
    BOOL topAtZero=White(marker,width/2,0)>0.9;
    assert((White(marker,width/2,height-1)>0.9)!=topAtZero);checks++;
    assert(![view squareTopCorners]);checks++;
    NSBitmapImageRep *initial=Paint(view,scale,NO);
    [view setSquareTopCorners:NO];NSBitmapImageRep *rounded=Paint(view,scale,NO);
    assert(memcmp([initial bitmapData],[rounded bitmapData],[rounded bytesPerRow]*height)==0);checks++;
    [view setSquareTopCorners:YES];NSBitmapImageRep *squareTop=Paint(view,scale,NO);
    assert(White(squareTop,width/2,height/2)>0.95);checks++;
    for(NSUInteger corner=0;corner<2;corner++)for(NSUInteger x=1;x<=2;x++)for(NSUInteger y=1;y<=2;y++) {
        if(x==2 && y==2)continue;
        NSInteger px=corner ? width-1-(x*scale) : x*scale;
        NSInteger top=topAtZero ? y*scale : height-1-y*scale;
        NSInteger bottom=topAtZero ? height-1-y*scale : y*scale;
        assert(White(rounded,px,top)<0.12 && White(rounded,px,bottom)<0.12);checks++;
        assert(White(squareTop,px,top)>0.95 && White(squareTop,px,bottom)<0.12);checks++;
    }
    [view setDrawsInterior:NO];NSBitmapImageRep *empty=Paint(view,scale,NO);
    assert(White(empty,width/2,height/2)<0.01);checks++;
    [view setDrawsInterior:YES];[view setSquareTopCorners:NO];return checks;
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    NSUInteger checks=0,rasters=0;
    NSSize sizes[]={ {260,138}, {420,226}, {760,320} };
    for(NSUInteger size=0;size<3;size++)for(NSUInteger flipped=0;flipped<2;flipped++)for(NSUInteger origin=0;origin<2;origin++)for(NSUInteger scale=1;scale<=2;scale++) {
        CornerProbeCard *view=[[[CornerProbeCard alloc] initWithFrame:NSMakeRect(0,0,sizes[size].width,sizes[size].height)] autorelease];
        view.probeFlipped=flipped;[view setBoundsOrigin:origin ? NSMakePoint(17,29) : NSZeroPoint];
        checks+=Check(view,scale);rasters+=5;
    }
    printf("PASS: %lu actual grouped-card rasters / %lu checks: defaults rounded, opt-in square top / rounded bottom, flipped/scaled/offset bounds\n",(unsigned long)rasters,(unsigned long)checks);
    [pool drain];return 0;
}
'''
folder = tempfile.mkdtemp(prefix='telegraphica-search-panel-corners-')
try:
    path = os.path.join(folder, 'probe.m')
    binary = os.path.join(folder, 'probe')
    with open(path, 'wb') as handle:
        handle.write(harness.replace('__IMPLEMENTATION__', implementation).encode('utf-8'))
    subprocess.check_call(sys.argv[1:] + [path, '-I' + os.path.join(ROOT, 'Sources/UI'), '-framework', 'Cocoa', '-o', binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
