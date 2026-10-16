#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Exercise the production sticker constructor, native presentation and send guards."""
from __future__ import print_function
import os, shutil, subprocess, sys, tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
def read(name):
    with open(os.path.join(ROOT,name),'rb') as handle:return handle.read().decode('utf-8')
source=read('Sources/UI/TGStatusWindowController+ComposerMedia.inc')
a=source.index('- (void)reloadStickerPickerItems {');load_method=source[a:source.index('- (void)reloadFavoriteStickerPickerItems',a)]
methods=[]
for first,last in [
 ('- (void)ensureStickerPickerWindow {','- (void)updateStickerPickerSelectionState'),
 ('- (void)rebuildStickerPickerGrid {','- (void)reloadStickerPickerItems {'),
 ('- (void)showStickerPicker:','- (void)sendStickerFromPickerButton:'),
 ('- (void)sendStickerFromPickerButton:','- (NSString *)temporaryVoiceRecordingPath')]:
    start=source.index(first);methods.append(source[start:source.index(last,start)])
specs=[('id','client'),('NSNumber *','profileUserID'),('NSNumber *','selectedChatID'),('NSNumber *','selectedMessageThreadID'),('NSString *','selectedMessageTopicKind'),('NSString *','activeSection'),('NSString *','currentAuthState'),('NSWindow *','hostWindow'),('NSView *','conversationPanelView'),('NSButton *','stickerButton'),('NSWindow *','stickerPickerWindow'),('NSScrollView *','stickerPickerScrollView'),('NSView *','stickerPickerContentView'),('NSButton *','stickerPickerRecentButton'),('NSButton *','stickerPickerFavoriteButton'),('NSSearchField *','stickerPickerSearchField'),('NSScrollView *','stickerPickerSetScrollView'),('NSView *','stickerPickerSetContentView'),('NSArray *','stickerPickerItems'),('NSArray *','stickerPickerStickerSets'),('NSMutableDictionary *','stickerPickerSetCache'),('NSMutableDictionary *','stickerPickerRailPreviewState'),('NSNumber *','stickerPickerSelectedSetID'),('NSTextField *','stickerPickerStatusField'),('id','stickerPickerPlaybackCoordinator'),('id','inlineMediaPlaybackCoordinator'),('id','stickerPickerGridThumbnailPrefetcher'),('id','stickerPickerRailThumbnailPrefetcher'),('NSUInteger','stickerPickerLoadGeneration'),('NSInteger','stickerPickerMode'),('BOOL','showingForumTopicList'),('BOOL','chatNavigationClosed'),('BOOL','forceMessageScrollToNewest'),('BOOL','pendingLiveChatRefresh'),('BOOL','pendingLiveMessageRefresh'),('NSTextField *','statusField')]
objects=lambda typ: '*' in typ or typ=='id'
fields='\n'.join('    %s _%s;'%(typ,name) for typ,name in specs)
properties='\n'.join('@property(nonatomic,%s) %s %s;'%('retain' if objects(typ) else 'assign',typ,name) for typ,name in specs)
synthesis='\n'.join('@synthesize %s=_%s;'%(name,name) for typ,name in specs)
release='\n'.join('    [_%s release];'%name for typ,name in specs if objects(typ))
harness=r'''
#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import "TGAquaShellViews.h"
#import "TGStatusViewCells.h"
#import "TGStickerPickerLayout.h"
#import "TGMessageThumbnailPrefetcher.h"
#include <assert.h>
#include <math.h>
static BOOL Aqua;
static NSString * const TGSectionChats=@"chats";
static NSMutableArray *Workers,*Mains;
static NSUInteger GridRebuilds,RecentLoads,SetLoads,Refreshes,Refocuses,DetailCount;
static BOOL Busy;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
BOOL TGInterfaceAnimationsEnabledForView(NSView *view) { (void)view;return NO; }
NSString *TGLoc(NSString *key) { return key; }
NSColor *TGClassicHeaderTextColor(CGFloat alpha) { return [NSColor colorWithCalibratedWhite:0 alpha:alpha]; }
NSColor *TGClassicCardInkColor(void) { return [NSColor blackColor]; }
NSImage *TGTemplateIconAssetImage(NSString *asset,NSSize size,NSColor *color,CGFloat alpha) { (void)asset;(void)size;(void)color;(void)alpha;return nil; }
NSNumber *TGMediaItemFullFileID(NSDictionary *item) { return [item objectForKey:@"file_id"]; }
NSString *TGMediaItemStickerFormat(NSDictionary *item) { (void)item;return @"webp"; }
NSString *TGMediaItemLocalPath(NSDictionary *item) { (void)item;return nil; }
NSImage *TGMediaCachedThumbnailFromFile(NSString *path,NSUInteger size) { (void)path;(void)size;return nil; }
BOOL TGStickerPickerItemNeedsLoadingIndicator(NSDictionary *item) { (void)item;return NO; }
NSButton *TGStickerPickerButtonWithFrame(NSRect frame,NSDictionary *item,NSInteger index,id target,SEL action) { (void)item;NSButton *button=[[[NSButton alloc] initWithFrame:frame] autorelease];[button setTag:index];[button setTarget:target];[button setAction:action];return button; }
static void ProbeDispatch(dispatch_queue_t queue,void (^block)(void)) { [(queue==dispatch_get_main_queue() ? Mains : Workers) addObject:[[block copy] autorelease]]; }
static void Flush(NSMutableArray *queue) { while([queue count]) {void (^block)(void)=[[[queue objectAtIndex:0] retain] autorelease];[queue removeObjectAtIndex:0];block();} }
#define dispatch_async ProbeDispatch
@interface TGLogger : NSObject
+ (id)sharedLogger;
- (void)log:(NSString *)text;
@end
@implementation TGLogger
+ (id)sharedLogger { static TGLogger *logger;if(!logger)logger=[[TGLogger alloc] init];return logger; }
- (void)log:(NSString *)text { (void)text; }
@end
@interface MockStickerClient : NSObject { @public NSUInteger sends;NSNumber *sentChat,*sentThread; }
@end
@implementation MockStickerClient
- (NSString *)sendStickerMessageToChatID:(NSNumber *)chat messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)topic stickerFileID:(NSNumber *)file emoji:(NSString *)emoji width:(NSNumber *)width height:(NSNumber *)height timeout:(NSTimeInterval)timeout error:(NSError **)error {
 (void)topic;(void)file;(void)emoji;(void)width;(void)height;(void)timeout;(void)error;sends++;[sentChat release];sentChat=[chat retain];[sentThread release];sentThread=[thread retain];return @"sent";
}
- (NSArray *)recentStickerItemsWithLimit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error { (void)limit;(void)timeout;(void)error;return [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@88 forKey:@"file_id"]]; }
- (void)dealloc { [sentChat release];[sentThread release];[super dealloc]; }
@end
@implementation TGMessageThumbnailPrefetcher
- (void)cancelAll {}
- (void)prefetchPath:(NSString *)path maximumPixelSize:(NSUInteger)size completion:(TGMessageThumbnailPrefetchCompletion)completion { (void)path;(void)size;(void)completion; }
@end
@implementation TGAquaMetalView
@synthesize dividerX=_dividerX;
@end
@implementation TGNavigationButtonCell
@synthesize badgeText=_badgeText,iconOnly=_iconOnly;
- (void)dealloc { [_badgeText release];[super dealloc]; }
@end
@implementation TGAquaTextButtonCell
@synthesize accented=_accented;
@end
@implementation TGAquaUtilityButtonCell
@synthesize iconAssetName=_iconAssetName;
- (void)dealloc { [_iconAssetName release];[super dealloc]; }
@end
@implementation TGStickerPickerBackgroundView
@end
@implementation TGStickerPickerPanelView
@end
@implementation TGStickerPickerTabButtonCell
@end
@implementation TGComposerInputBackgroundView
@end
@implementation TGStickerPickerLoadingView
- (void)startAnimation:(id)sender {(void)sender;}
@end
@interface TGStickerSetRailScrollView : NSScrollView
@end
@implementation TGStickerSetRailScrollView
@end
@interface StickerOwner : NSObject <NSWindowDelegate,NSPopoverDelegate> {
__FIELDS__
}
__PROPERTIES__
@end
#define TGStatusWindowController StickerOwner
#define TGTDLibClient MockStickerClient
@implementation StickerOwner
__SYNTHESIS__
- (NSWindow *)window { return self.hostWindow; }
- (NSTextField *)labelWithFrame:(NSRect)frame text:(NSString *)text font:(NSFont *)font { NSTextField *field=[[[NSTextField alloc] initWithFrame:frame] autorelease];[field setStringValue:text];[field setFont:font];return field; }
- (void)applyMutedLabelStyle:(id)view {(void)view;}
- (void)applyComposerTextFieldStyle:(id)view {(void)view;}
- (void)applyComposerPlaceholderStyle:(id)view {(void)view;}
- (void)installAquaTextCellOnButton:(NSButton *)button accented:(BOOL)accented { id target=[button target];SEL action=[button action];NSString *title=[[button title] copy];TGAquaTextButtonCell *cell=[[[TGAquaTextButtonCell alloc] initTextCell:title] autorelease];[cell setAccented:accented];[button setCell:cell];[button setTarget:target];[button setAction:action];[title release]; }
- (void)reloadStickerPickerSetsIfNeeded {SetLoads++;}
- (void)reloadStickerPickerItems {RecentLoads++;}
- (void)reloadStickerPickerItemsForSet:(id)set {(void)set;}
- (void)refreshStickerPickerPlayback {GridRebuilds++;}
- (void)updateStickerPickerSelectionState { [self.stickerPickerRecentButton setState:self.stickerPickerMode==0 ? NSOnState : NSOffState];[self.stickerPickerFavoriteButton setState:self.stickerPickerMode==1 ? NSOnState : NSOffState];[self updateAquaStickerPickerTabState]; }
- (void)selectRecentStickerPickerTab:(id)sender {(void)sender;self.stickerPickerMode=0;}
- (void)selectFavoriteStickerPickerTab:(id)sender {(void)sender;self.stickerPickerMode=1;}
- (void)selectStickerSetFromPickerButton:(id)sender {self.stickerPickerSelectedSetID=[[self.stickerPickerStickerSets objectAtIndex:[sender tag]] objectForKey:@"id"];self.stickerPickerMode=3;}
- (void)searchStickerPickerByEmoji:(id)sender {(void)sender;}
- (void)removeSelectedStickerSetFromPicker:(id)sender {(void)sender;}
- (void)scrollStickerPickerGridToTop {}
- (void)scheduleInlineMediaPlaybackRefresh {Refreshes++;}
- (void)appendDetail:(NSString *)text {(void)text;DetailCount++;}
- (void)setControlsBusy:(BOOL)busy {Busy=busy;}
- (void)handlePendingLiveRefreshesIfPossible {}
- (void)requestComposerRefocus {Refocuses++;}
#include "TGStatusWindowController+StickerPresentation.inc"
__METHODS__
- (void)dealloc { [self disposeAquaStickerPicker];[[NSNotificationCenter defaultCenter] removeObserver:self];[_stickerPickerWindow setDelegate:nil];[_stickerPickerWindow close];[_hostWindow close];
__RELEASE__
 [super dealloc]; }
@end
@interface StickerLoadOwner : StickerOwner
@end
@implementation StickerLoadOwner
__LOAD_METHOD__
@end
static StickerOwner *Owner(Class ownerClass) {
 StickerOwner *owner=[[[ownerClass alloc] init] autorelease];owner.client=[[[MockStickerClient alloc] init] autorelease];owner.profileUserID=@1;owner.selectedChatID=@7;owner.selectedMessageThreadID=@11;owner.activeSection=TGSectionChats;owner.currentAuthState=@"ready";
 NSRect visible=[[NSScreen mainScreen] visibleFrame];owner.hostWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(NSMinX(visible)+30,NSMinY(visible)+30,760,620) styleMask:NSTitledWindowMask|NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[owner.hostWindow setReleasedWhenClosed:NO];
 owner.conversationPanelView=[[[NSView alloc] initWithFrame:NSMakeRect(240,0,520,570)] autorelease];[[owner.hostWindow contentView] addSubview:owner.conversationPanelView];
 owner.stickerButton=[[[NSButton alloc] initWithFrame:NSMakeRect(650,12,36,30)] autorelease];[[owner.hostWindow contentView] addSubview:owner.stickerButton];[owner.stickerButton setEnabled:YES];
 owner.statusField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];[owner.hostWindow orderFront:nil];return owner;
}
static NSDictionary *Sticker(void) {return [NSDictionary dictionaryWithObjectsAndKeys:@88,@"file_id",@"test",@"emoji",nil];}
static NSPopover *Popover(StickerOwner *owner) {return [[owner aquaStickerPresentationState] objectForKey:@"popover"];}
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];[NSApp activateIgnoringOtherApps:YES];Workers=[[NSMutableArray alloc] init];Mains=[[NSMutableArray alloc] init];NSUInteger checks=0,geometries=0;
 for(CGFloat width=280;width<=760;width+=20)for(CGFloat height=310;height<=760;height+=30)for(CGFloat above=240;above<=720;above+=40) {
  NSSize size=TGAquaStickerPopoverSize(NSMakeSize(width,height),NSMakeSize(1280,800),above);
  if(!NSEqualSizes(size,NSZeroSize)){assert(size.width<=430 && size.width<=width-16 && size.height<=330 && size.height<=height-70 && size.height<=above-24);checks++;}geometries++;
 }
 Aqua=NO;StickerOwner *classic=Owner([StickerOwner class]);[classic showStickerPicker:nil];assert([classic.stickerPickerWindow isVisible] && ![classic aquaStickerPresentationState]);checks++;[classic.stickerPickerWindow orderOut:nil];[classic.hostWindow orderOut:nil];
 Aqua=YES;StickerOwner *owner=Owner([StickerOwner class]);[owner showStickerPicker:nil];assert([Popover(owner) isShown] && ![owner.stickerPickerWindow isVisible]);checks++;
 assert([owner.stickerPickerRecentButton target]==owner && [owner.stickerPickerRecentButton action]==@selector(selectRecentStickerPickerTab:) && [owner.stickerPickerFavoriteButton action]==@selector(selectFavoriteStickerPickerTab:) && [owner.stickerPickerSearchField action]==@selector(searchStickerPickerByEmoji:));checks++;
 assert([Popover(owner) behavior]==NSPopoverBehaviorTransient && [Popover(owner) contentSize].width<=430);checks++;
 [owner popoverDidClose:[NSNotification notificationWithName:NSPopoverDidCloseNotification object:Popover(owner)]];assert([owner aquaStickerPickerCanSend]);checks++;
 NSDictionary *context=[[owner stickerPickerLoadContext] retain];assert([owner stickerPickerLoadContextIsCurrent:context]);checks++;
 [owner showStickerPicker:nil];assert(![Popover(owner) isShown] && ![owner stickerPickerLoadContextIsCurrent:context]);checks++;[context release];
 owner.stickerPickerItems=[NSArray arrayWithObjects:Sticker(),Sticker(),Sticker(),Sticker(),Sticker(),nil];[owner showStickerPicker:nil];
 assert([[owner.stickerPickerContentView subviews] count]==5);checks++;
 for(NSSize size={300,280};size.width<=430;size.width+=130) {
  [owner layoutAquaStickerPickerForSize:size];[owner rebuildStickerPickerGrid];NSRect host=[[[owner aquaStickerPresentationState] objectForKey:@"view"] bounds];
  assert(NSContainsRect(host,[owner.stickerPickerSearchField frame]) && NSContainsRect(host,[owner.stickerPickerRecentButton frame]) && NSContainsRect(host,[owner.stickerPickerFavoriteButton frame]));checks++;
  NSRect viewport=[[owner.stickerPickerScrollView contentView] bounds];
  for(NSButton *button in [owner.stickerPickerContentView subviews]){assert(NSMinX([button frame])>=0 && NSMaxX([button frame])<=NSWidth(viewport));checks++;}
 }
 [owner closeAquaStickerPicker];[owner showStickerPicker:nil];context=[[owner stickerPickerLoadContext] retain];owner.selectedMessageThreadID=@12;assert(![owner aquaStickerPickerCanSend] && ![owner stickerPickerLoadContextIsCurrent:context]);checks++;owner.selectedMessageThreadID=@11;[owner closeAquaStickerPicker];[context release];
 NSArray *events=[NSArray arrayWithObjects:NSWindowDidResizeNotification,NSWindowDidMoveNotification,NSWindowWillCloseNotification,NSWindowWillMiniaturizeNotification,NSWindowWillEnterFullScreenNotification,NSWindowDidChangeScreenNotification,nil];
 for(NSString *event in events) {[owner showStickerPicker:nil];assert([Popover(owner) isShown]);[[NSNotificationCenter defaultCenter] postNotificationName:event object:owner.hostWindow];assert(![Popover(owner) isShown]);checks++;}
 [owner showStickerPicker:nil];[owner selectInstalledStickerPickerTab:nil];assert(owner.stickerPickerMode==3 && [[[owner aquaStickerPresentationState] objectForKey:@"wants_sets"] boolValue]);checks++;
 [owner finishAquaStickerSetLoad];assert([[owner.stickerPickerStatusField stringValue] isEqual:TGLoc(@"stickers.sets.empty")]);checks++;
 [owner closeAquaStickerPicker];
 owner.stickerPickerStickerSets=[NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@9 forKey:@"id"]];[owner showStickerPicker:nil];[owner selectInstalledStickerPickerTab:nil];assert(owner.stickerPickerMode==3 && [owner.stickerPickerSelectedSetID isEqual:@9]);checks++;
 owner.stickerPickerItems=[NSArray arrayWithObject:Sticker()];[owner rebuildStickerPickerGrid];NSButton *tile=[[owner.stickerPickerContentView subviews] objectAtIndex:0];[owner sendStickerFromPickerButton:tile];assert(![Popover(owner) isShown] && [Workers count]==1);checks++;
 MockStickerClient *client=owner.client;Flush(Workers);assert(client->sends==1 && [client->sentChat isEqual:@7] && [client->sentThread isEqual:@11]);checks++;Flush(Mains);assert(!Busy && Refocuses==1);checks++;
 [owner sendStickerFromPickerButton:tile];assert([Workers count]==0 && client->sends==1);checks++;
 [owner showStickerPicker:nil];[owner rebuildStickerPickerGrid];tile=[[owner.stickerPickerContentView subviews] objectAtIndex:0];[owner sendStickerFromPickerButton:tile];Flush(Workers);NSString *status=[[owner.statusField stringValue] copy];owner.profileUserID=@2;Flush(Mains);assert([[owner.statusField stringValue] isEqual:status] && Refocuses==1);[status release];checks++;
 [owner invalidateStickerPickerPresentation];assert([owner.stickerPickerItems count]==0 && [owner.stickerPickerStickerSets count]==0 && !owner.stickerPickerSelectedSetID);checks++;
 [owner disposeAquaStickerPicker];assert(![owner aquaStickerPresentationState]);checks++;[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResizeNotification object:owner.hostWindow];
 StickerOwner *pending=Owner([StickerLoadOwner class]);[pending showStickerPicker:nil];assert([Workers count]==1);[pending closeAquaStickerPicker];[pending showStickerPicker:nil];assert([Workers count]==2);checks++;
 void (^oldLoad)(void)=[[[Workers objectAtIndex:0] retain] autorelease];[Workers removeObjectAtIndex:0];oldLoad();Flush(Mains);assert([pending.stickerPickerItems count]==0);checks++;
 Flush(Workers);Flush(Mains);assert([pending.stickerPickerItems count]==1);checks++;
 pending.stickerPickerItems=[NSArray array];[pending reloadStickerPickerItems];pending.profileUserID=@22;Flush(Workers);Flush(Mains);assert([pending.stickerPickerItems count]==0);checks++;
 [pending closeAquaStickerPicker];[pending.hostWindow orderOut:nil];
 [owner.hostWindow orderOut:nil];[Workers release];[Mains release];printf("PASS: %lu sticker popover geometry matrices / %lu production constructor, native show/close/context/grid/send checks; Classic retained\n",(unsigned long)geometries,(unsigned long)checks);[pool drain];return 0;
}
'''
for token,value in [('__FIELDS__',fields),('__PROPERTIES__',properties),('__SYNTHESIS__',synthesis),('__RELEASE__',release),('__METHODS__','\n'.join(methods)),('__LOAD_METHOD__',load_method)]:harness=harness.replace(token,value)
folder=tempfile.mkdtemp(prefix='telegraphica-sticker-popover-')
try:
    path=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(path,'wb') as handle:handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+[path,'-I'+os.path.join(ROOT,'Sources/UI'),'-I'+os.path.join(ROOT,'Sources/Media'),'-framework','Cocoa','-o',binary])
    subprocess.check_call([binary])
finally:shutil.rmtree(folder)
