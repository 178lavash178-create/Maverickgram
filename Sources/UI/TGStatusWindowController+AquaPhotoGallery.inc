/* One immutable source snapshot per opening. Requests keep the existing
 * account/chat/thread guard and generation; navigation never searches another
 * chat or silently changes the Media Center's query/order. */
- (NSMutableDictionary *)aquaPhotoGallery {
    return objc_getAssociatedObject(self,@selector(aquaPhotoGallery));
}

- (void)clearAquaPhotoGallery {
    objc_setAssociatedObject(self,@selector(aquaPhotoGallery),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSView *view=[self.mediaPreviewWindow contentView];
    if ([view isKindOfClass:[TGAquaMediaViewerView class]]) [(TGAquaMediaViewerView *)view setGalleryIndex:NSNotFound count:0];
}

- (BOOL)aquaPhotoGalleryIsCurrent {
    NSDictionary *gallery=[self aquaPhotoGallery];
    if (!gallery || ![self mediaPreviewSelectionContextIsCurrent:[gallery objectForKey:@"selection"]]) return NO;
    return ![[gallery objectForKey:@"grid"] boolValue] ||
        [[gallery objectForKey:@"grid_generation"] unsignedIntegerValue]==self.mediaCenterGeneration;
}

- (void)updateAquaPhotoGalleryControls {
    TGAquaMediaViewerView *view=(TGAquaMediaViewerView *)[self.mediaPreviewWindow contentView];
    if (![view isKindOfClass:[TGAquaMediaViewerView class]]) return;
    NSDictionary *gallery=[self aquaPhotoGallery];
    BOOL current=[self aquaPhotoGalleryIsCurrent];
    [view setGalleryIndex:current ? [[gallery objectForKey:@"index"] unsignedIntegerValue] : NSNotFound
                   count:current ? [[gallery objectForKey:@"entries"] count] : 0];
}

- (void)prepareAquaPhotoGalleryForMessage:(TGMessageItem *)selected mediaItem:(NSDictionary *)selectedMedia gridSender:(id)sender {
    [self clearAquaPhotoGallery];
    if (!TGInterfaceDesignIsAqua() || !TGAquaPhotoTransitionIsStaticPhoto(selectedMedia) || ![selected messageID]) return;
    BOOL grid=sender!=nil;
    NSArray *items=grid ? [self.mediaCenterItems sortedArrayUsingComparator:^NSComparisonResult(id left,id right) {
        return TGMediaCenterCompareItems(left,right,[self.mediaCenterSortPopUpButton indexOfSelectedItem]);
    }] : self.messageItems;
    NSMutableArray *entries=[NSMutableArray array];
    NSUInteger selectedIndex=NSNotFound;
    for (TGMessageItem *item in items) {
        if (![item isKindOfClass:[TGMessageItem class]] || ![item messageID] ||
            ([item chatID] && ![[item chatID] isEqual:self.selectedChatID])) continue;
        /* A media-grid tile opens its first media entry; transcript albums
         * expose each of their photo tiles in the same order as the bubble. */
        NSArray *mediaItems=[item mediaItems];
        if (grid && [mediaItems count]) mediaItems=[NSArray arrayWithObject:[mediaItems objectAtIndex:0]];
        for (NSDictionary *media in mediaItems) {
            if (!TGAquaPhotoTransitionIsStaticPhoto(media)) continue;
            NSNumber *fileID=TGMediaItemFullFileID(media),*selectedFileID=TGMediaItemFullFileID(selectedMedia);
            BOOL sameMedia=[fileID integerValue]>0 && [selectedFileID integerValue]>0 ? [fileID isEqual:selectedFileID] : [media isEqual:selectedMedia];
            if ([[item messageID] isEqual:[selected messageID]] && sameMedia) selectedIndex=[entries count];
            [entries addObject:[NSDictionary dictionaryWithObjectsAndKeys:[item messageID],@"message",[[media copy] autorelease],@"media",nil]];
        }
    }
    if (selectedIndex==NSNotFound) return;
    NSMutableDictionary *gallery=[NSMutableDictionary dictionaryWithObjectsAndKeys:
        [[entries copy] autorelease],@"entries",[NSNumber numberWithUnsignedInteger:selectedIndex],@"index",
        [self mediaPreviewSelectionContext],@"selection",[NSNumber numberWithBool:grid],@"grid",
        [NSNumber numberWithUnsignedInteger:self.mediaCenterGeneration],@"grid_generation",nil];
    objc_setAssociatedObject(self,@selector(aquaPhotoGallery),gallery,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)moveAquaPhotoGalleryBy:(NSInteger)step {
    if (![self aquaPhotoGalleryIsCurrent] || ![self.mediaPreviewWindow isVisible] ||
        [self.mediaPreviewWindow delegate]!=self) { [self clearAquaPhotoGallery]; return; }
    NSMutableDictionary *gallery=[self aquaPhotoGallery];
    NSArray *entries=[gallery objectForKey:@"entries"];
    NSUInteger index=[[gallery objectForKey:@"index"] unsignedIntegerValue];
    if ((step<0 && index==0) || (step>0 && index+1>=[entries count]) || step==0) return;
    NSUInteger next=step<0 ? index-1 : index+1;
    NSDictionary *entry=[entries objectAtIndex:next];
    [gallery setObject:[NSNumber numberWithUnsignedInteger:next] forKey:@"index"];
    /* The originating tile is retained only for the first image. Returning
     * from another image fades rather than shrinking to an unrelated tile. */
    [self setAquaPhotoPreviewSourceContext:nil];
    TGAquaPhotoTransitionClear(self.mediaPreviewWindow);
    [self.mediaPreviewWindow setAlphaValue:1];
    [self.mediaPreviewImageView setImage:nil];
    [self updateAquaPhotoGalleryControls];
    [self openMediaPreviewForMediaItem:[entry objectForKey:@"media"]];
}

- (void)previousAquaPhoto:(id)sender { (void)sender; [self moveAquaPhotoGalleryBy:-1]; }
- (void)nextAquaPhoto:(id)sender { (void)sender; [self moveAquaPhotoGalleryBy:1]; }
- (void)toggleAquaPhotoFullscreen:(id)sender {
    (void)sender;
    if (![self.mediaPreviewWindow isVisible] || [self.mediaPreviewWindow delegate]!=self) return;
    TGAquaPhotoTransitionClear(self.mediaPreviewWindow);
    if ([self.mediaPreviewWindow respondsToSelector:@selector(toggleFullScreen:)])
        [self.mediaPreviewWindow toggleFullScreen:nil];
}
