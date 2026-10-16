/* Aqua has a single profile identity and tab bar. Reuse the existing media
   data flow, file actions and pagination without presenting its old shell. */
- (void)layoutAquaChatInfoMedia {
    if (![self isAquaChatInfoPanelActive] || !self.mediaCenterPanelView) return;
    NSView *host=[self.aquaChatInfoPanel mediaHostView];
    [self.mediaCenterPanelView setFrame:[host bounds]];
    [self.mediaCenterPanelView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    for (NSView *view in [NSArray arrayWithObjects:self.mediaCenterContentCardView,self.mediaCenterBackButton,self.mediaCenterAvatarView,self.mediaCenterTitleField,self.mediaCenterSubtitleField,nil]) [view setHidden:YES];
    for (NSView *view in self.mediaCenterTabButtons) [view setHidden:YES];
    NSRect bounds=[host bounds]; CGFloat width=NSWidth(bounds), height=NSHeight(bounds);
    [self.mediaCenterStatusField setFrame:NSMakeRect(12,MAX(0,height-42),MAX(0,width-66),34)];
    [[self.mediaCenterStatusField cell] setWraps:YES]; [[self.mediaCenterStatusField cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [self.mediaCenterStatusField setFont:[NSFont systemFontOfSize:10]];
    [self.mediaCenterRefreshButton setFrame:NSMakeRect(MAX(0,width-44),MAX(0,height-40),32,30)];
    NSClipView *clip=[self.mediaCenterScrollView contentView];
    BOOL posts=[clip postsBoundsChangedNotifications]; NSPoint origin=[clip bounds].origin;
    [clip setPostsBoundsChangedNotifications:NO];
    [self.mediaCenterScrollView setFrame:NSMakeRect(4,4,MAX(0,width-8),MAX(0,height-52))];
    [self.mediaCenterScrollView setAutohidesScrollers:YES];
    TGAquaMediaCenterReflowResults(self.mediaCenterResultsView,NSWidth([clip bounds]),
        TGMediaCenterSelectionUsesGrid([self mediaCenterCurrentTabIndex]),[self.mediaCenterItems count]==0);
    origin.x=0; origin.y=MIN(origin.y,MAX(0,NSHeight([self.mediaCenterResultsView frame])-NSHeight([clip bounds])));
    [clip scrollToPoint:origin]; [self.mediaCenterScrollView reflectScrolledClipView:clip];
    [clip setPostsBoundsChangedNotifications:posts];
    [self.mediaCenterLoadingSpinner setFrame:NSMakeRect(MAX(0,(width-24)/2),MAX(0,(height-24)/2),24,24)];
}
