#import <Cocoa/Cocoa.h>
#import "TGNotificationMuteState.h"
#import "TGNotificationReadState.h"
#import "TGNotificationDeliverySupport.h"
#import "TGChatItem.h"

static void Require(BOOL value, const char *message) { if (!value) { fprintf(stderr, "Notification mute failure: %s\n", message); exit(1); } }
static NSTimeInterval Now(void) { return [[NSDate date] timeIntervalSince1970]; }
static NSDictionary *Settings(BOOL inherit, NSInteger duration) {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:inherit], @"use_default_mute_for", [NSNumber numberWithInteger:duration], @"mute_for", nil];
}
static NSDictionary *Chat(NSNumber *chatID, BOOL inherit, NSInteger duration, BOOL channel) {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"chat", @"@type", chatID, @"id", Settings(inherit, duration), @"notification_settings",
        [NSDictionary dictionaryWithObjectsAndKeys:@"chatTypeSupergroup", @"@type", [NSNumber numberWithBool:channel], @"is_channel", nil], @"type", nil];
}
static NSDictionary *Scope(BOOL channel, NSInteger duration) {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"updateScopeNotificationSettings", @"@type", Settings(NO, duration), @"notification_settings",
        [NSDictionary dictionaryWithObject:channel ? @"notificationSettingsScopeChannelChats" : @"notificationSettingsScopeGroupChats" forKey:@"@type"], @"scope", nil];
}
static NSDictionary *Summary(NSInteger messageID) {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"Incoming", @"direction", @-100, @"chat_id", [NSNumber numberWithInteger:messageID], @"message_id", [NSNumber numberWithDouble:Now()], @"date", @"synthetic", @"preview", nil];
}

@interface ProbeNotification : NSObject
@property (nonatomic, copy) NSDictionary *userInfo;
@property (nonatomic, copy) NSString *title, *informativeText, *soundName;
@end
@implementation ProbeNotification
@synthesize userInfo=_userInfo, title=_title, informativeText=_informativeText, soundName=_soundName;
- (void)dealloc { [_userInfo release]; [_title release]; [_informativeText release]; [_soundName release]; [super dealloc]; }
@end
@interface ProbeCenter : NSObject
@property (nonatomic, retain) NSMutableArray *deliveredNotifications, *scheduledNotifications;
+ (id)defaultUserNotificationCenter;
- (void)deliverNotification:(id)notification;
- (void)removeDeliveredNotification:(id)notification;
- (void)removeScheduledNotification:(id)notification;
@end
@implementation ProbeCenter
@synthesize deliveredNotifications=_deliveredNotifications, scheduledNotifications=_scheduledNotifications;
+ (id)defaultUserNotificationCenter { static ProbeCenter *center; if (!center) center=[[self alloc] init]; return center; }
- (id)init { if ((self=[super init])) { _deliveredNotifications=[[NSMutableArray alloc] init]; _scheduledNotifications=[[NSMutableArray alloc] init]; } return self; }
- (void)dealloc { [_deliveredNotifications release]; [_scheduledNotifications release]; [super dealloc]; }
- (void)deliverNotification:(id)n { [_deliveredNotifications addObject:n]; }
- (void)removeDeliveredNotification:(id)n { [_deliveredNotifications removeObjectIdenticalTo:n]; }
- (void)removeScheduledNotification:(id)n { [_scheduledNotifications removeObjectIdenticalTo:n]; }
@end
static Class ProbeClass(NSString *name) { return [name isEqual:@"NSUserNotificationCenter"] ? [ProbeCenter class] : NSClassFromString(name); }
#define NSClassFromString ProbeClass
#define NSUserNotification ProbeNotification
#define NSUserNotificationCenter ProbeCenter
static BOOL TGMountainLionSafeLoginModeEnabled(void) { return NO; }
static BOOL TGUserDefaultBoolWithDefault(NSString *key, BOOL fallback) { (void)key; return fallback; }
#define TGNotificationsEnabledDefaultsKey @"enabled"
#define TGNotificationPreviewEnabledDefaultsKey @"preview"
#define TGNotificationSoundEnabledDefaultsKey @"sound"
#define TGLoc(x) (x)

@interface TGTDLibClient : NSObject
@property (nonatomic, retain) TGNotificationMuteState *muteState;
- (NSNumber *)notificationMuteStateForChatID:(NSNumber *)chatID;
- (NSDictionary *)chatSummaryForChatID:(NSNumber *)chatID downloadAvatar:(BOOL)avatar timeout:(NSTimeInterval)timeout error:(NSError **)error;
@end
@implementation TGTDLibClient
@synthesize muteState=_muteState;
- (id)init { if ((self=[super init])) _muteState=[[TGNotificationMuteState alloc] init]; return self; }
- (void)dealloc { [_muteState release]; [super dealloc]; }
- (NSNumber *)notificationMuteStateForChatID:(NSNumber *)chatID { return [_muteState mutedForChatID:chatID atUnixTime:Now()]; }
- (NSDictionary *)chatSummaryForChatID:(NSNumber *)chatID downloadAvatar:(BOOL)avatar timeout:(NSTimeInterval)timeout error:(NSError **)error {
    (void)avatar; (void)timeout; (void)error; (void)chatID;
    return [NSDictionary dictionaryWithObjectsAndKeys:@"synthetic", @"title", @"present", @"avatar_local_path", nil];
}
@end
@interface ProbeController : NSObject
@property (nonatomic, retain) TGTDLibClient *client;
@property (nonatomic, retain) NSMutableDictionary *notificationChatInfoByChatID;
@property (nonatomic, retain) TGNotificationReadState *notificationReadState;
@property (nonatomic, retain) NSDictionary *request, *result;
@property (nonatomic, assign) BOOL localMute, hasAccountUnreadCount;
@property (nonatomic, retain) NSArray *chatItems, *chatItemsBeforeTopicList;
@property (nonatomic, retain) id chatTableView;
- (BOOL)isChatIDLocallyMuted:(NSNumber *)chatID;
- (BOOL)isChatIDMutedForNotifications:(NSNumber *)chatID;
- (NSString *)notificationCacheKeyForChatID:(NSNumber *)chatID;
- (TGChatItem *)chatItemForNotificationChatID:(NSNumber *)chatID;
- (NSImage *)notificationAvatarImageForChatID:(NSNumber *)chatID;
- (void)applyLocalNotificationMuteStateToItems:(NSArray *)items;
- (void)updateApplicationBadge;
- (void)appendDetail:(NSString *)detail;
- (void)requestNotificationChatInfoFetchForChatID:(NSNumber *)chatID cacheKey:(NSString *)cacheKey;
- (void)fetchNotificationChatInfoInBackground:(NSDictionary *)request;
- (void)applyFetchedNotificationChatInfo:(NSDictionary *)result;
- (NSDictionary *)notificationChatInfoForChatID:(NSNumber *)chatID;
- (void)deliverNotificationForValidatedSummary:(NSDictionary *)summary;
- (void)removeMutedMessageNotifications;
- (void)deferNotificationSummaryUntilMuteStateKnown:(NSDictionary *)summary;
@end
@implementation ProbeController
@synthesize client=_client, notificationChatInfoByChatID=_notificationChatInfoByChatID, notificationReadState=_notificationReadState;
@synthesize request=_request, result=_result, localMute=_localMute, hasAccountUnreadCount=_hasAccountUnreadCount;
@synthesize chatItems=_chatItems, chatItemsBeforeTopicList=_chatItemsBeforeTopicList, chatTableView=_chatTableView;
- (id)init {
    if ((self=[super init])) { _client=[[TGTDLibClient alloc] init]; _notificationChatInfoByChatID=[[NSMutableDictionary alloc] init]; _notificationReadState=[[TGNotificationReadState alloc] init]; [_notificationReadState resetAtUnixTime:Now()-5]; }
    return self;
}
- (void)dealloc { [_client release]; [_notificationChatInfoByChatID release]; [_notificationReadState release]; [_request release]; [_result release]; [_chatItems release]; [_chatItemsBeforeTopicList release]; [_chatTableView release]; [super dealloc]; }
- (BOOL)isChatIDLocallyMuted:(NSNumber *)chatID { (void)chatID; return _localMute; }
- (BOOL)isChatIDMutedForNotifications:(NSNumber *)chatID { return _localMute || [[_client notificationMuteStateForChatID:chatID] boolValue]; }
- (NSString *)notificationCacheKeyForChatID:(NSNumber *)chatID { return [chatID stringValue]; }
- (TGChatItem *)chatItemForNotificationChatID:(NSNumber *)chatID { (void)chatID; return nil; }
- (NSImage *)notificationAvatarImageForChatID:(NSNumber *)chatID { (void)chatID; return nil; }
- (void)applyLocalNotificationMuteStateToItems:(NSArray *)items { (void)items; }
- (void)updateApplicationBadge {}
- (void)appendDetail:(NSString *)detail { (void)detail; }
- (void)performSelectorInBackground:(SEL)selector withObject:(id)object { Require(selector==@selector(fetchNotificationChatInfoInBackground:), "background target"); self.request=object; }
- (void)performSelectorOnMainThread:(SEL)selector withObject:(id)object waitUntilDone:(BOOL)wait { Require(selector==@selector(applyFetchedNotificationChatInfo:) && !wait, "completion target"); self.result=object; }
#include "../Sources/UI/TGStatusWindowController+NotificationMutePolicy.inc"
#include "../Sources/UI/TGStatusWindowController+NotificationChatInfo.inc"
#include "../Sources/UI/TGStatusWindowController+NotificationPresentation.inc"
@end
static ProbeController *Controller(void) {
    ProbeCenter *center=[ProbeCenter defaultUserNotificationCenter]; [center.deliveredNotifications removeAllObjects]; [center.scheduledNotifications removeAllObjects];
    return [[[ProbeController alloc] init] autorelease];
}
static void Resolve(ProbeController *c, BOOL muted) {
    [c.client.muteState recordTDLibObject:Chat(@-100, NO, muted ? 1000 : 0, YES) atUnixTime:Now()];
    [c fetchNotificationChatInfoInBackground:c.request]; [c applyFetchedNotificationChatInfo:c.result];
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    TGNotificationMuteState *state=[[[TGNotificationMuteState alloc] init] autorelease];
    Require(![state mutedForChatID:@-100 atUnixTime:100], "unknown chat is not permission");
    [state recordTDLibObject:Chat(@-100, YES, 0, YES) atUnixTime:100];
    Require(![state mutedForChatID:@-100 atUnixTime:100], "unknown default channel scope is not permission");
    [state recordTDLibObject:Scope(NO, 0) atUnixTime:100];
    Require(![state mutedForChatID:@-100 atUnixTime:100], "group scope does not unmute a channel");
    [state recordTDLibObject:Scope(YES, 30) atUnixTime:100];
    Require([[state mutedForChatID:@-100 atUnixTime:129] boolValue], "inherited channel mute applies");
    Require([[state mutedForChatID:@-100 atUnixTime:130] isEqual:@NO], "finite inherited mute expires");
    [state recordTDLibObject:Chat(@-200, NO, 0, YES) atUnixTime:100];
    Require([[state mutedForChatID:@-200 atUnixTime:101] isEqual:@NO], "explicit exception wins over default scope");
    [state recordTDLibObject:[NSDictionary dictionaryWithObjectsAndKeys:@"updateChatNotificationSettings", @"@type", @-200, @"chat_id", Settings(NO, 20), @"notification_settings", nil] atUnixTime:110];
    Require([[state mutedForChatID:@-200 atUnixTime:129] boolValue] && [[state mutedForChatID:@-200 atUnixTime:130] isEqual:@NO], "live direct mute applies and expires");
    [state recordTDLibObject:Scope(YES, 50) atUnixTime:200];
    [state recordScopeSettingsIfUnknown:Settings(NO,0) type:@"notificationSettingsScopeChannelChats" atUnixTime:201];
    Require([[state mutedForChatID:@-100 atUnixTime:201] boolValue], "stale RPC cannot replace a newer scope update");
    [state recordTDLibObject:Scope(YES,0) atUnixTime:202];
    Require([[state mutedForChatID:@-100 atUnixTime:203] isEqual:@NO], "external unmute immediately clears cached mute");

    ProbeCenter *center=[ProbeCenter defaultUserNotificationCenter];
    ProbeController *c=Controller();
    [c presentNotificationForUpdateSummary:Summary(1)];
    Require(c.request && [center.deliveredNotifications count]==0, "first unknown message waits, never alerts prematurely");
    Resolve(c,YES);
    Require([center.deliveredNotifications count]==0, "resolved muted chat never delivers queued message");
    Require(![c.notificationReadState isReadNotificationInfo:Summary(1)], "suppression never marks message read");

    c=Controller(); NSDictionary *summary=Summary(2);
    [c presentNotificationForUpdateSummary:summary]; [c presentNotificationForUpdateSummary:summary]; Resolve(c,NO);
    Require([center.deliveredNotifications count]==1, "resolved unmuted fresh message delivered exactly once");
    [c applyFetchedNotificationChatInfo:c.result];
    Require([center.deliveredNotifications count]==1, "duplicate async completion cannot replay delivery");
    [c.client.muteState recordTDLibObject:Chat(@-100,NO,1000,YES) atUnixTime:Now()];
    [c presentNotificationForUpdateSummary:Summary(3)];
    Require([center.deliveredNotifications count]==1, "live mute overrides complete title/avatar cache");
    [c handleNotificationMuteSettingsChanged];
    Require([center.deliveredNotifications count]==0, "muting purges delivered message notification");
    [c.client.muteState recordTDLibObject:Chat(@-100,NO,0,YES) atUnixTime:Now()];
    [c presentNotificationForUpdateSummary:Summary(4)];
    Require([center.deliveredNotifications count]==1, "live unmute overrides stale cached muted presentation");

    c=Controller(); [c presentNotificationForUpdateSummary:Summary(5)];
    [c.client.muteState recordTDLibObject:Chat(@-100,NO,0,YES) atUnixTime:Now()];
    [c fetchNotificationChatInfoInBackground:c.request];
    [c.client.muteState recordTDLibObject:Chat(@-100,NO,1000,YES) atUnixTime:Now()];
    [c applyFetchedNotificationChatInfo:c.result];
    Require([center.deliveredNotifications count]==0, "mute arriving while worker is pending blocks completion");
    Require([c notificationInfoSuppressedByMute:Summary(6)], "native late delivery guard rejects muted message");
    Require(![c notificationInfoSuppressedByMute:[NSDictionary dictionaryWithObjectsAndKeys:@-100,@"chat_id",@"call",@"kind",nil]], "native mute guard preserves call/update notices");

    c=Controller(); [c presentNotificationForUpdateSummary:Summary(7)];
    [c.notificationReadState recordReadMessageIDs:[NSArray arrayWithObject:@7] chatID:@-100]; Resolve(c,NO);
    Require([center.deliveredNotifications count]==0, "read during enrichment still suppresses delivery");
    c=Controller(); [c presentNotificationForUpdateSummary:Summary(8)];
    [c fetchNotificationChatInfoInBackground:c.request]; [c applyFetchedNotificationChatInfo:c.result];
    Require([center.deliveredNotifications count]==0, "scope lookup failure remains closed even when title is available");

    c=Controller(); [c presentNotificationForUpdateSummary:Summary(10)];
    NSDictionary *oldRequest = [[[c.request copy] autorelease] retain];
    c.client=[[[TGTDLibClient alloc] init] autorelease];
    [c.notificationChatInfoByChatID removeAllObjects];
    [c.client.muteState recordTDLibObject:Chat(@-100,NO,0,YES) atUnixTime:Now()];
    [c fetchNotificationChatInfoInBackground:oldRequest]; [c applyFetchedNotificationChatInfo:c.result];
    [oldRequest release];
    Require([center.deliveredNotifications count]==0, "client replacement drops old-account pending delivery");
    c=Controller(); [c presentNotificationForUpdateSummary:Summary(11)];
    [c.notificationChatInfoByChatID removeAllObjects];
    Resolve(c,NO);
    Require([center.deliveredNotifications count]==0, "logout clear drops pending delivery even with same client pointer");
    c=Controller(); [c.client.muteState recordTDLibObject:Chat(@-100,NO,0,YES) atUnixTime:Now()];
    c.localMute=YES; [c presentNotificationForUpdateSummary:Summary(12)];
    Require([center.deliveredNotifications count]==0, "local mute overrides authoritative unmuted server policy");
    c.localMute=NO; [c presentNotificationForUpdateSummary:Summary(13)];
    Require([center.deliveredNotifications count]==1, "ending local mute permits new message without marking previous messages read");
    c=Controller(); [c presentNotificationForUpdateSummary:Summary(15)]; c.localMute=YES; Resolve(c,NO);
    Require([center.deliveredNotifications count]==0, "local mute while enrichment is pending blocks completion");
    c=Controller(); [c.client.muteState recordTDLibObject:Chat(@-100,NO,0,YES) atUnixTime:Now()];
    NSMutableDictionary *oldDeferred=[NSMutableDictionary dictionaryWithDictionary:Summary(14)];
    [oldDeferred setObject:[NSNumber numberWithDouble:Now()-60] forKey:@"notification_deferred_at"];
    [c deliverNotificationForValidatedSummary:oldDeferred];
    Require([center.deliveredNotifications count]==0, "deferred delivery does not replay after sleep or long retry");

    c=Controller(); [c.client.muteState recordTDLibObject:Chat(@-100,NO,1000,YES) atUnixTime:Now()];
    ProbeNotification *muted=[[[ProbeNotification alloc] init] autorelease]; muted.userInfo=Summary(9);
    ProbeNotification *other=[[[ProbeNotification alloc] init] autorelease]; other.userInfo=[NSDictionary dictionaryWithObjectsAndKeys:@-200,@"chat_id",@9,@"message_id",nil];
    ProbeNotification *call=[[[ProbeNotification alloc] init] autorelease]; call.userInfo=[NSDictionary dictionaryWithObjectsAndKeys:@-100,@"chat_id",@"call",@"kind",nil];
    [center.deliveredNotifications addObjectsFromArray:[NSArray arrayWithObjects:muted,other,call,nil]];
    [center.scheduledNotifications addObjectsFromArray:[NSArray arrayWithObjects:muted,other,call,nil]];
    [c removeMutedMessageNotifications];
    Require([center.deliveredNotifications count]==2 && [center.scheduledNotifications count]==2, "purge removes queued and delivered muted messages only");
    puts("Notification mute production probe passed: inherited/direct policy, expiry, fail-closed enrichment, live changes, queued/delivered purge and preserved unread state.");
    [pool drain]; return 0;
}
