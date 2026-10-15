// Optional Aqua folder presentation. Both hosts reuse the same live controls.
- (void)configureAquaFolderDrawer {
    self.aquaFolderDrawer = [[[TGAquaFolderDrawer alloc] initWithParentWindow:[self window]
        folderScrollView:self.drawerFolderScrollView editTarget:self
        editAction:@selector(showChatFolderManagementWindow:)] autorelease];
    self.aquaFolderDrawerRequestedOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"TGAquaFolderDrawerOpen"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aquaFolderPresentationChanged:)
        name:TGAquaFolderPresentationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aquaFolderDrawerPlacementChanged:)
        name:TGAquaFolderDrawerPlacementDidChangeNotification object:self.aquaFolderDrawer];
}

- (BOOL)aquaUsesExternalFolderDrawer {
    return TGInterfaceDesignIsAqua() && TGAquaFoldersUseDrawer() && [self.aquaFolderDrawer canShowExternally];
}

- (BOOL)aquaFolderListExpanded {
    return TGAquaFoldersUseDrawer() ? self.aquaFolderDrawerRequestedOpen : !self.aquaFoldersCollapsed;
}

- (void)toggleAquaFolders:(id)sender {
    (void)sender;
    if (!TGInterfaceDesignIsAqua()) return;
    if (TGAquaFoldersUseDrawer()) {
        self.aquaFolderDrawerRequestedOpen = !self.aquaFolderDrawerRequestedOpen;
        [[NSUserDefaults standardUserDefaults] setBool:self.aquaFolderDrawerRequestedOpen forKey:@"TGAquaFolderDrawerOpen"];
    } else {
        self.aquaFoldersCollapsed = !self.aquaFoldersCollapsed;
        [[NSUserDefaults standardUserDefaults] setBool:self.aquaFoldersCollapsed forKey:@"TGAquaFoldersCollapsed"];
    }
    [self layoutContentView]; [self updateVisibleSection];
}

- (void)aquaFolderPresentationChanged:(NSNotification *)notification {
    (void)notification;
    if (!TGInterfaceDesignIsAqua()) return;
    [self.aquaFolderDrawer setVisible:NO];
    [self refreshInterfaceDesignControls];
    [self layoutContentView]; [self updateVisibleSection];
}

- (void)aquaFolderDrawerPlacementChanged:(NSNotification *)notification {
    (void)notification;
    if (!TGInterfaceDesignIsAqua()) return;
    [self layoutContentView]; [self updateVisibleSection];
}

- (void)layoutAquaFolderListInFrame:(NSRect)frame {
    [self.aquaFolderDrawer setFolderButtons:self.drawerFolderButtons];
    if ([self aquaUsesExternalFolderDrawer]) {
        [self.aquaFolderDrawer attachFolderScrollView];
        [self.aquaFolderDrawer layout];
        return;
    }
    [self.aquaFolderDrawer detachFolderScrollView];
    NSView *content = [[self window] contentView];
    [content addSubview:self.drawerFolderScrollView positioned:NSWindowAbove relativeTo:nil];
    [self.drawerFolderScrollView setFrame:frame];
    CGFloat width = NSWidth([[self.drawerFolderScrollView contentView] bounds]);
    CGFloat height = MAX(NSHeight(frame), [self.drawerFolderButtons count]*32.0);
    [self.drawerFolderContentView setFrame:NSMakeRect(0,0,width,height)];
    NSUInteger index = 0;
    for (NSButton *button in self.drawerFolderButtons) [button setFrame:NSMakeRect(0,index++*32.0,width,32)];
    NSClipView *clip = [self.drawerFolderScrollView contentView];
    NSPoint origin = [clip bounds].origin;
    [clip setBoundsOrigin:NSMakePoint(0,MIN(MAX(0,origin.y),MAX(0,height-NSHeight([clip bounds]))))];
    [self.drawerFolderScrollView reflectScrolledClipView:clip];
}
