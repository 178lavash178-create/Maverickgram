#!/usr/bin/env python
"""Exercise production shelf ownership and composer geometry without account/UI actions."""
from __future__ import print_function, unicode_literals
import os,shutil,subprocess,sys,tempfile
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
def read(path):
    with open(os.path.join(ROOT,path),'rb') as handle:return handle.read().decode('utf-8')
queue=read('Sources/UI/TGStatusWindowController+AquaQueuePresentation.inc')
layout=read('Sources/UI/TGStatusWindowController+SectionLayout.inc')
shell=read('Sources/UI/TGStatusWindowController+AquaShell.inc')
start=shell.index('    [content addSubview:self.aquaFooterView positioned:')
stacking=shell[start:shell.index('    TGAquaToolbarGeometry toolbar=',start)]
reservation=''
start=layout.index('    CGFloat sendButtonWidth = aqua ?')
composer=layout[start:layout.index('    [self.voiceRecordingIndicatorField setFrame:',start)]
harness=r'''
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
@interface NSObject (QueueDownloadMock)
- (void)closeCompactPopover;
@end
static BOOL Aqua=YES;
static NSString *TGSectionChats=@"chats";
BOOL TGInterfaceDesignIsAqua(void){return Aqua;}
NSString *TGLoc(NSString *key){return key;}
static void Check(BOOL value,const char *message){if(!value){fprintf(stderr,"Aqua queue integration: %s\n",message);exit(1);}}
@interface QueueWindow : NSObject { NSView *_content; }
- (NSView *)contentView;
@end
@implementation QueueWindow
- (id)init{self=[super init];if(self)_content=[[NSView alloc] initWithFrame:NSMakeRect(0,0,1200,800)];return self;}
- (NSView *)contentView{return _content;}
- (BOOL)makeFirstResponder:(id)responder{(void)responder;return YES;}
- (void)close{}
- (void)dealloc{[_content release];[super dealloc];}
@end
@interface TGScheduledMessagesWindowController : NSObject {
    id _client;NSNumber *_chatID;NSView *_shelf;QueueWindow *_window;
    NSUInteger _getterCalls,_invalidations,_reloads,_presentations,_hides;
}
@property(nonatomic,assign) NSUInteger getterCalls,invalidations,reloads;
@property(nonatomic,assign) NSUInteger presentations,hides;
- (id)initWithClient:(id)client chatID:(NSNumber *)chatID title:(NSString *)title;
- (NSView *)embeddedShelfView;
@end
@implementation TGScheduledMessagesWindowController
@synthesize getterCalls=_getterCalls,invalidations=_invalidations,reloads=_reloads;
@synthesize presentations=_presentations,hides=_hides;
- (id)initWithClient:(id)client chatID:(NSNumber *)chatID title:(NSString *)title{(void)title;self=[super init];if(self){_client=[client retain];_chatID=[chatID retain];_window=[[QueueWindow alloc] init];}return self;}
- (NSView *)embeddedShelfView{self.getterCalls++;if(!_shelf)_shelf=[[NSView alloc] initWithFrame:NSMakeRect(0,0,700,228)];return _shelf;}
- (void)invalidateEmbeddedShelf{self.invalidations++;[_shelf removeFromSuperview];}
- (void)presentEmbeddedShelfAnimated:(BOOL)animated{Check(animated,"first shelf presentation requests existing policy animation");Check([_shelf superview]!=nil,"presentation occurs after shelf attachment");self.presentations++;}
- (void)hideEmbeddedShelfImmediately{self.hides++;[_shelf setHidden:YES];}
- (BOOL)matchesClient:(id)client chatID:(NSNumber *)chatID{return _client==client&&[_chatID isEqual:chatID];}
- (CGFloat)preferredEmbeddedShelfHeight{return 228;}
- (void)setEmbeddedParentWindow:(id)window{(void)window;}
- (void)setShelfLayoutAction:(SEL)action{(void)action;}
- (void)setShelfCloseTarget:(id)target action:(SEL)action{(void)target;(void)action;}
- (void)reloadMessages{self.reloads++;}
- (id)window{return _window;}
- (void)dealloc{[_client release];[_chatID release];[_shelf release];[_window release];[super dealloc];}
@end
@interface QueueRoot : NSObject {
    TGScheduledMessagesWindowController *_scheduledMessagesWindowController;
    QueueWindow *_window;id _client,_downloadManagerWindowController;
    NSNumber *_selectedChatID;NSString *_selectedChatTitle,*_currentAuthState,*_activeSection;
    BOOL _chatNavigationClosed,_searchPanelVisible,_botComposerVisible,_profileReplaces,_profileActive,_mediaCenterVisible;
    NSButton *_sendTextField;
    NSView *_aquaFooterView,*_sidebarResizeHandleView,*_sendLabel,*_attachPhotoButton,*_botActionButton,*_botCommandPanelView,*_sendTextFieldBackgroundView,*_stickerButton,*_voiceRecordButton,*_sendMessageButton;
}
@property(nonatomic,retain) TGScheduledMessagesWindowController *scheduledMessagesWindowController;
@property(nonatomic,retain) id client,downloadManagerWindowController;
@property(nonatomic,retain) NSNumber *selectedChatID;
@property(nonatomic,copy) NSString *selectedChatTitle,*currentAuthState,*activeSection;
@property(nonatomic,assign) BOOL chatNavigationClosed,searchPanelVisible,botComposerVisible,profileReplaces,profileActive,mediaCenterVisible;
@property(nonatomic,retain) NSButton *sendTextField;
@property(nonatomic,retain) NSView *aquaFooterView,*sidebarResizeHandleView,*sendLabel,*attachPhotoButton,*botActionButton,*botCommandPanelView,*sendTextFieldBackgroundView,*stickerButton,*voiceRecordButton,*sendMessageButton;
@end
@implementation QueueRoot
@synthesize scheduledMessagesWindowController=_scheduledMessagesWindowController,client=_client,downloadManagerWindowController=_downloadManagerWindowController,selectedChatID=_selectedChatID,selectedChatTitle=_selectedChatTitle,currentAuthState=_currentAuthState,activeSection=_activeSection,chatNavigationClosed=_chatNavigationClosed,searchPanelVisible=_searchPanelVisible,botComposerVisible=_botComposerVisible,profileReplaces=_profileReplaces,profileActive=_profileActive,mediaCenterVisible=_mediaCenterVisible;
@synthesize aquaFooterView=_aquaFooterView,sidebarResizeHandleView=_sidebarResizeHandleView;
@synthesize sendTextField=_sendTextField,sendLabel=_sendLabel,attachPhotoButton=_attachPhotoButton,botActionButton=_botActionButton,botCommandPanelView=_botCommandPanelView,sendTextFieldBackgroundView=_sendTextFieldBackgroundView,stickerButton=_stickerButton,voiceRecordButton=_voiceRecordButton,sendMessageButton=_sendMessageButton;
- (id)init{self=[super init];if(self){_window=[[QueueWindow alloc] init];self.aquaFooterView=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,1200,58)] autorelease];self.sidebarResizeHandleView=[[[NSView alloc] init] autorelease];self.client=[[[NSObject alloc] init] autorelease];self.selectedChatID=@42;self.currentAuthState=@"ready";self.activeSection=TGSectionChats;self.sendTextField=[[[NSButton alloc] init] autorelease];self.sendLabel=[[[NSView alloc] init] autorelease];self.attachPhotoButton=[[[NSView alloc] init] autorelease];self.botActionButton=[[[NSView alloc] init] autorelease];self.botCommandPanelView=[[[NSView alloc] init] autorelease];self.sendTextFieldBackgroundView=[[[NSView alloc] init] autorelease];self.stickerButton=[[[NSView alloc] init] autorelease];self.voiceRecordButton=[[[NSView alloc] init] autorelease];self.sendMessageButton=[[[NSView alloc] init] autorelease];}return self;}
- (id)window{return _window;}
- (void)applyUtilityButtonStyle:(NSButton *)button{(void)button;}
- (void)installAquaTextCellOnButton:(NSButton *)button accented:(BOOL)accented{(void)button;(void)accented;}
- (void)closeAquaStickerPicker{}
- (void)closeSearchPanel:(id)sender{(void)sender;self.searchPanelVisible=NO;}
- (void)layoutContentView{}
- (BOOL)aquaChatInfoReplacesConversation{return self.profileReplaces;}
- (BOOL)isAquaChatInfoPanelActive{return self.profileActive;}
- (void)showScheduledMessages:(id)sender{(void)sender;[self toggleAquaScheduledMessages];}
__QUEUE__
- (void)layoutComposerWidth:(CGFloat)conversationWidth {
    BOOL aqua=TGInterfaceDesignIsAqua();CGFloat conversationX=0,composerY=8,composerHeight=46,composerInputHeight=30,replyPanelHeight=0,replyPanelGap=0;
__RESERVATION__
__COMPOSER__
}
- (void)restackComposerChrome {
    NSView *content=[[self window] contentView];
__STACKING__
}
- (void)dealloc{[_aquaFooterView release];[_sidebarResizeHandleView release];[_scheduledMessagesWindowController release];[_window release];[_client release];[_downloadManagerWindowController release];[_selectedChatID release];[_selectedChatTitle release];[_currentAuthState release];[_activeSection release];[_sendTextField release];[_sendLabel release];[_attachPhotoButton release];[_botActionButton release];[_botCommandPanelView release];[_sendTextFieldBackgroundView release];[_stickerButton release];[_voiceRecordButton release];[_sendMessageButton release];[super dealloc];}
@end
int main(void){
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    QueueRoot *root=[[[QueueRoot alloc] init] autorelease];
    Check([root toggleAquaScheduledMessages]&&[[[root scheduledMessagesWindowController] embeddedShelfView] superview]!=nil,"Aqua action attaches current-chat shelf");
    TGScheduledMessagesWindowController *opened=[[root scheduledMessagesWindowController] retain];
    Check(opened.presentations==1,"toggle presents attached shelf exactly once");
    CGFloat bottom=[root layoutAquaScheduledShelfAtX:300 bottom:58 width:650 top:700];Check(bottom==292,"visible shelf reserves228points plus6gap above composer");
    for(CGFloat top=120;top<=700;top+=10){CGFloat reserved=[root layoutAquaScheduledShelfAtX:300 bottom:58 width:650 top:top];NSView *shelf=[root.scheduledMessagesWindowController embeddedShelfView];if([shelf isHidden])Check(reserved==58,"insufficient height reserves no invisible shelf");else Check(top-reserved>=160 && NSHeight([shelf frame])<=228,"shelf reserves only room left above the minimum transcript");}
    Check(opened.presentations==1&&opened.hides>0,"relayout does not restart reveal and insufficient height cancels it");
    [root hideAquaScheduledMessages:root];Check(!root.scheduledMessagesWindowController&&opened.invalidations==1,"close retires controller and invalidates exactly once");[opened release];
    [root toggleAquaScheduledMessages];root.profileReplaces=YES;root.profileActive=YES;root.mediaCenterVisible=YES;
    bottom=[root layoutAquaScheduledShelfAtX:300 bottom:58 width:374 top:700];Check(bottom==58&&root.scheduledMessagesWindowController==nil,"replacement profile cannot retain visible scheduled shelf over hidden composer");
    root.profileReplaces=NO;root.profileActive=NO;root.mediaCenterVisible=NO;
    [root toggleAquaScheduledMessages];[root.sendTextField setHidden:YES];bottom=[root layoutAquaScheduledShelfAtX:300 bottom:58 width:650 top:700];Check(bottom==58&&!root.scheduledMessagesWindowController,"hidden conversation/composer cannot retain shelf");[root.sendTextField setHidden:NO];
    [root toggleAquaScheduledMessages];root.selectedChatID=@43;bottom=[root layoutAquaScheduledShelfAtX:300 bottom:58 width:650 top:700];Check(bottom==58&&!root.scheduledMessagesWindowController,"changed chat identity cannot retain old queue");root.selectedChatID=@42;
    [root toggleAquaScheduledMessages];root.activeSection=@"settings";bottom=[root layoutAquaScheduledShelfAtX:300 bottom:58 width:650 top:700];Check(bottom==58&&!root.scheduledMessagesWindowController,"section change retires shelf");root.activeSection=TGSectionChats;
    root.scheduledMessagesWindowController=[[[TGScheduledMessagesWindowController alloc] initWithClient:root.client chatID:root.selectedChatID title:@""] autorelease];opened=[root.scheduledMessagesWindowController retain];[root closeAquaScheduledMessages];Check(root.scheduledMessagesWindowController==nil&&opened.invalidations==1,"detached controller also invalidated on close");[opened release];
    Aqua=NO;root.scheduledMessagesWindowController=[[[TGScheduledMessagesWindowController alloc] initWithClient:root.client chatID:root.selectedChatID title:@""] autorelease];bottom=[root layoutAquaScheduledShelfAtX:300 bottom:58 width:650 top:700];Check(bottom==58&&root.scheduledMessagesWindowController.getterCalls==0,"Classic layout must not lazily create Aqua content");Aqua=YES;
    NSUInteger layouts=0;
    for(NSUInteger bot=0;bot<2;bot++)for(CGFloat width=400;width<=1000;width+=2){
        root.botComposerVisible=bot;[root layoutComposerWidth:width];
        NSRect input=[root.sendTextFieldBackgroundView frame],sticker=[root.stickerButton frame];
        Check(fabs(NSMaxX(input)+10-NSMinX(sticker))<0.01,"input reclaims all former queue-button width");
        Check(NSMaxX([root.sendMessageButton frame])<=width,"send context-menu anchor stays inside composer");
        NSView *content=[[root window] contentView];[root restackComposerChrome];
        Check([[content subviews] indexOfObjectIdenticalTo:root.sendMessageButton]>[[content subviews] indexOfObjectIdenticalTo:root.aquaFooterView],"send anchor remains above footer");
        layouts++;
    }
    printf("Aqua queue integration: %lu production composer layouts; toggle/close, detached invalidation, profile replacement, section lifecycle and Classic allocation guard PASS.\n",(unsigned long)layouts);[pool drain];return 0;
}
'''.replace('__QUEUE__',queue).replace('__RESERVATION__',reservation).replace('__COMPOSER__',composer).replace('__STACKING__',stacking)
folder=tempfile.mkdtemp(prefix='telegraphica-queue-integration-')
try:
    path=os.path.join(folder,'probe.m');binary=os.path.join(folder,'probe')
    with open(path,'wb') as handle:handle.write(harness.encode('utf-8'))
    subprocess.check_call(sys.argv[1:]+[path,'-framework','Cocoa','-o',binary]);subprocess.check_call([binary])
finally:shutil.rmtree(folder)
