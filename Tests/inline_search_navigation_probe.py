#!/usr/bin/env python
"""Execute inline-search UI helpers and complete queued production search jumps."""
from __future__ import print_function
import os, shutil, subprocess, sys, tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
def read(path):
    with open(os.path.join(ROOT,path),'rb') as stream: return stream.read().decode('utf-8')
source=read('Sources/UI/TGStatusWindowController+SearchNavigation.inc')
def methods(first,last):
    a=source.index(first);return source[a:source.index(last,a)]
production='\n'.join([
 methods('- (void)closeSearchPanel:','- (void)searchDebounceTimerFired:'),
 methods('- (void)jumpToSearchResult:','- (BOOL)handleSearchKeyEquivalent:')])
objects=[('NSButton *','sendMessageButton'),('NSWindow *','hostWindow'),('TGTDLibClient *','client'),('NSNumber *','profileUserID'),('NSString *','searchSenderQuery'),('NSString *','activeSection'),('NSString *','currentAuthState'),('NSNumber *','selectedChatID'),('NSString *','selectedChatTitle'),('NSNumber *','selectedMessageThreadID'),('NSString *','selectedMessageTopicKind'),('NSNumber *','highlightedSearchMessageID'),('NSMutableArray *','searchResultItems'),('NSMutableArray *','messageItems'),('NSMutableArray *','chatItems'),('SearchCardProbe *','searchPanelView'),('NSTextField *','searchTextField'),('NSTextField *','sendTextField'),('NSButton *','searchCloseButton'),('NSButton *','searchAdvancedButton'),('NSPopUpButton *','searchScopePopUpButton'),('NSPopUpButton *','searchFilterPopUpButton'),('NSTextField *','searchStatusField'),('NSScrollView *','searchResultsScrollView'),('TGInlineSearchResultsTableView *','searchResultsTableView'),('NSTableView *','messageTableView'),('NSTableView *','chatTableView'),('NSProgressIndicator *','messageLoadingSpinner'),('NSTimer *','searchHighlightTimer'),('NSTimer *','searchDebounceTimer'),('TGNavigationPositionStore *','navigationPositionStore')]
scalars=[('NSInteger','searchDateRangeIndex')]+[('BOOL',p) for p in ['searchEndReached','searchPanelVisible','searchLoading','chatTitleSearchOnly','searchInlineCurrentChatOnly','messageLoadingIndicatorVisible','messageItemsRepresentFocusedContext','showingForumTopicList','forumTopicsPresentedInTopBar']]+[('NSUInteger',p) for p in ['searchGeneration','messageLoadingGeneration','activations','latestRequests','headerRefreshes','visibleUpdates','searchRequests']]
props=objects+scalars
ivars='\n'.join(' %s _%s;'%(t,n) for t,n in props)
properties='\n'.join('@property(nonatomic,%s) %s %s;'%('retain' if '*' in t else 'assign',t,n) for t,n in props)
synth='\n'.join('@synthesize %s=_%s;'%(n,n) for t,n in props)
release=''.join('[_%s release];'%n for t,n in objects)
harness=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGKeyboardInputSupport.h"
#import "TGAquaShellViews.h"
#import "TGLocalization.h"
#import "TGNavigationPositionStore.h"
#import "TGSearchResultItem.h"
@interface SearchCardProbe : NSView { BOOL _squareTopCorners; }
@property(nonatomic,assign) BOOL squareTopCorners;
@end
@implementation SearchCardProbe
@synthesize squareTopCorners=_squareTopCorners;
@end
static BOOL Aqua=YES;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
NSColor *TGClassicCardInkColor(void) { return [NSColor blackColor]; }
static NSUInteger Checks;
static void Require(BOOL condition,const char *message) { Checks++;if(!condition) {fprintf(stderr,"Inline search: %s\n",message);exit(1);} }
static NSMutableArray *Workers,*Mains;
static void Dispatch(dispatch_queue_t queue,dispatch_block_t block) {id copy=[block copy];[(queue==dispatch_get_main_queue()?Mains:Workers) addObject:copy];[copy release];}
static void Run(NSMutableArray *queue) { Require([queue count]>0,"expected queued production callback");dispatch_block_t block=[[queue objectAtIndex:0] copy];[queue removeObjectAtIndex:0];block();[block release]; }
@interface TGMessageItem : NSObject { NSNumber *_messageID; NSNumber *_date; NSString *_senderDisplayName; }
@property(nonatomic,retain) NSNumber *date;
@property(nonatomic,copy) NSString *senderDisplayName;
@property(nonatomic,retain) NSNumber *messageID;
@end
@implementation TGMessageItem
@synthesize messageID=_messageID, date=_date,senderDisplayName=_senderDisplayName;
- (void)dealloc {[_messageID release];[_date release];[_senderDisplayName release];[super dealloc];}
@end
@interface TGTDLibClient : NSObject { NSArray *_items; }
@property(nonatomic,retain) NSArray *items;
- (NSArray *)messageContextPreviewItemsForChatID:(NSNumber *)chat messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind centerMessageID:(NSNumber *)message limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error;
@end
@implementation TGTDLibClient
@synthesize items=_items;
- (void)dealloc {[_items release];[super dealloc];}
- (NSArray *)messageContextPreviewItemsForChatID:(NSNumber *)chat messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind centerMessageID:(NSNumber *)message limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error { (void)chat;(void)thread;(void)kind;(void)message;(void)limit;(void)timeout;(void)error;return _items; }
@end
@interface InlineProbe : NSObject <NSTableViewDataSource,NSTableViewDelegate> {
__IVARS__
}
__PROPERTIES__
- (NSUInteger)indexOfMessageID:(NSNumber *)message inMessageItems:(NSArray *)items;
- (void)updateInlineSearchNavigation;
@end
@implementation InlineProbe
__SYNTH__
- (void)dealloc {[_searchHighlightTimer invalidate];[_searchDebounceTimer invalidate];__RELEASE__ [super dealloc];}
- (NSWindow *)window {return self.hostWindow;}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)table {return (NSInteger)[(table==self.searchResultsTableView ? self.searchResultItems:self.messageItems) count];}
- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row {(void)table;(void)column;(void)row;return @"";}
- (void)tableViewSelectionDidChange:(NSNotification *)notification {(void)notification;[self updateInlineSearchNavigation];}
- (void)applyUtilityButtonStyle:(NSButton *)button {(void)button;}
- (void)installAquaTextCellOnButton:(NSButton *)button accented:(BOOL)accented {(void)button;(void)accented;}
- (NSTextField *)labelWithFrame:(NSRect)frame text:(NSString *)text font:(NSFont *)font {NSTextField *field=[[[NSTextField alloc] initWithFrame:frame] autorelease];[field setEditable:NO];[field setSelectable:NO];[field setBordered:NO];[field setFont:font];[field setStringValue:text];return field;}
- (void)activateSearchResult:(id)sender {(void)sender;self.activations++;[self updateInlineSearchNavigation];}
- (void)jumpToNewestMessages:(id)sender {(void)sender;Require(!self.searchPanelVisible,"return latest closes inline search before navigating");self.latestRequests++;}
- (void)captureNavigationContinuity {}
- (void)closeForumTopicList:(id)sender {(void)sender;}
- (NSUInteger)indexOfChatID:(NSNumber *)chat inChatItems:(NSArray *)items {(void)chat;(void)items;return NSNotFound;}
- (void)appendDetail:(NSString *)text {(void)text;}
- (NSArray *)messageItemsInDisplayOrderFromItems:(NSArray *)items {return items;}
- (void)updateOutgoingReadStateForVisibleMessages {}
- (void)markVisiblePinnedMessagesFromPinnedItems {}
- (void)updateMessageJumpToNewestButtonVisibility {}
- (void)refreshSelectedChatHeaderDisplay {self.headerRefreshes++;}
- (void)updateVisibleSection {self.visibleUpdates++;[self updateInlineSearchNavigation];}
- (void)layoutContentView {}
- (void)performSearchReset:(BOOL)reset {(void)reset; self.searchRequests++;}
__FILTERS__
__INLINE__
#define dispatch_async(queue, ...) Dispatch(queue, (__VA_ARGS__))
__SEARCH__
#undef dispatch_async
@end
static TGMessageItem *Message(NSInteger i) {TGMessageItem *item=[[[TGMessageItem alloc] init] autorelease];item.messageID=[NSNumber numberWithInteger:i];return item;}
static TGSearchResultItem *Result(NSInteger i) {TGSearchResultItem *result=[[[TGSearchResultItem alloc] init] autorelease];result.chatID=@10;result.messageID=[NSNumber numberWithInteger:i];result.chatTitle=@"Synthetic conversation";return result;}
static void Fill(InlineProbe *p) {
 [p.searchResultItems removeAllObjects];[p.searchResultItems addObjectsFromArray:[NSArray arrayWithObjects:Result(50),Result(51),Result(52),nil]];[p.searchResultsTableView reloadData];
}
static InlineProbe *Prepare(void) {
 InlineProbe *p=[[[InlineProbe alloc] init] autorelease];p.profileUserID=@1;p.activeSection=@"chats";p.currentAuthState=@"ready";p.selectedChatID=@10;p.searchPanelVisible=YES;
 p.hostWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,800,700) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[p.hostWindow setReleasedWhenClosed:NO];
 p.searchTextField=[[[NSTextField alloc] initWithFrame:NSMakeRect(0,0,200,24)] autorelease];[p.searchTextField setStringValue:@"query"];[[p.hostWindow contentView] addSubview:p.searchTextField];
 p.sendTextField=[[[NSTextField alloc] initWithFrame:NSMakeRect(0,40,200,24)] autorelease];[[p.hostWindow contentView] addSubview:p.sendTextField];
 p.searchPanelView=[[[SearchCardProbe alloc] init] autorelease];p.searchCloseButton=[[[NSButton alloc] init] autorelease];p.searchAdvancedButton=[[[NSButton alloc] init] autorelease];
 p.searchScopePopUpButton=[[[NSPopUpButton alloc] init] autorelease];p.searchFilterPopUpButton=[[[NSPopUpButton alloc] init] autorelease];p.searchStatusField=[[[NSTextField alloc] init] autorelease];
 p.searchResultsScrollView=[[[NSScrollView alloc] initWithFrame:NSMakeRect(0,80,400,180)] autorelease];p.searchResultsTableView=[[[TGInlineSearchResultsTableView alloc] initWithFrame:NSMakeRect(0,0,400,180)] autorelease];[p.searchResultsTableView setHeaderView:nil];[p.searchResultsTableView setTarget:p];[p.searchResultsTableView setNextKeyView:p.searchTextField];[p.searchResultsTableView addTableColumn:[[[NSTableColumn alloc] initWithIdentifier:@"search"] autorelease]];[p.searchResultsTableView setDataSource:p];[p.searchResultsTableView setDelegate:p];[p.searchResultsScrollView setDocumentView:p.searchResultsTableView];[[p.hostWindow contentView] addSubview:p.searchResultsScrollView];
 p.messageTableView=[[[NSTableView alloc] initWithFrame:NSMakeRect(0,300,400,150)] autorelease];[p.messageTableView setHeaderView:nil];[p.messageTableView setDataSource:p];[p.messageTableView addTableColumn:[[[NSTableColumn alloc] initWithIdentifier:@"message"] autorelease]];p.chatTableView=[[[NSTableView alloc] init] autorelease];
 p.messageLoadingSpinner=[[[NSProgressIndicator alloc] init] autorelease];p.searchResultItems=[NSMutableArray array];p.messageItems=[NSMutableArray array];p.chatItems=[NSMutableArray array];p.navigationPositionStore=[[[TGNavigationPositionStore alloc] init] autorelease];
 p.client=[[[TGTDLibClient alloc] init] autorelease];p.client.items=[NSArray arrayWithObjects:Message(50),Message(51),Message(52),nil];Fill(p);[p configureInlineSearchNavigation];return p;
}
static NSEvent *Key(unichar key,NSUInteger flags) {NSString *text=[NSString stringWithCharacters:&key length:1];return [NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:flags timestamp:0 windowNumber:0 context:nil characters:text charactersIgnoringModifiers:text isARepeat:NO keyCode:0];}
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];Workers=[[NSMutableArray alloc] init];Mains=[[NSMutableArray alloc] init];
 InlineProbe *p=Prepare();NSDictionary *controls=objc_getAssociatedObject(p,&TGInlineSearchControlsKey);NSArray *buttons=[controls objectForKey:@"buttons"];NSTextField *counter=[controls objectForKey:@"counter"];
 for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
  TGSetLanguageCode(language);
  for(NSUInteger ended=0;ended<2;ended++) for(NSInteger row=-1;row<3;row++) {
   p.searchEndReached=ended!=0;if(row<0) [p.searchResultsTableView deselectAll:nil];else [p.searchResultsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];[p updateInlineSearchNavigation];
   Require([[buttons objectAtIndex:0] isEnabled]==(row>0) && [[buttons objectAtIndex:1] isEnabled]==(row<2 || !ended),"previous/next states match first/last/unselected bounds");
   Require([[counter stringValue] hasPrefix:[NSString stringWithFormat:@"%ld",(long)(row+1)]] && [[counter stringValue] rangeOfString:@"3"].location!=NSNotFound && [[counter stringValue] rangeOfString:@"search."].location==NSNotFound,"counter shows localized selected position and result total");
  }
  for(NSNumber *width in [NSArray arrayWithObjects:@340,@480,@800,nil]) for(NSNumber *height in [NSArray arrayWithObjects:@340,@500,nil]) {
   NSRect area=NSMakeRect(40,50,[width doubleValue],[height doubleValue]);[p layoutAquaInlineSearchInRect:area];
   NSView *nav=[p inlineSearchNavigationView];Require(NSContainsRect(area,[nav frame]),"navigation fits physical inline area");
   Require(!NSIntersectsRect([p.searchStatusField frame],[p.searchResultsScrollView frame]) && !NSIntersectsRect([p.searchResultsScrollView frame],[nav frame]),"status, result rows and navigation occupy separate vertical bands");
   for(NSView *button in buttons) Require(NSContainsRect([nav bounds],[button frame]),"localized navigation buttons fit their host");
   Require(!NSIntersectsRect([[buttons objectAtIndex:0] frame],[[buttons objectAtIndex:1] frame]) && !NSIntersectsRect([[buttons objectAtIndex:1] frame],[counter frame]) && !NSIntersectsRect([counter frame],[[buttons objectAtIndex:2] frame]),"counter and buttons do not overlap");
  }
 }
 [p.searchResultsTableView deselectAll:nil];NSUInteger before=p.activations;[p previousInlineSearchResult:nil];Require(p.activations==before,"previous at no selection is bounded");[p nextInlineSearchResult:nil];Require(p.activations==before+1 && [p.searchResultsTableView selectedRow]==0,"next starts from first result");[p previousInlineSearchResult:nil];Require(p.activations==before+1,"previous at first does not activate");[p nextInlineSearchResult:nil];[p nextInlineSearchResult:nil];before=p.activations;[p nextInlineSearchResult:nil];Require(p.activations==before && [p.searchResultsTableView selectedRow]==2,"next at last does not activate");
 [p.hostWindow makeFirstResponder:p.searchTextField];NSTextView *editor=(NSTextView *)[p.searchTextField currentEditor];[editor setMarkedText:@"pending" selectedRange:NSMakeRange(0,0) replacementRange:NSMakeRange(0,0)];before=p.activations;
 Require(![p control:p.searchTextField textView:editor doSearchCommandBySelector:@selector(insertNewline:)] && ![p control:p.searchTextField textView:editor doSearchCommandBySelector:@selector(cancelOperation:)] && ![p control:p.searchTextField textView:editor doSearchCommandBySelector:@selector(moveDown:)] && p.searchPanelVisible && p.activations==before,"IME keeps Enter Escape arrows inside composition");[editor unmarkText];
 [p.searchResultsTableView deselectAll:nil];Require([p control:p.searchTextField textView:editor doSearchCommandBySelector:@selector(insertTab:)] && [p.hostWindow firstResponder]==p.searchResultsTableView,"Tab reaches inline results");[p.searchResultsTableView keyDown:Key('\r',0)];Require(p.activations==before+1 && [p.searchResultsTableView selectedRow]==0,"Return from focused inline table chooses first result when nothing is selected");[p.searchResultsTableView keyDown:Key('\t',0)];Require([p.searchTextField currentEditor]!=nil,"Tab from inline results returns to editable query");
 // Whole production jump, with deterministic worker and main-queue delivery.
 [p jumpToSearchResult:Result(51)];Run(Workers);Run(Mains);Require(p.headerRefreshes==1 && p.messageItemsRepresentFocusedContext && [p.highlightedSearchMessageID isEqual:@51] && !p.messageLoadingIndicatorVisible,"successful actual jump presents focused hit and clears its spinner");
 [p jumpToSearchResult:Result(52)];Run(Workers);before=p.headerRefreshes;[p.searchTextField setStringValue:@"edited query"];[p scheduleSearchRequest];Require(!p.messageLoadingIndicatorVisible,"query edit cancels only outstanding jump spinner");Run(Mains);Require(p.headerRefreshes==before && [p.highlightedSearchMessageID isEqual:@51],"edited query rejects already queued old hit");[p.searchDebounceTimer invalidate];p.searchDebounceTimer=nil;
 [p jumpToSearchResult:Result(52)];Run(Workers);before=p.headerRefreshes;[p closeSearchPanel:nil];Run(Mains);Require(p.headerRefreshes==before && !p.searchPanelVisible && !p.highlightedSearchMessageID && !p.searchHighlightTimer && !p.searchDebounceTimer,"close cancels queued hit plus highlight and debounce state");
 p.searchPanelVisible=YES;Fill(p);[p jumpToSearchResult:Result(52)];Run(Workers);before=p.headerRefreshes;TGTDLibClient *old=p.client;p.client=[[[TGTDLibClient alloc] init] autorelease];Run(Mains);Require(p.headerRefreshes==before && !p.messageLoadingIndicatorVisible,"previous TDLib client cannot present a queued hit or leave its spinner stuck");p.client=old;
 p.searchPanelVisible=YES;Fill(p);[p jumpToSearchResult:Result(52)];Run(Workers);before=p.headerRefreshes;p.profileUserID=@2;Run(Mains);Require(p.headerRefreshes==before && !p.messageLoadingIndicatorVisible,"same TDLib client cannot present previous account hit or leave its spinner stuck");p.profileUserID=@1;
 [p advanceInlineSearchJumpGeneration];p.messageLoadingGeneration+=10;p.messageLoadingIndicatorVisible=YES;NSUInteger unrelatedGeneration=p.messageLoadingGeneration;[p closeSearchPanel:nil];Require(p.messageLoadingGeneration==unrelatedGeneration && p.messageLoadingIndicatorVisible,"closing inline search does not cancel a different message-history spinner");p.messageLoadingIndicatorVisible=NO;
 [p clearSearchHighlightTimerFired:p.searchHighlightTimer];Require(!p.highlightedSearchMessageID && !p.searchHighlightTimer,"highlight expiration clears visible search marker state");
 p.searchPanelVisible=YES;[p returnFromInlineSearchToLatest:nil];Require(p.latestRequests==1 && !p.searchPanelVisible,"return latest closes search and invokes existing latest route");
 p.searchPanelVisible=YES;Fill(p);[p jumpToSearchResult:Result(51)];Run(Workers);before=p.headerRefreshes;[p jumpToSearchResult:Result(52)];Run(Workers);Run(Mains);Require(p.headerRefreshes==before && p.messageLoadingIndicatorVisible,"superseded callback does not present old hit or stop newer jump spinner");Run(Mains);Require(p.headerRefreshes==before+1 && [p.highlightedSearchMessageID isEqual:@52] && !p.messageLoadingIndicatorVisible,"newest queued jump presents and ends only its own spinner");
 p.searchPanelVisible=YES;Fill(p);[p.hostWindow makeFirstResponder:p.searchResultsTableView];[p.searchResultsTableView keyDown:Key(27,0)];Require(!p.searchPanelVisible,"Escape from inline results closes only search");
 p.selectedChatID=nil;[p updateInlineSearchNavigation];Require(![[buttons objectAtIndex:2] isEnabled],"latest is unavailable without selected conversation");p.selectedChatID=@10;
 NSMenuItem *sendMenu=[[[NSMenuItem alloc] initWithTitle:@"Schedule" action:@selector(scheduleMessage:) keyEquivalent:@""] autorelease];
 p.sendMessageButton=[[[NSButton alloc] init] autorelease];[p.sendMessageButton setEnabled:NO];Require(![p validateMenuItem:sendMenu],"empty composer disables scheduled sending");
 [p.sendMessageButton setEnabled:YES];Require([p validateMenuItem:sendMenu],"ready draft enables scheduling");
 [sendMenu setAction:@selector(showScheduledMessages:)];Require([p validateMenuItem:sendMenu],"scheduled list remains reachable independently of draft");
 NSMenuItem *find=[[[NSMenuItem alloc] initWithTitle:@"Find" action:@selector(openChatSearch:) keyEquivalent:@"f"] autorelease];p.currentAuthState=@"ready";Require([p validateMenuItem:find],"conversation search menu enabled in ready selected chat");p.currentAuthState=@"waitCode";Require(![p validateMenuItem:find],"search menu disabled before authorization");p.currentAuthState=@"ready";p.selectedChatID=nil;Require(![p validateMenuItem:find],"conversation search menu disabled with no conversation");[find setAction:@selector(openChatListSearch:)];Require([p validateMenuItem:find],"find-chat menu remains available outside a conversation");

 p.selectedChatID=@10;p.searchPanelVisible=YES;[p.searchPanelView setHidden:NO];
 [p toggleAquaSearchFilters:nil];Require([p aquaSearchFiltersExpanded],"filters expand without a modal");
 NSDictionary *filterState=[p aquaSearchFilterState];
 for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
  TGSetLanguageCode(language);[p refreshAquaSearchFilterControls];
  for(NSNumber *width in [NSArray arrayWithObjects:@260,@320,@390,@440,@600,@1000,nil]) for(NSNumber *height in [NSArray arrayWithObjects:@340,@420,@600,nil]) {
   NSRect available=NSMakeRect(40,50,[width doubleValue],[height doubleValue]);[p layoutAquaInlineSearchInRect:available];
   NSScrollView *scroll=[filterState objectForKey:@"view"];NSView *doc=[filterState objectForKey:@"content"];
   Require(![scroll isHidden] && NSContainsRect(available,[scroll frame]),"expanded filters stay inside available search area");
   for(NSString *key in [NSArray arrayWithObjects:@"sender",@"period",@"from",@"to",@"reset",nil]) Require(NSContainsRect([doc bounds],[[filterState objectForKey:key] frame]),"all localized filter controls fit their scroll document");
   Require(!NSIntersectsRect([scroll frame],[p.searchStatusField frame]) && !NSIntersectsRect([scroll frame],[p.searchResultsScrollView frame]),"filter area does not overlap results/status");
   Require(NSMinY([p.searchPanelView frame])-NSMinY(available)>=160,"expanded search preserves transcript minimum");
  }
 }
 [[filterState objectForKey:@"sender"] setStringValue:@"Anna"];[[filterState objectForKey:@"period"] selectItemAtIndex:4];
 NSTimeZone *zone=[NSTimeZone timeZoneWithName:@"America/New_York"];[NSTimeZone setDefaultTimeZone:zone];
 NSCalendar *cal=[NSCalendar currentCalendar];NSDateComponents *parts=[[[NSDateComponents alloc] init] autorelease];[parts setYear:2026];[parts setMonth:11];[parts setDay:1];NSDate *start=[cal dateFromComponents:parts];
 [[filterState objectForKey:@"from"] setDateValue:start];[[filterState objectForKey:@"to"] setDateValue:start];[p applyAquaSearchFilters:nil];
 TGMessageItem *dated=Message(900);dated.date=[NSNumber numberWithDouble:[start timeIntervalSince1970]-1];Require(![p messageMatchesAquaSearchDate:dated],"custom dates exclude previous day");dated.date=[NSNumber numberWithDouble:[start timeIntervalSince1970]];Require([p messageMatchesAquaSearchDate:dated],"custom dates include start midnight");
 NSDateComponents *day=[[[NSDateComponents alloc] init] autorelease];[day setDay:1];NSDate *end=[cal dateByAddingComponents:day toDate:start options:0];Require([end timeIntervalSinceDate:start]==25*3600,"fixture crosses daylight-saving 25-hour day");dated.date=[NSNumber numberWithDouble:[end timeIntervalSince1970]-1];Require([p messageMatchesAquaSearchDate:dated],"custom dates include last second of 25-hour day");dated.date=[NSNumber numberWithDouble:[end timeIntervalSince1970]];Require(![p messageMatchesAquaSearchDate:dated],"custom dates exclude following midnight");
 [p.searchResultItems removeAllObjects];[p.searchResultsTableView reloadData];p.searchEndReached=NO;p.searchLoading=NO;[p updateInlineSearchNavigation];Require([[buttons objectAtIndex:1] isEnabled],"Next can continue a filtered-empty page");NSUInteger requests=p.searchRequests;[p nextInlineSearchResult:nil];Require(p.searchRequests==requests+1,"Next fetches a subsequent raw page without visible results");p.searchEndReached=YES;[p updateInlineSearchNavigation];Require(![[buttons objectAtIndex:1] isEnabled],"Next stops at true backend end");
 [p resetAquaSearchFilters:nil];Require(![p.searchSenderQuery length] && !p.searchDateRangeIndex && [p messageMatchesAquaSearchDate:dated],"Reset clears sender and custom date constraints");
 [p closeSearchPanel:nil];Require([[filterState objectForKey:@"view"] isHidden],"closing search hides filter view");
 [p toggleAquaSearchFilters:nil];Require(![p aquaSearchFiltersExpanded],"filters can collapse independently of their values");
 Aqua=NO;p.searchPanelVisible=YES;[p updateInlineSearchNavigation];Require([[p inlineSearchNavigationView] isHidden],"Classic does not display Aqua search navigation chrome");
 [p.searchHighlightTimer invalidate];[p.searchDebounceTimer invalidate];Require(![Workers count] && ![Mains count],"all production async callbacks drained");[Workers release];[Mains release];
 printf("Inline search PASS: %lu production UI, keyboard, IME, bounds and queued jump checks.\n",(unsigned long)Checks);[pool drain];return 0;
}
'''
for token,value in [('__IVARS__',ivars),('__PROPERTIES__',properties),('__SYNTH__',synth),('__RELEASE__',release),('__FILTERS__',read('Sources/UI/TGStatusWindowController+AquaSearchFilters.inc')),('__INLINE__',read('Sources/UI/TGStatusWindowController+InlineSearchPresentation.inc')),('__SEARCH__',production)]: harness=harness.replace(token,value)
folder=tempfile.mkdtemp(prefix='telegraphica-inline-search-')
try:
 path=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
 with open(path,'wb') as stream:stream.write(harness.encode('utf-8'))
 deps=['Sources/UI/TGKeyboardInputSupport.m','Sources/UI/TGAquaShellLayout.m','Sources/UI/TGNavigationPositionStore.m','Sources/UI/TGLocalization.m','Sources/Core/TGSearchResultItem.m']
 subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),'-I'+os.path.join(ROOT,'Sources/Core'),path]+[os.path.join(ROOT,p) for p in deps]+['-framework','Cocoa','-o',binary])
 subprocess.check_call([binary])
finally:shutil.rmtree(folder)
