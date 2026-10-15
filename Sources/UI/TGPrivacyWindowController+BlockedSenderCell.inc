@interface TGBlockedSenderCell : TGRepresentedObjectCell
@end

@implementation TGBlockedSenderCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSDictionary *summary = [[self representedObject] isKindOfClass:[NSDictionary class]]
        ? [self representedObject]
        : nil;
    if (!summary) {
        return;
    }

    BOOL selected = [self isHighlighted];
    BOOL flipped = [controlView isFlipped];
    NSString *title = [summary objectForKey:@"title"];
    if ([title length] == 0) {
        title = TGLoc(@"chat.untitled");
    }
    NSRect avatarRect = NSMakeRect(NSMinX(cellFrame) + 10.0,
                                   NSMinY(cellFrame) + floor((NSHeight(cellFrame) - 36.0) / 2.0),
                                   36.0,
                                   36.0);
    CGFloat textX = NSMaxX(avatarRect) + 11.0;
    CGFloat textWidth = MAX(40.0, NSMaxX(cellFrame) - textX - 12.0);
    /* Own the row surface, rather than pairing theme header text with an
       unrelated native selection gradient or a transparent table background. */
    NSColor *surface = selected ? TGClassicSelectedRowColor() : TGClassicTablePaperColor();
    [surface setFill];
    NSRectFill(cellFrame);
    TGDrawAvatarInRect([summary objectForKey:@"avatar_local_path"], title, avatarRect, selected, flipped);
    NSColor *ink = TGThemeReadableInk(selected ? TGClassicSelectedRowTextColor() : TGClassicCardInkColor(), surface, 4.5);
    NSColor *muted = TGThemeReadableInk(selected ? ink : TGClassicCardMutedInkColor(), surface, 4.5);
    NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSFont boldSystemFontOfSize:12.5], NSFontAttributeName,
                                     ink, NSForegroundColorAttributeName,
                                     nil];
    NSDictionary *detailAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSFont systemFontOfSize:10.5], NSFontAttributeName,
                                      muted, NSForegroundColorAttributeName,
                                      nil];
    [title drawInRect:NSMakeRect(textX, NSMinY(cellFrame) + 7.0, textWidth, 17.0)
       withAttributes:titleAttributes];
    NSString *username = [summary objectForKey:@"username"];
    NSString *detail = [username length] > 0
        ? [NSString stringWithFormat:@"@%@", username]
        : @"";
    if ([detail length] > 0) {
        [detail drawInRect:NSMakeRect(textX, NSMinY(cellFrame) + 25.0, textWidth, 15.0)
            withAttributes:detailAttributes];
    }
}

@end

