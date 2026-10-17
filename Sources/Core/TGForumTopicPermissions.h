#import <Foundation/Foundation.h>

/* Unknown or unavailable rights fail closed. Topic ownership only grants the
   documented rename/close exception; deletion requires explicit server rights. */
static inline BOOL TGForumPermissionFlag(NSDictionary *object, NSString *key) {
    id value = [object isKindOfClass:[NSDictionary class]] ? [object objectForKey:key] : nil;
    return [value respondsToSelector:@selector(boolValue)] && [value boolValue];
}
static inline NSDictionary *TGForumTopicActionPermissions(NSDictionary *context, NSDictionary *topic, NSNumber *topicID) {
    if (![context isKindOfClass:[NSDictionary class]]) context=nil;
    if (![topic isKindOfClass:[NSDictionary class]]) topic=nil;
    NSDictionary *status = [[context objectForKey:@"status"] isKindOfClass:[NSDictionary class]] ? [context objectForKey:@"status"] : nil;
    NSString *type = [status objectForKey:@"@type"];
    BOOL creator = [type isEqual:@"chatMemberStatusCreator"] &&
        (![status objectForKey:@"is_member"] || TGForumPermissionFlag(status,@"is_member"));
    BOOL admin = [type isEqual:@"chatMemberStatusAdministrator"];
    BOOL member = creator || admin || [type isEqual:@"chatMemberStatusMember"] ||
        ([type isEqual:@"chatMemberStatusRestricted"] && TGForumPermissionFlag(status,@"is_member"));
    NSDictionary *rights = [[status objectForKey:@"rights"] isKindOfClass:[NSDictionary class]] ? [status objectForKey:@"rights"] : status;
    BOOL manage = creator || (admin && TGForumPermissionFlag(rights,@"can_manage_topics"));
    BOOL remove = creator || (admin && TGForumPermissionFlag(rights,@"can_delete_messages"));
    BOOL validTopic = [topicID respondsToSelector:@selector(longLongValue)] && [topicID longLongValue]>0;
    BOOL general = (validTopic && [topicID longLongValue]==1) || TGForumPermissionFlag(topic,@"is_general");
    BOOL owned = member && TGForumPermissionFlag(topic,@"is_outgoing");
    BOOL create = manage || (member && TGForumPermissionFlag([context objectForKey:@"permissions"],@"can_create_topics"));
    if ([type isEqual:@"chatMemberStatusRestricted"])
        create = member && TGForumPermissionFlag([status objectForKey:@"permissions"],@"can_create_topics");
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:create], @"create",
        [NSNumber numberWithBool:validTopic && (manage || owned)], @"rename",
        [NSNumber numberWithBool:validTopic && (manage || owned)], @"close",
        [NSNumber numberWithBool:validTopic && (manage || owned)], @"reopen",
        [NSNumber numberWithBool:validTopic && !general && manage], @"pin",
        [NSNumber numberWithBool:validTopic && !general && manage], @"unpin",
        [NSNumber numberWithBool:validTopic && !general && remove], @"delete", nil];
}
