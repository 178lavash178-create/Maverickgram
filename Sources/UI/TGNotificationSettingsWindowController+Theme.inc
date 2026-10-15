- (void)refreshPreviewTheme:(NSNotification *)notification {
    (void)notification;
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(refreshPreviewTheme:) withObject:nil waitUntilDone:NO];
        return;
    }
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        TGThemeSurfaceInkColor(TGClassicCardInkColor(), TGThemeSurfaceCard, 4.5), NSForegroundColorAttributeName,
        [self.previewButton font], NSFontAttributeName, nil];
    NSAttributedString *title = [[[NSAttributedString alloc] initWithString:[self.previewButton title]
        attributes:attributes] autorelease];
    [self.previewButton setAttributedTitle:title];
    [self.previewButton setAttributedAlternateTitle:title];
    [self.previewButton setNeedsDisplay:YES];
}

