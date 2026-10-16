/* Shared viewer zoom/fit behavior, exercised directly by native probes. */
- (void)applyMediaPreviewZoomScale:(CGFloat)scale {
    NSImage *image = [self.mediaPreviewImageView image];
    if (!image) {
        return;
    }

    CGFloat minimumScale = self.mediaPreviewMinimumZoomScale > 0.0 ? self.mediaPreviewMinimumZoomScale : 0.10;
    if (scale < minimumScale) {
        scale = minimumScale;
    }
    if (scale > 6.0) {
        scale = 6.0;
    }
    self.mediaPreviewZoomScale = scale;
    [self.mediaPreviewZoomOutButton setEnabled:(scale > minimumScale + 0.001)];

    NSSize imageSize = [image size];
    CGFloat width = TGInterfaceDesignIsAqua() ? floor(imageSize.width * scale) : ceil(imageSize.width * scale);
    CGFloat height = TGInterfaceDesignIsAqua() ? floor(imageSize.height * scale) : ceil(imageSize.height * scale);
    if (width < 1.0) {
        width = 1.0;
    }
    if (height < 1.0) {
        height = 1.0;
    }
    [self.mediaPreviewImageView setFrame:NSMakeRect(0, 0, width, height)];
    [self.mediaPreviewImageView setNeedsDisplay:YES];
}

- (void)fitMediaPreview:(id)sender {
    (void)sender;
    NSImage *image = [self.mediaPreviewImageView image];
    if (!image) {
        return;
    }

    NSSize imageSize = [image size];
    [self.mediaPreviewScrollView tile];
    NSRect visibleRect = [[self.mediaPreviewScrollView contentView] bounds];
    if (imageSize.width <= 0.0 || imageSize.height <= 0.0 || NSWidth(visibleRect) <= 0.0 || NSHeight(visibleRect) <= 0.0) {
        [self applyMediaPreviewZoomScale:1.0];
        return;
    }

    CGFloat scaleX = NSWidth(visibleRect) / imageSize.width;
    CGFloat scaleY = NSHeight(visibleRect) / imageSize.height;
    CGFloat scale = (scaleX < scaleY) ? scaleX : scaleY;
    if (scale > 1.0) {
        scale = 1.0;
    }
    self.mediaPreviewMinimumZoomScale = scale;
    [self applyMediaPreviewZoomScale:scale];
    if (TGInterfaceDesignIsAqua()) [[self.mediaPreviewScrollView contentView] scrollToPoint:NSZeroPoint];
}

- (void)zoomInMediaPreview:(id)sender {
    (void)sender;
    CGFloat scale = self.mediaPreviewZoomScale > 0.0 ? self.mediaPreviewZoomScale : 1.0;
    [self applyMediaPreviewZoomScale:scale * 1.25];
}

- (void)zoomOutMediaPreview:(id)sender {
    (void)sender;
    CGFloat scale = self.mediaPreviewZoomScale > 0.0 ? self.mediaPreviewZoomScale : 1.0;
    [self applyMediaPreviewZoomScale:scale / 1.25];
}

- (void)mediaPreviewView:(id)sender didMagnifyBy:(NSNumber *)magnificationNumber {
    (void)sender;
    CGFloat delta = [magnificationNumber respondsToSelector:@selector(doubleValue)] ? (CGFloat)[magnificationNumber doubleValue] : 0.0;
    if (delta > -0.002 && delta < 0.002) {
        return;
    }

    CGFloat scale = self.mediaPreviewZoomScale > 0.0 ? self.mediaPreviewZoomScale : 1.0;
    CGFloat factor = 1.0 + delta;
    if (factor < 0.25) {
        factor = 0.25;
    }
    if (factor > 4.0) {
        factor = 4.0;
    }
    [self applyMediaPreviewZoomScale:scale * factor];
}
