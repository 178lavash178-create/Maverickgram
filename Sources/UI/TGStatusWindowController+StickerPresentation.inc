/* The Aqua picker rehosts the same controls and data used by Classic. Its
 * parent window is only the anchor; no second sticker window is presented. */
static char TGAquaStickerPresentationKey;
static NSSize TGAquaStickerPopoverSize(NSSize conversation, NSSize screen, CGFloat aboveAnchor) {
    if (!isfinite(conversation.width) || !isfinite(conversation.height) || !isfinite(screen.width) || !isfinite(aboveAnchor)) return NSZeroSize;
    CGFloat width=floor(MIN(430,MIN(conversation.width-16,screen.width-32)));
    CGFloat height=floor(MIN(330,MIN(conversation.height-70,aboveAnchor-24)));
    return width>=280 && height>=240 ? NSMakeSize(width,height) : NSZeroSize;
}
- (NSMutableDictionary *)aquaStickerPresentationState {
    return objc_getAssociatedObject(self,&TGAquaStickerPresentationKey);
}
- (NSDictionary *)stickerPickerAccountContext {
    return [NSDictionary dictionaryWithObjectsAndKeys:self.client ? (id)self.client : (id)[NSNull null],@"client",
        self.profileUserID ? (id)self.profileUserID : (id)[NSNull null],@"account",nil];
}
- (NSDictionary *)aquaStickerSelectionContext {
    return [NSDictionary dictionaryWithObjectsAndKeys:[self stickerPickerAccountContext],@"account",
        self.selectedChatID ? (id)self.selectedChatID : (id)[NSNull null],@"chat",
        self.selectedMessageThreadID ? (id)self.selectedMessageThreadID : (id)[NSNull null],@"thread",
        self.selectedMessageTopicKind ? self.selectedMessageTopicKind : @"",@"topic",
        self.activeSection ? self.activeSection : TGSectionChats,@"section",nil];
}
- (NSDictionary *)stickerPickerLoadContext {
    return TGInterfaceDesignIsAqua() ? [[self aquaStickerPresentationState] objectForKey:@"context"] : [self stickerPickerAccountContext];
}
- (BOOL)stickerPickerLoadContextIsCurrent:(NSDictionary *)context {
    if (!context || ![self.currentAuthState isEqualToString:@"ready"]) return NO;
    if (!TGInterfaceDesignIsAqua()) return [context isEqual:[self stickerPickerAccountContext]];
    return context==[[self aquaStickerPresentationState] objectForKey:@"context"] && [context isEqual:[self aquaStickerSelectionContext]];
}
- (BOOL)isStickerPickerPresentationVisible {
    if (!TGInterfaceDesignIsAqua()) return [self.stickerPickerWindow isVisible];
    return [[[self aquaStickerPresentationState] objectForKey:@"popover"] isShown];
}
- (void)configureAquaStickerPickerWithLegacyView:(NSView *)legacy panels:(NSArray *)panels removeSetButton:(NSButton *)remove {
    if (!TGInterfaceDesignIsAqua()) return;
    NSMutableDictionary *state=[NSMutableDictionary dictionary];
    NSView *host=[[[TGAquaMetalView alloc] initWithFrame:NSMakeRect(0,0,430,330)] autorelease];
    [state setObject:legacy forKey:@"legacy"]; [state setObject:host forKey:@"view"]; [state setObject:remove forKey:@"remove"];
    /* Decorative Classic cards stay in their original, hidden window. */
    for (NSView *panel in panels) [panel setHidden:YES];
    NSBox *gridBackground=[[[NSBox alloc] initWithFrame:NSZeroRect] autorelease];
    [gridBackground setBoxType:NSBoxCustom]; [gridBackground setBorderType:NSNoBorder];
    [gridBackground setFillColor:[NSColor whiteColor]]; [host addSubview:gridBackground]; [state setObject:gridBackground forKey:@"grid_background"];
    NSArray *controls=[NSArray arrayWithObjects:self.stickerPickerStatusField,self.stickerPickerRecentButton,self.stickerPickerFavoriteButton,self.stickerPickerSearchField,self.stickerPickerSetScrollView,self.stickerPickerScrollView,remove,nil];
    for (NSView *control in controls) { [control setAutoresizingMask:NSViewNotSizable]; [host addSubview:control]; }
    for (NSButton *button in [NSArray arrayWithObjects:self.stickerPickerRecentButton,self.stickerPickerFavoriteButton,nil]) {
        [self installAquaTextCellOnButton:button accented:NO]; [[button cell] setButtonType:NSToggleButton];
        [button setFont:[NSFont systemFontOfSize:11]];
    }
    NSButton *sets=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [sets setTitle:TGLoc(@"stickers.sets.tab")]; [sets setToolTip:TGLoc(@"stickers.sets.tab")];
    [sets setTarget:self]; [sets setAction:@selector(selectInstalledStickerPickerTab:)];
    [self installAquaTextCellOnButton:sets accented:NO]; [[sets cell] setButtonType:NSToggleButton];
    [host addSubview:sets]; [state setObject:sets forKey:@"sets"];
    id removeTarget=[remove target];SEL removeAction=[remove action];
    TGAquaUtilityButtonCell *removeCell=[[[TGAquaUtilityButtonCell alloc] initTextCell:@""] autorelease];
    [removeCell setIconOnly:YES];[removeCell setIconAssetName:@"folder-remove"];[remove setCell:removeCell];
    [remove setTarget:removeTarget];[remove setAction:removeAction];[remove setBordered:NO];
    NSSearchFieldCell *searchCell=[[[NSSearchFieldCell alloc] initTextCell:[self.stickerPickerSearchField stringValue]] autorelease];
    [searchCell setPlaceholderString:TGLoc(@"stickers.search.placeholder")];[self.stickerPickerSearchField setCell:searchCell];
    [self.stickerPickerSearchField setTarget:self];[self.stickerPickerSearchField setAction:@selector(searchStickerPickerByEmoji:)];
    [self.stickerPickerSearchField setFont:[NSFont systemFontOfSize:11]];
    [self.stickerPickerSetScrollView setHasHorizontalScroller:YES];[self.stickerPickerSetScrollView setAutohidesScrollers:YES];
    [self.stickerPickerSetScrollView setScrollerStyle:NSScrollerStyleOverlay];
    [self.stickerPickerScrollView setScrollerStyle:NSScrollerStyleOverlay];
    [self.stickerPickerStatusField setFont:[NSFont systemFontOfSize:10]];
    [self.stickerPickerStatusField setTextColor:TGClassicCardInkColor()];
    [[self.stickerPickerStatusField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    NSViewController *controller=[[[NSViewController alloc] initWithNibName:nil bundle:nil] autorelease];[controller setView:host];
    NSPopover *popover=[[[NSPopover alloc] init] autorelease];[popover setContentViewController:controller];
    [popover setBehavior:NSPopoverBehaviorTransient];[popover setDelegate:(id)self];
    [state setObject:popover forKey:@"popover"];
    objc_setAssociatedObject(self,&TGAquaStickerPresentationKey,state,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)layoutAquaStickerPickerForSize:(NSSize)size {
    NSDictionary *state=[self aquaStickerPresentationState];NSView *host=[state objectForKey:@"view"];
    if (!host) return;
    [host setFrameSize:size];CGFloat width=size.width,height=size.height;
    BOOL stacked=width<400;
    CGFloat tabsY=height-34,searchY=stacked ? height-62 : tabsY;
    [self.stickerPickerRecentButton setFrame:NSMakeRect(10,tabsY,82,24)];
    [self.stickerPickerFavoriteButton setFrame:NSMakeRect(94,tabsY,92,24)];
    [[state objectForKey:@"sets"] setFrame:NSMakeRect(188,tabsY,68,24)];
    [self.stickerPickerSearchField setFrame:NSMakeRect(stacked ? 10 : 266,searchY,stacked ? width-20 : width-276,24)];
    CGFloat gridTop=searchY-8;
    NSRect grid=NSMakeRect(10,80,width-20,MAX(0,gridTop-80));
    [[state objectForKey:@"grid_background"] setFrame:grid];[self.stickerPickerScrollView setFrame:grid];[self.stickerPickerScrollView tile];
    [self.stickerPickerStatusField setFrame:NSMakeRect(12,60,width-24,16)];
    [self.stickerPickerSetScrollView setFrame:NSMakeRect(8,8,MAX(0,width-52),48)];[self.stickerPickerSetScrollView tile];
    [[state objectForKey:@"remove"] setFrame:NSMakeRect(width-40,16,30,30)];
    [[[state objectForKey:@"popover"] contentViewController] setView:host];
    [[state objectForKey:@"popover"] setContentSize:size];
}
- (void)updateAquaStickerPickerTabState {
    NSButton *sets=[[self aquaStickerPresentationState] objectForKey:@"sets"];
    if (self.stickerPickerMode!=3) [[self aquaStickerPresentationState] removeObjectForKey:@"wants_sets"];
    [sets setState:self.stickerPickerMode==3 ? NSOnState : NSOffState];
    [sets setNeedsDisplay:YES];
    [[[self aquaStickerPresentationState] objectForKey:@"remove"] setEnabled:self.stickerPickerSelectedSetID!=nil];
}
- (void)selectInstalledStickerPickerTab:(id)sender {
    (void)sender;
    if ([self.stickerPickerStickerSets count]==0) {
        self.stickerPickerMode=3;self.stickerPickerSelectedSetID=nil;self.stickerPickerLoadGeneration++;
        [[self aquaStickerPresentationState] setObject:[NSNumber numberWithBool:YES] forKey:@"wants_sets"];
        self.stickerPickerItems=[NSArray array];[self.stickerPickerStatusField setStringValue:TGLoc(@"stickers.sets.loading")];
        [self updateStickerPickerSelectionState];[self rebuildStickerPickerGrid];[self reloadStickerPickerSetsIfNeeded];return;
    }
    NSUInteger index=0;
    for (NSDictionary *set in self.stickerPickerStickerSets) {
        if (self.stickerPickerSelectedSetID && [[set objectForKey:@"id"] isEqual:self.stickerPickerSelectedSetID]) break;
        index++;
    }
    if (index>=[self.stickerPickerStickerSets count]) index=0;
    NSButton *selection=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[selection setTag:(NSInteger)index];
    [self selectStickerSetFromPickerButton:selection];
}
- (void)finishAquaStickerSetLoad {
    NSMutableDictionary *state=[self aquaStickerPresentationState];
    if (![[state objectForKey:@"wants_sets"] boolValue]) return;
    [state removeObjectForKey:@"wants_sets"];
    if (self.stickerPickerMode!=3) return;
    if ([self.stickerPickerStickerSets count]) [self selectInstalledStickerPickerTab:nil];
    else [self.stickerPickerStatusField setStringValue:TGLoc(@"stickers.sets.empty")];
}
- (void)removeAquaStickerHostObservers {
    NSMutableDictionary *state=[self aquaStickerPresentationState];NSWindow *window=[state objectForKey:@"host_window"];
    if (!window) return;
    NSArray *names=[NSArray arrayWithObjects:NSWindowDidResizeNotification,NSWindowDidMoveNotification,NSWindowWillCloseNotification,NSWindowWillMiniaturizeNotification,NSWindowWillEnterFullScreenNotification,NSWindowDidChangeScreenNotification,nil];
    for (NSString *name in names) [[NSNotificationCenter defaultCenter] removeObserver:self name:name object:window];
    [state removeObjectForKey:@"host_window"];
}
- (void)finishAquaStickerPickerDismissal {
    NSMutableDictionary *state=[self aquaStickerPresentationState];
    [self removeAquaStickerHostObservers];
    if (![state objectForKey:@"context"]) return;
    [state removeObjectForKey:@"context"];[state removeObjectForKey:@"wants_sets"];
    for (NSString *key in [[[self.stickerPickerRailPreviewState allKeys] copy] autorelease]) {
        if ([[self.stickerPickerRailPreviewState objectForKey:key] isEqual:@"loading"]) [self.stickerPickerRailPreviewState removeObjectForKey:key];
    }
    self.stickerPickerLoadGeneration++;
    [self.stickerPickerPlaybackCoordinator removeAllPlayback];
    [self.stickerPickerGridThumbnailPrefetcher cancelAll];[self.stickerPickerRailThumbnailPrefetcher cancelAll];
    [self scheduleInlineMediaPlaybackRefresh];
}
- (void)popoverWillClose:(NSNotification *)notification {
    if ([notification object]==[[self aquaStickerPresentationState] objectForKey:@"popover"]) [self finishAquaStickerPickerDismissal];
}
- (void)popoverDidClose:(NSNotification *)notification {
    NSPopover *popover=[[self aquaStickerPresentationState] objectForKey:@"popover"];
    /* A late completion of an animated dismissal cannot retire a newly
     * reopened presentation of the same native popover. */
    if ([notification object]==popover && ![popover isShown]) [self finishAquaStickerPickerDismissal];
}
- (void)closeAquaStickerPicker {
    NSPopover *popover=[[self aquaStickerPresentationState] objectForKey:@"popover"];
    [popover setAnimates:NO];[popover close];[self finishAquaStickerPickerDismissal];
}
- (void)aquaStickerHostWindowDidChange:(NSNotification *)notification { (void)notification;[self closeAquaStickerPicker]; }
- (BOOL)showAquaStickerPicker {
    NSMutableDictionary *state=[self aquaStickerPresentationState];NSPopover *popover=[state objectForKey:@"popover"];
    if ([popover isShown]) { [self closeAquaStickerPicker];return NO; }
    NSButton *anchor=self.stickerButton;NSWindow *window=[self window];
    if (!popover || ![self.currentAuthState isEqualToString:@"ready"] || !self.selectedChatID || ![window isVisible] || [anchor window]!=window || [anchor isHiddenOrHasHiddenAncestor] || ![anchor isEnabled] ||
        ![(self.activeSection ? self.activeSection : TGSectionChats) isEqualToString:TGSectionChats] || self.chatNavigationClosed) return NO;
    NSScreen *screen=[window screen];if(!screen)screen=[NSScreen mainScreen];
    NSRect screenRect=[screen visibleFrame];
    NSRect anchorRect=[window convertRectToScreen:[anchor convertRect:[anchor bounds] toView:nil]];
    if (!NSIntersectsRect(anchorRect,screenRect)) return NO;
    NSSize size=TGAquaStickerPopoverSize([self.conversationPanelView bounds].size,screenRect.size,NSMaxY(screenRect)-NSMaxY(anchorRect));
    if (NSEqualSizes(size,NSZeroSize)) return NO;
    [self.stickerPickerRecentButton setState:self.stickerPickerMode==0 ? NSOnState : NSOffState];
    [self.stickerPickerFavoriteButton setState:self.stickerPickerMode==1 ? NSOnState : NSOffState];
    [self updateAquaStickerPickerTabState];
    [self layoutAquaStickerPickerForSize:size];
    [state setObject:[self aquaStickerSelectionContext] forKey:@"context"];[state setObject:window forKey:@"host_window"];
    NSArray *names=[NSArray arrayWithObjects:NSWindowDidResizeNotification,NSWindowDidMoveNotification,NSWindowWillCloseNotification,NSWindowWillMiniaturizeNotification,NSWindowWillEnterFullScreenNotification,NSWindowDidChangeScreenNotification,nil];
    for (NSString *name in names) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aquaStickerHostWindowDidChange:) name:name object:window];
    [popover setAnimates:TGInterfaceAnimationsEnabledForView(anchor)];
    @try { [popover showRelativeToRect:[anchor bounds] ofView:anchor preferredEdge:[anchor isFlipped] ? NSMinYEdge : NSMaxYEdge]; }
    @catch (NSException *exception) { (void)exception;[self closeAquaStickerPicker];return NO; }
    if (![popover isShown]) { [self closeAquaStickerPicker];return NO; }
    return YES;
}
- (BOOL)aquaStickerPickerCanSend {
    return [self isStickerPickerPresentationVisible] && [self stickerPickerLoadContextIsCurrent:[self stickerPickerLoadContext]] &&
        self.selectedChatID!=nil && !self.chatNavigationClosed && [self.stickerButton isEnabled];
}
- (void)invalidateStickerPickerPresentation {
    [self closeAquaStickerPicker];[self.stickerPickerWindow orderOut:nil];self.stickerPickerLoadGeneration++;
    self.stickerPickerItems=[NSArray array];self.stickerPickerStickerSets=[NSArray array];self.stickerPickerSelectedSetID=nil;self.stickerPickerMode=0;
    [self.stickerPickerSetCache removeAllObjects];[self.stickerPickerRailPreviewState removeAllObjects];
    [self.stickerPickerPlaybackCoordinator removeAllPlayback];[self.stickerPickerGridThumbnailPrefetcher cancelAll];[self.stickerPickerRailThumbnailPrefetcher cancelAll];
}
- (void)disposeAquaStickerPicker {
    NSPopover *popover=[[self aquaStickerPresentationState] objectForKey:@"popover"];
    [popover setDelegate:nil];[popover setAnimates:NO];[popover close];[self removeAquaStickerHostObservers];
    objc_setAssociatedObject(self,&TGAquaStickerPresentationKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
