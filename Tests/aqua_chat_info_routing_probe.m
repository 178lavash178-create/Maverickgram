#import <Cocoa/Cocoa.h>
#import "TGAquaChatInfoPanel.h"
#import "TGAquaShellViews.h"
#import "TGStatusViewComponents.h"
#import "TGLocalization.h"
#include <assert.h>

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
    return [NSDictionary dictionaryWithObject:@"fetched title" forKey:@"title"];
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
- (void)layoutContentView;
- (void)updateVisibleSection;
- (void)requestComposerRefocus;
- (void)openMediaCenter:(id)sender;
- (void)ensureMediaCenterWindow;
- (void)updateMediaCenterTabButtonStates;
@end
@implementation InfoRouting
@synthesize client=_client,currentAuthState=_currentAuthState,activeSection=_activeSection,selectedChatTitle=_selectedChatTitle,selectedChatAvatarLocalPath=_selectedChatAvatarLocalPath;
@synthesize selectedChatID=_selectedChatID,aquaChatInfoChatID=_aquaChatInfoChatID,aquaChatInfoPanel=_aquaChatInfoPanel,chatInfoWindowController=_chatInfoWindowController;
@synthesize sidebarPanelView=_sidebarPanelView,conversationPanelView=_conversationPanelView,window=_window,aquaChatInfoRequestGeneration=_aquaChatInfoRequestGeneration;
@synthesize mediaCenterSelectedTabIndex=_mediaCenterSelectedTabIndex,chatNavigationClosed=_chatNavigationClosed,mediaCenterVisible=_mediaCenterVisible;
- (void)dealloc {
    [_aquaChatInfoPanel setTarget:nil];[_aquaChatInfoPanel hideImmediately];
    [_client release];[_currentAuthState release];[_activeSection release];[_selectedChatTitle release];[_selectedChatAvatarLocalPath release];
    [_selectedChatID release];[_aquaChatInfoChatID release];[_aquaChatInfoPanel release];[_chatInfoWindowController release];
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
- (void)ensureMediaCenterWindow { ensuredMedia++; }
- (void)updateMediaCenterTabButtonStates {}
#include "TGStatusWindowController+AquaChatInfo.inc"
@end

static void Spin(void) { NSDate *end=[NSDate dateWithTimeIntervalSinceNow:0.20];while([end timeIntervalSinceNow]>0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]; }
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
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
    for(NSInteger tab=0;tab<4;tab++) {
        [host openAquaChatInfo:nil];NSButton *button=[[[NSButton alloc] init] autorelease];[button setTag:tab];
        [host openAquaChatInfoMedia:button];assert(!host.aquaChatInfoChatID && host.mediaCenterVisible && host->loadedTab==(NSUInteger)tab);
        initial=spy->renders;Spin();assert(spy->renders==initial);host.mediaCenterVisible=NO;flows++;
    }
    assert(host->openedMedia==4 && host->ensuredMedia==4);
    Aqua=NO;[host openAquaChatInfo:nil];assert(!host.aquaChatInfoChatID);flows++;
    [host.window close];
    printf("Aqua profile production routing: %lu async/lifecycle flows, client/chat/section/auth invalidation, narrow restoration and four exact shared media routes PASS.\n",(unsigned long)flows);
    [pool drain];return 0;
}
