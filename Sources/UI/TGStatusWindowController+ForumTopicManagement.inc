static NSString * const TGForumTopicOperationCreate = @"create";
static NSString * const TGForumTopicOperationRename = @"rename";
static NSString * const TGForumTopicOperationClose = @"close";
static NSString * const TGForumTopicOperationReopen = @"reopen";
static NSString * const TGForumTopicOperationPin = @"pin";
static NSString * const TGForumTopicOperationUnpin = @"unpin";
static NSString * const TGForumTopicOperationDelete = @"delete";

- (BOOL)forumTopicItemIsCurrent:(TGChatItem *)item {
    return [item isKindOfClass:[TGChatItem class]] && [item isForumTopic] && self.client &&
        [self.forumTopicItems isKindOfClass:[NSArray class]] && [self.currentAuthState isEqualToString:@"ready"] &&
        (self.showingForumTopicList || self.forumTopicsPresentedInTopBar) &&
        [[item parentChatID] isEqual:self.topicParentChatID] &&
        [self.forumTopicItems indexOfObjectIdenticalTo:item] != NSNotFound;
}

// Main-thread role updates override old asynchronously loaded topic snapshots.
// The bounded cache contains capabilities only and is scoped to client/account.
static char TGForumTopicRoleCacheKey;
- (NSMutableDictionary *)forumTopicRoleContexts {
    NSMutableDictionary *state=objc_getAssociatedObject(self,&TGForumTopicRoleCacheKey);
    id account=self.profileUserID ? (id)self.profileUserID : (id)[NSNull null];
    if ([state objectForKey:@"client"]!=self.client || ![[state objectForKey:@"account"] isEqual:account]) {
        state=[NSMutableDictionary dictionaryWithObjectsAndKeys:account,@"account",[NSMutableDictionary dictionary],@"roles",nil];
        if (self.client) [state setObject:self.client forKey:@"client"];
        objc_setAssociatedObject(self,&TGForumTopicRoleCacheKey,state,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return [state objectForKey:@"roles"];
}
- (void)refreshForumTopicItemRightsFromCache:(TGChatItem *)item {
    if (![self forumTopicItemIsCurrent:item]) return;
    NSDictionary *permissions=[item forumTopicActionPermissions];
    id groupID=[permissions objectForKey:@"supergroup_id"];
    NSDictionary *context=groupID ? [[self forumTopicRoleContexts] objectForKey:groupID] : nil;
    if (!context) return;
    NSDictionary *topic=[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:TGForumPermissionFlag(permissions,@"topic_is_outgoing")],@"is_outgoing",
        [NSNumber numberWithBool:TGForumPermissionFlag(permissions,@"topic_is_general")],@"is_general",nil];
    [item setForumTopicActionPermissions:TGForumTopicActionPermissions(context,topic,[item messageThreadID])];
}
- (void)applyForumTopicRightsUpdateSummary:(NSDictionary *)summary {
    if (![self.currentAuthState isEqualToString:@"ready"] || !self.client ||
        ![[summary objectForKey:@"kind"] isEqual:@"forum_topic_rights"]) return;
    id groupID=[summary objectForKey:@"supergroup_id"];
    if (![groupID respondsToSelector:@selector(longLongValue)] || [groupID longLongValue]<=0) return;
    NSMutableDictionary *contexts=[self forumTopicRoleContexts];
    if ([contexts count]>=64 && ![contexts objectForKey:groupID]) {
        // Preserve the displayed group's revocation even during unrelated updates.
        id activeID=[self.forumTopicItems count] ? [[[self.forumTopicItems objectAtIndex:0] forumTopicActionPermissions] objectForKey:@"supergroup_id"] : nil;
        id active=activeID ? [[contexts objectForKey:activeID] retain] : nil;
        [contexts removeAllObjects];
        if (active) { [contexts setObject:active forKey:activeID];[active release]; }
    }
    [contexts setObject:summary forKey:groupID];
    for (TGChatItem *item in self.forumTopicItems) [self refreshForumTopicItemRightsFromCache:item];
}
- (BOOL)forumTopicItem:(TGChatItem *)item allowsOperation:(NSString *)operation {
    if (![self forumTopicItemIsCurrent:item]) return NO;
    [self refreshForumTopicItemRightsFromCache:item];
    id flag = [[item forumTopicActionPermissions] objectForKey:operation];
    return [flag respondsToSelector:@selector(boolValue)] && [flag boolValue];
}

- (void)markForumTopicReadFromMenu:(id)sender {
    TGChatItem *item = [self forumTopicItemFromSender:sender];
    if (![self forumTopicItemIsCurrent:item] ||
        ![[item messageThreadID] respondsToSelector:@selector(longLongValue)] || [[item messageThreadID] longLongValue]<=0) return;
    TGTDLibClient *client=[self.client retain];
    TGChatItem *topic=[item retain];
    NSNumber *chatID=[[item parentChatID] retain], *threadID=[[item messageThreadID] retain];
    NSString *kind=[[item messageTopicKind] copy];
    NSUInteger generation=self.forumTopicNavigationGeneration;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
        NSError *error=nil;
        NSArray *messages=[[client recentMessagePreviewItemsForChatID:chatID messageThreadID:threadID messageTopicKind:kind limit:50 timeout:6.0 error:&error] copy];
        NSMutableArray *ids=[NSMutableArray array];
        for (TGMessageItem *message in messages) {
            if ([message isKindOfClass:[TGMessageItem class]] && [[message chatID] isEqual:chatID] && [[message messageID] longLongValue]>0)
                [ids addObject:[message messageID]];
        }
        NSArray *messageIDs=[ids copy];
        NSString *errorText=[[error localizedDescription] copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (client!=self.client || generation!=self.forumTopicNavigationGeneration || ![self forumTopicItemIsCurrent:topic] || ![messageIDs count]) {
                if (client==self.client && generation==self.forumTopicNavigationGeneration && [errorText length]) [self.statusField setStringValue:TGLoc(@"chat.markReadFailed")];
                [messageIDs release]; [messages release]; [errorText release]; [client release]; [topic release]; [chatID release]; [threadID release]; [kind release]; return;
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                NSAutoreleasePool *readPool=[[NSAutoreleasePool alloc] init];
                BOOL success=[client markMessagesAsReadForChatID:chatID messageThreadID:threadID messageTopicKind:kind messageIDs:messageIDs timeout:5.0 error:NULL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (client==self.client && generation==self.forumTopicNavigationGeneration && [self forumTopicItemIsCurrent:topic]) {
                        if (success) {
                            [self recordReadNotificationMessageIDs:messageIDs chatID:chatID];
                            [self clearUnreadCountForChatID:chatID messageThreadID:threadID];
                            [self.statusField setStringValue:TGLoc(@"chat.markedRead")];
                        } else [self.statusField setStringValue:TGLoc(@"chat.markReadFailed")];
                    }
                    [messageIDs release]; [messages release]; [errorText release]; [client release]; [topic release]; [chatID release]; [threadID release]; [kind release];
                });
                [readPool drain];
            });
        });
        [pool drain];
    });
}

- (NSString *)forumTopicNameFromPromptWithTitle:(NSString *)title
                                         detail:(NSString *)detail
                                   initialValue:(NSString *)initialValue
                                    actionTitle:(NSString *)actionTitle {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:title ? title : @""];
    [alert setInformativeText:detail ? detail : @""];
    [alert addButtonWithTitle:actionTitle ? actionTitle : TGLoc(@"save")];
    [alert addButtonWithTitle:TGLoc(@"cancel")];

    NSTextField *nameField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 0.0, 330.0, 24.0)] autorelease];
    [nameField setStringValue:initialValue ? initialValue : @""];
    [[nameField cell] setPlaceholderString:TGLoc(@"forum.topic.namePlaceholder")];
    [alert setAccessoryView:nameField];
    [[alert window] setInitialFirstResponder:nameField];
    if (TGRunAlert(alert, self.window) != NSAlertFirstButtonReturn) {
        return nil;
    }
    return [[nameField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (TGChatItem *)forumTopicItemFromSender:(id)sender {
    id representedObject = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    return ([representedObject isKindOfClass:[TGChatItem class]] && [representedObject isForumTopic]) ? representedObject : nil;
}

- (void)performForumTopicOperation:(NSString *)operation
                              item:(TGChatItem *)item
                              name:(NSString *)name {
    if (self.forumTopicMutationInFlight || ![self.currentAuthState isEqualToString:@"ready"]) {
        return;
    }

    NSNumber *chatID = nil;
    NSNumber *topicID = nil;
    if ([item isForumTopic]) {
        chatID = [item parentChatID];
        topicID = [item messageThreadID];
    } else {
        chatID = self.topicParentChatID;
    }
    if (![chatID respondsToSelector:@selector(longLongValue)] ||
        (![operation isEqualToString:TGForumTopicOperationCreate] &&
         ![topicID respondsToSelector:@selector(longLongValue)])) {
        [self.statusField setStringValue:TGLoc(@"forum.topic.invalid")];
        return;
    }

    if (item && ![self forumTopicItem:item allowsOperation:operation]) return;
    NSUInteger contextGeneration = self.forumTopicNavigationGeneration;
    self.forumTopicMutationInFlight = YES;
    [self.statusField setStringValue:TGLoc(@"forum.topic.saving")];
    [self appendDetail:[NSString stringWithFormat:@"Forum topic: %@ requested.", operation]];

    TGTDLibClient *client = [self.client retain];
    NSNumber *chatIDCopy = [[NSNumber numberWithLongLong:[chatID longLongValue]] retain];
    NSNumber *topicIDCopy = [topicID respondsToSelector:@selector(longLongValue)] ?
        [[NSNumber numberWithLongLong:[topicID longLongValue]] retain] : nil;
    NSString *operationCopy = [operation copy];
    NSString *nameCopy = [name copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSError *operationError = nil;
        BOOL success = NO;
        if ([operationCopy isEqualToString:TGForumTopicOperationCreate]) {
            success = [client createForumTopicInChatID:chatIDCopy name:nameCopy timeout:8.0 error:&operationError];
        } else if ([operationCopy isEqualToString:TGForumTopicOperationRename]) {
            success = [client renameForumTopicInChatID:chatIDCopy topicID:topicIDCopy name:nameCopy timeout:8.0 error:&operationError];
        } else if ([operationCopy isEqualToString:TGForumTopicOperationClose] ||
                   [operationCopy isEqualToString:TGForumTopicOperationReopen]) {
            success = [client setForumTopicInChatID:chatIDCopy
                                           topicID:topicIDCopy
                                            closed:[operationCopy isEqualToString:TGForumTopicOperationClose]
                                           timeout:8.0
                                             error:&operationError];
        } else if ([operationCopy isEqualToString:TGForumTopicOperationPin] ||
                   [operationCopy isEqualToString:TGForumTopicOperationUnpin]) {
            success = [client setForumTopicInChatID:chatIDCopy
                                           topicID:topicIDCopy
                                            pinned:[operationCopy isEqualToString:TGForumTopicOperationPin]
                                           timeout:8.0
                                             error:&operationError];
        } else if ([operationCopy isEqualToString:TGForumTopicOperationDelete]) {
            success = [client deleteForumTopicInChatID:chatIDCopy topicID:topicIDCopy timeout:8.0 error:&operationError];
        }
        NSString *errorMessage = [[operationError localizedDescription] copy];

        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL current = (client == self.client && contextGeneration == self.forumTopicNavigationGeneration &&
                [self.currentAuthState isEqualToString:@"ready"] && [self.topicParentChatID isEqual:chatIDCopy]);
            self.forumTopicMutationInFlight = NO;
            if (!current) {
                [client release]; [chatIDCopy release]; [topicIDCopy release];
                [operationCopy release]; [nameCopy release]; [errorMessage release]; return;
            }
            if (success) {
                [self.statusField setStringValue:TGLoc(@"forum.topic.saved")];
                [self appendDetail:[NSString stringWithFormat:@"Forum topic: %@ completed.", operationCopy]];
                [self reloadCurrentForumTopicListInteractive:NO];
            } else {
                [self.statusField setStringValue:TGLoc(@"forum.topic.failed")];
                if ([errorMessage length] > 0) {
                    [self appendDetail:[NSString stringWithFormat:@"Forum topic: %@", errorMessage]];
                    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                    [alert setMessageText:TGLoc(@"forum.topic.failed")];
                    [alert setInformativeText:errorMessage];
                    [alert addButtonWithTitle:TGLoc(@"close")];
                    TGRunAlert(alert, self.window);
                }
            }
            [client release];
            [chatIDCopy release];
            [topicIDCopy release];
            [operationCopy release];
            [nameCopy release];
            [errorMessage release];
        });
        [pool drain];
    });
}

- (void)createForumTopic:(id)sender {
    (void)sender;
    if (!self.showingForumTopicList) {
        [self openNewChatWindow:nil];
        return;
    }
    NSString *name = [self forumTopicNameFromPromptWithTitle:TGLoc(@"forum.topic.create")
                                                     detail:TGLoc(@"forum.topic.createHint")
                                               initialValue:@""
                                                actionTitle:TGLoc(@"forum.topic.createAction")];
    if ([name length] == 0) {
        return;
    }
    [self performForumTopicOperation:TGForumTopicOperationCreate item:nil name:name];
}

- (void)renameForumTopicFromMenu:(id)sender {
    TGChatItem *item = [self forumTopicItemFromSender:sender];
    if (![self forumTopicItem:item allowsOperation:TGForumTopicOperationRename]) {
        return;
    }
    NSString *name = [self forumTopicNameFromPromptWithTitle:TGLoc(@"forum.topic.rename")
                                                     detail:TGLoc(@"forum.topic.renameHint")
                                               initialValue:[item title]
                                                actionTitle:TGLoc(@"save")];
    if ([name length] == 0 || [name isEqualToString:[item title]]) {
        return;
    }
    [self performForumTopicOperation:TGForumTopicOperationRename item:item name:name];
}

- (void)toggleForumTopicClosedFromMenu:(id)sender {
    TGChatItem *item = [self forumTopicItemFromSender:sender];
    if (!item) {
        return;
    }
    [self performForumTopicOperation:([item isForumTopicClosed] ? TGForumTopicOperationReopen : TGForumTopicOperationClose)
                                item:item
                                name:nil];
}

- (void)toggleForumTopicPinnedFromMenu:(id)sender {
    TGChatItem *item = [self forumTopicItemFromSender:sender];
    if (!item) {
        return;
    }
    [self performForumTopicOperation:([item isForumTopicPinned] ? TGForumTopicOperationUnpin : TGForumTopicOperationPin)
                                item:item
                                name:nil];
}

- (void)deleteForumTopicFromMenu:(id)sender {
    TGChatItem *item = [self forumTopicItemFromSender:sender];
    if (![self forumTopicItem:item allowsOperation:TGForumTopicOperationDelete]) {
        return;
    }
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert setMessageText:[NSString stringWithFormat:TGLoc(@"forum.topic.deleteConfirmTitle"), [item title]]];
    [alert setInformativeText:TGLoc(@"forum.topic.deleteConfirm")];
    [alert addButtonWithTitle:TGLoc(@"forum.topic.delete")];
    [alert addButtonWithTitle:TGLoc(@"cancel")];
    if (TGRunAlert(alert, self.window) != NSAlertFirstButtonReturn) {
        return;
    }
    [self performForumTopicOperation:TGForumTopicOperationDelete item:item name:nil];
}

- (void)populateForumTopicContextMenu:(NSMenu *)menu forItem:(TGChatItem *)item {
    if (![self forumTopicItemIsCurrent:item]) return;
    [menu setAutoenablesItems:NO];
    BOOL enabled = !self.forumTopicMutationInFlight;
    NSMenuItem *readItem=[[[NSMenuItem alloc] initWithTitle:TGLoc(@"chat.markRead") action:@selector(markForumTopicReadFromMenu:) keyEquivalent:@""] autorelease];
    [readItem setTarget:self]; [readItem setRepresentedObject:item];
    [readItem setEnabled:enabled && [[item unreadCount] integerValue]>0];
    [menu addItem:readItem];
    NSArray *operations=[NSArray arrayWithObjects:@"rename",([item isForumTopicClosed] ? @"reopen" : @"close"),([item isForumTopicPinned] ? @"unpin" : @"pin"),@"delete",nil];
    NSArray *selectors=[NSArray arrayWithObjects:NSStringFromSelector(@selector(renameForumTopicFromMenu:)),NSStringFromSelector(@selector(toggleForumTopicClosedFromMenu:)),NSStringFromSelector(@selector(toggleForumTopicPinnedFromMenu:)),NSStringFromSelector(@selector(deleteForumTopicFromMenu:)),nil];
    BOOL separatorAdded=NO;
    for (NSUInteger index=0;index<[operations count];index++) {
        NSString *operation=[operations objectAtIndex:index];
        if (![self forumTopicItem:item allowsOperation:operation]) continue;
        if (!separatorAdded) { [menu addItem:[NSMenuItem separatorItem]]; separatorAdded=YES; }
        NSMenuItem *action=[[[NSMenuItem alloc] initWithTitle:TGLoc([@"forum.topic." stringByAppendingString:operation]) action:NSSelectorFromString([selectors objectAtIndex:index]) keyEquivalent:@""] autorelease];
        [action setRepresentedObject:item]; [action setTarget:self]; [action setEnabled:enabled]; [menu addItem:action];
    }
}
