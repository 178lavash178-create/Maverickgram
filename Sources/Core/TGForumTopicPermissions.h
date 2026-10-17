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
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:TGForumPermissionFlag(topic,@"is_outgoing")], @"topic_is_outgoing",
        [NSNumber numberWithBool:general], @"topic_is_general",
        [NSNumber numberWithBool:create], @"create",
        [NSNumber numberWithBool:validTopic && (manage || owned)], @"rename",
        [NSNumber numberWithBool:validTopic && (manage || owned)], @"close",
        [NSNumber numberWithBool:validTopic && (manage || owned)], @"reopen",
        [NSNumber numberWithBool:validTopic && !general && manage], @"pin",
        [NSNumber numberWithBool:validTopic && !general && manage], @"unpin",
        [NSNumber numberWithBool:validTopic && !general && remove], @"delete", nil];
    id groupID=[context objectForKey:@"supergroup_id"];
    if ([groupID respondsToSelector:@selector(longLongValue)] && [groupID longLongValue]>0)
        [result setObject:groupID forKey:@"supergroup_id"];
    return result;
}

/* Only self role/capability fields cross the receiver-to-UI boundary. */
static inline NSDictionary *TGForumTopicRightsUpdateSummary(NSDictionary *update) {
    if (![[update objectForKey:@"@type"] isEqual:@"updateSupergroup"]) return nil;
    NSDictionary *group=[[update objectForKey:@"supergroup"] isKindOfClass:[NSDictionary class]] ? [update objectForKey:@"supergroup"] : nil;
    id groupID=[group objectForKey:@"id"];
    NSDictionary *status=[[group objectForKey:@"status"] isKindOfClass:[NSDictionary class]] ? [group objectForKey:@"status"] : nil;
    if (![groupID respondsToSelector:@selector(longLongValue)] || [groupID longLongValue]<=0 || ![[status objectForKey:@"@type"] isKindOfClass:[NSString class]]) return nil;
    NSMutableDictionary *safeStatus=[NSMutableDictionary dictionaryWithObject:[status objectForKey:@"@type"] forKey:@"@type"];
    [safeStatus setObject:[NSNumber numberWithBool:TGForumPermissionFlag(status,@"is_member")] forKey:@"is_member"];
    // Creator has is_member in current schemas; absence retains legacy semantics.
    if (![status objectForKey:@"is_member"]) [safeStatus removeObjectForKey:@"is_member"];
    NSDictionary *rights=[[status objectForKey:@"rights"] isKindOfClass:[NSDictionary class]] ? [status objectForKey:@"rights"] : status;
    NSDictionary *safeRights=[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:TGForumPermissionFlag(rights,@"can_manage_topics")],@"can_manage_topics",
        [NSNumber numberWithBool:TGForumPermissionFlag(rights,@"can_delete_messages")],@"can_delete_messages",nil];
    [safeStatus setObject:safeRights forKey:@"rights"];
    return [NSDictionary dictionaryWithObjectsAndKeys:@"forum_topic_rights",@"kind",groupID,@"supergroup_id",safeStatus,@"status",nil];
}
