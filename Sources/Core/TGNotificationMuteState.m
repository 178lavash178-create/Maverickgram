#import "TGNotificationMuteState.h"

NSString *TGNotificationScopeForChatType(id object) {
    if (![object isKindOfClass:[NSDictionary class]]) { return nil; }
    NSString *type = [object objectForKey:@"@type"];
    if ([type isEqual:@"chatTypePrivate"] || [type isEqual:@"chatTypeSecret"]) { return @"notificationSettingsScopePrivateChats"; }
    if ([type isEqual:@"chatTypeBasicGroup"]) { return @"notificationSettingsScopeGroupChats"; }
    if ([type isEqual:@"chatTypeSupergroup"]) {
        return [[object objectForKey:@"is_channel"] boolValue] ? @"notificationSettingsScopeChannelChats" : @"notificationSettingsScopeGroupChats";
    }
    return nil;
}

static NSDictionary *TGAbsoluteMuteSettings(id object, NSTimeInterval now) {
    if (![object isKindOfClass:[NSDictionary class]]) { return nil; }
    id duration = [object objectForKey:@"mute_for"];
    if (![duration isKindOfClass:[NSNumber class]]) { return nil; }
    NSTimeInterval seconds = MAX(0.0, [duration doubleValue]);
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:seconds > 0.0 ? now + seconds : 0.0], @"until",
            [NSNumber numberWithBool:[[object objectForKey:@"use_default_mute_for"] boolValue]], @"inherit", nil];
}

@implementation TGNotificationMuteState
- (id)init {
    if ((self = [super init])) {
        _lock = [[NSLock alloc] init]; _chats = [[NSMutableDictionary alloc] init]; _scopes = [[NSMutableDictionary alloc] init];
    }
    return self;
}
- (void)dealloc { [_lock release]; [_chats release]; [_scopes release]; [super dealloc]; }
- (void)recordTDLibObject:(NSDictionary *)object atUnixTime:(NSTimeInterval)now {
    if (![object isKindOfClass:[NSDictionary class]]) { return; }
    NSString *type = [object objectForKey:@"@type"];
    if ([type isEqual:@"updateScopeNotificationSettings"]) {
        id scope = [object objectForKey:@"scope"];
        NSString *key = [scope isKindOfClass:[NSDictionary class]] ? [scope objectForKey:@"@type"] : nil;
        NSDictionary *settings = TGAbsoluteMuteSettings([object objectForKey:@"notification_settings"], now);
        if ([key isKindOfClass:[NSString class]] && settings) {
            [_lock lock]; [_scopes setObject:settings forKey:key]; [_lock unlock];
        }
        return;
    }
    NSDictionary *chat = [type isEqual:@"updateNewChat"] ? [object objectForKey:@"chat"] : object;
    BOOL settingsUpdate = [type isEqual:@"updateChatNotificationSettings"];
    if (![type isEqual:@"chat"] && ![type isEqual:@"updateNewChat"] && !settingsUpdate) { return; }
    if (![chat isKindOfClass:[NSDictionary class]]) { return; }
    id chatID = [chat objectForKey:settingsUpdate ? @"chat_id" : @"id"];
    if (![chatID isKindOfClass:[NSNumber class]] || [chatID longLongValue] == 0) { return; }
    NSDictionary *settings = TGAbsoluteMuteSettings([chat objectForKey:@"notification_settings"], now);
    NSString *scope = TGNotificationScopeForChatType([chat objectForKey:@"type"]);
    [_lock lock];
    NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:([_chats objectForKey:chatID] ?: [NSDictionary dictionary])];
    if (settings) { [entry setObject:settings forKey:@"settings"]; }
    if (scope) { [entry setObject:scope forKey:@"scope"]; }
    [_chats setObject:entry forKey:chatID];
    [_lock unlock];
}
- (void)recordScopeSettingsIfUnknown:(NSDictionary *)settings type:(NSString *)type atUnixTime:(NSTimeInterval)now {
    NSDictionary *absolute = TGAbsoluteMuteSettings(settings, now);
    if (![type isKindOfClass:[NSString class]] || !absolute) { return; }
    [_lock lock];
    /* A live update received while the request was waiting is newer than its reply. */
    if (![_scopes objectForKey:type]) { [_scopes setObject:absolute forKey:type]; }
    [_lock unlock];
}
- (NSNumber *)mutedForScopeType:(NSString *)type atUnixTime:(NSTimeInterval)now {
    if (![type isKindOfClass:[NSString class]]) { return nil; }
    [_lock lock]; NSDictionary *settings = [_scopes objectForKey:type];
    NSNumber *result = settings ? [NSNumber numberWithBool:[[settings objectForKey:@"until"] doubleValue] > now] : nil;
    [_lock unlock]; return result;
}
- (NSNumber *)mutedForChatID:(NSNumber *)chatID atUnixTime:(NSTimeInterval)now {
    if (![chatID isKindOfClass:[NSNumber class]]) { return nil; }
    [_lock lock];
    NSDictionary *entry = [_chats objectForKey:chatID];
    NSDictionary *settings = [entry objectForKey:@"settings"];
    if ([[settings objectForKey:@"inherit"] boolValue]) {
        NSString *scope = [entry objectForKey:@"scope"];
        settings = scope ? [_scopes objectForKey:scope] : nil;
    }
    NSNumber *result = settings ? [NSNumber numberWithBool:[[settings objectForKey:@"until"] doubleValue] > now] : nil;
    [_lock unlock]; return result;
}
@end
