// The map is the content; only the search rail and confirmation rail are raised.
- (void)buildAquaViews {
    [[self window] setContentSize:NSMakeSize(640,552)];
    TGAquaUtilityWindowView *root = [[[TGAquaUtilityWindowView alloc] initWithFrame:NSMakeRect(0,0,640,552)] autorelease];
    root.headerHeight = 96.0; root.footerHeight = 100.0;
    [[self window] setContentView:root];
    [root addSubview:[self labelWithFrame:NSMakeRect(18,520,604,20) text:TGLoc(@"share.location.title")
        font:[NSFont boldSystemFontOfSize:14] color:TGThemeSurfaceInkColor(TGClassicHeaderTextColor(1),TGThemeSurfaceHeader,4.5)]];
    self.searchService = [[[TGLocationSearchService alloc] init] autorelease];
    self.searchField = [[[NSSearchField alloc] initWithFrame:NSMakeRect(18,472,350,26)] autorelease];
    [[self.searchField cell] setPlaceholderString:TGLoc(@"share.location.searchPlaceholder")];
    [self.searchField setFont:[NSFont systemFontOfSize:12]];
    [self.searchField setTarget:self]; [self.searchField setAction:@selector(searchPressed:)];
    [self.searchField setEnabled:[self.searchService isAvailable]];
    [self.searchField setToolTip:TGLoc(@"share.location.pickerHint")];
    [root addSubview:self.searchField];
    self.searchButton = [self buttonWithFrame:NSMakeRect(378,472,80,26) title:TGLoc(@"share.location.search") action:@selector(searchPressed:) primary:NO];
    [self.searchButton setEnabled:[self.searchService isAvailable]]; [root addSubview:self.searchButton];
    self.currentLocationButton = [self buttonWithFrame:NSMakeRect(470,472,152,26) title:TGLoc(@"share.location.mine") action:@selector(currentLocationPressed:) primary:NO];
    [self.currentLocationButton setEnabled:self.mapServicesAvailable];
    [self.currentLocationButton setToolTip:TGLoc(@"share.location.manualHint")]; [root addSubview:self.currentLocationButton];
    self.mapImageView = [[[TGLocationStaticMapView alloc] initWithFrame:NSMakeRect(0,100,640,356)] autorelease];
    [self.mapImageView setCoordinateTarget:self]; [self.mapImageView setCoordinateAction:@selector(mapCoordinateChosen:)];
    [self.mapImageView setZoom:self.mapZoom]; [root addSubview:self.mapImageView];
    if (self.mapServicesAvailable) {
        self.locationServiceMapView = [[[NSClassFromString(@"MKMapView") alloc] initWithFrame:NSMakeRect(-4,-4,1,1)] autorelease];
        [self.locationServiceMapView setDelegate:(id)self]; [self.locationServiceMapView setHidden:YES]; [root addSubview:self.locationServiceMapView];
        [self.mapImageView setSelectionPinImage:[self systemSelectionPinImage]];
    }
    NSButton *zoomOut = [self buttonWithFrame:NSMakeRect(562,418,28,28) title:@"−" action:@selector(zoomOutPressed:) primary:NO];
    NSButton *zoomIn = [self buttonWithFrame:NSMakeRect(596,418,28,28) title:@"+" action:@selector(zoomInPressed:) primary:NO];
    [root addSubview:zoomOut]; [root addSubview:zoomIn];
    [root addSubview:[self labelWithFrame:NSMakeRect(18,74,560,18) text:TGLoc(@"share.location.selected")
        font:[NSFont boldSystemFontOfSize:11] color:TGThemeSurfaceInkColor(TGClassicHeaderTextColor(1),TGThemeSurfaceHeader,4.5)]];
    self.statusField = [self labelWithFrame:NSMakeRect(18,52,604,18) text:TGLoc(@"share.location.ready")
        font:[NSFont systemFontOfSize:11] color:TGThemeSurfaceInkColor(TGClassicHeaderDetailTextColor(1),TGThemeSurfaceHeader,4.5)];
    [[self.statusField cell] setLineBreakMode:NSLineBreakByTruncatingTail]; [root addSubview:self.statusField];
    self.spinner = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(604,76,16,16)] autorelease];
    [self.spinner setStyle:NSProgressIndicatorSpinningStyle]; [self.spinner setDisplayedWhenStopped:NO]; [root addSubview:self.spinner];
    NSButton *cancel = [self buttonWithFrame:NSMakeRect(392,14,110,28) title:TGLoc(@"cancel") action:@selector(cancelPressed:) primary:NO];
    [cancel setKeyEquivalent:@"\033"]; [root addSubview:cancel];
    self.sendButton = [self buttonWithFrame:NSMakeRect(512,14,110,28) title:TGLoc(@"send") action:@selector(sendPressed:) primary:YES];
    [root addSubview:self.sendButton];
    [[self window] setInitialFirstResponder:[self.searchService isAvailable]?self.searchField:self.mapImageView];
    [self setSelectedCoordinate:CLLocationCoordinate2DMake(53.9006,27.5590) reloadMap:YES];
}
