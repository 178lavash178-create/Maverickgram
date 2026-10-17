#import "TGLocalization.h"
#import "TGChatListSelectionAppearance.h"
@interface TGFolderSourceListView : NSTableView @end
@implementation TGFolderSourceListView
- (BOOL)isOpaque {return YES;}
- (void)drawBackgroundInClipRect:(NSRect)clip {[TGClassicTablePaperColor() set];NSRectFillUsingOperation(clip,NSCompositeCopy);}
- (void)highlightSelectionInClipRect:(NSRect)clip {(void)clip;}
- (void)drawRow:(NSInteger)row clipRect:(NSRect)clip {
    NSRect rowFrame=[self rectOfRow:row];rowFrame.origin.x=NSMinX([self bounds]);rowFrame.size.width=NSWidth([self bounds]);
    NSRect frame=NSInsetRect(rowFrame,4,2);
    if([[self selectedRowIndexes] containsIndex:(NSUInteger)row] && NSIntersectsRect(frame,clip)) {
        [TGListSelectionBackground() set];[[NSBezierPath bezierPathWithRoundedRect:frame xRadius:4 yRadius:4] fill];
    }
    [super drawRow:row clipRect:clip];
}
@end
@interface TGChatFolderListCell : TGRepresentedObjectCell
@end

@implementation TGChatFolderListCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSDictionary *folder = [[self representedObject] isKindOfClass:[NSDictionary class]]
        ? [self representedObject]
        : nil;
    if (!folder) {
        return;
    }

    BOOL highlighted = [self isHighlighted];
    BOOL ownsSelection=[controlView isKindOfClass:[TGFolderSourceListView class]];
    if(ownsSelection) {NSTableView *table=(NSTableView *)controlView;NSInteger row=[table rowAtPoint:NSMakePoint(NSMidX(cellFrame),NSMidY(cellFrame))];highlighted=row>=0&&[[table selectedRowIndexes] containsIndex:(NSUInteger)row];}
    NSColor *surface=highlighted ? TGListSelectionBackground() : TGClassicTablePaperColor();
    if(!ownsSelection){[surface setFill]; NSRectFill(cellFrame);}
    NSColor *titleColor=TGThemeReadableInk(highlighted ? TGListSelectionForeground() : TGClassicCardInkColor(),surface,4.5);
    NSColor *detailColor=TGThemeReadableInk(highlighted ? titleColor : TGClassicCardMutedInkColor(),surface,4.5);
    NSRect iconRect = NSMakeRect(NSMinX(cellFrame) + 8.0,
                                 NSMinY(cellFrame) + floor((NSHeight(cellFrame) - 18.0) / 2.0),
                                 18.0,
                                 18.0);
    TGDrawTemplateIconAsset(@"folder", iconRect, titleColor, 0.92, [controlView isFlipped]);

    CGFloat textX = NSMaxX(iconRect) + 8.0;
    CGFloat textWidth = MAX(36.0, NSMaxX(cellFrame) - textX - 8.0);
    BOOL shared = [[folder objectForKey:@"is_shareable"] boolValue];
    NSMutableParagraphStyle *paragraph=[[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setLineBreakMode:TGInterfaceDesignIsAqua() ? NSLineBreakByTruncatingTail : NSLineBreakByWordWrapping];
    NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     paragraph, NSParagraphStyleAttributeName,
                                     [NSFont boldSystemFontOfSize:12.0], NSFontAttributeName,
                                     titleColor, NSForegroundColorAttributeName,
                                     nil];
    NSDictionary *detailAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      paragraph, NSParagraphStyleAttributeName,
                                      [NSFont systemFontOfSize:10.0], NSFontAttributeName,
                                      detailColor, NSForegroundColorAttributeName,
                                      nil];
    NSString *title = [[folder objectForKey:@"title"] isKindOfClass:[NSString class]]
        ? [folder objectForKey:@"title"]
        : @"";
    CGFloat titleY = shared ? NSMinY(cellFrame) + 5.0 : NSMinY(cellFrame) + 12.0;
    [title drawInRect:NSMakeRect(textX, titleY, textWidth, 16.0)
       withAttributes:titleAttributes];
    if (shared) {
        [TGLoc(@"folders.shared") drawInRect:NSMakeRect(textX,
                                                        NSMinY(cellFrame) + 21.0,
                                                        textWidth,
                                                        13.0)
                              withAttributes:detailAttributes];
    }
}

@end

@interface TGChatFolderChatCell : TGRepresentedObjectCell
@end

@implementation TGChatFolderChatCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    TGChatItem *item = [[self representedObject] isKindOfClass:[TGChatItem class]]
        ? [self representedObject]
        : nil;
    if (!item) {
        return;
    }
    BOOL highlighted = [self isHighlighted];
    BOOL ownsSelection=[controlView isKindOfClass:[TGFolderSourceListView class]];
    if(ownsSelection) {NSTableView *table=(NSTableView *)controlView;NSInteger row=[table rowAtPoint:NSMakePoint(NSMidX(cellFrame),NSMidY(cellFrame))];highlighted=row>=0&&[[table selectedRowIndexes] containsIndex:(NSUInteger)row];}
    NSColor *surface=highlighted ? TGListSelectionBackground() : TGClassicTablePaperColor();
    if(!ownsSelection){[surface setFill]; NSRectFill(cellFrame);}
    NSColor *titleColor=TGThemeReadableInk(highlighted ? TGListSelectionForeground() : TGClassicCardInkColor(),surface,4.5);
    NSColor *detailColor=TGThemeReadableInk(highlighted ? titleColor : TGClassicCardMutedInkColor(),surface,4.5);
    NSRect avatarRect = NSMakeRect(NSMinX(cellFrame) + 5.0,
                                   NSMinY(cellFrame) + floor((NSHeight(cellFrame) - 28.0) / 2.0),
                                   28.0,
                                   28.0);
    TGDrawAvatarInRect([item avatarLocalPath],
                       [item title],
                       avatarRect,
                       highlighted,
                       [controlView isFlipped]);

    CGFloat textX = NSMaxX(avatarRect) + 9.0;
    CGFloat width = MAX(40.0, NSMaxX(cellFrame) - textX - 8.0);
    NSMutableParagraphStyle *paragraph=[[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setLineBreakMode:TGInterfaceDesignIsAqua() ? NSLineBreakByTruncatingTail : NSLineBreakByWordWrapping];
    NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     paragraph, NSParagraphStyleAttributeName,
                                     [NSFont boldSystemFontOfSize:12.0], NSFontAttributeName,
                                     titleColor, NSForegroundColorAttributeName,
                                     nil];
    NSDictionary *detailAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      paragraph, NSParagraphStyleAttributeName,
                                      [NSFont systemFontOfSize:10.0], NSFontAttributeName,
                                      detailColor, NSForegroundColorAttributeName,
                                      nil];
    [[item title] drawInRect:NSMakeRect(textX, NSMinY(cellFrame) + 4.0, width, 16.0)
              withAttributes:titleAttributes];
    [TGLocalizedChatTypeSummary([item typeSummary]) drawInRect:NSMakeRect(textX, NSMinY(cellFrame) + 20.0, width, 14.0)
                    withAttributes:detailAttributes];
}

@end

