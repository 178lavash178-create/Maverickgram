- (void)buildAquaRecordingViews {
    [[self window] setContentSize:NSMakeSize(580,650)];
    TGAquaMetalView *root=[[[TGAquaMetalView alloc] initWithFrame:NSMakeRect(0,0,580,650)] autorelease];
    [[self window] setContentView:root];
    NSTextField *title=TGAquaRecordingLabel(NSMakeRect(44,608,492,28),TGLoc(@"videoNote.title"),[NSFont boldSystemFontOfSize:19],NO);[root addSubview:title];
    NSTextField *hint=TGAquaRecordingLabel(NSMakeRect(20,584,540,20),TGLoc(@"videoNote.hint"),[NSFont systemFontOfSize:11],NO);[root addSubview:hint];
    self.cameraStateImageView=[[[NSImageView alloc] initWithFrame:NSMakeRect(542,610,24,24)] autorelease];
    [self.cameraStateImageView setImageScaling:NSImageScaleProportionallyUpOrDown];
    self.cameraStateAssetName=@"video";[root addSubview:self.cameraStateImageView];[self refreshCameraTheme:nil];
    TGAquaRecordingDisplayView *well=[[[TGAquaRecordingDisplayView alloc] initWithFrame:NSMakeRect(94,210,392,368)] autorelease];[root addSubview:well];
    self.previewView=[[[TGVideoNotePreviewView alloc] initWithFrame:NSMakeRect(110,214,360,360)] autorelease];
    [self.previewView setWantsLayer:YES];[[self.previewView layer] setMasksToBounds:YES];[root addSubview:self.previewView];
    // Preserve the original separate opaque backing and child circular mask;
    // masking AVCapture's backing layer directly breaks old Core Animation.
    CALayer *clip=[CALayer layer];[clip setFrame:[[self.previewView layer] bounds]];[clip setCornerRadius:180];[clip setMasksToBounds:YES];
    [clip setBackgroundColor:[[NSColor blackColor] CGColor]];[clip setBorderWidth:2];
    [clip setBorderColor:[[NSColor colorWithCalibratedWhite:0.15 alpha:1] CGColor]];
    [[self.previewView layer] addSublayer:clip];self.previewClipLayer=clip;
    TGAquaRecordingDisplayView *clockWell=[[[TGAquaRecordingDisplayView alloc] initWithFrame:NSMakeRect(174,150,232,48)] autorelease];[root addSubview:clockWell];
    self.timerField=TGAquaRecordingLabel(NSMakeRect(180,158,220,34),@"0:00 / 1:00",[NSFont boldSystemFontOfSize:24],YES);
    TGAquaRecordingConfigureClock(self.timerField,24);[root addSubview:self.timerField];
    self.statusField=TGAquaRecordingLabel(NSMakeRect(42,112,496,26),@"",[NSFont systemFontOfSize:12],NO);[root addSubview:self.statusField];
    self.spinner=[[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(282,86,16,16)] autorelease];
    [self.spinner setStyle:NSProgressIndicatorSpinningStyle];[self.spinner setDisplayedWhenStopped:NO];[root addSubview:self.spinner];
    self.cancelButton=TGAquaRecordingButton(NSMakeRect(24,26,124,34),TGLoc(@"cancel"),self,@selector(cancelPressed:),NO);
    [self.cancelButton setKeyEquivalent:@"\e"];[self.cancelButton setKeyEquivalentModifierMask:0];[root addSubview:self.cancelButton];
    self.retryButton=TGAquaRecordingButton(NSMakeRect(160,26,124,34),TGLoc(@"videoNote.retry"),self,@selector(retryPressed:),NO);[root addSubview:self.retryButton];
    self.playButton=TGAquaRecordingButton(NSMakeRect(296,26,124,34),TGLoc(@"play"),self,@selector(playPressed:),NO);[root addSubview:self.playButton];
    self.recordButton=TGAquaRecordingButton(NSMakeRect(432,26,124,34),TGLoc(@"videoNote.record"),self,@selector(recordPressed:),YES);[root addSubview:self.recordButton];
    self.stopButton=TGAquaRecordingButton(NSMakeRect(432,26,124,34),TGLoc(@"videoNote.stop"),self,@selector(stopPressed:),YES);[root addSubview:self.stopButton];
    self.sendButton=TGAquaRecordingButton(NSMakeRect(432,26,124,34),TGLoc(@"send"),self,@selector(sendPressed:),YES);[self.sendButton setKeyEquivalent:@"\r"];[self.sendButton setKeyEquivalentModifierMask:0];[root addSubview:self.sendButton];
    [self showReadyToRecordControls];
}
