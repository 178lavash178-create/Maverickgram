/* Kept with the existing media preview flow: identity is resolved again at
 * presentation/close, never inferred from a stale row or screen coordinate. */
- (NSDictionary *)aquaPhotoPreviewSourceContext {
    return objc_getAssociatedObject(self, @selector(aquaPhotoPreviewSourceContext));
}

- (void)setAquaPhotoPreviewSourceContext:(NSDictionary *)context {
    objc_setAssociatedObject(self, @selector(aquaPhotoPreviewSourceContext), context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)mediaPreviewSelectionContext {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.client ? (id)self.client : (id)[NSNull null], @"client",
            self.profileUserID ? (id)self.profileUserID : (id)[NSNull null], @"account",
            self.selectedChatID ? (id)self.selectedChatID : (id)[NSNull null], @"chat",
            self.selectedMessageThreadID ? (id)self.selectedMessageThreadID : (id)[NSNull null], @"thread",
            self.selectedMessageTopicKind ? self.selectedMessageTopicKind : @"", @"topic",
            self.activeSection ? self.activeSection : @"", @"section",
            [NSNumber numberWithBool:self.chatNavigationClosed], @"chat_closed",
            [NSNumber numberWithBool:self.mediaCenterVisible], @"media_center",
            nil];
}

- (BOOL)mediaPreviewSelectionContextIsCurrent:(NSDictionary *)context {
    return [context isEqual:[self mediaPreviewSelectionContext]] && [self.currentAuthState isEqualToString:@"ready"];
}

- (void)prepareAquaPhotoPreviewForMessage:(TGMessageItem *)item mediaItem:(NSDictionary *)mediaItem gridSender:(id)sender {
    [self setAquaPhotoPreviewSourceContext:nil];
    if (!TGInterfaceDesignIsAqua() || !TGAquaPhotoTransitionIsStaticPhoto(mediaItem) || ![item messageID]) return;
    NSMutableDictionary *context = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [self mediaPreviewSelectionContext], @"selection",
                                    [item messageID], @"message",
                                    mediaItem, @"media",
                                    nil];
    if ([sender isKindOfClass:[NSView class]]) {
        NSView *tile = [(NSView *)sender superview];
        for (NSView *child in [tile subviews]) {
            if ([child isKindOfClass:[NSImageView class]] && [(NSImageView *)child image]) {
                [context setObject:child forKey:@"grid_image_view"];
                [context setObject:[NSNumber numberWithUnsignedInteger:self.mediaCenterGeneration] forKey:@"grid_generation"];
                break;
            }
        }
        /* A list's generic file icon is not a photo thumbnail. */
        if (![context objectForKey:@"grid_image_view"]) return;
    }
    [self setAquaPhotoPreviewSourceContext:context];
}

- (NSRect)aquaPhotoPreviewSourceScreenRectForContext:(NSDictionary *)context {
    if (!context || ![self mediaPreviewSelectionContextIsCurrent:[context objectForKey:@"selection"]]) return NSZeroRect;
    NSImageView *gridImageView = [context objectForKey:@"grid_image_view"];
    if (gridImageView) {
        if (!self.mediaCenterVisible ||
            [[context objectForKey:@"grid_generation"] unsignedIntegerValue] != self.mediaCenterGeneration ||
            ![gridImageView isDescendantOf:self.mediaCenterResultsView]) return NSZeroRect;
        /* The grid uses aspect fit, so start from the actual picture rather
         * than the surrounding card/title/button hit area. */
        NSSize imageSize = [[gridImageView image] size];
        NSRect bounds = [gridImageView bounds];
        if (imageSize.width <= 0.0 || imageSize.height <= 0.0) return NSZeroRect;
        CGFloat scale = MIN(NSWidth(bounds) / imageSize.width, NSHeight(bounds) / imageSize.height);
        NSRect picture = NSMakeRect(NSMidX(bounds) - imageSize.width * scale / 2.0,
                                    NSMidY(bounds) - imageSize.height * scale / 2.0,
                                    imageSize.width * scale, imageSize.height * scale);
        return TGAquaPhotoVisibleScreenRect(gridImageView, picture);
    }
    if (self.mediaCenterVisible || [self.messageTableView isHiddenOrHasHiddenAncestor]) return NSZeroRect;
    NSUInteger row = 0;
    for (TGMessageItem *item in self.messageItems) {
        if ([[item messageID] isEqual:[context objectForKey:@"message"]]) {
            NSRect cellFrame = [self messageBubbleCellFrameForRow:(NSInteger)row];
            for (NSDictionary *entry in [self mediaLayoutEntriesForItem:item inCellFrame:cellFrame]) {
                NSDictionary *candidate = [entry objectForKey:@"media_item"];
                NSDictionary *original = [context objectForKey:@"media"];
                NSNumber *fileID = TGMediaItemFullFileID(original);
                BOOL same = fileID && [fileID integerValue] > 0
                    ? [fileID isEqual:TGMediaItemFullFileID(candidate)] : [candidate isEqual:original];
                if (same && TGAquaPhotoTransitionIsStaticPhoto(candidate))
                    return TGAquaPhotoVisibleScreenRect(self.messageTableView, [[entry objectForKey:@"frame"] rectValue]);
            }
            return NSZeroRect;
        }
        row++;
    }
    return NSZeroRect;
}

- (BOOL)windowShouldClose:(id)sender {
    return sender != self.mediaPreviewWindow || TGAquaPhotoTransitionShouldClose(self.mediaPreviewWindow);
}

- (void)invalidateAquaPhotoPreview {
    self.mediaPreviewRequestGeneration = self.mediaPreviewRequestGeneration + 1;
    [self setAquaPhotoPreviewSourceContext:nil];
    TGAquaPhotoTransitionClear(self.mediaPreviewWindow);
}
