/* The panel renders the existing TDLib profile summaries. Every response is
   scoped to its client, chat and generation; navigation never reuses a result. */
- (BOOL)isAquaChatInfoPanelActive {
    return TGInterfaceDesignIsAqua() && self.client &&
        [self.currentAuthState isEqualToString:@"ready"] &&
        [self.activeSection isEqualToString:TGSectionChats] &&
        !self.chatNavigationClosed && !self.mediaCenterVisible &&
        self.aquaChatInfoChatID && [self.aquaChatInfoChatID isEqual:self.selectedChatID];
}

- (BOOL)aquaChatInfoReplacesConversation {
    if (![self isAquaChatInfoPanelActive]) return NO;
    NSView *content = [[self window] contentView];
    CGFloat x = NSMaxX([self.sidebarPanelView frame])+6.0;
    NSRect available = NSMakeRect(x,NSMinY([self.conversationPanelView frame]),MAX(0,NSWidth([content bounds])-x),NSHeight([self.conversationPanelView frame]));
    return TGAquaChatInfoFrames(available,YES).replacesConversation;
}

- (void)invalidateAquaChatInfoPanel {
    if (self.aquaChatInfoChatID) self.aquaChatInfoRequestGeneration++;
    self.aquaChatInfoChatID = nil;
    [self.aquaChatInfoPanel hideImmediately];
}

- (void)updateAquaChatInfoPanelVisibility {
    if (![self isAquaChatInfoPanelActive]) {
        [self invalidateAquaChatInfoPanel];
        return;
    }
    NSView *content = [[self window] contentView];
    NSRect frame = [self.conversationPanelView frame];
    CGFloat left = NSMaxX([self.sidebarPanelView frame])+6.0;
    NSRect available = NSMakeRect(left,NSMinY(frame),MAX(0,NSWidth([content bounds])-left),NSHeight(frame));
    TGAquaChatInfoGeometry geometry = TGAquaChatInfoFrames(available,YES);
    [content addSubview:self.aquaChatInfoPanel positioned:NSWindowAbove relativeTo:nil];
    if (![self.aquaChatInfoPanel isClosing]) [self.aquaChatInfoPanel presentInFrame:geometry.panel animated:YES];
}

- (void)openAquaChatInfo:(id)sender {
    (void)sender;
    if (!TGInterfaceDesignIsAqua() || !self.client || ![self.currentAuthState isEqualToString:@"ready"] || !self.selectedChatID) return;
    if ([self isAquaChatInfoPanelActive] && ![self.aquaChatInfoPanel isClosing]) { [self closeAquaChatInfo:nil]; return; }
    if (!self.aquaChatInfoPanel) {
        self.aquaChatInfoPanel = [[[TGAquaChatInfoPanel alloc] initWithFrame:NSZeroRect] autorelease];
        [self.aquaChatInfoPanel setTarget:self];
    }
    [self.aquaChatInfoPanel hideImmediately];
    self.aquaChatInfoChatID = self.selectedChatID;
    self.aquaChatInfoRequestGeneration++;
    NSMutableDictionary *initial = [NSMutableDictionary dictionary];
    if ([self.selectedChatTitle length]) [initial setObject:self.selectedChatTitle forKey:@"title"];
    if ([self.selectedChatAvatarLocalPath length]) [initial setObject:self.selectedChatAvatarLocalPath forKey:@"avatar_local_path"];
    [self.aquaChatInfoPanel showSummary:initial loading:YES error:nil];
    [self layoutContentView]; [self updateVisibleSection];
    // Ending editing commits the current local draft; no message is sent.
    [[self window] makeFirstResponder:self.aquaChatInfoPanel];
    NSUInteger generation = self.aquaChatInfoRequestGeneration;
    TGTDLibClient *client = [self.client retain];
    NSNumber *chatID = [self.aquaChatInfoChatID retain];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSDictionary *basic = [client chatSummaryForChatID:chatID downloadAvatar:YES timeout:1.5 error:NULL];
        NSError *error = nil;
        NSDictionary *details = [client chatDetailsSummaryForChatID:chatID timeout:3.0 error:&error];
        NSMutableDictionary *combined = [NSMutableDictionary dictionaryWithDictionary:initial];
        if ([basic isKindOfClass:[NSDictionary class]]) [combined addEntriesFromDictionary:basic];
        if ([details isKindOfClass:[NSDictionary class]]) [combined addEntriesFromDictionary:details];
        NSDictionary *snapshot = [combined copy];
        NSString *errorMessage = details ? nil : [([error localizedDescription] ? [error localizedDescription] : TGLoc(@"contacts.profileError")) copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation == self.aquaChatInfoRequestGeneration && client == self.client &&
                [chatID isEqual:self.aquaChatInfoChatID] && [self isAquaChatInfoPanelActive] && ![self.aquaChatInfoPanel isClosing]) {
                [self.aquaChatInfoPanel showSummary:snapshot loading:NO error:errorMessage];
            }
            [snapshot release]; [errorMessage release]; [chatID release]; [client release];
        });
        [pool drain];
    });
}

- (void)closeAquaChatInfo:(id)sender {
    (void)sender;
    self.aquaChatInfoRequestGeneration++;
    [self.aquaChatInfoPanel closeAnimated:YES];
}

- (void)aquaChatInfoPanelDidClose:(id)sender {
    if (sender != self.aquaChatInfoPanel) return;
    self.aquaChatInfoChatID = nil;
    [self layoutContentView]; [self updateVisibleSection];
    [self requestComposerRefocus];
}

- (void)openAquaChatInfoMedia:(id)sender {
    if (![self isAquaChatInfoPanelActive]) return;
    NSInteger tab = [sender respondsToSelector:@selector(tag)] ? [sender tag] : 0;
    [self invalidateAquaChatInfoPanel];
    [self layoutContentView];
    [self ensureMediaCenterWindow];
    self.mediaCenterSelectedTabIndex = MAX(0,MIN(3,tab));
    [self updateMediaCenterTabButtonStates];
    [self openMediaCenter:sender];
}

- (void)openAquaChatInfoDetails:(id)sender {
    (void)sender;
    if (![self isAquaChatInfoPanelActive]) return;
    [[self.chatInfoWindowController window] close];
    self.chatInfoWindowController = [[[TGChatInfoWindowController alloc] initWithClient:self.client chatID:self.selectedChatID title:self.selectedChatTitle] autorelease];
    [[self.chatInfoWindowController window] center];
    [self.chatInfoWindowController showWindow:self];
    [[self.chatInfoWindowController window] makeKeyAndOrderFront:self];
    [self.chatInfoWindowController reloadChatInfo];
}
