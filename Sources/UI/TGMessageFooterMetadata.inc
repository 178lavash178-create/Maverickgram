// Views, reply counts and the existing pin asset share one reserved metadata band.
// No aggregate is synthesized for group messages whose server metadata omits it.
static NSString *TGMessageFooterViewTitle(TGMessageItem *item) {
    NSNumber *count = [item messageViewCount];
    if ([count longLongValue] <= 0) count = [item messageViewerCount];
    if (![count isKindOfClass:[NSNumber class]] || [count longLongValue] < 0) return nil;
    NSString *format = TGLoc(@"message.views.format");
    if ([format isEqualToString:@"message.views.format"]) format = @"%@ views";
    return [NSString stringWithFormat:format, TGMessageCompactCountString(count)];
}
CGFloat TGMessageFooterIndicatorsWidthForItem(TGMessageItem *item) {
    CGFloat width = TGMessageReplyIndicatorWidthForItem(item);
    if ([item isPinned]) width += 16.0;
    NSString *views = TGMessageFooterViewTitle(item);
    if ([views length]) width += ceil([views sizeWithAttributes:[NSDictionary dictionaryWithObject:TGChatMessageMetaFont() forKey:NSFontAttributeName]].width) + 7.0;
    return width;
}
NSRect TGMessageFooterIndicatorsRectForTimeRect(TGMessageItem *item, NSRect timeRect) {
    CGFloat width = TGMessageFooterIndicatorsWidthForItem(item);
    return width > 0.0 && !NSIsEmptyRect(timeRect)
        ? NSMakeRect(NSMinX(timeRect)-width,NSMinY(timeRect),width,NSHeight(timeRect)) : NSZeroRect;
}
static void TGDrawMessageFooterIndicators(TGMessageItem *item, NSRect timeRect, NSRect countAnchor, BOOL wrapped, BOOL flipped) {
    if (NSIsEmptyRect(timeRect)) return;
    NSColor *ink = TGMessageMetadataInkColor(item,flipped);
    NSRect remaining = countAnchor;
    if ([item isPinned]) {
        NSRect pin = NSMakeRect(NSMinX(timeRect)-16.0,floor(NSMidY(timeRect)-6.0),12.0,12.0);
        TGDrawTemplateIconAsset(@"Phosphor/pin",pin,ink,1.0,flipped);
        if (!wrapped) remaining.origin.x -= 16.0;
    }
    TGDrawMessageReplyIndicatorForTimeRect(item,remaining,flipped);
    remaining.origin.x -= TGMessageReplyIndicatorWidthForItem(item);
    NSString *views = TGMessageFooterViewTitle(item);
    if ([views length]) {
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:TGChatMessageMetaFont(),NSFontAttributeName,ink,NSForegroundColorAttributeName,nil];
        CGFloat width = ceil([views sizeWithAttributes:attributes].width);
        [views drawInRect:NSMakeRect(NSMinX(remaining)-width-7.0,NSMinY(remaining),width,NSHeight(remaining)) withAttributes:attributes];
    }
}


void TGDrawMessageFooterIndicatorsForTimeRect(TGMessageItem *item, NSRect timeRect, BOOL flipped) {
    TGDrawMessageFooterIndicators(item,timeRect,timeRect,NO,flipped);
}
// Timestamp, original receipts and pin stay together on the final line. Only
// passive view/reply counts wrap above when the physical viewport requires it.
CGFloat TGMessageFooterWrappedHeightForItem(TGMessageItem *item, CGFloat innerWidth) {
    CGFloat indicators = TGMessageFooterIndicatorsWidthForItem(item);
    NSString *time = TGShortTimeStringFromDateValue([item date]);
    if (indicators <= ([item isPinned] ? 16.0 : 0.0) || ![time length]) return 0.0;
    NSSize size = [time sizeWithAttributes:[NSDictionary dictionaryWithObject:TGChatMessageMetaFont() forKey:NSFontAttributeName]];
    CGFloat status = TGOutgoingStatusDotsWidthForItem(item);
    CGFloat width = ceil(size.width) + status + (status > 0.0 ? 5.0 : 0.0) + indicators + 2.0;
    return width > innerWidth ? MAX(12.0,ceil(size.height)+2.0)+4.0 : 0.0;
}
CGFloat TGMessageContentFooterReservation(TGMessageItem *item, CGFloat innerWidth) {
    if (TGReactionChipsMinimumWidthForItem(item)>0.0) return 0.0;
    CGFloat extra = TGMessageFooterWrappedHeightForItem(item,innerWidth);
    // Fixed-height controls must not center their content in added metadata.
    // Give their passive footer a separate region even when it fits one line.
    if (TGMessageFooterIndicatorsWidthForItem(item)>0.0 &&
        (TGMessageItemIsNonVisualPlayableMedia(item) || TGMessageItemIsNonVisualDocument(item) ||
         TGMessageItemIsPollContent(item) || TGMessageItemIsCallContent(item))) {
        NSString *time = TGShortTimeStringFromDateValue([item date]);
        NSSize size = [time sizeWithAttributes:[NSDictionary dictionaryWithObject:TGChatMessageMetaFont() forKey:NSFontAttributeName]];
        if ([time length]) extra += MAX(12.0,ceil(size.height)+2.0)+4.0;
    }
    return extra;
}
static NSRect TGMessageFooterCountAnchor(TGMessageItem *item, NSRect timeRect, CGFloat innerWidth, BOOL flipped) {
    CGFloat extra = TGMessageFooterWrappedHeightForItem(item,innerWidth);
    if (extra > 0.0 && !NSIsEmptyRect(timeRect)) {
        CGFloat status = TGOutgoingStatusDotsWidthForItem(item);
        timeRect.origin.x = NSMaxX(timeRect)+status+(status > 0.0 ? 5.0 : 0.0);
        timeRect.origin.y += flipped ? -extra : extra;
    }
    return timeRect;
}
NSRect TGMessageFooterIndicatorsRectInWidth(TGMessageItem *item, NSRect timeRect, CGFloat innerWidth, BOOL flipped) {
    if (TGMessageFooterWrappedHeightForItem(item,innerWidth)<=0.0)
        return TGMessageFooterIndicatorsRectForTimeRect(item,timeRect);
    NSRect anchor = TGMessageFooterCountAnchor(item,timeRect,innerWidth,flipped);
    CGFloat countWidth = TGMessageFooterIndicatorsWidthForItem(item)-([item isPinned]?16.0:0.0);
    NSRect counts = NSMakeRect(NSMinX(anchor)-countWidth,NSMinY(anchor),countWidth,NSHeight(anchor));
    NSRect pin = [item isPinned] ? NSMakeRect(NSMinX(timeRect)-16.0,NSMinY(timeRect),16.0,NSHeight(timeRect)) : NSZeroRect;
    return NSIsEmptyRect(pin) ? counts : NSUnionRect(counts,pin);
}
void TGDrawMessageFooterIndicatorsInWidth(TGMessageItem *item, NSRect timeRect, CGFloat innerWidth, BOOL flipped) {
    BOOL wrapped = TGMessageFooterWrappedHeightForItem(item,innerWidth)>0.0;
    TGDrawMessageFooterIndicators(item,timeRect,TGMessageFooterCountAnchor(item,timeRect,innerWidth,flipped),wrapped,flipped);
}

// AppKit font metrics and PNG sampling differ on Mavericks and newer systems.
// Measure the approved, unchanged asset against actual timestamp ink once per
// font/orientation/line height. This positions the original image; it does not
// generate or alter any icon. Whole-point offsets retain crisp legacy pixels.
static CGFloat TGMessageReceiptOpticalOffset(NSRect timeRect, BOOL flipped) {
    static NSCache *cache = nil;
    if (!cache) { cache = [[NSCache alloc] init]; [cache setCountLimit:64]; }
    NSFont *font = TGChatMessageMetaFont();
    NSString *key = [NSString stringWithFormat:@"%@|%.2f|%.2f|%d",[font fontName],[font pointSize],NSHeight(timeRect),flipped];
    NSNumber *cached = [cache objectForKey:key];
    if (cached) return [cached doubleValue];
    CGFloat offset = flipped ? -1.0 : 1.0;
    const NSInteger scale = 4, pixelsWide = 512, pixelsHigh = 192;
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:pixelsWide pixelsHigh:pixelsHigh bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    if (bitmap) {
        memset([bitmap bitmapData],0,[bitmap bytesPerRow]*pixelsHigh);
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
        [NSGraphicsContext setCurrentContext:context];
        NSAffineTransform *transform = [NSAffineTransform transform];
        if (flipped) [transform translateXBy:0 yBy:pixelsHigh];
        [transform scaleXBy:scale yBy:flipped ? -scale : scale]; [transform concat];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[context graphicsPort] flipped:flipped]];
        [@"12:30" drawInRect:NSMakeRect(4,8,80,NSHeight(timeRect)) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]];
        TGDrawTemplateIconAsset(@"done-mini",NSMakeRect(100,8+floor((NSHeight(timeRect)-10.0)/2.0),10,10),[NSColor blackColor],1.0,flipped);
        [NSGraphicsContext restoreGraphicsState];
        NSInteger textMin=pixelsHigh,textMax=-1,iconMin=pixelsHigh,iconMax=-1;
        const unsigned char *bytes = [bitmap bitmapData];
        NSInteger stride = [bitmap bytesPerRow];
        NSInteger alphaIndex = ([bitmap bitmapFormat] & NSAlphaFirstBitmapFormat) ? 0 : 3;
        for (NSInteger y=0;y<pixelsHigh;y++) for (NSInteger x=0;x<pixelsWide;x++) {
            if (bytes[y*stride+x*4+alphaIndex]<64) continue;
            if (x<90*scale) { textMin=MIN(textMin,y); textMax=MAX(textMax,y); }
            else { iconMin=MIN(iconMin,y); iconMax=MAX(iconMax,y); }
        }
        if (textMax>=textMin && iconMax>=iconMin) {
            CGFloat screenDelta=(textMin+textMax-iconMin-iconMax)/(2.0*scale);
            offset=round((flipped ? 1.0 : -1.0)*screenDelta);
        }
    }
    [cache setObject:[NSNumber numberWithDouble:offset] forKey:key];
    return offset;
}
