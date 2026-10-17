/* The same search panel/model lives in a transient anchored window in Aqua.
 * The observer has its own identity: never unregister a window's delegate. */
static char TGAquaChatSearchStateKey;
- (NSMutableDictionary *)aquaChatSearchState { return objc_getAssociatedObject(self,&TGAquaChatSearchStateKey); }
- (NSDictionary *)aquaChatSearchContext {
    return [NSDictionary dictionaryWithObjectsAndKeys:self.client ? (id)self.client : (id)[NSNull null],@"client",
        self.profileUserID ? (id)self.profileUserID : (id)[NSNull null],@"account",
        self.activeSection ? self.activeSection : TGSectionChats,@"section",nil];
}
- (BOOL)aquaChatSearchContextIsCurrent:(NSDictionary *)context {
    if (!TGInterfaceDesignIsAqua()) return YES;
    return context && context==[[self aquaChatSearchState] objectForKey:@"context"] &&
        [self.currentAuthState isEqualToString:@"ready"] && [context isEqual:[self aquaChatSearchContext]];
}
- (void)finishAquaChatSearchDismissal {
    NSMutableDictionary *state=[self aquaChatSearchState];
    [[state objectForKey:@"observer"] invalidate];[state removeObjectForKey:@"observer"];
    if (![state objectForKey:@"context"]) return;
    [state removeObjectForKey:@"context"];self.chatSearchGeneration++;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateChatSearchWindowResults) object:nil];
}
- (void)invalidateAquaChatSearchPresentation {
    NSPopover *popover=[[self aquaChatSearchState] objectForKey:@"popover"];
    [popover setAnimates:NO];[popover close];[self finishAquaChatSearchDismissal];
}
- (void)aquaChatSearchWindowChanged:(NSNotification *)notification { (void)notification;[self invalidateAquaChatSearchPresentation]; }
- (BOOL)showAquaChatSearchPanel {
    if (!TGInterfaceDesignIsAqua() || ![self.currentAuthState isEqualToString:@"ready"]) return NO;
    NSView *anchor=[self aquaToolbarSearchField];NSWindow *window=[self window];
    if (![window isVisible] || [anchor window]!=window || [anchor isHiddenOrHasHiddenAncestor]) return NO;
    NSMutableDictionary *state=[self aquaChatSearchState];
    if (!state) {
        state=[NSMutableDictionary dictionary];
        TGChatSearchPanelView *panel=[self chatSearchPanelView];
        [panel removeFromSuperview];
        [self.chatSearchWindow setContentView:[[[NSView alloc] initWithFrame:NSZeroRect] autorelease]];
        NSViewController *controller=[[[NSViewController alloc] initWithNibName:nil bundle:nil] autorelease];[controller setView:panel];
        NSPopover *popover=[[[NSPopover alloc] init] autorelease];
        [popover setContentViewController:controller];[popover setBehavior:NSPopoverBehaviorTransient];[popover setDelegate:(id)self];
        [state setObject:popover forKey:@"popover"];
        objc_setAssociatedObject(self,&TGAquaChatSearchStateKey,state,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSPopover *popover=[state objectForKey:@"popover"];
    if ([popover isShown]) return YES;
    [self finishAquaChatSearchDismissal];
    NSScreen *screen=[window screen];if (!screen) screen=[NSScreen mainScreen];
    NSRect visible=[screen visibleFrame],screenAnchor=[window convertRectToScreen:[anchor convertRect:[anchor bounds] toView:nil]];
    CGFloat width=floor(MIN(480,MIN(NSWidth(visible)-32,NSWidth([[window contentView] bounds])-24)));
    CGFloat below=NSMinY(screenAnchor)-NSMinY(visible)-24;
    CGFloat above=NSMaxY(visible)-NSMaxY(screenAnchor)-24;
    BOOL opensAbove=below<220 && above>below;
    CGFloat height=floor(MIN(380,opensAbove ? above : below));
    if (width<280 || height<220) return NO;
    TGChatSearchPanelView *panel=[self chatSearchPanelView];[panel setFrameSize:NSMakeSize(width,height)];[panel layoutPanelSubviews];
    [popover setContentSize:NSMakeSize(width,height)];
    [state setObject:[self aquaChatSearchContext] forKey:@"context"];
    NSArray *events=[NSArray arrayWithObjects:NSWindowDidResizeNotification,NSWindowDidMoveNotification,NSWindowWillCloseNotification,NSWindowWillMiniaturizeNotification,nil];
    TGWindowEventObserver *observer=[[[TGWindowEventObserver alloc] initWithWindow:window names:events target:self action:@selector(aquaChatSearchWindowChanged:)] autorelease];
    [state setObject:observer forKey:@"observer"];
    // Live-resizing the main window and an opening popover must not share a snapshot animation.
    [popover setAnimates:TGInterfaceAnimationsEnabledForView(anchor) && ![window inLiveResize]];
    NSRectEdge edge=opensAbove ? ([anchor isFlipped] ? NSMinYEdge : NSMaxYEdge) : ([anchor isFlipped] ? NSMaxYEdge : NSMinYEdge);
    @try { [popover showRelativeToRect:[anchor bounds] ofView:anchor preferredEdge:edge]; }
    @catch (NSException *exception) { (void)exception;[self invalidateAquaChatSearchPresentation];return NO; }
    if (![popover isShown]) { [self finishAquaChatSearchDismissal];return NO; }
    [[panel window] makeFirstResponder:[panel searchField]];
    return YES;
}
- (void)disposeAquaChatSearchPresentation {
    NSPopover *popover=[[self aquaChatSearchState] objectForKey:@"popover"];
    [popover setDelegate:nil];[self invalidateAquaChatSearchPresentation];
    objc_setAssociatedObject(self,&TGAquaChatSearchStateKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
