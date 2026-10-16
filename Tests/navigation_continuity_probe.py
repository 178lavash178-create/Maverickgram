#!/usr/bin/env python
"""Exercise production semantic anchors, real AppKit viewports and async guards."""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
with open(os.path.join(ROOT, 'Sources/UI/TGStatusWindowController+MessageDataFlow.inc'), 'rb') as stream:
    flow = stream.read().decode('utf-8')
start = flow.index('- (void)reloadMessagesForChatID:')
start = flow.index('            BOOL sameThread =', start)
end = flow.index('            if (!selectionStillCurrent)', start)
guards = flow[start:end]
reload_start = flow.index('- (void)reloadMessagesForChatID:')
reload_end = flow.index('\n- (void)reloadOlderMessagesInteractive', reload_start)
reload_method = flow[reload_start:reload_end]
jump_start = flow.index('- (void)jumpToNewestMessages:')
jump_end = flow.index('\n- (NSInteger)firstUnreadMessageRow', jump_start)
jump_method = flow[jump_start:jump_end]
props = [
 ('TGNavigationPositionStore *','navigationPositionStore','retain'),
 ('NSNumber *','profileUserID','retain'),('NSNumber *','selectedChatFilterID','retain'),
 ('NSNumber *','topicParentChatID','retain'),('NSNumber *','selectedChatID','retain'),
 ('NSNumber *','selectedMessageThreadID','retain'),('NSString *','selectedMessageTopicKind','copy'),
 ('NSString *','topicParentTitle','copy'),('NSString *','selectedChatTitle','copy'),
 ('NSString *','currentAuthState','copy'),('TGTDLibClient *','client','retain'),
 ('NSMutableArray *','chatItems','retain'),('NSMutableArray *','messageItems','retain'),
 ('NSArray *','drawerFolderButtons','retain'),('NSScrollView *','chatScrollView','retain'),
 ('NSScrollView *','messageScrollView','retain'),('NSTableView *','chatTableView','retain'),
 ('NSTableView *','messageTableView','retain'),('NSTextField *','chatsLabel','retain'),
 ('NSTextField *','selectedChatField','retain'),('NSButton *','topicBackButton','retain'),
 ('BOOL','showingArchivedChats','assign'),('BOOL','showingForumTopicList','assign'),
 ('BOOL','forumTopicsPresentedInTopBar','assign'),('BOOL','chatNavigationClosed','assign'),
 ('BOOL','messageItemsRepresentFocusedContext','assign'),('BOOL','forceMessageScrollToNewest','assign'),
 ('BOOL','initialUnreadPositionPending','assign'),('NSUInteger','searchGeneration','assign'),
 ('NSUInteger','jumpUpdates','assign'),
 ('BOOL','backgroundMessageRefreshInFlight','assign'),('BOOL','pendingLiveMessageRefresh','assign'),
 ('BOOL','messageLoadingIndicatorVisible','assign'),('BOOL','composerRefocusPending','assign'),
 ('BOOL','olderMessagesExhausted','assign'),('BOOL','lastPreserveOlder','assign'),
 ('NSUInteger','messageLoadingGeneration','assign'),('NSUInteger','selectedChatUnreadCount','assign'),
 ('NSUInteger','applyCount','assign'),('NSNumber *','selectedChatLastReadInboxMessageID','retain'),
 ('NSProgressIndicator *','messageLoadingSpinner','retain'),('NSTextField *','statusField','retain'),
 ('NSArray *','lastAppliedItems','retain')]
ivars='\n'.join('    %s _%s;' % (t,n) for t,n,a in props)
properties='\n'.join('@property(nonatomic,%s) %s %s;' % (a,t,n) for t,n,a in props)
synth='\n'.join('@synthesize %s=_%s;' % (n,n) for t,n,a in props)
releases=''.join('[_%s release];' % n for t,n,a in props if a!='assign')
with open(os.path.join(ROOT, 'Sources/UI/TGStatusWindowController+SearchNavigation.inc'), 'rb') as stream:
    search = stream.read().decode('utf-8')
search_end = search.index('    NSNumber *chatID = [result.chatID retain];')
search_start = search.rindex('    [self captureNavigationContinuity];', 0, search_end)
search_cancel = search[search_start:search_end]
harness=r'''
#import <Cocoa/Cocoa.h>
#import "TGNavigationPositionStore.h"
#include <math.h>
static NSUInteger const TGStatusChatPreviewInitialLimit=50,TGStatusChatPreviewMaximumLimit=500;
static BOOL Aqua=YES;
static BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
static NSString *TGLoc(NSString *key) { return key; }
static NSUInteger const TGMessagePreviewInitialLimit=20,TGMessagePrefillMaxAttempts=3;
static BOOL TGStatusErrorLooksOffline(NSString *message) { (void)message;return NO; }
static NSMutableArray *WorkerBlocks,*MainBlocks;
static void ProbeDispatch(dispatch_queue_t queue,dispatch_block_t block) {
 id copied=[block copy];[(queue==dispatch_get_main_queue() ? MainBlocks : WorkerBlocks) addObject:copied];[copied release];
}
static void RunOne(NSMutableArray *queue) { dispatch_block_t block=[[queue objectAtIndex:0] copy];[queue removeObjectAtIndex:0];block();[block release]; }
@interface TGLogger : NSObject
+ (id)sharedLogger;
- (void)log:(NSString *)text;
@end
@implementation TGLogger
+ (id)sharedLogger { static TGLogger *logger; if(!logger) logger=[[self alloc] init];return logger; }
- (void)log:(NSString *)text { (void)text; }
@end
static NSUInteger checks;
static void Check(BOOL yes,const char *message) { checks++;if(!yes) { fprintf(stderr,"Navigation continuity: %s\n",message);exit(1); } }
static void Near(CGFloat actual,CGFloat expected,const char *message) { if(fabs(actual-expected)>=0.05) fprintf(stderr,"actual=%f expected=%f\n",actual,expected);Check(fabs(actual-expected)<0.05,message); }
@interface TGChatItem : NSObject {
 NSNumber *_chatID,*_parentChatID,*_messageThreadID,*_messageID;NSString *_messageTopicKind;BOOL _isForumTopic;
}
@property(nonatomic,retain) NSNumber *chatID,*parentChatID,*messageThreadID,*messageID;
@property(nonatomic,copy) NSString *messageTopicKind;
@property(nonatomic) BOOL isForumTopic;
@end
@implementation TGChatItem
@synthesize chatID=_chatID,parentChatID=_parentChatID,messageThreadID=_messageThreadID,messageID=_messageID,messageTopicKind=_messageTopicKind,isForumTopic=_isForumTopic;
- (void)dealloc { [_chatID release];[_parentChatID release];[_messageThreadID release];[_messageID release];[_messageTopicKind release];[super dealloc]; }
@end
@interface TGMessageItem : TGChatItem @end
@implementation TGMessageItem @end
@interface TGTDLibClient : NSObject {
 NSArray *_aroundItems,*_latestItems;NSMutableArray *_requestedAnchors;BOOL _aroundError;NSUInteger _latestCalls;NSString *_authorizationState;
}
@property(nonatomic,retain) NSArray *aroundItems,*latestItems;
@property(nonatomic,retain) NSMutableArray *requestedAnchors;
@property(nonatomic) BOOL aroundError;
@property(nonatomic) NSUInteger latestCalls;
@property(nonatomic,copy) NSString *authorizationState;
- (NSArray *)messagePreviewItemsForChatID:(NSNumber *)chat messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind aroundMessageID:(NSNumber *)anchor newerMessageCount:(NSUInteger)newer limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error;
- (NSArray *)recentMessagePreviewItemsForChatID:(NSNumber *)chat messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error;
- (NSString *)currentAuthorizationStatePreparingIfNeededWithTimeout:(NSTimeInterval)timeout error:(NSError **)error;
@end
@implementation TGTDLibClient
@synthesize aroundItems=_aroundItems,latestItems=_latestItems,requestedAnchors=_requestedAnchors,aroundError=_aroundError,latestCalls=_latestCalls,authorizationState=_authorizationState;
- (id)init { if((self=[super init])) _requestedAnchors=[[NSMutableArray alloc] init];return self; }
- (void)dealloc { [_aroundItems release];[_latestItems release];[_requestedAnchors release];[_authorizationState release];[super dealloc]; }
- (NSArray *)messagePreviewItemsForChatID:(NSNumber *)chat messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind aroundMessageID:(NSNumber *)anchor newerMessageCount:(NSUInteger)newer limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error {
 (void)chat;(void)thread;(void)kind;(void)newer;(void)limit;(void)timeout;[_requestedAnchors addObject:anchor];
 if(_aroundError) { if(error) *error=[NSError errorWithDomain:@"synthetic" code:400 userInfo:nil];return nil; }return _aroundItems;
}
- (NSArray *)recentMessagePreviewItemsForChatID:(NSNumber *)chat messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error {
 (void)chat;(void)thread;(void)kind;(void)limit;(void)timeout;(void)error;_latestCalls++;return _latestItems;
}
- (NSString *)currentAuthorizationStatePreparingIfNeededWithTimeout:(NSTimeInterval)timeout error:(NSError **)error { (void)timeout;(void)error;return _authorizationState ? _authorizationState : @"ready"; }
@end
@interface NavigationProbe : NSObject <NSTableViewDataSource> {
__IVARS__
}
__PROPERTIES__
@end
@implementation NavigationProbe
__SYNTH__
- (void)dealloc { __RELEASES__ [super dealloc]; }
- (NSInteger)numberOfRowsInTableView:(NSTableView *)table { return (NSInteger)[(table==self.chatTableView ? self.chatItems : self.messageItems) count]; }
- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row { (void)table;(void)column;(void)row;return @""; }
- (BOOL)isMessageHistoryNearBottom { NSClipView *clip=[self.messageScrollView contentView];return NSMaxY([clip bounds])>=NSHeight([self.messageTableView bounds])-25; }
- (void)updateMessageJumpToNewestButtonVisibility { self.jumpUpdates++; }
#include "TGStatusWindowController+NavigationContinuity.inc"
- (void)beginExplicitSearchJump {
__SEARCH_CANCEL__
}
- (BOOL)acceptsClient:(NSObject *)client chat:(NSNumber *)chatIDCopy thread:(NSNumber *)messageThreadIDCopy kind:(NSString *)messageTopicKindCopy generation:(NSUInteger)navigationPresentationGeneration anchor:(NSNumber *)navigationAnchorCopy key:(NSString *)navigationKeyCopy {
BOOL navigationInitialRestore=navigationAnchorCopy!=nil,navigationContinuingRestore=NO;
__GUARDS__
 return selectionStillCurrent && !cancelledRestore;
}
- (void)appendDetail:(NSString *)text { (void)text; }
- (void)setControlsBusy:(BOOL)value { (void)value; }
- (void)updateVisibleSection {}
- (void)scheduleVisibleMessageItemsRead {}
- (void)setOfflineModeActive:(BOOL)value reason:(NSString *)reason { (void)value;(void)reason; }
- (BOOL)messageHistoryNeedsPrefill { return NO; }
- (void)prefillOlderMessagesIfNeededWithAttemptsRemaining:(NSUInteger)attempts { (void)attempts; }
- (void)handlePendingLiveRefreshesIfPossible {}
- (void)consumePendingComposerRefocus:(id)sender { (void)sender; }
- (void)updateAuthControlsForState:(NSString *)state { self.currentAuthState=state; }
- (void)scrollMessagesToNewestIfAvailable {}
- (void)performSelector:(SEL)selector withObject:(id)object afterDelay:(NSTimeInterval)delay { (void)selector;(void)object;(void)delay; }
- (void)applyRecentMessageItems:(NSArray *)items preservingOlderItems:(BOOL)preserve {
 self.applyCount++;self.lastAppliedItems=items;self.lastPreserveOlder=preserve;
 if(!preserve) [self.messageItems removeAllObjects];
 for(TGMessageItem *item in items) {
  BOOL found=NO;for(TGMessageItem *old in self.messageItems) if([[old messageID] isEqual:[item messageID]]) found=YES;
  if(!found) [self.messageItems addObject:item];
 }
 [self.messageTableView reloadData];self.forceMessageScrollToNewest=NO;
 if(!preserve) [self restoreNavigationTranscriptIfPending];
}
#define dispatch_async(queue, ...) ProbeDispatch(queue, (__VA_ARGS__))
__RELOAD_METHOD__
#undef dispatch_async
__JUMP_METHOD__
@end
static TGChatItem *Chat(NSInteger i) { TGChatItem *item=[[[TGChatItem alloc] init] autorelease];item.chatID=[NSNumber numberWithInteger:i];return item; }
static TGMessageItem *Message(NSInteger i) { TGMessageItem *item=[[[TGMessageItem alloc] init] autorelease];item.messageID=[NSNumber numberWithInteger:i];return item; }
static void Prepare(NavigationProbe *p) {
 p.profileUserID=@1;p.selectedChatID=@12;p.currentAuthState=@"ready";p.client=[[[TGTDLibClient alloc] init] autorelease];
 p.chatItems=[NSMutableArray array];p.messageItems=[NSMutableArray array];
 for(NSInteger i=0;i<40;i++) { [p.chatItems addObject:Chat(100+i)];[p.messageItems addObject:Message(200+i)]; }
 for(NSUInteger t=0;t<2;t++) {
  NSScrollView *scroll=[[[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,240,180)] autorelease];
  [scroll setBorderType:NSNoBorder];[scroll setHasVerticalScroller:NO];
  NSTableView *table=[[[NSTableView alloc] initWithFrame:NSMakeRect(0,0,240,1600)] autorelease];
  [table setHeaderView:nil];[table setRowHeight:40];[table setIntercellSpacing:NSMakeSize(0,2)];
  [table addTableColumn:[[[NSTableColumn alloc] initWithIdentifier:@"content"] autorelease]];
  if(t==0) { p.chatScrollView=scroll;p.chatTableView=table; } else { p.messageScrollView=scroll;p.messageTableView=table; }
  [table setDataSource:p];[scroll setDocumentView:table];[table reloadData];[table tile];
 }
 p.chatsLabel=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
 p.selectedChatField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
 p.topicBackButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
 NSButton *all=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[all setTag:-1];[all setTitle:@"Все чаты"];
 NSButton *work=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[work setTag:3];[work setTitle:@"Работа"];
 p.drawerFolderButtons=[NSArray arrayWithObjects:all,work,nil];
}
static NSDictionary *Position(id anchor,double offset,double origin,BOOL end) { return [NSDictionary dictionaryWithObjectsAndKeys:anchor,@"anchor",[NSNumber numberWithDouble:offset],@"offset",[NSNumber numberWithDouble:origin],@"origin",[NSNumber numberWithBool:end],@"nearEnd",nil]; }
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 TGNavigationPositionStore *store=[[[TGNavigationPositionStore alloc] init] autorelease];
 NSMutableSet *keys=[NSMutableSet set];
 for(NSInteger account=1;account<=2;account++) for(NSInteger folder=0;folder<3;folder++) for(NSInteger forum=0;forum<3;forum++) {
  NSString *key=TGNavigationListPositionKey([NSNumber numberWithInteger:account],folder==1 ? @3:nil,folder==2,forum ? [NSNumber numberWithInteger:forum]:nil);
  Check(key && ![keys containsObject:key],"list keys isolate account, folder, archive and forum");[keys addObject:key];
 }
 for(NSInteger account=1;account<=2;account++) for(NSInteger chat=1;chat<=2;chat++) for(NSInteger thread=0;thread<=2;thread++) for(NSString *kind in [NSArray arrayWithObjects:@"forum",@"thread",nil]) {
  NSString *key=TGNavigationTranscriptPositionKey([NSNumber numberWithInteger:account],[NSNumber numberWithInteger:chat],thread ? [NSNumber numberWithInteger:thread]:nil,kind);
  Check(key && ![keys containsObject:key],"transcript keys isolate account, chat, thread and kind");[keys addObject:key];
 }
 Check(!TGNavigationListPositionKey(nil,nil,NO,nil) && !TGNavigationTranscriptPositionKey(@1,@0,nil,nil),"anonymous/invalid selection has no state");
 [store savePosition:Position(@7,3,80,NO) forKey:@"a"];[store armKey:@"a" transcript:YES];
 [store armKey:store.pendingTranscriptKey transcript:YES];Check([store.pendingTranscriptKey isEqual:@"a"],"rearming aliased pending key is safe under MRC");
 Check(![store consumePositionForKey:@"other" transcript:YES],"wrong context cannot consume pending restore");
 Check([[[store consumePositionForKey:@"a" transcript:YES] objectForKey:@"anchor"] isEqual:@7] && !store.pendingTranscriptKey,"restore consumed once");
 [store savePosition:Position(@8,0,200,YES) forKey:@"end"];[store armKey:@"end" transcript:YES];Check(!store.pendingTranscriptKey,"latest readers retain normal unread/latest routing");
 [store savePosition:Position(@9,NAN,0,NO) forKey:@"bad"];Check(![store positionForKey:@"bad"],"nonfinite geometry rejected");
 [store armKey:@"a" transcript:YES];for(NSUInteger i=0;i<65;i++) [store savePosition:Position(@1,0,0,NO) forKey:[NSString stringWithFormat:@"entry%lu",(unsigned long)i]];
 Check(![store positionForKey:@"a"] && ![store positionForKey:@"entry0"] && [store positionForKey:@"entry64"] && !store.pendingTranscriptKey,"bounded eviction also invalidates pending anchors");
 [store clear];Check(![store positionForKey:@"entry64"],"account/logout clears all state");
 NSMutableDictionary *large=[NSMutableDictionary dictionaryWithDictionary:Position(@1,0,0,NO)];[large setObject:@300 forKey:@"loadedCount"];
 [store savePosition:large forKey:@"count"];Check([[[store positionForKey:@"count"] objectForKey:@"loadedCount"] unsignedIntegerValue]==300,"paginated list count retained");
 [large setObject:@9999 forKey:@"loadedCount"];[store savePosition:large forKey:@"count"];Check([[[store positionForKey:@"count"] objectForKey:@"loadedCount"] unsignedIntegerValue]==500,"pagination restore remains capped at product maximum");
 NavigationProbe *p=[[[NavigationProbe alloc] init] autorelease];Prepare(p);
 NSClipView *list=[p.chatScrollView contentView],*transcript=[p.messageScrollView contentView];
 CGFloat listY=NSMinY([p.chatTableView rectOfRow:10])+7;
 [list scrollToPoint:NSMakePoint(0,listY)];[p captureNavigationChatList];NSString *listKey=[[p navigationChatListKey] copy];
 Check([[[p.navigationPositionStore positionForKey:listKey] objectForKey:@"anchor"] isEqual:@"chat:110"],"real list viewport captures first visible semantic row");
 NSMutableDictionary *paged=[NSMutableDictionary dictionaryWithDictionary:[p.navigationPositionStore positionForKey:listKey]];[paged setObject:@300 forKey:@"loadedCount"];[p.navigationPositionStore savePosition:paged forKey:listKey];[p armNavigationChatListRestore];
 Check([p navigationChatListRestoreLimit]==300,"folder reentry requests enough rows for anchor beyond initial50");
 CGFloat folderOffset=35-NSMinY([p.chatTableView rectOfRow:0]);p.selectedChatFilterID=@3;[list scrollToPoint:NSMakePoint(0,35)];[p captureNavigationChatList];p.selectedChatFilterID=nil;
 [p.chatItems insertObject:Chat(900) atIndex:0];[p.chatTableView reloadData];[p armNavigationChatListRestore];[list scrollToPoint:NSZeroPoint];[p captureNavigationChatList];[p restoreNavigationChatListIfPending];
 Near([list bounds].origin.y,NSMinY([p.chatTableView rectOfRow:11])+7,"return survives reordered rows and ignores programmatic incoming selection capture");
 [p.chatItems removeObjectAtIndex:11];[p.chatTableView reloadData];[p armNavigationChatListRestore];[p restoreNavigationChatListIfPending];Near([list bounds].origin.y,listY,"deleted list anchor falls back to saved bounded origin");
 p.selectedChatFilterID=@3;[p armNavigationChatListRestore];[p restoreNavigationChatListIfPending];Near([list bounds].origin.y,NSMinY([p.chatTableView rectOfRow:1])+folderOffset,"folder viewports remain independent");
 p.showingForumTopicList=YES;p.topicParentChatID=@12;p.topicParentTitle=@"Группа";p.selectedChatTitle=@"Общение";[p refreshNavigationBreadcrumb];
 Check([[p.selectedChatField toolTip] isEqual:@"Работа › Группа › Общение"] && [[p.topicBackButton toolTip] rangeOfString:@"Работа"].location!=NSNotFound,"existing header controls expose folder/group/topic path");
 p.showingForumTopicList=NO;p.topicParentTitle=nil;p.selectedChatFilterID=nil;
 CGFloat messageY=NSMinY([p.messageTableView rectOfRow:15])+11;
 [transcript scrollToPoint:NSMakePoint(0,messageY)];[p captureNavigationTranscript];[p armNavigationTranscriptRestore];
 Check([[p navigationPendingTranscriptAnchor] isEqual:@215],"history return requests exact semantic message anchor");
 [p.messageItems insertObject:Message(199) atIndex:0];[p.messageTableView reloadData];[transcript scrollToPoint:NSZeroPoint];p.initialUnreadPositionPending=YES;
 Check([p restoreNavigationTranscriptIfPending] && !p.initialUnreadPositionPending && p.jumpUpdates==1,"restored history replaces initial unread positioning only after matching anchor exists");
 Near([transcript bounds].origin.y,NSMinY([p.messageTableView rectOfRow:16])+11,"message restoration preserves intra-row offset after history insertion");
 NSString *transcriptKey=[p navigationTranscriptKey];
 p.messageItemsRepresentFocusedContext=YES;[p.navigationPositionStore markRestoredTranscriptKey:transcriptKey generation:0];
 CGFloat laterY=NSMinY([p.messageTableView rectOfRow:20])+4;[transcript scrollToPoint:NSMakePoint(0,laterY)];[p captureNavigationTranscript];
 Check([[[p.navigationPositionStore positionForKey:transcriptKey] objectForKey:@"anchor"] isEqual:@219],"scrolling restored around-anchor history updates next return anchor");
 [p beginExplicitSearchJump];[transcript scrollToPoint:NSMakePoint(0,10)];[p captureNavigationTranscript];
 Check([[[p.navigationPositionStore positionForKey:transcriptKey] objectForKey:@"anchor"] isEqual:@219],"explicit search focus cannot overwrite normal history anchor");
 [p armNavigationTranscriptRestore];Check(!p.messageItemsRepresentFocusedContext,"switching from search/restored history clears previous focus before requesting new anchor");NSObject *client=p.client;
 Check([p acceptsClient:client chat:@12 thread:nil kind:nil generation:p.messageLoadingGeneration anchor:@219 key:transcriptKey],"matching async anchored reply accepted");
 Check(![p acceptsClient:[[[NSObject alloc] init] autorelease] chat:@12 thread:nil kind:nil generation:p.messageLoadingGeneration anchor:@219 key:transcriptKey],"previous account client cannot apply async history");
 Check(![p acceptsClient:client chat:@12 thread:@2 kind:@"forum" generation:p.messageLoadingGeneration anchor:@219 key:transcriptKey],"old topic reply cannot apply to parent history");
 Check(![p acceptsClient:client chat:@12 thread:nil kind:nil generation:p.messageLoadingGeneration+1 anchor:@219 key:transcriptKey],"explicit search supersedes in-flight history reply");
 [p forgetNavigationTranscriptPosition];p.forceMessageScrollToNewest=YES;
 Check(![p navigationPendingTranscriptAnchor] && ![p restoreNavigationTranscriptIfPending] && ![p acceptsClient:client chat:@12 thread:nil kind:nil generation:p.messageLoadingGeneration anchor:@219 key:transcriptKey],"explicit latest cancels both viewport restore and late anchored reply");
 p.forceMessageScrollToNewest=NO;[p.navigationPositionStore savePosition:Position(@999,0,200,NO) forKey:transcriptKey];[p armNavigationTranscriptRestore];
 Check(![p restoreNavigationTranscriptIfPending],"deleted message falls through to normal unread/latest behavior");
 [p captureNavigationTranscript];[p armNavigationTranscriptRestore];[p clearNavigationContinuity];Check(![p navigationPendingTranscriptAnchor] && ![p.navigationPositionStore isRestoredTranscriptKey:transcriptKey generation:p.searchGeneration],"account reset clears pending and restored provenance");
 // Execute the complete production TDLib request/completion method without network.
 WorkerBlocks=[[NSMutableArray alloc] init];MainBlocks=[[NSMutableArray alloc] init];
 TGTDLibClient *backend=[[[TGTDLibClient alloc] init] autorelease];
 NavigationProbe *r=[[[NavigationProbe alloc] init] autorelease];Prepare(r);r.client=backend;
 NSArray *history=[NSArray arrayWithObjects:Message(10),Message(11),Message(12),Message(13),Message(14),Message(15),Message(16),Message(17),Message(18),Message(19),Message(20),nil];
 backend.aroundItems=history;backend.latestItems=[NSArray arrayWithObjects:Message(9000),Message(9001),nil];
 NSString *returnKey=[r navigationTranscriptKey];
 [r.preparedNavigationPositionStore savePosition:Position(@12,3,94,NO) forKey:returnKey];
 r.messageItemsRepresentFocusedContext=YES;[r armNavigationTranscriptRestore];[r.messageItems removeAllObjects];[r.messageTableView reloadData];
 [r reloadMessagesForChatID:r.selectedChatID interactive:NO];RunOne(WorkerBlocks);
 Check([[backend.requestedAnchors lastObject] isEqual:@12],"whole reload requests saved anchor after switching from focused page");
 r.searchGeneration+=3;RunOne(MainBlocks);
 Check(r.applyCount==1 && r.messageItemsRepresentFocusedContext && [r navigationRestoredHistoryIsActive],"opening/typing/closing search does not discard initial history response");
 NSUInteger latestBefore=backend.latestCalls;
 [r reloadMessagesForChatID:r.selectedChatID interactive:NO];RunOne(WorkerBlocks);RunOne(MainBlocks);
 Check(backend.latestCalls==latestBefore && [backend.requestedAnchors count]==2 && r.messageItemsRepresentFocusedContext,"next live poll refreshes visible historical page rather than latest gap");
 for(TGMessageItem *item in r.messageItems) Check([[item messageID] integerValue]<100,"restored history never merges far latest messages");
 r.searchGeneration+=4;Check([r navigationRestoredHistoryIsActive],"query-only changes preserve restored provenance");
 [r captureNavigationTranscript];Check(![[[r.navigationPositionStore positionForKey:returnKey] objectForKey:@"nearEnd"] boolValue],"end of historical slice is not latest end of chat");
 [r reloadMessagesForChatID:r.selectedChatID interactive:NO];RunOne(WorkerBlocks);NSUInteger before=r.applyCount;
 [r beginExplicitSearchJump];r.messageLoadingGeneration++;RunOne(MainBlocks);
 Check(r.applyCount==before && ![r navigationRestoredHistoryIsActive],"actual explicit search jump supersedes queued historical poll");
 // A same-client account swap must reject an already completed worker result.
 r.messageItemsRepresentFocusedContext=NO;[r.navigationPositionStore savePosition:Position(@12,0,0,NO) forKey:returnKey];[r armNavigationTranscriptRestore];
 backend.authorizationState=@"closing";[r reloadMessagesForChatID:r.selectedChatID interactive:NO];RunOne(WorkerBlocks);before=r.applyCount;r.profileUserID=@2;RunOne(MainBlocks);
 Check(r.applyCount==before && [r.currentAuthState isEqual:@"ready"],"same client and same chat IDs cannot apply previous account history or auth state");r.profileUserID=@1;
 [r armNavigationTranscriptRestore];[r reloadMessagesForChatID:r.selectedChatID interactive:NO];RunOne(WorkerBlocks);r.client=[[[TGTDLibClient alloc] init] autorelease];RunOne(MainBlocks);
 Check([r.currentAuthState isEqual:@"ready"],"old client callback cannot replace current authorization state");r.client=backend;backend.authorizationState=@"ready";
 // Initial deleted/missing anchors fall back once, including TDLib 400 errors.
 for(NSUInteger errorCase=0;errorCase<2;errorCase++) {
  [r.navigationPositionStore savePosition:Position(@777,0,0,NO) forKey:returnKey];r.messageItemsRepresentFocusedContext=YES;[r armNavigationTranscriptRestore];
  [r.messageItems removeAllObjects];[r.messageTableView reloadData];backend.aroundError=errorCase!=0;
  [r reloadMessagesForChatID:r.selectedChatID interactive:NO];RunOne(WorkerBlocks);RunOne(MainBlocks);
  Check(!r.messageItemsRepresentFocusedContext && !r.navigationPositionStore.pendingTranscriptKey && !r.lastPreserveOlder && [r.messageItems count]==2,"deleted/errored saved anchor falls back to normal latest without focused flag");
 }
 backend.aroundError=NO;
 // Ongoing historical refresh errors keep the visible page without latest fetch.
 [r.messageItems removeAllObjects];[r.messageItems addObjectsFromArray:history];[r.messageTableView reloadData];r.messageItemsRepresentFocusedContext=YES;
 [r.navigationPositionStore markRestoredTranscriptKey:returnKey generation:0];backend.aroundError=YES;latestBefore=backend.latestCalls;before=r.applyCount;
 [r reloadMessagesForChatID:r.selectedChatID interactive:NO];RunOne(WorkerBlocks);RunOne(MainBlocks);
 Check(r.applyCount==before && backend.latestCalls==latestBefore && r.messageItemsRepresentFocusedContext,"ongoing history error preserves cached focused page");backend.aroundError=NO;
 // Latest cancels an ongoing history request and replaces, rather than merges.
 [r reloadMessagesForChatID:r.selectedChatID interactive:NO];RunOne(WorkerBlocks);before=r.applyCount;[r jumpToNewestMessages:nil];RunOne(MainBlocks);
 Check(r.applyCount==before && r.pendingLiveMessageRefresh,"latest cancels queued around-anchor completion");
 r.pendingLiveMessageRefresh=NO;[r reloadMessagesForChatID:r.selectedChatID interactive:NO];RunOne(WorkerBlocks);RunOne(MainBlocks);
 Check(!r.lastPreserveOlder && !r.messageItemsRepresentFocusedContext && [r.messageItems count]==2 && [[[r.messageItems objectAtIndex:0] messageID] isEqual:@9000],"explicit latest replaces ancient page without disjoint merge");
 Check(![WorkerBlocks count] && ![MainBlocks count],"all synthetic production async callbacks drained");[WorkerBlocks release];[MainBlocks release];
 Aqua=NO;[p captureNavigationContinuity];[p armNavigationTranscriptRestore];Check(!p.navigationPositionStore.pendingTranscriptKey,"Classic does not acquire navigation restore state");
 [listKey release];printf("Navigation continuity PASS: %lu checks, semantic isolation, actual viewports and production async guards.\n",(unsigned long)checks);
 [pool drain];return 0;
}
'''
for token,value in [('__IVARS__',ivars),('__PROPERTIES__',properties),('__SYNTH__',synth),('__RELEASES__',releases),('__GUARDS__',guards),('__SEARCH_CANCEL__',search_cancel),('__RELOAD_METHOD__',reload_method),('__JUMP_METHOD__',jump_method)]:
    harness=harness.replace(token,value)
folder=tempfile.mkdtemp(prefix='telegraphica-navigation-')
try:
    path=os.path.join(folder,'probe.m')
    binary=os.path.join(folder,'probe')
    with open(path,'wb') as stream: stream.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),path,os.path.join(ROOT,'Sources/UI/TGNavigationPositionStore.m'),'-framework','Cocoa','-o',binary])
    subprocess.check_call([binary])
finally:
    shutil.rmtree(folder)
