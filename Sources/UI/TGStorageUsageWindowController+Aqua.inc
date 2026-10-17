// Presentation only: scope/type values, confirmation and cleanup stay shared.
- (NSTextField *)aquaStorageLabel:(NSString *)key bold:(BOOL)bold {
    NSTextField *field=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [field setEditable:NO];[field setSelectable:NO];[field setBezeled:NO];[field setDrawsBackground:NO];
    [field setFont:bold ? [NSFont boldSystemFontOfSize:13] : [NSFont systemFontOfSize:12]];
    [field setTextColor:[NSColor colorWithCalibratedWhite:0.18 alpha:1]];[field setStringValue:TGLoc(key)];
    return field;
}
- (void)configureAquaStorageViews {
    TGAquaUtilityWindowView *root=[[[TGAquaUtilityWindowView alloc] initWithFrame:[[[self window] contentView] bounds]] autorelease];
    root.headerHeight=58;root.footerHeight=100;[root setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    for(NSView *view in [NSArray arrayWithObjects:self.titleField,self.subtitleField,self.chartView,self.typePopUpButton,self.scopePopUpButton,self.hintField,self.refreshButton,self.clearButton,self.progressIndicator,nil]) {
        [view setAutoresizingMask:NSViewNotSizable];[root addSubview:view];
    }
    [self.titleField setFont:[NSFont boldSystemFontOfSize:17]];[self.titleField setAlignment:NSLeftTextAlignment];
    [self.subtitleField setFont:[NSFont boldSystemFontOfSize:18]];[self.subtitleField setAlignment:NSLeftTextAlignment];
    [[self.subtitleField cell] setLineBreakMode:NSLineBreakByWordWrapping];[[self.subtitleField cell] setWraps:YES];[[self.subtitleField cell] setUsesSingleLineMode:NO];
    [self.hintField setAlignment:NSLeftTextAlignment];[self.hintField setFont:[NSFont systemFontOfSize:11]];
    [[self.hintField cell] setWraps:YES];[[self.hintField cell] setUsesSingleLineMode:NO];
    [self.hintField setToolTip:[self.hintField stringValue]];
    [self.chartView setCenterText:@""];
    self.aquaRowsView=[[[NSView alloc] initWithFrame:NSZeroRect] autorelease];[root addSubview:self.aquaRowsView];
    for(NSView *row in self.categoryRows) [self.aquaRowsView addSubview:row];
    NSMutableArray *fields=[NSMutableArray array];
    NSArray *keys=[NSArray arrayWithObjects:@"aqua.storage.categories",@"aqua.storage.cleanup",@"storage.type",@"storage.scope",nil];
    for(NSUInteger i=0;i<[keys count];i++){NSTextField *field=[self aquaStorageLabel:[keys objectAtIndex:i] bold:i<2];[fields addObject:field];[root addSubview:field];}
    self.aquaSectionFields=fields;
    // Reparenting retains every shared control before replacing the old cards.
    [[self window] setContentView:root];[[self window] setMinSize:NSMakeSize(600,680)];[[self window] setMaxSize:NSMakeSize(1100,960)];
    [[self window] setContentSize:NSMakeSize(680,690)];[self layoutAquaStorageViews];
}
- (void)layoutAquaStorageViews {
    if(!self.aquaRowsView)return;
    NSRect bounds=[[[self window] contentView] bounds];CGFloat w=NSWidth(bounds),h=NSHeight(bounds),top=h-76;
    [self.titleField setFrame:NSMakeRect(24,h-41,w-96,24)];[self.refreshButton setFrame:NSMakeRect(w-54,h-44,30,30)];
    [self.chartView setFrame:NSMakeRect(24,top-138,132,132)];
    [self.subtitleField setFrame:NSMakeRect(184,top-88,MAX(0,w-208),54)];
    [self.progressIndicator setFrame:NSMakeRect(78,top-84,24,24)];
    [[self.aquaSectionFields objectAtIndex:0] setFrame:NSMakeRect(24,top-176,w-48,22)];
    [self.aquaRowsView setFrame:NSMakeRect(24,top-328,w-48,144)];
    NSUInteger count=[self.categoryRows count];
    for(NSUInteger i=0;i<count;i++)[[self.categoryRows objectAtIndex:i] setFrame:NSMakeRect(0,144-(i+1)*36,w-48,36)];
    [[self.aquaSectionFields objectAtIndex:1] setFrame:NSMakeRect(24,208,w-48,22)];
    [[self.aquaSectionFields objectAtIndex:2] setFrame:NSMakeRect(24,172,104,24)];[[self.aquaSectionFields objectAtIndex:3] setFrame:NSMakeRect(24,134,104,24)];
    [self.typePopUpButton setFrame:NSMakeRect(138,170,MAX(0,w-162),30)];[self.scopePopUpButton setFrame:NSMakeRect(138,132,MAX(0,w-162),30)];
    [self.clearButton setFrame:NSMakeRect(w-240,34,216,32)];[self.hintField setFrame:NSMakeRect(24,16,MAX(0,w-288),68)];
}
- (void)windowDidResize:(NSNotification *)notification {if([notification object]==[self window])[self layoutAquaStorageViews];}
