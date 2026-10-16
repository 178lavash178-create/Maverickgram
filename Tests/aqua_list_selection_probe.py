#!/usr/bin/env python
"""Raster production utility rows, search table and date separator surfaces."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
def read(path):
    with open(os.path.join(ROOT, path), 'rb') as handle:
        return handle.read().decode('utf-8')
def implementation(source, name):
    start = source.index('@implementation ' + name + '\n')
    return source[start:source.index('\n@end', start) + len('\n@end')] + '\n'
cells = read('Sources/UI/TGStatusViewCells.m')
contacts = read('Sources/UI/TGContactsViewController.m')
search = read('Sources/UI/TGChatSearchPanelView.inc')
accessory_start = cells.index('static void TGDrawMessageTopAccessories(')
production = implementation(cells, 'TGRepresentedObjectCell')
production += contacts[contacts.index('static NSString *TGContactsSubtitle('):contacts.index('@interface TGContactsViewController ()')]
production += read('Sources/UI/TGChatFolderManagementWindowController+Cells.inc')
production += read('Sources/UI/TGPrivacyWindowController+BlockedSenderCell.inc')
production += search[:search.index('@interface TGChatSearchPanelView :')]
production += cells[accessory_start:cells.index('\n@implementation TGMessageBubbleCell', accessory_start)]
harness = r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGStatusViewCells.h"
#import "TGChatListSelectionAppearance.h"
#import "TGThemeContrast.h"
#import "TGLocalization.h"
#import "TGChatItem.h"
#import "TGSearchResultItem.h"
#import "TGSavedMessagesCell.h"
#import "TGIconAssets.h"
#import "TGMessageLayoutSupport.h"
#include <assert.h>
#include <string.h>
static NSMutableArray *Texts,*Inks,*Frames;
// Avatars and photo decoding have their own probes; these rows contain only
// synthetic account-independent text. All typography and selected materials
// below are the production drawing implementations.
void TGDrawAvatarInRect(NSString *p,NSString *t,NSRect r,BOOL s,BOOL f) {(void)p;(void)t;(void)r;(void)s;(void)f;}
NSImage *TGMediaCachedThumbnailFromFile(NSString *p,NSUInteger s) {(void)p;(void)s;return nil;}
void TGLoadImageThumbnailFromFileAsync(NSString *p,NSUInteger s,void(^done)(NSImage *)) {(void)p;(void)s;(void)done;assert(0);}
@interface TGMessageItem : NSObject
@property(nonatomic,copy) NSString *dateSeparatorTitle;
@property(nonatomic,assign) BOOL showsUnreadSeparator;
@end
@implementation TGMessageItem
@synthesize dateSeparatorTitle=_dateSeparatorTitle,showsUnreadSeparator=_showsUnreadSeparator;
- (void)dealloc {[_dateSeparatorTitle release];[super dealloc];}
@end
@interface NSString (SelectionCapture)
- (void)tgSelectionDrawInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes;
@end
@implementation NSString (SelectionCapture)
- (void)tgSelectionDrawInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes {
    if(Texts && [attributes objectForKey:NSForegroundColorAttributeName]) {
        [Texts addObject:self];[Inks addObject:[attributes objectForKey:NSForegroundColorAttributeName]];[Frames addObject:[NSValue valueWithRect:rect]];
    }
    [self tgSelectionDrawInRect:rect withAttributes:attributes];
}
@end
@interface Flipped : NSView
@end
@implementation Flipped
- (BOOL)isFlipped {return YES;}
@end
__PRODUCTION__
@interface SearchSource : NSObject <NSTableViewDataSource>
@property(nonatomic,retain) TGSearchResultItem *result;
@end
@implementation SearchSource
@synthesize result=_result;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)table {return 1;}
- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)col row:(NSInteger)row {return self.result;}
- (void)dealloc {[_result release];[super dealloc];}
@end
static BOOL Same(NSColor *a,NSColor *b) {
    a=[a colorUsingColorSpaceName:NSCalibratedRGBColorSpace];b=[b colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    return fabs([a redComponent]-[b redComponent])<.015 && fabs([a greenComponent]-[b greenComponent])<.015 && fabs([a blueComponent]-[b blueComponent])<.015;
}
static BOOL White(NSColor *c) {return Same(c,[NSColor whiteColor]) && [c alphaComponent]>.99;}
static NSUInteger WhitePixels(NSBitmapImageRep *bitmap,NSRect frame,BOOL flipped,NSUInteger scale,CGFloat height) {
    if(!flipped) frame.origin.y=height-NSMaxY(frame);
    NSUInteger n=0;
    for(NSInteger y=MAX(0,ceil(NSMinY(frame)*scale));y<MIN([bitmap pixelsHigh],floor(NSMaxY(frame)*scale));y++)
      for(NSInteger x=MAX(0,ceil(NSMinX(frame)*scale));x<MIN([bitmap pixelsWide],floor(NSMaxX(frame)*scale));x++) {
        NSColor *c=[[bitmap colorAtX:x y:y] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        if([c redComponent]>.92 && [c greenComponent]>.92 && [c blueComponent]>.92) n++;
      }
    return n;
}
static NSBitmapImageRep *Begin(CGFloat width,CGFloat height,BOOL flipped,NSUInteger scale) {
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width*scale pixelsHigh:height*scale bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:width*scale*4 bitsPerPixel:32] autorelease];
    [NSGraphicsContext saveGraphicsState];NSGraphicsContext *base=[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[base graphicsPort] flipped:flipped]];
    NSAffineTransform *transform=[NSAffineTransform transform];[transform scaleBy:scale];
    if(flipped) {[transform translateXBy:0 yBy:height];[transform scaleXBy:1 yBy:-1];}[transform concat];
    [TGClassicTablePaperColor() set];NSRectFill(NSMakeRect(0,0,width,height));
    [Texts removeAllObjects];[Inks removeAllObjects];[Frames removeAllObjects];return bitmap;
}
static void VerifyGlyphs(NSBitmapImageRep *bitmap,BOOL flip,NSUInteger scale,CGFloat height) {
    assert([Texts count]>=1);
    for(NSUInteger n=0;n<[Texts count];n++) {
        if(!White([Inks objectAtIndex:n])) fprintf(stderr,"non-white drawn text: %s\n",[[Texts objectAtIndex:n] UTF8String]);assert(White([Inks objectAtIndex:n]));
        assert(WhitePixels(bitmap,[[Frames objectAtIndex:n] rectValue],flip,scale,height)>3*scale);
    }
}
int main(int argc,const char **argv) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];BOOL aqua=argc>1 && strcmp(argv[1],"aqua")==0;
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
    [NSApplication sharedApplication];assert(TGInterfaceDesignIsAqua()==aqua);
    Texts=[NSMutableArray array];Inks=[NSMutableArray array];Frames=[NSMutableArray array];
    method_exchangeImplementations(class_getInstanceMethod([NSString class],@selector(drawInRect:withAttributes:)),class_getInstanceMethod([NSString class],@selector(tgSelectionDrawInRect:withAttributes:)));
    NSArray *themes=[NSArray arrayWithObjects:TGThemeIdentifierVKBlue,TGThemeIdentifierVisualNotebook,TGThemeIdentifierVisualSpaceTerminal,nil];
    NSUInteger rows=0,searches=0,dates=0;
    for(NSString *theme in themes) {
      TGSetActiveThemeIdentifier(theme);
      if(!aqua) {assert(Same(TGListSelectionBackground(),TGClassicSelectedRowColor()));assert(Same(TGListSelectionForeground(),TGClassicSelectedRowTextColor()));}
      for(NSUInteger selected=0;selected<2;selected++) for(NSUInteger flip=0;flip<2;flip++) for(NSUInteger scale=1;scale<=2;scale++) {
        NSRect bounds=NSMakeRect(0,0,360,50);NSView *view=flip?[[[Flipped alloc] initWithFrame:bounds] autorelease]:[[[NSView alloc] initWithFrame:bounds] autorelease];
        TGContactRowCell *contact=[[[TGContactRowCell alloc] initTextCell:@""] autorelease];[contact setObjectValue:[NSDictionary dictionaryWithObjectsAndKeys:@"Synthetic contact",@"display_name",@"sample",@"username",@YES,@"is_online",nil]];
        TGBlockedSenderCell *blocked=[[[TGBlockedSenderCell alloc] initTextCell:@""] autorelease];[blocked setObjectValue:[NSDictionary dictionaryWithObjectsAndKeys:@"Synthetic sender",@"title",@"sample",@"username",nil]];
        TGChatFolderListCell *folder=[[[TGChatFolderListCell alloc] initTextCell:@""] autorelease];[folder setObjectValue:[NSDictionary dictionaryWithObjectsAndKeys:@"Synthetic folder",@"title",@YES,@"is_shareable",nil]];
        TGChatFolderChatCell *chat=[[[TGChatFolderChatCell alloc] initTextCell:@""] autorelease];[chat setObjectValue:[[[TGChatItem alloc] initWithChatID:@42 title:@"Synthetic chat" typeSummary:@"Private" unreadCount:@0] autorelease]];
        TGSavedMessagesCell *saved=[[[TGSavedMessagesCell alloc] initTextCell:@""] autorelease];[saved setObjectValue:[NSDictionary dictionaryWithObjectsAndKeys:@"Synthetic saved",@"title",@"File description",@"detail",nil]];
        for(NSCell *cell in [NSArray arrayWithObjects:contact,blocked,folder,chat,saved,nil]) {
          [cell setHighlighted:selected];NSBitmapImageRep *bitmap=Begin(360,50,flip,scale);
          if(cell==saved) [cell drawWithFrame:bounds inView:view];else [cell drawInteriorWithFrame:bounds inView:view];
          [NSGraphicsContext restoreGraphicsState];assert([Texts count]==2);
          NSColor *surface=[bitmap colorAtX:350*scale y:25*scale];
          assert(Same(surface,selected?TGListSelectionBackground():TGClassicTablePaperColor()));
          for(NSColor *ink in Inks) assert(TGThemeContrastRatio(ink,surface)>=4.49);
          if(aqua && selected) VerifyGlyphs(bitmap,flip,scale,50);
          rows++;
        }
        TGMessageItem *message=[[[TGMessageItem alloc] init] autorelease];message.dateSeparatorTitle=@"Today";
        NSBitmapImageRep *date=Begin(360,70,flip,scale);TGDrawMessageTopAccessories(message,NSMakeRect(0,0,360,70),flip);[NSGraphicsContext restoreGraphicsState];
        if(aqua) {VerifyGlyphs(date,flip,scale,70);assert(TGThemeContrastRatio([Inks objectAtIndex:0],TGListSelectionBackground())>=4.5);}dates++;
      }
      for(NSUInteger selected=0;selected<2;selected++) for(NSUInteger scale=1;scale<=2;scale++) {
        SearchSource *source=[[[SearchSource alloc] init] autorelease];source.result=[[[TGSearchResultItem alloc] init] autorelease];source.result.chatTitle=@"Synthetic search";source.result.snippet=@"Result detail";
        TGChatSearchResultsTableView *table=[[[TGChatSearchResultsTableView alloc] initWithFrame:NSMakeRect(0,0,360,60)] autorelease];[table setHeaderView:nil];[table setRowHeight:50];[table setIntercellSpacing:NSZeroSize];[table setDataSource:source];[table setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
        NSTableColumn *column=[[[NSTableColumn alloc] initWithIdentifier:@"result"] autorelease];[column setWidth:360];[column setDataCell:[[[TGChatSearchResultCell alloc] initTextCell:@""] autorelease]];[table addTableColumn:column];[table reloadData];
        if(selected) [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        NSBitmapImageRep *bitmap=Begin(360,60,YES,scale);[table drawRect:[table bounds]];[NSGraphicsContext restoreGraphicsState];
        if(aqua && selected) {assert(Same([bitmap colorAtX:335*scale y:25*scale],TGListSelectionBackground()));VerifyGlyphs(bitmap,YES,scale,60);}
        assert([Texts count]==2);searches++;
      }

    }
    printf("%s utility selection: %lu production row rasters, %lu actual search table rasters, %lu date pills; white glyphs/blue surfaces, 1x/2x, flipped/unflipped PASS.\n",aqua?"Aqua":"Classic",(unsigned long)rows,(unsigned long)searches,(unsigned long)dates);
    [pool drain];return 0;
}
'''.replace('__PRODUCTION__',production)
folder = tempfile.mkdtemp(prefix='telegraphica-list-selection-')
try:
    app=os.path.join(folder,'Probe.app');macos=os.path.join(app,'Contents','MacOS');resources=os.path.join(app,'Contents','Resources')
    os.makedirs(macos);os.makedirs(resources)
    shutil.copytree(os.path.join(ROOT,'Sources/Resources/Icons'),os.path.join(resources,'Icons'))
    source=os.path.join(folder,'selection.m');binary=os.path.join(macos,'selection')
    with open(source,'wb') as handle:handle.write(harness.encode('utf-8'))
    ui=os.path.join(ROOT,'Sources/UI');core=os.path.join(ROOT,'Sources/Core')
    dependencies=['Sources/Core/TGChatItem.m','Sources/Core/TGSearchResultItem.m','Sources/UI/TGSavedMessagesCell.m','Sources/UI/TGIconAssets.m','Sources/UI/TGLocalization.m','Sources/UI/TGTheme.m','Sources/UI/TGInterfaceDesign.m','Sources/UI/TGDialogPresentation.m','Sources/UI/TGAquaAppearance.m','Sources/UI/TGVisualWorldThemeSpec.m']
    subprocess.check_call(sys.argv[1:]+['-I'+ui,'-I'+core,source]+[os.path.join(ROOT,p) for p in dependencies]+['-framework','Cocoa','-o',binary])
    subprocess.check_call([binary,'aqua']);subprocess.check_call([binary,'classic'])
finally:
    shutil.rmtree(folder)
