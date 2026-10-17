@interface TGNotificationExceptionTableView : NSTableView @end
@implementation TGNotificationExceptionTableView
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
@interface TGNotificationExceptionCell : TGRepresentedObjectCell @end
@implementation TGNotificationExceptionCell
- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
    NSDictionary *summary=[[self representedObject] isKindOfClass:[NSDictionary class]] ? [self representedObject] : nil;if(!summary)return;
    BOOL selected=[self isHighlighted];BOOL ownsSelection=[view isKindOfClass:[TGNotificationExceptionTableView class]];if(ownsSelection){NSTableView *table=(NSTableView *)view;NSInteger row=[table rowAtPoint:NSMakePoint(NSMidX(frame),NSMidY(frame))];selected=row>=0&&[[table selectedRowIndexes] containsIndex:(NSUInteger)row];}
    NSColor *paper=selected ? TGListSelectionBackground():TGClassicTablePaperColor();if(!ownsSelection){[paper set];NSRectFill(frame);}
    NSColor *ink=selected ? TGListSelectionForeground():TGClassicCardInkColor();NSColor *detail=selected ? ink:TGClassicCardMutedInkColor();
    NSString *title=[[summary objectForKey:@"title"] isKindOfClass:[NSString class]] ? [summary objectForKey:@"title"]:TGLoc(@"chat.untitled");
    if(![title length])title=TGLoc(@"chat.untitled");
    NSString *avatar=[[summary objectForKey:@"avatar_local_path"] isKindOfClass:[NSString class]] ? [summary objectForKey:@"avatar_local_path"]:nil;
    TGDrawAvatarInRect(avatar,title,NSMakeRect(NSMinX(frame)+8,NSMinY(frame)+7,30,30),selected,[view isFlipped]);
    NSMutableParagraphStyle *paragraph=[[[NSMutableParagraphStyle alloc] init] autorelease];[paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *titleAttributes=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:12],NSFontAttributeName,ink,NSForegroundColorAttributeName,paragraph,NSParagraphStyleAttributeName,nil];
    NSDictionary *detailAttributes=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:10],NSFontAttributeName,detail,NSForegroundColorAttributeName,paragraph,NSParagraphStyleAttributeName,nil];
    CGFloat x=NSMinX(frame)+48,width=MAX(0,NSMaxX(frame)-x-8);
    [title drawInRect:NSMakeRect(x,NSMinY(frame)+5,width,17) withAttributes:titleAttributes];
    [TGLoc([[summary objectForKey:@"muted"] boolValue] ? @"folders.muted":@"notifications.exceptions.on") drawInRect:NSMakeRect(x,NSMinY(frame)+23,width,15) withAttributes:detailAttributes];
}
@end
