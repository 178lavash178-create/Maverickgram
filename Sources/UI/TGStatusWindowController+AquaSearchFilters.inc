// Expanded filters belong to the current search, rather than an unrelated modal.
static char TGAquaSearchFiltersKey;
- (NSMutableDictionary *)aquaSearchFilterState {
    NSMutableDictionary *state=objc_getAssociatedObject(self,&TGAquaSearchFiltersKey);
    if(!state) {
        state=[NSMutableDictionary dictionary];
        objc_setAssociatedObject(self,&TGAquaSearchFiltersKey,state,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return state;
}
- (BOOL)aquaSearchFiltersExpanded {
    return [[[self aquaSearchFilterState] objectForKey:@"expanded"] boolValue];
}
- (void)ensureAquaSearchFilterControls {
    NSMutableDictionary *state=[self aquaSearchFilterState];
    if([state objectForKey:@"view"]) return;
    NSScrollView *scroll=[[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];
    [scroll setDrawsBackground:NO]; [scroll setBorderType:NSNoBorder];
    [scroll setHasVerticalScroller:YES]; [scroll setAutohidesScrollers:YES];
    NSView *view=[[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
    [scroll setDocumentView:view];
    [state setObject:scroll forKey:@"view"]; [state setObject:view forKey:@"content"];
    NSArray *keys=[NSArray arrayWithObjects:@"senderLabel",@"periodLabel",@"fromLabel",@"toLabel",nil];
    for(NSString *key in keys) {
        NSTextField *label=[self labelWithFrame:NSZeroRect text:@"" font:[NSFont systemFontOfSize:11]];
        [view addSubview:label]; [state setObject:label forKey:key];
    }
    NSComboBox *sender=[[[NSComboBox alloc] initWithFrame:NSZeroRect] autorelease];
    [sender setFont:[NSFont systemFontOfSize:12]]; [sender setCompletes:YES];
    [sender setTarget:self]; [sender setAction:@selector(applyAquaSearchFilters:)];
    [sender setDelegate:(id)self]; [view addSubview:sender]; [state setObject:sender forKey:@"sender"];
    NSPopUpButton *period=[[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO] autorelease];
    [period setFont:[NSFont systemFontOfSize:12]]; [period setTarget:self];
    [period setAction:@selector(applyAquaSearchFilters:)]; [view addSubview:period]; [state setObject:period forKey:@"period"];
    for(NSString *key in [NSArray arrayWithObjects:@"from",@"to",nil]) {
        NSDatePicker *picker=[[[NSDatePicker alloc] initWithFrame:NSZeroRect] autorelease];
        [picker setDatePickerStyle:NSTextFieldAndStepperDatePickerStyle];
        [picker setDatePickerElements:NSYearMonthDayDatePickerElementFlag];
        [picker setFont:[NSFont systemFontOfSize:11]];
        [picker setDateValue:[NSDate date]];
        [picker setTarget:self]; [picker setAction:@selector(applyAquaSearchFilters:)];
        [view addSubview:picker]; [state setObject:picker forKey:key];
    }
    NSButton *reset=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [reset setTarget:self]; [reset setAction:@selector(resetAquaSearchFilters:)];
    [self applyUtilityButtonStyle:reset]; [self installAquaTextCellOnButton:reset accented:NO];
    [view addSubview:reset]; [state setObject:reset forKey:@"reset"];
    [[[self window] contentView] addSubview:scroll]; [scroll setHidden:YES];
}
- (void)refreshAquaSearchFilterControls {
    NSMutableDictionary *state=[self aquaSearchFilterState];
    if(![state objectForKey:@"view"]) return;
    [[state objectForKey:@"senderLabel"] setStringValue:TGLoc(@"search.messages.sender")];
    [[state objectForKey:@"periodLabel"] setStringValue:TGLoc(@"search.messages.date")];
    [[state objectForKey:@"fromLabel"] setStringValue:TGLoc(@"search.messages.from")];
    [[state objectForKey:@"toLabel"] setStringValue:TGLoc(@"search.messages.to")];
    [[state objectForKey:@"reset"] setTitle:TGLoc(@"search.messages.reset")];
    NSLocale *locale=[[[NSLocale alloc] initWithLocaleIdentifier:TGLanguageCode()] autorelease];
    [[state objectForKey:@"from"] setLocale:locale]; [[state objectForKey:@"to"] setLocale:locale];
    NSComboBox *sender=[state objectForKey:@"sender"];
    if(![sender currentEditor]) [sender setStringValue:self.searchSenderQuery ? self.searchSenderQuery : @""];
    [sender setToolTip:TGLoc(@"search.messages.senderPlaceholder")];
    NSMutableArray *names=[NSMutableArray array];
    for(TGMessageItem *item in self.messageItems) {
        NSString *name=[item senderDisplayName];
        if([name length] && ![names containsObject:name]) [names addObject:name];
    }
    if(![sender currentEditor]) { [sender removeAllItems]; [sender addItemsWithObjectValues:names]; [sender setStringValue:self.searchSenderQuery ? self.searchSenderQuery : @""]; }
    NSPopUpButton *period=[state objectForKey:@"period"];
    [period removeAllItems];
    for(NSString *key in [NSArray arrayWithObjects:@"search.messages.dateAny",@"search.messages.dateToday",@"search.messages.dateWeek",@"search.messages.dateMonth",@"search.messages.dateCustom",nil])
        [period addItemWithTitle:TGLoc(key)];
    BOOL custom=[[state objectForKey:@"custom"] boolValue];
    [period selectItemAtIndex:custom ? 4 : MAX(0,MIN(3,self.searchDateRangeIndex))];
    [[state objectForKey:@"from"] setEnabled:custom]; [[state objectForKey:@"to"] setEnabled:custom];
}
- (void)toggleAquaSearchFilters:(id)sender {
    (void)sender;
    [self ensureAquaSearchFilterControls];
    NSMutableDictionary *state=[self aquaSearchFilterState];
    [state setObject:[NSNumber numberWithBool:![self aquaSearchFiltersExpanded]] forKey:@"expanded"];
    [self refreshAquaSearchFilterControls]; [self layoutContentView];
}
- (void)applyAquaSearchFilters:(id)sender {
    (void)sender;
    NSMutableDictionary *state=[self aquaSearchFilterState];
    self.searchSenderQuery=[[[state objectForKey:@"sender"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSInteger range=[[state objectForKey:@"period"] indexOfSelectedItem];
    BOOL custom=range==4; self.searchDateRangeIndex=custom ? 0 : range;
    [state setObject:[NSNumber numberWithBool:custom] forKey:@"custom"];
    if(custom) {
        NSDate *from=[[state objectForKey:@"from"] dateValue], *to=[[state objectForKey:@"to"] dateValue];
        // Keep the range valid when either edge is edited. Calendar boundaries
        // below include the whole last day, also across daylight-saving changes.
        if([from compare:to]==NSOrderedDescending) {
            if(sender==[state objectForKey:@"from"]) [[state objectForKey:@"to"] setDateValue:from];
            else [[state objectForKey:@"from"] setDateValue:to];
        }
    }
    BOOL active=custom || self.searchDateRangeIndex>0 || [self.searchSenderQuery length]>0;
    [self.searchAdvancedButton setTitle:TGLoc(active ? @"search.messages.filtersActive" : @"search.messages.filters")];
    [self refreshAquaSearchFilterControls]; [self performSearchReset:YES];
}
- (void)resetAquaSearchFilters:(id)sender {
    (void)sender; self.searchSenderQuery=nil; self.searchDateRangeIndex=0;
    [[self aquaSearchFilterState] removeObjectForKey:@"custom"];
    [self.searchAdvancedButton setTitle:TGLoc(@"search.messages.filters")];
    [self refreshAquaSearchFilterControls]; [self performSearchReset:YES];
}
- (BOOL)messageMatchesAquaSearchDate:(TGMessageItem *)item {
    NSDictionary *state=[self aquaSearchFilterState];
    if(!TGInterfaceDesignIsAqua() || ![[state objectForKey:@"custom"] boolValue]) return YES;
    NSCalendar *calendar=[NSCalendar currentCalendar];
    NSUInteger units=NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit;
    NSDate *start=[calendar dateFromComponents:[calendar components:units fromDate:[[state objectForKey:@"from"] dateValue]]];
    NSDate *end=[calendar dateFromComponents:[calendar components:units fromDate:[[state objectForKey:@"to"] dateValue]]];
    NSDateComponents *day=[[[NSDateComponents alloc] init] autorelease]; [day setDay:1];
    end=[calendar dateByAddingComponents:day toDate:end options:0];
    NSTimeInterval timestamp=[[item date] doubleValue];
    return timestamp>0 && timestamp>=[start timeIntervalSince1970] && timestamp<[end timeIntervalSince1970];
}
- (CGFloat)aquaSearchFilterHeightForWidth:(CGFloat)width availableHeight:(CGFloat)height {
    if(!TGInterfaceDesignIsAqua() || ![self aquaSearchFiltersExpanded]) return 0;
    // Compact view still scrolls its contents rather than covering the transcript.
    CGFloat minimum=(!self.chatTitleSearchOnly && !self.searchInlineCurrentChatOnly && width<380) ? 332.0 : 304.0;
    return MIN(width<346 ? 166.0 : (width<406 ? 132.0 : 98.0),MAX(0.0,height-minimum));
}
- (void)layoutAquaSearchFiltersInRect:(NSRect)rect visible:(BOOL)visible {
    NSMutableDictionary *state=[self aquaSearchFilterState];
    NSView *view=[state objectForKey:@"view"];
    [view setHidden:!visible || NSHeight(rect)<1];
    if(!visible || !view) return;
    [view setFrame:rect];
    CGFloat w=NSWidth(rect)-16,h=w<310 ? 166.0 : (w<370 ? 132.0 : 98.0),gap=10;
    NSView *content=[state objectForKey:@"content"];
    [content setFrame:NSMakeRect(0,0,w,h)];
    [(NSScrollView *)view tile];
    [content scrollRectToVisible:NSMakeRect(0,MAX(0,h-NSHeight(rect)),1,NSHeight(rect))];
    CGFloat half=floor((w-gap)/2);
    [[state objectForKey:@"senderLabel"] setFrame:NSMakeRect(0,h-15,half,15)];
    [[state objectForKey:@"periodLabel"] setFrame:NSMakeRect(half+gap,h-15,half,15)];
    [[state objectForKey:@"sender"] setFrame:NSMakeRect(0,h-44,half,27)];
    [[state objectForKey:@"period"] setFrame:NSMakeRect(half+gap,h-44,half,27)];
    BOOL narrow=w<370,stackDates=w<310; CGFloat resetWidth=80,datesWidth=narrow ? w : w-resetWidth-gap;
    CGFloat dateWidth=MAX(64,floor((datesWidth-44-gap)/2));
    [[state objectForKey:@"fromLabel"] setFrame:NSMakeRect(0,h-77,20,17)];
    [[state objectForKey:@"from"] setFrame:NSMakeRect(22,h-82,dateWidth,26)];
    CGFloat toX=22+dateWidth+gap;
    [[state objectForKey:@"toLabel"] setFrame:NSMakeRect(toX,h-77,20,17)];
    [[state objectForKey:@"to"] setFrame:NSMakeRect(toX+22,h-82,dateWidth,26)];
    if(stackDates) {
        [[state objectForKey:@"from"] setFrame:NSMakeRect(22,h-82,w-22,26)];
        [[state objectForKey:@"toLabel"] setFrame:NSMakeRect(0,h-109,20,17)];
        [[state objectForKey:@"to"] setFrame:NSMakeRect(22,h-114,w-22,26)];
    }
    [[state objectForKey:@"reset"] setFrame:NSMakeRect(w-resetWidth,stackDates ? h-147 : (narrow ? h-115 : h-82),resetWidth,26)];
}
