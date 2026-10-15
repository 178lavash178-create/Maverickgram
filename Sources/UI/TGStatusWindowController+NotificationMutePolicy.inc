- (BOOL)notificationInfoSuppressedByMute:(id)info {
    if (![info isKindOfClass:[NSDictionary class]]) { return NO; }
    id chatID = [info objectForKey:@"chat_id"], messageID = [info objectForKey:@"message_id"];
    if (![chatID isKindOfClass:[NSNumber class]] || [chatID longLongValue] == 0 ||
        ![messageID isKindOfClass:[NSNumber class]] || [messageID longLongValue] <= 0) { return NO; }
    NSNumber *state = [self.client notificationMuteStateForChatID:chatID];
    return !state || [state boolValue] || [self isChatIDLocallyMuted:chatID];
}

/* UI delivery always asks the live Core cache, never an avatar/title snapshot. */
- (void)removeMutedMessageNotifications {
    Class centerClass = NSClassFromString(@"NSUserNotificationCenter");
    if (centerClass) {
        TGRemoveMutedMessageNotifications([centerClass defaultUserNotificationCenter], ^BOOL(NSNumber *chatID) {
            return [self isChatIDMutedForNotifications:chatID];
        });
    }
    NSArray *keys = [[self.notificationChatInfoByChatID allKeys] copy];
    for (NSString *key in keys) {
        NSNumber *chatID = [NSNumber numberWithLongLong:[key longLongValue]];
        if (![self isChatIDMutedForNotifications:chatID]) { continue; }
        NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:[self.notificationChatInfoByChatID objectForKey:key]];
        [entry removeObjectForKey:@"pending_summaries"];
        [self.notificationChatInfoByChatID setObject:entry forKey:key];
    }
    [keys release];
}

- (void)handleNotificationMuteSettingsChanged {
    [self removeMutedMessageNotifications];
    [self applyLocalNotificationMuteStateToItems:self.chatItems];
    [self applyLocalNotificationMuteStateToItems:self.chatItemsBeforeTopicList];
    [self.chatTableView reloadData];
    [self updateApplicationBadge];
}

- (void)deferNotificationSummaryUntilMuteStateKnown:(NSDictionary *)summary {
    NSNumber *chatID = [summary objectForKey:@"chat_id"];
    NSString *key = [self notificationCacheKeyForChatID:chatID];
    if (![key length] || !self.client) { return; }
    NSDictionary *cached = [self.notificationChatInfoByChatID objectForKey:key];
    NSMutableDictionary *entry = cached ? [NSMutableDictionary dictionaryWithDictionary:cached] : [NSMutableDictionary dictionary];
    NSArray *existing = [entry objectForKey:@"pending_summaries"];
    NSMutableArray *pending = existing ? [NSMutableArray arrayWithArray:existing] : [NSMutableArray array];
    NSMutableDictionary *queuedSummary = [NSMutableDictionary dictionaryWithDictionary:summary];
    [queuedSummary setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"notification_deferred_at"];
    [pending addObject:queuedSummary];
    /* Bounded transient queue, never persisted or replayed after reconnect. */
    if ([pending count] > 32) { [pending removeObjectAtIndex:0]; }
    [entry setObject:pending forKey:@"pending_summaries"];
    [self.notificationChatInfoByChatID setObject:entry forKey:key];
    [self requestNotificationChatInfoFetchForChatID:chatID cacheKey:key];
}
