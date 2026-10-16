- (void)ensureVoicePreviewWindow {
    if (self.voicePreviewWindow) {
        return;
    }

    NSRect frame = NSMakeRect(0, 0, 420, 190);
    NSWindow *window = [[[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSTitledWindowMask | NSClosableWindowMask)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO] autorelease];
    [window setTitle:@"Voice message"];
    [window setReleasedWhenClosed:NO];
    [window setDelegate:self];
    if (TGInterfaceDesignIsAqua()) {
        [window setContentSize:NSMakeSize(520,290)];
        [window setTitle:TGLoc(@"recording.voice.title")];
        [self buildAquaVoicePreviewWindow:window]; self.voicePreviewWindow=window; return;
    }
    TGUtilityWindowView *contentView = [[[TGUtilityWindowView alloc] initWithFrame:frame] autorelease];
    [window setContentView:contentView];

    TGUtilityPanelView *panelView = [[[TGUtilityPanelView alloc] initWithFrame:NSMakeRect(10, 10, 400, 170)] autorelease];
    [contentView addSubview:panelView];
    TGGroupedCardView *cardView = [[[TGGroupedCardView alloc] initWithFrame:NSMakeRect(18, 18, 384, 154)] autorelease];
    [contentView addSubview:cardView];

    NSTextField *titleField = [self labelWithFrame:NSMakeRect(30, 146, 360, 22)
                                              text:@"Voice message ready"
                                              font:[NSFont boldSystemFontOfSize:15.0]];
    [titleField setAlignment:NSCenterTextAlignment];
    [titleField setTextColor:TGClassicCardInkColor()];
    [contentView addSubview:titleField];
    self.voicePreviewTitleField = titleField;

    NSButton *playButton = [[[NSButton alloc] initWithFrame:NSMakeRect(30, 76, 48, 48)] autorelease];
    [playButton setTitle:@"Play"];
    [playButton setCell:[[[TGMediaPlaybackButtonCell alloc] initTextCell:@"Play"] autorelease]];
    [playButton setBordered:NO];
    [playButton setFocusRingType:NSFocusRingTypeNone];
    [playButton setTarget:self];
    [playButton setAction:@selector(toggleVoicePreviewPlayback:)];
    [contentView addSubview:playButton];
    self.voicePreviewPlayButton = playButton;

    NSButton *stopButton = [[[NSButton alloc] initWithFrame:NSMakeRect(134, 78, 152, 34)] autorelease];
    [stopButton setTitle:@"Stop"];
    [stopButton setTarget:self];
    [stopButton setAction:@selector(toggleVoiceRecording:)];
    [self applySkeuomorphicButtonStyle:stopButton isPrimary:YES];
    [stopButton setHidden:YES];
    [contentView addSubview:stopButton];
    self.voicePreviewStopButton = stopButton;

    NSSlider *progressSlider = [[[NSSlider alloc] initWithFrame:NSMakeRect(92, 94, 208, 22)] autorelease];
    [progressSlider setMinValue:0.0];
    [progressSlider setMaxValue:1.0];
    [progressSlider setDoubleValue:0.0];
    [progressSlider setContinuous:YES];
    [progressSlider setTarget:self];
    [progressSlider setAction:@selector(voicePreviewSliderChanged:)];
    [progressSlider setEnabled:NO];
    [contentView addSubview:progressSlider];
    self.voicePreviewProgressSlider = progressSlider;

    NSTextField *timeField = [self labelWithFrame:NSMakeRect(308, 94, 82, 20)
                                             text:@"0:00 / 0:00"
                                             font:[NSFont systemFontOfSize:11.0]];
    [timeField setAlignment:NSRightTextAlignment];
    [self applyMutedLabelStyle:timeField];
    [contentView addSubview:timeField];
    self.voicePreviewTimeField = timeField;

    NSButton *cancelButton = [self modalCloseButtonWithFrame:NSMakeRect(172, 34, 102, 30)];
    [cancelButton setTitle:TGLoc(@"cancel")];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancelVoicePreview:)];
    [cancelButton setKeyEquivalent:[NSString stringWithFormat:@"%C", (unichar)27]];
    [cancelButton setKeyEquivalentModifierMask:0];
    [contentView addSubview:cancelButton];
    self.voicePreviewCancelButton = cancelButton;

    NSButton *sendButton = [[[NSButton alloc] initWithFrame:NSMakeRect(288, 34, 102, 30)] autorelease];
    [sendButton setTitle:TGLoc(@"send")];
    [sendButton setTarget:self];
    [sendButton setAction:@selector(sendVoicePreview:)];
    [sendButton setKeyEquivalent:@"\r"];
    [sendButton setKeyEquivalentModifierMask:0];
    [self applySkeuomorphicButtonStyle:sendButton isPrimary:YES];
    [contentView addSubview:sendButton];
    self.voicePreviewSendButton = sendButton;

    NSTextField *errorField = [self labelWithFrame:NSMakeRect(30, 124, 360, 16)
                                              text:@""
                                              font:[NSFont systemFontOfSize:11.0]];
    [errorField setTextColor:[NSColor colorWithCalibratedRed:0.760 green:0.160 blue:0.130 alpha:1.0]];
    [errorField setAlignment:NSCenterTextAlignment];
    [errorField setHidden:YES];
    [[errorField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [contentView addSubview:errorField];
    self.voicePreviewErrorField = errorField;

    self.voicePreviewWindow = window;
}

- (void)configureVoicePreviewWindowForRecording {
    [self ensureVoicePreviewWindow];
    [self.voicePreviewTitleField setStringValue:TGLoc(@"voice.recording")];
    [self.voicePreviewTitleField setTextColor:TGClassicCardInkColor()];
    [self.voicePreviewErrorField setStringValue:@"Press Stop when you finish recording."];
    [self.voicePreviewErrorField setHidden:NO];
    [self.voicePreviewPlayButton setHidden:YES];
    [self.voicePreviewProgressSlider setHidden:YES];
    [self.voicePreviewTimeField setHidden:YES];
    [self.voicePreviewCancelButton setHidden:YES];
    [self.voicePreviewSendButton setHidden:YES];
    [self.voicePreviewStopButton setHidden:NO];
    [self.voicePreviewStopButton setEnabled:YES];
    if (TGInterfaceDesignIsAqua()) {
        [self.voicePreviewTitleField setStringValue:TGLoc(@"recording.voice.title")];
        [self.voicePreviewTimeField setFrame:NSMakeRect(40,128,440,46)];
        [self.voicePreviewTimeField setHidden:NO];
        [self.voicePreviewTimeField setStringValue:@"0:00"];
        [self.voicePreviewCancelButton setHidden:NO];
        [self.voicePreviewErrorField setStringValue:TGLoc(@"recording.voice.hint")];
        [self.voicePreviewErrorField setTextColor:[NSColor colorWithCalibratedWhite:0.28 alpha:1]];
        [self startVoicePreviewTimer];
    }
    [self.voicePreviewWindow center];
    [self.voicePreviewWindow makeKeyAndOrderFront:nil];
}

- (void)configureVoicePreviewWindowForReadyDuration:(NSTimeInterval)duration {
    [self ensureVoicePreviewWindow];
    if (TGInterfaceDesignIsAqua()) [self invalidateVoicePreviewTimer];
    [self.voicePreviewTitleField setStringValue:[NSString stringWithFormat:@"Voice message %.0fs", duration]];
    [self.voicePreviewTitleField setTextColor:TGClassicCardInkColor()];
    [self.voicePreviewPlayButton setTitle:@"Play"];
    [self.voicePreviewPlayButton setHidden:NO];
    [self.voicePreviewStopButton setHidden:YES];
    [self.voicePreviewProgressSlider setHidden:NO];
    [self.voicePreviewTimeField setHidden:NO];
    [self.voicePreviewCancelButton setHidden:NO];
    [self.voicePreviewSendButton setHidden:NO];
    [self.voicePreviewSendButton setTitle:TGLoc(@"send")];
    [self.voicePreviewSendButton setEnabled:YES];
    [self.voicePreviewErrorField setStringValue:@""];
    [self.voicePreviewErrorField setHidden:YES];
    if (TGInterfaceDesignIsAqua()) {
        [self.voicePreviewTimeField setFrame:TGAquaVoiceRecordingClockFrame()];
        [self.voicePreviewTitleField setStringValue:TGLoc(@"recording.voice.ready")];
        [self.voicePreviewErrorField setTextColor:[NSColor colorWithCalibratedRed:0.76 green:0.16 blue:0.13 alpha:1]];
    }
    [self updateVoicePreviewTimelineWithCurrentTime:0.0 duration:duration];
    [self.voicePreviewWindow center];
    [self.voicePreviewWindow makeKeyAndOrderFront:nil];
}


- (void)buildAquaVoicePreviewWindow:(NSWindow *)window {
    TGAquaMetalView *root=[[[TGAquaMetalView alloc] initWithFrame:NSMakeRect(0,0,520,290)] autorelease];[window setContentView:root];
    NSTextField *title=TGAquaRecordingLabel(NSMakeRect(20,246,480,26),TGLoc(@"recording.voice.title"),[NSFont boldSystemFontOfSize:18],NO);
    [root addSubview:title];self.voicePreviewTitleField=title;
    NSTextField *hint=TGAquaRecordingLabel(NSMakeRect(20,218,480,20),TGLoc(@"videoNote.preview"),[NSFont systemFontOfSize:12],NO);[root addSubview:hint];
    TGAquaRecordingDisplayView *display=[[[TGAquaRecordingDisplayView alloc] initWithFrame:NSMakeRect(20,98,480,108)] autorelease];[root addSubview:display];
    NSTextField *clock=TGAquaRecordingLabel(TGAquaVoiceRecordingClockFrame(),@"0:00",[NSFont boldSystemFontOfSize:28],YES);
    TGAquaRecordingConfigureClock(clock,28);[root addSubview:clock];self.voicePreviewTimeField=clock;
    NSButton *play=[[[NSButton alloc] initWithFrame:NSMakeRect(40,124,60,60)] autorelease];
    [play setCell:[[[TGMediaPlaybackButtonCell alloc] initTextCell:@"Play"] autorelease]];[play setTitle:@"Play"];[play setBordered:NO];
    [play setTarget:self];[play setAction:@selector(toggleVoicePreviewPlayback:)];[play setToolTip:TGLoc(@"play")];[root addSubview:play];self.voicePreviewPlayButton=play;
    NSSlider *slider=[[[NSSlider alloc] initWithFrame:NSMakeRect(120,112,360,22)] autorelease];
    [slider setMinValue:0];[slider setMaxValue:1];[slider setEnabled:NO];[slider setContinuous:YES];[slider setTarget:self];[slider setAction:@selector(voicePreviewSliderChanged:)];
    [root addSubview:slider];self.voicePreviewProgressSlider=slider;
    NSTextField *error=TGAquaRecordingLabel(NSMakeRect(20,66,480,26),@"",[NSFont systemFontOfSize:11],NO);
    [error setHidden:YES];[root addSubview:error];self.voicePreviewErrorField=error;
    NSButton *cancel=TGAquaRecordingButton(NSMakeRect(20,22,138,34),TGLoc(@"cancel"),self,@selector(cancelVoicePreview:),NO);
    [cancel setKeyEquivalent:@"\e"];[cancel setKeyEquivalentModifierMask:0];[root addSubview:cancel];self.voicePreviewCancelButton=cancel;
    NSButton *stop=TGAquaRecordingButton(NSMakeRect(362,22,138,34),TGLoc(@"videoNote.stop"),self,@selector(toggleVoiceRecording:),YES);
    [root addSubview:stop];self.voicePreviewStopButton=stop;
    NSButton *send=TGAquaRecordingButton(NSMakeRect(362,22,138,34),TGLoc(@"send"),self,@selector(sendVoicePreview:),YES);
    [send setKeyEquivalent:@"\r"];[send setKeyEquivalentModifierMask:0];[root addSubview:send];self.voicePreviewSendButton=send;
}
