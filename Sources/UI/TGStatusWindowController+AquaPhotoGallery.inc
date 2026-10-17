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
    NSUInteger index=[[gallery objectForKey:@"index"] unsignedIntegerValue];
    NSArray *entries=[gallery objectForKey:@"entries"];
    if (current && index<[entries count]) {
        NSDictionary *entry=[entries objectAtIndex:index];
        [view setMediaTitle:[entry objectForKey:@"title"] detail:[entry objectForKey:@"detail"]];
    }
}

/* Album bubbles aggregate multiple messages; file metadata belongs to the
 * selected media dictionary, not to the first message in the bubble. */
- (NSDictionary *)aquaPhotoGalleryMetadataForMedia:(NSDictionary *)media message:(TGMessageItem *)item {
    id name=[media objectForKey:@"file_name"];
    NSString *path=TGMediaItemFullLocalPath(media);
    if (![path length]) path=TGMediaItemLocalPath(media);
    NSString *title=([name isKindOfClass:[NSString class]] && [name length]) ? name : [path lastPathComponent];
    if (![title length]) title=TGLoc(@"media.viewer.photo");
    id size=[media objectForKey:@"file_size"];
    unsigned long long bytes=([size respondsToSelector:@selector(longLongValue)] && [size longLongValue]>0) ? [size unsignedLongLongValue] : TGMediaCenterFileSizeAtPath(path);
    NSMutableArray *parts=[NSMutableArray array];
    if (bytes>0) [parts addObject:TGMediaCenterReadableSize(bytes)];
    NSNumber *width=[media objectForKey:@"width"],*height=[media objectForKey:@"height"];
    if ([width respondsToSelector:@selector(doubleValue)] && [height respondsToSelector:@selector(doubleValue)] && [width doubleValue]>0 && [height doubleValue]>0)
        [parts addObject:[NSString stringWithFormat:@"%.0f × %.0f",[width doubleValue],[height doubleValue]]];
    NSString *date=TGMediaCenterDateStringForItem(item);
    id mediaDate=[media objectForKey:@"date"];
    if ([mediaDate respondsToSelector:@selector(doubleValue)] && [mediaDate doubleValue]>0) {
        NSDateFormatter *formatter=[[[NSDateFormatter alloc] init] autorelease];
        [formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:TGLanguageCode()] autorelease]];
        [formatter setDateStyle:NSDateFormatterShortStyle]; [formatter setTimeStyle:NSDateFormatterShortStyle];
        date=[formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[mediaDate doubleValue]]];
    }
    if ([date length]) [parts addObject:date];
    return [NSDictionary dictionaryWithObjectsAndKeys:title,@"title",[parts componentsJoinedByString:@" · "],@"detail",nil];
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
            NSDictionary *metadata=[self aquaPhotoGalleryMetadataForMedia:media message:item];
            [entries addObject:[NSDictionary dictionaryWithObjectsAndKeys:[item messageID],@"message",[[media copy] autorelease],@"media",
                [metadata objectForKey:@"title"],@"title",[metadata objectForKey:@"detail"],@"detail",nil]];
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
