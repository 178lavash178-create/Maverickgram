// Presentation only: scope/type values, confirmation and cleanup stay shared.
- (NSTextField *)aquaStorageLabel:(NSString *)key bold:(BOOL)bold {
    NSTextField *field=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [field setEditable:NO];[field setSelectable:NO];[field setBezeled:NO];[field setDrawsBackground:NO];
    [field setFont:bold ? [NSFont boldSystemFontOfSize:13] : [NSFont systemFontOfSize:12]];
    [field setTextColor:[NSColor colorWithCalibratedWhite:0.18 alpha:1]];[field setStringValue:TGLoc(key)];
    return field;
}
- (void)applyAquaStorageCell:(NSButtonCell *)cell toButton:(NSButton *)button {
    [cell setButtonType:NSMomentaryPushInButton];[cell setTarget:[button target]];
    [cell setAction:[button action]];[cell setEnabled:[button isEnabled]];
    [button setCell:cell];[button setBordered:NO];
}
- (void)configureAquaStorageViews {
    TGAquaUtilityWindowView *root=[[[TGAquaUtilityWindowView alloc] initWithFrame:[TGUtilityWindowContentView([self window]) bounds]] autorelease];
    root.headerHeight=52;root.footerHeight=54;[root setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    for(NSView *view in [NSArray arrayWithObjects:self.titleField,self.subtitleField,self.chartView,self.typePopUpButton,self.scopePopUpButton,self.hintField,self.refreshButton,self.clearButton,self.progressIndicator,nil]) {
        [view setAutoresizingMask:NSViewNotSizable];[root addSubview:view];
    }
    [self applyAquaStorageCell:[[[TGPrimaryTextButtonCell alloc] initTextCell:[self.clearButton title]] autorelease] toButton:self.clearButton];
    [self applyAquaStorageCell:[[[TGHeaderIconButtonCell alloc] initTextCell:@"refresh"] autorelease] toButton:self.refreshButton];
    [self.refreshButton setImage:TGTemplateIconAssetImage(@"refresh",NSMakeSize(18,18),TGClassicHeaderTextColor(1),1)];
    [self.refreshButton setTitle:@""];
    [self.titleField setFont:[NSFont boldSystemFontOfSize:14]];[self.titleField setAlignment:NSLeftTextAlignment];
    [self.subtitleField setFont:[NSFont boldSystemFontOfSize:15]];[self.subtitleField setAlignment:NSLeftTextAlignment];
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
    [[self window] setContentView:root];[[self window] setMinSize:NSMakeSize(430,460)];[[self window] setMaxSize:NSMakeSize(1100,960)];
    [[self window] setContentSize:NSMakeSize(680,480)];TGFitUtilityWindowToVisibleScreen([self window]);
    [self layoutAquaStorageViews];
}
- (void)layoutAquaStorageViews {
    if(!self.aquaRowsView)return;
    NSRect bounds=[TGUtilityWindowContentView([self window]) bounds];CGFloat w=NSWidth(bounds),h=NSHeight(bounds);
    [self.titleField setFrame:NSMakeRect(20,h-34,w-90,20)];
    [self.refreshButton setFrame:NSMakeRect(w-50,h-41,30,30)];
    BOOL narrow=w<600;
    [self.chartView setHidden:narrow];
    [self.chartView setFrame:NSMakeRect(20,h-216,104,104)];
    [self.subtitleField setFrame:NSMakeRect(20,h-107,124,42)];
    [self.progressIndicator setFrame:NSMakeRect(60,h-176,24,24)];
    [[self.aquaSectionFields objectAtIndex:0] setFrame:NSMakeRect(narrow?180:160,h-88,w-(narrow?200:180),20)];
    CGFloat rowsX=narrow?4:144,rowsWidth=w-rowsX-20;
    [self.aquaRowsView setFrame:NSMakeRect(rowsX,h-222,rowsWidth,128)];
    NSUInteger count=[self.categoryRows count];
    for(NSUInteger i=0;i<count;i++)[[self.categoryRows objectAtIndex:i] setFrame:NSMakeRect(0,128-(i+1)*32,rowsWidth,32)];
    [[self.aquaSectionFields objectAtIndex:1] setFrame:NSMakeRect(20,h-256,w-40,20)];
    [[self.aquaSectionFields objectAtIndex:2] setFrame:NSMakeRect(20,h-288,108,22)];
    [[self.aquaSectionFields objectAtIndex:3] setFrame:NSMakeRect(20,h-324,108,22)];
    CGFloat fieldWidth=MIN(400,w-164);
    [self.typePopUpButton setFrame:NSMakeRect(144,h-292,fieldWidth,28)];
    [self.scopePopUpButton setFrame:NSMakeRect(144,h-328,fieldWidth,28)];
    [self.hintField setFrame:NSMakeRect(20,68,w-40,34)];
    [self.clearButton setFrame:NSMakeRect(w-244,12,224,30)];
}
- (void)windowDidResize:(NSNotification *)notification {if([notification object]==[self window])[self layoutAquaStorageViews];}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)proposed {
    NSScreen *screen=[window screen] ? [window screen] : [NSScreen mainScreen];
    return screen ? TGUtilityWindowFrameFittingVisibleFrame(proposed,[screen visibleFrame]) : proposed;
}
- (void)windowDidChangeScreen:(NSNotification *)notification {
    if([notification object]==[self window]) {
        TGFitUtilityWindowToVisibleScreen([self window]);[self layoutAquaStorageViews];
    }
}
