#import "TGNotificationDeliverySupport.h"
#import "TGNotificationReadState.h"
#import "../Core/TGChatItem.h"

void TGRecordConfirmedNotificationChatReads(NSArray *items, TGNotificationReadState *readState) {
    if (![items isKindOfClass:[NSArray class]]) { return; }
    for (id value in items) {
        if (![value isKindOfClass:[TGChatItem class]] || [value isForumTopic]) { continue; }
        [readState recordReadInboxMessageID:[value lastReadInboxMessageID] chatID:[value chatID]];
    }
}

void TGRemoveConfirmedReadNotifications(id center, TGNotificationReadState *readState) {
    if (![center respondsToSelector:@selector(deliveredNotifications)] ||
        ![center respondsToSelector:@selector(removeDeliveredNotification:)]) { return; }
    NSArray *delivered = [[center deliveredNotifications] copy];
    for (id notification in delivered) {
        if ([notification respondsToSelector:@selector(userInfo)] &&
            [readState isReadNotificationInfo:[notification userInfo]]) {
            [center removeDeliveredNotification:notification];
        }
    }
    [delivered release];
}

void TGRemoveMessageNotificationsAfterLogout(id center) {
    if (![center respondsToSelector:@selector(deliveredNotifications)] ||
        ![center respondsToSelector:@selector(removeDeliveredNotification:)]) { return; }
    NSArray *delivered = [[center deliveredNotifications] copy];
    for (id notification in delivered) {
        if (![notification respondsToSelector:@selector(userInfo)]) { continue; }
        id info = [notification userInfo];
        if (![info isKindOfClass:[NSDictionary class]]) { continue; }
        id chatID = [info objectForKey:@"chat_id"];
        id messageID = [info objectForKey:@"message_id"];
        if ([chatID isKindOfClass:[NSNumber class]] && [chatID longLongValue] != 0 &&
            [messageID isKindOfClass:[NSNumber class]] && [messageID longLongValue] > 0) {
            [center removeDeliveredNotification:notification];
        }
    }
    [delivered release];
}

void TGRemoveMutedMessageNotifications(id center, BOOL (^isMuted)(NSNumber *chatID)) {
    if (!isMuted) { return; }
    NSArray *selectors = [NSArray arrayWithObjects:@"deliveredNotifications", @"scheduledNotifications", nil];
    for (NSString *name in selectors) {
        SEL getter = NSSelectorFromString(name);
        SEL remover = NSSelectorFromString([name isEqual:@"deliveredNotifications"] ? @"removeDeliveredNotification:" : @"removeScheduledNotification:");
        if (![center respondsToSelector:getter] || ![center respondsToSelector:remover]) { continue; }
        NSArray *notifications = [[center performSelector:getter] copy];
        for (id notification in notifications) {
            if (![notification respondsToSelector:@selector(userInfo)]) { continue; }
            id info = [notification userInfo];
            if (![info isKindOfClass:[NSDictionary class]]) { continue; }
            id chatID = [info objectForKey:@"chat_id"], messageID = [info objectForKey:@"message_id"];
            if ([chatID isKindOfClass:[NSNumber class]] && [chatID longLongValue] != 0 &&
                [messageID isKindOfClass:[NSNumber class]] && [messageID longLongValue] > 0 && isMuted(chatID)) {
                [center performSelector:remover withObject:notification];
            }
        }
        [notifications release];
    }
}
