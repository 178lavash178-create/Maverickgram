#!/usr/bin/env python
"""Render the production chat cell with real approved marker assets and fonts."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
with open(os.path.join(ROOT,'Sources/UI/TGStatusViewCells.m'),'rb') as handle:
    source=handle.read().decode('utf-8')
start=source.index('@implementation TGChatListCell\n')
cell=source[start:source.index('\n@end',start)+len('\n@end')]
harness=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGStatusViewCells.h"
#import "TGChatListSelectionAppearance.h"
#import "TGChatUnreadBadgeAppearance.h"
#import "TGThemeContrast.h"
#import "TGLocalization.h"
#import "TGChatItem.h"
#include <assert.h>
#include <string.h>
static NSMutableArray *Texts,*Inks,*Frames,*Markers;
#define TGDrawTemplateIconAsset TGRealApprovedMarker
#import "TGIconAssets.m"
#undef TGDrawTemplateIconAsset
void TGDrawTemplateIconAsset(NSString *name,NSRect rect,NSColor *ink,CGFloat alpha,BOOL flipped) {
    [Markers addObject:[NSDictionary dictionaryWithObjectsAndKeys:name,@"name",ink,@"ink",nil]];
    TGRealApprovedMarker(name,rect,ink,alpha,flipped);
}
void TGDrawAvatarInRect(NSString *path,NSString *title,NSRect rect,BOOL selected,BOOL flipped) { (void)path;(void)title;(void)rect;(void)selected;(void)flipped; }
void TGAccessibilityConfigureContent(id element,NSString *description) { (void)element;(void)description; }
NSString *TGAccessibilityDescriptionForChatItem(TGChatItem *item) { (void)item;return @"synthetic chat"; }
@interface NSString (RowCapture)
- (void)tgRowDrawInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes;
@end
@implementation NSString (RowCapture)
- (void)tgRowDrawInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes {
    if(Texts && [attributes objectForKey:NSForegroundColorAttributeName]) {
        [Texts addObject:self];[Inks addObject:[attributes objectForKey:NSForegroundColorAttributeName]];[Frames addObject:[NSValue valueWithRect:rect]];
    }
    [self tgRowDrawInRect:rect withAttributes:attributes];
}
@end
@interface FlippedRowView : NSView
@end
@implementation FlippedRowView
- (BOOL)isFlipped { return YES; }
@end
__CELL__
static BOOL White(NSColor *color) {
    NSColor *rgb=[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    return [rgb redComponent]>0.99 && [rgb greenComponent]>0.99 && [rgb blueComponent]>0.99 && [rgb alphaComponent]>0.99;
}
static BOOL Same(NSColor *a,NSColor *b) {
    a=[a colorUsingColorSpaceName:NSCalibratedRGBColorSpace];b=[b colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    return fabs([a redComponent]-[b redComponent])<0.01 && fabs([a greenComponent]-[b greenComponent])<0.01 && fabs([a blueComponent]-[b blueComponent])<0.01;
}
int main(int argc,const char **argv) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    BOOL aqua=(argc>1 && strcmp(argv[1],"aqua")==0);
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
    [NSApplication sharedApplication];assert(TGInterfaceDesignIsAqua()==aqua);
    assert(TGIconAssetImageNamed(@"robot") && TGIconAssetImageNamed(@"flag-triangle") && TGIconAssetImageNamed(@"sound-off"));
    Texts=[NSMutableArray array];Inks=[NSMutableArray array];Frames=[NSMutableArray array];Markers=[NSMutableArray array];
    method_exchangeImplementations(class_getInstanceMethod([NSString class],@selector(drawInRect:withAttributes:)),class_getInstanceMethod([NSString class],@selector(tgRowDrawInRect:withAttributes:)));
    NSUInteger rasters=0,markerChecks=0,glyphChecks=0;
    NSArray *themes=aqua?[NSArray arrayWithObjects:TGThemeIdentifierVKBlue,TGThemeIdentifierVisualNotebook,TGThemeIdentifierVisualSpaceTerminal,nil]:TGThemeIdentifiers();
    for(NSString *theme in themes) {
      TGSetActiveThemeIdentifier(theme);
      for(NSUInteger selected=0;selected<2;selected++) for(NSUInteger flip=0;flip<2;flip++) for(NSUInteger scale=1;scale<=2;scale++) for(NSUInteger variant=0;variant<4;variant++) {
        BOOL compact=(variant==3),muted=(variant==1);
        TGChatItem *item=[[[TGChatItem alloc] initWithChatID:@42 title:@"Synthetic selected chat" typeSummary:@"Private" unreadCount:variant<2?@999:@0] autorelease];
        item.notificationsMuted=muted;item.pinned=YES;item.bot=YES;item.community=YES;item.markedAsUnread=(variant==2);
        CGFloat width=compact?92:360;NSRect bounds=NSMakeRect(0,0,width,36);
        NSView *view=flip?[[[FlippedRowView alloc] initWithFrame:bounds] autorelease]:[[[NSView alloc] initWithFrame:bounds] autorelease];
        TGChatListCell *chat=[[[TGChatListCell alloc] initTextCell:@""] autorelease];chat.chatItem=item;[chat setHighlighted:selected];
        [Texts removeAllObjects];[Inks removeAllObjects];[Frames removeAllObjects];[Markers removeAllObjects];
        NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width*scale pixelsHigh:36*scale bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:width*scale*4 bitsPerPixel:32] autorelease];
        [NSGraphicsContext saveGraphicsState];NSGraphicsContext *base=[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[base graphicsPort] flipped:flip]];
        NSAffineTransform *transform=[NSAffineTransform transform];[transform scaleBy:scale];if(flip) { [transform translateXBy:0 yBy:36];[transform scaleXBy:1 yBy:-1]; } [transform concat];
        [TGClassicTablePaperColor() set];NSRectFill(bounds);[chat drawWithFrame:bounds inView:view];[NSGraphicsContext restoreGraphicsState];
        if(selected) {
            NSColor *background=[bitmap colorAtX:20*scale y:8*scale];
            assert(Same(background,TGChatListSelectionBackground()));
            if(aqua) { assert(White(TGChatListSelectionForeground()));assert(TGThemeContrastRatio([NSColor whiteColor],background)>=4.5); }
            else { assert(Same(TGChatListSelectionBackground(),TGClassicSelectedRowColor()));assert(Same(TGChatListSelectionForeground(),TGClassicSelectedRowTextColor())); }
        }
        if(!compact) {
            NSUInteger title=[Texts indexOfObject:item.title];assert(title!=NSNotFound);
            NSColor *ink=[Inks objectAtIndex:title];
            assert(Same(ink,selected?TGChatListSelectionForeground():TGThemeSurfaceInkColor(TGClassicInkColor(),TGThemeSurfaceRecessed,4.5)));
            if(aqua && selected) {
                assert(White(ink));NSRect text=[[Frames objectAtIndex:title] rectValue];NSUInteger whitePixels=0;
                if(!flip) text.origin.y=36-NSMaxY(text);
                for(NSUInteger y=ceil(NSMinY(text)*scale);y<(NSUInteger)floor(NSMaxY(text)*scale);y++) for(NSUInteger x=ceil(NSMinX(text)*scale);x<(NSUInteger)floor(NSMaxX(text)*scale);x++) {
                    NSColor *pixel=[[bitmap colorAtX:x y:y] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
                    if([pixel redComponent]>.90 && [pixel greenComponent]>.90 && [pixel blueComponent]>.90) whitePixels++;
                }
                assert(whitePixels>4*scale);glyphChecks++;
                for(NSDictionary *marker in Markers) { assert(White([marker objectForKey:@"ink"]));markerChecks++; }
                NSUInteger community=[Texts indexOfObject:TGLoc(@"chat.community.badge")];assert(community!=NSNotFound && White([Inks objectAtIndex:community]));
                if(variant==0) { NSUInteger counter=[Texts indexOfObject:@"999"];assert(counter!=NSNotFound);assert(Same([Inks objectAtIndex:counter],TGChatListSelectionBackground())); }
            }
        }
        rasters++;
      }
    }
    method_exchangeImplementations(class_getInstanceMethod([NSString class],@selector(drawInRect:withAttributes:)),class_getInstanceMethod([NSString class],@selector(tgRowDrawInRect:withAttributes:)));
    printf("%s chat row selection: %lu actual cell rasters,%lu white title glyph regions,%lu approved white markers; selected/unselected,muted/unread/community/compact,both orientations,1x/2x,Classic palette preservation PASS.\n",aqua?"Aqua":"Classic",(unsigned long)rasters,(unsigned long)glyphChecks,(unsigned long)markerChecks);
    [pool drain];return 0;
}
'''.replace('__CELL__',cell)
folder=tempfile.mkdtemp(prefix='telegraphica-chat-selection-')
try:
    app=os.path.join(folder,'Probe.app')
    macos=os.path.join(app,'Contents','MacOS');resources=os.path.join(app,'Contents','Resources')
    os.makedirs(macos);os.makedirs(resources)
    shutil.copytree(os.path.join(ROOT,'Sources/Resources/Icons'),os.path.join(resources,'Icons'))
    source=os.path.join(folder,'selection.m');binary=os.path.join(macos,'selection')
    with open(source,'wb') as handle:handle.write(harness.encode('utf-8'))
    ui=os.path.join(ROOT,'Sources/UI');core=os.path.join(ROOT,'Sources/Core')
    subprocess.check_call(sys.argv[1:]+['-I'+ui,'-I'+core,source,os.path.join(core,'TGChatItem.m'),os.path.join(ui,'TGChatUnreadBadgeAppearance.m'),os.path.join(ui,'TGLocalization.m'),os.path.join(ui,'TGTheme.m'),os.path.join(ui,'TGInterfaceDesign.m'),os.path.join(ui,'TGDialogPresentation.m'),os.path.join(ui,'TGAquaAppearance.m'),os.path.join(ui,'TGVisualWorldThemeSpec.m'),'-framework','Cocoa','-o',binary])
    subprocess.check_call([binary,'aqua'])
    subprocess.check_call([binary,'classic'])
finally:
    shutil.rmtree(folder)
