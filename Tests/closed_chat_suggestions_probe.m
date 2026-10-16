#import <Cocoa/Cocoa.h>
#import "TGChatItem.h"
static BOOL Aqua = YES;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
NSString *TGLanguageCode(void) { return @"en"; }
NSString *TGLoc(NSString *key) { return key; }
NSColor *TGClassicInkColor(void) { return [NSColor blackColor]; }
NSColor *TGClassicMutedInkColor(void) { return [NSColor grayColor]; }
NSColor *TGClassicCardInkColor(void) { return [NSColor blackColor]; }
NSColor *TGClassicCardMutedInkColor(void) { return [NSColor grayColor]; }
@interface TGGroupedCardView : NSView
@property(nonatomic,assign) BOOL drawsInterior;
@end
@implementation TGGroupedCardView
@synthesize drawsInterior;
@end
@interface TGProfileAvatarView : NSView
@property(nonatomic,copy) NSString *displayName;
@property(nonatomic,copy) NSString *avatarLocalPath;
@end
@implementation TGProfileAvatarView
@synthesize displayName,avatarLocalPath;
- (void)dealloc { [displayName release]; [avatarLocalPath release]; [super dealloc]; }
@end
@interface Probe : NSObject
@property(nonatomic,assign) BOOL showingArchivedChats,showingForumTopicList,chatNavigationClosed,suppressChatSelectionHandling;
@property(nonatomic,retain) NSArray *closedChatRecentItems,*chatItemsBeforeTopicList,*chatItems,*closedChatSuggestionItems,*closedChatSuggestionViews;
@property(nonatomic,retain) TGGroupedCardView *closedChatPlaceholderView;
@property(nonatomic,retain) NSTextField *closedChatTitleField,*closedChatHintField;
@property(nonatomic,retain) NSTableView *chatTableView;
@property(nonatomic,retain) NSButton *closedChatEmptyActionButton;
@property(nonatomic,retain) NSNumber *selectedChatFilterID,*suppressedForumTopicAutoOpenChatID,*openedChatID;
@property(nonatomic,copy) NSString *currentAuthState;
@property(nonatomic,assign) NSUInteger selectedCount,layoutCount;
- (NSTextField *)labelWithFrame:(NSRect)frame text:(NSString *)text font:(NSFont *)font;
- (void)applyPointingHandCursorToButtonsInView:(NSView *)view;
- (void)updateAuthControlsForState:(NSString *)state;
- (void)updateVisibleSection;
- (void)layoutContentView;
- (NSUInteger)indexOfChatID:(NSNumber *)chatID inChatItems:(NSArray *)items;
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
- (void)chatLifecycleWindowController:(id)controller didOpenChatID:(NSNumber *)chatID title:(NSString *)title;
@end
@implementation Probe
@synthesize showingArchivedChats,showingForumTopicList,chatNavigationClosed,suppressChatSelectionHandling;
@synthesize closedChatRecentItems,chatItemsBeforeTopicList,chatItems,closedChatSuggestionItems,closedChatSuggestionViews;
@synthesize closedChatPlaceholderView,closedChatTitleField,closedChatHintField,chatTableView;
@synthesize selectedChatFilterID,closedChatEmptyActionButton,suppressedForumTopicAutoOpenChatID,openedChatID,currentAuthState,selectedCount,layoutCount;
- (NSTextField *)labelWithFrame:(NSRect)frame text:(NSString *)text font:(NSFont *)font {
    NSTextField *field=[[[NSTextField alloc] initWithFrame:frame] autorelease];
    [field setStringValue:text]; [field setFont:font]; [field setEditable:NO]; return field;
}
- (void)applyPointingHandCursorToButtonsInView:(NSView *)view { (void)view; }
- (void)updateAuthControlsForState:(NSString *)state { (void)state; }
- (void)updateVisibleSection { }
- (void)layoutContentView { self.layoutCount++; }
- (NSUInteger)indexOfChatID:(NSNumber *)chatID inChatItems:(NSArray *)items {
    for (NSUInteger i=0;i<[items count];i++) if ([[[items objectAtIndex:i] chatID] isEqual:chatID]) return i;
    return NSNotFound;
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification { (void)notification; self.selectedCount++; }
- (void)chatLifecycleWindowController:(id)controller didOpenChatID:(NSNumber *)chatID title:(NSString *)title {
    (void)controller; (void)title; self.openedChatID=chatID; self.chatNavigationClosed=NO;
}
#include "../Sources/UI/TGStatusWindowController+ClosedChatSuggestions.inc"
@end
static void Require(BOOL ok, const char *label) {
    if (!ok) { fprintf(stderr,"Closed chat suggestions: %s\n",label); exit(1); }
}
static TGChatItem *Item(long long value, NSString *kind) {
    return [[[TGChatItem alloc] initWithChatID:[NSNumber numberWithLongLong:value] title:[NSString stringWithFormat:@"Chat %lld",value] typeSummary:kind unreadCount:@0] autorelease];
}
static void CheckGeometry(Probe *probe, NSRect surface) {
    [probe layoutClosedChatPlaceholderViewInFrame:surface];
    Require(NSContainsRect(surface,[probe.closedChatPlaceholderView frame]),"card stays in conversation");
    NSUInteger visible=0;
    for (NSView *tile in probe.closedChatSuggestionViews) if (![tile isHidden]) {
        visible++;
        Require(NSContainsRect([probe.closedChatPlaceholderView bounds],[tile frame]),"tile fits card");
        Require(!NSIntersectsRect([tile frame],[probe.closedChatTitleField frame]),"tile clears title");
        Require(!NSIntersectsRect([tile frame],[probe.closedChatHintField frame]),"tile clears hint");
        for (NSView *other in probe.closedChatSuggestionViews) if (other!=tile && ![other isHidden])
            Require(!NSIntersectsRect([tile frame],[other frame]),"tiles do not overlap");
    }
    if ([probe.chatItems count] && NSWidth(surface)>=420 && NSHeight(surface)>=210)
        Require(visible>0,"available chats are visibly suggested");
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    Probe *p=[[[Probe alloc] init] autorelease];
    p.closedChatPlaceholderView=[[[TGGroupedCardView alloc] initWithFrame:NSZeroRect] autorelease];
    p.closedChatTitleField=[p labelWithFrame:NSZeroRect text:@"Chats are closed" font:[NSFont boldSystemFontOfSize:15]];
    p.closedChatHintField=[p labelWithFrame:NSZeroRect text:@"Choose a recent chat" font:[NSFont systemFontOfSize:12]];
    [p.closedChatPlaceholderView addSubview:p.closedChatTitleField]; [p.closedChatPlaceholderView addSubview:p.closedChatHintField];
    p.chatNavigationClosed=YES; p.currentAuthState=@"ready"; p.chatItems=[NSArray array];
    CheckGeometry(p,NSMakeRect(270,52,420,340));
    Require([p.closedChatSuggestionViews count]==0,"empty initial list");
    Require(![p.closedChatEmptyActionButton isHidden] && [p.closedChatEmptyActionButton action]==@selector(openChatSearchWindow:),"empty account offers Search chats");
    p.showingArchivedChats=YES;
    CheckGeometry(p,NSMakeRect(270,52,420,340));
    Require([p.closedChatEmptyActionButton action]==@selector(folderFilterChanged:) && [p.closedChatEmptyActionButton tag]==-1,"cold empty Archive offers All chats");
    Require(NSContainsRect([p.closedChatPlaceholderView bounds],[p.closedChatEmptyActionButton frame]),"empty action fits compact card");
    Require(NSHeight([p.closedChatPlaceholderView frame])==174,"empty card is compact");
    p.showingArchivedChats=NO;
    NSMutableArray *items=[NSMutableArray array];
    TGChatItem *topic=Item(99,@"Private"); topic.forumTopic=YES;
    [items addObject:topic]; [items addObject:Item(0,@"Private")];
    [items addObject:Item(-1,@"Group")];
    for (NSUInteger i=1;i<=7;i++) [items addObject:Item(i,@"Private")];
    [items addObject:Item(1,@"Private")];
    p.chatItems=items;
    // No Esc/rebuild call: later list arrival must populate on normal layout.
    CheckGeometry(p,NSMakeRect(270,52,420,340));
    Require([p.closedChatSuggestionViews count]==8,"late list populates eight unique valid chats");
    Require([[[p.closedChatSuggestionItems objectAtIndex:0] chatID] longLongValue]==1,"private chats precede groups");
    Require([[[p.closedChatSuggestionItems lastObject] chatID] longLongValue]==-1,"groups remain fallback");
    NSArray *originalViews=p.closedChatSuggestionViews;
    [p layoutClosedChatPlaceholderViewInFrame:NSMakeRect(270,52,420,340)];
    Require(originalViews==p.closedChatSuggestionViews,"unchanged layout does not rebuild views");
    TGChatItem *first=[p.closedChatSuggestionItems objectAtIndex:0]; first.title=@"Renamed";
    first.avatarLocalPath=@"/nonexistent/avatar.png";
    [p layoutClosedChatPlaceholderViewInFrame:NSMakeRect(270,52,420,340)];
    NSArray *children=[[p.closedChatSuggestionViews objectAtIndex:0] subviews];
    Require([[[children objectAtIndex:1] stringValue] isEqual:@"Renamed"],"mutable title refreshed");
    Require([[[children objectAtIndex:0] avatarLocalPath] isEqual:first.avatarLocalPath],"mutable avatar refreshed");
    for (NSUInteger count=1;count<=8;count++) {
        p.chatItems=[items subarrayWithRange:NSMakeRange(3,count)];
        CGFloat widths[]={320,420,600}; CGFloat heights[]={210,280,340,600};
        for(NSUInteger w=0;w<3;w++) for(NSUInteger h=0;h<4;h++) CheckGeometry(p,NSMakeRect(10,20,widths[w],heights[h]));
    }
    p.chatItems=[NSArray arrayWithObject:Item(123,@"Private")];
    [p rememberAquaClosedChatRecentItemsFromItems:p.chatItems];
    p.showingArchivedChats=YES; p.chatItems=[NSArray array];
    [p rememberAquaClosedChatRecentItemsFromItems:p.chatItems];
    CheckGeometry(p,NSMakeRect(270,52,420,340));
    Require([p.closedChatSuggestionItems count]==1 && [[[p.closedChatSuggestionItems objectAtIndex:0] chatID] longLongValue]==123,"empty Archive uses already loaded main chats");
    Require([p.closedChatEmptyActionButton isHidden],"snapshot suggestions replace empty action");
    p.showingArchivedChats=NO; p.selectedChatFilterID=@10;
    [p rememberAquaClosedChatRecentItemsFromItems:[NSArray arrayWithObject:Item(999,@"Private")]];
    Require([[[[p closedChatSuggestionSourceItems] objectAtIndex:0] chatID] longLongValue]==123,"empty custom folder retains main-list snapshot");
    p.selectedChatFilterID=nil;
    [p clearClosedChatSuggestionsForSessionChange];
    Require(!p.closedChatRecentItems && !p.closedChatSuggestionItems && !p.closedChatSuggestionViews,"session reset discards snapshot and views");
    Require([[p closedChatSuggestionSourceItems] count]==0,"no previous-account suggestions");
    [p rememberAquaClosedChatRecentItemsFromItems:[NSArray arrayWithObject:Item(456,@"Private")]];
    [p rememberAquaClosedChatRecentItemsFromItems:[NSArray array]];
    Require([p.closedChatRecentItems count]==0,"authoritatively empty main list clears old snapshot");
    p.showingForumTopicList=YES; p.chatItemsBeforeTopicList=[NSArray arrayWithObject:Item(55,@"Private")];
    p.chatItems=[NSArray arrayWithObject:topic];
    Require([[[[p closedChatSuggestionSourceItems] objectAtIndex:0] chatID] longLongValue]==55,"forum uses parent chat list");
    p.showingForumTopicList=NO;
    p.chatItems=[NSArray arrayWithObject:Item(77,@"Private")];
    p.suppressChatSelectionHandling=YES;
    Require([p restoreAquaClosedChatPlaceholderAfterChatListUpdate],"closed state consumes stale selection completion");
    Require(p.chatNavigationClosed && p.selectedCount==0 && p.suppressChatSelectionHandling,"late list preserves closed and suppression state");
    Require([[[p.closedChatSuggestionItems objectAtIndex:0] chatID] longLongValue]==77,"late completion refreshes suggestions");
    NSButton *button=[[[NSButton alloc] init] autorelease]; [button setTag:0];
    p.chatItems=[NSArray array]; [p openClosedChatSuggestion:button];
    Require([p.openedChatID longLongValue]==77 && !p.chatNavigationClosed,"stale tile opens actual chat through existing navigation");
    Aqua=NO; p.chatNavigationClosed=YES; NSUInteger oldLayouts=p.layoutCount;
    Require(![p restoreAquaClosedChatPlaceholderAfterChatListUpdate] && p.layoutCount==oldLayouts,"Classic selection behavior untouched");
    p.chatItems=[NSArray arrayWithObject:Item(88,@"Private")]; [p rebuildClosedChatSuggestions];
    [p layoutClosedChatPlaceholderViewInFrame:NSMakeRect(0,0,600,400)];
    Require(NSEqualSizes([p.closedChatPlaceholderView frame].size,NSMakeSize(500,190)),"Classic card geometry preserved");
    puts("Closed chat suggestions PASS: late list, empty Archive/folder fallback, cold empty actions, session reset, state guard, filters, avatars, 96 layouts, stale click, Classic");
    [pool drain]; return 0;
}
