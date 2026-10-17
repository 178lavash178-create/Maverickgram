// Keep screen fitting separate from presentation and from controller layouts.
@interface TGUtilityOverflowScrollView : NSScrollView { NSUInteger _originalAutoresizingMask; }
@property(nonatomic,assign) NSUInteger originalAutoresizingMask;
@end
@implementation TGUtilityOverflowScrollView
@synthesize originalAutoresizingMask = _originalAutoresizingMask;
@end

static char TGUtilityWindowOriginalLimitsKey;
static char TGUtilityWindowScreenObserverKey;

// The window owns this observer; the back-reference is deliberately non-owning.
@interface TGUtilityWindowScreenObserver : NSObject { NSWindow *_window; BOOL _fitting; }
@property(nonatomic,assign) BOOL fitting;
- (id)initWithWindow:(NSWindow *)window;
@end
@implementation TGUtilityWindowScreenObserver
@synthesize fitting=_fitting;
- (id)initWithWindow:(NSWindow *)window {
    self=[super init];if(self){_window=window;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenChanged:) name:NSWindowDidChangeScreenNotification object:window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenChanged:) name:NSApplicationDidChangeScreenParametersNotification object:nil];}
    return self;
}
- (void)screenChanged:(NSNotification *)notification {
    (void)notification;if(!_fitting)TGFitUtilityWindowToVisibleScreen(_window);
}
- (void)dealloc {[[NSNotificationCenter defaultCenter] removeObserver:self];[super dealloc];}
@end

NSView *TGUtilityWindowContentView(NSWindow *window) {
    NSView *root = [window contentView];
    return [root isKindOfClass:[TGUtilityOverflowScrollView class]] ? [(NSScrollView *)root documentView] : root;
}

NSRect TGUtilityWindowFrameFittingVisibleFrame(NSRect frame, NSRect visibleFrame) {
    if (NSIsEmptyRect(visibleFrame)) return frame;
    NSRect available = NSInsetRect(visibleFrame,MIN(8.0,NSWidth(visibleFrame)/8.0),MIN(8.0,NSHeight(visibleFrame)/8.0));
    frame.size.width = MIN(NSWidth(frame),NSWidth(available));
    frame.size.height = MIN(NSHeight(frame),NSHeight(available));
    frame.origin.x = MAX(NSMinX(available),MIN(NSMinX(frame),NSMaxX(available)-NSWidth(frame)));
    frame.origin.y = MAX(NSMinY(available),MIN(NSMinY(frame),NSMaxY(available)-NSHeight(frame)));
    return frame;
}

void TGFitUtilityWindowToVisibleFrame(NSWindow *window, NSRect visibleFrame) {
    if (!window || ![NSThread isMainThread] || NSIsEmptyRect(visibleFrame)) return;
    TGUtilityWindowScreenObserver *screenObserver=objc_getAssociatedObject(window,&TGUtilityWindowScreenObserverKey);
    if(screenObserver.fitting)return;
    NSDictionary *limits = objc_getAssociatedObject(window,&TGUtilityWindowOriginalLimitsKey);
    if (!limits) {
        NSSize minimum = [window minSize];
        // A non-resizable form's entire initial content is its safe minimum.
        if (!([window styleMask]&NSResizableWindowMask) || minimum.width<100.0 || minimum.height<100.0) minimum = [window frame].size;
        limits = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithSize:minimum],@"minimum",
                  [NSValue valueWithSize:[window maxSize]],@"maximum",nil];
        objc_setAssociatedObject(window,&TGUtilityWindowOriginalLimitsKey,limits,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        TGUtilityWindowScreenObserver *observer=[[[TGUtilityWindowScreenObserver alloc] initWithWindow:window] autorelease];
        objc_setAssociatedObject(window,&TGUtilityWindowScreenObserverKey,observer,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        screenObserver=observer;
    }
    // setFrame can synchronously announce a screen change. Finish this fit
    // before responding to it, including explicit fits to another display.
    screenObserver.fitting=YES;
    NSSize minimum = [[limits objectForKey:@"minimum"] sizeValue];
    NSSize maximum = [[limits objectForKey:@"maximum"] sizeValue];
    NSRect fitted = TGUtilityWindowFrameFittingVisibleFrame([window frame],visibleFrame);
    NSRect available = TGUtilityWindowFrameFittingVisibleFrame(visibleFrame,visibleFrame);
    NSView *root = [window contentView];
    BOOL overflow = (minimum.width>NSWidth(available) || minimum.height>NSHeight(available));
    if (overflow && ![root isKindOfClass:[TGUtilityOverflowScrollView class]]) {
        NSSize naturalSize = [root frame].size;
        TGUtilityOverflowScrollView *viewport = [[[TGUtilityOverflowScrollView alloc] initWithFrame:[root frame]] autorelease];
        [viewport setBorderType:NSNoBorder]; [viewport setHasVerticalScroller:YES]; [viewport setHasHorizontalScroller:YES];
        [viewport setAutohidesScrollers:YES]; [viewport setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [viewport setDrawsBackground:YES]; [viewport setBackgroundColor:[NSColor windowBackgroundColor]];
        viewport.originalAutoresizingMask = [root autoresizingMask];
        [root retain];
        [root setAutoresizingMask:NSViewNotSizable];
        // Older AppKit removes its previous content view from its superview
        // during replacement. Install the viewport before adopting that view
        // as its document, or10.9 detaches the document we just attached.
        [window setContentView:viewport]; [viewport setDocumentView:root];
        [root setFrameSize:naturalSize];
        [root release];
    }
    if (!overflow && [root isKindOfClass:[TGUtilityOverflowScrollView class]]) {
        TGUtilityOverflowScrollView *viewport = (TGUtilityOverflowScrollView *)root;
        NSView *document = [[viewport documentView] retain];
        NSUInteger originalMask = viewport.originalAutoresizingMask;
        fitted.size.width = MAX(NSWidth(fitted),minimum.width);
        fitted.size.height = MAX(NSHeight(fitted),minimum.height);
        fitted = TGUtilityWindowFrameFittingVisibleFrame(fitted,visibleFrame);
        [window setMinSize:NSMakeSize(MIN(minimum.width,NSWidth(available)),MIN(minimum.height,NSHeight(available)))];
        [window setMaxSize:NSMakeSize(MIN(maximum.width,NSWidth(available)),MIN(maximum.height,NSHeight(available)))];
        // Resize delegates still reach the document through the viewport.
        // Give them the final bounds before setFrame dispatches their callback.
        [document setFrameSize:[window contentRectForFrameRect:fitted].size];
        [window setFrame:fitted display:NO];
        [viewport setDocumentView:nil];
        [document setAutoresizingMask:originalMask];
        [window setContentView:document];
        [document release];
    }
    [window setMinSize:NSMakeSize(MIN(minimum.width,NSWidth(available)),MIN(minimum.height,NSHeight(available)))];
    [window setMaxSize:NSMakeSize(MIN(maximum.width,NSWidth(available)),MIN(maximum.height,NSHeight(available)))];
    if (!NSEqualRects(fitted,[window frame])) [window setFrame:fitted display:NO];
    if ([[window contentView] isKindOfClass:[TGUtilityOverflowScrollView class]]) {
        NSScrollView *scroll = (NSScrollView *)[window contentView]; [scroll tile];
        NSView *document = [scroll documentView];
        [document scrollPoint:NSMakePoint(0,[document isFlipped] ? 0 : MAX(0.0,NSHeight([document bounds])-NSHeight([[scroll contentView] bounds])))];
    }
    screenObserver.fitting=NO;
}

void TGFitUtilityWindowToVisibleScreen(NSWindow *window) {
    NSScreen *screen = [window screen] ? [window screen] : [NSScreen mainScreen];
    if (screen) TGFitUtilityWindowToVisibleFrame(window,[screen visibleFrame]);
}
