/* Offer the optional interface once; never restart while the user is composing. */
static NSString * const TGAquaSuggestionSeenKey=@"TelegraphicaAquaSuggestionSeen";
- (void)queueAquaSuggestionIfNeeded {
    if (TGInterfaceDesignIsAqua() || [[NSUserDefaults standardUserDefaults] boolForKey:TGAquaSuggestionSeenKey] ||
        ![self.currentAuthState isEqualToString:@"ready"] || objc_getAssociatedObject(self,@selector(offerAquaSuggestion))) return;
    objc_setAssociatedObject(self,@selector(offerAquaSuggestion),[NSNumber numberWithBool:YES],OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self performSelector:@selector(offerAquaSuggestion) withObject:nil afterDelay:3.0];
}
- (void)offerAquaSuggestion {
    objc_setAssociatedObject(self,@selector(offerAquaSuggestion),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSWindow *window=[self window];
    if (TGInterfaceDesignIsAqua() || [[NSUserDefaults standardUserDefaults] boolForKey:TGAquaSuggestionSeenKey] ||
        ![self.currentAuthState isEqualToString:@"ready"] || ![NSApp isActive] || ![window isVisible] ||
        [window isMiniaturized] || [window inLiveResize] || [window attachedSheet] || [NSApp modalWindow] ||
        self.controlsBusy || [[self.sendTextField stringValue] length]>0) return;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TGAquaSuggestionSeenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSAlert *alert=[[[NSAlert alloc] init] autorelease];
    [alert setMessageText:TGLoc(@"aqua.offer.title")];[alert setInformativeText:TGLoc(@"aqua.offer.message")];
    [alert addButtonWithTitle:TGLoc(@"aqua.offer.open")];[alert addButtonWithTitle:TGLoc(@"aqua.offer.later")];
    if (TGRunAlert(alert,window)==NSAlertFirstButtonReturn && [self.currentAuthState isEqualToString:@"ready"]) {
        NSButton *route=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];[route setTag:3];[self navigationChanged:route];
    }
}
