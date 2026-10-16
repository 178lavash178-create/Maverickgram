// Account-scoped viewport anchors; no sessions, message bodies or titles persisted.
- (TGNavigationPositionStore *)preparedNavigationPositionStore {
    if (!self.navigationPositionStore) self.navigationPositionStore=[[[TGNavigationPositionStore alloc] init] autorelease];
    return self.navigationPositionStore;
}
- (void)clearNavigationContinuity { [self.navigationPositionStore clear]; }
- (NSString *)navigationChatListKey {
    return TGNavigationListPositionKey(self.profileUserID,self.selectedChatFilterID,self.showingArchivedChats,
        (self.showingForumTopicList && !self.forumTopicsPresentedInTopBar) ? self.topicParentChatID : nil);
}
- (NSString *)navigationTranscriptKey {
    return TGNavigationTranscriptPositionKey(self.profileUserID,self.selectedChatID,self.selectedMessageThreadID,self.selectedMessageTopicKind);
}
- (NSString *)navigationChatAnchor:(TGChatItem *)item {
    return [item isForumTopic] ? [NSString stringWithFormat:@"topic:%@:%@:%@",[item parentChatID],[item messageThreadID],[item messageTopicKind] ? [item messageTopicKind] : @"forum"] : [NSString stringWithFormat:@"chat:%@",[item chatID]];
}
- (void)captureNavigationChatList {
    if (!TGInterfaceDesignIsAqua() || ![self.profileUserID longLongValue] || ![self.chatItems count]) return;
    if([self.navigationPositionStore pendingPositionForKey:[self navigationChatListKey] transcript:NO]) return;
    NSClipView *clip=[self.chatScrollView contentView];
    NSRange rows=[self.chatTableView rowsInRect:[clip bounds]];
    if(rows.location==NSNotFound || rows.location>=[self.chatItems count]) return;
    NSRect row=[self.chatTableView rectOfRow:rows.location];
    NSDictionary *position=[NSDictionary dictionaryWithObjectsAndKeys:[self navigationChatAnchor:[self.chatItems objectAtIndex:rows.location]],@"anchor",[NSNumber numberWithDouble:[clip bounds].origin.y-NSMinY(row)],@"offset",[NSNumber numberWithDouble:[clip bounds].origin.y],@"origin",[NSNumber numberWithUnsignedInteger:[self.chatItems count]],@"loadedCount",nil];
    [[self preparedNavigationPositionStore] savePosition:position forKey:[self navigationChatListKey]];
}
- (void)captureNavigationTranscript {
    if (!TGInterfaceDesignIsAqua() || ![self.profileUserID longLongValue] || ![self.messageItems count] || self.chatNavigationClosed || (self.messageItemsRepresentFocusedContext && ![self navigationRestoredHistoryIsActive])) return;
    NSClipView *clip=[self.messageScrollView contentView];
    NSRange rows=[self.messageTableView rowsInRect:[clip bounds]];
    if(rows.location==NSNotFound || rows.location>=[self.messageItems count]) return;
    NSUInteger row=rows.location;
    while(row<[self.messageItems count] && ![[self.messageItems objectAtIndex:row] messageID]) row++;
    if(row>=[self.messageItems count]) return;
    NSDictionary *position=[NSDictionary dictionaryWithObjectsAndKeys:[[self.messageItems objectAtIndex:row] messageID],@"anchor",[NSNumber numberWithDouble:[clip bounds].origin.y-NSMinY([self.messageTableView rectOfRow:row])],@"offset",[NSNumber numberWithDouble:[clip bounds].origin.y],@"origin",[NSNumber numberWithBool:(!self.messageItemsRepresentFocusedContext && [self isMessageHistoryNearBottom])],@"nearEnd",nil];
    [[self preparedNavigationPositionStore] savePosition:position forKey:[self navigationTranscriptKey]];
}
- (void)captureNavigationContinuity { [self captureNavigationChatList];[self captureNavigationTranscript]; }
- (void)armNavigationChatListRestore {
    if(TGInterfaceDesignIsAqua()) [[self preparedNavigationPositionStore] armKey:[self navigationChatListKey] transcript:NO];
    [self refreshNavigationBreadcrumb];
}
- (NSUInteger)navigationChatListRestoreLimit {
    if(!TGInterfaceDesignIsAqua()) return TGStatusChatPreviewInitialLimit;
    NSUInteger saved=[[[self.navigationPositionStore pendingPositionForKey:[self navigationChatListKey] transcript:NO] objectForKey:@"loadedCount"] unsignedIntegerValue];
    return MIN(TGStatusChatPreviewMaximumLimit,MAX(TGStatusChatPreviewInitialLimit,saved));
}
- (void)armNavigationTranscriptRestore {
    if(TGInterfaceDesignIsAqua()) {
        self.forceMessageScrollToNewest=NO;
        self.messageItemsRepresentFocusedContext=NO;
        [[self preparedNavigationPositionStore] markRestoredTranscriptKey:nil generation:0];
        [self.navigationPositionStore armKey:[self navigationTranscriptKey] transcript:YES];
    }
}
- (void)restoreNavigationClip:(NSClipView *)clip table:(NSTableView *)table row:(NSUInteger)row offset:(CGFloat)offset fallback:(CGFloat)fallback {
    CGFloat y=row==NSNotFound ? fallback : NSMinY([table rectOfRow:row])+offset;
    CGFloat maximum=MAX(0,NSHeight([[clip documentView] bounds])-NSHeight([clip bounds]));
    [clip scrollToPoint:NSMakePoint(0,MAX(0,MIN(maximum,y)))];
    [(NSScrollView *)[clip superview] reflectScrolledClipView:clip];
}
- (void)restoreNavigationChatListIfPending {
    NSDictionary *position=[self.navigationPositionStore consumePositionForKey:[self navigationChatListKey] transcript:NO];
    if(!position) return;
    NSUInteger row=0,found=NSNotFound;
    for(TGChatItem *item in self.chatItems) { if([[self navigationChatAnchor:item] isEqual:[position objectForKey:@"anchor"]]) { found=row;break; } row++; }
    [self restoreNavigationClip:[self.chatScrollView contentView] table:self.chatTableView row:found offset:[[position objectForKey:@"offset"] doubleValue] fallback:[[position objectForKey:@"origin"] doubleValue]];
}
- (BOOL)navigationRestoredHistoryIsActive {
    return TGInterfaceDesignIsAqua() && self.messageItemsRepresentFocusedContext &&
        [self.navigationPositionStore isRestoredTranscriptKey:[self navigationTranscriptKey] generation:0];
}
- (NSNumber *)navigationVisibleTranscriptAnchor {
    if(![self navigationRestoredHistoryIsActive] || self.forceMessageScrollToNewest) return nil;
    [self captureNavigationTranscript];
    return [[self.navigationPositionStore positionForKey:[self navigationTranscriptKey]] objectForKey:@"anchor"];
}
- (NSNumber *)navigationPendingTranscriptAnchor {
    if(!TGInterfaceDesignIsAqua() || self.forceMessageScrollToNewest || self.messageItemsRepresentFocusedContext) return nil;
    return [[self.navigationPositionStore pendingPositionForKey:[self navigationTranscriptKey] transcript:YES] objectForKey:@"anchor"];
}
- (BOOL)restoreNavigationTranscriptIfPending {
    NSDictionary *position=[self.navigationPositionStore consumePositionForKey:[self navigationTranscriptKey] transcript:YES];
    if(!position || self.forceMessageScrollToNewest || self.messageItemsRepresentFocusedContext) return NO;
    NSUInteger row=0;
    for(TGMessageItem *item in self.messageItems) {
        if([[item messageID] isEqual:[position objectForKey:@"anchor"]]) {
            [self restoreNavigationClip:[self.messageScrollView contentView] table:self.messageTableView row:row offset:[[position objectForKey:@"offset"] doubleValue] fallback:0];
            self.initialUnreadPositionPending=NO;
            [self updateMessageJumpToNewestButtonVisibility];
            return YES;
        }
        row++;
    }
    return NO;
}
- (void)forgetNavigationTranscriptPosition {
    [self.navigationPositionStore removePositionForKey:[self navigationTranscriptKey]];
}
- (NSString *)navigationFolderTitle {
    for(NSButton *button in self.drawerFolderButtons) {
        NSInteger tag=[button tag];
        if((self.showingArchivedChats && tag==-2) || (!self.showingArchivedChats && ((self.selectedChatFilterID && tag==[self.selectedChatFilterID integerValue]) || (!self.selectedChatFilterID && tag==-1)))) return [button title];
    }
    return self.showingArchivedChats ? TGLoc(@"drawer.archive") : TGLoc(@"chats");
}
- (void)refreshNavigationBreadcrumb {
    if(!TGInterfaceDesignIsAqua()) return;
    NSMutableArray *parts=[NSMutableArray array];NSString *folder=[self navigationFolderTitle];
    if([folder length]) [parts addObject:folder];
    if([self.topicParentTitle length]) [parts addObject:self.topicParentTitle];
    if([self.selectedChatTitle length] && ![[parts lastObject] isEqual:self.selectedChatTitle]) [parts addObject:self.selectedChatTitle];
    NSString *path=[parts componentsJoinedByString:@" › "];
    [self.chatsLabel setToolTip:path];[self.selectedChatField setToolTip:path];
    if(!self.showingForumTopicList && !self.forumTopicsPresentedInTopBar && [folder length]) [self.chatsLabel setStringValue:folder];
    [self.topicBackButton setToolTip:[NSString stringWithFormat:@"%@ — %@",TGLoc(@"back"),folder ? folder : TGLoc(@"chats")]];
}
