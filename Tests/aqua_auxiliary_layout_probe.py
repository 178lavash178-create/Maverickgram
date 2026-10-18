#!/usr/bin/env python
"""Exercise production search-panel and contact footer geometry without TDLib."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
def read(path):
    with open(os.path.join(ROOT,path),'rb') as handle:
        return handle.read().decode('utf-8')
contacts=read('Sources/UI/TGContactsViewController.m')
start=contacts.index('- (void)layoutContent {')
layout=contacts[start:contacts.index('\n- (void)setView:',start)]
cells=read('Sources/UI/TGStatusViewCells.m')
start=cells.index('@implementation TGRepresentedObjectCell\n')
cell=cells[start:cells.index('\n@end',start)+len('\n@end')]
properties=['titleField','createChatButton','refreshButton','searchField','profileView','listCardView','scrollView','tableView','statusField','spinner','openButton','actionButton']
types=['NSTextField','NSButton','NSButton','NSSearchField','NSView','NSView','NSScrollView','NSTableView','NSTextField','NSProgressIndicator','NSButton','NSButton']
interface='@interface ContactLayoutProbe : NSViewController\n'+''.join('@property(nonatomic,retain) %s *%s;\n'%(t,p) for t,p in zip(types,properties))+'@end\n@implementation ContactLayoutProbe\n'+''.join('@synthesize %s=_%s;\n'%(p,p) for p in properties)+layout+'\n@end\n'
app=read('Sources/AppDelegate.m')
a=app.index('- (void)buildMainMenu {');b=app.index('\n- (void)dealloc',a)
menu='@interface MenuProbe : NSObject\n@end\n@implementation MenuProbe\n'+app[a:b]+'\n@end\n'
chat_search=read('Sources/UI/TGStatusWindowController+ChatSearchWindow.inc')
a=chat_search.index('- (void)closeChatSearchWindow:');b=chat_search.index('\n- (void)clearChatSearch',a)
close_search='@interface SearchCloseProbe : NSObject\n@property(nonatomic,retain) NSWindow *chatSearchWindow,*mainWindow;\n@property(nonatomic,retain) NSTextField *sendTextField;\n@property(nonatomic) NSUInteger chatSearchGeneration;\n@end\n@implementation SearchCloseProbe\n@synthesize chatSearchWindow,mainWindow,sendTextField,chatSearchGeneration;\n- (NSWindow *)window { return self.mainWindow; }\n- (NSDictionary *)aquaChatSearchState { return nil; }\n- (void)invalidateAquaChatSearchPresentation {}\n'+chat_search[a:b]+'\n@end\n'

presentation=r"""
static NSString * const TGSectionChats=@"chats";
BOOL TGInterfaceAnimationsEnabledForView(NSView *view) { (void)view;return NO; }
@interface SearchPresentationProbe : NSObject <NSPopoverDelegate,NSWindowDelegate>
@property(nonatomic,retain) NSWindow *mainWindow,*chatSearchWindow;
@property(nonatomic,retain) NSView *anchor;
@property(nonatomic,retain) TGChatSearchPanelView *panel;
@property(nonatomic,retain) id client,profileUserID;
@property(nonatomic,copy) NSString *currentAuthState,*activeSection;
@property(nonatomic) NSUInteger chatSearchGeneration,resizeCount;
@end
@implementation SearchPresentationProbe
@synthesize mainWindow,chatSearchWindow,anchor,panel,client,profileUserID,currentAuthState,activeSection,chatSearchGeneration,resizeCount;
- (NSWindow *)window {return self.mainWindow;}
- (NSView *)aquaToolbarSearchField {return self.anchor;}
- (TGChatSearchPanelView *)chatSearchPanelView {return self.panel;}
- (void)openFromAnchor:(id)sender {(void)sender;[self showAquaChatSearchPanel];}
- (void)windowDidResize:(NSNotification *)note {(void)note;self.resizeCount++;}
- (void)popoverDidClose:(NSNotification *)note {(void)note;[self finishAquaChatSearchDismissal];}
__PRESENTATION_METHODS__
@end
static void CheckSearchPresentation(void) {
 SearchPresentationProbe *p=[[[SearchPresentationProbe alloc] init] autorelease];
 p.mainWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(200,200,760,600) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[p.mainWindow setReleasedWhenClosed:NO];[p.mainWindow setDelegate:p];
 p.anchor=[[[TGAquaSearchAnchorField alloc] initWithFrame:NSMakeRect(440,550,240,26)] autorelease];[[p.mainWindow contentView] addSubview:p.anchor];[(NSControl *)p.anchor setTarget:p];[(NSControl *)p.anchor setAction:@selector(openFromAnchor:)];
 p.chatSearchWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,460,340) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[p.chatSearchWindow setReleasedWhenClosed:NO];
 p.panel=[[[TGChatSearchPanelView alloc] initWithFrame:NSMakeRect(0,0,460,340)] autorelease];[p.chatSearchWindow setContentView:p.panel];
 p.client=[[[NSObject alloc] init] autorelease];p.profileUserID=@17;p.activeSection=@"chats";p.currentAuthState=@"ready";
 [p.mainWindow makeKeyAndOrderFront:nil];
 for(NSUInteger cycle=0;cycle<8;cycle++) {
  if(cycle==0) [p.anchor mouseDown:nil];
  Require([p showAquaChatSearchPanel],"Aqua opens real anchored popover on toolbar click");
  NSPopover *popover=[[p aquaChatSearchState] objectForKey:@"popover"];
  Require([popover isShown] && ![p.chatSearchWindow isVisible] && [p.panel window]!=p.chatSearchWindow,"same results panel is hosted only by the popover");
  Require([[p.panel searchField] currentEditor]!=nil,"opening focuses editable query inside popover");
  NSDictionary *context=[[[p aquaChatSearchState] objectForKey:@"context"] retain];
  Require([p aquaChatSearchContextIsCurrent:context],"current request context accepted");
  p.panel.query=@"preserve query";NSUInteger generation=p.chatSearchGeneration;
  Require([p showAquaChatSearchPanel] && [p.panel.query isEqual:@"preserve query"] && p.chatSearchGeneration==generation,"repeated opening preserves query and generation");
  if(cycle==0) {p.profileUserID=@18;Require(![p aquaChatSearchContextIsCurrent:context],"account swap invalidates async search");p.profileUserID=@17;p.client=[[[NSObject alloc] init] autorelease];Require(![p aquaChatSearchContextIsCurrent:context],"client replacement invalidates async search");}
  if(cycle==1) {p.activeSection=@"settings";Require(![p aquaChatSearchContextIsCurrent:context],"section change invalidates async search");p.activeSection=@"chats";}
  NSUInteger before=p.resizeCount;[p.mainWindow setContentSize:NSMakeSize(780+cycle,600)];
  Require(![popover isShown] && ![[p aquaChatSearchState] objectForKey:@"context"] && p.chatSearchGeneration==generation+1,"resize closes search and invalidates asynchronous results exactly once");
  Require(p.resizeCount>before,"search observer disposal preserves main window delegate resize");
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
  Require(![popover isShown],"restoring anchor focus after dismissal never reopens search");
  Require(![p aquaChatSearchContextIsCurrent:context],"dismissed request context stays invalid");[context release];
 }
 NSScreen *screen=[p.mainWindow screen];[p.mainWindow setFrameOrigin:NSMakePoint(NSMinX([screen visibleFrame])+100,NSMinY([screen visibleFrame])-450)];
 NSRect lowAnchor=[p.mainWindow convertRectToScreen:[p.anchor convertRect:[p.anchor bounds] toView:nil]];
 Require(NSMinY(lowAnchor)-NSMinY([screen visibleFrame])-24<220 && NSMaxY([screen visibleFrame])-NSMaxY(lowAnchor)-24>220,"low-anchor fixture really has room only above");
 Require([p showAquaChatSearchPanel],"search also opens above low screen anchor");[p invalidateAquaChatSearchPresentation];
 p.currentAuthState=@"waitCode";Require(![p showAquaChatSearchPanel],"unauthorized search cannot open");p.currentAuthState=@"ready";
 [p.anchor setHidden:YES];Require(![p showAquaChatSearchPanel],"hidden anchor cannot open");[p.anchor setHidden:NO];
 [p disposeAquaChatSearchPresentation];Require([p aquaChatSearchState]==nil,"disposal releases observer and presentation state");
 [p.mainWindow setDelegate:nil];[p.mainWindow orderOut:nil];
}
""".replace('__PRESENTATION_METHODS__',read('Sources/UI/TGStatusWindowController+AquaChatSearch.inc'))

harness=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGWindowEventObserver.h"
#import "TGAquaSearchAnchorField.h"
#import "TGStatusViewCells.h"
#import "TGSearchResultItem.h"
#import "TGLocalization.h"
#import "TGTheme.h"
#import "TGIconAssets.h"
#import "TGMessageLayoutSupport.h"
#import "TGInterfaceDesign.h"
#import "TGAquaAppearance.h"
#include <stdlib.h>
void TGDrawAvatarInRect(NSString *p,NSString *t,NSRect r,BOOL s,BOOL f) {(void)p;(void)t;(void)r;(void)s;(void)f;}
static void Require(BOOL value,const char *message) {if(!value){fprintf(stderr,"Auxiliary layout: %s\n",message);exit(1);}}
__CELL__
__SEARCH__
__CONTACT__
__MENU__
__CLOSE_SEARCH__
__PRESENTATION__
static NSEvent *Key(unichar character,NSUInteger flags,unsigned short code) { NSString *text=[NSString stringWithCharacters:&character length:1];return [NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:flags timestamp:0 windowNumber:0 context:nil characters:text charactersIgnoringModifiers:text isARepeat:NO keyCode:code]; }
@interface SearchTarget : NSObject { @public NSUInteger changed,commits,closes;long long lastChatID; }
@end
@implementation SearchTarget
- (void)changed:(id)sender {(void)sender;changed++;}
- (void)commit:(id)sender {lastChatID=[[[sender selectedResult] chatID] longLongValue];commits++;}
- (void)close:(id)sender {(void)sender;closes++;}
@end
int main(int argc,const char **argv) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    BOOL aqua=argc>1 && strcmp(argv[1],"aqua")==0;
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
    [NSApplication sharedApplication];
    TGChatSearchPanelView *panel=[[[TGChatSearchPanelView alloc] initWithFrame:NSMakeRect(0,0,420,460)] autorelease];
    SearchTarget *target=[[[SearchTarget alloc] init] autorelease];panel.target=target;panel.queryChangedAction=@selector(changed:);panel.commitAction=@selector(commit:);panel.closeAction=@selector(close:);
    NSMutableArray *results=[NSMutableArray array];
    for(NSUInteger i=0;i<50;i++) {TGSearchResultItem *item=[[[TGSearchResultItem alloc] init] autorelease];item.chatID=[NSNumber numberWithUnsignedInteger:i+1];item.chatTitle=@"Synthetic search result";[results addObject:item];}
    panel.results=results;
    NSScrollView *scroll=[panel valueForKey:@"scrollView"];
    [[scroll contentView] scrollToPoint:NSMakePoint(0,280)];[scroll reflectScrolledClipView:[scroll contentView]];
    [panel setFrameSize:NSMakeSize(520,500)];
    Require(fabs([[scroll contentView] bounds].origin.y-280)<1,"resizing keeps the current search position");
    panel.results=[NSArray arrayWithObject:[results objectAtIndex:0]];
    Require([[scroll contentView] bounds].origin.y==0,"a new query starts at its first result");
    panel.query=@"query";[panel controlTextDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:[panel searchField]]];Require(target->changed==1,"typing still routes query changes");
    panel.query=@"";[panel searchFieldAction:nil];Require(target->changed==2,"native cancel routes cleared query");
    panel.selectedIndex=0;[panel commitSearch:nil];Require(target->commits==1,"search result still commits");[panel closeSearch:nil];Require(target->closes==1,"close still routes to owner");
    NSWindow *searchWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,520,500) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[searchWindow setReleasedWhenClosed:NO];[searchWindow setContentView:panel];
    panel.query=@"same query";panel.results=results;panel.selectedIndex=9;
    TGSearchResultItem *replacement=[[[TGSearchResultItem alloc] init] autorelease];replacement.chatID=@10;replacement.chatTitle=@"Updated title";
    NSMutableArray *updated=[NSMutableArray arrayWithArray:results];[updated replaceObjectAtIndex:9 withObject:replacement];[updated insertObject:[results objectAtIndex:20] atIndex:0];
    panel.results=updated;
    Require(panel.selectedIndex==10 && [[[panel selectedResult] chatID] isEqual:@10],"asynchronous same-query results retain the exact keyboard-selected chat identity");
    panel.query=@"other query";panel.results=results;Require(panel.selectedIndex==-1,"new query clears previous keyboard selection");
    NSTableView *table=[panel valueForKey:@"tableView"];NSSearchField *search=[panel searchField];
    Require([search nextKeyView]==table && [table nextKeyView]==search,"search and results have a closed native Tab loop");
    [searchWindow makeFirstResponder:search];NSTextView *editor=(NSTextView *)[search currentEditor];
    Require([panel control:search textView:editor doCommandBySelector:@selector(insertTab:)],"Tab from query routes to results");
    Require([searchWindow firstResponder]==table && panel.selectedIndex==0,"Tab starts at first result and focuses table");
    NSUInteger arrowCommits=target->commits;[table keyDown:Key(NSDownArrowFunctionKey,0,125)];Require(panel.selectedIndex==1,"native Down arrow navigates focused results");
    [table keyDown:Key(NSUpArrowFunctionKey,0,126)];Require(panel.selectedIndex==0 && target->commits==arrowCommits,"native Up/Down navigate without activating a result");
    NSUInteger before=target->commits;[table keyDown:Key('\r',0,36)];Require(target->commits==before+1 && target->lastChatID==1,"Return from results activates selected chat exactly once");
    [table keyDown:Key(NSBackTabCharacter,NSShiftKeyMask,48)];Require([search currentEditor] && [searchWindow firstResponder]==[search currentEditor],"ShiftTab from results returns to editable query");
    editor=(NSTextView *)[search currentEditor];[editor setMarkedText:@"pending" selectedRange:NSMakeRange(0,0) replacementRange:NSMakeRange(0,0)];
    before=target->commits;NSUInteger closesBefore=target->closes;
    Require(![panel control:search textView:editor doCommandBySelector:@selector(insertNewline:)] && ![panel control:search textView:editor doCommandBySelector:@selector(cancelOperation:)] && ![panel control:search textView:editor doCommandBySelector:@selector(moveDown:)],"IME composition keeps Enter Escape and arrows with input method");
    Require(target->commits==before && target->closes==closesBefore && [editor hasMarkedText],"IME is not committed, closed or modified by search shortcuts");[editor unmarkText];
    [searchWindow makeFirstResponder:table];[table keyDown:Key('\t',0,48)];Require([search currentEditor]!=nil,"Tab from results returns to query");
    [searchWindow makeFirstResponder:table];[table keyDown:Key(27,0,53)];Require(target->closes==closesBefore+1,"Escape from focused results closes search locally");
    panel.results=[NSArray array];before=target->commits;[table keyDown:Key('\r',0,36)];Require(target->commits==before,"Enter with empty results never activates a stale selection");
    SearchCloseProbe *close=[[[SearchCloseProbe alloc] init] autorelease];close.chatSearchWindow=searchWindow;close.mainWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,400,200) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[close.mainWindow setReleasedWhenClosed:NO];close.sendTextField=[[[NSTextField alloc] initWithFrame:NSMakeRect(0,0,200,30)] autorelease];[[close.mainWindow contentView] addSubview:close.sendTextField];close.chatSearchGeneration=4;[close closeChatSearchWindow:nil];
    Require(close.chatSearchGeneration==5 && [close.sendTextField currentEditor]!=nil && ![searchWindow isVisible],"closing search invalidates async generation and restores composer focus");
    MenuProbe *menu=[[[MenuProbe alloc] init] autorelease];[menu buildMainMenu];NSMenu *main=[NSApp mainMenu];NSMenu *find=[[main itemAtIndex:[main numberOfItems]-1] submenu];
    Require([find numberOfItems]==2 && [[find itemAtIndex:0] action]==@selector(openChatSearch:) && [[find itemAtIndex:1] action]==@selector(openChatListSearch:),"Search menu exposes distinct existing conversation and chat actions");
    Require([[[find itemAtIndex:0] keyEquivalent] isEqual:@"f"] && [[[find itemAtIndex:1] keyEquivalent] isEqual:@"k"] && [[find itemAtIndex:0] keyEquivalentModifierMask]==NSCommandKeyMask && [[find itemAtIndex:1] keyEquivalentModifierMask]==NSCommandKeyMask,"menu documents existing CmdF and CmdK shortcuts");
    if(aqua) CheckSearchPresentation();
    if(aqua) {
        for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
            TGSetLanguageCode(language);
            for(NSNumber *width in [NSArray arrayWithObjects:@280,@320,@400,nil]) {
                for(NSNumber *height in [NSArray arrayWithObjects:@220,@340,nil]) {
                    TGChatSearchPanelView *compact=[[[TGChatSearchPanelView alloc] initWithFrame:NSMakeRect(0,0,[width doubleValue],[height doubleValue])] autorelease];
                    compact.results=results;
                    NSTextField *title=[compact valueForKey:@"titleField"],*status=[compact valueForKey:@"statusField"];
                    NSScrollView *list=[compact valueForKey:@"scrollView"];
                    Require([title isHidden] && NSIsEmptyRect([title frame]),"compact Aqua search has no repeated large title");
                    Require([[status stringValue] isEqual:TGLoc(@"search.chats.recentShort")],"recent section uses complete short localized label");
                    Require(NSMaxY([[compact searchField] frame]) < NSMinY([status frame]) && NSMaxY([status frame]) < NSMinY([list frame]),"query, section label and list never overlap");
                    Require(NSContainsRect([compact bounds],[list frame]) && NSMinY([list frame])<=70 && NSWidth([list frame])==[width doubleValue],"compact results reclaim header and card padding at minimum size");
                    Require([[list documentView] rowHeight]==44 && [list hasVerticalScroller],"compact source rows retain native scrolling for overflow");
                    compact.statusText=@"Network unavailable";
                    Require([[status stringValue] isEqual:@"Network unavailable"],"compact status still shows loading/error result text");
                }
            }
        }
    }
    NSUInteger layouts=0;
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
        TGSetLanguageCode(language);
        for(NSNumber *width in [NSArray arrayWithObjects:@320,@420,@620,nil]) {
            [panel setFrameSize:NSMakeSize([width doubleValue],460)];
            for(NSString *key in [NSArray arrayWithObjects:@"titleField",@"searchField",@"statusField",@"scrollView",nil])
                Require([[panel valueForKey:key] isHidden] || NSContainsRect([panel bounds],[[panel valueForKey:key] frame]),"visible search controls fit narrow window");
            Require([TGLoc(@"downloads.short") sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:13] forKey:NSFontAttributeName]].width+24<=112,"localized toolbar download caption fits full button");
            if(aqua) Require([[panel searchField] isBezeled] && [[[panel searchField] cell] searchButtonCell]!=nil && [[[panel searchField] cell] cancelButtonCell]!=nil,"Aqua uses native search and clear affordances");
            layouts++;
        }
        for(NSNumber *width in [NSArray arrayWithObjects:@420,@719,@720,@980,nil]) {
            ContactLayoutProbe *c=[[[ContactLayoutProbe alloc] init] autorelease];[c setView:aqua ? [[[TGAquaUtilityWindowView alloc] initWithFrame:NSMakeRect(0,0,[width doubleValue],560)] autorelease] : [[[NSView alloc] initWithFrame:NSMakeRect(0,0,[width doubleValue],560)] autorelease]];
            c.titleField=[[[NSTextField alloc] init] autorelease];c.createChatButton=[[[NSButton alloc] init] autorelease];c.refreshButton=[[[NSButton alloc] init] autorelease];c.searchField=[[[NSSearchField alloc] init] autorelease];c.profileView=[[[NSView alloc] init] autorelease];c.listCardView=[[[NSView alloc] init] autorelease];c.scrollView=[[[NSScrollView alloc] init] autorelease];c.tableView=[[[NSTableView alloc] init] autorelease];c.statusField=[[[NSTextField alloc] init] autorelease];c.spinner=[[[NSProgressIndicator alloc] init] autorelease];c.openButton=[[[NSButton alloc] init] autorelease];c.actionButton=[[[NSButton alloc] init] autorelease];[c.openButton setTitle:TGLoc(@"contacts.open")];[c.actionButton setTitle:TGLoc(@"contacts.actions")];[c layoutContent];
            Require(NSContainsRect([[c view] bounds],[c.openButton frame]) && NSContainsRect([[c view] bounds],[c.actionButton frame]) && !NSIntersectsRect([c.openButton frame],[c.actionButton frame]),"contact actions fit and do not overlap");
            NSButton *buttons[]={c.openButton,c.actionButton};for(NSUInteger i=0;i<2;i++) {
                CGFloat text=[[buttons[i] title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:i==0?13:12] forKey:NSFontAttributeName]].width;
                Require(NSWidth([buttons[i] frame])>=ceil(text)+(i==0?32:28),"localized contact action fits its actual font");
            }
            layouts++;
        }
    }
    printf("Auxiliary %s: %lu localized narrow/wide production layouts; search scroll/cancel/commit/close and keyboard/focus/IME/menu routes PASS.\n",aqua?"Aqua":"Classic",(unsigned long)layouts);
    [pool drain];return 0;
}
'''.replace('__CELL__',cell).replace('__SEARCH__',read('Sources/UI/TGChatSearchPanelView.inc')).replace('__CONTACT__',interface).replace('__MENU__',menu).replace('__CLOSE_SEARCH__',close_search).replace('__PRESENTATION__',presentation)
folder=tempfile.mkdtemp(prefix='telegraphica-auxiliary-layout-')
try:
    source=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(source,'wb') as handle:handle.write(harness.encode('utf-8'))
    deps=['Sources/UI/TGAquaSearchAnchorField.m','Sources/UI/TGWindowEventObserver.m','Sources/Core/TGSearchResultItem.m','Sources/UI/TGIconAssets.m','Sources/UI/TGLocalization.m','Sources/UI/TGTheme.m','Sources/UI/TGInterfaceDesign.m','Sources/UI/TGDialogPresentation.m','Sources/UI/TGAquaAppearance.m','Sources/UI/TGVisualWorldThemeSpec.m']
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),'-I'+os.path.join(ROOT,'Sources/Core'),source]+[os.path.join(ROOT,p) for p in deps]+['-framework','Cocoa','-o',binary])
    subprocess.check_call([binary,'aqua']);subprocess.check_call([binary,'classic'])
finally:
    shutil.rmtree(folder)
