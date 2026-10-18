// Keep authentication semantics unchanged: only the shared utility chrome and
// plain QR stage differ. The footer holds two lines of status plus full tooltip.
- (void)buildAquaViews {
    TGAquaUtilityWindowView *root = [[[TGAquaUtilityWindowView alloc] initWithFrame:NSMakeRect(0,0,480,520)] autorelease];
    [root setHeaderHeight:52.0]; [root setFooterHeight:54.0]; [[self window] setContentView:root];
    NSTextField *title = TGQRCodeLoginLabel(TGLoc(@"login.qr.title"),NSMakeRect(24,486,432,20),[NSFont boldSystemFontOfSize:14.0]);
    [title setAlignment:NSLeftTextAlignment]; [(TGThemeTextField *)title setThemeSurface:TGThemeSurfaceWindow];
    [root addSubview:title];
    NSTextField *hint = TGQRCodeLoginLabel(TGLoc(@"login.qr.hint"),NSMakeRect(32,408,416,44),[NSFont systemFontOfSize:12.0]);
    [(TGThemeTextField *)hint setThemeSurface:TGThemeSurfaceCard];
    [[hint cell] setUsesSingleLineMode:NO]; [[hint cell] setWraps:YES]; [[hint cell] setScrollable:NO];
    [[hint cell] setLineBreakMode:NSLineBreakByWordWrapping]; [root addSubview:hint];
    _qrImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(90,90,300,300)];
    [_qrImageView setImageScaling:NSImageScaleProportionallyUpOrDown]; [root addSubview:_qrImageView];
    _spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(227,227,26,26)];
    [_spinner setStyle:NSProgressIndicatorSpinningStyle]; [_spinner setDisplayedWhenStopped:NO]; [root addSubview:_spinner];
    _statusField = [TGQRCodeLoginLabel(TGLoc(@"login.qr.loading"),NSMakeRect(24,10,432,34),[NSFont systemFontOfSize:11.0]) retain];
    [(TGThemeTextField *)_statusField setThemeSurface:TGThemeSurfaceWindow]; [(TGThemeTextField *)_statusField setDetailInk:YES];
    [(TGThemeTextField *)_statusField refreshThemeInk]; [[_statusField cell] setUsesSingleLineMode:NO];
    [[_statusField cell] setWraps:YES]; [[_statusField cell] setScrollable:NO];
    [[_statusField cell] setLineBreakMode:NSLineBreakByWordWrapping]; [_statusField setSelectable:YES];
    [_statusField setToolTip:[_statusField stringValue]]; [root addSubview:_statusField];
}
