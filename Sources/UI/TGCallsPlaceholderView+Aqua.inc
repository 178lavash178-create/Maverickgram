// Aqua uses a source list between two quiet rails, without cards per call.
- (void)drawRect:(NSRect)dirtyRect {
    if (!TGInterfaceDesignIsAqua()) { [super drawRect:dirtyRect]; return; }
    NSRect bounds=[self bounds];
    [[NSColor colorWithCalibratedWhite:0.985 alpha:1] set];NSRectFill(bounds);
    CGFloat headerHeight=NSWidth(bounds)<620?146:110;
    NSRect header=NSMakeRect(0,NSHeight(bounds)-headerHeight,NSWidth(bounds),headerHeight);
    NSRect footer=NSMakeRect(0,0,NSWidth(bounds),54);
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:header],header,TGThemeSurfaceHeader,NO);
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:footer],footer,TGThemeSurfaceHeader,NO);
    [[NSColor colorWithCalibratedWhite:0.65 alpha:1] set];NSRectFill(NSMakeRect(0,53,NSWidth(bounds),1));
}
- (void)layoutAquaCalls {
    NSSize size=[self bounds].size;CGFloat w=size.width,h=size.height;
    [self.cardView setHidden:YES];[[self viewWithTag:602] setHidden:YES];
    [self.titleField setFont:[NSFont boldSystemFontOfSize:14]];
    [self.titleField setAlignment:NSLeftTextAlignment];
    [self.titleField setFrame:NSMakeRect(24,h-36,MAX(80,w-48),20)];
    NSTextField *newLabel=(NSTextField *)[self viewWithTag:601];
    [newLabel setFrame:NSMakeRect(24,h-64,MAX(80,w-48),18)];
    CGFloat refresh=MAX(82,ceil([[self.refreshButton title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]].width)+24);
    CGFloat start=MAX(128,ceil([[self.startCallButton title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:13] forKey:NSFontAttributeName]].width)+28);
    CGFloat popup=MAX(80,w-48-refresh-start-16);
    [self.contactPopUpButton setFrame:NSMakeRect(24,h-98,popup,28)];
    [self.startCallButton setFrame:NSMakeRect(32+popup,h-98,start,28)];
    [self.refreshButton setFrame:NSMakeRect(w-24-refresh,h-98,refresh,28)];
    BOOL stacked=w<620;
    if(stacked){
        [self.contactPopUpButton setFrame:NSMakeRect(24,h-98,w-48,28)];
        [self.startCallButton setFrame:NSMakeRect(w-32-refresh-start,h-134,start,28)];
        [self.refreshButton setFrame:NSMakeRect(w-24-refresh,h-134,refresh,28)];
    }
    [self.historyScrollView setFrame:NSMakeRect(16,66,MAX(100,w-32),MAX(40,h-(stacked?224:188)))];
    [self.historyScrollView tile];
    CGFloat listWidth=MAX(1,NSWidth([[self.historyScrollView contentView] bounds]));
    [[[self.tableView tableColumns] lastObject] setWidth:listWidth];
    [self.tableView setFrameSize:NSMakeSize(listWidth,MAX(NSHeight([[self.historyScrollView contentView] bounds]),[self.tableView numberOfRows]*[self.tableView rowHeight]))];
    [self.statusField setAlignment:NSLeftTextAlignment];
    [self.statusField setFrame:NSMakeRect(24,18,MAX(80,w-76),18)];
    [self.spinner setFrame:NSMakeRect(w-40,19,16,16)];
    [self.unavailableTitleField setFrame:NSMakeRect(24,h/2+18,MAX(80,w-48),28)];
    [self.unavailableDetailField setFrame:NSMakeRect(24,h/2-50,MAX(80,w-48),64)];
}

- (void)setFrameSize:(NSSize)size {
    [super setFrameSize:size];
    // Finish after native springs have settled the scroll view and document.
    if(TGInterfaceDesignIsAqua())[self layoutAquaCalls];
}
