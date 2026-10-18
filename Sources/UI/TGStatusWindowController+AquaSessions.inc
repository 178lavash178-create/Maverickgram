// Session presentation reuses existing data, selection and termination handlers.
- (void)setActiveSessionsStatusText:(NSString *)text {
    [self.activeSessionsStatusField setStringValue:text ? text : @""];
    [self.activeSessionsStatusField setToolTip:text];
}
- (void)configureAquaActiveSessionsWindow {
    if(!TGInterfaceDesignIsAqua()) return;
    NSWindow *window=self.activeSessionsWindow;
    TGAquaUtilityWindowView *root=[[[TGAquaUtilityWindowView alloc] initWithFrame:[TGUtilityWindowContentView(window) bounds]] autorelease];
    root.headerHeight=52; root.footerHeight=54;
    [root setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    NSTextField *title=[self utilityLabelWithFrame:NSZeroRect text:TGLoc(@"settings.section.sessions") font:[NSFont boldSystemFontOfSize:14]];
    [title setTag:5921]; [root addSubview:title];
    NSScrollView *scroll=[self.activeSessionsTableView enclosingScrollView];
    for(NSView *view in [NSArray arrayWithObjects:scroll,self.activeSessionsStatusField,self.activeSessionsTerminatePopup,self.activeSessionsTerminateButton,self.activeSessionsRefreshButton,self.activeSessionsCloseButton,nil]) {
        [view setAutoresizingMask:NSViewNotSizable]; [root addSubview:view];
    }
    [scroll setBorderType:NSNoBorder]; [scroll setDrawsBackground:YES]; [scroll setBackgroundColor:[NSColor whiteColor]];
    [scroll setHasVerticalScroller:YES]; [scroll setAutohidesScrollers:YES];
    [self.activeSessionsTableView setBackgroundColor:[NSColor whiteColor]];
    [self.activeSessionsTableView setIntercellSpacing:NSZeroSize];
    [self.activeSessionsStatusField setFont:[NSFont systemFontOfSize:11]];
    [[self.activeSessionsStatusField cell] setWraps:YES]; [[self.activeSessionsStatusField cell] setUsesSingleLineMode:NO];
    [[self.activeSessionsStatusField cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [self.activeSessionsStatusField setSelectable:YES];
    [self.activeSessionsRefreshButton setCell:[[[TGHeaderIconButtonCell alloc] initTextCell:@"refresh"] autorelease]];
    [self.activeSessionsRefreshButton setTitle:@"↻"];
    [self.activeSessionsRefreshButton setToolTip:TGLoc(@"settings.sessions.refresh")];
    [self.activeSessionsRefreshButton setButtonType:NSMomentaryPushInButton];
    [self.activeSessionsRefreshButton setTarget:self]; [self.activeSessionsRefreshButton setAction:@selector(reloadActiveSessions:)];
    [self.activeSessionsTerminatePopup setFont:[NSFont systemFontOfSize:12]];
    [self.activeSessionsTerminateButton setFont:[NSFont systemFontOfSize:12]];
    [window setContentView:root]; [window setDelegate:self];
    [self layoutAquaActiveSessionsWindow];
}
- (void)layoutAquaActiveSessionsWindow {
    if(!TGInterfaceDesignIsAqua() || !self.activeSessionsWindow) return;
    NSView *root=TGUtilityWindowContentView(self.activeSessionsWindow);
    if(![root isKindOfClass:[TGAquaUtilityWindowView class]]) return;
    CGFloat w=NSWidth([root bounds]),h=NSHeight([root bounds]);
    [[root viewWithTag:5921] setFrame:NSMakeRect(20,h-35,MAX(0,w-82),22)];
    [self.activeSessionsRefreshButton setFrame:NSMakeRect(w-52,h-41,32,30)];
    [self.activeSessionsCloseButton setFrame:NSMakeRect(w-130,12,110,30)];
    [self.activeSessionsStatusField setFrame:NSMakeRect(20,12,MAX(0,w-168),30)];
    CGFloat buttonWidth=MAX(146,ceil([[self.activeSessionsTerminateButton cell] cellSize].width));
    buttonWidth=MIN(buttonWidth,MAX(146,w*0.45));
    [self.activeSessionsTerminateButton setFrame:NSMakeRect(w-20-buttonWidth,66,buttonWidth,28)];
    [self.activeSessionsTerminatePopup setFrame:NSMakeRect(20,66,MAX(0,w-buttonWidth-52),28)];
    NSScrollView *scroll=[self.activeSessionsTableView enclosingScrollView];
    [scroll setFrame:NSMakeRect(0,108,w,MAX(0,h-160))]; [scroll tile];
    NSSize viewport=[[scroll contentView] bounds].size;
    [[[self.activeSessionsTableView tableColumns] lastObject] setWidth:viewport.width];
    CGFloat rows=[self.activeSessionsTableView numberOfRows]*([self.activeSessionsTableView rowHeight]+[self.activeSessionsTableView intercellSpacing].height);
    [self.activeSessionsTableView setFrameSize:NSMakeSize(viewport.width,MAX(viewport.height,rows))];
}
