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

- (void)installAquaToolbarCellOnButton:(NSButton *)button asset:(NSString *)asset toggle:(BOOL)toggle {
    id target=[button target];SEL action=[button action];NSInteger state=[button state];
    NSString *title=[[button title] copy];
    NSString *badge=[[button cell] respondsToSelector:@selector(badgeText)] ? [[(TGNavigationButtonCell *)[button cell] badgeText] copy] : nil;
    static NSDictionary *colorAssets=nil;
    if(!colorAssets) colorAssets=[[NSDictionary alloc] initWithObjectsAndKeys:
        @"AquaToolbar/chats",@"chat",@"AquaToolbar/contacts",@"contacts",@"AquaToolbar/calls",@"call-receive",
        @"AquaToolbar/workshop",@"workshop",@"AquaToolbar/settings",@"settings",@"AquaToolbar/downloads",@"arrow-down",nil];
    NSString *originalName=[colorAssets objectForKey:asset];
    NSImage *original=TGIconAssetImageNamed(originalName);
    TGAquaToolbarItemCell *cell=[[[TGAquaToolbarItemCell alloc] initTextCell:title] autorelease];
    [cell setButtonType:toggle ? NSToggleButton : NSMomentaryPushInButton];
    [cell setIconOnly:YES];[cell setIconAssetName:asset];[cell setBadgeText:badge];
    [cell setImage:original ? original : TGIconAssetImageNamed(asset)];[cell setUsesOriginalIconColors:original!=nil];
    [button setCell:cell];[button setTitle:title];[button setState:state];
    [button setTarget:target];[button setAction:action];[button setBordered:NO];
    [button setFocusRingType:NSFocusRingTypeExterior];[button setToolTip:title];[title release];[badge release];
}
- (NSPopUpButton *)aquaToolbarAccountButton {
    return objc_getAssociatedObject(self,@selector(aquaToolbarAccountButton));
}
- (NSSearchField *)aquaToolbarSearchField {
    return objc_getAssociatedObject(self,@selector(aquaToolbarSearchField));
}
- (void)configureAquaToolbarAccessories {
    NSPopUpButton *account=[[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:YES] autorelease];
    [account setBordered:NO];[account setFont:[NSFont systemFontOfSize:13]];
    [[account cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [account addItemWithTitle:@"Telegraphica"];
    NSMenuItem *profile=[[[NSMenuItem alloc] initWithTitle:TGLoc(@"profile.title") action:@selector(openProfileFromDrawer:) keyEquivalent:@""] autorelease];
    [profile setTarget:self];[[account menu] addItem:profile];
    NSMenuItem *settings=[[[NSMenuItem alloc] initWithTitle:TGLoc(@"settings") action:@selector(navigationChanged:) keyEquivalent:@""] autorelease];
    [settings setTarget:self];[settings setTag:3];[[account menu] addItem:settings];
    objc_setAssociatedObject(self,@selector(aquaToolbarAccountButton),account,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.aquaToolbarView addSubview:account];
    NSSearchField *search=[[[NSSearchField alloc] initWithFrame:NSZeroRect] autorelease];
    [search setTarget:self];[search setAction:@selector(commitAquaToolbarSearch:)];
    [search setFont:[NSFont systemFontOfSize:12]];
    [[search cell] setSendsWholeSearchString:YES];[[search cell] setSendsSearchStringImmediately:NO];
    [search setFocusRingType:NSFocusRingTypeDefault];
    objc_setAssociatedObject(self,@selector(aquaToolbarSearchField),search,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.aquaToolbarView addSubview:search];[self refreshAquaToolbarAccount];
}
- (void)refreshAquaToolbarAccount {
    NSPopUpButton *account=[self aquaToolbarAccountButton];if(!account) return;
    NSString *full=[self.accountBadgeView displayName];if(![full length]) full=@"Telegraphica";
    NSString *name=[self.profileFirstName length] ? self.profileFirstName : full;
    [[account itemAtIndex:0] setTitle:name];[account setTitle:name];
    [[account itemAtIndex:1] setTitle:TGLoc(@"profile.title")];[[account itemAtIndex:2] setTitle:TGLoc(@"settings")];
    [account setToolTip:[NSString stringWithFormat:@"%@ — %@",full,TGLoc(@"profile.openHint")]];
    [[[self aquaToolbarSearchField] cell] setPlaceholderString:TGLoc(@"search.chats.title")];
    [[self aquaToolbarSearchField] setToolTip:TGLoc(@"search.chats.title")];
}
- (void)commitAquaToolbarSearch:(id)sender {
    if(![self.currentAuthState isEqualToString:@"ready"]) return;
    NSString *query=[[[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
    if([query length]) {
        [self openChatSearchWindow:sender];
        TGChatSearchPanelView *panel=[self chatSearchPanelView];[panel setQuery:query];
        [self updateChatSearchWindowResults];
        [self.chatSearchWindow makeFirstResponder:[panel searchField]];
        NSTextView *editor=(NSTextView *)[[panel searchField] currentEditor];
        [editor setSelectedRange:NSMakeRange([query length],0)];[sender setStringValue:@""];
    }
    [query release];
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
    [self installAquaToolbarCellOnButton:self.aquaDownloadsButton asset:@"arrow-down" toggle:NO];
    [self configureAquaToolbarAccessories];
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
        [self installAquaToolbarCellOnButton:[toolbarButtons objectAtIndex:toolbarIndex]
            asset:[toolbarAssets objectAtIndex:toolbarIndex] toggle:YES];
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
    [self.aquaDownloadsButton setToolTip:TGLoc(@"downloads.short")];
    [self.workshopDrawerButton setToolTip:TGLoc(@"workshop.title")];
    [self refreshAquaToolbarAccount];
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
    [self.aquaSearchButton setHidden:YES]; // Replaced by the editable native search field.
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
    TGAquaToolbarGeometry toolbar=TGAquaToolbarFrames(width,height);
    [self.accountBadgeView setFrame:toolbar.avatar];
    [content addSubview:self.accountBadgeView positioned:NSWindowAbove relativeTo:nil];
    NSRect accountFrame=toolbar.account,searchFrame=toolbar.search;
    accountFrame.origin.y-=height-TGAquaToolbarHeight();searchFrame.origin.y-=height-TGAquaToolbarHeight();
    NSPopUpButton *account=[self aquaToolbarAccountButton];
    CGFloat nameWidth=ceil([[account title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[account font] forKey:NSFontAttributeName]].width)+28;
    accountFrame.size.width=MIN(NSWidth(accountFrame),MAX(54,nameWidth));
    [[self aquaToolbarAccountButton] setFrame:accountFrame];[[self aquaToolbarSearchField] setFrame:searchFrame];
    NSArray *order = [NSArray arrayWithObjects:[self.navigationButtons objectAtIndex:2], [self.navigationButtons objectAtIndex:0], [self.navigationButtons objectAtIndex:1], self.workshopDrawerButton, [self.navigationButtons objectAtIndex:3], nil];
    NSUInteger index = 0;
    for (NSButton *button in order) {
        [button setFrame:TGAquaToolbarSectionFrame(width, height, index)];
        [content addSubview:button positioned:NSWindowAbove relativeTo:nil]; index++;
    }
    if (self.markAllChatsReadSpinner) {
        NSRect chatsFrame = [[self.navigationButtons objectAtIndex:2] frame];
        [self.markAllChatsReadSpinner setFrame:NSMakeRect(NSMidX(chatsFrame)+8, NSMaxY(chatsFrame)-18, 14, 14)];
        [content addSubview:self.markAllChatsReadSpinner positioned:NSWindowAbove relativeTo:nil];
    }
    [self.aquaDownloadsButton setFrame:toolbar.downloads];
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
