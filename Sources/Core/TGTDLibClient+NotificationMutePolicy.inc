- (NSNumber *)notificationMuteStateForChatID:(NSNumber *)chatID {
    return [_notificationMuteState mutedForChatID:chatID atUnixTime:[[NSDate date] timeIntervalSince1970]];
}

- (NSString *)notificationScopeTypeForChatTypeObject:(id)chatTypeObject {
    return TGNotificationScopeForChatType(chatTypeObject);
}

- (BOOL)scopeNotificationsMutedForType:(NSString *)scopeType timeout:(NSTimeInterval)timeout {
    NSNumber *state = [_notificationMuteState mutedForScopeType:scopeType atUnixTime:[[NSDate date] timeIntervalSince1970]];
    if (state) { return [state boolValue]; }
    if ([scopeType length] == 0) { return YES; }
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
        @"getScopeNotificationSettings", @"@type", [NSDictionary dictionaryWithObject:scopeType forKey:@"@type"], @"scope", nil];
    NSDictionary *response = [self sendTDLibRequestAndWaitForExtra:request
        extraPrefix:@"telegraphica-notification-scope" timeout:MIN(MAX(timeout, 0.5), 1.2) errorCode:124 error:NULL];
    NSDictionary *settings = [[response objectForKey:@"notification_settings"] isKindOfClass:[NSDictionary class]]
        ? [response objectForKey:@"notification_settings"] : response;
    if ([[response objectForKey:@"@type"] isEqual:@"scopeNotificationSettings"] || settings != response) {
        [_notificationMuteState recordScopeSettingsIfUnknown:settings type:scopeType atUnixTime:[[NSDate date] timeIntervalSince1970]];
    }
    state = [_notificationMuteState mutedForScopeType:scopeType atUnixTime:[[NSDate date] timeIntervalSince1970]];
    return !state || [state boolValue];
}

- (BOOL)chatNotificationsMutedFromObject:(NSDictionary *)chatObject {
    /* Presentation fallback is also used for forum-topic objects with no chat
       settings. Actual delivery permission comes only from the live tri-state cache. */
    if (![chatObject isKindOfClass:[NSDictionary class]]) { return NO; }
    NSDictionary *settings = [chatObject objectForKey:@"notification_settings"];
    if (![settings isKindOfClass:[NSDictionary class]]) { return NO; }
    if ([[settings objectForKey:@"use_default_mute_for"] boolValue]) {
        return [self scopeNotificationsMutedForType:TGNotificationScopeForChatType([chatObject objectForKey:@"type"]) timeout:0.8];
    }
    id duration = [settings objectForKey:@"mute_for"];
    return ![duration isKindOfClass:[NSNumber class]] || [duration longLongValue] > 0;
}
