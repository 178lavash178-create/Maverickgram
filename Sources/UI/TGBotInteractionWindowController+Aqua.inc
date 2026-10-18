// A single geometry pass owns both scroll hosts. Never let two independent
// height-sizable masks allocate the same extra space during window resizing.
- (void)buildAquaViews {
    TGAquaUtilityWindowView *root = [[[TGAquaUtilityWindowView alloc] initWithFrame:[[[self window] contentView] bounds]] autorelease];
    [root setHeaderHeight:52.0]; [root setFooterHeight:54.0];
    [root setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [[self window] setContentView:root];
    self.aquaViews = [NSMutableDictionary dictionary];
    self.titleField = [self labelWithFrame:NSZeroRect font:[NSFont boldSystemFontOfSize:14.0] surface:TGThemeSurfaceWindow detail:NO];
    [self.titleField setStringValue:TGLoc(@"bot.window.title")]; [root addSubview:self.titleField];
    self.descriptionField = [self labelWithFrame:NSZeroRect font:[NSFont systemFontOfSize:11.0] surface:TGThemeSurfaceCard detail:YES];
    [[self.descriptionField cell] setUsesSingleLineMode:NO]; [[self.descriptionField cell] setWraps:YES];
    [[self.descriptionField cell] setScrollable:NO]; [[self.descriptionField cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [root addSubview:self.descriptionField];
    for (NSString *key in [NSArray arrayWithObjects:@"bot.commands.title", @"bot.inline.title", nil]) {
        NSTextField *label = [self labelWithFrame:NSZeroRect font:[NSFont boldSystemFontOfSize:12.0] surface:TGThemeSurfaceCard detail:NO];
        [label setStringValue:TGLoc(key)]; [root addSubview:label]; [self.aquaViews setObject:label forKey:key];
    }
    self.commandTableView = [self tableWithFrame:NSMakeRect(24,300,672,140) identifier:@"command" root:root];
    self.resultTableView = [self tableWithFrame:NSMakeRect(24,70,672,140) identifier:@"result" root:root];
    for (NSTableView *table in [NSArray arrayWithObjects:self.commandTableView,self.resultTableView,nil]) {
        [[table enclosingScrollView] setAutoresizingMask:NSViewNotSizable];
        [[table enclosingScrollView] setBorderType:NSBezelBorder];
        [[table enclosingScrollView] setAutohidesScrollers:YES];
        [table setBackgroundColor:[NSColor whiteColor]];
        [table setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle];
    }
    self.commandButton = [self buttonWithFrame:NSZeroRect titleKey:@"bot.command.send" action:@selector(sendCommandPressed:) primary:NO];
    self.resultButton = [self buttonWithFrame:NSZeroRect titleKey:@"bot.inline.send" action:@selector(sendResultPressed:) primary:YES];
    self.searchButton = [self buttonWithFrame:NSZeroRect titleKey:@"menu.search" action:@selector(searchPressed:) primary:NO];
    for (NSButton *button in [NSArray arrayWithObjects:self.commandButton,self.resultButton,self.searchButton,nil]) {
        SEL action = [button action];
        TGAquaTextButtonCell *cell = [[[TGAquaTextButtonCell alloc] initTextCell:[button title]] autorelease];
        [cell setAccented:(button == self.resultButton)]; [button setCell:cell];
        [button setTarget:self]; [button setAction:action];
        [button setButtonType:NSMomentaryPushInButton]; [button setFont:[NSFont systemFontOfSize:13.0]]; [root addSubview:button];
    }
    self.targetPopUpButton = [[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    [root addSubview:self.targetPopUpButton];
    self.queryField = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [[self.queryField cell] setPlaceholderString:TGLoc(@"bot.inline.placeholder")];
    [self.queryField setTarget:self]; [self.queryField setAction:@selector(searchPressed:)]; [root addSubview:self.queryField];
    self.statusField = [self labelWithFrame:NSZeroRect font:[NSFont systemFontOfSize:10.0] surface:TGThemeSurfaceWindow detail:YES];
    [[self.statusField cell] setUsesSingleLineMode:NO]; [[self.statusField cell] setWraps:YES];
    [[self.statusField cell] setScrollable:NO]; [[self.statusField cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [self.statusField setSelectable:YES]; [root addSubview:self.statusField];
    self.spinner = [[[NSProgressIndicator alloc] initWithFrame:NSZeroRect] autorelease];
    [self.spinner setStyle:NSProgressIndicatorSpinningStyle]; [self.spinner setDisplayedWhenStopped:NO]; [root addSubview:self.spinner];
    [[self window] setDelegate:(id)self];
    [self layoutAquaViews]; [self updateControls];
}
- (void)layoutAquaViews {
    if (!self.aquaViews) return;
    // The screen-fit guard can install a scroll viewport around this form.
    // Its smaller bounds must never reflow the natural-sized document.
    NSRect bounds = [TGUtilityWindowContentView([self window]) bounds]; CGFloat width=NSWidth(bounds), height=NSHeight(bounds), inner=width-48.0;
    CGFloat resultHeight=floor((height-330.0)*0.48), queryY=70.0+resultHeight+8.0, inlineY=queryY+38.0;
    CGFloat commandY=inlineY+38.0, commandBottom=commandY+36.0, commandTop=height-138.0;
    [self.titleField setFrame:NSMakeRect(24,height-34,inner,20)];
    [self.descriptionField setFrame:NSMakeRect(24,height-104,inner,36)];
    [[self.aquaViews objectForKey:@"bot.commands.title"] setFrame:NSMakeRect(24,height-132,inner,18)];
    [[self.commandTableView enclosingScrollView] setFrame:NSMakeRect(24,commandBottom,inner,MAX(40,commandTop-commandBottom))];
    CGFloat commandWidth=MAX(166.0,[[self.commandButton cell] cellSize].width+12.0);
    [self.commandButton setFrame:NSMakeRect(width-24-commandWidth,commandY,commandWidth,28)];
    [[self.aquaViews objectForKey:@"bot.inline.title"] setFrame:NSMakeRect(24,inlineY+4,inner-236,18)];
    [self.targetPopUpButton setFrame:NSMakeRect(width-244,inlineY,220,26)];
    CGFloat searchWidth=MAX(100.0,[[self.searchButton cell] cellSize].width+12.0);
    [self.queryField setFrame:NSMakeRect(24,queryY,inner-searchWidth-10,28)];
    [self.searchButton setFrame:NSMakeRect(width-24-searchWidth,queryY,searchWidth,28)];
    [[self.resultTableView enclosingScrollView] setFrame:NSMakeRect(24,70,inner,resultHeight)];
    CGFloat resultWidth=MAX(166.0,[[self.resultButton cell] cellSize].width+12.0);
    [self.resultButton setFrame:NSMakeRect(width-24-resultWidth,13,resultWidth,28)];
    [self.statusField setFrame:NSMakeRect(24,10,inner-resultWidth-40,34)];
    [self.spinner setFrame:NSMakeRect(width-24-resultWidth-28,19,16,16)];
    for (NSTableView *table in [NSArray arrayWithObjects:self.commandTableView,self.resultTableView,nil])
        [[[table tableColumns] objectAtIndex:0] setWidth:MAX(40,[[table enclosingScrollView] contentSize].width)];
}
- (void)windowDidResize:(NSNotification *)notification { (void)notification; [self layoutAquaViews]; }
