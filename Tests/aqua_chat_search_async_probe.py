#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real chat-search callbacks: debounce invalidation, lifecycle and account scope."""
from __future__ import print_function
import os, shutil, subprocess, sys, tempfile
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
def read(path):
    with open(os.path.join(ROOT,path),'rb') as handle: return handle.read().decode('utf-8')
def method(source,first,last):
    start=source.index(first); return source[start:source.index(last,start)]
source=read('Sources/UI/TGStatusWindowController+ChatSearchWindow.inc')
actual='\n'.join([
    method(source,'- (void)closeChatSearchWindow:','- (void)clearChatSearchWindowResultButtons'),
    method(source,'- (void)updateChatSearchWindowResults {','- (void)chatSearchWindowTextCommitted:'),
    method(source,'- (void)chatSearchWindowResultActivated:','- (BOOL)control:')])
aqua=read('Sources/UI/TGStatusWindowController+AquaChatSearch.inc')
context=method(aqua,'- (NSDictionary *)aquaChatSearchContext {','- (void)invalidateAquaChatSearchPresentation')
harness=r'''
#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import "TGChatItem.h"
#import "TGSearchResultItem.h"
static BOOL Aqua=YES;
static NSString *TGSectionChats=@"chats";
static NSMutableArray *Workers,*Mains,*Debounces;
static NSUInteger Checks;
static void Require(BOOL value,const char *why){Checks++;if(!value){fprintf(stderr,"Chat-search async: %s\n",why);exit(1);}}
BOOL TGInterfaceDesignIsAqua(void){return Aqua;}
NSString *TGLoc(NSString *key){return key;}
NSString *TGLocalizedChatTypeSummary(NSString *type){return type;}
static void Queue(dispatch_queue_t queue,dispatch_block_t block){id copy=[block copy];[(queue==dispatch_get_main_queue()?Mains:Workers) addObject:copy];[copy release];}
static void Run(NSMutableArray *queue){Require([queue count]>0,"expected pending callback");dispatch_block_t block=[[queue objectAtIndex:0] copy];[queue removeObjectAtIndex:0];block();[block release];}
@interface SearchSchedulingAdapter:NSObject
+ (void)cancelPreviousPerformRequestsWithTarget:(id)target selector:(SEL)selector object:(id)object;
@end
@implementation SearchSchedulingAdapter
+ (void)cancelPreviousPerformRequestsWithTarget:(id)target selector:(SEL)selector object:(id)object{
 (void)object;for(NSInteger i=(NSInteger)[Debounces count]-1;i>=0;i--){NSDictionary *entry=[Debounces objectAtIndex:(NSUInteger)i];if([[entry objectForKey:@"target"] pointerValue]==target && [[entry objectForKey:@"selector"] isEqual:NSStringFromSelector(selector)])[Debounces removeObjectAtIndex:(NSUInteger)i];}
}
@end
@interface TGLogger:NSObject
+ (id)sharedLogger;
- (void)log:(NSString *)text;
@end
@implementation TGLogger
+ (id)sharedLogger{static TGLogger *logger=nil;if(!logger)logger=[[self alloc] init];return logger;}
- (void)log:(NSString *)text{(void)text;}
@end
@interface TGTDLibClient:NSObject
@property(nonatomic,retain) NSArray *answer;
@property(nonatomic) NSUInteger calls;
@property(nonatomic,copy) NSString *lastQuery;
@end
@implementation TGTDLibClient
@synthesize answer=_answer,calls=_calls,lastQuery=_lastQuery;
- (NSArray *)searchChatPreviewItemsWithQuery:(NSString *)query limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error{(void)limit;(void)timeout;(void)error;self.calls++;self.lastQuery=query;return self.answer;}
- (NSArray *)mainChatPreviewItemsWithLimit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error{(void)limit;(void)timeout;(void)error;self.calls++;self.lastQuery=@"recent";return self.answer;}
- (void)dealloc{[_answer release];[_lastQuery release];[super dealloc];}
@end
@interface ProbeWindow:NSObject
@property(nonatomic) BOOL key,shown;
- (BOOL)isShown;
- (BOOL)isKeyWindow;
- (void)orderOut:(id)sender;
@end
@implementation ProbeWindow
@synthesize key=_key,shown=_shown;
- (BOOL)isShown{return _shown;}
- (BOOL)isKeyWindow{return _key;}
- (void)orderOut:(id)sender{(void)sender;_shown=NO;_key=NO;}
@end
@interface TGChatSearchPanelView:NSObject
@property(nonatomic,copy) NSString *query,*statusText;
@property(nonatomic,copy) NSArray *results;
@property(nonatomic) NSUInteger renders;
@property(nonatomic) NSInteger selectedIndex;
- (TGSearchResultItem *)selectedResult;
@end
@implementation TGChatSearchPanelView
@synthesize query=_query,statusText=_statusText,results=_results,renders=_renders,selectedIndex=_selectedIndex;
- (void)setResults:(NSArray *)value{[_results release];_results=[value copy];_selectedIndex=-1;_renders++;}
- (TGSearchResultItem *)selectedResult{return _selectedIndex>=0 && (NSUInteger)_selectedIndex<[_results count]?[_results objectAtIndex:(NSUInteger)_selectedIndex]:nil;}
- (void)layoutPanelSubviews{}
- (void)setNeedsDisplay:(BOOL)needed{(void)needed;}
- (void)displayIfNeeded{}
- (void)dealloc{[_query release];[_statusText release];[_results release];[super dealloc];}
@end
@interface SearchRoot:NSObject
@property(nonatomic,retain) TGTDLibClient *client;
@property(nonatomic,retain) NSNumber *profileUserID;
@property(nonatomic,copy) NSString *activeSection,*currentAuthState;
@property(nonatomic,retain) NSMutableDictionary *state;
@property(nonatomic,retain) TGChatSearchPanelView *panel;
@property(nonatomic,retain) NSMutableArray *chatSearchWindowResults;
@property(nonatomic,copy) NSArray *chatItems,*chatItemsBeforeTopicList,*local;
@property(nonatomic) BOOL showingForumTopicList;
@property(nonatomic) NSUInteger chatSearchGeneration,jumps;
@property(nonatomic,retain) ProbeWindow *chatSearchWindow;
@property(nonatomic,retain) id sendTextField;
@end
@implementation SearchRoot
@synthesize client=_client,profileUserID=_profileUserID,activeSection=_activeSection,currentAuthState=_currentAuthState,state=_state,panel=_panel,chatSearchWindowResults=_chatSearchWindowResults,chatItems=_chatItems,chatItemsBeforeTopicList=_chatItemsBeforeTopicList,local=_local,showingForumTopicList=_showingForumTopicList,chatSearchGeneration=_chatSearchGeneration,jumps=_jumps,chatSearchWindow=_chatSearchWindow,sendTextField=_sendTextField;
- (void)dealloc{[_client release];[_profileUserID release];[_activeSection release];[_currentAuthState release];[_state release];[_panel release];[_chatSearchWindowResults release];[_chatItems release];[_chatItemsBeforeTopicList release];[_local release];[_chatSearchWindow release];[_sendTextField release];[super dealloc];}
- (NSMutableDictionary *)aquaChatSearchState{return self.state;}
- (void)buildChatSearchWindowIfNeeded{}
- (TGChatSearchPanelView *)chatSearchPanelView{return self.panel;}
- (NSArray *)localChatSearchResultsForQuery:(NSString *)query{(void)query;return self.local?self.local:[NSArray array];}
- (void)jumpToSearchResult:(TGSearchResultItem *)result{(void)result;self.jumps++;}
- (id)window{return nil;}
- (void)invalidateAquaChatSearchPresentation{[self finishAquaChatSearchDismissal];}
- (void)performSelector:(SEL)selector withObject:(id)object afterDelay:(NSTimeInterval)delay{(void)object;Require(delay==0.25,"production debounce interval retained");[Debounces addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithPointer:self],@"target",NSStringFromSelector(selector),@"selector",nil]];}
#define NSObject SearchSchedulingAdapter
#define dispatch_async Queue
__CONTEXT__
__METHODS__
#undef dispatch_async
#undef NSObject
@end
static TGChatItem *Chat(long long identifier,NSString *title){return [[[TGChatItem alloc] initWithChatID:[NSNumber numberWithLongLong:identifier] title:title typeSummary:@"Private" unreadCount:@0] autorelease];}
static SearchRoot *Prepare(void){SearchRoot *p=[[[SearchRoot alloc] init] autorelease];p.client=[[[TGTDLibClient alloc] init] autorelease];p.profileUserID=@1;p.activeSection=TGSectionChats;p.currentAuthState=@"ready";p.panel=[[[TGChatSearchPanelView alloc] init] autorelease];p.panel.query=@"A";p.chatSearchWindowResults=[NSMutableArray array];p.chatItems=[NSArray array];p.chatSearchWindow=[[[ProbeWindow alloc] init] autorelease];p.chatSearchWindow.shown=YES;p.state=[NSMutableDictionary dictionary];[p.state setObject:p.chatSearchWindow forKey:@"popover"];[p.state setObject:[p aquaChatSearchContext] forKey:@"context"];return p;}
static void Debounce(SearchRoot *p){Require([Debounces count]==1,"one debounce survives rapid query edits");[Debounces removeAllObjects];[p updateChatSearchWindowResults];}
static void EmptyQueues(void){Require(![Workers count]&&![Mains count]&&![Debounces count],"all simulated queues drained");}
static void Pending(SearchRoot *p,BOOL recent){p.panel.query=recent?@"":@"A";p.client.answer=[NSArray arrayWithObject:Chat(11,@"Old")];[p updateChatSearchWindowResults];Require([Workers count]==1,"one server operation submitted");Run(Workers);Require([Mains count]==1,"server result can wait before UI completion");}
int main(void){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];Workers=[[NSMutableArray alloc] init];Mains=[[NSMutableArray alloc] init];Debounces=[[NSMutableArray alloc] init];
 SearchRoot *p=Prepare();Pending(p,NO);NSUInteger previous=p.chatSearchGeneration;p.panel.query=@"B";[p chatSearchWindowQueryChanged:nil];Require(p.chatSearchGeneration>previous,"typing invalidates old generation before debounce");Require(![p.chatSearchWindowResults count]&&![p.panel.results count],"backing and displayed old rows clear immediately");[p chatSearchWindowResultActivated:p.panel];Require(p.jumps==0,"old row cannot be keyboard-activated under new text");Run(Mains);Require(![p.panel.results count],"A reply during B debounce is rejected");
 p.client.answer=[NSArray arrayWithObject:Chat(22,@"B match")];Debounce(p);Run(Workers);Run(Mains);Require([p.panel.results count]==1&&[[[p.panel.results objectAtIndex:0] chatID] isEqual:@22]&&[p.client.lastQuery isEqual:@"B"],"new B reply is accepted after debounce");EmptyQueues();
 // Two fast edits replace the one pending debounce, without starting a request.
 p.panel.query=@"C";[p chatSearchWindowQueryChanged:nil];p.panel.query=@"D";[p chatSearchWindowQueryChanged:nil];Require([Debounces count]==1&&![Workers count],"rapid edits cancel the previous delayed request");[p closeChatSearchWindow:nil];Require(![Debounces count],"closing cancels deferred request before submission");EmptyQueues();
 for(NSUInteger recent=0;recent<2;recent++)for(NSUInteger mutation=0;mutation<7;mutation++){
  p=Prepare();Pending(p,recent);NSUInteger renders=p.panel.renders;
  if(mutation==0)[p closeChatSearchWindow:nil];
  else if(mutation==1)p.profileUserID=@2;
  else if(mutation==2)p.client=[[[TGTDLibClient alloc] init] autorelease];
  else if(mutation==3)p.currentAuthState=@"closed";
  else if(mutation==4)p.activeSection=@"settings";
  else if(mutation==5)[p.state setObject:[[[p aquaChatSearchContext] mutableCopy] autorelease] forKey:@"context"];
  else { [p finishAquaChatSearchDismissal];[p.state setObject:[p aquaChatSearchContext] forKey:@"context"]; }
  Run(Mains);Require(p.panel.renders==renders&&! [p.chatSearchWindowResults count],"query/recent reply cannot enter closed, replaced or stale account context");EmptyQueues();
 }
 p=Prepare();Pending(p,YES);p.panel.query=@"B";[p chatSearchWindowQueryChanged:nil];Run(Mains);Require(![p.panel.results count],"recent-chat response during a typed query debounce is rejected");[p closeChatSearchWindow:nil];EmptyQueues();
 p=Prepare();p.panel.query=@"";NSMutableArray *recent=[NSMutableArray array];for(NSUInteger i=0;i<18;i++)[recent addObject:Chat((long long)i+1,@"Recent")];p.client.answer=recent;[p updateChatSearchWindowResults];Run(Workers);Run(Mains);Require([p.panel.results count]==12&&[p.client.lastQuery isEqual:@"recent"],"current recent response is accepted with production twelve-row bound");EmptyQueues();
 // Local result remains first and deduplicates the same backend chat.
 p=Prepare();TGSearchResultItem *local=[[[TGSearchResultItem alloc] init] autorelease];local.chatID=@33;local.chatTitle=@"Local";p.local=[NSArray arrayWithObject:local];p.client.answer=[NSArray arrayWithObjects:Chat(33,@"Duplicate"),Chat(44,@"Server"),nil];[p updateChatSearchWindowResults];Run(Workers);Run(Mains);Require([p.panel.results count]==2&&[p.panel.results objectAtIndex:0]==local,"local merge order and identity deduplication preserved");EmptyQueues();
 // Classic has no Aqua context or popover; its standalone search still works.
 Aqua=NO;p=Prepare();p.state=nil;p.client.answer=[NSArray arrayWithObject:Chat(55,@"Classic")];[p updateChatSearchWindowResults];Run(Workers);Run(Mains);Require([p.panel.results count]==1&&[[[p.panel.results objectAtIndex:0] chatID] isEqual:@55],"Classic accepts normal standalone search without Aqua context");Pending(p,NO);NSUInteger renders=p.panel.renders;[p closeChatSearchWindow:nil];Run(Mains);Require(p.panel.renders==renders,"Classic close also rejects pending reply");EmptyQueues();
 [Workers release];[Mains release];[Debounces release];printf("Chat-search async: %lu production debounce, lifecycle, account and Classic checks PASS.\n",(unsigned long)Checks);[pool drain];return 0;}
'''
folder=tempfile.mkdtemp(prefix='telegraphica-chat-search-async-')
try:
    path=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(path,'wb') as handle:handle.write(harness.replace('__METHODS__',actual).replace('__CONTEXT__',context).encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/Core'),'-Wno-objc-method-access',path,os.path.join(ROOT,'Sources/Core/TGChatItem.m'),os.path.join(ROOT,'Sources/Core/TGSearchResultItem.m'),'-framework','Cocoa','-o',binary])
    subprocess.check_call([binary])
finally:shutil.rmtree(folder)
