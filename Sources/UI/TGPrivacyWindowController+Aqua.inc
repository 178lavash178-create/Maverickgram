// Four native sections share the existing controls and data/mutation handlers.
- (NSTextField *)aquaPrivacyLabel:(NSString *)text size:(CGFloat)size bold:(BOOL)bold {
    NSTextField *field=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [field setEditable:NO]; [field setSelectable:NO]; [field setBezeled:NO]; [field setDrawsBackground:NO];
    [field setFont:bold ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size]];
    [field setTextColor:[NSColor colorWithCalibratedWhite:0.18 alpha:1]]; [field setStringValue:text];
    [[field cell] setWraps:YES]; [[field cell] setUsesSingleLineMode:NO]; [[field cell] setLineBreakMode:NSLineBreakByWordWrapping];
    return field;
}
- (void)configureAquaPrivacyViews {
    TGAquaUtilityWindowView *root=[[[TGAquaUtilityWindowView alloc] initWithFrame:[[[self window] contentView] bounds]] autorelease];
    root.headerHeight=110;root.footerHeight=54;[root setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    self.aquaTitleField=[self aquaPrivacyLabel:TGLoc(@"privacy.title") size:17 bold:YES];[root addSubview:self.aquaTitleField];
    self.aquaSectionSelector=[[[NSSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
    [self.aquaSectionSelector setSegmentCount:4];[[self.aquaSectionSelector cell] setTrackingMode:NSSegmentSwitchTrackingSelectOne];
    NSArray *tabs=[NSArray arrayWithObjects:@"aqua.privacy.visibility",@"privacy.retention",@"aqua.privacy.permissions",@"aqua.privacy.blocked",nil];
    NSMutableArray *panes=[NSMutableArray array];NSMutableArray *labels=[NSMutableArray array];
    NSArray *headings=[NSArray arrayWithObjects:@"privacy.rules",@"privacy.retention",@"privacy.permissions.title",@"privacy.blocked",@"privacy.accountTTL",@"privacy.defaultAutoDelete",nil];
    for(NSUInteger i=0;i<4;i++) {
        [self.aquaSectionSelector setLabel:TGLoc([tabs objectAtIndex:i]) forSegment:i];
        NSView *pane=[[[NSView alloc] initWithFrame:NSZeroRect] autorelease];[panes addObject:pane];[root addSubview:pane];
    }
    for(NSUInteger i=0;i<[headings count];i++) {
        NSTextField *label=[self aquaPrivacyLabel:TGLoc([headings objectAtIndex:i]) size:i<4?14:12 bold:i<4];
        [labels addObject:label];[[panes objectAtIndex:i<4?i:1] addSubview:label];
    }
    self.aquaSectionViews=panes;self.aquaSectionLabels=labels;
    [self.aquaSectionSelector setSelectedSegment:0];[self.aquaSectionSelector setTarget:self];[self.aquaSectionSelector setAction:@selector(aquaPrivacySectionChanged:)];[root addSubview:self.aquaSectionSelector];
    NSArray *groups=[NSArray arrayWithObjects:
        [NSArray arrayWithObjects:self.settingPopUpButton,self.rulePopUpButton,self.ruleHintField,self.applyRuleButton,nil],
        [NSArray arrayWithObjects:self.accountTTLPopUpButton,self.autoDeletePopUpButton,self.applyRetentionButton,nil],
        [NSArray arrayWithObjects:self.microphonePermissionButton,self.cameraPermissionButton,self.locationPermissionButton,nil],
        [NSArray arrayWithObjects:self.contactPopUpButton,self.blockButton,self.unblockButton,nil],nil];
    for(NSUInteger i=0;i<[groups count];i++)for(NSView *view in [groups objectAtIndex:i]) {[view setAutoresizingMask:NSViewNotSizable];[[panes objectAtIndex:i] addSubview:view];}
    self.aquaBlockedScrollView=[[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];
    [self.aquaBlockedScrollView setBorderType:NSBezelBorder];[self.aquaBlockedScrollView setHasVerticalScroller:YES];[self.aquaBlockedScrollView setAutohidesScrollers:YES];
    [self.aquaBlockedScrollView setDrawsBackground:YES];[self.aquaBlockedScrollView setBackgroundColor:[NSColor whiteColor]];
    [self.aquaBlockedScrollView setDocumentView:self.blockedTableView];[[panes objectAtIndex:3] addSubview:self.aquaBlockedScrollView];
    [self.blockedTableView setBackgroundColor:[NSColor whiteColor]];
    for(NSView *view in [NSArray arrayWithObjects:self.refreshButton,self.statusField,self.spinner,nil]) {[view setAutoresizingMask:NSViewNotSizable];[root addSubview:view];}
    // All controls have been reparented before releasing the Classic root.
    [[self window] setContentView:root];[[self window] setDelegate:self];
    [[self window] setMinSize:NSMakeSize(640,500)];[[self window] setMaxSize:NSMakeSize(1100,900)];
    [[self window] setContentSize:NSMakeSize(680,560)];
    [self layoutAquaPrivacyViews];
}
- (void)aquaPrivacySectionChanged:(id)sender {(void)sender;[self layoutAquaPrivacyViews];}
- (void)layoutAquaPrivacyViews {
    if(!self.aquaSectionSelector)return;
    NSRect bounds=[[[self window] contentView] bounds];CGFloat w=NSWidth(bounds),h=NSHeight(bounds),pw=MAX(0,w-48),ph=MAX(0,h-184);
    [self.aquaTitleField setFrame:NSMakeRect(24,h-41,MAX(0,w-170),24)];[self.refreshButton setFrame:NSMakeRect(w-116,h-45,92,30)];
    [self.aquaSectionSelector setFrame:NSMakeRect(24,h-95,w-48,30)];for(NSUInteger i=0;i<4;i++)[self.aquaSectionSelector setWidth:(w-52)/4 forSegment:i];
    NSInteger selected=[self.aquaSectionSelector selectedSegment];
    for(NSUInteger i=0;i<4;i++){NSView *pane=[self.aquaSectionViews objectAtIndex:i];[pane setFrame:NSMakeRect(24,68,pw,ph)];[pane setHidden:(NSInteger)i!=selected];[[self.aquaSectionLabels objectAtIndex:i] setFrame:NSMakeRect(0,ph-54,pw,46)];}
    [self.settingPopUpButton setFrame:NSMakeRect(0,ph-104,pw,30)];
    [self.rulePopUpButton setFrame:NSMakeRect(0,ph-150,MAX(160,pw-182),30)];
    [self.ruleHintField setFrame:NSMakeRect(2,ph-222,pw-4,60)];
    [self.applyRuleButton setFrame:NSMakeRect(pw-156,16,156,30)];
    [[self.aquaSectionLabels objectAtIndex:4] setFrame:NSMakeRect(0,ph-120,MAX(0,pw-214),44)];
    [[self.aquaSectionLabels objectAtIndex:5] setFrame:NSMakeRect(0,ph-188,MAX(0,pw-214),44)];
    [self.accountTTLPopUpButton setFrame:NSMakeRect(pw-194,ph-112,194,30)];[self.autoDeletePopUpButton setFrame:NSMakeRect(pw-194,ph-180,194,30)];
    [self.applyRetentionButton setFrame:NSMakeRect(pw-156,16,156,30)];
    NSArray *permissions=[NSArray arrayWithObjects:self.microphonePermissionButton,self.cameraPermissionButton,self.locationPermissionButton,nil];
    for(NSUInteger i=0;i<3;i++)[[permissions objectAtIndex:i] setFrame:NSMakeRect(0,ph-104-i*48,pw,30)];
    [self.aquaBlockedScrollView setFrame:NSMakeRect(0,62,pw,MAX(80,ph-126))];[self.aquaBlockedScrollView tile];
    NSSize viewport=[[self.aquaBlockedScrollView contentView] bounds].size;
    [[[self.blockedTableView tableColumns] lastObject] setWidth:viewport.width];
    CGFloat rowsHeight=[self.blockedTableView numberOfRows]*([self.blockedTableView rowHeight]+[self.blockedTableView intercellSpacing].height);
    [self.blockedTableView setFrameSize:NSMakeSize(viewport.width,MAX(viewport.height,rowsHeight))];
    [self.contactPopUpButton setFrame:NSMakeRect(0,16,MAX(100,pw-304),30)];[self.blockButton setFrame:NSMakeRect(pw-294,16,132,30)];[self.unblockButton setFrame:NSMakeRect(pw-152,16,152,30)];
    [self.statusField setFrame:NSMakeRect(24,13,MAX(0,w-76),30)];[[self.statusField cell] setWraps:YES];[[self.statusField cell] setUsesSingleLineMode:NO];[[self.statusField cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [self.spinner setFrame:NSMakeRect(w-40,21,16,16)];
}
- (void)windowDidResize:(NSNotification *)notification {if([notification object]==[self window])[self layoutAquaPrivacyViews];}
