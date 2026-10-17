- (void)buildAquaViews {
    TGUtilityWindowView *root = [[[TGUtilityWindowView alloc] initWithFrame:[[[self window] contentView] bounds]] autorelease];
    [root setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[self window] setContentView:root];
    self.aquaTitleField=[self labelWithFrame:NSZeroRect font:[NSFont boldSystemFontOfSize:16] surface:TGThemeSurfaceWindow detail:NO];
    [self.aquaTitleField setStringValue:TGLoc(@"contacts.title")]; [root addSubview:self.aquaTitleField];

    self.createPopUpButton=[[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:YES] autorelease];
    [self.createPopUpButton setAutoenablesItems:NO];
    [self.createPopUpButton addItemWithTitle:TGLoc(@"contacts.createMenu")];
    NSArray *titles=[NSArray arrayWithObjects:TGLoc(@"create.channel"),TGLoc(@"create.group"),TGLoc(@"create.secret"),nil];
    SEL actions[]={@selector(createChannel:),@selector(createGroup:),@selector(createSecretChat:)};
    for(NSUInteger i=0;i<[titles count];i++) {
        NSMenuItem *item=[[[NSMenuItem alloc] initWithTitle:[titles objectAtIndex:i] action:actions[i] keyEquivalent:@""] autorelease];
        [item setTarget:self]; [item setTag:i]; [[self.createPopUpButton menu] addItem:item];
    }
    [self.createPopUpButton setToolTip:TGLoc(@"contacts.createMenu")]; [root addSubview:self.createPopUpButton];
    self.searchField=[[[NSSearchField alloc] initWithFrame:NSZeroRect] autorelease];
    [[self.searchField cell] setPlaceholderString:TGLoc(@"contacts.search")]; [self.searchField setDelegate:(id)self];
    TGAccessibilityConfigureContent(self.searchField,TGLoc(@"contacts.search")); [root addSubview:self.searchField];
    self.refreshButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [self.refreshButton setCell:[[[TGHeaderIconButtonCell alloc] initTextCell:@"↻"] autorelease]];
    [self.refreshButton setTitle:@"↻"]; [self.refreshButton setToolTip:TGLoc(@"contacts.refresh")];
    [self.refreshButton setTarget:self]; [self.refreshButton setAction:@selector(refreshContactsAction:)]; [root addSubview:self.refreshButton];

    self.aquaListCard=[[[TGGroupedCardView alloc] initWithFrame:NSZeroRect] autorelease]; [root addSubview:self.aquaListCard];
    self.aquaListScrollView=[[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];
    [self.aquaListScrollView setBorderType:NSNoBorder]; [self.aquaListScrollView setHasVerticalScroller:YES];
    [self.aquaListScrollView setAutohidesScrollers:YES]; [self.aquaListScrollView setDrawsBackground:NO];
    [[self.aquaListScrollView contentView] setDrawsBackground:NO];
    self.tableView=[[[NSTableView alloc] initWithFrame:NSZeroRect] autorelease];
    [self.tableView setDataSource:self]; [self.tableView setDelegate:self]; [self.tableView setAllowsMultipleSelection:YES];
    [self.tableView setHeaderView:nil]; [self.tableView setRowHeight:54]; [self.tableView setIntercellSpacing:NSMakeSize(0,1)];
    [self.tableView setBackgroundColor:TGClassicTablePaperColor()]; [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(openSelectedContact:)]; [self.tableView setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle];
    NSTableColumn *column=[[[NSTableColumn alloc] initWithIdentifier:@"contact"] autorelease];
    [column setDataCell:[[[TGChatLifecycleContactCell alloc] initTextCell:@""] autorelease]];
    [column setResizingMask:NSTableColumnAutoresizingMask]; [self.tableView addTableColumn:column];
    TGAccessibilityConfigureList(self.tableView,TGLoc(@"contacts.title"));
    [self.aquaListScrollView setDocumentView:self.tableView]; [root addSubview:self.aquaListScrollView];

    self.statusField=[self labelWithFrame:NSZeroRect font:[NSFont systemFontOfSize:11] surface:TGThemeSurfaceWindow detail:YES];
    [self.statusField setStringValue:TGLoc(@"contacts.loading")]; [root addSubview:self.statusField];
    self.spinner=[[[NSProgressIndicator alloc] initWithFrame:NSZeroRect] autorelease];
    [self.spinner setStyle:NSProgressIndicatorSpinningStyle]; [self.spinner setControlSize:NSSmallControlSize];
    [self.spinner setDisplayedWhenStopped:NO]; [root addSubview:self.spinner];
    self.openButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [self.openButton setCell:[[[TGPrimaryTextButtonCell alloc] initTextCell:TGLoc(@"contacts.open")] autorelease]];
    [self.openButton setTitle:TGLoc(@"contacts.open")]; [self.openButton setTarget:self]; [self.openButton setAction:@selector(openSelectedContact:)];
    [self.openButton setEnabled:NO]; [root addSubview:self.openButton];
    self.inviteDisclosureButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [self.inviteDisclosureButton setButtonType:NSPushOnPushOffButton];
    [self.inviteDisclosureButton setBezelStyle:NSRoundedBezelStyle];
    [self.inviteDisclosureButton setTitle:TGLoc(@"contacts.inviteTitle")];
    [self.inviteDisclosureButton setToolTip:TGLoc(@"contacts.inviteTitle")];
    [self.inviteDisclosureButton setTarget:self]; [self.inviteDisclosureButton setAction:@selector(toggleAquaInvitation:)];
    [root addSubview:self.inviteDisclosureButton];
    self.inviteField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [[self.inviteField cell] setPlaceholderString:TGLoc(@"contacts.invitePlaceholder")]; [self.inviteField setDelegate:self];
    TGAccessibilityConfigureContent(self.inviteField,TGLoc(@"contacts.inviteTitle")); [root addSubview:self.inviteField];
    self.joinButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [self.joinButton setCell:[[[TGSecondaryTextButtonCell alloc] initTextCell:TGLoc(@"contacts.join")] autorelease]];
    [self.joinButton setTitle:TGLoc(@"contacts.join")]; [self.joinButton setTarget:self]; [self.joinButton setAction:@selector(joinInviteLink:)];
    [self.joinButton setEnabled:NO]; [root addSubview:self.joinButton];
    [self layoutAquaViews]; [self updateSelectionActions];
}

- (void)layoutAquaViews {
    if (!self.createPopUpButton) return;
    TGChatLifecycleAquaGeometry g=TGChatLifecycleAquaFrames([[[self window] contentView] bounds].size,self.aquaInvitationVisible);
    [self.aquaTitleField setFrame:g.title]; [self.createPopUpButton setFrame:g.create];
    [self.searchField setFrame:g.search]; [self.refreshButton setFrame:g.refresh];
    [self.aquaListCard setFrame:g.list]; [self.aquaListScrollView setFrame:NSInsetRect(g.list,5,5)];
    [self.aquaListScrollView tile];
    NSTableColumn *column=[[self.tableView tableColumns] lastObject];
    [column setWidth:NSWidth([[self.aquaListScrollView contentView] bounds])];
    [self.statusField setFrame:g.status]; [self.spinner setFrame:g.spinner];
    [self.openButton setFrame:g.open]; [self.inviteDisclosureButton setFrame:g.inviteToggle];
    [self.inviteField setFrame:g.inviteField]; [self.joinButton setFrame:g.join];
    [self.inviteField setHidden:!self.aquaInvitationVisible]; [self.joinButton setHidden:!self.aquaInvitationVisible];
    [self.inviteDisclosureButton setState:self.aquaInvitationVisible ? NSOnState : NSOffState];
}
- (void)toggleAquaInvitation:(id)sender {
    (void)sender; self.aquaInvitationVisible=!self.aquaInvitationVisible;
    [self layoutAquaViews];
    [[self window] makeFirstResponder:self.aquaInvitationVisible ? (NSResponder *)self.inviteField : (NSResponder *)self.searchField];
}
- (void)windowDidResize:(NSNotification *)notification {
    if ([notification object]==[self window]) [self layoutAquaViews];
}
