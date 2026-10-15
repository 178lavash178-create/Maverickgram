#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Exercise production Settings cell, panel paint and settings viewport geometry."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
def read(name):
    with open(os.path.join(ROOT, name), 'rb') as handle:
        return handle.read().decode('utf-8')
def implementation(source, name):
    start = source.index('@implementation ' + name + '\n')
    return source[start:source.index('\n@end', start) + len('\n@end')]
cell = implementation(read('Sources/UI/TGAquaShellViews.m'), 'TGAquaUtilityButtonCell')
panel = implementation(read('Sources/UI/TGStatusViewCells.m'), 'TGPanelView')
layout = read('Sources/UI/TGStatusWindowController+SectionLayout.inc')
start = layout.index('    [self.settingsTitleField setAlignment:NSCenterTextAlignment];')
geometry = layout[start:layout.index('\n    CGFloat settingsDocWidth', start)]
harness = r'''
#import <Cocoa/Cocoa.h>
#import "TGAquaShellViews.h"
#import "TGStatusViewCells.h"
#import "TGAquaAppearance.h"
#include <assert.h>
static BOOL Aqua;
static NSUInteger IconCalls, HeaderCalls;
static NSRect IconFrame;
static NSColor *IconInk;
static CGFloat const TGPanelHeaderHeight=40, TGPanelCornerRadius=14;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
NSColor *TGColorFromHex(NSUInteger hex) {
    return [NSColor colorWithCalibratedRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1];
}
NSColor *TGClassicHeaderSeparatorColor(void) { return [NSColor grayColor]; }
NSColor *TGClassicPanelStrokeColor(void) { return [NSColor grayColor]; }
void TGThemeDrawPanelBackgroundInPath(NSBezierPath *path, NSRect rect, BOOL flipped) {
    TGAquaDrawSurfaceInPath(path,rect,TGThemeSurfacePanel,flipped);
}
void TGThemeDrawHeaderBackgroundInRect(NSRect rect, BOOL flipped) {
    HeaderCalls++; TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:rect],rect,TGThemeSurfaceHeader,flipped);
}
void TGDrawTemplateIconAsset(NSString *name, NSRect rect, NSColor *ink, CGFloat alpha, BOOL flipped) {
    (void)alpha; (void)flipped;
    assert([name isEqualToString:@"settings"]);
    IconCalls++; IconFrame=rect; IconInk=ink;
}
@implementation TGNavigationButtonCell
@synthesize badgeText = _badgeText, iconOnly = _iconOnly;
- (void)dealloc { [_badgeText release]; [super dealloc]; }
@end
@interface FlippedSettingsProbe : NSView
@end
@implementation FlippedSettingsProbe
- (BOOL)isFlipped { return YES; }
@end
__CELL__
__PANEL__
@interface SettingsGeometryProbe : NSObject {
    NSTextField *_settingsTitleField;
    NSScrollView *_settingsScrollView;
}
@property(nonatomic,retain) NSTextField *settingsTitleField;
@property(nonatomic,retain) NSScrollView *settingsScrollView;
- (void)layoutAqua:(BOOL)aqua width:(CGFloat)width top:(CGFloat)top;
@end
@implementation SettingsGeometryProbe
@synthesize settingsTitleField = _settingsTitleField, settingsScrollView = _settingsScrollView;
- (id)init { if((self=[super init])) {
    _settingsTitleField=[[NSTextField alloc] initWithFrame:NSZeroRect];
    _settingsScrollView=[[NSScrollView alloc] initWithFrame:NSZeroRect];
} return self; }
- (void)dealloc { [_settingsTitleField release]; [_settingsScrollView release]; [super dealloc]; }
- (void)layoutAqua:(BOOL)aqua width:(CGFloat)width top:(CGFloat)top {
    CGFloat mainX=0, mainWidth=width, mainTop=top, panelTitleY=top-30;
    CGFloat bottomNavigationY=10, bottomNavigationHeight=62;
__GEOMETRY__
}
@end
static NSBitmapImageRep *Bitmap(NSUInteger width,NSUInteger height) {
    return [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    NSMutableDictionary *alphaMasks=[NSMutableDictionary dictionary];
    NSUInteger cases=0;
    for(NSUInteger flipped=0;flipped<2;flipped++) for(NSUInteger badge=0;badge<2;badge++) for(NSUInteger title=0;title<2;title++) for(NSUInteger enabled=0;enabled<2;enabled++) for(NSUInteger selected=0;selected<2;selected++) for(NSUInteger pressed=0;pressed<2;pressed++) {
        NSView *view=flipped ? [[[FlippedSettingsProbe alloc] initWithFrame:NSMakeRect(0,0,228,64)] autorelease] : [[[NSView alloc] initWithFrame:NSMakeRect(0,0,228,64)] autorelease];
        TGAquaUtilityButtonCell *cell=[[[TGAquaUtilityButtonCell alloc] initTextCell:title ? @"Настройки" : @"Settings"] autorelease];
        [cell setState:selected ? NSOnState : NSOffState]; [cell setHighlighted:pressed]; [cell setEnabled:enabled];
        cell.badgeText=badge ? @"1" : nil;
        NSBitmapImageRep *bitmap=Bitmap(228,64);
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
        IconCalls=0; [cell drawWithFrame:NSMakeRect(16,16,196,32) inView:view];
        assert(IconCalls==1 && NSWidth(IconFrame)==20 && NSHeight(IconFrame)==20);
        assert(NSMinX(IconFrame)>20 && NSMaxX(IconFrame)<208);
        CGFloat r,g,b,a; [[IconInk colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
        if(!enabled) assert(fabs(r-0.4)<0.005 && fabs(g-0.4)<0.005 && fabs(b-0.4)<0.005);
        else if(selected) assert(r>0.99 && g>0.99 && b>0.99);
        else assert(r<0.3 && b<0.4);
        [NSGraphicsContext restoreGraphicsState];
        NSMutableData *mask=[NSMutableData dataWithLength:228*64];
        unsigned char *bytes=[mask mutableBytes];
        NSUInteger visible=0;
        for(NSUInteger y=0;y<64;y++) for(NSUInteger x=0;x<228;x++) {
            CGFloat alpha=[[bitmap colorAtX:x y:y] alphaComponent];
            // Shape threshold is insensitive to gradient color/dithering.
            bytes[y*228+x]=alpha>0.5; if(bytes[y*228+x]) visible++;
        }
        // Every state has the same visible bezel, including the idle button.
        assert(visible>5500);
        NSString *key=[NSString stringWithFormat:@"%lu:%lu:%lu",(unsigned long)flipped,(unsigned long)badge,(unsigned long)title];
        NSData *first=[alphaMasks objectForKey:key];
        if(first) assert([first isEqualToData:mask]); else [alphaMasks setObject:mask forKey:key];
        cases++;
    }
    for(NSUInteger aqua=0;aqua<2;aqua++) for(NSUInteger hidden=0;hidden<2;hidden++) {
        Aqua=aqua; TGPanelView *view=[[[TGPanelView alloc] initWithFrame:NSMakeRect(0,0,400,200)] autorelease];
        assert(!view.headerHidden); view.headerHidden=hidden;
        NSBitmapImageRep *bitmap=Bitmap(400,200);
        [NSGraphicsContext saveGraphicsState]; [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
        HeaderCalls=0; [view drawRect:[view bounds]];
        assert(HeaderCalls==((aqua && hidden) ? 0 : 1));
        [NSGraphicsContext restoreGraphicsState];
    }
    SettingsGeometryProbe *geometry=[[[SettingsGeometryProbe alloc] init] autorelease];
    for(NSUInteger aqua=0;aqua<2;aqua++) for(NSUInteger width=760;width<=1200;width+=220) for(NSUInteger top=480;top<=900;top+=140) {
        [geometry layoutAqua:aqua width:width top:top];
        NSRect frame=[geometry.settingsScrollView frame];
        assert(NSMaxY(frame)==top-(aqua ? 8 : 48));
        assert(NSMinY(frame)==(aqua ? TGAquaFooterBaseHeight() : 82));
        assert(NSMinX(frame)==8 && NSWidth(frame)==width-16);
    }
    printf("Aqua Settings chrome: %lu idle/selected/pressed/disabled real-button rasters; identical bezels; approved icon ink; headerless Aqua/Classic preservation; actual settings viewport PASS.\n",(unsigned long)cases);
    [pool drain]; return 0;
}
'''
if not isinstance(harness, type(u'')):
    harness = harness.decode('utf-8')
harness = harness.replace('__CELL__',cell).replace('__PANEL__',panel).replace('__GEOMETRY__',geometry)
folder=tempfile.mkdtemp(prefix='telegraphica-aqua-settings-')
try:
    source=os.path.join(folder,'probe.m')
    binary=os.path.join(folder,'probe')
    with open(source,'wb') as handle:
        handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),source,os.path.join(ROOT,'Sources/UI/TGAquaAppearance.m'),os.path.join(ROOT,'Sources/UI/TGAquaShellLayout.m'),'-framework','Cocoa','-o',binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
