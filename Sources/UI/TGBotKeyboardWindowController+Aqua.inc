// The keyboard is a plain list, with its sole action in the standard footer.
- (void)buildAquaViews {
    NSRect bounds = [[[self window] contentView] bounds]; CGFloat width=NSWidth(bounds), height=NSHeight(bounds);
    TGAquaUtilityWindowView *root = [[[TGAquaUtilityWindowView alloc] initWithFrame:bounds] autorelease];
    [root setHeaderHeight:52.0]; [root setFooterHeight:54.0]; [root setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [[self window] setContentView:root];
    NSTextField *title = [self labelWithFrame:NSMakeRect(24,height-34,width-48,20) font:[NSFont boldSystemFontOfSize:14.0] surface:TGThemeSurfaceWindow detail:NO];
    [title setStringValue:TGLoc(@"bot.keyboard.title")]; [title setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)]; [root addSubview:title];
    NSTextField *hint = [self labelWithFrame:NSMakeRect(24,height-102,width-48,34) font:[NSFont systemFontOfSize:11.0] surface:TGThemeSurfaceCard detail:YES];
    [hint setStringValue:TGLoc(@"bot.keyboard.hint")]; [[hint cell] setUsesSingleLineMode:NO]; [[hint cell] setWraps:YES];
    [[hint cell] setScrollable:NO]; [[hint cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [hint setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)]; [root addSubview:hint];
    NSScrollView *scroll = [[[NSScrollView alloc] initWithFrame:NSMakeRect(24,108,width-48,height-218)] autorelease];
    [scroll setBorderType:NSBezelBorder]; [scroll setHasVerticalScroller:YES]; [scroll setAutohidesScrollers:YES];
    [scroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    self.tableView = [[[NSTableView alloc] initWithFrame:[[scroll contentView] bounds]] autorelease];
    NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"button"] autorelease];
    [column setWidth:[scroll contentSize].width]; [self.tableView addTableColumn:column]; [self.tableView setHeaderView:nil];
    [self.tableView setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle]; [self.tableView setRowHeight:34.0];
    [self.tableView setBackgroundColor:[NSColor whiteColor]]; [self.tableView setDataSource:self]; [self.tableView setDelegate:self];
    [self.tableView setTarget:self]; [self.tableView setDoubleAction:@selector(activatePressed:)]; [scroll setDocumentView:self.tableView]; [root addSubview:scroll];
    self.activateButton = [[[NSButton alloc] initWithFrame:NSMakeRect(width-190,13,166,28)] autorelease];
    TGAquaTextButtonCell *cell = [[[TGAquaTextButtonCell alloc] initTextCell:TGLoc(@"bot.keyboard.activate")] autorelease];
    [cell setAccented:YES]; [self.activateButton setCell:cell]; [self.activateButton setTitle:TGLoc(@"bot.keyboard.activate")];
    [self.activateButton setButtonType:NSMomentaryPushInButton]; [self.activateButton setTarget:self]; [self.activateButton setAction:@selector(activatePressed:)];
    [self.activateButton setAutoresizingMask:(NSViewMinXMargin | NSViewMaxYMargin)]; [root addSubview:self.activateButton];
    self.statusField = [self labelWithFrame:NSMakeRect(24,64,width-72,34) font:[NSFont systemFontOfSize:11.0] surface:TGThemeSurfaceCard detail:YES];
    [[self.statusField cell] setUsesSingleLineMode:NO]; [[self.statusField cell] setWraps:YES]; [[self.statusField cell] setScrollable:NO];
    [[self.statusField cell] setLineBreakMode:NSLineBreakByWordWrapping]; [self.statusField setSelectable:YES];
    [self.statusField setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)]; [root addSubview:self.statusField];
    self.spinner = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(width-40,73,16,16)] autorelease];
    [self.spinner setStyle:NSProgressIndicatorSpinningStyle]; [self.spinner setDisplayedWhenStopped:NO];
    [self.spinner setAutoresizingMask:(NSViewMinXMargin | NSViewMaxYMargin)]; [root addSubview:self.spinner]; [self updateControls];
}
