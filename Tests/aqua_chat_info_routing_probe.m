#import <Cocoa/Cocoa.h>
#import "TGAquaChatInfoPanel.h"
#import "TGAquaShellViews.h"
#import "TGStatusViewComponents.h"
#import "TGLocalization.h"
#import "TGMediaCenterLayout.h"
#include <unistd.h>
#include <assert.h>

static BOOL TGMediaCenterSelectionUsesGrid(NSInteger index) { return index==0 || index==5; }
static BOOL Aqua=YES;
static NSString *TGSectionChats=@"chats";
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
BOOL TGInterfaceAnimationsEnabledForView(NSView *view) { (void)view;return NO; }
NSColor *TGColorFromHex(NSUInteger hex) { return [NSColor colorWithCalibratedRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1]; }
void TGDrawTemplateIconAsset(NSString *name,NSRect rect,NSColor *ink,CGFloat alpha,BOOL flipped) { (void)name;(void)rect;(void)ink;(void)alpha;(void)flipped; }
@implementation TGNavigationButtonCell
@synthesize badgeText=_badgeText,iconOnly=_iconOnly;
- (void)dealloc { [_badgeText release];[super dealloc]; }
@end
@implementation TGProfileAvatarView
@synthesize displayName=_displayName,avatarLocalPath=_avatarLocalPath;
- (void)dealloc { [_displayName release];[_avatarLocalPath release];[super dealloc]; }
@end

@interface TGTDLibClient : NSObject
@end
@implementation TGTDLibClient
- (NSDictionary *)chatSummaryForChatID:(NSNumber *)chatID downloadAvatar:(BOOL)avatar timeout:(NSTimeInterval)timeout error:(NSError **)error {
    (void)chatID;(void)avatar;(void)timeout;(void)error;
    return [NSDictionary dictionaryWithObject:[@"W" stringByPaddingToLength:128 withString:@"W" startingAtIndex:0] forKey:@"title"];
}
- (NSDictionary *)chatDetailsSummaryForChatID:(NSNumber *)chatID timeout:(NSTimeInterval)timeout error:(NSError **)error {
    (void)chatID;(void)timeout;(void)error;
    [NSThread sleepForTimeInterval:0.05];
    return [NSDictionary dictionaryWithObjectsAndKeys:@"private",@"kind",[NSDictionary dictionaryWithObject:@"biography" forKey:@"bio"],@"profile",nil];
}
@end
@interface TGChatInfoWindowController : NSWindowController
- (id)initWithClient:(id)client chatID:(NSNumber *)chatID title:(NSString *)title;
- (void)reloadChatInfo;
@end
@implementation TGChatInfoWindowController
- (id)initWithClient:(id)client chatID:(NSNumber *)chatID title:(NSString *)title { (void)client;(void)chatID;(void)title;return [super initWithWindow:nil]; }
- (void)reloadChatInfo {}
@end

@interface PanelSpy : TGAquaChatInfoPanel { @public NSUInteger renders; }
@end
@implementation PanelSpy
- (void)showSummary:(NSDictionary *)summary loading:(BOOL)loading error:(NSString *)errorMessage { renders++;[super showSummary:summary loading:loading error:errorMessage]; }
@end

@interface InfoRouting : NSObject {
    TGTDLibClient *_client;
    NSString *_currentAuthState,*_activeSection,*_selectedChatTitle,*_selectedChatAvatarLocalPath;
    NSNumber *_selectedChatID,*_aquaChatInfoChatID;
    TGAquaChatInfoPanel *_aquaChatInfoPanel;
    TGChatInfoWindowController *_chatInfoWindowController;
    NSView *_sidebarPanelView,*_conversationPanelView;
    NSWindow *_window;
    NSUInteger _aquaChatInfoRequestGeneration;
    NSInteger _mediaCenterSelectedTabIndex;
    BOOL _chatNavigationClosed,_mediaCenterVisible;
    NSUInteger _mediaCenterGeneration;
    NSView *_mediaCenterPanelView,*_mediaCenterContentCardView,*_mediaCenterAvatarView,*_mediaCenterResultsView;
    NSButton *_mediaCenterBackButton,*_mediaCenterRefreshButton;
    NSTextField *_mediaCenterTitleField,*_mediaCenterSubtitleField,*_mediaCenterStatusField;
    NSArray *_mediaCenterTabButtons,*_mediaCenterItems;
    NSScrollView *_mediaCenterScrollView;
    NSProgressIndicator *_mediaCenterLoadingSpinner;
    @public NSUInteger refocus,openedMedia,loadedTab,ensuredMedia;
}
@property(nonatomic,retain) TGTDLibClient *client;
@property(nonatomic,copy) NSString *currentAuthState,*activeSection,*selectedChatTitle,*selectedChatAvatarLocalPath;
@property(nonatomic,retain) NSNumber *selectedChatID,*aquaChatInfoChatID;
@property(nonatomic,retain) TGAquaChatInfoPanel *aquaChatInfoPanel;
@property(nonatomic,retain) TGChatInfoWindowController *chatInfoWindowController;
@property(nonatomic,retain) NSView *sidebarPanelView,*conversationPanelView;
@property(nonatomic,retain) NSWindow *window;
@property(nonatomic,assign) NSUInteger aquaChatInfoRequestGeneration;
@property(nonatomic,assign) NSInteger mediaCenterSelectedTabIndex;
@property(nonatomic,assign) BOOL chatNavigationClosed,mediaCenterVisible;
@property(nonatomic,assign) NSUInteger mediaCenterGeneration;
@property(nonatomic,retain) NSView *mediaCenterPanelView,*mediaCenterContentCardView,*mediaCenterAvatarView,*mediaCenterResultsView;
@property(nonatomic,retain) NSButton *mediaCenterBackButton,*mediaCenterRefreshButton;
@property(nonatomic,retain) NSTextField *mediaCenterTitleField,*mediaCenterSubtitleField,*mediaCenterStatusField;
@property(nonatomic,retain) NSArray *mediaCenterTabButtons,*mediaCenterItems;
@property(nonatomic,retain) NSScrollView *mediaCenterScrollView;
@property(nonatomic,retain) NSProgressIndicator *mediaCenterLoadingSpinner;
- (void)layoutContentView;
- (void)updateVisibleSection;
- (void)requestComposerRefocus;
- (void)openMediaCenter:(id)sender;
- (void)ensureMediaCenterWindow;
- (void)updateMediaCenterTabButtonStates;
- (void)closeMediaCenterInlinePreview:(id)sender;
- (void)reloadMediaCenter:(id)sender;
- (NSInteger)mediaCenterCurrentTabIndex;
@end
@implementation InfoRouting
@synthesize client=_client,currentAuthState=_currentAuthState,activeSection=_activeSection,selectedChatTitle=_selectedChatTitle,selectedChatAvatarLocalPath=_selectedChatAvatarLocalPath;
@synthesize selectedChatID=_selectedChatID,aquaChatInfoChatID=_aquaChatInfoChatID,aquaChatInfoPanel=_aquaChatInfoPanel,chatInfoWindowController=_chatInfoWindowController;
@synthesize sidebarPanelView=_sidebarPanelView,conversationPanelView=_conversationPanelView,window=_window,aquaChatInfoRequestGeneration=_aquaChatInfoRequestGeneration;
@synthesize mediaCenterSelectedTabIndex=_mediaCenterSelectedTabIndex,chatNavigationClosed=_chatNavigationClosed,mediaCenterVisible=_mediaCenterVisible;
@synthesize mediaCenterGeneration=_mediaCenterGeneration,mediaCenterPanelView=_mediaCenterPanelView,mediaCenterContentCardView=_mediaCenterContentCardView,mediaCenterAvatarView=_mediaCenterAvatarView,mediaCenterResultsView=_mediaCenterResultsView;
@synthesize mediaCenterBackButton=_mediaCenterBackButton,mediaCenterRefreshButton=_mediaCenterRefreshButton,mediaCenterTitleField=_mediaCenterTitleField,mediaCenterSubtitleField=_mediaCenterSubtitleField,mediaCenterStatusField=_mediaCenterStatusField;
@synthesize mediaCenterTabButtons=_mediaCenterTabButtons,mediaCenterItems=_mediaCenterItems,mediaCenterScrollView=_mediaCenterScrollView,mediaCenterLoadingSpinner=_mediaCenterLoadingSpinner;
- (void)dealloc {
    [_aquaChatInfoPanel setTarget:nil];[_aquaChatInfoPanel hideImmediately];
    [_client release];[_currentAuthState release];[_activeSection release];[_selectedChatTitle release];[_selectedChatAvatarLocalPath release];
    [_selectedChatID release];[_aquaChatInfoChatID release];[_aquaChatInfoPanel release];[_chatInfoWindowController release];
    [_mediaCenterPanelView release];[_mediaCenterContentCardView release];[_mediaCenterAvatarView release];[_mediaCenterResultsView release];
    [_mediaCenterBackButton release];[_mediaCenterRefreshButton release];[_mediaCenterTitleField release];[_mediaCenterSubtitleField release];[_mediaCenterStatusField release];
    [_mediaCenterTabButtons release];[_mediaCenterItems release];[_mediaCenterScrollView release];[_mediaCenterLoadingSpinner release];
    [_sidebarPanelView release];[_conversationPanelView release];[_window release];[super dealloc];
}
- (void)layoutContentView {
    NSRect available=NSMakeRect(206,0,NSWidth([[self.window contentView] bounds])-206,560);
    TGAquaChatInfoGeometry g=TGAquaChatInfoFrames(available,[self isAquaChatInfoPanelActive]);
    [self.conversationPanelView setFrame:g.conversation];
}
- (void)updateVisibleSection { [self updateAquaChatInfoPanelVisibility]; }
- (void)requestComposerRefocus { refocus++; }
- (void)openMediaCenter:(id)sender { (void)sender;openedMedia++;loadedTab=(NSUInteger)self.mediaCenterSelectedTabIndex;self.mediaCenterVisible=YES;[self updateVisibleSection]; }
// Data/control fixtures only: the actual production profile-host layout and
// in-place results reflow are included below, rather than replaced by spies.
- (void)ensureMediaCenterWindow {
    ensuredMedia++;
    if(self.mediaCenterPanelView) return;
    self.mediaCenterPanelView=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,900,600)] autorelease];
    self.mediaCenterContentCardView=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,900,600)] autorelease];
    self.mediaCenterAvatarView=[[[NSView alloc] initWithFrame:NSMakeRect(10,540,48,48)] autorelease];
    self.mediaCenterBackButton=[[[NSButton alloc] initWithFrame:NSMakeRect(10,500,80,30)] autorelease];
    self.mediaCenterRefreshButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    self.mediaCenterTitleField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    self.mediaCenterSubtitleField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    self.mediaCenterStatusField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [self.mediaCenterStatusField setStringValue:@"A long loading status that wraps in the narrow unified profile host."];
    self.mediaCenterScrollView=[[[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,850,400)] autorelease];
    [self.mediaCenterScrollView setHasVerticalScroller:YES];
    self.mediaCenterResultsView=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,850,600)] autorelease];
    [self.mediaCenterScrollView setDocumentView:self.mediaCenterResultsView];
    self.mediaCenterLoadingSpinner=[[[NSProgressIndicator alloc] initWithFrame:NSZeroRect] autorelease];
    NSMutableArray *tabs=[NSMutableArray array];
    for(NSUInteger i=0;i<8;i++) {
        NSButton *button=[[[NSButton alloc] initWithFrame:NSMakeRect(10+i*40,450,36,30)] autorelease];
        [tabs addObject:button];[self.mediaCenterPanelView addSubview:button];
    }
    self.mediaCenterTabButtons=tabs;self.mediaCenterItems=[NSArray arrayWithObject:@"fixture media"];
    for(NSUInteger i=0;i<5;i++) [self.mediaCenterResultsView addSubview:[[[NSView alloc] initWithFrame:NSMakeRect(8,8+i*90,800,82)] autorelease]];
    for(NSView *view in [NSArray arrayWithObjects:self.mediaCenterContentCardView,self.mediaCenterAvatarView,self.mediaCenterBackButton,self.mediaCenterRefreshButton,self.mediaCenterTitleField,self.mediaCenterSubtitleField,self.mediaCenterStatusField,self.mediaCenterScrollView,self.mediaCenterLoadingSpinner,nil]) [self.mediaCenterPanelView addSubview:view];
}
- (void)closeMediaCenterInlinePreview:(id)sender { (void)sender; }
- (void)reloadMediaCenter:(id)sender { (void)sender;openedMedia++;loadedTab=(NSUInteger)self.mediaCenterSelectedTabIndex; }
- (NSInteger)mediaCenterCurrentTabIndex { return self.mediaCenterSelectedTabIndex; }
- (void)updateMediaCenterTabButtonStates {}
#include "TGStatusWindowController+AquaChatInfo.inc"
@end

static void Spin(void) { NSDate *end=[NSDate dateWithTimeIntervalSinceNow:0.20];while([end timeIntervalSinceNow]>0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]; }
int main(void) {
    alarm(30);NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    InfoRouting *host=[[[InfoRouting alloc] init] autorelease];
    host.window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1080,620) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [host.window setReleasedWhenClosed:NO];
    host.client=[[[TGTDLibClient alloc] init] autorelease];host.currentAuthState=@"ready";host.activeSection=TGSectionChats;
    host.selectedChatID=[NSNumber numberWithInt:10];host.selectedChatTitle=@"initial title";
    host.sidebarPanelView=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,200,560)] autorelease];
    host.conversationPanelView=[[[NSView alloc] initWithFrame:NSMakeRect(206,0,874,560)] autorelease];
    PanelSpy *spy=[[[PanelSpy alloc] initWithFrame:NSZeroRect] autorelease];host.aquaChatInfoPanel=spy;[spy setTarget:host];
    NSUInteger flows=0;
    [host openAquaChatInfo:nil];assert([host isAquaChatInfoPanelActive] && ![host aquaChatInfoReplacesConversation]);
    NSUInteger initial=spy->renders;Spin();assert(spy->renders==initial+1);flows++;
    [host closeAquaChatInfo:nil];assert(!host.aquaChatInfoChatID && [spy isHidden] && host->refocus==1);flows++;
    // Closing before the fetch completes cannot resurrect the profile.
    [host openAquaChatInfo:nil];initial=spy->renders;[host closeAquaChatInfo:nil];Spin();assert(spy->renders==initial && !host.aquaChatInfoChatID);flows++;
    // A->B and A->B->A responses remain scoped to the actual request.
    [host openAquaChatInfo:nil];initial=spy->renders;host.selectedChatID=[NSNumber numberWithInt:11];[host updateVisibleSection];
    host.selectedChatID=[NSNumber numberWithInt:10];Spin();assert(spy->renders==initial && !host.aquaChatInfoChatID);flows++;
    [host openAquaChatInfo:nil];initial=spy->renders;host.activeSection=@"settings";[host updateVisibleSection];Spin();assert(spy->renders==initial && [spy isHidden]);host.activeSection=TGSectionChats;flows++;
    [host openAquaChatInfo:nil];initial=spy->renders;[host invalidateAquaChatInfoPanel];host.client=[[[TGTDLibClient alloc] init] autorelease];Spin();assert(spy->renders==initial);flows++;
    [host openAquaChatInfo:nil];initial=spy->renders;host.currentAuthState=@"waitPhoneNumber";[host updateVisibleSection];Spin();assert(spy->renders==initial && [spy isHidden]);host.currentAuthState=@"ready";flows++;
    [host.window setContentSize:NSMakeSize(760,620)];[host layoutContentView];
    [host openAquaChatInfo:nil];assert([host aquaChatInfoReplacesConversation]);Spin();[host closeAquaChatInfo:nil];assert(![host aquaChatInfoReplacesConversation]);flows++;
    [host openAquaChatInfo:nil];
    NSUInteger profileGeneration=host.aquaChatInfoRequestGeneration;
    NSNumber *profileChat=host.aquaChatInfoChatID;
    NSView *identity=[spy valueForKey:@"avatarView"];
    initial=spy->renders;
    // Select media while the same profile request is still in flight: its
    // eventual summary may enrich the identity without reverting the tab.
    for(NSInteger tab=0;tab<8;tab++) {
        NSButton *button=[[[NSButton alloc] init] autorelease];[button setTag:tab];
        NSUInteger mediaGeneration=host.mediaCenterGeneration;
        [host openAquaChatInfoMedia:button];
        assert([host isAquaChatInfoPanelActive] && host.aquaChatInfoChatID==profileChat);
        assert(host.aquaChatInfoRequestGeneration==profileGeneration);
        assert(host.mediaCenterVisible && host.mediaCenterSelectedTabIndex==tab && [spy selectedMediaTab]==tab);
        assert(host->loadedTab==(NSUInteger)tab && host.mediaCenterGeneration==mediaGeneration+1);
        assert([host.mediaCenterPanelView superview]==[spy mediaHostView]);
        assert(NSEqualRects([host.mediaCenterPanelView frame],[[spy mediaHostView] bounds]));
        assert([host.mediaCenterScrollView documentView]==host.mediaCenterResultsView);
        assert([spy valueForKey:@"avatarView"]==identity && ![identity isHidden]);
        for(NSView *oldHeader in [NSArray arrayWithObjects:host.mediaCenterContentCardView,host.mediaCenterBackButton,host.mediaCenterAvatarView,host.mediaCenterTitleField,host.mediaCenterSubtitleField,nil]) assert([oldHeader isHidden]);
        for(NSView *oldTab in host.mediaCenterTabButtons) assert([oldTab isHidden]);
        assert(NSContainsRect([host.mediaCenterPanelView bounds],[host.mediaCenterScrollView frame]));
        assert(NSContainsRect([host.mediaCenterPanelView bounds],[host.mediaCenterRefreshButton frame]));
        assert(NSWidth([host.mediaCenterResultsView frame])==floor(NSWidth([[host.mediaCenterScrollView contentView] bounds])));
        if(tab==0) {
            CGFloat loadingBodyHeight=NSHeight([host.mediaCenterPanelView bounds]);
            Spin();assert(spy->renders==initial+1 && [spy selectedMediaTab]==tab);
            NSRect body=[host.mediaCenterPanelView bounds];
            // A legal 128-character enriched title grows the fixed identity
            // header. The active media controls must follow its new body now,
            // without another user tab action or window resize.
            assert(NSHeight(body)!=loadingBodyHeight);
            assert(NSHeight([host.mediaCenterScrollView frame])==MAX(0,NSHeight(body)-52));
            assert(NSContainsRect(body,[host.mediaCenterStatusField frame]));
            assert(NSContainsRect(body,[host.mediaCenterRefreshButton frame]));
        }
        flows++;
    }
    assert(host->openedMedia==8 && host->ensuredMedia==8);
    // Exercise the real embedded-media layout again across wide/narrow host
    // changes, preserving existing row identities and clip notification policy.
    NSArray *rows=[[host.mediaCenterResultsView subviews] copy];
    NSClipView *clip=[host.mediaCenterScrollView contentView];
    [clip setPostsBoundsChangedNotifications:YES];
    for(NSNumber *width in [NSArray arrayWithObjects:@1080,@760,@1280,nil]) {
        [host.window setContentSize:NSMakeSize([width doubleValue],620)];
        [host layoutContentView];[host updateVisibleSection];
        assert([[host.mediaCenterResultsView subviews] isEqualToArray:rows]);
        assert([clip postsBoundsChangedNotifications]);
        assert([host.mediaCenterPanelView superview]==[spy mediaHostView]);
        assert(NSEqualRects([host.mediaCenterPanelView frame],[[spy mediaHostView] bounds]));
        assert(NSContainsRect([host.mediaCenterPanelView bounds],[host.mediaCenterScrollView frame]));
        assert(NSWidth([host.mediaCenterResultsView frame])==floor(NSWidth([clip bounds])));
        assert(host.aquaChatInfoChatID==profileChat && host.aquaChatInfoRequestGeneration==profileGeneration);
    }
    [rows release];flows++;
    NSButton *info=[[[NSButton alloc] init] autorelease];[info setTag:-1];
    NSUInteger reloads=host->openedMedia;
    [host openAquaChatInfoMedia:info];
    assert([host isAquaChatInfoPanelActive] && host.aquaChatInfoChatID==profileChat && host.aquaChatInfoRequestGeneration==profileGeneration);
    assert(!host.mediaCenterVisible && [host.mediaCenterPanelView isHidden] && [spy selectedMediaTab]==-1);
    assert(host->openedMedia==reloads && ![[spy valueForKey:@"scrollView"] isHidden]);flows++;
    // Closing the unified profile invalidates the existing media-generation token.
    [info setTag:4];[host openAquaChatInfoMedia:info];
    NSUInteger mediaGeneration=host.mediaCenterGeneration;[host closeAquaChatInfo:nil];
    assert(!host.aquaChatInfoChatID && !host.mediaCenterVisible && host.mediaCenterGeneration>mediaGeneration && [host.mediaCenterPanelView isHidden]);flows++;
    Aqua=NO;[host openAquaChatInfo:nil];assert(!host.aquaChatInfoChatID);flows++;
    [host.window close];
    printf("Aqua profile production routing: %lu async/lifecycle flows, client/chat/section/auth invalidation, narrow restoration and all eight exact embedded media routes and Info return without profile invalidation, fixed identity and hidden legacy chrome PASS.\n",(unsigned long)flows);
    alarm(0);[pool drain];return 0;
}
