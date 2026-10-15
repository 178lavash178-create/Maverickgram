#import "TGAquaFolderDrawer.h"
#import "TGAquaShellViews.h"
#import "TGLocalization.h"
#include <math.h>

NSString * const TGAquaFolderDrawerPlacementDidChangeNotification = @"TGAquaFolderDrawerPlacementDidChangeNotification";

TGAquaFolderDrawerGeometry TGAquaFolderDrawerPlacement(NSRect parent, NSRect visible, CGFloat parentHeight, NSUInteger count, BOOL fullScreen) {
    TGAquaFolderDrawerGeometry result = {NO, NSMinXEdge, {240.0, 0.0}};
    if (fullScreen || count == 0 || !isfinite(parentHeight) || parentHeight < 98.0 ||
        !isfinite(parent.origin.x) || !isfinite(parent.origin.y) || !isfinite(parent.size.width) || !isfinite(parent.size.height) ||
        !isfinite(visible.origin.x) || !isfinite(visible.origin.y) || !isfinite(visible.size.width) || !isfinite(visible.size.height) ||
        NSIsEmptyRect(parent) || NSIsEmptyRect(visible)) return result;
    CGFloat room = result.contentSize.width + 16.0 + 8.0;
    BOOL left = NSMinX(parent) - NSMinX(visible) >= room;
    BOOL right = NSMaxX(visible) - NSMaxX(parent) >= room;
    if (!left && !right) return result;
    result.canShow = YES;
    result.edge = left ? NSMinXEdge : NSMaxXEdge;
    result.contentSize.height = MIN(parentHeight - 16.0, 50.0 + MIN((CGFloat)count, 100000.0) * 32.0);
    return result;
}

NSRect TGAquaFolderDrawerPreparedParentFrame(NSRect parent, NSRect visible, BOOL fullScreen) {
    if (fullScreen || !isfinite(parent.origin.x) || !isfinite(parent.origin.y) ||
        !isfinite(parent.size.width) || !isfinite(parent.size.height) ||
        !isfinite(visible.origin.x) || !isfinite(visible.origin.y) ||
        !isfinite(visible.size.width) || !isfinite(visible.size.height) ||
        NSIsEmptyRect(parent) || NSIsEmptyRect(visible)) return parent;
    CGFloat room = 240.0 + 16.0 + 8.0;
    if (NSMinX(parent)-NSMinX(visible)>=room || NSMaxX(visible)-NSMaxX(parent)>=room ||
        NSWidth(parent)+room>NSWidth(visible)) return parent;
    CGFloat leftX = NSMinX(visible)+room;
    CGFloat rightX = NSMaxX(visible)-NSWidth(parent)-room;
    // Both candidates keep the complete parent and native drawer horizontally
    // inside the selected display. Ties retain the preferred left drawer.
    CGFloat candidateX = fabs(leftX-NSMinX(parent))<=fabs(rightX-NSMinX(parent)) ? leftX : rightX;
    if (candidateX<NSMinX(visible) || candidateX+NSWidth(parent)>NSMaxX(visible)) return parent;
    parent.origin.x = candidateX;
    return parent;
}

@interface TGAquaDrawerDocumentView : NSView
@end
@implementation TGAquaDrawerDocumentView
- (BOOL)isFlipped { return YES; }
@end

@implementation TGAquaFolderDrawer
- (NSDrawer *)drawer { return _drawer; }
- (NSView *)contentView { return _contentView; }
- (NSScrollView *)folderScrollView { return _folderScrollView; }

- (id)initWithParentWindow:(NSWindow *)window folderScrollView:(NSScrollView *)scrollView editTarget:(id)target editAction:(SEL)action {
    self = [super init];
    if (!self) return nil;
    _parentWindow = window;
    _folderScrollView = [scrollView retain];
    _folderButtons = [[NSArray alloc] init];
    _contentView = [[TGAquaMetalView alloc] initWithFrame:NSMakeRect(0,0,240,82)];
    _titleField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [_titleField setEditable:NO]; [_titleField setSelectable:NO]; [_titleField setBordered:NO]; [_titleField setDrawsBackground:NO];
    [_titleField setFont:[NSFont boldSystemFontOfSize:11]];
    [_titleField setTextColor:[NSColor colorWithCalibratedWhite:0.23 alpha:1]];
    [_contentView addSubview:_titleField];
    _editButton = [[NSButton alloc] initWithFrame:NSZeroRect];
    TGAquaSectionButtonCell *cell = [[[TGAquaSectionButtonCell alloc] initTextCell:@""] autorelease];
    [cell setAlignment:NSRightTextAlignment]; [_editButton setCell:cell];
    [_editButton setBordered:NO]; [_editButton setTarget:target]; [_editButton setAction:action];
    [_contentView addSubview:_editButton];
    _drawer = [[NSDrawer alloc] initWithContentSize:NSMakeSize(240,82) preferredEdge:NSMinXEdge];
    [_drawer setParentWindow:window]; [_drawer setContentView:_contentView]; [_drawer setDelegate:self];
    [_drawer setLeadingOffset:8]; [_drawer setTrailingOffset:8];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    for (NSString *name in [NSArray arrayWithObjects:NSWindowDidMoveNotification,NSWindowDidResizeNotification,
         NSWindowDidChangeScreenNotification,NSWindowDidDeminiaturizeNotification,
         NSWindowDidEnterFullScreenNotification,NSWindowDidExitFullScreenNotification,nil]) {
        [center addObserver:self selector:@selector(parentGeometryChanged:) name:name object:window];
    }
    [center addObserver:self selector:@selector(parentWillClose:) name:NSWindowWillCloseNotification object:window];
    [center addObserver:self selector:@selector(parentGeometryChanged:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    [self refreshLocalization];
    return self;
}

- (TGAquaFolderDrawerGeometry)currentPlacement {
    NSScreen *screen = [_parentWindow screen];
    NSRect visible = screen ? [screen visibleFrame] : NSZeroRect;
    BOOL fullScreen = ([_parentWindow styleMask] & NSFullScreenWindowMask) != 0;
    return TGAquaFolderDrawerPlacement([_parentWindow frame], visible,
        NSHeight([[_parentWindow contentView] bounds]), [_folderButtons count], fullScreen);
}
- (BOOL)canShowExternally { return _parentWindow && [self currentPlacement].canShow; }
- (BOOL)prepareToOpen {
    if (![NSThread isMainThread] || !_parentWindow || ![_parentWindow isVisible] || [_parentWindow isMiniaturized] || [_folderButtons count]==0) return NO;
    TGAquaFolderDrawerGeometry placement = [self currentPlacement];
    if (placement.canShow) return YES;
    NSScreen *screen = [_parentWindow screen];
    if (!screen || NSHeight([[_parentWindow contentView] bounds])<98) return NO;
    BOOL fullScreen = ([_parentWindow styleMask] & NSFullScreenWindowMask)!=0;
    NSRect current = [_parentWindow frame];
    NSRect proposed = TGAquaFolderDrawerPreparedParentFrame(current,[screen visibleFrame],fullScreen);
    if (!NSEqualRects(current,proposed)) [_parentWindow setFrame:proposed display:YES animate:YES];
    [self layout];
    return [self canShowExternally];
}
- (BOOL)isOpen { NSInteger state = [_drawer state]; return state == NSDrawerOpenState || state == NSDrawerOpeningState; }
- (void)setFolderButtons:(NSArray *)buttons {
    NSArray *next = buttons ? buttons : [NSArray array];
    if (_folderButtons != next) {
        [_folderButtons release]; _folderButtons = [next copy];
    }
}
- (void)refreshLocalization {
    NSString *language = TGLanguageCode();
    [_titleField setStringValue:[language isEqual:@"ru"] ? @"Папки" : ([language isEqual:@"be"] ? @"Папкі" : @"Folders")];
    [_editButton setTitle:[language isEqual:@"ru"] ? @"Изменить" : ([language isEqual:@"be"] ? @"Змяніць" : @"Edit")];
    [self layout];
}
- (void)attachFolderScrollView {
    if ([_folderScrollView superview] != _contentView) {
        [_folderScrollView removeFromSuperview]; [_contentView addSubview:_folderScrollView];
    }
}
- (void)detachFolderScrollView {
    [self setVisible:NO];
    if ([_folderScrollView superview] == _contentView) [_folderScrollView removeFromSuperview];
}
- (void)setVisible:(BOOL)visible { _requestedVisible = visible; [self layout]; }

- (void)layout {
    if (_layoutInProgress) return;
    _layoutInProgress = YES;
    TGAquaFolderDrawerGeometry geometry = [self currentPlacement];
    _hasPlacement = YES; _lastCanShow = geometry.canShow;
    if (geometry.canShow) {
        [_drawer setPreferredEdge:geometry.edge];
        // Orthogonal drawer height is controlled by parent offsets. Ask its
        // actual native window for trim instead of assuming a particular OS skin.
        NSWindow *nativeWindow = [_contentView window];
        NSRect sample = NSMakeRect(0,0,240,82);
        CGFloat trim = nativeWindow ? MAX(0,NSHeight([nativeWindow frameRectForContentRect:sample])-82.0) : 0;
        CGFloat parentHeight = NSHeight([[_parentWindow contentView] bounds]);
        CGFloat height = MIN(geometry.contentSize.height,MAX(0,parentHeight-16.0-trim));
        NSSize contentSize = NSMakeSize(240,height);
        [_drawer setLeadingOffset:8];
        [_drawer setTrailingOffset:MAX(8,parentHeight-8.0-height-trim)];
        [_drawer setMinContentSize:NSMakeSize(240,MIN(82,height))]; [_drawer setMaxContentSize:contentSize];
        [_drawer setContentSize:contentSize];
        [_contentView setFrameSize:contentSize];
        [_titleField setFrame:NSMakeRect(12,height-30,120,20)];
        [_editButton setFrame:NSMakeRect(144,height-34,84,26)];
        if (_requestedVisible) {
            [self attachFolderScrollView];
            [_folderScrollView setFrame:NSMakeRect(6,6,228,MAX(0,height-50))];
            NSView *document = [_folderScrollView documentView];
            if (!document) { document = [[[TGAquaDrawerDocumentView alloc] initWithFrame:NSZeroRect] autorelease]; [_folderScrollView setDocumentView:document]; }
            for (NSView *view in [NSArray arrayWithArray:[document subviews]])
                if ([view isKindOfClass:[NSButton class]] && ![_folderButtons containsObject:view]) [view removeFromSuperview];
            CGFloat width = NSWidth([[_folderScrollView contentView] bounds]);
            [document setFrame:NSMakeRect(0,0,width,MAX(NSHeight([[_folderScrollView contentView] bounds]),[_folderButtons count]*32.0))];
            NSUInteger row = 0;
            for (NSButton *button in _folderButtons) { [button setFrame:NSMakeRect(0,row*32.0,width,32)]; if ([button superview] != document) [document addSubview:button]; row++; }
            NSClipView *clip = [_folderScrollView contentView];
            CGFloat maxY = MAX(0,NSHeight([document frame])-NSHeight([clip bounds]));
            [clip setBoundsOrigin:NSMakePoint(0,MIN(maxY,MAX(0,[clip bounds].origin.y)))];
            [_folderScrollView reflectScrolledClipView:clip];
            if ([self isOpen] && [_drawer edge] != geometry.edge) [_drawer close];
            else if ([_drawer state] == NSDrawerClosedState && [_parentWindow isVisible] && ![_parentWindow isMiniaturized]) [_drawer openOnEdge:geometry.edge];
        }
    }
    if (!_requestedVisible || !geometry.canShow) [_drawer close];
    _layoutInProgress = NO;
}
- (void)parentGeometryChanged:(NSNotification *)notification {
    (void)notification;
    BOOL hadPlacement = _hasPlacement, couldShow = _lastCanShow;
    [self layout];
    if (hadPlacement && couldShow != _lastCanShow)
        [[NSNotificationCenter defaultCenter] postNotificationName:TGAquaFolderDrawerPlacementDidChangeNotification object:self];
}
- (void)drawerDidOpen:(NSNotification *)notification { (void)notification; [self layout]; }
- (void)drawerDidClose:(NSNotification *)notification { (void)notification; if (_requestedVisible) [self layout]; }
- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)size {
    (void)sender; (void)size;
    TGAquaFolderDrawerGeometry geometry = [self currentPlacement];
    return geometry.canShow ? NSMakeSize(geometry.contentSize.width,MIN(size.height,geometry.contentSize.height)) : size;
}
- (void)parentWillClose:(NSNotification *)notification {
    (void)notification; _requestedVisible = NO; [_drawer close];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_drawer setDelegate:nil]; [_drawer close]; [_drawer setParentWindow:nil];
    if ([_folderScrollView superview] == _contentView) [_folderScrollView removeFromSuperview];
    [_drawer release]; [_contentView release]; [_folderScrollView release]; [_titleField release]; [_editButton release]; [_folderButtons release];
    [super dealloc];
}
@end
