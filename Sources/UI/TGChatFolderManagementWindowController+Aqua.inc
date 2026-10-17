/* Flat Aqua editor; data, mutations, drag ordering and Classic stay in the owner. */
- (NSTextField *)aquaFolderLabel:(NSString *)key text:(NSString *)text {
    NSTextField *field=[self labelWithFrame:NSZeroRect font:[NSFont boldSystemFontOfSize:12]
                                  surface:TGThemeSurfaceCard detail:NO];
    [field setStringValue:text]; [self.aquaViews setObject:field forKey:key];
    [TGUtilityWindowContentView([self window]) addSubview:field]; return field;
}
- (NSScrollView *)aquaFolderScrollWithTable:(NSTableView *)table key:(NSString *)key {
    NSScrollView *scroll=[[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];
    [scroll setBorderType:NSNoBorder]; [scroll setHasVerticalScroller:YES];
    [scroll setAutohidesScrollers:YES]; [scroll setDrawsBackground:YES];
    [scroll setBackgroundColor:TGClassicTablePaperColor()];
    [table setBackgroundColor:TGClassicTablePaperColor()];[table setFocusRingType:NSFocusRingTypeNone];[table setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];[table setGridStyleMask:NSTableViewGridNone]; [scroll setDocumentView:table];
    [self.aquaViews setObject:scroll forKey:key]; [TGUtilityWindowContentView([self window]) addSubview:scroll]; return scroll;
}
- (void)buildAquaViews {
    TGAquaUtilityWindowView *root=[[[TGAquaUtilityWindowView alloc] initWithFrame:[TGUtilityWindowContentView([self window]) bounds]] autorelease];
    [root setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable]; [[self window] setContentView:root];
    self.aquaViews=[NSMutableDictionary dictionary]; [[self window] setDelegate:(id)self];
    [[self aquaFolderLabel:@"heading" text:TGLoc(@"folders.manage.title")] setFont:[NSFont boldSystemFontOfSize:14]];
    NSArray *keys=[NSArray arrayWithObjects:@"folderLabel",@"nameLabel",@"includeLabel",@"excludeLabel",@"chatLabel",nil];
    NSArray *texts=[NSArray arrayWithObjects:@"folders.list",@"folders.name",@"folders.include",@"folders.exclude",@"folders.alwaysInclude",nil];
    for(NSUInteger i=0;i<[keys count];i++) [self aquaFolderLabel:[keys objectAtIndex:i] text:TGLoc([texts objectAtIndex:i])];
    NSArray *assets=[NSArray arrayWithObjects:@"upload",@"folder-add",@"folder-remove",@"folder-share",@"refresh",nil];
    NSArray *tips=[NSArray arrayWithObjects:@"folders.import",@"folders.add",@"folders.delete",@"folders.share",@"folders.refresh",nil];
    SEL actions[]={@selector(importFolder:),@selector(addFolder:),@selector(deleteFolder:),@selector(shareFolder:),@selector(refreshAction:)};
    NSMutableArray *toolbar=[NSMutableArray array];
    for(NSUInteger i=0;i<[assets count];i++) {NSButton *button=[self iconButtonWithFrame:NSZeroRect assetName:[assets objectAtIndex:i] toolTip:TGLoc([tips objectAtIndex:i]) action:actions[i]];[root addSubview:button];[toolbar addObject:button];}
    self.importButton=[toolbar objectAtIndex:0];self.addButton=[toolbar objectAtIndex:1];self.deleteButton=[toolbar objectAtIndex:2];self.shareButton=[toolbar objectAtIndex:3];self.refreshButton=[toolbar objectAtIndex:4];
    self.folderTableView=[[[TGFolderSourceListView alloc] initWithFrame:NSZeroRect] autorelease];
    [self.folderTableView setDataSource:self];[self.folderTableView setDelegate:self];[self.folderTableView setHeaderView:nil];
    [self.folderTableView setRowHeight:42];[self.folderTableView setIntercellSpacing:NSZeroSize];
    [self.folderTableView setAllowsMultipleSelection:NO];[self.folderTableView setAllowsEmptySelection:YES];
    [self.folderTableView setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle];
    [self.folderTableView registerForDraggedTypes:[NSArray arrayWithObject:TGChatFolderDragPasteboardType]];
    [self.folderTableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    NSTableColumn *folder=[[[NSTableColumn alloc] initWithIdentifier:@"folder"] autorelease];
    [folder setDataCell:[[[TGChatFolderListCell alloc] initTextCell:@""] autorelease]];[self.folderTableView addTableColumn:folder];
    [self aquaFolderScrollWithTable:self.folderTableView key:@"folderScroll"];
    NSBox *divider=[[[NSBox alloc] initWithFrame:NSZeroRect] autorelease];[divider setBoxType:NSBoxSeparator];[root addSubview:divider];[self.aquaViews setObject:divider forKey:@"divider"];
    self.titleField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [[self.titleField cell] setPlaceholderString:TGLoc(@"folders.name.placeholder")];[self.titleField setDelegate:self];[root addSubview:self.titleField];
    NSArray *includeKeys=[NSArray arrayWithObjects:@"folders.contacts",@"folders.nonContacts",@"folders.bots",@"folders.groups",@"folders.channels",nil];
    NSMutableArray *include=[NSMutableArray array];for(NSString *key in includeKeys){NSButton *button=[self checkButtonWithFrame:NSZeroRect title:TGLoc(key)];[root addSubview:button];[include addObject:button];}
    self.includeContactsButton=[include objectAtIndex:0];self.includeNonContactsButton=[include objectAtIndex:1];self.includeBotsButton=[include objectAtIndex:2];self.includeGroupsButton=[include objectAtIndex:3];self.includeChannelsButton=[include objectAtIndex:4];
    NSArray *excludeKeys=[NSArray arrayWithObjects:@"folders.muted",@"folders.read",@"folders.archived",nil];
    NSMutableArray *exclude=[NSMutableArray array];for(NSString *key in excludeKeys){NSButton *button=[self checkButtonWithFrame:NSZeroRect title:TGLoc(key)];[root addSubview:button];[exclude addObject:button];}
    self.excludeMutedButton=[exclude objectAtIndex:0];self.excludeReadButton=[exclude objectAtIndex:1];self.excludeArchivedButton=[exclude objectAtIndex:2];
    self.chatSearchField=[[[NSSearchField alloc] initWithFrame:NSZeroRect] autorelease];[[self.chatSearchField cell] setPlaceholderString:TGLoc(@"folders.searchChats")];[self.chatSearchField setDelegate:(id)self];[root addSubview:self.chatSearchField];
    self.chatTableView=[[[TGFolderSourceListView alloc] initWithFrame:NSZeroRect] autorelease];[self.chatTableView setDataSource:self];[self.chatTableView setDelegate:self];[self.chatTableView setHeaderView:nil];
    [self.chatTableView setRowHeight:38];[self.chatTableView setIntercellSpacing:NSZeroSize];[self.chatTableView setAllowsMultipleSelection:NO];
    NSTableColumn *included=[[[NSTableColumn alloc] initWithIdentifier:@"included"] autorelease];[included setWidth:30];[included setMinWidth:30];[included setMaxWidth:30];[included setEditable:YES];
    NSButtonCell *check=[[[NSButtonCell alloc] init] autorelease];[check setButtonType:NSSwitchButton];[check setTitle:@""];[included setDataCell:check];[self.chatTableView addTableColumn:included];
    NSTableColumn *chat=[[[NSTableColumn alloc] initWithIdentifier:@"chat"] autorelease];[chat setDataCell:[[[TGChatFolderChatCell alloc] initTextCell:@""] autorelease]];[self.chatTableView addTableColumn:chat];
    [self aquaFolderScrollWithTable:self.chatTableView key:@"chatScroll"];
    self.statusField=[self labelWithFrame:NSZeroRect font:[NSFont systemFontOfSize:11] surface:TGThemeSurfaceWindow detail:YES];[root addSubview:self.statusField];
    self.spinner=[[[NSProgressIndicator alloc] initWithFrame:NSZeroRect] autorelease];[self.spinner setStyle:NSProgressIndicatorSpinningStyle];[self.spinner setControlSize:NSSmallControlSize];[self.spinner setDisplayedWhenStopped:NO];[root addSubview:self.spinner];
    self.saveButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[self.saveButton setCell:[[[TGPrimaryTextButtonCell alloc] initTextCell:TGLoc(@"folders.save")] autorelease]];[self.saveButton setTitle:TGLoc(@"folders.save")];[self.saveButton setTarget:self];[self.saveButton setAction:@selector(saveFolder:)];[root addSubview:self.saveButton];
    /* Only the editor scrolls on constrained screens; the source list and Save stay anchored. */
    NSScrollView *editorScroll=[[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];
    [editorScroll setBorderType:NSNoBorder];[editorScroll setHasVerticalScroller:YES];[editorScroll setAutohidesScrollers:YES];[editorScroll setDrawsBackground:NO];
    NSView *document=[[[NSView alloc] initWithFrame:NSZeroRect] autorelease];[editorScroll setDocumentView:document];[root addSubview:editorScroll];
    [self.aquaViews setObject:editorScroll forKey:@"editorScroll"];[self.aquaViews setObject:document forKey:@"editorDocument"];
    NSMutableArray *editorViews=[NSMutableArray arrayWithObjects:self.titleField,self.chatSearchField,[self.aquaViews objectForKey:@"chatScroll"],nil];
    [editorViews addObjectsFromArray:include];[editorViews addObjectsFromArray:exclude];
    for(NSString *key in [NSArray arrayWithObjects:@"nameLabel",@"includeLabel",@"excludeLabel",@"chatLabel",nil])[editorViews addObject:[self.aquaViews objectForKey:key]];
    for(NSView *view in editorViews){[view retain];[view removeFromSuperview];[document addSubview:view];[view release];}
    [self layoutAquaViews];[self updateControlStates];
}
- (void)layoutAquaViews {
    if(!self.aquaViews)return;
    NSView *root=TGUtilityWindowContentView([self window]);NSSize size=[root bounds].size;CGFloat w=size.width,h=size.height;
    CGFloat header=w<500 ? 88 : 52,side=w<500 ? 140 : (w<650 ? 180 : 224);
    [(TGAquaUtilityWindowView *)root setHeaderHeight:header];
    [[self.aquaViews objectForKey:@"heading"] setFrame:NSMakeRect(20,h-34,MAX(0,w-(header>52 ? 40 : 230)),20)];
    NSArray *toolbar=[NSArray arrayWithObjects:self.importButton,self.addButton,self.deleteButton,self.shareButton,self.refreshButton,nil];
    for(NSUInteger i=0;i<[toolbar count];i++)[[toolbar objectAtIndex:i] setFrame:NSMakeRect(w-194+i*35,h-(header>52 ? 77 : 41),30,30)];
    [[self.aquaViews objectForKey:@"folderLabel"] setFrame:NSMakeRect(16,h-header-30,side-28,18)];
    [[self.aquaViews objectForKey:@"folderScroll"] setFrame:NSMakeRect(4,62,side-8,MAX(0,h-header-102))];
    [[self.aquaViews objectForKey:@"divider"] setFrame:NSMakeRect(side,54,1,MAX(0,h-header-54))];
    NSScrollView *editorScroll=[self.aquaViews objectForKey:@"editorScroll"];
    [editorScroll setFrame:NSMakeRect(side+1,54,MAX(0,w-side-1),MAX(0,h-header-54))];[editorScroll tile];
    CGFloat documentWidth=NSWidth([[editorScroll contentView] bounds]),editor=MAX(0,documentWidth-40),x=20;
    NSUInteger columns=editor>=430 ? 3 : (editor>=290 ? 2 : 1),includeRows=(5+columns-1)/columns,excludeRows=(3+columns-1)/columns;
    CGFloat column=floor((editor-8*(columns-1))/columns),documentHeight=MAX(NSHeight([[editorScroll contentView] bounds]),427+26*(includeRows-2)+26*(excludeRows-1));
    NSView *document=[self.aquaViews objectForKey:@"editorDocument"];NSPoint oldOrigin=[[editorScroll contentView] bounds].origin;CGFloat oldHeight=NSHeight([document frame]);
    [document setFrameSize:NSMakeSize(documentWidth,documentHeight)];
    /* Non-flipped documents preserve the distance from the top while resizing. */
    oldOrigin.y=MAX(0,MIN(documentHeight-NSHeight([[editorScroll contentView] bounds]),oldOrigin.y+documentHeight-oldHeight));
    [[editorScroll contentView] scrollToPoint:oldOrigin];[editorScroll reflectScrolledClipView:[editorScroll contentView]];
    [[self.aquaViews objectForKey:@"nameLabel"] setFrame:NSMakeRect(x,documentHeight-30,editor,18)];[self.titleField setFrame:NSMakeRect(x,documentHeight-61,editor,26)];
    [[self.aquaViews objectForKey:@"includeLabel"] setFrame:NSMakeRect(x,documentHeight-91,editor,18)];
    NSArray *include=[NSArray arrayWithObjects:self.includeContactsButton,self.includeNonContactsButton,self.includeBotsButton,self.includeGroupsButton,self.includeChannelsButton,nil];
    CGFloat includeY=documentHeight-118;
    for(NSUInteger i=0;i<[include count];i++)[[include objectAtIndex:i] setFrame:NSMakeRect(x+(column+8)*(i%columns),includeY-26*(i/columns),column,22)];
    CGFloat excludeLabelY=includeY-26*(includeRows-1)-30,excludeY=excludeLabelY-27;
    [[self.aquaViews objectForKey:@"excludeLabel"] setFrame:NSMakeRect(x,excludeLabelY,editor,18)];
    NSArray *exclude=[NSArray arrayWithObjects:self.excludeMutedButton,self.excludeReadButton,self.excludeArchivedButton,nil];
    for(NSUInteger i=0;i<[exclude count];i++)[[exclude objectAtIndex:i] setFrame:NSMakeRect(x+(column+8)*(i%columns),excludeY-26*(i/columns),column,22)];
    CGFloat chatLabelY=excludeY-26*(excludeRows-1)-33,searchY=chatLabelY-33;
    [[self.aquaViews objectForKey:@"chatLabel"] setFrame:NSMakeRect(x,chatLabelY,editor,18)];[self.chatSearchField setFrame:NSMakeRect(x,searchY,editor,26)];
    NSScrollView *chat=[self.aquaViews objectForKey:@"chatScroll"];[chat setFrame:NSMakeRect(x,12,editor,MAX(0,searchY-20))];[chat tile];
    [[self.chatTableView tableColumnWithIdentifier:@"chat"] setWidth:MAX(20,NSWidth([[chat contentView] bounds])-30)];
    [self.chatTableView setFrameSize:NSMakeSize(NSWidth([[chat contentView] bounds]),MAX(NSHeight([[chat contentView] bounds]),[self.chatTableView numberOfRows]*38.0))];
    NSScrollView *folders=[self.aquaViews objectForKey:@"folderScroll"];[folders tile];[[[self.folderTableView tableColumns] objectAtIndex:0] setWidth:NSWidth([[folders contentView] bounds])];
    [self.folderTableView setFrameSize:NSMakeSize(NSWidth([[folders contentView] bounds]),MAX(NSHeight([[folders contentView] bounds]),[self.folderTableView numberOfRows]*42.0))];
    [self.statusField setFrame:NSMakeRect(20,19,MAX(0,w-220),18)];[self.spinner setFrame:NSMakeRect(w-190,20,16,16)];[self.saveButton setFrame:NSMakeRect(w-156,12,136,30)];
}
- (void)windowDidResize:(NSNotification *)notification {if([notification object]==[self window])[self layoutAquaViews];}
- (void)windowDidChangeScreen:(NSNotification *)notification {if(self.aquaViews && [notification object]==[self window]){TGFitUtilityWindowToVisibleScreen([self window]);[self layoutAquaViews];}}
- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)frame {return self.aquaViews && [window screen] ? TGUtilityWindowFrameFittingVisibleFrame(frame,[[window screen] visibleFrame]) : frame;}
