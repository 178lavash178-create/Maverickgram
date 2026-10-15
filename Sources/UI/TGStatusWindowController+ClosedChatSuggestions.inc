- (NSArray *)closedChatSuggestionsFromItems:(NSArray *)source {
    NSMutableArray *primary = [NSMutableArray array];
    NSMutableArray *fallback = [NSMutableArray array];
    NSMutableSet *seenIDs = [NSMutableSet set];
    NSUInteger index = 0;
    for (index = 0; index < [source count]; index++) {
        id candidate = [source objectAtIndex:index];
        if (![candidate isKindOfClass:[TGChatItem class]] || [(TGChatItem *)candidate isForumTopic]) {
            continue;
        }
        TGChatItem *item = (TGChatItem *)candidate;
        NSNumber *chatID = [item chatID];
        if (![chatID respondsToSelector:@selector(longLongValue)] || (TGInterfaceDesignIsAqua() && [chatID longLongValue] == 0)) {
            continue;
        }
        NSNumber *normalizedID = [NSNumber numberWithLongLong:[chatID longLongValue]];
        if ([seenIDs containsObject:normalizedID]) {
            continue;
        }
        [seenIDs addObject:normalizedID];
        BOOL privateLike = ([[item typeSummary] isEqualToString:@"Private"] || [item isSavedMessages]);
        if (privateLike) {
            [primary addObject:item];
        } else {
            [fallback addObject:item];
        }
        if ([primary count] >= 8) {
            break;
        }
    }
    if ([primary count] < 8) {
        for (index = 0; index < [fallback count] && [primary count] < 8; index++) {
            [primary addObject:[fallback objectAtIndex:index]];
        }
    }
    return primary;
}

// Keep only references to the same eight loaded model objects used by the
// main list. Empty folders/archive can then offer recent chats without requests.
- (void)rememberAquaClosedChatRecentItemsFromItems:(NSArray *)items {
    if (!TGInterfaceDesignIsAqua() || ![self.currentAuthState isEqualToString:@"ready"] ||
        self.showingArchivedChats || self.selectedChatFilterID) {
        return;
    }
    self.closedChatRecentItems = [self closedChatSuggestionsFromItems:items];
}

- (void)clearClosedChatSuggestionsForSessionChange {
    self.closedChatRecentItems = nil;
    self.closedChatSuggestionItems = nil;
    for (NSView *view in self.closedChatSuggestionViews) {
        [view removeFromSuperview];
    }
    self.closedChatSuggestionViews = nil;
    [self.closedChatEmptyActionButton setHidden:YES];
}

- (NSArray *)closedChatSuggestionSourceItems {
    NSArray *source = (self.showingForumTopicList && self.chatItemsBeforeTopicList) ? self.chatItemsBeforeTopicList : self.chatItems;
    NSArray *items = [self closedChatSuggestionsFromItems:source];
    if (TGInterfaceDesignIsAqua() && [items count] == 0 && [self.currentAuthState isEqualToString:@"ready"]) {
        return [self closedChatSuggestionsFromItems:self.closedChatRecentItems];
    }
    return items;
}

- (void)rebuildClosedChatSuggestions {
    NSUInteger index = 0;
    for (index = 0; index < [self.closedChatSuggestionViews count]; index++) {
        id view = [self.closedChatSuggestionViews objectAtIndex:index];
        if ([view isKindOfClass:[NSView class]]) {
            [(NSView *)view removeFromSuperview];
        }
    }

    NSArray *items = [self closedChatSuggestionSourceItems];
    NSMutableArray *views = [NSMutableArray array];
    for (index = 0; index < [items count]; index++) {
        TGChatItem *item = [items objectAtIndex:index];
        TGGroupedCardView *tile = [[[TGGroupedCardView alloc] initWithFrame:NSMakeRect(0, 0, 74, 82)] autorelease];
        [tile setDrawsInterior:NO];

        TGProfileAvatarView *avatarView = [[[TGProfileAvatarView alloc] initWithFrame:NSMakeRect(15.0, 28.0, 44.0, 44.0)] autorelease];
        [avatarView setDisplayName:[[item title] length] > 0 ? [item title] : TGLoc(@"search.chats.fallbackChat")];
        [avatarView setAvatarLocalPath:[item avatarLocalPath]];
        [tile addSubview:avatarView];

        NSTextField *titleField = [self labelWithFrame:NSMakeRect(3.0, 4.0, 68.0, 18.0)
                                                  text:([[item title] length] > 0 ? [item title] : TGLoc(@"search.chats.fallbackChat"))
                                                  font:[NSFont boldSystemFontOfSize:11.0]];
        [titleField setAlignment:NSCenterTextAlignment];
        [titleField setTextColor:(TGInterfaceDesignIsAqua() ? TGClassicCardInkColor() : TGClassicInkColor())];
        [[titleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [tile addSubview:titleField];

        NSButton *button = [[[NSButton alloc] initWithFrame:[tile bounds]] autorelease];
        [button setBordered:NO];
        [button setTransparent:YES];
        [button setTitle:@""];
        [button setTag:(NSInteger)index];
        [button setTarget:self];
        [button setAction:@selector(openClosedChatSuggestion:)];
        [button setToolTip:[[item title] length] > 0 ? [item title] : TGLoc(@"search.chats.openHint")];
        [tile addSubview:button];
        [self.closedChatPlaceholderView addSubview:tile];
        [views addObject:tile];
    }
    self.closedChatSuggestionItems = items;
    self.closedChatSuggestionViews = views;
    [self applyPointingHandCursorToButtonsInView:self.closedChatPlaceholderView];
}

// Late chat-list completions must not reopen the conversation the user closed.
// Notification-driven navigation is handled before this guard by applyChatItems.
- (BOOL)restoreAquaClosedChatPlaceholderAfterChatListUpdate {
    if (!TGInterfaceDesignIsAqua() || !self.chatNavigationClosed) {
        return NO;
    }
    BOOL previousSuppression = self.suppressChatSelectionHandling;
    self.suppressChatSelectionHandling = YES;
    [self.chatTableView deselectAll:nil];
    self.suppressChatSelectionHandling = previousSuppression;
    [self rebuildClosedChatSuggestions];
    [self updateAuthControlsForState:self.currentAuthState];
    [self updateVisibleSection];
    [self layoutContentView];
    return YES;
}

- (void)layoutAquaClosedChatSuggestionsInFrame:(NSRect)surface {
    if (!self.chatNavigationClosed) {
        return;
    }
    // A placeholder can first become visible without Esc (startup or section
    // navigation). Populate it from the latest loaded list, not only on Esc.
    NSArray *items = [self closedChatSuggestionSourceItems];
    if (![items isEqualToArray:self.closedChatSuggestionItems] ||
        [items count] != [self.closedChatSuggestionViews count]) {
        [self rebuildClosedChatSuggestions];
    }
    NSUInteger count = [self.closedChatSuggestionViews count];
    NSString *hint = TGLoc(@"closedChats.hint");
    BOOL emptyFolder = self.showingArchivedChats || self.selectedChatFilterID != nil;
    NSString *language = TGLanguageCode();
    BOOL russian = [language isEqualToString:@"ru"], belarusian = [language isEqualToString:@"be"];
    if (count == 0) {
        hint = emptyFolder ? (russian ? @"Здесь пока нет чатов. Откройте «Все чаты», чтобы выбрать переписку." :
            (belarusian ? @"Тут пакуль няма чатаў. Адкрыйце «Усе чаты», каб выбраць размову." :
             @"There are no chats here yet. Open All chats to choose a conversation.")) :
            (russian ? @"Откройте «Поиск чатов» или «Контакты», чтобы начать общение." :
             (belarusian ? @"Адкрыйце «Пошук чатаў» або «Кантакты», каб пачаць размову." :
              @"Open Search chats or Contacts to start a conversation."));
        if (!self.closedChatEmptyActionButton) {
            self.closedChatEmptyActionButton = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
            [self.closedChatEmptyActionButton setBezelStyle:NSRoundedBezelStyle];
            [self.closedChatEmptyActionButton setButtonType:NSMomentaryPushInButton];
            [self.closedChatEmptyActionButton setFont:[NSFont systemFontOfSize:13.0]];
            [self.closedChatEmptyActionButton setTarget:self];
            [self.closedChatPlaceholderView addSubview:self.closedChatEmptyActionButton];
        }
        [self.closedChatEmptyActionButton setTitle:emptyFolder ? TGLoc(@"drawer.all") :
            (russian ? @"Поиск чатов" : (belarusian ? @"Пошук чатаў" : @"Search chats"))];
        [self.closedChatEmptyActionButton setTag:-1];
        [self.closedChatEmptyActionButton setAction:emptyFolder ? @selector(folderFilterChanged:) : @selector(openChatSearchWindow:)];
    }
    [self.closedChatEmptyActionButton setHidden:count != 0];
    [self.closedChatHintField setStringValue:hint];
    CGFloat width = MIN(500.0, MAX(1.0, NSWidth(surface) - 24.0));
    NSUInteger columns = MIN((NSUInteger)4, MAX((NSUInteger)1, (NSUInteger)floor(MAX(0.0, width - 20.0) / 86.0)));
    columns = MIN(columns, MAX((NSUInteger)1, count));
    NSUInteger rows = count ? (count + columns - 1) / columns : 0;
    CGFloat wantedHeight = rows ? 94.0 + rows * 82.0 + (rows - 1) * 12.0 : 174.0;
    CGFloat height = MIN(wantedHeight, MAX(1.0, NSHeight(surface) - 24.0));
    NSRect frame = NSMakeRect(NSMinX(surface) + floor((NSWidth(surface) - width) / 2.0),
                             NSMinY(surface) + floor((NSHeight(surface) - height) / 2.0), width, height);
    [self.closedChatPlaceholderView setFrame:frame];
    [self.closedChatTitleField setTextColor:TGClassicCardInkColor()];
    [self.closedChatHintField setTextColor:TGClassicCardMutedInkColor()];
    [self.closedChatTitleField setFrame:NSMakeRect(16.0, MAX(0.0, height - 38.0), MAX(0.0, width - 32.0), MIN(22.0, height))];
    [self.closedChatHintField setFrame:NSMakeRect(16.0, MIN(12.0, height), MAX(0.0, width - 32.0), MIN(28.0, MAX(0.0, height - 50.0)))];
    if (count == 0) {
        [self.closedChatHintField setFrame:NSMakeRect(20.0, 60.0, MAX(0.0, width - 40.0), 44.0)];
        CGFloat buttonWidth = MIN(190.0, MAX(0.0, width - 40.0));
        [self.closedChatEmptyActionButton setFrame:NSMakeRect(floor((width-buttonWidth)/2.0), 16.0, buttonWidth, 32.0)];
    }
    NSUInteger visibleRows = (NSUInteger)floor(MAX(0.0, height - 82.0) / 94.0);
    CGFloat rowWidth = columns * 74.0 + (columns - 1) * 12.0;
    CGFloat startX = floor((width - rowWidth) / 2.0);
    for (NSUInteger index = 0; index < count; index++) {
        NSView *tile = [self.closedChatSuggestionViews objectAtIndex:index];
        BOOL visible = (index / columns < visibleRows && width >= 94.0);
        [tile setHidden:!visible];
        [tile setFrame:NSMakeRect(startX + (index % columns) * 86.0,
                                 height - 136.0 - (index / columns) * 94.0, 74.0, 82.0)];
        TGChatItem *item = [items objectAtIndex:index];
        NSArray *children = [tile subviews];
        TGProfileAvatarView *avatar = [children objectAtIndex:0];
        NSString *title = [[item title] length] ? [item title] : TGLoc(@"search.chats.fallbackChat");
        [avatar setDisplayName:title];
        if (![[avatar avatarLocalPath] isEqualToString:[item avatarLocalPath]] &&
            ([avatar avatarLocalPath] || [item avatarLocalPath])) {
            [avatar setAvatarLocalPath:[item avatarLocalPath]];
        }
        NSTextField *label = [children objectAtIndex:1];
        [label setStringValue:title];
        [label setTextColor:TGClassicCardInkColor()];
        [[children objectAtIndex:2] setToolTip:title];
    }
}

- (void)layoutClosedChatPlaceholderViewInFrame:(NSRect)messageSurfaceFrame {
    if (!self.closedChatPlaceholderView) {
        return;
    }
    if (TGInterfaceDesignIsAqua()) {
        [self layoutAquaClosedChatSuggestionsInFrame:messageSurfaceFrame];
        return;
    }
    [self.closedChatTitleField setTextColor:TGClassicInkColor()];
    [self.closedChatHintField setTextColor:TGClassicMutedInkColor()];
    CGFloat cardWidth = NSWidth(messageSurfaceFrame) - 70.0;
    if (cardWidth > 500.0) {
        cardWidth = 500.0;
    }
    if (cardWidth < 320.0) {
        cardWidth = 320.0;
    }
    CGFloat cardHeight = ([self.closedChatSuggestionViews count] > 4) ? 308.0 : 190.0;
    if (NSHeight(messageSurfaceFrame) < cardHeight + 24.0) {
        cardHeight = MAX(154.0, NSHeight(messageSurfaceFrame) - 24.0);
    }
    CGFloat cardX = NSMinX(messageSurfaceFrame) + floor((NSWidth(messageSurfaceFrame) - cardWidth) / 2.0);
    CGFloat cardY = NSMinY(messageSurfaceFrame) + floor((NSHeight(messageSurfaceFrame) - cardHeight) / 2.0);
    [self.closedChatPlaceholderView setFrame:NSMakeRect(cardX, cardY, cardWidth, cardHeight)];
    [self.closedChatTitleField setFrame:NSMakeRect(24.0, cardHeight - 46.0, cardWidth - 48.0, 22.0)];
    [self.closedChatHintField setFrame:NSMakeRect(38.0, 22.0, cardWidth - 76.0, 36.0)];

    NSUInteger count = [self.closedChatSuggestionViews count];
    if (count == 0) {
        return;
    }
    NSUInteger columns = count > 4 ? 4 : count;
    CGFloat tileWidth = 74.0;
    CGFloat tileHeight = 82.0;
    CGFloat gap = 12.0;
    CGFloat rowWidth = ((CGFloat)columns * tileWidth) + ((CGFloat)(columns - 1) * gap);
    CGFloat startX = floor((cardWidth - rowWidth) / 2.0);
    CGFloat firstRowY = cardHeight - 132.0;
    if (count > 4) {
        firstRowY = cardHeight - 132.0;
    }
    if (firstRowY < 82.0) {
        firstRowY = 82.0;
    }
    NSUInteger index = 0;
    for (index = 0; index < count; index++) {
        NSView *tile = [self.closedChatSuggestionViews objectAtIndex:index];
        NSUInteger row = index / columns;
        NSUInteger column = index % columns;
        CGFloat tileX = startX + ((tileWidth + gap) * (CGFloat)column);
        CGFloat tileY = firstRowY - ((tileHeight + 12.0) * (CGFloat)row);
        [tile setFrame:NSMakeRect(tileX, tileY, tileWidth, tileHeight)];
    }
}

- (void)openClosedChatSuggestion:(id)sender {
    NSInteger index = [sender respondsToSelector:@selector(tag)] ? [sender tag] : -1;
    if (index < 0 || (NSUInteger)index >= [self.closedChatSuggestionItems count]) {
        return;
    }
    id candidate = [self.closedChatSuggestionItems objectAtIndex:(NSUInteger)index];
    if (![candidate isKindOfClass:[TGChatItem class]]) {
        return;
    }
    TGChatItem *item = (TGChatItem *)candidate;
    NSNumber *chatID = nil;
    if ([[item chatID] respondsToSelector:@selector(longLongValue)]) {
        chatID = [NSNumber numberWithLongLong:[[item chatID] longLongValue]];
    }
    if (!chatID) {
        return;
    }
    NSUInteger selectedIndex = [self indexOfChatID:chatID inChatItems:self.chatItems];
    if (TGInterfaceDesignIsAqua() && selectedIndex == NSNotFound) {
        // The folder may have refreshed after the tile was presented. Use the
        // existing contact navigation path rather than leaving a blank chat.
        [self chatLifecycleWindowController:nil didOpenChatID:chatID title:[item title]];
        return;
    }
    self.chatNavigationClosed = NO;
    self.suppressedForumTopicAutoOpenChatID = nil;
    if (selectedIndex != NSNotFound) {
        [self.chatTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedIndex] byExtendingSelection:NO];
        [self.chatTableView scrollRowToVisible:selectedIndex];
        [self tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification
                                                                         object:self.chatTableView]];
    }
    [self updateVisibleSection];
    [self layoutContentView];
}
