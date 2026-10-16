// A single scheduled shelf is owned by the active conversation. Closing it
// invalidates callbacks rather than retaining an invisible queue for another chat.
static char TGAquaScheduledButtonKey;
- (NSButton *)aquaScheduledMessagesButton {
    return objc_getAssociatedObject(self,&TGAquaScheduledButtonKey);
}
- (void)ensureAquaScheduledMessagesButton {
    if(!TGInterfaceDesignIsAqua() || [self aquaScheduledMessagesButton]) return;
    NSButton *button=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [button setTarget:self]; [button setAction:@selector(showScheduledMessages:)];
    [self applyUtilityButtonStyle:button]; [self installAquaTextCellOnButton:button accented:NO];
    [button setTitle:TGLoc(@"scheduled.shelf.title")]; [button setToolTip:TGLoc(@"scheduled.title")];
    [button setHidden:YES]; [[[self window] contentView] addSubview:button];
    objc_setAssociatedObject(self,&TGAquaScheduledButtonKey,button,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)closeAquaScheduledMessages {
    if(!TGInterfaceDesignIsAqua()) return;
    NSView *shelf=[self.scheduledMessagesWindowController embeddedShelfView];
    [shelf removeFromSuperview];
    [self.scheduledMessagesWindowController invalidateEmbeddedShelf];
    self.scheduledMessagesWindowController=nil;
}
- (void)hideAquaScheduledMessages:(id)sender {
    (void)sender; [self closeAquaScheduledMessages]; [self layoutContentView];
    if([self.sendTextField isEnabled]) [[self window] makeFirstResponder:self.sendTextField];
}
- (BOOL)toggleAquaScheduledMessages {
    if(!TGInterfaceDesignIsAqua()) return NO;
    if(!self.client || ![self.currentAuthState isEqualToString:@"ready"] || !self.selectedChatID) { NSBeep(); return YES; }
    if([[self.scheduledMessagesWindowController embeddedShelfView] superview]) {
        [self hideAquaScheduledMessages:self]; return YES;
    }
    [self closeAquaStickerPicker]; [self.downloadManagerWindowController closeCompactPopover];
    if(self.searchPanelVisible) [self closeSearchPanel:self];
    // The controller is intentionally per-chat; all read/mutation completions
    // are invalidated when the owning conversation changes.
    [self.scheduledMessagesWindowController invalidateEmbeddedShelf];
    [[self.scheduledMessagesWindowController window] close];
    self.scheduledMessagesWindowController=[[[TGScheduledMessagesWindowController alloc] initWithClient:self.client chatID:self.selectedChatID title:self.selectedChatTitle] autorelease];
    NSView *shelf=[self.scheduledMessagesWindowController embeddedShelfView];
    [self.scheduledMessagesWindowController setEmbeddedParentWindow:[self window]];
    [self.scheduledMessagesWindowController setShelfCloseTarget:self action:@selector(hideAquaScheduledMessages:)];
    [[[self window] contentView] addSubview:shelf];
    [self.scheduledMessagesWindowController reloadMessages];
    [self layoutContentView];
    [self.scheduledMessagesWindowController presentEmbeddedShelfAnimated:YES]; return YES;
}
- (CGFloat)aquaScheduledButtonWidthForConversationWidth:(CGFloat)width bot:(BOOL)bot {
    CGFloat button=width<500 ? 76.0 : 100.0;
    return width-(bot ? 366.0 : 288.0)-button-6.0>=112.0 ? button : 0.0;
}
- (CGFloat)layoutAquaScheduledShelfAtX:(CGFloat)x bottom:(CGFloat)bottom width:(CGFloat)width top:(CGFloat)top {
    if(!TGInterfaceDesignIsAqua()) return bottom;
    NSView *shelf=[self.scheduledMessagesWindowController embeddedShelfView];
    if(![shelf superview]) return bottom;
    BOOL valid=[self.activeSection isEqualToString:TGSectionChats] && !self.chatNavigationClosed && ![self aquaChatInfoReplacesConversation] && ![self.sendTextField isHidden] &&
        [self.scheduledMessagesWindowController matchesClient:self.client chatID:self.selectedChatID] &&
        [self.currentAuthState isEqualToString:@"ready"];
    if(!valid) { [self closeAquaScheduledMessages]; return bottom; }
    CGFloat height=MIN([self.scheduledMessagesWindowController preferredEmbeddedShelfHeight],MAX(0,top-bottom-166));
    [shelf setHidden:height<90];
    if(height<90) { [self.scheduledMessagesWindowController hideEmbeddedShelfImmediately]; return bottom; }
    [shelf setFrame:NSMakeRect(x,bottom,width,height)];
    return bottom+height+6;
}
