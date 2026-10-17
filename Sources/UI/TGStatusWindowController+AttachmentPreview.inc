- (void)ensurePhotoSendPreviewWindow {
    if (self.photoSendPreviewWindow) {
        return;
    }

    NSRect frame = NSMakeRect(0, 0, 520, 600);
    NSWindow *window = [[[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSTitledWindowMask | NSClosableWindowMask)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO] autorelease];
    [window setTitle:TGLoc(@"attachment.preview.title")];
    [window setReleasedWhenClosed:NO];

    TGUtilityWindowView *contentView = [[[TGUtilityWindowView alloc] initWithFrame:frame] autorelease];
    [contentView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [window setContentView:contentView];

    TGUtilityPanelView *panelView = [[[TGUtilityPanelView alloc] initWithFrame:NSMakeRect(12, 16, 496, 548)] autorelease];
    [panelView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [contentView addSubview:panelView];
    TGGroupedCardView *previewCard = [[[TGGroupedCardView alloc] initWithFrame:NSMakeRect(24, 78, 472, 476)] autorelease];
    [previewCard setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [contentView addSubview:previewCard];

    NSTextField *titleField = [self labelWithFrame:NSMakeRect(24, 562, 472, 24)
                                              text:[NSString stringWithFormat:TGLoc(@"attachment.preview.count"), (unsigned long)1]
                                              font:[NSFont boldSystemFontOfSize:16.0]];
    [titleField setAlignment:NSCenterTextAlignment];
    [titleField setTextColor:TGThemeSurfaceInkColor(TGClassicHeaderTextColor(1.0), TGThemeSurfaceWindow, 4.5)];
    [contentView addSubview:titleField];
    self.photoSendTitleField = titleField;

    NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(36, 246, 448, 296)] autorelease];
    [imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [imageView setImageFrameStyle:NSImageFrameNone];
    [imageView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [contentView addSubview:imageView];
    self.photoSendPreviewImageView = imageView;

    // Return inserts a line break. Scrolling keeps long captions editable.
    NSTextField *captionLabel = [self labelWithFrame:NSMakeRect(40, 216, 440, 18)
                                               text:TGLoc(@"caption.placeholder")
                                               font:[NSFont systemFontOfSize:12.0]];
    [self applyMutedLabelStyle:captionLabel];
    [contentView addSubview:captionLabel];
    TGComposerInputBackgroundView *captionBackground = [[[TGComposerInputBackgroundView alloc] initWithFrame:NSMakeRect(36, 88, 448, 120)] autorelease];
    [captionBackground setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
    [contentView addSubview:captionBackground];
    self.photoSendCaptionBackgroundView = captionBackground;

    NSScrollView *captionScroll = [[[NSScrollView alloc] initWithFrame:NSMakeRect(43, 95, 434, 106)] autorelease];
    [captionScroll setBorderType:NSNoBorder];
    [captionScroll setHasVerticalScroller:YES];
    [captionScroll setHasHorizontalScroller:NO];
    [captionScroll setAutohidesScrollers:YES];
    [captionScroll setDrawsBackground:NO];
    [[captionScroll contentView] setDrawsBackground:NO];
    [captionScroll setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    NSTextView *captionField = [[[NSTextView alloc] initWithFrame:[[captionScroll contentView] bounds]] autorelease];
    [captionField setRichText:NO];
    [captionField setImportsGraphics:NO];
    [captionField setAllowsUndo:YES];
    [captionField setVerticallyResizable:YES];
    [captionField setHorizontallyResizable:NO];
    [captionField setMinSize:NSMakeSize(0, NSHeight([[captionScroll contentView] bounds]))];
    [captionField setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [captionField setAutoresizingMask:NSViewWidthSizable];
    [captionField setTextContainerInset:NSMakeSize(3, 4)];
    [[captionField textContainer] setContainerSize:NSMakeSize(NSWidth([[captionScroll contentView] bounds]), CGFLOAT_MAX)];
    [[captionField textContainer] setWidthTracksTextView:YES];
    TGAccessibilityConfigureContent(captionField, TGLoc(@"caption.placeholder"));
    [captionScroll setDocumentView:captionField];
    [contentView addSubview:captionScroll];
    self.photoSendCaptionField = captionField;
    self.photoSendCaptionScrollView = captionScroll;
    [self refreshAttachmentCaptionStyle];

    NSTextField *errorField = [self labelWithFrame:NSMakeRect(36, 64, 448, 18)
                                              text:@""
                                              font:[NSFont systemFontOfSize:11.0]];
    [errorField setTextColor:[NSColor colorWithCalibratedRed:0.760 green:0.160 blue:0.130 alpha:1.0]];
    [errorField setHidden:YES];
    [errorField setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
    [[errorField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [contentView addSubview:errorField];
    self.photoSendErrorField = errorField;

    NSButton *cancelButton = [self modalCloseButtonWithFrame:NSMakeRect(244, 28, 108, 30)];
    [cancelButton setTitle:TGLoc(@"cancel")];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancelPendingPhotoSend:)];
    [cancelButton setKeyEquivalent:[NSString stringWithFormat:@"%C", (unichar)27]];
    [cancelButton setKeyEquivalentModifierMask:0];
    [cancelButton setAutoresizingMask:(NSViewMinXMargin | NSViewMaxYMargin)];
    [contentView addSubview:cancelButton];

    NSButton *sendButton = [[[NSButton alloc] initWithFrame:NSMakeRect(368, 28, 108, 30)] autorelease];
    [sendButton setTitle:TGLoc(@"send")];
    [sendButton setTarget:self];
    [sendButton setAction:@selector(sendPendingPhotoPreview:)];
    [sendButton setKeyEquivalent:@"\r"];
    [sendButton setKeyEquivalentModifierMask:0];
    [self applySkeuomorphicButtonStyle:sendButton isPrimary:YES];
    [sendButton setAutoresizingMask:(NSViewMinXMargin | NSViewMaxYMargin)];
    [contentView addSubview:sendButton];
    self.photoSendSendButton = sendButton;

    self.photoSendPreviewWindow = window;
}

- (void)refreshAttachmentCaptionStyle {
    NSTextView *caption = self.photoSendCaptionField;
    [caption setDrawsBackground:NO];
    [caption setFont:[NSFont systemFontOfSize:13.0]];
    NSColor *ink = TGThemeSurfaceInkColor(TGClassicInkColor(), TGThemeSurfaceCard, 4.5);
    [caption setTextColor:ink];
    [caption setInsertionPointColor:ink];
    [self.photoSendCaptionBackgroundView setNeedsDisplay:YES];
}

// A reused text view must not carry undo operations into the next attachment.
- (void)resetAttachmentCaption {
    NSTextView *caption=self.photoSendCaptionField;
    NSUndoManager *undo=[caption undoManager];
    [caption breakUndoCoalescing];
    [undo removeAllActions];
    BOOL allowsUndo=[caption allowsUndo];
    [caption setAllowsUndo:NO];
    [caption setString:@""];
    [caption setSelectedRange:NSMakeRange(0,0)];
    [caption scrollRangeToVisible:NSMakeRange(0,0)];
    [undo removeAllActions];
    [caption setAllowsUndo:allowsUndo];
}
