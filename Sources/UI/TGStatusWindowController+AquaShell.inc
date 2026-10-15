// Optional shell. The controller's existing actions/data sources remain shared.
- (void)installAquaTextCellOnButton:(NSButton *)button accented:(BOOL)accented {
    id target = [button target]; SEL action = [button action];
    NSString *title = [[button title] copy]; NSInteger state = [button state];
    TGAquaTextButtonCell *cell = [[[TGAquaTextButtonCell alloc] initTextCell:title] autorelease];
    [cell setAccented:accented];
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
    NSView *content = [[self window] contentView];
    self.aquaToolbarView = [[[TGAquaMetalView alloc] initWithFrame:NSZeroRect] autorelease];
    self.aquaFooterView = [[[TGAquaMetalView alloc] initWithFrame:NSZeroRect] autorelease];
    [content addSubview:self.aquaToolbarView];
    [content addSubview:self.aquaFooterView];
    self.aquaFolderHeaderButton = [self aquaButtonWithAction:@selector(toggleAquaFolders:)];
    self.aquaFolderEditButton = [self aquaButtonWithAction:@selector(showChatFolderManagementWindow:)];
    self.aquaSearchButton = [self aquaButtonWithAction:@selector(openChatSearchWindow:)];
    self.aquaDownloadsButton = [self aquaButtonWithAction:@selector(showDownloadManagerWindow:)];
    self.aquaArchiveButton = [self aquaButtonWithAction:@selector(openAquaArchive:)];
    [self.aquaArchiveButton setTag:-2];
    self.aquaFolderDivider = [[[TGAquaFolderDivider alloc] initWithFrame:NSZeroRect] autorelease];
    [self.aquaFolderDivider setTarget:self];
    [self.aquaFolderDivider setAction:@selector(resizeAquaFolders:)];
    [content addSubview:self.aquaFolderDivider];
    self.aquaFolderPreferredHeight = [[NSUserDefaults standardUserDefaults] doubleForKey:@"TGAquaFolderHeight"];
    if (self.aquaFolderPreferredHeight < 76.0) self.aquaFolderPreferredHeight = 210.0;
    self.aquaFoldersCollapsed = [[NSUserDefaults standardUserDefaults] boolForKey:@"TGAquaFoldersCollapsed"];
    for (NSButton *button in self.navigationButtons) [self installAquaTextCellOnButton:button accented:NO];
    [self installAquaTextCellOnButton:self.workshopDrawerButton accented:NO];
    [self installAquaTextCellOnButton:self.attachPhotoButton accented:NO];
    [self installAquaTextCellOnButton:self.sendMessageButton accented:YES];
    [self.drawerFolderScrollView setAutohidesScrollers:NO];
}

- (void)refreshInterfaceDesignControls {
    BOOL ru = [TGLanguageCode() isEqualToString:@"ru"];
    [self.interfaceDesignLabel setStringValue:ru ? @"Интерфейс" : @"Interface"];
    [self.interfaceDesignHint setStringValue:ru ? @"Смена дизайна потребует перезапуска. Классические темы сохраняются." : @"Changing design restarts the app. Your classic theme is preserved."];
    [self.interfaceDesignLabel setTextColor:TGClassicCardInkColor()];
    [self.interfaceDesignHint setTextColor:TGClassicCardMutedInkColor()];
    [self.interfaceDesignPopUpButton removeAllItems];
    [self.interfaceDesignPopUpButton addItemsWithTitles:[NSArray arrayWithObjects:ru ? @"Классический" : @"Classic", @"Aqua", nil]];
    [self.interfaceDesignPopUpButton selectItemAtIndex:TGInterfaceDesignIsAqua() ? 1 : 0];
    [self.themePopUpButton setEnabled:!TGInterfaceDesignIsAqua()];
    [self.themeCategoryPopUpButton setEnabled:!TGInterfaceDesignIsAqua()];
    if (!TGInterfaceDesignIsAqua()) return;
    [self.aquaFolderHeaderButton setTitle:ru ? @"Папки" : @"Folders"];
    [self.aquaFolderHeaderButton setToolTip:ru ? @"Свернуть или развернуть список папок" : @"Collapse or expand folders"];
    [self.aquaFolderEditButton setTitle:ru ? @"Изменить" : @"Edit"];
    [self.aquaSearchButton setTitle:ru ? @"Поиск чатов" : @"Search chats"];
    [self.aquaDownloadsButton setTitle:ru ? @"Загрузки" : @"Downloads"];
    [self.aquaArchiveButton setTitle:TGLoc(@"drawer.archive")];
    [self.workshopDrawerButton setTitle:TGLoc(@"workshop.title")];
    [self.attachPhotoButton setTitle:ru ? @"Файл" : @"File"];
    [self.sendMessageButton setTitle:TGLoc(@"send")];
}

- (void)interfaceDesignSelectionChanged:(id)sender {
    (void)sender;
    NSString *identifier = [self.interfaceDesignPopUpButton indexOfSelectedItem] == 1 ? @"aqua" : @"classic";
    NSError *error = nil;
    if (!TGRequestInterfaceDesignChange(identifier, [self window], &error)) {
        [self.interfaceDesignPopUpButton selectItemAtIndex:TGInterfaceDesignIsAqua() ? 1 : 0];
        if (error) [[NSAlert alertWithError:error] runModal];
    }
}

- (void)openAquaArchive:(id)sender {
    self.activeSection = TGSectionChats;
    [self folderFilterChanged:sender];
    [self layoutContentView]; [self updateVisibleSection];
}

- (void)toggleAquaFolders:(id)sender {
    (void)sender;
    self.aquaFoldersCollapsed = !self.aquaFoldersCollapsed;
    [[NSUserDefaults standardUserDefaults] setBool:self.aquaFoldersCollapsed forKey:@"TGAquaFoldersCollapsed"];
    [self layoutContentView]; [self updateVisibleSection];
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
    for (NSView *view in [NSArray arrayWithObjects:self.aquaToolbarView, self.aquaFooterView, self.aquaSearchButton, self.aquaDownloadsButton, self.aquaArchiveButton, self.workshopDrawerButton, nil]) [view setHidden:!ready];
    for (NSButton *button in self.navigationButtons) [button setHidden:!ready];
    for (NSView *view in [NSArray arrayWithObjects:self.aquaFolderHeaderButton, self.aquaFolderEditButton, nil]) [view setHidden:!chats];
    [self.aquaFolderDivider setHidden:(!chats || self.aquaFoldersCollapsed)];
    [self.drawerFolderScrollView setHidden:(!chats || self.aquaFoldersCollapsed)];
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
    CGFloat controlY = NSMinY([self.attachPhotoButton frame]);
    CGFloat footerHeight = MAX(52.0, NSMaxY([self.sendTextFieldBackgroundView frame]) + 6.0);
    [self.aquaToolbarView setFrame:NSMakeRect(0, height-54, width, 54)];
    [self.aquaFooterView setFrame:NSMakeRect(0, 0, width, footerHeight)];
    // Chrome is behind the live controls, not an overlay over the composer.
    [content addSubview:self.aquaFooterView positioned:NSWindowBelow relativeTo:self.attachPhotoButton];
    [self.accountBadgeView setFrame:NSMakeRect(12, height-44, 32, 34)];
    [content addSubview:self.accountBadgeView positioned:NSWindowAbove relativeTo:nil];
    CGFloat searchWidth = MIN(200.0, floor(width*0.18));
    [self.aquaSearchButton setFrame:NSMakeRect(54, height-42, searchWidth, 30)];
    CGFloat navigationX = 66 + searchWidth;
    NSArray *order = [NSArray arrayWithObjects:[self.navigationButtons objectAtIndex:2], [self.navigationButtons objectAtIndex:0], [self.navigationButtons objectAtIndex:1], self.workshopDrawerButton, nil];
    NSUInteger index = 0;
    for (NSButton *button in order) {
        [button setFrame:NSMakeRect(navigationX + index*78, height-42, 77, 30)];
        [content addSubview:button positioned:NSWindowAbove relativeTo:nil]; index++;
    }
    if (self.markAllChatsReadSpinner) {
        NSRect chatsFrame = [[self.navigationButtons objectAtIndex:2] frame];
        [self.markAllChatsReadSpinner setFrame:NSMakeRect(NSMaxX(chatsFrame)-18, NSMidY(chatsFrame)-7, 14, 14)];
        [content addSubview:self.markAllChatsReadSpinner positioned:NSWindowAbove relativeTo:nil];
    }
    [self.aquaDownloadsButton setFrame:NSMakeRect(width-124, height-42, 112, 30)];
    [self.aquaArchiveButton setFrame:NSMakeRect(12, controlY, floor((sidebarWidth-30)/2), 32)];
    NSButton *settings = [self.navigationButtons objectAtIndex:3];
    [settings setFrame:NSMakeRect(NSMaxX([self.aquaArchiveButton frame])+6, controlY, floor((sidebarWidth-30)/2), 32)];
    [content addSubview:settings positioned:NSWindowAbove relativeTo:nil];
    [self.aquaFolderHeaderButton setFrame:NSMakeRect(8, NSMaxY(sidebar)-30, MAX(86, sidebarWidth-104), 26)];
    [self.aquaFolderEditButton setFrame:NSMakeRect(sidebarWidth-88, NSMaxY(sidebar)-30, 80, 26)];
    TGAquaSourceListGeometry frames = TGAquaSourceListFrames(sidebar, footerHeight, self.aquaFolderPreferredHeight, self.aquaFoldersCollapsed);
    [self.drawerFolderScrollView setFrame:frames.folders];
    [content addSubview:self.drawerFolderScrollView positioned:NSWindowAbove relativeTo:nil];
    [self.aquaFolderDivider setFrame:frames.divider];
    CGFloat folderWidth = NSWidth([[self.drawerFolderScrollView contentView] bounds]);
    CGFloat documentHeight = MAX(NSHeight(frames.folders), [self.drawerFolderButtons count]*32.0);
    [self.drawerFolderContentView setFrame:NSMakeRect(0,0,folderWidth,documentHeight)];
    index = 0;
    for (NSButton *button in self.drawerFolderButtons) { [button setFrame:NSMakeRect(0,index*32.0,folderWidth,32)]; index++; }
    CGFloat maximumY = MAX(0, documentHeight-NSHeight([[self.drawerFolderScrollView contentView] bounds]));
    NSPoint origin = [[self.drawerFolderScrollView contentView] bounds].origin;
    [[self.drawerFolderScrollView contentView] setBoundsOrigin:NSMakePoint(0, MIN(MAX(0,origin.y), maximumY))];
    [self.drawerFolderScrollView reflectScrolledClipView:[self.drawerFolderScrollView contentView]];
    CGFloat headerY = NSMinY(frames.chatHeader)+3;
    NSArray *headerControls = [NSArray arrayWithObjects:self.topicBackButton,self.chatsLabel,self.composeChatButton,self.chatSearchButton,self.loadChatsButton,nil];
    for (NSView *view in headerControls) { NSRect r = [view frame]; r.origin.y = headerY + (view==self.chatsLabel ? 5 : 0); [view setFrame:r]; }
    if (!self.showingForumTopicList) {
        [self.chatsLabel setFrame:NSMakeRect(10, headerY+5, MAX(60,sidebarWidth-126), 20)];
    }
    [self.chatScrollSurfaceView setFrame:frames.chats];
    [self.chatScrollView setFrame:NSInsetRect(frames.chats,2,2)];
    [self.chatScrollView tile];
    [[self.chatTableView tableColumnWithIdentifier:@"chat"] setWidth:NSWidth([[self.chatScrollView contentView] bounds])];
    [self.aquaArchiveButton setState:self.showingArchivedChats ? NSOnState : NSOffState];
    [self updateAquaShellVisibility];
}
