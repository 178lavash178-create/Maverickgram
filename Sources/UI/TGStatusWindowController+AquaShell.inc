// Optional shell. The controller's existing actions/data sources remain shared.
- (void)installAquaTextCellOnButton:(NSButton *)button accented:(BOOL)accented {
    id target = [button target]; SEL action = [button action];
    NSString *title = [[button title] copy]; NSInteger state = NSOffState;
    TGAquaTextButtonCell *cell = [[[TGAquaTextButtonCell alloc] initTextCell:title] autorelease];
    [cell setAccented:accented]; [cell setButtonType:NSMomentaryPushInButton];
    [button setCell:cell]; [button setTitle:title]; [button setState:state];
    [button setTarget:target]; [button setAction:action];
    [button setBordered:NO]; [button setFocusRingType:NSFocusRingTypeExterior];
    [title release];
}

- (NSButton *)aquaButtonWithAction:(SEL)action {
    NSButton *button = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [button setTarget:self]; [button setAction:action];
    [self installAquaTextCellOnButton:button accented:NO];
    [[[self window] contentView] addSubview:button];
    return button;
}

- (void)configureInterfaceDesignControls {
    self.interfaceDesignLabel = [self labelWithFrame:NSZeroRect text:@"" font:[NSFont systemFontOfSize:13.0]];
    self.interfaceDesignHint = [self labelWithFrame:NSZeroRect text:@"" font:[NSFont systemFontOfSize:11.0]];
    self.interfaceDesignPopUpButton = [[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    [self.interfaceDesignPopUpButton setTarget:self];
    [self.interfaceDesignPopUpButton setAction:@selector(interfaceDesignSelectionChanged:)];
    [self.settingsContentView addSubview:self.interfaceDesignLabel];
    [self.settingsContentView addSubview:self.interfaceDesignHint];
    [self.settingsContentView addSubview:self.interfaceDesignPopUpButton];
    if (!TGInterfaceDesignIsAqua()) return;
    TGAquaConfigureTranscriptViewport(self.messageScrollView, (TGScrollSurfaceView *)self.messageScrollSurfaceView);
    self.aquaFolderPresentationSettingsView = [[[TGAquaFolderPresentationSettingsView alloc] initWithFrame:NSZeroRect] autorelease];
    [self.settingsContentView addSubview:self.aquaFolderPresentationSettingsView];
    [self configureAquaFolderDrawer];
    NSView *content = [[self window] contentView];
    self.aquaToolbarView = [[[TGAquaMetalView alloc] initWithFrame:NSZeroRect] autorelease];
    self.aquaFooterView = [[[TGAquaMetalView alloc] initWithFrame:NSZeroRect] autorelease];
    [content addSubview:self.aquaToolbarView];
    [content addSubview:self.aquaFooterView];
    self.aquaChatHeaderView = [[[TGAquaMetalView alloc] initWithFrame:NSZeroRect] autorelease];
    [content addSubview:self.aquaChatHeaderView];
    self.aquaFolderHeaderButton = [self aquaButtonWithAction:@selector(toggleAquaFolders:)];
    self.aquaFolderEditButton = [self aquaButtonWithAction:@selector(showChatFolderManagementWindow:)];
    for (NSButton *button in [NSArray arrayWithObjects:self.aquaFolderHeaderButton, self.aquaFolderEditButton, nil]) {
        id target = [button target]; SEL action = [button action];
        TGAquaSectionButtonCell *cell = [[[TGAquaSectionButtonCell alloc] initTextCell:@""] autorelease];
        [cell setAlignment:button == self.aquaFolderHeaderButton ? NSLeftTextAlignment : NSRightTextAlignment];
        [button setCell:cell]; [button setTarget:target]; [button setAction:action];
        [button setBordered:NO];
    }
    self.aquaSearchButton = [self aquaButtonWithAction:@selector(openChatSearchWindow:)];
    self.aquaDownloadsButton = [self aquaButtonWithAction:@selector(showDownloadManagerWindow:)];
    self.aquaFolderDivider = [[[TGAquaFolderDivider alloc] initWithFrame:NSZeroRect] autorelease];
    [self.aquaFolderDivider setTarget:self];
    [self.aquaFolderDivider setAction:@selector(resizeAquaFolders:)];
    [content addSubview:self.aquaFolderDivider];
    self.aquaFolderPreferredHeight = [[NSUserDefaults standardUserDefaults] doubleForKey:@"TGAquaFolderHeight"];
    if (self.aquaFolderPreferredHeight < 76.0) self.aquaFolderPreferredHeight = 210.0;
    self.aquaFoldersCollapsed = [[NSUserDefaults standardUserDefaults] boolForKey:@"TGAquaFoldersCollapsed"];
    NSArray *toolbarButtons = [self.navigationButtons arrayByAddingObject:self.workshopDrawerButton];
    NSArray *toolbarAssets = [NSArray arrayWithObjects:@"contacts", @"call-receive", @"chat", @"settings", @"workshop", nil];
    for (NSUInteger toolbarIndex=0; toolbarIndex<[toolbarButtons count]; toolbarIndex++) {
        NSButton *button = [toolbarButtons objectAtIndex:toolbarIndex];
        id target = [button target]; SEL action = [button action];
        NSString *title = [[button title] copy]; NSInteger state = [button state];
        TGAquaUtilityButtonCell *cell = [[[TGAquaUtilityButtonCell alloc] initTextCell:title] autorelease];
        [cell setButtonType:NSToggleButton]; [cell setIconOnly:YES];
        [cell setIconAssetName:[toolbarAssets objectAtIndex:toolbarIndex]];
        [button setCell:cell]; [button setTitle:title]; [button setState:state];
        [button setTarget:target]; [button setAction:action]; [button setBordered:NO];
        [title release];
    }
    [self installAquaTextCellOnButton:self.attachPhotoButton accented:NO];
    NSImage *attachmentTemplate=[[TGIconAssetImageNamed(@"attach") copy] autorelease];
    [attachmentTemplate setTemplate:YES];
    [self.attachPhotoButton setImage:attachmentTemplate];
    [self installAquaTextCellOnButton:self.sendMessageButton accented:YES];
    [(TGPanelView *)self.settingsPanelView setHeaderHidden:YES];
    [self.chatScrollSurfaceView setSquareEdges:YES];
    [self.drawerFolderScrollView setAutohidesScrollers:NO];
}

- (void)refreshInterfaceDesignControls {
    [self.interfaceDesignLabel setStringValue:TGLoc(@"settings.section.interface")];
    [self.interfaceDesignHint setStringValue:TGLoc(@"aqua.interface.changeHint")];
    [self.interfaceDesignLabel setTextColor:TGClassicCardInkColor()];
    [self.interfaceDesignHint setTextColor:TGClassicCardMutedInkColor()];
    [self.interfaceDesignPopUpButton removeAllItems];
    [self.interfaceDesignPopUpButton addItemsWithTitles:[NSArray arrayWithObjects:TGLoc(@"aqua.interface.classic"), @"Aqua", nil]];
    [self.interfaceDesignPopUpButton selectItemAtIndex:TGInterfaceDesignIsAqua() ? 1 : 0];
    [self.themePopUpButton setEnabled:!TGInterfaceDesignIsAqua()];
    [self.themeCategoryPopUpButton setEnabled:!TGInterfaceDesignIsAqua()];
    if (!TGInterfaceDesignIsAqua()) return;
    [self.aquaFolderHeaderButton setTitle:[NSString stringWithFormat:@"%@ · %lu", TGLoc(@"aqua.folders.heading"), (unsigned long)[self.drawerFolderButtons count]]];
    [self.aquaFolderPresentationSettingsView refreshAppearance];
    [self.aquaFolderDrawer refreshLocalization];
    [self.aquaFolderHeaderButton setToolTip:TGLoc(TGAquaFoldersUseDrawer() ? @"aqua.folders.toggleDrawer" : @"aqua.folders.toggleInline")];
    [self.aquaFolderEditButton setTitle:TGLoc(@"profile.edit.short")];
    [self.aquaSearchButton setTitle:TGLoc(@"search.chats.title")];
    [self.aquaDownloadsButton setTitle:TGLoc(@"downloads.short")];
    [self.workshopDrawerButton setTitle:TGLoc(@"workshop.title")];
    [self.attachPhotoButton setTitle:TGLoc(@"aqua.attachFile")];
    [self.sendMessageButton setTitle:TGLoc(@"send")];
}

- (void)interfaceDesignSelectionChanged:(id)sender {
    (void)sender;
    NSString *identifier = [self.interfaceDesignPopUpButton indexOfSelectedItem] == 1 ? @"aqua" : @"classic";
    NSError *error = nil;
    if (!TGRequestInterfaceDesignChange(identifier, [self window], &error)) {
        [self.interfaceDesignPopUpButton selectItemAtIndex:TGInterfaceDesignIsAqua() ? 1 : 0];
        if (error) TGRunAlert([NSAlert alertWithError:error], self.window);
    }
}


- (void)resizeAquaFolders:(TGAquaFolderDivider *)sender {
    CGFloat current = NSHeight([self.drawerFolderScrollView frame]);
    self.aquaFolderPreferredHeight = MAX(76.0, MIN(340.0, current + [sender dragDelta]));
    [[NSUserDefaults standardUserDefaults] setDouble:self.aquaFolderPreferredHeight forKey:@"TGAquaFolderHeight"];
    [self layoutContentView];
}

- (void)updateAquaShellVisibility {
    if (!TGInterfaceDesignIsAqua()) return;
    BOOL ready = [self.currentAuthState isEqualToString:@"ready"];
    BOOL chats = ready && [self.activeSection isEqualToString:TGSectionChats];
    for (NSView *view in [NSArray arrayWithObjects:self.aquaToolbarView, self.aquaSearchButton, self.aquaDownloadsButton, self.workshopDrawerButton, nil]) [view setHidden:!ready];
    [self.aquaFooterView setHidden:(!chats || self.chatNavigationClosed || (self.mediaCenterVisible && ![self isAquaChatInfoPanelActive]) || [self aquaChatInfoReplacesConversation])];
    for (NSButton *button in self.navigationButtons) [button setHidden:!ready];
    [self.aquaFolderHeaderButton setHidden:!chats];
    [self.aquaFolderEditButton setHidden:(!chats || [self aquaUsesExternalFolderDrawer])];
    [self.aquaChatHeaderView setHidden:!chats];
    BOOL expanded = [self aquaFolderListExpanded];
    BOOL external = [self aquaUsesExternalFolderDrawer];
    [self.aquaFolderDivider setHidden:(!chats || external || !expanded || [self.drawerFolderButtons count] == 0)];
    [self.drawerFolderScrollView setHidden:(!chats || !expanded || [self.drawerFolderButtons count] == 0)];
    [self.aquaFolderDrawer setVisible:(chats && external && expanded && [self.drawerFolderButtons count] > 0)];
    for (NSButton *button in self.drawerFolderButtons) [button setHidden:NO];
    [self.topPanelView setHidden:YES]; [self.bottomNavigationView setHidden:YES];
    [self.accountBadgeView setHidden:!ready];
    [self.drawerButton setHidden:![self.activeSection isEqualToString:TGSectionProfile]];
    [self.titleField setHidden:YES]; [self.statusField setHidden:YES];
}

- (void)layoutAquaShell {
    if (!TGInterfaceDesignIsAqua() || !self.aquaToolbarView) return;
    NSView *content = [[self window] contentView];
    CGFloat width = NSWidth([content bounds]), height = NSHeight([content bounds]);
    NSRect sidebar = [self.sidebarPanelView frame];
    CGFloat sidebarWidth = NSWidth(sidebar);
    BOOL showingChats = [self.activeSection isEqualToString:TGSectionChats];
    BOOL composerVisible = showingChats && !self.chatNavigationClosed && (!self.mediaCenterVisible || [self isAquaChatInfoPanelActive]) && ![self aquaChatInfoReplacesConversation];
    CGFloat footerHeight = TGAquaFooterHeight(composerVisible, [self.sendTextFieldBackgroundView frame]);
    [self.aquaToolbarView setFrame:NSMakeRect(0, height-TGAquaToolbarHeight(), width, TGAquaToolbarHeight())];
    CGFloat conversationX = NSMaxX(sidebar) + 6.0;
    [self.aquaFooterView setFrame:NSMakeRect(conversationX, 0, MAX(0, NSWidth([self.conversationPanelView frame])), footerHeight)];
    [self.aquaFooterView setDividerX:0];
    // Chrome is behind the live controls, not an overlay over the composer.
    [content addSubview:self.aquaFooterView positioned:NSWindowAbove relativeTo:nil];
    NSRect resizeFrame = [self.sidebarResizeHandleView frame];
    resizeFrame.size.height = MAX(0, NSMaxY(resizeFrame));
    resizeFrame.origin.y = 0;
    [self.sidebarResizeHandleView setFrame:resizeFrame];
    for (NSView *control in [NSArray arrayWithObjects:self.attachPhotoButton, self.botActionButton, self.sendTextFieldBackgroundView, self.sendTextField, self.stickerButton, self.voiceRecordButton, self.sendMessageButton, nil]) {
        [content addSubview:control positioned:NSWindowAbove relativeTo:nil];
    }
    [self.accountBadgeView setFrame:NSMakeRect(12, height-41, 32, 34)];
    [content addSubview:self.accountBadgeView positioned:NSWindowAbove relativeTo:nil];
    CGFloat searchWidth = MIN(200.0, floor(width*0.18));
    [self.aquaSearchButton setFrame:NSMakeRect(54, height-39, searchWidth, 30)];
    NSArray *order = [NSArray arrayWithObjects:[self.navigationButtons objectAtIndex:2], [self.navigationButtons objectAtIndex:0], [self.navigationButtons objectAtIndex:1], self.workshopDrawerButton, [self.navigationButtons objectAtIndex:3], nil];
    NSUInteger index = 0;
    for (NSButton *button in order) {
        [button setFrame:TGAquaToolbarSectionFrame(width, height, index)];
        [content addSubview:button positioned:NSWindowAbove relativeTo:nil]; index++;
    }
    if (self.markAllChatsReadSpinner) {
        NSRect chatsFrame = [[self.navigationButtons objectAtIndex:2] frame];
        [self.markAllChatsReadSpinner setFrame:NSMakeRect(NSMaxX(chatsFrame)-18, NSMidY(chatsFrame)-7, 14, 14)];
        [content addSubview:self.markAllChatsReadSpinner positioned:NSWindowAbove relativeTo:nil];
    }
    [self.aquaDownloadsButton setFrame:NSMakeRect(width-124, height-39, 112, 30)];
    [self.aquaFolderEditButton setFrame:NSMakeRect(sidebarWidth-88, NSMaxY(sidebar)-30, 80, 26)];
    [self.aquaFolderDrawer setFolderButtons:self.drawerFolderButtons];
    BOOL external = [self aquaUsesExternalFolderDrawer];
    [self.aquaFolderHeaderButton setFrame:NSMakeRect(8, NSMaxY(sidebar)-30, MAX(86, sidebarWidth-(external ? 16 : 104)), 26)];
    TGAquaSourceListGeometry frames = TGAquaSourceListFrames(sidebar, 0.0, self.aquaFolderPreferredHeight, [self.drawerFolderButtons count], external || ![self aquaFolderListExpanded]);
    [self.aquaFolderDivider setFrame:frames.divider];
    [self layoutAquaFolderListInFrame:frames.folders];
    [self.aquaChatHeaderView setFrame:frames.chatHeader];
    [content addSubview:self.aquaChatHeaderView positioned:NSWindowAbove relativeTo:nil];
    BOOL compact = [self isChatSidebarCompactForWidth:sidebarWidth];
    if (!compact) {
        TGAquaChatHeaderGeometry header = TGAquaChatHeaderFrames(frames.chatHeader, self.showingForumTopicList);
        [self.topicBackButton setFrame:header.back];
        [self.chatsLabel setFrame:header.title];
        [[self.chatsLabel cell] setWraps:NO];
        [[self.chatsLabel cell] setScrollable:YES];
        [[self.chatsLabel cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.chatsLabel setToolTip:[self.chatsLabel stringValue]];
        [self.composeChatButton setFrame:header.compose];
        [self.chatSearchButton setFrame:header.search];
        [self.loadChatsButton setFrame:header.refresh];
        [self.loadMoreChatsButton setFrame:header.refresh];
    }
    NSArray *headerControls = [NSArray arrayWithObjects:self.topicBackButton,self.chatsLabel,self.composeChatButton,self.chatSearchButton,self.loadChatsButton,self.loadMoreChatsButton,nil];
    for (NSView *view in headerControls) [content addSubview:view positioned:NSWindowAbove relativeTo:nil];
    [self.chatScrollSurfaceView setFrame:frames.chats];
    [self.chatScrollView setFrame:NSInsetRect(frames.chats,2,2)];
    [self.chatScrollView tile];
    [[self.chatTableView tableColumnWithIdentifier:@"chat"] setWidth:NSWidth([[self.chatScrollView contentView] bounds])];
    BOOL ru = [TGLanguageCode() isEqualToString:@"ru"];
    [self.aquaFolderHeaderButton setTitle:[NSString stringWithFormat:@"%@ · %lu", ru ? @"ПАПКИ" : @"FOLDERS", (unsigned long)[self.drawerFolderButtons count]]];
    [self updateAquaShellVisibility];
}
