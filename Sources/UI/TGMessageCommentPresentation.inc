// Shared comment/discussion presentation; included by TGMessageLayoutSupport.m.
BOOL TGMessageItemHasCommentThread(TGMessageItem *item) {
    BOOL hasReplies = ([[item messageThreadReplyCount] respondsToSelector:@selector(integerValue)] && [[item messageThreadReplyCount] integerValue] > 0);
    return ([item isKindOfClass:[TGMessageItem class]] &&
            ([item canGetMessageThread] || hasReplies) &&
            [[item chatID] respondsToSelector:@selector(longLongValue)] &&
            [[item messageID] respondsToSelector:@selector(longLongValue)]);
}

NSString *TGMessageCommentTitleForItem(TGMessageItem *item) {
    NSInteger count = ([[item messageThreadReplyCount] respondsToSelector:@selector(integerValue)]
        ? [[item messageThreadReplyCount] integerValue] : 0);
    if (count <= 0) { return TGLoc(@"message.comments.add"); }
    NSString *language = TGLanguageCode();
    NSString *key = @"message.comments.count.many";
    if ([language isEqualToString:@"ru"] || [language isEqualToString:@"be"]) {
        NSInteger lastTwoDigits = count % 100;
        NSInteger lastDigit = count % 10;
        if (lastTwoDigits < 11 || lastTwoDigits > 14) {
            if (lastDigit == 1) { key = @"message.comments.count.one"; }
            else if (lastDigit >= 2 && lastDigit <= 4) { key = @"message.comments.count.few"; }
        }
    } else if (count == 1) {
        key = @"message.comments.count.one";
    }
    return [NSString stringWithFormat:TGLoc(key), (long)count];
}

BOOL TGMessageItemShowsCommentBar(TGMessageItem *item) {
    return [item isChannelPost] && TGMessageItemHasCommentThread(item);
}

static CGFloat TGMessageCommentTitleLineHeight(void) {
    NSFont *font = TGChatMessageBoldSecondaryFont();
    return MAX(16.0, ceil([font ascender] - [font descender] + [font leading]) + 2.0);
}

CGFloat TGMessageCommentBarHeightForItem(TGMessageItem *item) {
    return TGMessageItemShowsCommentBar(item) ? MAX(34.0, TGMessageCommentTitleLineHeight() + 18.0) : 0.0;
}

NSRect TGMessageCommentBarRectForItem(TGMessageItem *item, NSRect bubbleRect, BOOL flipped) {
    BOOL blocks = TGChatMessagesAsBlocksEnabled();
    CGFloat height = blocks
        ? (TGMessageItemShowsCommentBar(item) ? MAX(24.0, TGMessageCommentTitleLineHeight() + 8.0) : 0.0)
        : TGMessageCommentBarHeightForItem(item);
    if (height <= 0.0 || NSIsEmptyRect(bubbleRect)) {
        return NSZeroRect;
    }
    CGFloat innerWidth = blocks ? MAX(40.0, NSWidth(bubbleRect) - 74.0) : NSWidth(bubbleRect) - 20.0;
    CGFloat reactionHeight = TGMessageReactionFooterHeight(item, innerWidth);
    CGFloat y = flipped ? (NSMaxY(bubbleRect) - reactionHeight - height - 4.0)
                        : (NSMinY(bubbleRect) + reactionHeight + 4.0);
    CGFloat inset = blocks ? 50.0 : 10.0;
    return NSMakeRect(NSMinX(bubbleRect) + inset, y, innerWidth, height - 6.0);
}

void TGDrawMessageCommentBarForItem(TGMessageItem *item, NSRect bubbleRect, BOOL outgoing, BOOL flipped) {
    if (!TGMessageItemShowsCommentBar(item)) {
        return;
    }
    NSRect barRect = TGMessageCommentBarRectForItem(item, bubbleRect, flipped);
    if (NSIsEmptyRect(barRect)) {
        return;
    }
    NSBezierPath *barPath = [NSBezierPath bezierPathWithRoundedRect:barRect xRadius:11.0 yRadius:11.0];
    NSColor *fillColor = outgoing ? TGClassicIncomingBubbleBottomColor() : TGClassicOutgoingBubbleBottomColor();
    [fillColor set];
    NSColor *commentInk = TGThemeReadableInk(TGClassicNavigationSelectedColor(1.0), fillColor, 4.5);
    [barPath fill];
    [TGClassicNavigationSelectedStrokeColor(0.48) set];
    [barPath setLineWidth:0.8];
    [barPath stroke];

    NSString *title = TGMessageCommentTitleForItem(item);
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                TGChatMessageBoldSecondaryFont(), NSFontAttributeName,
                                commentInk, NSForegroundColorAttributeName,
                                nil];
    CGFloat iconSide = 15.0;
    NSRect iconRect = NSMakeRect(NSMinX(barRect) + 10.0,
                                 NSMinY(barRect) + floor((NSHeight(barRect) - iconSide) / 2.0),
                                 iconSide,
                                 iconSide);
    TGDrawTemplateIconAsset(@"route-arrow", iconRect, commentInk, 1.0, flipped);
    CGFloat titleHeight = TGMessageCommentTitleLineHeight();
    NSRect textRect = NSMakeRect(NSMaxX(iconRect) + 7.0,
                                 NSMinY(barRect) + floor((NSHeight(barRect) - titleHeight) / 2.0),
                                 MAX(0.0, NSWidth(barRect) - iconSide - 27.0),
                                 titleHeight);
    [title drawInRect:textRect withAttributes:attributes];
}

// Group replies are passive metadata, distinct from channel discussion links.
CGFloat TGMessageReplyIndicatorWidthForItem(TGMessageItem *item) {
    if (![item isKindOfClass:[TGMessageItem class]] || [item isChannelPost] ||
        [[item messageThreadReplyCount] longLongValue] <= 0) return 0.0;
    NSString *count = [[item messageThreadReplyCount] stringValue];
    return 12.0 + 3.0 + ceil([count sizeWithAttributes:[NSDictionary dictionaryWithObject:TGChatMessageMetaFont() forKey:NSFontAttributeName]].width) + 7.0;
}

NSRect TGMessageReplyIndicatorRectForTimeRect(TGMessageItem *item, NSRect timeRect) {
    CGFloat width = TGMessageReplyIndicatorWidthForItem(item);
    return width > 0.0 && !NSIsEmptyRect(timeRect)
        ? NSMakeRect(NSMinX(timeRect)-width, NSMinY(timeRect), width-7.0, NSHeight(timeRect)) : NSZeroRect;
}

void TGDrawMessageReplyIndicatorForTimeRect(TGMessageItem *item, NSRect timeRect, BOOL flipped) {
    NSRect rect = TGMessageReplyIndicatorRectForTimeRect(item,timeRect);
    if (NSIsEmptyRect(rect)) return;
    NSColor *ink = TGMessageMetadataInkColor(item,flipped);
    NSRect icon = NSMakeRect(NSMinX(rect),floor(NSMidY(rect)-6.0),12.0,12.0);
    TGDrawTemplateIconAsset(@"route-arrow",icon,ink,1.0,flipped);
    NSString *count = [[item messageThreadReplyCount] stringValue];
    [count drawInRect:NSMakeRect(NSMaxX(icon)+3.0,NSMinY(rect),MAX(0.0,NSWidth(rect)-15.0),NSHeight(rect))
       withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:TGChatMessageMetaFont(),NSFontAttributeName,ink,NSForegroundColorAttributeName,nil]];
}
