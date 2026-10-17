- (void)layoutResponsiveViews {
    if(!self.responsiveLayout)return;
    NSSize size=TGUtilityRestoreResponsiveLayout(self.responsiveLayout);CGFloat w=size.width,h=size.height;
    [self.titleField setFrame:NSMakeRect(24,h-50,w-260,28)];
    // The title and timer get separate rows; neither is a canvas for another
    // control when the user narrows the window.
    [self.membersLabel setFrame:NSMakeRect(38,h-218,w-76,18)];
    [TGUtilityResponsiveView(self.responsiveLayout,@"autoDeleteLabel") setFrame:NSMakeRect(38,h-250,128,18)];
    [self.autoDeletePopUpButton setFrame:NSMakeRect(174,h-256,152,28)];
    [self.applyAutoDeleteButton setFrame:NSMakeRect(338,h-256,MIN(158,w-372),28)];
    [self.memberScrollView setFrame:NSMakeRect(34,190,w-68,MAX(36,h-454))];
    CGFloat contactWidth=MAX(160,w-278);
    [self.contactPopUpButton setFrame:NSMakeRect(34,150,contactWidth,28)];
    [self.addButton setFrame:NSMakeRect(46+contactWidth,150,104,28)];
    [self.rolePopUpButton setFrame:NSMakeRect(w-312,112,154,28)];
    [self.applyRoleButton setFrame:NSMakeRect(w-150,112,116,28)];
    CGFloat secretTextWidth=w-224;
    [self.secretStateField setFrame:NSMakeRect(190,h-292,secretTextWidth,22)];
    CGFloat fingerprintHeight=MIN(62,MAX(42,h-456));
    [self.secretFingerprintField setFrame:NSMakeRect(190,h-300-fingerprintHeight,secretTextWidth,fingerprintHeight)];
    [self.secretKeyImageView setFrame:NSMakeRect(42,h-390,128,128)];
    CGFloat secretActionY=MAX(116,h-410);
    [self.closeSecretChatButton setFrame:NSMakeRect(190,secretActionY,secretTextWidth,30)];
    [self.deleteSecretHistoryButton setFrame:NSMakeRect(190,secretActionY-38,secretTextWidth,30)];
    [self.statusField setFrame:NSMakeRect(34,24,w-100,16)];
    [self.spinner setFrame:NSMakeRect(w-50,24,16,16)];
    TGUtilitySizeResponsiveTable(self.memberTableView);
}
- (void)windowDidResize:(NSNotification *)notification {
    if([notification object]==[self window])[self layoutResponsiveViews];
}
