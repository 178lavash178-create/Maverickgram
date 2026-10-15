#!/usr/bin/env python
"""Rasterize real bundled wallpaper through the production clip and store."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
harness=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGAquaChatBackground.h"
#import "TGAquaChatBackgroundClipView.h"
#include <assert.h>
#include <string.h>
static BOOL Flipped;
static TGAquaChatBackgroundStore *Store;
static id ProbeSharedStore(id object,SEL selector) { (void)object;(void)selector;return Store; }
@interface PhaseDefaults : NSUserDefaults
@end
@implementation PhaseDefaults
- (id)objectForKey:(NSString *)key { (void)key;return nil; }
- (void)setObject:(id)value forKey:(NSString *)key { (void)value;(void)key; }
- (BOOL)synchronize { return YES; }
@end
@interface PhaseDocument : NSView
@end
@implementation PhaseDocument
- (BOOL)isFlipped { return Flipped; }
@end
static NSData *Render(TGAquaChatBackgroundClipView *clip,NSUInteger scale,BOOL requirePattern) {
    NSRect bounds=[clip bounds];
    NSUInteger width=NSWidth(bounds)*scale,height=NSHeight(bounds)*scale;
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width*4 bitsPerPixel:32] autorelease];
    [NSGraphicsContext saveGraphicsState]; [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    NSAffineTransform *transform=[NSAffineTransform transform]; [transform scaleBy:scale];
    if([clip isFlipped]) { [transform translateXBy:0 yBy:NSHeight(bounds)]; [transform scaleXBy:1 yBy:-1]; }
    [transform translateXBy:-NSMinX(bounds) yBy:-NSMinY(bounds)]; [transform concat];
    [clip drawRect:bounds];
    [NSGraphicsContext restoreGraphicsState];
    assert([[bitmap colorAtX:8 y:8] alphaComponent]>0.99);
    if(requirePattern) {
        // A missing resource silently paints the solid fallback. Demand real
        // variation so stationary fallback pixels cannot masquerade as a pass.
        const unsigned char *pixels=[bitmap bitmapData];
        BOOL varied=NO;
        for(NSUInteger pixel=1;pixel<width*height;pixel++) {
            if(memcmp(pixels,pixels+pixel*4,3)!=0) { varied=YES;break; }
        }
        assert(varied);
    }
    return [NSData dataWithBytes:[bitmap bitmapData] length:[bitmap bytesPerRow]*[bitmap pixelsHigh]];
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    PhaseDefaults *defaults=[[[PhaseDefaults alloc] init] autorelease];
    Store=[[[TGAquaChatBackgroundStore alloc] initWithDefaults:defaults rootDirectory:@"/unused-wallpaper-phase-probe"] autorelease];
    Method shared=class_getClassMethod([TGAquaChatBackgroundStore class],@selector(sharedStore));
    IMP original=method_setImplementation(shared,(IMP)ProbeSharedStore);
    NSUInteger checks=0,textureCount=0,wallpaperCount=0;
    NSMutableArray *patterns=[NSMutableArray array];
    for(NSDictionary *preset in [TGAquaChatBackgroundStore presets]) {
        NSString *kind=[preset objectForKey:@"kind"];
        if([kind isEqualToString:@"color"]) continue;
        if([kind isEqualToString:@"texture"]) textureCount++; else wallpaperCount++;
        [patterns addObject:preset];
    }
    assert(textureCount==5 && wallpaperCount==5);
    for(NSDictionary *preset in patterns) for(NSUInteger scale=1;scale<=2;scale++) for(NSUInteger flip=0;flip<2;flip++) {
        NSAutoreleasePool *iterationPool=[[NSAutoreleasePool alloc] init];
        Flipped=flip;
        NSString *identifier=[preset objectForKey:@"id"];
        NSDictionary *configuration=[TGAquaChatBackgroundStore configurationForPresetIdentifier:identifier];
        assert(configuration && [Store setConfiguration:configuration forAccountID:nil chatID:nil error:NULL]);
        TGAquaChatBackgroundClipView *clip=[[[TGAquaChatBackgroundClipView alloc] initWithFrame:NSMakeRect(0,0,180,120)] autorelease];
        PhaseDocument *document=[[[PhaseDocument alloc] initWithFrame:NSMakeRect(0,0,180,3000)] autorelease];
        [clip setDocumentView:document];
        assert([clip isFlipped]==Flipped && ![clip copiesOnScroll]);
        [clip setBoundsOrigin:NSZeroPoint]; NSData *reference=Render(clip,scale,YES);
        // Integer and fractional origins catch phase shifts and backing-scale errors.
        CGFloat origins[]={1,2,17,38,75,123,260,512.5};
        for(NSUInteger i=0;i<sizeof(origins)/sizeof(origins[0]);i++) {
            [clip setBoundsOrigin:NSMakePoint(0,origins[i])];
            if(![reference isEqualToData:Render(clip,scale,NO)]) {
                fprintf(stderr,"Wallpaper moved: %s scale%lu flipped%lu origin%.1f\n",[identifier UTF8String],(unsigned long)scale,(unsigned long)flip,(double)origins[i]);
                return 1;
            }
            checks++;
        }
        [iterationPool drain];
    }
    method_setImplementation(shared,original);
    printf("Aqua actual wallpaper viewport anchoring: %lu scroll rasters,5bundled tiles+5wallpaperimages,nonuniform pixels,1x/2x,both orientations PASS.\n",(unsigned long)checks);
    [pool drain];return 0;
}
'''
folder=tempfile.mkdtemp(prefix='telegraphica-aqua-texture-phase-')
try:
    app=os.path.join(folder,'Probe.app')
    macos=os.path.join(app,'Contents','MacOS')
    resources=os.path.join(app,'Contents','Resources')
    os.makedirs(macos)
    for resource_folder in ('Textures','Wallpapers'):
        shutil.copytree(os.path.join(ROOT,'Sources','Resources',resource_folder),os.path.join(resources,resource_folder))
    source=os.path.join(folder,'probe.m')
    binary=os.path.join(macos,'probe')
    with open(source,'wb') as handle:
        handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources','UI'),source,os.path.join(ROOT,'Sources','UI','TGAquaChatBackground.m'),os.path.join(ROOT,'Sources','UI','TGAquaChatBackgroundClipView.m'),'-framework','Cocoa','-framework','ImageIO','-o',binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
