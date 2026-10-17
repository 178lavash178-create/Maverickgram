#!/usr/bin/env python
"""Production topic menus/read actions and folder routing, isolated from accounts."""
from __future__ import print_function, unicode_literals
import os,sys,subprocess,tempfile,shutil
root=os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))
def read(path):
    with open(os.path.join(root,path),'rb') as f:return f.read().decode('utf-8')
controller=read('Sources/UI/TGStatusWindowController.m')
a=controller.index('- (void)folderFilterChanged:');b=controller.index('\n- (void)toggleDrawer:',a)
folder=controller[a:b]
forum=read('Sources/UI/TGStatusWindowController+ForumTopicManagement.inc')
refresh=read('Sources/UI/TGStatusWindowController+TableForumFlow.inc')
a=refresh.index('- (void)reloadCurrentForumTopicListInteractive:')
a=refresh.index('            BOOL sameAccount =',a)
b=refresh.index('            if (stillCurrent',a)
refresh_guard='- (BOOL)acceptsForumRefreshClient:(TGTDLibClient *)client account:(NSNumber *)account generation:(NSUInteger)refreshGeneration parent:(NSNumber *)parentChatID {'+refresh[a:b]+'return stillCurrent;}'

section=read('Sources/UI/TGStatusWindowController+SectionLayout.inc')
def bool_method(source,name,method,extra=''):
    a=source.index('    BOOL '+name+' = ');b=source.index(';',a)+1
    return '- (BOOL)'+method+' {'+extra+source[a:b]+'return '+name+';}'
header=bool_method(controller,'canCall','headerCanCall')+bool_method(section,'showSelectedChatCall','headerShowsCall','BOOL showConversationContent=YES;')+bool_method(section,'layoutSelectedChatCall','headerReservesCallWidth')
harness=r'''
#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import "TGForumTopicPermissions.h"
#import "TGForumTopicRefreshSupport.h"
#import "TGChatItem.h"
#import "TGMessageItem.h"
#import "TGTDLibClient+ForumTopics.h"
static NSString *TGSectionChats=@"chats",*TGSectionWorkshop=@"workshop";
static NSUInteger Checks;
static void Check(BOOL value,const char *reason){Checks++;if(!value){fprintf(stderr,"Forum actions: %s\n",reason);exit(1);}}
NSString *TGLoc(NSString *key){return key;}
static NSInteger TGRunAlert(NSAlert *alert,NSWindow *window){(void)alert;(void)window;return NSAlertSecondButtonReturn;}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TGTDLibClient
@end
#pragma clang diagnostic pop
@interface TopicClient:TGTDLibClient
@property(nonatomic) NSUInteger historyCalls,readCalls,invalidations;
@property(nonatomic) BOOL transportAvailable;
@property(nonatomic,retain) NSNumber *historyThread,*readThread,*readChat;
@property(nonatomic,copy) NSString *historyKind,*readKind;
@property(nonatomic,copy) NSArray *readIDs;
@property(nonatomic,copy) void(^beforeHistory)(void);
@end
@implementation TopicClient
@synthesize transportAvailable,historyCalls,readCalls,invalidations,historyThread,readThread,readChat,historyKind,readKind,readIDs,beforeHistory;
- (NSArray *)recentMessagePreviewItemsForChatID:(NSNumber *)chatID messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind limit:(NSUInteger)limit timeout:(NSTimeInterval)timeout error:(NSError **)error {
 (void)limit;(void)timeout;(void)error;self.historyCalls++;self.historyThread=thread;self.historyKind=kind;
 if(beforeHistory)dispatch_sync(dispatch_get_main_queue(),beforeHistory);
 TGMessageItem *message=[[[TGMessageItem alloc] initWithChatID:chatID messageID:@99 date:@0 outgoing:NO preview:@"fixture"] autorelease];return [NSArray arrayWithObject:message];
}
- (BOOL)markMessagesAsReadForChatID:(NSNumber *)chatID messageThreadID:(NSNumber *)thread messageTopicKind:(NSString *)kind messageIDs:(NSArray *)ids timeout:(NSTimeInterval)timeout error:(NSError **)error{
 (void)timeout;(void)error;self.readCalls++;self.readChat=chatID;self.readThread=thread;self.readKind=kind;self.readIDs=ids;return YES;
}
- (void)invalidateMainChatListExhaustion { self.invalidations++; }
- (void)dealloc{[historyThread release];[readThread release];[readChat release];[historyKind release];[readKind release];[readIDs release];[beforeHistory release];[super dealloc];}
@end
@interface TopicRoot:NSObject
@property(nonatomic,retain) TopicClient *client,*callCoordinator;
@property(nonatomic,retain) NSNumber *selectedChatID,*profileUserID;
@property(nonatomic,copy) NSString *selectedChatTypeSummary;
@property(nonatomic) BOOL mediaCenterVisible;
@property(nonatomic,copy) NSString *currentAuthState,*activeSection,*selectedMessageTopicKind;
@property(nonatomic,retain) NSNumber *topicParentChatID,*selectedChatFilterID,*selectedMessageThreadID,*suppressedForumTopicAutoOpenChatID;
@property(nonatomic,copy) NSArray *forumTopicItems;
@property(nonatomic) BOOL showingForumTopicList,forumTopicsPresentedInTopBar,forumTopicMutationInFlight,showingArchivedChats,chatNavigationClosed,chatsExhausted,autoChatListLoadArmed,autoChatListRefreshArmed;
@property(nonatomic) NSUInteger forumTopicNavigationGeneration,chatPreviewLimit,reloads,readClears;
@property(nonatomic,retain) NSTextField *statusField;
@property(nonatomic,retain) NSWindow *window;
@property(nonatomic,retain) id workshopCoordinator;
@end
@implementation TopicRoot
@synthesize callCoordinator,selectedChatID,profileUserID,selectedChatTypeSummary,mediaCenterVisible,client,currentAuthState,activeSection,selectedMessageTopicKind,topicParentChatID,selectedChatFilterID,selectedMessageThreadID,suppressedForumTopicAutoOpenChatID,forumTopicItems,showingForumTopicList,forumTopicsPresentedInTopBar,forumTopicMutationInFlight,showingArchivedChats,chatNavigationClosed,chatsExhausted,autoChatListLoadArmed,autoChatListRefreshArmed,forumTopicNavigationGeneration,chatPreviewLimit,reloads,readClears,statusField,window,workshopCoordinator;
- (id)init{if((self=[super init])){self.currentAuthState=@"ready";self.activeSection=TGSectionChats;self.client=[[[TopicClient alloc] init] autorelease];self.statusField=[[[NSTextField alloc] init] autorelease];}return self;}
- (void)dealloc{[callCoordinator release];[selectedChatID release];[profileUserID release];[selectedChatTypeSummary release];[client release];[currentAuthState release];[activeSection release];[selectedMessageTopicKind release];[topicParentChatID release];[selectedChatFilterID release];[selectedMessageThreadID release];[suppressedForumTopicAutoOpenChatID release];[forumTopicItems release];[statusField release];[window release];[workshopCoordinator release];[super dealloc];}
- (void)appendDetail:(NSString *)text{(void)text;}
- (void)openNewChatWindow:(id)sender{(void)sender;}
- (void)reloadCurrentForumTopicListInteractive:(BOOL)interactive{(void)interactive;}
- (void)recordReadNotificationMessageIDs:(NSArray *)ids chatID:(NSNumber *)chatID{Check([ids count]>0 && [chatID isEqual:self.topicParentChatID],"read notification state remains bound to the requested topic messages");}
- (void)clearUnreadCountForChatID:(NSNumber *)chatID messageThreadID:(NSNumber *)thread{Check([chatID isEqual:self.topicParentChatID],"only current parent unread count changes");Check([thread longLongValue]>0,"General uses topic 1, never chat-wide zero");self.readClears++;}
- (BOOL)isAquaChatInfoPanelActive{return NO;}
__HEADER__
- (void)refreshChatListTitle{}
- (void)updateDrawerFolderButtonStates{}
- (void)captureNavigationContinuity{}
- (void)armNavigationChatListRestore{}
- (NSUInteger)navigationChatListRestoreLimit{return 40;}
- (void)clearForumTopicListState{self.showingForumTopicList=NO;self.forumTopicsPresentedInTopBar=NO;self.forumTopicItems=nil;self.topicParentChatID=nil;}
- (void)reloadChatsInteractive:(BOOL)interactive preserveSelection:(BOOL)preserve requestedLimit:(NSUInteger)limit{Check(interactive&&!preserve&&limit==40,"folder reload uses correct navigation request");self.reloads++;}
__FORUM__
__REFRESH_GUARD__
__FOLDER__
@end
static BOOL MenuHas(NSMenu *menu,SEL selector){for(NSMenuItem *item in [menu itemArray])if([item action]==selector)return YES;return NO;}
static TGChatItem *Topic(NSNumber *thread){TGChatItem *item=[[[TGChatItem alloc] initWithChatID:@(-100) title:@"Topic" typeSummary:@"Forum topic" unreadCount:@9] autorelease];item.forumTopic=YES;item.parentChatID=@(-100);item.messageThreadID=thread;item.messageTopicKind=@"forum";return item;}
static void Spin(void){NSDate *until=[NSDate dateWithTimeIntervalSinceNow:.3];while([until timeIntervalSinceNow]>0)[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.005]];}
int main(void){NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
 TopicRoot *p=[[[TopicRoot alloc] init] autorelease];TGChatItem *item=Topic(@66);p.topicParentChatID=item.parentChatID;p.forumTopicItems=[NSArray arrayWithObject:item];p.showingForumTopicList=YES;
 NSMenu *menu=[[[NSMenu alloc] initWithTitle:@"test"] autorelease];[p populateForumTopicContextMenu:menu forItem:item];Check([menu numberOfItems]==1&&MenuHas(menu,@selector(markForumTopicReadFromMenu:)),"non-admin only sees read action");
 // Execute real receiver normalization and UI role-cache policy, including a
 // delayed topic snapshot that still contains administrator capabilities.
 p.profileUserID=@1;p.selectedChatID=p.topicParentChatID;
 Check([p acceptsForumRefreshClient:p.client account:@1 generation:p.forumTopicNavigationGeneration parent:p.topicParentChatID],"matching topic refresh callback remains eligible");
 Check(![p acceptsForumRefreshClient:p.client account:@2 generation:p.forumTopicNavigationGeneration parent:p.topicParentChatID],"topic refresh rejects an old account with identical group IDs");
 Check(![p acceptsForumRefreshClient:[[[TopicClient alloc] init] autorelease] account:@1 generation:p.forumTopicNavigationGeneration parent:p.topicParentChatID],"topic refresh rejects a replaced client");
 p.currentAuthState=@"closed";Check(![p acceptsForumRefreshClient:p.client account:@1 generation:p.forumTopicNavigationGeneration parent:p.topicParentChatID],"topic refresh rejects signed-out callback");p.currentAuthState=@"ready";
 Check(![p acceptsForumRefreshClient:p.client account:@1 generation:p.forumTopicNavigationGeneration+1 parent:p.topicParentChatID],"topic refresh rejects superseded navigation");
 NSDictionary *adminStatus=[NSDictionary dictionaryWithObject:@"chatMemberStatusCreator" forKey:@"@type"];
 NSDictionary *adminContext=[NSDictionary dictionaryWithObjectsAndKeys:adminStatus,@"status",@30,@"supergroup_id",nil];
 NSDictionary *adminPermissions=TGForumTopicActionPermissions(adminContext,nil,@66);
 item.forumTopicActionPermissions=adminPermissions;
 [menu removeAllItems];[p populateForumTopicContextMenu:menu forItem:item];
 Check(MenuHas(menu,@selector(deleteForumTopicFromMenu:))&&MenuHas(menu,@selector(toggleForumTopicPinnedFromMenu:)),"fresh administrator snapshot offers permitted actions");
 NSDictionary *member=[NSDictionary dictionaryWithObject:@"chatMemberStatusMember" forKey:@"@type"];
 NSDictionary *raw=[NSDictionary dictionaryWithObjectsAndKeys:@"updateSupergroup",@"@type",[NSDictionary dictionaryWithObjectsAndKeys:@30,@"id",member,@"status",@"must not propagate",@"description",nil],@"supergroup",nil];
 NSDictionary *demotion=TGForumTopicRightsUpdateSummary(raw);
 Check([[demotion objectForKey:@"kind"] isEqual:@"forum_topic_rights"] && ![demotion objectForKey:@"description"],"receiver normalizes only safe current-role capabilities");
 [p applyForumTopicRightsUpdateSummary:demotion];[menu removeAllItems];[p populateForumTopicContextMenu:menu forItem:item];
 Check([menu numberOfItems]==1,"retained topic menu drops revoked administrative actions without reloading transcript");
 item.forumTopicActionPermissions=adminPermissions;[menu removeAllItems];[p populateForumTopicContextMenu:menu forItem:item];
 Check([menu numberOfItems]==1,"late administrator topic snapshot cannot restore revoked menu entries");
 for(NSUInteger group=100;group<200;group++) {
  [p applyForumTopicRightsUpdateSummary:[NSDictionary dictionaryWithObjectsAndKeys:@"forum_topic_rights",@"kind",[NSNumber numberWithUnsignedInteger:group],@"supergroup_id",member,@"status",nil]];
 }
 Check([[p forumTopicRoleContexts] count]<=64,"role cache remains bounded during unrelated group updates");
 item.forumTopicActionPermissions=adminPermissions;Check(![p forumTopicItem:item allowsOperation:@"delete"],"bounded pruning preserves the displayed group's revocation");
 p.profileUserID=@2;item.forumTopicActionPermissions=adminPermissions;
 Check([p forumTopicItem:item allowsOperation:@"delete"],"previous account role cache cannot override a new account snapshot");
 [p applyForumTopicRightsUpdateSummary:demotion];p.client=[[[TopicClient alloc] init] autorelease];item.forumTopicActionPermissions=adminPermissions;
 Check([p forumTopicItem:item allowsOperation:@"delete"],"previous client role cache cannot override current client capabilities");
 [p applyForumTopicRightsUpdateSummary:demotion];
 item.forumTopicActionPermissions=TGForumTopicActionPermissions(adminContext,[NSDictionary dictionaryWithObject:@YES forKey:@"is_outgoing"],@66);
 Check([p forumTopicItem:item allowsOperation:@"rename"]&&![p forumTopicItem:item allowsOperation:@"delete"],"demoted topic creator keeps only documented ownership actions");
 [p applyForumTopicRightsUpdateSummary:[NSDictionary dictionaryWithObjectsAndKeys:@"forum_topic_rights",@"kind",@30,@"supergroup_id",[NSDictionary dictionaryWithObject:@"chatMemberStatusBanned" forKey:@"@type"],@"status",nil]];
 Check(![p forumTopicItem:item allowsOperation:@"rename"],"banned creator loses ownership management actions");
 [p applyForumTopicRightsUpdateSummary:demotion];
 Check([p forumTopicItem:item allowsOperation:@"rename"],"rejoining restores actual topic ownership without inventing deletion rights");
 NSDictionary *flatStatus=[NSDictionary dictionaryWithObjectsAndKeys:@"chatMemberStatusAdministrator",@"@type",@YES,@"can_manage_topics",@NO,@"can_delete_messages",nil];
 NSDictionary *flatUpdate=TGForumTopicRightsUpdateSummary([NSDictionary dictionaryWithObjectsAndKeys:@"updateSupergroup",@"@type",[NSDictionary dictionaryWithObjectsAndKeys:@30,@"id",flatStatus,@"status",nil],@"supergroup",nil]);
 [p applyForumTopicRightsUpdateSummary:flatUpdate];
 Check([p forumTopicItem:item allowsOperation:@"pin"]&&![p forumTopicItem:item allowsOperation:@"delete"],"legacy flat role updates preserve distinct manage and delete capabilities");
 Check(!TGForumTopicRightsUpdateSummary([NSDictionary dictionaryWithObject:@"updateSupergroup" forKey:@"@type"]),"malformed role update does not invent capabilities");
 // Existing independent fixtures below have no server group identity.
 item.forumTopicActionPermissions=[NSDictionary dictionaryWithObjectsAndKeys:@YES,@"rename",@YES,@"close",nil];[menu removeAllItems];[p populateForumTopicContextMenu:menu forItem:item];Check(MenuHas(menu,@selector(renameForumTopicFromMenu:))&&MenuHas(menu,@selector(toggleForumTopicClosedFromMenu:)),"documented own-topic permissions appear");Check(!MenuHas(menu,@selector(deleteForumTopicFromMenu:))&&!MenuHas(menu,@selector(toggleForumTopicPinnedFromMenu:)),"ownership does not invent destructive rights");
 NSMenuItem *sender=[[[NSMenuItem alloc] init] autorelease];[sender setRepresentedObject:item];
 for(NSNumber *thread in [NSArray arrayWithObjects:@66,@1,nil]){item.messageThreadID=thread;NSUInteger before=p.client.readCalls;[p markForumTopicReadFromMenu:sender];Spin();Check(p.client.readCalls==before+1,"one explicit topic read sends one receipt");Check([p.client.historyThread isEqual:thread]&&[p.client.readThread isEqual:thread]&&[p.client.readKind isEqual:@"forum"],"read remains scoped to requested topic including General");Check([p.client.readChat isEqual:@(-100)]&&[p.client.readIDs isEqual:[NSArray arrayWithObject:@99]],"only returned topic message IDs reach receipt");}
 item.messageThreadID=@66;item.messageTopicKind=@"forum_legacy";[p markForumTopicReadFromMenu:sender];Spin();Check([p.client.readKind isEqual:@"forum_legacy"],"legacy topic identity retained");
 NSUInteger before=p.client.readCalls;p.client.beforeHistory=^{p.forumTopicNavigationGeneration++;};[p markForumTopicReadFromMenu:sender];Spin();Check(p.client.readCalls==before,"navigation changed during history fetch cannot mark anything read");p.client.beforeHistory=nil;
 p.forumTopicItems=nil;[menu removeAllItems];[p populateForumTopicContextMenu:menu forItem:item];Check([menu numberOfItems]==0,"missing current topic array never accepts stale item");p.forumTopicItems=[NSArray arrayWithObject:item];
 p.currentAuthState=@"closed";[p markForumTopicReadFromMenu:sender];Spin();Check(p.client.readCalls==before,"signed-out context ignores old menu");p.currentAuthState=@"ready";
 for(NSUInteger mode=0;mode<5;mode++){p.showingForumTopicList=mode==0;p.forumTopicsPresentedInTopBar=mode==1;p.chatNavigationClosed=mode==2;p.activeSection=mode==3?@"settings":TGSectionChats;p.topicParentChatID=@(-100);p.selectedMessageThreadID=@66;p.selectedMessageTopicKind=@"forum";p.selectedChatFilterID=nil;NSUInteger previous=p.reloads;NSButton *button=[[[NSButton alloc] init] autorelease];[button setTag:-1];[p folderFilterChanged:button];Check(p.reloads==previous+(mode<4?1:0),"same All chats filter exits topics, closed chat or non-chat section");if(mode<4)Check(!p.showingForumTopicList&&!p.forumTopicsPresentedInTopBar&&!p.chatNavigationClosed&&!p.selectedMessageThreadID&&!p.selectedMessageTopicKind&&[p.activeSection isEqual:TGSectionChats],"folder exit removes stale thread and section state");}
 p.selectedChatFilterID=@7;NSButton *all=[[[NSButton alloc] init] autorelease];[all setTag:-1];NSUInteger previous=p.reloads;[p folderFilterChanged:all];Check(p.reloads==previous+1&&!p.selectedChatFilterID&&!p.showingArchivedChats,"custom folder returns to All chats");
 p.callCoordinator=p.client;p.callCoordinator.transportAvailable=YES;p.activeSection=TGSectionChats;p.mediaCenterVisible=NO;p.profileUserID=@10;
 for(NSUInteger identity=0;identity<4;identity++){
    p.selectedChatID=identity==0?nil:(identity==1?@10:@20);p.selectedChatTypeSummary=identity==3?@"Supergroup":@"Private";
    BOOL expected=identity==2;Check([p headerCanCall]==expected,"Saved Messages and absent or group chat cannot enable calls");
    Check([p headerShowsCall]==expected,"Saved Messages never display audio/video buttons");
    Check([p headerReservesCallWidth]==expected,"hidden self-call buttons do not reserve title width");
 }
 printf("Forum actions: %lu production menu, read context, General and folder navigation checks PASS.\n",(unsigned long)Checks);[pool drain];return 0;}
'''
build=tempfile.mkdtemp(prefix='telegraphica-forum-actions-')
try:
 path=os.path.join(build,'probe.m')
 with open(path,'wb') as f:f.write(harness.replace('__FORUM__',forum).replace('__FOLDER__',folder).replace('__REFRESH_GUARD__',refresh_guard).replace('__HEADER__',header).encode('utf-8'))
 clang=os.environ.get('CLANG') or subprocess.check_output(['xcrun','--find','clang']).decode('utf-8').strip()
 sdk=subprocess.check_output(['xcrun','--show-sdk-path']).decode('utf-8').strip()
 command=[clang,'-isysroot',sdk,'-fblocks','-fno-objc-arc','-Wno-deprecated-declarations','-Wno-shadow-ivar','-Wno-objc-method-access','-arch',os.environ.get('TELEGRAPHICA_TEST_ARCH','x86_64'),'-mmacosx-version-min='+os.environ.get('TELEGRAPHICA_TEST_DEPLOYMENT_TARGET','10.8'),'-I'+os.path.join(root,'Sources/Core'),'-I'+os.path.join(root,'Sources/UI'),path,os.path.join(root,'Sources/Core/TGChatItem.m'),os.path.join(root,'Sources/Core/TGMessageItem.m'),'-framework','Cocoa','-o',os.path.join(build,'probe')]
 subprocess.check_call(command);subprocess.check_call([os.path.join(build,'probe')])
finally:shutil.rmtree(build)
