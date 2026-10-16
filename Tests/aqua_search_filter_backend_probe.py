#!/usr/bin/env python
"""Real search callbacks: local filters, raw cursors and changed-criteria cancellation."""
from __future__ import print_function, unicode_literals
import os,re,shutil,subprocess,sys,tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
def read(path):
    with open(os.path.join(ROOT,path),'rb') as handle:return handle.read().decode('utf-8')
# Reuse the existing AppKit/model adapters, then replace its deliberately stubbed
# search backend with the production method. No test runner is executed here.
base_path=os.path.join(ROOT,'Tests/inline_search_navigation_probe.py')
base=read('Tests/inline_search_navigation_probe.py')
namespace={'__file__':base_path,'__name__':'gallery_search_fixture'}
eval(compile(base[:base.index("folder=tempfile.mkdtemp(")],base_path,'exec'),namespace)
harness=namespace['harness']
source=read('Sources/UI/TGStatusWindowController+SearchNavigation.inc')
def methods(first,last):
    start=source.index(first);return source[start:source.index(last,start)]
actual='\n'.join([
    methods('- (void)setSearchStatusText:','- (void)openSearchPanelGlobal:'),
    methods('- (BOOL)messageItem:','- (NSArray *)localChatSearchResultsForQuery:'),
    methods('- (void)performSearchReset:','- (void)activateSearchResult:')])
extra=r'''
- (NSArray *)localChatSearchResultsForQuery:(NSString *)query {(void)query;return [NSArray array];}
- (TGSearchResultItem *)searchResultForMessageItem:(TGMessageItem *)item chatTitle:(NSString *)title {
    TGSearchResultItem *result=[[[TGSearchResultItem alloc] init] autorelease];result.chatID=self.selectedChatID;result.messageID=item.messageID;result.chatTitle=title;return result;
}
'''
static=source[:source.index('- (NSString *)searchResultChatTitleForChatID:')]
harness=harness.replace('@interface InlineProbe :',static+'\n@interface InlineProbe :',1)
harness=harness.replace('@interface InlineProbe : NSObject <NSTableViewDataSource,NSTableViewDelegate> {','@interface InlineProbe : NSObject <NSTableViewDataSource,NSTableViewDelegate> {\n NSString *_globalSearchOffset;',1)
harness=harness.replace('- (NSUInteger)indexOfMessageID:', '@property(nonatomic,copy) NSString *globalSearchOffset;\n- (NSUInteger)indexOfMessageID:',1)
harness=harness.replace('@implementation InlineProbe\n','@implementation InlineProbe\n@synthesize globalSearchOffset=_globalSearchOffset;\n',1)
harness,count=re.subn(r'- \(void\)performSearchReset:\(BOOL\)reset \{[^\n]*\}',lambda match:extra+'\n#define dispatch_async(queue, ...) Dispatch(queue, (__VA_ARGS__))\n'+actual+'\n#undef dispatch_async',harness,count=1)
if count!=1:raise AssertionError('Expected exactly one search backend adapter to replace')
client=r'''
static NSNumber *RequestedAnchor;
@interface TGTDLibClient (SearchBackendProbe)
- (NSArray *)searchMessagePreviewItemsForChatID:(NSNumber *)chat messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind query:(NSString *)query filter:(NSString *)filter fromMessageID:(NSNumber *)anchor limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error;
- (NSArray *)globalSearchMessagePreviewItemsWithQuery:(NSString *)query filter:(NSString *)filter offset:(NSString **)offset limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error;
@end
@implementation TGTDLibClient (SearchBackendProbe)
- (NSArray *)searchMessagePreviewItemsForChatID:(NSNumber *)chat messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind query:(NSString *)query filter:(NSString *)filter fromMessageID:(NSNumber *)anchor limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error {
    (void)chat;(void)thread;(void)kind;(void)query;(void)filter;(void)limit;(void)timeout;(void)error;[RequestedAnchor release];RequestedAnchor=[anchor retain];return self.items;
}
- (NSArray *)globalSearchMessagePreviewItemsWithQuery:(NSString *)query filter:(NSString *)filter offset:(NSString **)offset limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error {
    (void)query;(void)filter;(void)limit;(void)timeout;(void)error;*offset=@"same-server-token";return self.items;
}
@end
'''
harness=harness.replace('@interface InlineProbe :',client+'\n@interface InlineProbe :',1)
main=r'''
static NSArray *Page(NSInteger first,BOOL firstMatches) {
    NSMutableArray *items=[NSMutableArray array];for(NSInteger i=0;i<30;i++) {
        TGMessageItem *item=Message(first-i);item.date=[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];item.senderDisplayName=(firstMatches&&i==0)?@"Alice":@"Bob";[items addObject:item];
    }return items;
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];Workers=[[NSMutableArray alloc] init];Mains=[[NSMutableArray alloc] init];
    InlineProbe *p=Prepare();p.searchInlineCurrentChatOnly=YES;p.client.items=Page(100,NO);p.searchSenderQuery=@"Bob";
    [p performSearchReset:YES];Run(Workers);
    [p ensureAquaSearchFilterControls];NSDictionary *filters=[p aquaSearchFilterState];[[filters objectForKey:@"sender"] setStringValue:@"Alice"];[[filters objectForKey:@"period"] addItemsWithTitles:[NSArray arrayWithObjects:@"Any",@"Today",@"Week",@"Month",@"Custom",nil]];[[filters objectForKey:@"period"] selectItemAtIndex:0];
    [p applyAquaSearchFilters:nil];Run(Mains);Require(p.searchLoading && ![p.searchResultItems count],"changed sender rejects old queued result without stopping newer search");Run(Workers);Run(Mains);
    Require(![p.searchResultItems count] && !p.searchEndReached && [[p searchPaginationAnchorMessageID] integerValue]==71,"filtered-empty first page retains raw last-message cursor and more state");
    NSDictionary *controls=objc_getAssociatedObject(p,&TGInlineSearchControlsKey);NSButton *next=[[controls objectForKey:@"buttons"] objectAtIndex:1];Require([next isEnabled],"zero local matches still exposes explicit continuation");
    p.client.items=Page(70,YES);[p nextInlineSearchResult:nil];Require([Workers count]==1,"Next requests another raw page when no filtered rows exist");Run(Workers);Run(Mains);
    Require([RequestedAnchor integerValue]==71 && [p.searchResultItems count]==1 && [[p searchPaginationAnchorMessageID] integerValue]==41,"pagination uses raw cursor rather than last visible filtered hit");
    // A custom-date edit invalidates a reply already dispatched to main.
    p.client.items=Page(100,YES);[p performSearchReset:YES];Run(Workers);
    [[filters objectForKey:@"period"] selectItemAtIndex:4];NSDate *future=[NSDate dateWithTimeIntervalSinceNow:86400*30];[[filters objectForKey:@"from"] setDateValue:future];[[filters objectForKey:@"to"] setDateValue:future];
    [p applyAquaSearchFilters:[filters objectForKey:@"from"]];Run(Mains);Require(p.searchLoading&&! [p.searchResultItems count],"custom date edit rejects previous criteria callback immediately");Run(Workers);Run(Mains);Require(![p.searchResultItems count]&&!p.searchEndReached,"custom date filtered-empty page can continue");
    [p resetAquaSearchFilters:nil];Run(Workers);Run(Mains);Require([p.searchResultItems count]==30,"Reset restores raw query matches");
    [p performSearchReset:NO];Run(Workers);Run(Mains);Require(p.searchEndReached,"repeated raw last-message cursor ends pagination rather than looping");
    p.searchInlineCurrentChatOnly=NO;[p.searchScopePopUpButton addItemsWithTitles:[NSArray arrayWithObjects:@"Chat",@"Everywhere",nil]];[p.searchScopePopUpButton selectItemAtIndex:1];[p performSearchReset:YES];Run(Workers);Run(Mains);Require(!p.searchEndReached,"first global response token permits continuation");[p performSearchReset:NO];Run(Workers);Run(Mains);Require(p.searchEndReached,"repeated global offset token ends pagination");
    [p.searchHighlightTimer invalidate];[p.searchDebounceTimer invalidate];Require(![Workers count]&&![Mains count],"all queued worker/main callbacks drained");[RequestedAnchor release];[Workers release];[Mains release];
    printf("Search filter backend: %lu actual callback/cursor/criteria checks PASS; no TDLib or account actions.\n",(unsigned long)Checks);[pool drain];return 0;
}
'''
harness=harness[:harness.index('int main(void) {')]+main
folder=tempfile.mkdtemp(prefix='telegraphica-search-filter-backend-')
try:
    path=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(path,'wb') as handle:handle.write(harness.encode('utf-8'))
    deps=['Sources/UI/TGKeyboardInputSupport.m','Sources/UI/TGAquaShellLayout.m','Sources/UI/TGNavigationPositionStore.m','Sources/UI/TGLocalization.m','Sources/Core/TGSearchResultItem.m']
    subprocess.check_call(sys.argv[1:]+['-I'+os.path.join(ROOT,'Sources/UI'),'-I'+os.path.join(ROOT,'Sources/Core'),path]+[os.path.join(ROOT,p) for p in deps]+['-framework','Cocoa','-o',binary]);subprocess.check_call([binary])
finally:shutil.rmtree(folder)
