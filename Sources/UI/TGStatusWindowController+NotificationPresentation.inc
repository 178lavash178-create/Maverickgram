- (void)presentNotificationForUpdateSummary:(NSDictionary *)summary {
    if (TGMountainLionSafeLoginModeEnabled()) {
        return;
    }
    if (!TGUserDefaultBoolWithDefault(TGNotificationsEnabledDefaultsKey, YES)) {
        return;
    }
    if (![summary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *direction = [summary objectForKey:@"direction"];
    if (![direction isEqualToString:@"Incoming"]) {
        return;
    }

    NSNumber *chatID = [summary objectForKey:@"chat_id"];
    if ([self isChatIDMutedForNotifications:chatID]) {
        return;
    }
    /* Reject replay before chat/avatar enrichment can schedule background work. */
    if (![self.notificationReadState consumeIncomingNotificationSummary:summary
                                                            atUnixTime:[[NSDate date] timeIntervalSince1970]]) { return; }
    if (![self.client notificationMuteStateForChatID:chatID]) {
        [self deferNotificationSummaryUntilMuteStateKnown:summary];
        return;
    }
    [self deliverNotificationForValidatedSummary:summary];
}

- (void)deliverNotificationForValidatedSummary:(NSDictionary *)summary {
    NSNumber *chatID = [summary objectForKey:@"chat_id"];
    NSNumber *liveState = [self.client notificationMuteStateForChatID:chatID];
    if (!liveState || [liveState boolValue] || [self isChatIDLocallyMuted:chatID] ||
        !TGUserDefaultBoolWithDefault(TGNotificationsEnabledDefaultsKey, YES) || TGMountainLionSafeLoginModeEnabled()) { return; }
    id deferredAt = [summary objectForKey:@"notification_deferred_at"];
    if ([deferredAt isKindOfClass:[NSNumber class]]) {
        NSTimeInterval age = [[NSDate date] timeIntervalSince1970] - [deferredAt doubleValue];
        /* Never replay queued alerts after sleep or a delayed network retry. */
        if (age < 0.0 || age > 5.0) { return; }
    }
    /* An enrichment completion can follow a read, a mute or a settings change. */
    if ([self.notificationReadState isReadNotificationInfo:summary]) { return; }
    NSDictionary *notificationChatInfo = [self notificationChatInfoForChatID:chatID];
    NSString *title = [notificationChatInfo objectForKey:@"title"];
    if ([title length] == 0) {
        title = @"New message";
    }
    NSString *preview = [summary objectForKey:@"preview"];
    if (![preview isKindOfClass:[NSString class]] || [preview length] == 0) {
        preview = @"New message";
    }
    if (!TGUserDefaultBoolWithDefault(TGNotificationPreviewEnabledDefaultsKey, YES)) {
        preview = TGLoc(@"notification.hiddenPreview");
    }
    NSUserNotification *notification = [[[NSUserNotification alloc] init] autorelease];
    [notification setTitle:title];
    [notification setInformativeText:preview];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if ([chatID respondsToSelector:@selector(longLongValue)]) {
        [userInfo setObject:[NSNumber numberWithLongLong:[chatID longLongValue]] forKey:@"chat_id"];
    }
    id messageID = [summary objectForKey:@"message_id"];
    if ([messageID respondsToSelector:@selector(longLongValue)]) {
        [userInfo setObject:[NSNumber numberWithLongLong:[messageID longLongValue]] forKey:@"message_id"];
    }
    id messageThreadID = [summary objectForKey:@"message_thread_id"];
    if ([messageThreadID respondsToSelector:@selector(longLongValue)] && [messageThreadID longLongValue] > 0) {
        [userInfo setObject:[NSNumber numberWithLongLong:[messageThreadID longLongValue]] forKey:@"message_thread_id"];
    }
    if ([self.notificationReadState isReadNotificationInfo:userInfo]) { return; }
    if ([userInfo count] > 0) {
        [notification setUserInfo:userInfo];
    }
    if ([notification respondsToSelector:NSSelectorFromString(@"setContentImage:")]) {
        NSImage *avatarImage = [self notificationAvatarImageForChatID:chatID];
        if (avatarImage) {
            [notification setValue:avatarImage forKey:@"contentImage"];
        }
    }
    if (TGUserDefaultBoolWithDefault(TGNotificationSoundEnabledDefaultsKey, YES)) {
        [notification setSoundName:NSUserNotificationDefaultSoundName];
    }
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
