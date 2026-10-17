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
    TGAquaUtilityWindowView *root=[[[TGAquaUtilityWindowView alloc] initWithFrame:[TGUtilityWindowContentView([self window]) bounds]] autorelease];
    root.headerHeight=96;root.footerHeight=54;[root setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    self.aquaTitleField=[self aquaPrivacyLabel:TGLoc(@"privacy.title") size:14 bold:YES];[root addSubview:self.aquaTitleField];
    self.aquaSectionSelector=[[[NSSegmentedControl alloc] initWithFrame:NSZeroRect] autorelease];
    [self.aquaSectionSelector setFont:[NSFont systemFontOfSize:12]];
    self.aquaSectionPopUp=[[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    [self.aquaSectionPopUp setFont:[NSFont systemFontOfSize:12]];
    [self.aquaSectionPopUp setTarget:self];[self.aquaSectionPopUp setAction:@selector(aquaPrivacySectionChanged:)];
    [root addSubview:self.aquaSectionPopUp];
    [self.aquaSectionSelector setSegmentCount:4];[[self.aquaSectionSelector cell] setTrackingMode:NSSegmentSwitchTrackingSelectOne];
    NSArray *tabs=[NSArray arrayWithObjects:@"aqua.privacy.visibility",@"privacy.retention",@"aqua.privacy.permissions",@"aqua.privacy.blocked",nil];
    NSMutableArray *panes=[NSMutableArray array];NSMutableArray *labels=[NSMutableArray array];
    NSArray *headings=[NSArray arrayWithObjects:@"aqua.privacy.setting",@"aqua.privacy.audience",@"privacy.accountTTL",@"privacy.defaultAutoDelete",nil];
    for(NSUInteger i=0;i<4;i++) {
        [self.aquaSectionSelector setLabel:TGLoc([tabs objectAtIndex:i]) forSegment:i];
        [self.aquaSectionPopUp addItemWithTitle:TGLoc([tabs objectAtIndex:i])];
        NSView *pane=[[[NSView alloc] initWithFrame:NSZeroRect] autorelease];[panes addObject:pane];[root addSubview:pane];
    }
    for(NSUInteger i=0;i<[headings count];i++) {
        NSTextField *label=[self aquaPrivacyLabel:TGLoc([headings objectAtIndex:i]) size:12 bold:NO];
        [labels addObject:label];[[panes objectAtIndex:i<2?0:1] addSubview:label];
    }
    self.aquaSectionViews=panes;self.aquaSectionLabels=labels;
    [self.aquaSectionSelector setSelectedSegment:0];[self.aquaSectionSelector setTarget:self];[self.aquaSectionSelector setAction:@selector(aquaPrivacySectionChanged:)];[root addSubview:self.aquaSectionSelector];
    NSArray *groups=[NSArray arrayWithObjects:
        [NSArray arrayWithObjects:self.settingPopUpButton,self.rulePopUpButton,self.ruleHintField,nil],
        [NSArray arrayWithObjects:self.accountTTLPopUpButton,self.autoDeletePopUpButton,nil],
        [NSArray arrayWithObjects:self.microphonePermissionButton,self.cameraPermissionButton,self.locationPermissionButton,nil],
        [NSArray arrayWithObjects:self.contactPopUpButton,self.blockButton,self.unblockButton,nil],nil];
    for(NSUInteger i=0;i<[groups count];i++)for(NSView *view in [groups objectAtIndex:i]) {[view setAutoresizingMask:NSViewNotSizable];[[panes objectAtIndex:i] addSubview:view];}
    self.aquaBlockedScrollView=[[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];
    [self.aquaBlockedScrollView setBorderType:NSBezelBorder];[self.aquaBlockedScrollView setHasVerticalScroller:YES];[self.aquaBlockedScrollView setAutohidesScrollers:YES];
    [self.aquaBlockedScrollView setDrawsBackground:YES];[self.aquaBlockedScrollView setBackgroundColor:[NSColor whiteColor]];
    [self.aquaBlockedScrollView setDocumentView:self.blockedTableView];[[panes objectAtIndex:3] addSubview:self.aquaBlockedScrollView];
    [self.blockedTableView setBackgroundColor:[NSColor whiteColor]];
    for(NSView *view in [NSArray arrayWithObjects:self.refreshButton,self.statusField,self.spinner,self.applyRuleButton,self.applyRetentionButton,nil]) {[view setAutoresizingMask:NSViewNotSizable];[root addSubview:view];}
    for(NSButton *button in [NSArray arrayWithObjects:self.microphonePermissionButton,self.cameraPermissionButton,self.locationPermissionButton,nil])[button setFont:[NSFont systemFontOfSize:12]];
    // All controls have been reparented before releasing the Classic root.
    [[self window] setContentView:root];[[self window] setDelegate:self];
    [[self window] setMinSize:NSMakeSize(430,420)];[[self window] setMaxSize:NSMakeSize(1100,900)];
    [[self window] setContentSize:NSMakeSize(680,450)];
    TGFitUtilityWindowToVisibleScreen([self window]);
    [self layoutAquaPrivacyViews];
}
- (void)aquaPrivacySectionChanged:(id)sender {
    if(sender==self.aquaSectionPopUp)[self.aquaSectionSelector setSelectedSegment:[self.aquaSectionPopUp indexOfSelectedItem]];
    [self layoutAquaPrivacyViews];
}
- (void)layoutAquaPrivacySectionNavigation:(NSRect)frame {
    NSFont *font=[self.aquaSectionSelector font];
    NSDictionary *attributes=[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    CGFloat widths[4],measured=0;
    for(NSUInteger i=0;i<4;i++) {
        widths[i]=ceil([[self.aquaSectionSelector labelForSegment:i] sizeWithAttributes:attributes].width)+28;
        measured+=widths[i];[self.aquaSectionSelector setWidth:widths[i] forSegment:i];
    }
    // Native bezel metrics differ across supported AppKit versions.
    CGFloat nativeMinimum=[[self.aquaSectionSelector cell] cellSize].width;
    BOOL fits=MAX(measured,nativeMinimum)<=NSWidth(frame);
    [self.aquaSectionSelector setHidden:!fits];[self.aquaSectionPopUp setHidden:fits];
    [self.aquaSectionSelector setFrame:frame];[self.aquaSectionPopUp setFrame:frame];
    [self.aquaSectionPopUp selectItemAtIndex:MAX(0,[self.aquaSectionSelector selectedSegment])];
    if(fits) {
        CGFloat extra=MAX(0,NSWidth(frame)-MAX(measured,nativeMinimum))/4;
        for(NSUInteger i=0;i<4;i++)[self.aquaSectionSelector setWidth:widths[i]+extra forSegment:i];
    }
}
- (void)layoutAquaPrivacyViews {
    if(!self.aquaSectionSelector)return;
    NSRect bounds=[TGUtilityWindowContentView([self window]) bounds];
    CGFloat w=NSWidth(bounds),h=NSHeight(bounds),pw=MAX(0,w-40),ph=MAX(0,h-182);
    BOOL stacked=pw<560;
    CGFloat formWidth=MIN(560,pw),left=floor((pw-formWidth)/2);
    CGFloat fieldWidth=stacked?MIN(346,pw):formWidth-214;
    CGFloat fieldX=stacked?floor((pw-fieldWidth)/2):left+214;
    [self.aquaTitleField setFrame:NSMakeRect(20,h-34,MAX(0,w-150),20)];
    [self.refreshButton setFrame:NSMakeRect(w-112,h-41,92,30)];
    [self layoutAquaPrivacySectionNavigation:NSMakeRect(20,h-82,MAX(0,w-40),26)];
    NSInteger selected=[self.aquaSectionSelector selectedSegment];
    for(NSUInteger i=0;i<4;i++) {
        NSView *pane=[self.aquaSectionViews objectAtIndex:i];
        [pane setFrame:NSMakeRect(20,70,pw,ph)];[pane setHidden:(NSInteger)i!=selected];
    }
    // Stable form columns let short choices remain short; no repeated tab heading.
    NSArray *popups=[NSArray arrayWithObjects:self.settingPopUpButton,self.rulePopUpButton,self.accountTTLPopUpButton,self.autoDeletePopUpButton,nil];
    for(NSUInteger i=0;i<4;i++) {
        CGFloat y=ph-(stacked?60:54)-(i%2)*(stacked?72:48);
        NSTextField *label=[self.aquaSectionLabels objectAtIndex:i];
        NSDictionary *attributes=[NSDictionary dictionaryWithObject:[label font] forKey:NSFontAttributeName];
        CGFloat labelWidth=stacked?fieldWidth:198;
        CGFloat labelHeight=MAX(22,ceil([[label stringValue] boundingRectWithSize:NSMakeSize(labelWidth,100)
            options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes].size.height)+2);
        [label setFrame:NSMakeRect(stacked?fieldX:left,stacked?y+32:y+floor((28-labelHeight)/2),labelWidth,labelHeight)];
        [[popups objectAtIndex:i] setFrame:NSMakeRect(fieldX,y,fieldWidth,28)];
    }
    [self.ruleHintField setFont:[NSFont systemFontOfSize:11]];
    [self.ruleHintField setFrame:NSMakeRect(fieldX,ph-(stacked?192:166),fieldWidth,54)];
    NSArray *permissions=[NSArray arrayWithObjects:self.microphonePermissionButton,self.cameraPermissionButton,self.locationPermissionButton,nil];
    for(NSUInteger i=0;i<3;i++) {
        NSButton *button=[permissions objectAtIndex:i];
        [button setFrame:NSMakeRect(left,ph-54-i*44,formWidth,26)];
    }
    [self.aquaBlockedScrollView setFrame:NSMakeRect(0,stacked?98:56,pw,MAX(80,ph-(stacked?98:56)))];[self.aquaBlockedScrollView tile];
    NSSize viewport=[[self.aquaBlockedScrollView contentView] bounds].size;
    [[[self.blockedTableView tableColumns] lastObject] setWidth:viewport.width];
    CGFloat rowsHeight=[self.blockedTableView numberOfRows]*([self.blockedTableView rowHeight]+[self.blockedTableView intercellSpacing].height);
    [self.blockedTableView setFrameSize:NSMakeSize(viewport.width,MAX(viewport.height,rowsHeight))];
    if(stacked) {
        CGFloat buttonWidth=floor((pw-12)/2);
        [self.contactPopUpButton setFrame:NSMakeRect(0,52,pw,28)];
        [self.blockButton setFrame:NSMakeRect(0,8,buttonWidth,28)];
        [self.unblockButton setFrame:NSMakeRect(buttonWidth+12,8,pw-buttonWidth-12,28)];
    } else {
        [self.contactPopUpButton setFrame:NSMakeRect(0,8,MAX(100,pw-304),28)];
        [self.blockButton setFrame:NSMakeRect(pw-294,8,132,28)];[self.unblockButton setFrame:NSMakeRect(pw-152,8,152,28)];
    }
    // Each editable section owns one footer action. Permissions apply immediately.
    [self.applyRuleButton setHidden:selected!=0];[self.applyRetentionButton setHidden:selected!=1];
    [self.applyRuleButton setFrame:NSMakeRect(w-144,12,124,30)];
    [self.applyRetentionButton setFrame:NSMakeRect(w-144,12,124,30)];
    CGFloat statusWidth=w-(selected<2?204:70);
    [self.statusField setFrame:NSMakeRect(20,12,MAX(0,statusWidth),30)];
    [[self.statusField cell] setWraps:YES];[[self.statusField cell] setUsesSingleLineMode:NO];[[self.statusField cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [self.spinner setFrame:NSMakeRect(selected<2?w-174:w-36,19,16,16)];
}
- (void)windowDidResize:(NSNotification *)notification {if([notification object]==[self window])[self layoutAquaPrivacyViews];}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)proposed {
    NSScreen *screen=[window screen] ? [window screen] : [NSScreen mainScreen];
    return screen ? TGUtilityWindowFrameFittingVisibleFrame(proposed,[screen visibleFrame]) : proposed;
}
- (void)windowDidChangeScreen:(NSNotification *)notification {
    if([notification object]==[self window]) {
        TGFitUtilityWindowToVisibleScreen([self window]);[self layoutAquaPrivacyViews];
    }
}
