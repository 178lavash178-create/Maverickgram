#import "TGTDLibClient+ForumTopics.h"
#import "TGForumTopicPermissions.h"

@interface TGTDLibClient (ForumTopicsPrivate)

- (NSDictionary *)sendTDLibRequestAndWaitForExtra:(NSDictionary *)request
                                      extraPrefix:(NSString *)extraPrefix
                                          timeout:(NSTimeInterval)timeout
                                        errorCode:(NSInteger)errorCode
                                            error:(NSError **)error;
- (NSError *)errorWithDescription:(NSString *)description code:(NSInteger)code;

@end

@implementation TGTDLibClient (ForumTopics)

- (NSDictionary *)forumTopicRightsForChatID:(NSNumber *)chatID timeout:(NSTimeInterval)timeout {
    if (![chatID respondsToSelector:@selector(longLongValue)] || [chatID longLongValue]==0) return nil;
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:@"getChat",@"@type",chatID,@"chat_id",nil];
    NSDictionary *chat = [self sendTDLibRequestAndWaitForExtra:request extraPrefix:@"telegraphica-forum-rights-chat" timeout:timeout errorCode:118 error:NULL];
    NSDictionary *chatType = [[chat objectForKey:@"type"] isKindOfClass:[NSDictionary class]] ? [chat objectForKey:@"type"] : nil;
    NSNumber *groupID = [chatType objectForKey:@"supergroup_id"];
    if (![[chatType objectForKey:@"@type"] isEqual:@"chatTypeSupergroup"] || ![groupID respondsToSelector:@selector(longLongValue)]) return nil;
    request = [NSDictionary dictionaryWithObjectsAndKeys:@"getSupergroup",@"@type",groupID,@"supergroup_id",nil];
    NSDictionary *group = [self sendTDLibRequestAndWaitForExtra:request extraPrefix:@"telegraphica-forum-rights-group" timeout:timeout errorCode:118 error:NULL];
    if (![[group objectForKey:@"@type"] isEqual:@"supergroup"]) return nil;
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if ([[group objectForKey:@"status"] isKindOfClass:[NSDictionary class]]) [result setObject:[group objectForKey:@"status"] forKey:@"status"];
    if ([[chat objectForKey:@"permissions"] isKindOfClass:[NSDictionary class]]) [result setObject:[chat objectForKey:@"permissions"] forKey:@"permissions"];
    return result;
}

- (BOOL)tg_forumRequestHasCurrentPermission:(NSDictionary *)request timeout:(NSTimeInterval)timeout error:(NSError **)error {
    NSString *type = [request objectForKey:@"@type"];
    NSString *operation = nil;
    if ([type isEqual:@"createForumTopic"]) operation=@"create";
    else if ([type isEqual:@"editForumTopic"]) operation=@"rename";
    else if ([type isEqual:@"toggleForumTopicIsClosed"]) operation=@"close";
    else if ([type isEqual:@"toggleForumTopicIsPinned"]) operation=@"pin";
    else if ([type isEqual:@"deleteForumTopic"]) operation=@"delete";
    if (!operation) return NO;
    NSNumber *chatID = [request objectForKey:@"chat_id"], *topicID=[request objectForKey:@"forum_topic_id"];
    NSDictionary *rights = [self forumTopicRightsForChatID:chatID timeout:MIN(timeout,2.0)];
    NSDictionary *info = nil;
    if (![operation isEqual:@"create"]) {
        NSDictionary *topicRequest = [NSDictionary dictionaryWithObjectsAndKeys:@"getForumTopic",@"@type",chatID,@"chat_id",topicID,@"forum_topic_id",topicID,@"message_thread_id",nil];
        NSDictionary *topic = [self sendTDLibRequestAndWaitForExtra:topicRequest extraPrefix:@"telegraphica-forum-current-topic" timeout:MIN(timeout,2.0) errorCode:118 error:error];
        info = [[topic objectForKey:@"info"] isKindOfClass:[NSDictionary class]] ? [topic objectForKey:@"info"] : nil;
        if (!info) return NO;
        id returnedTopicID=[info objectForKey:@"forum_topic_id"];
        if (!returnedTopicID) returnedTopicID=[info objectForKey:@"message_thread_id"];
        id returnedChatID=[info objectForKey:@"chat_id"];
        if ((returnedTopicID && (![returnedTopicID respondsToSelector:@selector(longLongValue)] || [returnedTopicID longLongValue]!=[topicID longLongValue])) ||
            (returnedChatID && (![returnedChatID respondsToSelector:@selector(longLongValue)] || [returnedChatID longLongValue]!=[chatID longLongValue]))) return NO;
    }
    if (TGForumPermissionFlag(TGForumTopicActionPermissions(rights,info,topicID),operation)) return YES;
    if (error) *error=[self errorWithDescription:@"This forum topic action is not permitted by the current chat rights." code:118];
    return NO;
}


- (NSString *)tg_validForumTopicName:(NSString *)name error:(NSError **)error {
    if (![name isKindOfClass:[NSString class]]) {
        if (error) {
            *error = [self errorWithDescription:@"Forum topic name is required." code:118];
        }
        return nil;
    }

    NSMutableString *singleLine = [NSMutableString stringWithString:name];
    [singleLine replaceOccurrencesOfString:@"\r" withString:@" " options:0 range:NSMakeRange(0, [singleLine length])];
    [singleLine replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0, [singleLine length])];
    NSString *trimmed = [singleLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmed length] == 0 || [trimmed length] > 128) {
        if (error) {
            *error = [self errorWithDescription:@"Forum topic name must contain between 1 and 128 characters." code:118];
        }
        return nil;
    }
    return trimmed;
}

- (BOOL)tg_validateForumChatID:(NSNumber *)chatID topicID:(NSNumber *)topicID error:(NSError **)error {
    if (![chatID respondsToSelector:@selector(longLongValue)] ||
        (topicID && ![topicID respondsToSelector:@selector(longLongValue)])) {
        if (error) {
            *error = [self errorWithDescription:@"Forum topic action requires valid chat and topic identifiers." code:118];
        }
        return NO;
    }
    return YES;
}

- (BOOL)tg_forumTopicRequestSucceeded:(NSDictionary *)request
                           extraPrefix:(NSString *)extraPrefix
                               timeout:(NSTimeInterval)timeout
                                 error:(NSError **)error {
    if (![self tg_forumRequestHasCurrentPermission:request timeout:timeout error:error]) return NO;
    NSDictionary *response = [self sendTDLibRequestAndWaitForExtra:request
                                                       extraPrefix:extraPrefix
                                                           timeout:timeout
                                                         errorCode:118
                                                             error:error];
    if (![response isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    NSString *responseType = [response objectForKey:@"@type"];
    return ([responseType isEqualToString:@"ok"] || [responseType isEqualToString:@"forumTopicInfo"]);
}

- (BOOL)createForumTopicInChatID:(NSNumber *)chatID
                            name:(NSString *)name
                         timeout:(NSTimeInterval)timeout
                           error:(NSError **)error {
    if (![self tg_validateForumChatID:chatID topicID:nil error:error]) {
        return NO;
    }
    NSString *validatedName = [self tg_validForumTopicName:name error:error];
    if (!validatedName) {
        return NO;
    }

    NSDictionary *icon = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"forumTopicIcon", @"@type",
                          [NSNumber numberWithUnsignedInt:0x6FB9F0], @"color",
                          [NSNumber numberWithLongLong:0], @"custom_emoji_id",
                          nil];
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"createForumTopic", @"@type",
                             chatID, @"chat_id",
                             validatedName, @"name",
                             [NSNumber numberWithBool:NO], @"is_name_implicit",
                             icon, @"icon",
                             nil];
    return [self tg_forumTopicRequestSucceeded:request
                                   extraPrefix:@"telegraphica-create-forum-topic"
                                       timeout:timeout
                                         error:error];
}

- (BOOL)renameForumTopicInChatID:(NSNumber *)chatID
                         topicID:(NSNumber *)topicID
                            name:(NSString *)name
                         timeout:(NSTimeInterval)timeout
                           error:(NSError **)error {
    if (![self tg_validateForumChatID:chatID topicID:topicID error:error]) {
        return NO;
    }
    NSString *validatedName = [self tg_validForumTopicName:name error:error];
    if (!validatedName) {
        return NO;
    }

    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"editForumTopic", @"@type",
                             chatID, @"chat_id",
                             topicID, @"forum_topic_id",
                             topicID, @"message_thread_id",
                             validatedName, @"name",
                             [NSNumber numberWithBool:NO], @"edit_icon_custom_emoji",
                             [NSNumber numberWithLongLong:0], @"icon_custom_emoji_id",
                             nil];
    return [self tg_forumTopicRequestSucceeded:request
                                   extraPrefix:@"telegraphica-edit-forum-topic"
                                       timeout:timeout
                                         error:error];
}

- (BOOL)setForumTopicInChatID:(NSNumber *)chatID
                      topicID:(NSNumber *)topicID
                       closed:(BOOL)closed
                      timeout:(NSTimeInterval)timeout
                        error:(NSError **)error {
    if (![self tg_validateForumChatID:chatID topicID:topicID error:error]) {
        return NO;
    }
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"toggleForumTopicIsClosed", @"@type",
                             chatID, @"chat_id",
                             topicID, @"forum_topic_id",
                             topicID, @"message_thread_id",
                             [NSNumber numberWithBool:closed], @"is_closed",
                             nil];
    return [self tg_forumTopicRequestSucceeded:request
                                   extraPrefix:@"telegraphica-toggle-forum-topic-closed"
                                       timeout:timeout
                                         error:error];
}

- (BOOL)setForumTopicInChatID:(NSNumber *)chatID
                      topicID:(NSNumber *)topicID
                       pinned:(BOOL)pinned
                      timeout:(NSTimeInterval)timeout
                        error:(NSError **)error {
    if (![self tg_validateForumChatID:chatID topicID:topicID error:error]) {
        return NO;
    }
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"toggleForumTopicIsPinned", @"@type",
                             chatID, @"chat_id",
                             topicID, @"forum_topic_id",
                             topicID, @"message_thread_id",
                             [NSNumber numberWithBool:pinned], @"is_pinned",
                             nil];
    return [self tg_forumTopicRequestSucceeded:request
                                   extraPrefix:@"telegraphica-toggle-forum-topic-pinned"
                                       timeout:timeout
                                         error:error];
}

- (BOOL)deleteForumTopicInChatID:(NSNumber *)chatID
                         topicID:(NSNumber *)topicID
                         timeout:(NSTimeInterval)timeout
                           error:(NSError **)error {
    if (![self tg_validateForumChatID:chatID topicID:topicID error:error]) {
        return NO;
    }
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"deleteForumTopic", @"@type",
                             chatID, @"chat_id",
                             topicID, @"forum_topic_id",
                             topicID, @"message_thread_id",
                             nil];
    return [self tg_forumTopicRequestSucceeded:request
                                   extraPrefix:@"telegraphica-delete-forum-topic"
                                       timeout:timeout
                                         error:error];
}

@end
