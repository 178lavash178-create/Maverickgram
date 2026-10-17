// Aqua profile editing: the shared utility material frames a plain native form.
static NSTextField *TGProfileEditAquaLabel(NSString *title, NSRect frame) {
    NSTextField *field = [[[NSTextField alloc] initWithFrame:frame] autorelease];
    [field setEditable:NO]; [field setSelectable:NO]; [field setBordered:NO];
    [field setDrawsBackground:NO]; [field setFont:[NSFont systemFontOfSize:12.0]];
    [field setTextColor:[NSColor colorWithCalibratedWhite:0.22 alpha:1.0]];
    [field setStringValue:title ? title : @""]; return field;
}
static NSTextField *TGProfileEditAquaInput(NSRect frame) {
    NSTextField *field = TGProfileEditInput(frame);
    [field setBezelStyle:NSTextFieldSquareBezel];
    [field setFocusRingType:NSFocusRingTypeExterior]; return field;
}
static NSButton *TGProfileEditAquaButton(NSString *title, NSRect frame, BOOL primary, id target, SEL action) {
    NSButton *button = [[[NSButton alloc] initWithFrame:frame] autorelease];
    TGAquaTextButtonCell *cell = [[[TGAquaTextButtonCell alloc] initTextCell:title] autorelease];
    [cell setAccented:primary]; [button setCell:cell]; [button setTitle:title];
    [button setButtonType:NSMomentaryPushInButton]; [button setFont:[NSFont systemFontOfSize:13.0]];
    [button setTarget:target]; [button setAction:action]; return button;
}
- (void)buildAquaProfileEditor {
    TGAquaUtilityWindowView *content = [[[TGAquaUtilityWindowView alloc] initWithFrame:NSMakeRect(0,0,500,500)] autorelease];
    [content setHeaderHeight:52.0]; [content setFooterHeight:54.0];
    [[self window] setContentView:content];
    NSTextField *heading = TGProfileEditAquaLabel(TGLoc(@"profile.edit.title"),NSMakeRect(24,466,452,20));
    [heading setFont:[NSFont boldSystemFontOfSize:14.0]]; [content addSubview:heading];

    _avatarView = [[TGProfileAvatarView alloc] initWithFrame:NSMakeRect(24,360,72,72)];
    [content addSubview:_avatarView];
    [content addSubview:TGProfileEditAquaLabel(TGLoc(@"profile.edit.photo"),NSMakeRect(116,404,360,18))];
    _photoButton = [TGProfileEditAquaButton(TGLoc(@"profile.edit.photo.choose"),NSMakeRect(116,367,190,28),NO,self,@selector(chooseProfilePhoto:)) retain];
    [content addSubview:_photoButton];

    [content addSubview:TGProfileEditAquaLabel(TGLoc(@"profile.edit.firstName"),NSMakeRect(24,330,218,18))];
    [content addSubview:TGProfileEditAquaLabel(TGLoc(@"profile.edit.lastName"),NSMakeRect(258,330,218,18))];
    _firstNameField = [TGProfileEditAquaInput(NSMakeRect(24,300,218,26)) retain];
    _lastNameField = [TGProfileEditAquaInput(NSMakeRect(258,300,218,26)) retain];
    [content addSubview:_firstNameField]; [content addSubview:_lastNameField];
    [content addSubview:TGProfileEditAquaLabel(TGLoc(@"profile.edit.username"),NSMakeRect(24,276,452,18))];
    _usernameField = [TGProfileEditAquaInput(NSMakeRect(24,246,452,26)) retain];
    [[_usernameField cell] setPlaceholderString:@"username"]; [content addSubview:_usernameField];
    [content addSubview:TGProfileEditAquaLabel(TGLoc(@"profile.edit.bio"),NSMakeRect(24,222,452,18))];
    _bioScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(24,118,452,100)];
    [_bioScrollView setBorderType:NSBezelBorder]; [_bioScrollView setHasVerticalScroller:YES];
    [_bioScrollView setHasHorizontalScroller:NO]; [_bioScrollView setAutohidesScrollers:YES];
    [_bioScrollView setDrawsBackground:YES]; [_bioScrollView setBackgroundColor:[NSColor whiteColor]];
    NSSize size = [_bioScrollView contentSize];
    _bioTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,size.width,size.height)];
    [_bioTextView setRichText:NO]; [_bioTextView setImportsGraphics:NO]; [_bioTextView setAllowsUndo:YES];
    [_bioTextView setFont:[NSFont systemFontOfSize:13.0]];
    [_bioTextView setTextColor:[NSColor colorWithCalibratedWhite:0.15 alpha:1.0]];
    [_bioTextView setBackgroundColor:[NSColor whiteColor]]; [_bioTextView setTextContainerInset:NSMakeSize(6,6)];
    [_bioTextView setHorizontallyResizable:NO]; [_bioTextView setVerticallyResizable:YES];
    [_bioTextView setMinSize:NSMakeSize(0,size.height)]; [_bioTextView setMaxSize:NSMakeSize(FLT_MAX,FLT_MAX)];
    [[_bioTextView textContainer] setWidthTracksTextView:YES];
    [[_bioTextView textContainer] setContainerSize:NSMakeSize(size.width,FLT_MAX)];
    [_bioTextView setAutoresizingMask:NSViewWidthSizable];
    [_bioScrollView setDocumentView:_bioTextView]; [content addSubview:_bioScrollView];

    _errorField = [TGProfileEditAquaLabel(@"",NSMakeRect(24,72,452,36)) retain];
    [_errorField setFont:[NSFont systemFontOfSize:11.0]];
    [_errorField setTextColor:[NSColor colorWithCalibratedRed:0.62 green:0.12 blue:0.10 alpha:1.0]];
    [[_errorField cell] setUsesSingleLineMode:NO]; [[_errorField cell] setWraps:YES];
    [[_errorField cell] setScrollable:NO]; [_errorField setHidden:YES]; [content addSubview:_errorField];
    _cancelButton = [TGProfileEditAquaButton(TGLoc(@"cancel"),NSMakeRect(246,13,110,28),NO,self,@selector(cancelProfileEdit:)) retain];
    _saveButton = [TGProfileEditAquaButton(TGLoc(@"save"),NSMakeRect(366,13,110,28),YES,self,@selector(saveProfile:)) retain];
    [_cancelButton setKeyEquivalent:@"\033"]; [_saveButton setKeyEquivalent:@"\r"];
    [content addSubview:_cancelButton]; [content addSubview:_saveButton];
    [_photoButton setNextKeyView:_firstNameField]; [_firstNameField setNextKeyView:_lastNameField];
    [_lastNameField setNextKeyView:_usernameField]; [_usernameField setNextKeyView:_bioTextView];
    [_bioTextView setNextKeyView:_cancelButton]; [_cancelButton setNextKeyView:_saveButton];
    [_saveButton setNextKeyView:_photoButton]; [[self window] setInitialFirstResponder:_firstNameField];
}
