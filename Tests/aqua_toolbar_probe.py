#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Production Aqua toolbar cells, responsive geometry and native accessory actions."""
from __future__ import print_function, unicode_literals
import os, shutil, subprocess, sys, tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
def read(path):
 with open(os.path.join(ROOT,path),'rb') as f:return f.read().decode('utf-8')
views=read('Sources/UI/TGAquaShellViews.m')
a=views.index('NSRect TGAquaToolbarItemIconFrame(');b=views.index('@implementation TGAquaTextButtonCell',a)
cell=views[a:b]
shell=read('Sources/UI/TGStatusWindowController+AquaShell.inc')
a=shell.index('- (void)installAquaToolbarCellOnButton:');b=shell.index('- (void)configureInterfaceDesignControls',a)
accessories=shell[a:b]
harness=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGAquaShellViews.h"
#import "TGAquaAppearance.h"
#import "TGIconAssets.h"
#import "TGLocalization.h"
#import "TGTheme.h"
#include <math.h>
static NSUInteger Checks;
static void Check(BOOL condition,const char *message) { Checks++;if(!condition) {fprintf(stderr,"Aqua toolbar: %s\n",message);exit(1);} }
NSColor *TGColorFromHex(NSUInteger hex) {return [NSColor colorWithCalibratedRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1];}
@implementation TGNavigationButtonCell
@synthesize badgeText=_badgeText,iconOnly=_iconOnly;
- (void)dealloc {[_badgeText release];[super dealloc];}
@end
@implementation TGAquaUtilityButtonCell
@synthesize iconAssetName=_iconAssetName;
- (void)dealloc {[_iconAssetName release];[super dealloc];}
@end
__CELL__
@interface PreviewMetalView : NSView
@end
@implementation PreviewMetalView
- (void)drawRect:(NSRect)dirty {(void)dirty;NSRect rect=[self bounds];TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:rect],rect,TGThemeSurfaceHeader,[self isFlipped]);}
@end
@interface FlipView : NSView {BOOL _flipped;}
@property(nonatomic) BOOL flipped;
@end
@implementation FlipView
@synthesize flipped=_flipped;
- (BOOL)isFlipped {return _flipped;}
@end
@interface Badge : NSObject {NSString *_displayName;}
@property(nonatomic,copy) NSString *displayName;
@end
@implementation Badge
@synthesize displayName=_displayName;
- (void)dealloc {[_displayName release];[super dealloc];}
@end
@interface TGChatSearchPanelView : NSObject {NSString *_query;NSSearchField *_searchField;}
@property(nonatomic,copy) NSString *query;
@property(nonatomic,retain) NSSearchField *searchField;
@end
@implementation TGChatSearchPanelView
@synthesize query=_query,searchField=_searchField;
- (void)setQuery:(NSString *)query {[_query release];_query=[query copy];[_searchField setStringValue:query];}
- (void)dealloc {[_query release];[_searchField release];[super dealloc];}
@end
@interface ToolbarProbe : NSObject {
 NSView *_aquaToolbarView;Badge *_accountBadgeView;NSString *_profileFirstName,*_currentAuthState;
 NSWindow *_chatSearchWindow;TGChatSearchPanelView *_panel;NSUInteger _opened,_updated,_profileActions,_settingsActions;
}
@property(nonatomic,retain) NSView *aquaToolbarView;
@property(nonatomic,retain) Badge *accountBadgeView;
@property(nonatomic,copy) NSString *profileFirstName,*currentAuthState;
@property(nonatomic,retain) NSWindow *chatSearchWindow;
@property(nonatomic,retain) TGChatSearchPanelView *panel;
@property(nonatomic) NSUInteger opened,updated,profileActions,settingsActions;
@end
@implementation ToolbarProbe
@synthesize aquaToolbarView=_aquaToolbarView,accountBadgeView=_accountBadgeView,profileFirstName=_profileFirstName,currentAuthState=_currentAuthState,chatSearchWindow=_chatSearchWindow,panel=_panel,opened=_opened,updated=_updated,profileActions=_profileActions,settingsActions=_settingsActions;
- (void)dealloc {[_aquaToolbarView release];[_accountBadgeView release];[_profileFirstName release];[_currentAuthState release];[_chatSearchWindow release];[_panel release];[super dealloc];}
- (void)openProfileFromDrawer:(id)sender {(void)sender;self.profileActions++;}
- (void)navigationChanged:(id)sender {if([sender tag]==3) self.settingsActions++;}
- (void)openChatSearchWindow:(id)sender {(void)sender;self.opened++;[self.panel setQuery:@""];}
- (TGChatSearchPanelView *)chatSearchPanelView {return self.panel;}
- (void)updateChatSearchWindowResults {self.updated++;}
__ACCESSORIES__
@end
static NSBitmapImageRep *Bitmap(NSUInteger w,NSUInteger h) {return [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];}
static NSBitmapImageRep *Render(TGAquaToolbarItemCell *cell,BOOL flipped) {
 NSBitmapImageRep *bitmap=Bitmap(90,72);FlipView *view=[[[FlipView alloc] initWithFrame:NSMakeRect(0,0,90,72)] autorelease];view.flipped=flipped;
 [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
 [cell drawWithFrame:NSMakeRect(10,10,70,52) inView:view];[NSGraphicsContext restoreGraphicsState];return bitmap;
}
static BOOL SamePixel(NSBitmapImageRep *a,NSBitmapImageRep *b,NSUInteger x,NSUInteger y) {const unsigned char *left=[a bitmapData]+y*[a bytesPerRow]+4*x,*right=[b bitmapData]+y*[b bytesPerRow]+4*x;return memcmp(left,right,4)==0;}
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 NSArray *assets=[NSArray arrayWithObjects:@"chat",@"contacts",@"call-receive",@"workshop",@"settings",@"arrow-down",nil];
 NSArray *keys=[NSArray arrayWithObjects:@"chats",@"contacts",@"calls",@"workshop.title",@"settings",@"downloads.short",nil];
 for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
  TGSetLanguageCode(language);
  for(NSUInteger width=760;width<=980;width+=220) {
   TGAquaToolbarGeometry g=TGAquaToolbarFrames(width,700);Check(NSMaxX(g.account)<NSMinX(g.sections[0]) && NSMaxX(g.sections[4])+12<=NSMinX(g.search) && NSMaxX(g.search)+12<=NSMinX(g.downloads),"account, five sections, native search and downloads never overlap at760/980");
   for(NSUInteger i=0;i<6;i++) {
    CGFloat available=(i<5 ? NSWidth(g.sections[i]):NSWidth(g.downloads))-4;
    CGFloat needed=[TGLoc([keys objectAtIndex:i]) sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName]].width;
    Check(needed<=available,"all localized captions fit without hiding actions");
   }
  }
  for(NSUInteger i=0;i<[assets count];i++) for(NSUInteger flip=0;flip<2;flip++) for(NSUInteger selected=0;selected<2;selected++) {
   Check(TGIconAssetImageNamed([assets objectAtIndex:i])!=nil,"approved icon exists in real bundle");
   TGAquaToolbarItemCell *cell=[[[TGAquaToolbarItemCell alloc] initTextCell:TGLoc([keys objectAtIndex:i])] autorelease];cell.iconAssetName=[assets objectAtIndex:i];[cell setButtonType:NSToggleButton];[cell setState:selected?NSOnState:NSOffState];
   NSRect frame=NSMakeRect(10,10,70,52),icon=TGAquaToolbarItemIconFrame(frame,flip),label=TGAquaToolbarItemLabelFrame(frame,flip);
   Check(!NSIntersectsRect(icon,label) && NSContainsRect(frame,icon) && NSContainsRect(frame,label),"icon above caption has separate, contained geometry in both coordinate systems");
   NSBitmapImageRep *idle=Render(cell,flip);Check([[idle colorAtX:11 y:11] alphaComponent]<0.01 && [[idle colorAtX:78 y:60] alphaComponent]<0.01,"selected and idle items never paint old square bezels");
   for(NSString *badge in [NSArray arrayWithObjects:@"7",@"12345",nil]) {
    cell.badgeText=badge;NSBitmapImageRep *withBadge=Render(cell,flip);NSRect excluded=NSInsetRect(TGAquaToolbarItemBadgeFrame(frame,28,flip),-1,-1);excluded.origin.y=72-NSMaxY(excluded);NSUInteger sampled=0;
    for(NSUInteger y=15;y<57;y++) for(NSUInteger x=28;x<61;x++) if(!NSPointInRect(NSMakePoint(x,y),excluded)) {Check(SamePixel(idle,withBadge,x,y),"badge overlay never shifts icon or caption raster");sampled++;}
    Check(sampled>300,"static badge comparison covers actual icon footprint");
   }
  }
 }
 ToolbarProbe *owner=[[[ToolbarProbe alloc] init] autorelease];owner.aquaToolbarView=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,980,64)] autorelease];owner.accountBadgeView=[[[Badge alloc] init] autorelease];owner.accountBadgeView.displayName=@"Длинное имя профиля для проверки ширины";owner.profileFirstName=@"Юрий";owner.currentAuthState=@"ready";
 owner.chatSearchWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,400,200) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[owner.chatSearchWindow setReleasedWhenClosed:NO];owner.panel=[[[TGChatSearchPanelView alloc] init] autorelease];owner.panel.searchField=[[[NSSearchField alloc] initWithFrame:NSMakeRect(0,0,300,26)] autorelease];[[owner.chatSearchWindow contentView] addSubview:owner.panel.searchField];
 [owner configureAquaToolbarAccessories];NSPopUpButton *account=[owner aquaToolbarAccountButton];NSSearchField *search=[owner aquaToolbarSearchField];
 Check([[account title] isEqual:@"Юрий"] && [[account toolTip] rangeOfString:owner.accountBadgeView.displayName].location!=NSNotFound,"short account caption keeps full profile name in tooltip");
 Check([[account itemAtIndex:1] action]==@selector(openProfileFromDrawer:) && [[account itemAtIndex:2] action]==@selector(navigationChanged:) && [[account itemAtIndex:2] tag]==3,"native dropdown reuses existing Profile and Settings actions");
 for(NSUInteger i=1;i<=2;i++) {NSMenuItem *item=[account itemAtIndex:i];[[item target] performSelector:[item action] withObject:item];}
 Check(owner.profileActions==1 && owner.settingsActions==1,"dropdown action routing preserves profile/settings identities");
 Check([[search cell] sendsWholeSearchString] && ![[search cell] sendsSearchStringImmediately],"native toolbar search submits whole query instead of sending every keystroke");
 [search setStringValue:@"  сохранённый запрос  "];[search sendAction:[search action] to:[search target]];
 Check(owner.opened==1 && owner.updated==1 && [[owner.panel query] isEqual:@"сохранённый запрос"] && [[search stringValue] length]==0,"Return seeds existing chat-search backend with trimmed query and resets toolbar input");
 [search sendAction:[search action] to:[search target]];Check(owner.opened==1,"native clear with empty query never reopens search");
 owner.currentAuthState=@"waitCode";[search setStringValue:@"private query"];[search sendAction:[search action] to:[search target]];Check(owner.opened==1,"toolbar search cannot start before authorization");
 NSButton *button=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[button setTarget:owner];[button setAction:@selector(openProfileFromDrawer:)];[button setTag:92];[button setTitle:@"Profile"];[button setState:NSOnState];[owner installAquaToolbarCellOnButton:button asset:@"contacts" toggle:YES];
 Check([button target]==owner && [button action]==@selector(openProfileFromDrawer:) && [button tag]==92 && [button state]==NSOnState && [[button cell] isKindOfClass:[TGAquaToolbarItemCell class]],"toolbar presentation preserves native action/tag/selected state");
 [owner installAquaToolbarCellOnButton:button asset:@"arrow-down" toggle:NO];[button performClick:nil];Check([(NSButtonCell *)[button cell] showsStateBy]==0 && ![[button cell] isHighlighted],"momentary downloads-style action never becomes selected tab");
 for(NSUInteger i=0;i<[assets count];i++) {
  [button setTitle:TGLoc([keys objectAtIndex:i])];[owner installAquaToolbarCellOnButton:button asset:[assets objectAtIndex:i] toggle:YES];
  TGAquaToolbarItemCell *actual=(TGAquaToolbarItemCell *)[button cell];Check([actual usesOriginalIconColors] && [actual image]!=nil,"all six bundled Oxygen originals resolve through nested resource paths");
  [actual setState:NSOffState];NSBitmapImageRep *idle=Render(actual,NO);[actual setState:NSOnState];NSBitmapImageRep *selected=Render(actual,NO);
  NSRect pixels=TGAquaToolbarItemIconFrame(NSMakeRect(10,10,70,52),NO);NSMutableSet *colors=[NSMutableSet set];NSUInteger covered=0;
  for(NSUInteger y=72-NSMaxY(pixels);y<72-NSMinY(pixels);y++) for(NSUInteger x=NSMinX(pixels);x<NSMaxX(pixels);x++) {
   Check(SamePixel(idle,selected,x,y),"Oxygen original RGB and shading are preserved when selected");
   const unsigned char *pixel=[idle bitmapData]+y*[idle bytesPerRow]+4*x;
   if(pixel[3]>200) {[colors addObject:[NSNumber numberWithUnsignedLong:((NSUInteger)pixel[0]<<16)|((NSUInteger)pixel[1]<<8)|pixel[2]]];covered++;}
  }
  Check(covered>60 && [colors count]>16,"full-color toolbar retains source shading rather than flattening artwork");
  NSUInteger blue=0;for(NSUInteger y=45;y<60;y++) for(NSUInteger x=12;x<78;x++) {const unsigned char *pixel=[selected bitmapData]+y*[selected bytesPerRow]+4*x;if(pixel[3]>100 && pixel[2]>pixel[0]+20 && pixel[2]>pixel[1]+10) blue++;}
  Check(blue>5,"active caption is blue while original icon artwork remains untouched");
 }
 TGAquaToolbarItemCell *original=[[[TGAquaToolbarItemCell alloc] initTextCell:@"Native"] autorelease];original.usesOriginalIconColors=YES;[original setImage:[NSImage imageNamed:NSImageNameComputer]];[original setButtonType:NSToggleButton];
 NSBitmapImageRep *off=Render(original,NO);[original setState:NSOnState];NSBitmapImageRep *on=Render(original,NO);NSRect icon=TGAquaToolbarItemIconFrame(NSMakeRect(10,10,70,52),NO);
 for(NSUInteger y=72-NSMaxY(icon);y<72-NSMinY(icon);y++) for(NSUInteger x=NSMinX(icon);x<NSMaxX(icon);x++) Check(SamePixel(off,on,x,y),"full-color approved native artwork is preserved across state changes");
 const char *preview=getenv("TELEGRAPHICA_TOOLBAR_PREVIEW_DIR");
 if(preview) {
  NSString *directory=[NSString stringWithUTF8String:preview];[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];owner.profileFirstName=@"Иван";owner.currentAuthState=@"ready";[search setStringValue:@""];
  for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) for(NSUInteger width=760;width<=980;width+=220) {
   TGSetLanguageCode(language);[owner refreshAquaToolbarAccount];NSRect bounds=NSMakeRect(0,0,width,64);TGAquaToolbarGeometry g=TGAquaToolbarFrames(width,64);
   NSWindow *previewWindow=[[[NSWindow alloc] initWithContentRect:bounds styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[previewWindow setReleasedWhenClosed:NO];
   PreviewMetalView *root=[[[PreviewMetalView alloc] initWithFrame:bounds] autorelease];[previewWindow setContentView:root];
   NSImageView *avatar=[[[NSImageView alloc] initWithFrame:g.avatar] autorelease];[avatar setImage:[NSImage imageNamed:NSImageNameUser]];[root addSubview:avatar];
   NSRect accountRect=g.account;accountRect.size.width=MIN(NSWidth(accountRect),MAX(54,ceil([[account title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[account font] forKey:NSFontAttributeName]].width)+28));
   [account removeFromSuperview];[search removeFromSuperview];[account setFrame:accountRect];[search setFrame:g.search];[root addSubview:account];[root addSubview:search];
   for(NSUInteger i=0;i<6;i++) {
    NSButton *item=[[[NSButton alloc] initWithFrame:i<5 ? g.sections[i] : g.downloads] autorelease];
    [item setTitle:TGLoc([keys objectAtIndex:i])];[owner installAquaToolbarCellOnButton:item asset:[assets objectAtIndex:i] toggle:i<5];[item setState:i==0 ? NSOnState:NSOffState];
    [(TGAquaToolbarItemCell *)[item cell] setBadgeText:i==0 ? @"7" : nil];[root addSubview:item];
   }
   [previewWindow display];NSBitmapImageRep *bar=[root bitmapImageRepForCachingDisplayInRect:bounds];[root cacheDisplayInRect:bounds toBitmapImageRep:bar];
   NSString *file=[directory stringByAppendingPathComponent:[NSString stringWithFormat:@"aqua-toolbar-%@-%lu.png",language,(unsigned long)width]];
   [[bar representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:file atomically:YES];
  }
 }
 printf("Aqua toolbar PASS: %lu real-asset raster, localization, geometry, native dropdown/search and action checks.\n",(unsigned long)Checks);[pool drain];return 0;
}
'''
harness=harness.replace('__CELL__',cell).replace('__ACCESSORIES__',accessories)
folder=tempfile.mkdtemp(prefix='telegraphica-aqua-toolbar-')
try:
 app=os.path.join(folder,'Probe.app');contents=os.path.join(app,'Contents');os.makedirs(os.path.join(contents,'MacOS'));os.makedirs(os.path.join(contents,'Resources'));path=os.path.join(folder,'probe.m');binary=os.path.join(contents,'MacOS','probe')
 shutil.copytree(os.path.join(ROOT,'Sources/Resources/Icons'),os.path.join(contents,'Resources/Icons'))
 shutil.copytree(os.path.join(ROOT,'Sources/Resources/Textures'),os.path.join(contents,'Resources/Textures'))
 with open(os.path.join(contents,'Info.plist'),'w') as f:f.write('<?xml version="1.0"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>probe</string><key>CFBundleIdentifier</key><string>local.telegraphica.toolbar-probe</string></dict></plist>')
 with open(path,'wb') as f:f.write(harness.encode('utf-8'))
 deps=['Sources/UI/TGAquaShellLayout.m','Sources/UI/TGIconAssets.m','Sources/UI/TGLocalization.m','Sources/UI/TGAquaAppearance.m']
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),path]+[os.path.join(ROOT,p) for p in deps]+['-framework','Cocoa','-o',binary]);subprocess.check_call([binary])
finally:shutil.rmtree(folder)
