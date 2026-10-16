#import "TGAquaPhotoTransition.h"
#import "TGAnimationSupport.h"
#import "../Media/TGMediaItemSupport.h"
#import "../Services/TGResourcePolicy.h"
#import <objc/runtime.h>
#import <math.h>

static char TGPhotoTransitionKey;

BOOL TGAquaPhotoTransitionIsStaticPhoto(NSDictionary *item) {
    return [item isKindOfClass:[NSDictionary class]] &&
           [TGMediaItemContentType(item) isEqualToString:@"messagePhoto"];
}
BOOL TGAquaMediaTransitionSupportsThumbnail(NSDictionary *item) {
    if (![item isKindOfClass:[NSDictionary class]]) return NO;
    NSString *kind=TGMediaItemContentType(item);
    return TGAquaPhotoTransitionIsStaticPhoto(item) || [kind isEqualToString:@"messageVideo"] ||
        [kind isEqualToString:@"messageVideoNote"] || [kind isEqualToString:@"messageAnimation"];
}

NSRect TGAquaPhotoAspectFillRect(NSSize imageSize, NSRect bounds) {
    if (imageSize.width <= 0.0 || imageSize.height <= 0.0 || NSIsEmptyRect(bounds)) return NSZeroRect;
    CGFloat scale = MAX(NSWidth(bounds) / imageSize.width, NSHeight(bounds) / imageSize.height);
    NSSize size = NSMakeSize(imageSize.width * scale, imageSize.height * scale);
    return NSMakeRect(NSMidX(bounds) - size.width / 2.0, NSMidY(bounds) - size.height / 2.0, size.width, size.height);
}

NSRect TGAquaPhotoVisibleScreenRect(NSView *view, NSRect rect) {
    NSWindow *window = [view window];
    if (!view || !window || ![window isVisible] || [window isMiniaturized] ||
        [view isHiddenOrHasHiddenAncestor] || NSIsEmptyRect(rect) ||
        !NSContainsRect([view visibleRect], NSInsetRect(rect, 0.5, 0.5))) return NSZeroRect;
    NSRect result = [window convertRectToScreen:[view convertRect:rect toView:nil]];
    for (NSScreen *screen in [NSScreen screens]) {
        if (NSContainsRect([screen frame], result)) return result;
    }
    return NSZeroRect;
}
NSRect TGAquaPhotoIntersectedVisibleScreenRect(NSView *view, NSRect rect) {
    NSRect visible=NSIntersectionRect(rect,[view visibleRect]);
    /* Scroll clipping is normal in a transcript. A useful visible portion is
     * still a valid origin; a one-pixel sliver is not. */
    if (NSWidth(visible)<24 || NSHeight(visible)<24) return NSZeroRect;
    return TGAquaPhotoVisibleScreenRect(view,visible);
}

@interface TGAquaPhotoMotionImageView : NSView {
    NSImage *_image;
    BOOL _circular;
}
- (id)initWithImage:(NSImage *)image circular:(BOOL)circular;
@end
@implementation TGAquaPhotoMotionImageView
- (id)initWithImage:(NSImage *)image circular:(BOOL)circular {
    self = [super initWithFrame:NSZeroRect];
    if (self) { _image = [image retain]; _circular=circular; }
    return self;
}
- (void)dealloc { [_image release]; [super dealloc]; }
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    [NSGraphicsContext saveGraphicsState];
    NSRectClip([self bounds]);
    if (_circular) [[NSBezierPath bezierPathWithOvalInRect:[self bounds]] addClip];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [_image drawInRect:TGAquaPhotoAspectFillRect([_image size], [self bounds])
             fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
}
@end

@interface TGAquaPhotoTransition : NSObject {
    NSWindow *_window; /* owner, deliberately not retained */
    NSView *_imageView;
    NSImage *_image;
    NSView *_policyView;
    id<TGAquaPhotoTransitionSource> _source; /* owning controller, not retained */
    NSDictionary *_context;
    NSWindow *_imageWindow;
    NSTimer *_timer;
    NSRect _startRect;
    NSRect _endRect;
    NSTimeInterval _startTime;
    BOOL _closing;
    BOOL _allowClose;
    BOOL _returnsToSource, _circular;
    NSRect _viewerFrame;
}
- (id)initWithWindow:(NSWindow *)window imageView:(NSView *)imageView image:(NSImage *)image
         policyView:(NSView *)view source:(id<TGAquaPhotoTransitionSource>)source context:(NSDictionary *)context
            returns:(BOOL)returns circular:(BOOL)circular;
- (void)open;
- (BOOL)shouldClose;
- (void)cancel;
@end

@implementation TGAquaPhotoTransition
- (id)initWithWindow:(NSWindow *)window imageView:(NSView *)imageView image:(NSImage *)image
         policyView:(NSView *)view source:(id<TGAquaPhotoTransitionSource>)source context:(NSDictionary *)context
            returns:(BOOL)returns circular:(BOOL)circular {
    self = [super init];
    if (self) {
        _window = window;
        _imageView = [imageView retain];
        _image=[image retain]; _returnsToSource=returns; _circular=circular;
        _policyView = [view retain];
        _source = source;
        _context = [context copy];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(interrupted:) name:TGResourcePolicyDidChangeNotification object:nil];
        [center addObserver:self selector:@selector(interrupted:) name:NSApplicationDidResignActiveNotification object:nil];
        [center addObserver:self selector:@selector(geometryChanged:) name:NSWindowDidResizeNotification object:window];
        [center addObserver:self selector:@selector(geometryChanged:) name:NSWindowDidMoveNotification object:window];
        [center addObserver:self selector:@selector(sourceClosed:) name:NSWindowWillCloseNotification object:[view window]];
        [center addObserver:self selector:@selector(sourceClosed:) name:NSWindowWillMiniaturizeNotification object:[view window]];
    }
    return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate]; [_timer release];
    [_imageWindow orderOut:nil]; [_imageWindow release];
    [_imageView release]; [_image release]; [_policyView release]; [_context release];
    [super dealloc];
}
- (void)cancel {
    [_timer invalidate]; [_timer release]; _timer = nil;
    [_imageWindow orderOut:nil]; [_imageWindow release]; _imageWindow = nil;
    [_window setAlphaValue:1.0];
    _closing = NO;
}
- (void)finish {
    [self retain];
    BOOL close = _closing;
    [self cancel];
    if (close) { _allowClose = YES; [_window close]; }
    [self release];
}
- (void)interrupted:(NSNotification *)notification {
    (void)notification;
    if (!TGInterfaceAnimationsEnabledForView(_policyView)) [self finish];
}
- (void)geometryChanged:(NSNotification *)notification {
    (void)notification;
    /* First-show AppKit notifications can arrive after presentation starts.
     * Only a real geometry change interrupts the reveal. */
    if (_timer && !NSEqualRects(_viewerFrame,[_window frame])) [self finish];
}
- (void)sourceClosed:(NSNotification *)notification { (void)notification; [self cancel]; }
- (void)tick:(NSTimer *)timer {
    (void)timer;
    CGFloat progress = ([NSDate timeIntervalSinceReferenceDate] - _startTime) / 0.28;
    if (progress >= 1.0 || !TGInterfaceAnimationsEnabledForView(_policyView)) { [self finish]; return; }
    CGFloat t = MAX(0.0, progress);
    CGFloat eased = t * t * (3.0 - 2.0 * t);
    if (_imageWindow) {
        NSRect frame = NSMakeRect(_startRect.origin.x + (_endRect.origin.x - _startRect.origin.x) * eased,
                                 _startRect.origin.y + (_endRect.origin.y - _startRect.origin.y) * eased,
                                 _startRect.size.width + (_endRect.size.width - _startRect.size.width) * eased,
                                 _startRect.size.height + (_endRect.size.height - _startRect.size.height) * eased);
        [_imageWindow setFrame:frame display:YES];
        CGFloat dissolve = _closing ? MIN(1.0, t * 4.0) : MIN(1.0, (1.0 - t) * 4.0);
        [_imageWindow setAlphaValue:dissolve];
        [_window setAlphaValue:1.0 - dissolve];
    } else {
        [_window setAlphaValue:(_closing ? 1.0 - eased : eased)];
    }
}
- (void)startClosing:(BOOL)closing {
    [self cancel];
    _closing = closing;
    _viewerFrame=[_window frame];
    NSRect sourceRect = [_source aquaPhotoPreviewSourceScreenRectForContext:_context];
    if (closing && !_returnsToSource) sourceRect=NSZeroRect;
    /* A panned/zoomed image is not the full picture. Dissolve it in place
     * instead of substituting a differently cropped image during close. */
    NSRect imageRect = TGAquaPhotoVisibleScreenRect(_imageView, [_imageView bounds]);
    if (!NSIsEmptyRect(sourceRect) && !NSIsEmptyRect(imageRect) && _image) {
        _startRect = closing ? imageRect : sourceRect;
        _endRect = closing ? sourceRect : imageRect;
        _imageWindow = [[NSWindow alloc] initWithContentRect:_startRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [_imageWindow setReleasedWhenClosed:NO];
        [_imageWindow setOpaque:NO];
        [_imageWindow setBackgroundColor:[NSColor clearColor]];
        [_imageWindow setHasShadow:YES];
        [_imageWindow setIgnoresMouseEvents:YES];
        [_imageWindow setLevel:[_window level]];
        TGAquaPhotoMotionImageView *view = [[[TGAquaPhotoMotionImageView alloc] initWithImage:_image circular:_circular] autorelease];
        [_imageWindow setContentView:view];
        [_imageWindow setAlphaValue:closing ? 0.0 : 1.0];
        [_imageWindow orderWindow:NSWindowAbove relativeTo:[_window windowNumber]];
    }
    [_window setAlphaValue:closing ? 1.0 : 0.0];
    _startTime = [NSDate timeIntervalSinceReferenceDate];
    _timer = [[NSTimer timerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(tick:) userInfo:nil repeats:YES] retain];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}
- (void)open {
    if (TGInterfaceAnimationsEnabledForView(_policyView)) [self startClosing:NO];
    else [_window setAlphaValue:1.0];
}
- (BOOL)shouldClose {
    if (_allowClose || !TGInterfaceAnimationsEnabledForView(_policyView)) { [self cancel]; return YES; }
    if (!_closing) [self startClosing:YES];
    return NO;
}
@end

void TGAquaPhotoTransitionClear(NSWindow *window) {
    TGAquaPhotoTransition *motion = objc_getAssociatedObject(window, &TGPhotoTransitionKey);
    [motion cancel];
    if (window) objc_setAssociatedObject(window, &TGPhotoTransitionKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
void TGAquaPhotoTransitionCancel(NSWindow *window) { [objc_getAssociatedObject(window, &TGPhotoTransitionKey) cancel]; }
void TGAquaPhotoTransitionOpen(NSWindow *window, NSImageView *imageView, NSView *policyView,
                              id<TGAquaPhotoTransitionSource> source, NSDictionary *context) {
    TGAquaPhotoTransitionClear(window);
    if (!window || !context) return;
    TGAquaPhotoTransition *motion = [[[TGAquaPhotoTransition alloc] initWithWindow:window imageView:imageView image:[imageView image] policyView:policyView source:source context:context returns:YES circular:NO] autorelease];
    objc_setAssociatedObject(window, &TGPhotoTransitionKey, motion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [motion open];
}
void TGAquaMediaTransitionOpen(NSWindow *window, NSView *destinationView, NSImage *poster,
                              NSView *policyView, id<TGAquaPhotoTransitionSource> source, NSDictionary *context, BOOL circular) {
    TGAquaPhotoTransitionClear(window);
    if (!window) return;
    TGAquaPhotoTransition *motion=[[[TGAquaPhotoTransition alloc] initWithWindow:window imageView:destinationView image:poster policyView:policyView source:source context:context returns:NO circular:circular] autorelease];
    objc_setAssociatedObject(window,&TGPhotoTransitionKey,motion,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [motion open];
}
BOOL TGAquaPhotoTransitionShouldClose(NSWindow *window) {
    TGAquaPhotoTransition *motion = objc_getAssociatedObject(window, &TGPhotoTransitionKey);
    return !motion || [motion shouldClose];
}
