// UI-only search navigation, sharing the existing TDLib requests and result list.
static char TGInlineSearchControlsKey;
static char TGInlineSearchJumpGenerationKey;
static char TGInlineSearchJumpPendingKey;
- (NSUInteger)inlineSearchJumpGeneration {
    return [objc_getAssociatedObject(self,&TGInlineSearchJumpGenerationKey) unsignedIntegerValue];
}
- (NSUInteger)advanceInlineSearchJumpGeneration {
    NSUInteger pending=[objc_getAssociatedObject(self,&TGInlineSearchJumpPendingKey) unsignedIntegerValue];
    if(pending && self.messageLoadingGeneration==pending) {
        self.messageLoadingGeneration++;
        self.messageLoadingIndicatorVisible=NO; [self.messageLoadingSpinner stopAnimation:self];
    }
    objc_setAssociatedObject(self,&TGInlineSearchJumpPendingKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSUInteger generation=[self inlineSearchJumpGeneration]+1;
    objc_setAssociatedObject(self,&TGInlineSearchJumpGenerationKey,[NSNumber numberWithUnsignedInteger:generation],OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return generation;
}
- (void)redrawInlineSearchMessage:(NSNumber *)messageID {
    NSUInteger row=[self indexOfMessageID:messageID inMessageItems:self.messageItems];
    if(row!=NSNotFound && row<(NSUInteger)[self.messageTableView numberOfRows])
        [self.messageTableView setNeedsDisplayInRect:[self.messageTableView rectOfRow:(NSInteger)row]];
}
- (NSView *)inlineSearchNavigationView {
    return [objc_getAssociatedObject(self,&TGInlineSearchControlsKey) objectForKey:@"view"];
}
- (void)configureInlineSearchNavigation {
    NSView *view=[[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
    NSMutableArray *buttons=[NSMutableArray array];
    SEL actions[]={@selector(previousInlineSearchResult:),@selector(nextInlineSearchResult:),@selector(returnFromInlineSearchToLatest:)};
    for(NSUInteger i=0;i<3;i++) {
        NSButton *button=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
        [button setTarget:self]; [button setAction:actions[i]]; [self applyUtilityButtonStyle:button];
        [button setFocusRingType:NSFocusRingTypeExterior]; [view addSubview:button]; [buttons addObject:button];
    }
    NSTextField *counter=[self labelWithFrame:NSZeroRect text:@"" font:[NSFont systemFontOfSize:11]];
    [counter setAlignment:NSCenterTextAlignment]; [view addSubview:counter];
    NSDictionary *controls=[NSDictionary dictionaryWithObjectsAndKeys:view,@"view",buttons,@"buttons",counter,@"counter",nil];
    objc_setAssociatedObject(self,&TGInlineSearchControlsKey,controls,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[[self window] contentView] addSubview:view]; [view setHidden:YES];
    if(TGInterfaceDesignIsAqua()) {
        [self.searchPanelView setSquareTopCorners:YES];
        for(NSButton *button in buttons) [self installAquaTextCellOnButton:button accented:NO];
        [self installAquaTextCellOnButton:self.searchAdvancedButton accented:NO];
        [self installAquaTextCellOnButton:self.searchCloseButton accented:NO];
    }
}
- (void)updateInlineSearchNavigation {
    NSDictionary *controls=objc_getAssociatedObject(self,&TGInlineSearchControlsKey);
    NSArray *buttons=[controls objectForKey:@"buttons"];
    if([buttons count]!=3) return;
    NSInteger row=[self.searchResultsTableView selectedRow]; NSUInteger count=[self.searchResultItems count];
    NSButton *previous=[buttons objectAtIndex:0], *next=[buttons objectAtIndex:1], *latest=[buttons objectAtIndex:2];
    [previous setTitle:TGLoc(@"back")]; [previous setToolTip:TGLoc(@"search.messages.previous")];
    [next setTitle:TGLoc(@"search.messages.nextShort")]; [next setToolTip:TGLoc(@"search.messages.next")];
    [latest setTitle:TGLoc(@"search.messages.returnLatest")]; [latest setToolTip:TGLoc(@"search.messages.returnLatestHint")];
    [previous setEnabled:row>0];
    BOOL more=!self.searchEndReached && !self.searchLoading && [[self.searchTextField stringValue] length]>0;
    [next setEnabled:(count>0 && row<(NSInteger)count-1) || more];
    if(more && row>=(NSInteger)count-1) [next setToolTip:TGLoc(@"search.messages.more")];
    [latest setEnabled:self.selectedChatID!=nil];
    NSString *position=[NSString stringWithFormat:TGLoc(self.searchEndReached ? @"search.messages.position" : @"search.messages.positionMore"),[NSString stringWithFormat:@"%ld",(long)(row<0 ? 0 : row+1)],[NSString stringWithFormat:@"%lu",(unsigned long)count]];
    NSTextField *counter=[controls objectForKey:@"counter"];
    [counter setStringValue:count ? position : @""]; [counter setToolTip:count ? position : nil];
    [counter setTextColor:TGClassicCardInkColor()];
    BOOL hidden=!self.searchPanelVisible || !TGInterfaceDesignIsAqua() || [self.searchPanelView isHidden];
    [[self inlineSearchNavigationView] setHidden:hidden];
    if(hidden) [[[self aquaSearchFilterState] objectForKey:@"view"] setHidden:YES];
    [self.searchStatusField setToolTip:[self.searchStatusField stringValue]];
}
- (CGFloat)layoutAquaInlineSearchInRect:(NSRect)rect {
    BOOL results=[self.searchResultItems count]>0 || self.searchLoading;
    CGFloat extra=[self aquaSearchFilterHeightForWidth:NSWidth(rect) availableHeight:NSHeight(rect)];
    NSRect baseRect=rect; baseRect.size.height=MAX(0,baseRect.size.height-extra);
    TGAquaSearchGeometry g=TGAquaSearchFrames(baseRect,self.chatTitleSearchOnly || self.searchInlineCurrentChatOnly,results);
    g.query.origin.y+=extra; g.close.origin.y+=extra; g.filter.origin.y+=extra; g.advanced.origin.y+=extra;
    if(!NSIsEmptyRect(g.scope)) g.scope.origin.y+=extra;
    g.height+=extra;
    [self layoutAquaSearchFiltersInRect:NSMakeRect(NSMinX(rect)+10,NSMinY(g.filter)-extra-2,NSWidth(rect)-20,extra)
                              visible:self.searchPanelVisible && ![self.searchPanelView isHidden] && extra>0];
    [self.searchPanelView setFrame:NSMakeRect(NSMinX(rect),NSMaxY(rect)-g.height,NSWidth(rect),g.height)];
    [self.searchTextField setFrame:g.query]; [self.searchCloseButton setFrame:g.close];
    [self.searchScopePopUpButton setFrame:g.scope]; [self.searchScopePopUpButton setHidden:NSIsEmptyRect(g.scope)];
    [self.searchFilterPopUpButton setFrame:g.filter]; [self.searchAdvancedButton setFrame:g.advanced];
    [self.searchStatusField setFrame:g.status]; [self.searchResultsScrollView setFrame:g.results];
    [self.searchResultsScrollView setHidden:[self.searchPanelView isHidden] || !results || NSHeight(g.results)<1];
    [self.searchResultsTableView setHidden:[self.searchPanelView isHidden] || !results || NSHeight(g.results)<1];
    [self.searchResultsScrollView tile];
    [[self.searchResultsTableView tableColumnWithIdentifier:@"search"] setWidth:NSWidth([[self.searchResultsScrollView contentView] bounds])];
    NSView *nav=[self inlineSearchNavigationView]; [nav setFrame:g.navigation];
    NSDictionary *controls=objc_getAssociatedObject(self,&TGInlineSearchControlsKey);
    NSArray *buttons=[controls objectForKey:@"buttons"]; CGFloat w=NSWidth(g.navigation);
    [[buttons objectAtIndex:0] setFrame:NSMakeRect(0,0,54,28)];
    [[buttons objectAtIndex:1] setFrame:NSMakeRect(58,0,54,28)];
    [[buttons objectAtIndex:2] setFrame:NSMakeRect(MAX(116,w-76),0,76,28)];
    [[controls objectForKey:@"counter"] setFrame:NSMakeRect(116,5,MAX(0,w-196),18)];
    [self updateInlineSearchNavigation];
    return NSMaxY(rect)-g.height-6;
}
- (void)previousInlineSearchResult:(id)sender {
    (void)sender; NSInteger row=[self.searchResultsTableView selectedRow];
    if(row<=0) return;
    [self.searchResultsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)(row-1)] byExtendingSelection:NO];
    [self.searchResultsTableView scrollRowToVisible:row-1]; [self activateSearchResult:self];
}
- (void)nextInlineSearchResult:(id)sender {
    (void)sender; NSInteger row=[self.searchResultsTableView selectedRow]+1;
    if(row<0 || row>=(NSInteger)[self.searchResultItems count]) {
        if(!self.searchEndReached && !self.searchLoading && [[self.searchTextField stringValue] length]>0) [self performSearchReset:NO];
        return;
    }
    [self.searchResultsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:NO];
    [self.searchResultsTableView scrollRowToVisible:row]; [self activateSearchResult:self];
}
- (void)returnFromInlineSearchToLatest:(id)sender {
    [self closeSearchPanel:sender]; [self jumpToNewestMessages:sender];
}
- (BOOL)validateMenuItem:(NSMenuItem *)item {
    SEL action=[item action];
    if(action==@selector(openChatListSearch:) || action==@selector(openChatSearch:))
        return [self.currentAuthState isEqualToString:@"ready"] && (action!=@selector(openChatSearch:) || self.selectedChatID!=nil);
    if(action==@selector(showScheduledMessages:))
        return self.client && [self.currentAuthState isEqualToString:@"ready"] && self.selectedChatID!=nil;
    if(action==@selector(scheduleMessage:) || action==@selector(sendMessageSilently:) || action==@selector(sendMessageWhenOnline:) ||
       action==@selector(sendMessageWithoutLinkPreview:) || action==@selector(sendMessageWithPreviewAboveText:) || action==@selector(sendMessageWithLinkPreviewOptions:))
        return [self.sendMessageButton isEnabled];
    return YES;
}
