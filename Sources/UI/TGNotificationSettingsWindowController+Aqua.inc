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
    [selectedID release];[self tableViewSelectionDidChange:nil];[self updateAquaNotificationContext];
}
- (void)aquaSearchChanged:(id)sender {(void)sender;[self applyAquaSearch];}
- (void)controlTextDidChange:(NSNotification *)notification {if([notification object]==self.aquaSearchField)[self applyAquaSearch];}
- (NSTextField *)aquaNotificationLabel:(NSString *)key text:(NSString *)text {
    NSTextField *field=[self labelWithFrame:NSZeroRect font:[NSFont systemFontOfSize:12] surface:TGThemeSurfaceCard detail:NO];
    [field setStringValue:text];[self.aquaViews setObject:field forKey:key];[TGUtilityWindowContentView([self window]) addSubview:field];return field;
}
- (void)buildAquaViews {
    TGAquaUtilityWindowView *root=[[[TGAquaUtilityWindowView alloc] initWithFrame:[TGUtilityWindowContentView([self window]) bounds]] autorelease];
    [root setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];[[self window] setContentView:root];[[self window] setDelegate:(id)self];
    self.aquaViews=[NSMutableDictionary dictionary];self.filteredExceptions=[NSArray array];
    NSTextField *heading=[self aquaNotificationLabel:@"heading" text:TGLoc(@"notifications.exceptions.title")];[heading setFont:[NSFont boldSystemFontOfSize:14]];
    self.refreshButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];TGAquaUtilityButtonCell *refresh=[[[TGAquaUtilityButtonCell alloc] initTextCell:@""] autorelease];[refresh setIconOnly:YES];[refresh setIconAssetName:@"refresh"];[self.refreshButton setCell:refresh];[self.refreshButton setButtonType:NSMomentaryPushInButton];
    [self.refreshButton setImage:TGTemplateIconAssetImage(@"refresh",NSMakeSize(18,18),TGClassicHeaderTextColor(1),1)];[self.refreshButton setTitle:@""];[self.refreshButton setToolTip:TGLoc(@"refresh")];[self.refreshButton setTarget:self];[self.refreshButton setAction:@selector(refreshPressed:)];[root addSubview:self.refreshButton];
    self.aquaSearchField=[[[NSSearchField alloc] initWithFrame:NSZeroRect] autorelease];[[self.aquaSearchField cell] setPlaceholderString:TGLoc(@"folders.searchChats")];[self.aquaSearchField setDelegate:(id)self];[self.aquaSearchField setTarget:self];[self.aquaSearchField setAction:@selector(aquaSearchChanged:)];[root addSubview:self.aquaSearchField];
    self.tableView=[[[TGNotificationExceptionTableView alloc] initWithFrame:NSZeroRect] autorelease];[self.tableView setHeaderView:nil];[self.tableView setRowHeight:44];[self.tableView setIntercellSpacing:NSZeroSize];
    [self.tableView setFocusRingType:NSFocusRingTypeNone];[self.tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];[self.tableView setGridStyleMask:NSTableViewGridNone];
    [self.tableView setBackgroundColor:TGClassicTablePaperColor()];[self.tableView setDataSource:self];[self.tableView setDelegate:self];[self.tableView setAllowsEmptySelection:YES];[self.tableView setAllowsMultipleSelection:NO];
    [self.tableView setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle];
    NSTableColumn *column=[[[NSTableColumn alloc] initWithIdentifier:@"title"] autorelease];[column setDataCell:[[[TGNotificationExceptionCell alloc] initTextCell:@""] autorelease]];[self.tableView addTableColumn:column];
    NSScrollView *scroll=[[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];[scroll setBorderType:NSNoBorder];[scroll setHasVerticalScroller:YES];[scroll setAutohidesScrollers:YES];[scroll setDrawsBackground:YES];[scroll setBackgroundColor:TGClassicTablePaperColor()];[scroll setDocumentView:self.tableView];[root addSubview:scroll];[self.aquaViews setObject:scroll forKey:@"scroll"];
    NSBox *divider=[[[NSBox alloc] initWithFrame:NSZeroRect] autorelease];[divider setBoxType:NSBoxSeparator];[root addSubview:divider];[self.aquaViews setObject:divider forKey:@"divider"];
    NSTextField *count=[self aquaNotificationLabel:@"listCount" text:@""];[count setFont:[NSFont systemFontOfSize:10]];[count setTextColor:TGClassicCardMutedInkColor()];
    NSTextField *listEmpty=[self aquaNotificationLabel:@"listEmpty" text:TGLoc(@"search.chats.empty")];[listEmpty setAlignment:NSCenterTextAlignment];[[listEmpty cell] setWraps:YES];[[listEmpty cell] setLineBreakMode:NSLineBreakByWordWrapping];
    NSTextField *emptyHeading=[self aquaNotificationLabel:@"emptyHeading" text:@""];[emptyHeading setAlignment:NSCenterTextAlignment];[emptyHeading setFont:[NSFont boldSystemFontOfSize:14]];[[emptyHeading cell] setWraps:YES];[[emptyHeading cell] setLineBreakMode:NSLineBreakByWordWrapping];
    NSTextField *emptyDetail=[self aquaNotificationLabel:@"emptyDetail" text:@""];[emptyDetail setAlignment:NSCenterTextAlignment];[emptyDetail setTextColor:TGClassicCardMutedInkColor()];[[emptyDetail cell] setWraps:YES];[[emptyDetail cell] setLineBreakMode:NSLineBreakByWordWrapping];
    self.selectionField=[self aquaNotificationLabel:@"selection" text:TGLoc(@"notifications.exceptions.select")];[self.selectionField setFont:[NSFont boldSystemFontOfSize:14]];
    [[self.selectionField cell] setWraps:YES];[[self.selectionField cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [self aquaNotificationLabel:@"muteLabel" text:TGLoc(@"notifications.exceptions.mute")];
    self.mutePopUpButton=[[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    for(NSString *key in [NSArray arrayWithObjects:@"notifications.exceptions.on",@"notifications.mute.hour",@"notifications.mute.eightHours",@"notifications.mute.day",@"notifications.mute.forever",nil])[self.mutePopUpButton addItemWithTitle:TGLoc(key)];[root addSubview:self.mutePopUpButton];
    self.previewButton=[[[TGThemeSwitchButton alloc] initWithFrame:NSZeroRect] autorelease];[self.previewButton setButtonType:NSSwitchButton];[self.previewButton setTitle:TGLoc(@"notifications.exceptions.preview")];[self.previewButton setFont:[NSFont systemFontOfSize:12]];[[self.previewButton cell] setWraps:YES];[[self.previewButton cell] setLineBreakMode:NSLineBreakByWordWrapping];[root addSubview:self.previewButton];
    self.statusField=[self labelWithFrame:NSZeroRect font:[NSFont systemFontOfSize:11] surface:TGThemeSurfaceWindow detail:YES];[self.statusField setStringValue:TGLoc(@"notifications.exceptions.loading")];[root addSubview:self.statusField];
    self.spinner=[[[NSProgressIndicator alloc] initWithFrame:NSZeroRect] autorelease];[self.spinner setStyle:NSProgressIndicatorSpinningStyle];[self.spinner setControlSize:NSSmallControlSize];[self.spinner setDisplayedWhenStopped:NO];[root addSubview:self.spinner];
    self.resetButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[self.resetButton setCell:[[[TGSecondaryTextButtonCell alloc] initTextCell:TGLoc(@"notifications.exceptions.reset")] autorelease]];[self.resetButton setTitle:TGLoc(@"notifications.exceptions.reset")];[self.resetButton setTarget:self];[self.resetButton setAction:@selector(resetPressed:)];[root addSubview:self.resetButton];
    self.applyButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[self.applyButton setCell:[[[TGPrimaryTextButtonCell alloc] initTextCell:TGLoc(@"apply")] autorelease]];[self.applyButton setTitle:TGLoc(@"apply")];[self.applyButton setTarget:self];[self.applyButton setAction:@selector(applyPressed:)];[root addSubview:self.applyButton];
    [self layoutAquaViews];[self updateEditorAvailability];
}
- (void)layoutAquaViews {
    if(!self.aquaViews)return; NSSize size=[TGUtilityWindowContentView([self window]) bounds].size;CGFloat w=size.width,h=size.height,left=MIN(290,floor(w*0.40)),x=left+20,editor=MAX(0,w-x-20),footer=w<540 ? 86 : 54;
    [(TGAquaUtilityWindowView *)TGUtilityWindowContentView([self window]) setFooterHeight:footer];
    [[self.aquaViews objectForKey:@"heading"] setFrame:NSMakeRect(20,h-34,w-90,20)];[self.refreshButton setFrame:NSMakeRect(w-50,h-41,30,30)];
    [self.aquaSearchField setFrame:NSMakeRect(12,h-94,left-24,26)];
    NSScrollView *scroll=[self.aquaViews objectForKey:@"scroll"];[scroll setFrame:NSMakeRect(4,footer+8,left-8,MAX(0,h-footer-134))];[scroll tile];[[[self.tableView tableColumns] objectAtIndex:0] setWidth:NSWidth([[scroll contentView] bounds])];
    [self.tableView setFrameSize:NSMakeSize(NSWidth([[scroll contentView] bounds]),MAX(NSHeight([[scroll contentView] bounds]),[self.tableView numberOfRows]*44.0))];
    [[self.aquaViews objectForKey:@"divider"] setFrame:NSMakeRect(left,footer,1,MAX(0,h-footer-52))];
    [[self.aquaViews objectForKey:@"listCount"] setFrame:NSMakeRect(16,h-122,left-32,16)];
    [[self.aquaViews objectForKey:@"listEmpty"] setFrame:NSMakeRect(20,54+(h-180)/2,left-40,40)];
    [self.selectionField setFrame:NSMakeRect(x,h-116,editor,48)];
    [[self.aquaViews objectForKey:@"muteLabel"] setFrame:NSMakeRect(x,h-154,editor,20)];[self.mutePopUpButton setFrame:NSMakeRect(x,h-189,editor,28)];
    CGFloat previewHeight=MAX(24,ceil([[self.previewButton title] boundingRectWithSize:NSMakeSize(MAX(1,editor-20),100) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:[self.previewButton font] forKey:NSFontAttributeName]].size.height)+4);
    [self.previewButton setFrame:NSMakeRect(x,h-207-previewHeight,editor,previewHeight)];
    [self.statusField setFrame:NSMakeRect(20,footer>54 ? 56 : 19,MAX(0,w-(footer>54 ? 66 : 332)),18)];[self.spinner setFrame:NSMakeRect(footer>54 ? w-38 : w-302,footer>54 ? 57 : 20,16,16)];
    [self.resetButton setFrame:NSMakeRect(w-278,12,122,30)];[self.applyButton setFrame:NSMakeRect(w-144,12,124,30)];
    [self updateAquaNotificationContext];
}
- (void)windowDidResize:(NSNotification *)notification {if([notification object]==[self window])[self layoutAquaViews];}
- (void)windowDidChangeScreen:(NSNotification *)notification {if(self.aquaViews && [notification object]==[self window]){TGFitUtilityWindowToVisibleScreen([self window]);[self layoutAquaViews];}}
- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)frame {return self.aquaViews && [window screen] ? TGUtilityWindowFrameFittingVisibleFrame(frame,[[window screen] visibleFrame]) : frame;}

- (void)updateAquaNotificationContext {
    if(!self.aquaViews)return;
    BOOL selected=[self selectedSummary]!=nil;
    for(NSView *view in [NSArray arrayWithObjects:self.selectionField,[self.aquaViews objectForKey:@"muteLabel"],self.mutePopUpButton,self.previewButton,self.resetButton,self.applyButton,nil]) [view setHidden:!selected];
    NSString *query=[[self.aquaSearchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL noResults=[query length]>0 && [self.filteredExceptions count]==0;
    BOOL empty=[self.exceptions count]==0;
    NSTextField *heading=[self.aquaViews objectForKey:@"emptyHeading"],*detail=[self.aquaViews objectForKey:@"emptyDetail"];
    [heading setHidden:selected];[detail setHidden:selected];
    [heading setStringValue:TGLoc(self.loading ? @"notifications.exceptions.loading" : (noResults ? @"search.chats.empty" : (empty ? @"notifications.exceptions.empty" : @"notifications.exceptions.select")))];
    [detail setStringValue:self.loading ? @"" : TGLoc(noResults ? @"notifications.exceptions.noResultsHelp" : (empty ? @"notifications.exceptions.emptyHelp" : @"notifications.exceptions.selectionHelp"))];
    /* No duplicate no-results panel in the source list: the context explains it once. */
    [[self.aquaViews objectForKey:@"listEmpty"] setHidden:YES];
    CGFloat w=NSWidth([TGUtilityWindowContentView([self window]) bounds]),h=NSHeight([TGUtilityWindowContentView([self window]) bounds]);
    CGFloat left=MIN(290,floor(w*0.40)),x=left+20,width=MAX(0,w-x-20),footer=w<540 ? 86 : 54;
    CGFloat headingHeight=MAX(24,ceil([[heading stringValue] boundingRectWithSize:NSMakeSize(MAX(1,width),200) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:[heading font] forKey:NSFontAttributeName]].size.height)+4);
    CGFloat detailHeight=MAX(20,ceil([[detail stringValue] boundingRectWithSize:NSMakeSize(MAX(1,width),200) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:[detail font] forKey:NSFontAttributeName]].size.height)+4);
    CGFloat base=footer+(h-footer-52-headingHeight-detailHeight-12)/2;
    [heading setFrame:NSMakeRect(x,base+detailHeight+12,width,headingHeight)];[detail setFrame:NSMakeRect(x,base,width,detailHeight)];
    if(!selected)[self.statusField setFrame:NSMakeRect(20,footer>54 ? 56 : 19,MAX(0,w-66),18)];
    NSString *count=[query length] ? [NSString stringWithFormat:TGLoc(@"notifications.exceptions.filteredCount"),(unsigned long)[self.filteredExceptions count],(unsigned long)[self.exceptions count]] : [NSString stringWithFormat:TGLoc(@"notifications.exceptions.count"),(unsigned long)[self.exceptions count]];
    [[self.aquaViews objectForKey:@"listCount"] setStringValue:count];[[self.aquaViews objectForKey:@"listCount"] setToolTip:count];
}
