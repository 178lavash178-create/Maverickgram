#import "TGChatListSelectionAppearance.h"
#import "TGAquaAppearance.h"

@interface TGChatSearchResultsTableView : NSTableView
@end

@implementation TGChatSearchResultsTableView

- (void)keyDown:(NSEvent *)event {
    NSUInteger modifiers=[event modifierFlags] & (NSCommandKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSShiftKeyMask);
    NSString *characters=[event charactersIgnoringModifiers];
    unichar key=[characters length]==1 ? [characters characterAtIndex:0] : 0;
    SEL action=NULL;
    if(modifiers==0 && (key=='\r' || key=='\n' || key==3)) action=@selector(commitSearch:);
    else if(modifiers==0 && key==27) action=@selector(closeSearch:);
    else if((modifiers==0 || modifiers==NSShiftKeyMask) && (key=='\t' || key==NSBackTabCharacter)) action=@selector(focusSearchField:);
    if(action && [[self target] respondsToSelector:action]) {
        [self retain];
        [[self target] performSelector:action withObject:self];
        [self release];
        return;
    }
    [super keyDown:event];
}

- (BOOL)isOpaque {
    return YES;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
    /*
     * Paint the result paper, including the empty space after the final row.
     * Clear its backing store explicitly when a search shrinks the result
     * count; otherwise AppKit 10.8/10.9 can leave the previously drawn rows
     * cached below the last real result.
     */
    [TGClassicTablePaperColor() set];
    NSRectFillUsingOperation(clipRect, NSCompositeCopy);
}

- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect {
    NSRect nativeRow = [self rectOfRow:row];
    if (TGInterfaceDesignIsAqua()) {
        NSRect rowRect = NSInsetRect(nativeRow, 4.0, 1.0);
        if (NSIntersectsRect(rowRect, clipRect)) {
            if ([[self selectedRowIndexes] containsIndex:(NSUInteger)row]) {
                [TGListSelectionBackground() set];
                [[NSBezierPath bezierPathWithRoundedRect:rowRect xRadius:4.0 yRadius:4.0] fill];
            } else {
                [TGClassicTableGridColor() set];
                NSRectFill(NSMakeRect(NSMinX(nativeRow)+49.0, NSMaxY(nativeRow)-1.0,
                                     MAX(0.0,NSWidth(nativeRow)-61.0), 1.0));
            }
        }
        [super drawRow:row clipRect:clipRect];
        return;
    }
    NSRect rowRect = NSInsetRect(nativeRow, 4.0, 3.0);
    if (NSIntersectsRect(rowRect, clipRect)) {
        NSBezierPath *rowPath = [NSBezierPath bezierPathWithRoundedRect:rowRect xRadius:7.0 yRadius:7.0];
        TGThemeDrawGroupedCardInPath(rowPath, rowRect, [self isFlipped]);
        [TGClassicTableGridColor() set];
        [rowPath setLineWidth:1.0];
        [rowPath stroke];
    }
    [super drawRow:row clipRect:clipRect];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    NSInteger selectedRow = [self selectedRow];
    if (selectedRow < 0 || selectedRow >= [self numberOfRows]) {
        return;
    }
    BOOL aqua = TGInterfaceDesignIsAqua();
    NSRect rowRect = NSInsetRect([self rectOfRow:selectedRow], 4.0, aqua ? 1.0 : 3.0);
    if (!NSIntersectsRect(rowRect, clipRect)) {
        return;
    }
    NSBezierPath *selectedPath = [NSBezierPath bezierPathWithRoundedRect:rowRect xRadius:(aqua ? 4.0 : 7.0) yRadius:(aqua ? 4.0 : 7.0)];
    [TGListSelectionBackground() set];
    [selectedPath fill];
    if (!aqua) {
        [TGClassicNavigationSelectedStrokeColor(0.62) set];
        [selectedPath setLineWidth:1.0];
        [selectedPath stroke];
    }
}

@end

@interface TGChatSearchResultCell : TGRepresentedObjectCell
@end

@implementation TGChatSearchResultCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    TGSearchResultItem *result = [[self representedObject] isKindOfClass:[TGSearchResultItem class]]
        ? [self representedObject]
        : nil;
    if (!result) {
        return;
    }

    BOOL selected = [self isHighlighted];
    if (TGInterfaceDesignIsAqua() && [controlView isKindOfClass:[NSTableView class]]) {
        // This table owns its rounded highlight and disables native selection
        // drawing, so AppKit does not reliably highlight its data cell.
        NSTableView *table = (NSTableView *)controlView;
        NSInteger row = [table rowAtPoint:NSMakePoint(NSMidX(cellFrame), NSMidY(cellFrame))];
        selected = row >= 0 && [[table selectedRowIndexes] containsIndex:(NSUInteger)row];
    }
    BOOL flipped = [controlView isFlipped];
    BOOL aqua = TGInterfaceDesignIsAqua();
    CGFloat avatarSize = aqua ? 30.0 : 34.0;
    NSRect avatarRect = NSMakeRect(NSMinX(cellFrame) + (aqua ? 10.0 : 9.0),
                                   NSMinY(cellFrame) + floor((NSHeight(cellFrame) - avatarSize) / 2.0),
                                   avatarSize,
                                   avatarSize);
    NSString *title = [result displayTitle];
    TGDrawAvatarInRect([result avatarLocalPath], title, avatarRect, selected, flipped);

    CGFloat textX = NSMaxX(avatarRect) + 11.0;
    CGFloat textWidth = MAX(40.0, NSMaxX(cellFrame) - textX - 12.0);
    NSColor *titleColor = selected ? (TGInterfaceDesignIsAqua() ? TGListSelectionForeground() : TGClassicHeaderTextColor(1.0)) : TGClassicCardInkColor();
    NSColor *detailColor = selected ? (TGInterfaceDesignIsAqua() ? TGListSelectionForeground() : TGClassicHeaderDetailTextColor(0.95)) : TGClassicCardMutedInkColor();
    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setLineBreakMode:(aqua ? NSLineBreakByTruncatingTail : NSLineBreakByWordWrapping)];
    NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     paragraph, NSParagraphStyleAttributeName,
                                     [NSFont boldSystemFontOfSize:(aqua ? 12.0 : 12.5)], NSFontAttributeName,
                                     titleColor, NSForegroundColorAttributeName,
                                     nil];
    NSDictionary *detailAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      paragraph, NSParagraphStyleAttributeName,
                                      [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                                      detailColor, NSForegroundColorAttributeName,
                                      nil];
    [title drawInRect:NSMakeRect(textX, NSMinY(cellFrame) + (aqua ? 5.0 : 7.0), textWidth, 17.0)
       withAttributes:titleAttributes];
    NSString *detail = [result displaySubtitle];
    if ([detail length] == 0) {
        detail = TGLoc(@"search.chats.openHint");
    }
    [detail drawInRect:NSMakeRect(textX, NSMinY(cellFrame) + (aqua ? 23.0 : 25.0), textWidth, 16.0)
        withAttributes:detailAttributes];
}

@end

@interface TGChatSearchPanelView : NSView <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate> {
    id _target;
    SEL _queryChangedAction;
    SEL _commitAction;
    SEL _closeAction;
    NSString *_statusText;
    NSString *_resultsQuery;
    NSArray *_results;
    NSSearchField *_searchField;
    NSTextField *_titleField;
    NSTextField *_statusField;
    NSScrollView *_scrollView;
    NSTableView *_tableView;
}
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL queryChangedAction;
@property (nonatomic, assign) SEL commitAction;
@property (nonatomic, assign) SEL closeAction;
@property (nonatomic, copy) NSString *query;
@property (nonatomic, copy) NSString *statusText;
@property (nonatomic, retain) NSArray *results;
@property (nonatomic, assign) NSInteger selectedIndex;
- (TGSearchResultItem *)selectedResult;
- (NSSearchField *)searchField;
- (void)layoutPanelSubviews;
- (void)updateResultsDocumentGeometry;
@end

@implementation TGChatSearchPanelView

@synthesize target = _target;
@synthesize queryChangedAction = _queryChangedAction;
@synthesize commitAction = _commitAction;
@synthesize closeAction = _closeAction;
@synthesize statusText = _statusText;
@synthesize results = _results;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _statusText = [TGLoc(@"search.chats.recent") copy];
        _results = [[NSArray alloc] init];

        _titleField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        [_titleField setEditable:NO];
        [_titleField setBordered:NO];
        [_titleField setDrawsBackground:NO];
        [_titleField setSelectable:NO];
        [[_titleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [_titleField setFont:[NSFont boldSystemFontOfSize:16.0]];
        [_titleField setTextColor:TGClassicInkColor()];
        [_titleField setStringValue:TGLoc(@"search.chats.title")];
        [self addSubview:_titleField];

        _searchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
        [_searchField setDelegate:self];
        [_searchField setTarget:self];
        if (TGInterfaceDesignIsAqua()) [_searchField setAction:@selector(searchFieldAction:)];
        [_searchField setBezeled:TGInterfaceDesignIsAqua()];
        if (!TGInterfaceDesignIsAqua()) [_searchField setBordered:NO];
        [_searchField setDrawsBackground:TGInterfaceDesignIsAqua()];
        [_searchField setFocusRingType:(TGInterfaceDesignIsAqua() ? NSFocusRingTypeDefault : NSFocusRingTypeNone)];
        if (!TGInterfaceDesignIsAqua() && [[_searchField cell] respondsToSelector:@selector(setSearchButtonCell:)]) {
            [[_searchField cell] setSearchButtonCell:nil];
        }
        if (!TGInterfaceDesignIsAqua() && [[_searchField cell] respondsToSelector:@selector(setCancelButtonCell:)]) {
            [[_searchField cell] setCancelButtonCell:nil];
        }
        [[_searchField cell] setPlaceholderString:TGLoc(@"search.chats.placeholder")];
        [self addSubview:_searchField];

        _statusField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        [_statusField setEditable:NO];
        [_statusField setBordered:NO];
        [_statusField setDrawsBackground:NO];
        [_statusField setSelectable:NO];
        [[_statusField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [_statusField setFont:[NSFont systemFontOfSize:11.0]];
        [_statusField setTextColor:TGClassicMutedInkColor()];
        [_statusField setStringValue:(TGInterfaceDesignIsAqua() ? TGLoc(@"search.chats.recentShort") : _statusText)];
        [self addSubview:_statusField];

        _tableView = [[TGChatSearchResultsTableView alloc] initWithFrame:NSZeroRect];
        [_tableView setHeaderView:nil];
        [_tableView setRowHeight:(TGInterfaceDesignIsAqua() ? 44.0 : 50.0)];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setTarget:self];
        [_tableView setAction:@selector(commitSearch:)];
        [_tableView setDoubleAction:@selector(commitSearch:)];
        [_tableView setAllowsEmptySelection:YES];
        [_tableView setBackgroundColor:TGClassicTablePaperColor()];
        [_tableView setUsesAlternatingRowBackgroundColors:NO];
        [_tableView setGridStyleMask:NSTableViewGridNone];
        [_tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
        [_tableView setIntercellSpacing:NSMakeSize(0.0, TGInterfaceDesignIsAqua() ? 0.0 : 1.0)];

        NSTableColumn *resultColumn = [[[NSTableColumn alloc] initWithIdentifier:@"result"] autorelease];
        [resultColumn setWidth:400.0];
        [resultColumn setResizingMask:NSTableColumnAutoresizingMask];
        [resultColumn setDataCell:[[[TGChatSearchResultCell alloc] initTextCell:@""] autorelease]];
        [_tableView addTableColumn:resultColumn];

        _scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
        [_scrollView setHasVerticalScroller:YES];
        [_scrollView setHasHorizontalScroller:NO];
        [_scrollView setBorderType:NSNoBorder];
        [_scrollView setDrawsBackground:YES];
        [_scrollView setBackgroundColor:TGClassicTablePaperColor()];
        [[_scrollView contentView] setDrawsBackground:YES];
        [[_scrollView contentView] setBackgroundColor:TGClassicTablePaperColor()];
        [_scrollView setAutohidesScrollers:YES];
        [_scrollView setDocumentView:_tableView];
        [self addSubview:_scrollView];
        [_searchField setNextKeyView:_tableView];
        [_tableView setNextKeyView:_searchField];

        [self layoutPanelSubviews];
    }
    return self;
}

- (void)dealloc {
    [_statusText release];
    [_resultsQuery release];
    [_results release];
    [_searchField release];
    [_titleField release];
    [_statusField release];
    [_scrollView release];
    [_tableView release];
    [super dealloc];
}

- (BOOL)isFlipped {
    return YES;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    (void)oldSize;
    [self layoutPanelSubviews];
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    [self layoutPanelSubviews];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self layoutPanelSubviews];
}

- (void)layoutPanelSubviews {
    NSRect bounds = [self bounds];
    CGFloat inset = 18.0;
    if (TGInterfaceDesignIsAqua()) {
        // One native query field, one quiet section line, then the source list.
        // No repeated title or nested row cards inside an already framed popover.
        CGFloat available = MAX(0.0, NSWidth(bounds) - 24.0);
        [_titleField setHidden:YES];
        [_titleField setFrame:NSZeroRect];
        [_searchField setFrame:NSMakeRect(12.0, 12.0, available, 26.0)];
        [_statusField setFrame:NSMakeRect(14.0, 46.0, MAX(0.0,NSWidth(bounds)-28.0), 17.0)];
        [_scrollView setFrame:NSMakeRect(0.0, 70.0, NSWidth(bounds), MAX(0.0, NSHeight(bounds) - 76.0))];
    } else {
        [_titleField setFrame:NSMakeRect(inset + 6.0, 18.0, MAX(80.0, NSWidth(bounds) - (inset * 2.0) - 12.0), 22.0)];
        [_searchField setFrame:NSMakeRect(inset + 48.0, 67.0, MAX(92.0, NSWidth(bounds) - (inset * 2.0) - 62.0), 21.0)];
        [_statusField setFrame:NSMakeRect(inset + 16.0, 101.0, MAX(120.0, NSWidth(bounds) - (inset * 2.0) - 32.0), 18.0)];
        [_scrollView setFrame:NSMakeRect(inset + 12.0, 138.0, MAX(120.0, NSWidth(bounds) - (inset * 2.0) - 24.0), MAX(80.0, NSHeight(bounds) - 162.0))];
    }
    [self updateResultsDocumentGeometry];
    CGFloat tableWidth = NSWidth([[_scrollView contentView] bounds]);
    NSArray *columns = [_tableView tableColumns];
    if ([columns count] == 1) {
        [[columns objectAtIndex:0] setWidth:MAX(100.0, tableWidth)];
    }
    [self setNeedsDisplay:YES];
}

- (void)updateResultsDocumentGeometry {
    NSClipView *clipView = [_scrollView contentView];
    NSPoint origin = [clipView bounds].origin;
    CGFloat visibleHeight = NSHeight([clipView bounds]);
    NSSize intercellSpacing = [_tableView intercellSpacing];
    CGFloat rowExtent = [_tableView rowHeight] + intercellSpacing.height;
    CGFloat documentHeight = MAX(1.0, ((CGFloat)[_results count] * rowExtent));
    BOOL needsVerticalScroller = documentHeight > visibleHeight + 0.5;

    if ([_scrollView hasVerticalScroller] != needsVerticalScroller) {
        [_scrollView setHasVerticalScroller:needsVerticalScroller];
        [_scrollView tile];
    }

    CGFloat documentWidth = NSWidth([clipView bounds]);
    [_tableView setFrame:NSMakeRect(0.0, 0.0, MAX(1.0, documentWidth), documentHeight)];
    // A window resize must not jump a user back to the first search result.
    origin.x = 0;
    origin.y = MAX(0.0, MIN(origin.y, documentHeight - visibleHeight));
    [clipView scrollToPoint:origin];
    [_scrollView reflectScrolledClipView:clipView];
    [clipView setNeedsDisplay:YES];
    [_tableView setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSRect bounds = [self bounds];
    if (TGInterfaceDesignIsAqua()) {
        [TGClassicTablePaperColor() set]; NSRectFill(bounds);
        NSRect header = NSMakeRect(0, 0, NSWidth(bounds), 69.0);
        TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:header], header, TGThemeSurfaceHeader, [self isFlipped]);
        [TGClassicTableGridColor() set];
        NSRectFill(NSMakeRect(0.0,69.0,NSWidth(bounds),1.0));
        return;
    }
    TGThemeDrawWindowBackgroundInRect(bounds, [self isFlipped]);

    NSRect shellRect = NSInsetRect(bounds, 10.0, 10.0);
    NSBezierPath *shellPath = [NSBezierPath bezierPathWithRoundedRect:shellRect xRadius:12.0 yRadius:12.0];
    TGThemeDrawPanelBackgroundInPath(shellPath, shellRect, [self isFlipped]);
    [TGClassicPanelStrokeColor() set];
    [shellPath setLineWidth:1.0];
    [shellPath stroke];

    NSRect searchCardRect = NSMakeRect(22.0, 50.0, MAX(120.0, NSWidth(bounds) - 44.0), 74.0);
    NSBezierPath *searchCardPath = [NSBezierPath bezierPathWithRoundedRect:searchCardRect xRadius:10.0 yRadius:10.0];
    TGThemeDrawGroupedCardInPath(searchCardPath, searchCardRect, [self isFlipped]);
    [TGClassicTableGridColor() set];
    [searchCardPath setLineWidth:1.0];
    [searchCardPath stroke];

    NSRect inputRect = NSInsetRect([_searchField frame], -2.0, -2.0);
    inputRect.origin.x -= 30.0;
    inputRect.size.width += 30.0;
    NSBezierPath *inputPath = [NSBezierPath bezierPathWithRoundedRect:inputRect xRadius:8.0 yRadius:8.0];
    TGThemeDrawRecessedBackgroundInPath(inputPath, inputRect, [self isFlipped]);
    [TGClassicTableGridColor() set];
    [inputPath setLineWidth:1.0];
    [inputPath stroke];
    TGDrawTemplateIconAsset(@"search",
                            NSMakeRect(NSMinX(inputRect) + 8.0, NSMidY(inputRect) - 7.0, 14.0, 14.0),
                            TGClassicMutedInkColor(),
                            1.0,
                            [self isFlipped]);

    NSRect resultsCardRect = NSInsetRect([_scrollView frame], -8.0, -8.0);
    NSBezierPath *resultsCardPath = [NSBezierPath bezierPathWithRoundedRect:resultsCardRect xRadius:10.0 yRadius:10.0];
    TGThemeDrawGroupedCardInPath(resultsCardPath, resultsCardRect, [self isFlipped]);
    [TGClassicPanelStrokeColor() set];
    [resultsCardPath setLineWidth:1.0];
    [resultsCardPath stroke];
}

- (NSSearchField *)searchField {
    return _searchField;
}

- (NSString *)query {
    return [_searchField stringValue] ? [_searchField stringValue] : @"";
}

- (void)setQuery:(NSString *)query {
    [_searchField setStringValue:(query ? query : @"")];
}

- (void)setStatusText:(NSString *)statusText {
    if (_statusText == statusText || [_statusText isEqualToString:statusText]) {
        return;
    }
    [_statusText release];
    _statusText = [statusText copy];
    NSString *display = _statusText ? _statusText : @"";
    if (TGInterfaceDesignIsAqua() && [display isEqualToString:TGLoc(@"search.chats.recent")])
        display = TGLoc(@"search.chats.recentShort");
    [_statusField setStringValue:display];
}

- (void)setResults:(NSArray *)results {
    // Server additions for the same query must not replace a keyboard choice.
    NSString *query=[self query];
    BOOL sameQuery=(_resultsQuery && [_resultsQuery isEqualToString:query]);
    TGSearchResultItem *selected=sameQuery ? [[self selectedResult] retain] : nil;
    NSPoint origin=sameQuery ? [[_scrollView contentView] bounds].origin : NSZeroPoint;
    NSArray *snapshot = results ? [[NSArray alloc] initWithArray:results] : [[NSArray alloc] init];
    [_results release];_results=snapshot;
    [_resultsQuery release];_resultsQuery=[query copy];
    NSInteger selectedIndex=-1;
    if(selected) {
        NSUInteger index=0;
        for(TGSearchResultItem *candidate in _results) {
            if([candidate isKindOfClass:[TGSearchResultItem class]]) {
                BOOL sameIdentity=([candidate chatID] && [[candidate chatID] isEqual:[selected chatID]] &&
                    ((! [candidate messageThreadID] && ![selected messageThreadID]) || [[candidate messageThreadID] isEqual:[selected messageThreadID]]) &&
                    ((! [candidate messageTopicKind] && ![selected messageTopicKind]) || [[candidate messageTopicKind] isEqual:[selected messageTopicKind]]));
                if(candidate==selected || sameIdentity) { selectedIndex=(NSInteger)index;break; }
            }
            index++;
        }
    }
    [_tableView reloadData];
    [self setSelectedIndex:selectedIndex];
    [self updateResultsDocumentGeometry];
    NSClipView *clip=[_scrollView contentView];
    origin.y=MAX(0,MIN(origin.y,NSHeight([_tableView bounds])-NSHeight([clip bounds])));
    [clip scrollToPoint:origin];[_scrollView reflectScrolledClipView:clip];
    if(selectedIndex>=0) [_tableView scrollRowToVisible:selectedIndex];
    [selected release];
}

- (TGSearchResultItem *)selectedResult {
    NSInteger selectedRow = [_tableView selectedRow];
    if (selectedRow < 0 || (NSUInteger)selectedRow >= [_results count]) {
        return nil;
    }
    id candidate = [_results objectAtIndex:(NSUInteger)selectedRow];
    return [candidate isKindOfClass:[TGSearchResultItem class]] ? (TGSearchResultItem *)candidate : nil;
}

- (NSInteger)selectedIndex {
    return [_tableView selectedRow];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (selectedIndex < 0 || (NSUInteger)selectedIndex >= [_results count]) {
        [_tableView deselectAll:self];
        return;
    }
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)selectedIndex] byExtendingSelection:NO];
}

- (void)sendAction:(SEL)selector {
    if (_target && selector && [_target respondsToSelector:selector]) {
        [_target performSelector:selector withObject:self];
    }
}

- (void)searchFieldAction:(id)sender {
    (void)sender;
    // Native cancel sends an action; it need not post a text-change notification.
    if ([[self query] length] == 0) [self sendAction:_queryChangedAction];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    (void)notification;
    [self sendAction:_queryChangedAction];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if(control!=_searchField || [textView hasMarkedText]) return NO;
    if(commandSelector==@selector(insertTab:) || commandSelector==@selector(insertBacktab:)) {
        if([_results count]==0) return NO;
        if([_tableView selectedRow]<0) [self setSelectedIndex:0];
        [[self window] makeFirstResponder:_tableView];
        [_tableView scrollRowToVisible:[_tableView selectedRow]];
        return YES;
    }
    if (commandSelector == @selector(cancelOperation:)) {
        [self closeSearch:self];
        return YES;
    }
    if (commandSelector == @selector(insertNewline:) ||
        commandSelector == @selector(insertNewlineIgnoringFieldEditor:)) {
        [self commitSearch:self];
        return YES;
    }
    if (commandSelector == @selector(moveDown:) || commandSelector == @selector(moveUp:)) {
        NSInteger resultCount = (NSInteger)[_results count];
        if (resultCount == 0) {
            return YES;
        }
        NSInteger selectedRow = [_tableView selectedRow];
        if (commandSelector == @selector(moveDown:)) {
            selectedRow = (selectedRow < 0) ? 0 : MIN(resultCount - 1, selectedRow + 1);
        } else {
            selectedRow = (selectedRow < 0) ? (resultCount - 1) : MAX(0, selectedRow - 1);
        }
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)selectedRow] byExtendingSelection:NO];
        [_tableView scrollRowToVisible:selectedRow];
        return YES;
    }
    return NO;
}

- (void)commitSearch:(id)sender {
    (void)sender;
    if (![self selectedResult] && [_results count] > 0) {
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    if ([self selectedResult]) {
        [self sendAction:_commitAction];
    }
}

- (void)focusSearchField:(id)sender {
    (void)sender;
    [[self window] makeFirstResponder:_searchField];
}

- (void)cancelOperation:(id)sender { [self closeSearch:sender]; }

- (void)closeSearch:(id)sender {
    (void)sender;
    [self sendAction:_closeAction];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    (void)tableView;
    return (NSInteger)[_results count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    (void)tableView;
    if (row < 0 || (NSUInteger)row >= [_results count]) {
        return @"";
    }
    id candidate = [_results objectAtIndex:(NSUInteger)row];
    TGSearchResultItem *result = [candidate isKindOfClass:[TGSearchResultItem class]] ? (TGSearchResultItem *)candidate : nil;
    return result;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    (void)notification;
}

- (void)resetCursorRects {
    [super resetCursorRects];
    [self addCursorRect:[_scrollView frame] cursor:[NSCursor pointingHandCursor]];
}

@end
