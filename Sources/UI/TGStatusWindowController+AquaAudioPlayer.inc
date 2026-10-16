static NSDictionary *TGMediaCenterFirstMediaDictionaryForItem(TGMessageItem *item);
- (BOOL)isAquaAudioPlayerVisible {
    return TGInterfaceDesignIsAqua() && [self.currentAuthState isEqualToString:@"ready"] && self.aquaAudioPlayerView && ![self.aquaAudioPlayerView isHidden];
}
- (void)aquaAudioPlayerPresentationChanged:(id)sender { (void)sender; [self layoutContentView]; }
- (void)layoutAquaAudioPlayerForContentBounds:(NSRect)bounds {
    if (!self.aquaAudioPlayerView || [self.mediaPlaybackPlayPauseButton superview] != [self.aquaAudioPlayerView surface]) return;
    [self.aquaAudioPlayerView setFrame:TGAquaAudioPlayerFrame(bounds)];
    NSArray *frames=TGAquaAudioPlayerControlFrames(NSWidth(bounds));
    NSArray *controls=[NSArray arrayWithObjects:self.mediaPlaybackPlayPauseButton,self.aquaAudioNextButton,self.mediaPlaybackTitleField,self.mediaPlaybackProgressSlider,self.mediaPlaybackTimeField,self.mediaPlaybackRatePopUpButton,self.aquaAudioCloseButton,nil];
    NSUInteger index=0;
    for (NSView *view in controls) { [view setAutoresizingMask:NSViewNotSizable]; [view setFrame:[[frames objectAtIndex:index++] rectValue]]; }
    TGMessageItem *next=TGNextSequentialAudioMessageItem(self.messageItems,self.mediaPlaybackSourceMessageItem);
    [self.aquaAudioNextButton setEnabled:(next!=nil && [[self.mediaPlaybackSourceMessageItem chatID] isEqual:self.selectedChatID])];
}
- (void)presentAquaAudioPlayer {
    if (!self.aquaAudioPlayerView) {
        self.aquaAudioPlayerView=[[[TGAquaAudioPlayerView alloc] initWithFrame:TGAquaAudioPlayerFrame([[[self window] contentView] bounds])] autorelease];
        [self.aquaAudioPlayerView setLayoutTarget:self]; [self.aquaAudioPlayerView setLayoutAction:@selector(aquaAudioPlayerPresentationChanged:)];
        [[[self window] contentView] addSubview:self.aquaAudioPlayerView positioned:NSWindowBelow relativeTo:self.aquaToolbarView];
        NSButton *next=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
        TGAquaUtilityButtonCell *nextCell=[[[TGAquaUtilityButtonCell alloc] initTextCell:@""] autorelease];
        [nextCell setIconAssetName:@"next"]; [next setCell:nextCell]; [next setBordered:NO];
        [next setTarget:self]; [next setAction:@selector(aquaAudioNext:)];
        [next setToolTip:TGLoc(@"media.playback.next")];
        self.aquaAudioNextButton=next; [[self.aquaAudioPlayerView surface] addSubview:next];
        NSButton *close=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
        TGAquaUtilityButtonCell *closeCell=[[[TGAquaUtilityButtonCell alloc] initTextCell:@""] autorelease];
        [closeCell setIconAssetName:@"cross"]; [close setCell:closeCell]; [close setBordered:NO];
        [close setTarget:self]; [close setAction:@selector(closeAquaAudioPlayer:)];
        [close setToolTip:TGLoc(@"media.playback.close")];
        self.aquaAudioCloseButton=close; [[self.aquaAudioPlayerView surface] addSubview:close];
    }
    for (NSView *view in [NSArray arrayWithObjects:self.mediaPlaybackPlayPauseButton,self.mediaPlaybackTitleField,self.mediaPlaybackProgressSlider,self.mediaPlaybackTimeField,self.mediaPlaybackRatePopUpButton,nil]) {
        if ([view superview]!=[self.aquaAudioPlayerView surface]) { [view removeFromSuperview]; [[self.aquaAudioPlayerView surface] addSubview:view]; }
        [view setHidden:NO];
    }
    NSDictionary *audioMedia=TGMediaCenterFirstMediaDictionaryForItem(self.mediaPlaybackSourceMessageItem);
    NSData *artworkData=TGMediaItemMiniThumbnailData(audioMedia);
    NSImage *artwork=[artworkData length]>0 && [artworkData length]<=1024*1024 ? [[[NSImage alloc] initWithData:artworkData] autorelease] : nil;
    [self.aquaAudioPlayerView setArtworkImage:artwork ? artwork : TGIconAssetImageNamed(@"headphones")];
    [[self.mediaPlaybackTitleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [self.mediaPlaybackTitleField setToolTip:[self.mediaPlaybackTitleField stringValue]];
    [self.mediaPlaybackWindow orderOut:nil];
    [self layoutAquaAudioPlayerForContentBounds:[[[self window] contentView] bounds]];
    [self.aquaAudioPlayerView setPresented:YES animated:YES]; [self layoutContentView];
}
- (void)detachAquaAudioPlayerAnimated:(BOOL)animated {
    if (!self.aquaAudioPlayerView) return;
    [self.aquaAudioPlayerView setPresented:NO animated:animated];
    for (NSView *view in [NSArray arrayWithObjects:self.mediaPlaybackPlayPauseButton,self.mediaPlaybackTitleField,self.mediaPlaybackProgressSlider,self.mediaPlaybackTimeField,self.mediaPlaybackRatePopUpButton,nil]) {
        if ([view superview]==[self.aquaAudioPlayerView surface]) { [view removeFromSuperview]; [[self.mediaPlaybackWindow contentView] addSubview:view]; }
    }
    [self layoutContentView];
}
- (void)closeAquaAudioPlayer:(id)sender {
    (void)sender; [self cancelMediaPlaybackPreparation]; [self resetMediaPlaybackState];
    self.mediaPlaybackSourceMessageItem=nil;
}
- (void)aquaAudioNext:(id)sender {
    (void)sender;
    if (![[self.mediaPlaybackSourceMessageItem chatID] isEqual:self.selectedChatID]) return;
    TGMessageItem *next=TGNextSequentialAudioMessageItem(self.messageItems,self.mediaPlaybackSourceMessageItem);
    if (next) [self openPlayableMediaForMessageItem:next];
}
