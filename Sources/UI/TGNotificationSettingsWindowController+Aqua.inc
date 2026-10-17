/* Local filtering changes only the displayed list. Mutations still use chat_id. */
- (NSArray *)displayedExceptions {return self.aquaViews ? self.filteredExceptions : self.exceptions;}
- (void)applyAquaSearch {
    NSNumber *selectedID=[[[self selectedSummary] objectForKey:@"chat_id"] retain];
    NSString *query=[[self.aquaSearchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *matches=[NSMutableArray array];
    for(NSDictionary *summary in self.exceptions) {
        NSString *title=[[summary objectForKey:@"title"] isKindOfClass:[NSString class]] ? [summary objectForKey:@"title"] : @"";
        if(![query length] || [title rangeOfString:query options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].location!=NSNotFound)[matches addObject:summary];
    }
    self.filteredExceptions=matches; [self.tableView reloadData];[self.tableView deselectAll:nil];
    for(NSUInteger i=0;i<[matches count];i++)if([[[matches objectAtIndex:i] objectForKey:@"chat_id"] isEqual:selectedID]){[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];break;}
    [selectedID release];[self tableViewSelectionDidChange:nil];
}
- (void)aquaSearchChanged:(id)sender {(void)sender;[self applyAquaSearch];}
- (void)controlTextDidChange:(NSNotification *)notification {if([notification object]==self.aquaSearchField)[self applyAquaSearch];}
- (NSTextField *)aquaNotificationLabel:(NSString *)key text:(NSString *)text {
    NSTextField *field=[self labelWithFrame:NSZeroRect font:[NSFont systemFontOfSize:12] surface:TGThemeSurfaceCard detail:NO];
    [field setStringValue:text];[self.aquaViews setObject:field forKey:key];[[[self window] contentView] addSubview:field];return field;
}
- (void)buildAquaViews {
    TGAquaUtilityWindowView *root=[[[TGAquaUtilityWindowView alloc] initWithFrame:[[[self window] contentView] bounds]] autorelease];
    [root setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];[[self window] setContentView:root];[[self window] setDelegate:(id)self];
    self.aquaViews=[NSMutableDictionary dictionary];self.filteredExceptions=[NSArray array];
    NSTextField *heading=[self aquaNotificationLabel:@"heading" text:TGLoc(@"notifications.exceptions.title")];[heading setFont:[NSFont boldSystemFontOfSize:14]];
    self.refreshButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[self.refreshButton setCell:[[[TGHeaderIconButtonCell alloc] initTextCell:@""] autorelease]];
    [self.refreshButton setImage:TGTemplateIconAssetImage(@"refresh",NSMakeSize(18,18),TGClassicHeaderTextColor(1),1)];[self.refreshButton setTitle:@""];[self.refreshButton setToolTip:TGLoc(@"refresh")];[self.refreshButton setTarget:self];[self.refreshButton setAction:@selector(refreshPressed:)];[root addSubview:self.refreshButton];
    self.aquaSearchField=[[[NSSearchField alloc] initWithFrame:NSZeroRect] autorelease];[[self.aquaSearchField cell] setPlaceholderString:TGLoc(@"folders.searchChats")];[self.aquaSearchField setDelegate:(id)self];[self.aquaSearchField setTarget:self];[self.aquaSearchField setAction:@selector(aquaSearchChanged:)];[root addSubview:self.aquaSearchField];
    self.tableView=[[[NSTableView alloc] initWithFrame:NSZeroRect] autorelease];[self.tableView setHeaderView:nil];[self.tableView setRowHeight:44];[self.tableView setIntercellSpacing:NSMakeSize(0,1)];
    [self.tableView setBackgroundColor:TGClassicTablePaperColor()];[self.tableView setDataSource:self];[self.tableView setDelegate:self];[self.tableView setAllowsEmptySelection:YES];[self.tableView setAllowsMultipleSelection:NO];
    [self.tableView setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle];
    NSTableColumn *column=[[[NSTableColumn alloc] initWithIdentifier:@"title"] autorelease];[column setDataCell:[[[TGNotificationExceptionCell alloc] initTextCell:@""] autorelease]];[self.tableView addTableColumn:column];
    NSScrollView *scroll=[[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];[scroll setBorderType:NSNoBorder];[scroll setHasVerticalScroller:YES];[scroll setAutohidesScrollers:YES];[scroll setDrawsBackground:YES];[scroll setBackgroundColor:TGClassicTablePaperColor()];[scroll setDocumentView:self.tableView];[root addSubview:scroll];[self.aquaViews setObject:scroll forKey:@"scroll"];
    NSBox *divider=[[[NSBox alloc] initWithFrame:NSZeroRect] autorelease];[divider setBoxType:NSBoxSeparator];[root addSubview:divider];[self.aquaViews setObject:divider forKey:@"divider"];
    self.selectionField=[self aquaNotificationLabel:@"selection" text:TGLoc(@"notifications.exceptions.select")];[self.selectionField setFont:[NSFont boldSystemFontOfSize:14]];
    [[self.selectionField cell] setWraps:YES];[[self.selectionField cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [self aquaNotificationLabel:@"muteLabel" text:TGLoc(@"notifications.exceptions.mute")];
    self.mutePopUpButton=[[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    for(NSString *key in [NSArray arrayWithObjects:@"notifications.exceptions.on",@"notifications.mute.hour",@"notifications.mute.eightHours",@"notifications.mute.day",@"notifications.mute.forever",nil])[self.mutePopUpButton addItemWithTitle:TGLoc(key)];[root addSubview:self.mutePopUpButton];
    self.previewButton=[[[TGThemeSwitchButton alloc] initWithFrame:NSZeroRect] autorelease];[self.previewButton setButtonType:NSSwitchButton];[self.previewButton setTitle:TGLoc(@"notifications.exceptions.preview")];[self.previewButton setFont:[NSFont systemFontOfSize:12]];[root addSubview:self.previewButton];
    self.statusField=[self labelWithFrame:NSZeroRect font:[NSFont systemFontOfSize:11] surface:TGThemeSurfaceWindow detail:YES];[self.statusField setStringValue:TGLoc(@"notifications.exceptions.loading")];[root addSubview:self.statusField];
    self.spinner=[[[NSProgressIndicator alloc] initWithFrame:NSZeroRect] autorelease];[self.spinner setStyle:NSProgressIndicatorSpinningStyle];[self.spinner setControlSize:NSSmallControlSize];[self.spinner setDisplayedWhenStopped:NO];[root addSubview:self.spinner];
    self.resetButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[self.resetButton setCell:[[[TGSecondaryTextButtonCell alloc] initTextCell:TGLoc(@"notifications.exceptions.reset")] autorelease]];[self.resetButton setTitle:TGLoc(@"notifications.exceptions.reset")];[self.resetButton setTarget:self];[self.resetButton setAction:@selector(resetPressed:)];[root addSubview:self.resetButton];
    self.applyButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[self.applyButton setCell:[[[TGPrimaryTextButtonCell alloc] initTextCell:TGLoc(@"apply")] autorelease]];[self.applyButton setTitle:TGLoc(@"apply")];[self.applyButton setTarget:self];[self.applyButton setAction:@selector(applyPressed:)];[root addSubview:self.applyButton];
    [self layoutAquaViews];[self updateEditorAvailability];
}
- (void)layoutAquaViews {
    if(!self.aquaViews)return; NSSize size=[[[self window] contentView] bounds].size;CGFloat w=size.width,h=size.height,left=MIN(290,floor(w*0.43)),x=left+22,editor=w-x-20;
    [[self.aquaViews objectForKey:@"heading"] setFrame:NSMakeRect(20,h-34,w-90,20)];[self.refreshButton setFrame:NSMakeRect(w-50,h-41,30,30)];
    [self.aquaSearchField setFrame:NSMakeRect(12,h-94,left-24,26)];
    NSScrollView *scroll=[self.aquaViews objectForKey:@"scroll"];[scroll setFrame:NSMakeRect(4,62,left-8,MAX(0,h-164))];[scroll tile];[[[self.tableView tableColumns] objectAtIndex:0] setWidth:NSWidth([[scroll contentView] bounds])];
    [self.tableView setFrameSize:NSMakeSize(NSWidth([[scroll contentView] bounds]),MAX(NSHeight([[scroll contentView] bounds]),[self.tableView numberOfRows]*45.0))];
    [[self.aquaViews objectForKey:@"divider"] setFrame:NSMakeRect(left,54,1,MAX(0,h-106))];
    [self.selectionField setFrame:NSMakeRect(x,h-116,editor,48)];
    [[self.aquaViews objectForKey:@"muteLabel"] setFrame:NSMakeRect(x,h-154,editor,20)];[self.mutePopUpButton setFrame:NSMakeRect(x,h-189,editor,28)];
    [self.previewButton setFrame:NSMakeRect(x,h-231,editor,24)];
    [self.statusField setFrame:NSMakeRect(20,19,MAX(0,w-332),18)];[self.spinner setFrame:NSMakeRect(w-302,20,16,16)];
    [self.resetButton setFrame:NSMakeRect(w-278,12,122,30)];[self.applyButton setFrame:NSMakeRect(w-144,12,124,30)];
}
- (void)windowDidResize:(NSNotification *)notification {if([notification object]==[self window])[self layoutAquaViews];}
