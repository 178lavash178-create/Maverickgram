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

@interface TGAquaPhotoMotionImageView : NSView {
    NSImage *_image;
}
- (id)initWithImage:(NSImage *)image;
@end
@implementation TGAquaPhotoMotionImageView
- (id)initWithImage:(NSImage *)image {
    self = [super initWithFrame:NSZeroRect];
    if (self) _image = [image retain];
    return self;
}
- (void)dealloc { [_image release]; [super dealloc]; }
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    [NSGraphicsContext saveGraphicsState];
    NSRectClip([self bounds]);
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [_image drawInRect:TGAquaPhotoAspectFillRect([_image size], [self bounds])
             fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
}
@end

@interface TGAquaPhotoTransition : NSObject {
    NSWindow *_window; /* owner, deliberately not retained */
    NSImageView *_imageView;
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
}
- (id)initWithWindow:(NSWindow *)window imageView:(NSImageView *)imageView
         policyView:(NSView *)view source:(id<TGAquaPhotoTransitionSource>)source context:(NSDictionary *)context;
- (void)open;
- (BOOL)shouldClose;
- (void)cancel;
@end

@implementation TGAquaPhotoTransition
- (id)initWithWindow:(NSWindow *)window imageView:(NSImageView *)imageView
         policyView:(NSView *)view source:(id<TGAquaPhotoTransitionSource>)source context:(NSDictionary *)context {
    self = [super init];
    if (self) {
        _window = window;
        _imageView = [imageView retain];
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
    [_imageView release]; [_policyView release]; [_context release];
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
- (void)geometryChanged:(NSNotification *)notification { (void)notification; if (_timer) [self finish]; }
- (void)sourceClosed:(NSNotification *)notification { (void)notification; [self cancel]; }
- (void)tick:(NSTimer *)timer {
    (void)timer;
    CGFloat progress = ([NSDate timeIntervalSinceReferenceDate] - _startTime) / 0.20;
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
    NSRect sourceRect = [_source aquaPhotoPreviewSourceScreenRectForContext:_context];
    /* A panned/zoomed image is not the full picture. Dissolve it in place
     * instead of substituting a differently cropped image during close. */
    NSRect imageRect = TGAquaPhotoVisibleScreenRect(_imageView, [_imageView bounds]);
    if (!NSIsEmptyRect(sourceRect) && !NSIsEmptyRect(imageRect) && [_imageView image]) {
        _startRect = closing ? imageRect : sourceRect;
        _endRect = closing ? sourceRect : imageRect;
        _imageWindow = [[NSWindow alloc] initWithContentRect:_startRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [_imageWindow setReleasedWhenClosed:NO];
        [_imageWindow setOpaque:NO];
        [_imageWindow setBackgroundColor:[NSColor clearColor]];
        [_imageWindow setHasShadow:YES];
        [_imageWindow setIgnoresMouseEvents:YES];
        [_imageWindow setLevel:[_window level]];
        TGAquaPhotoMotionImageView *view = [[[TGAquaPhotoMotionImageView alloc] initWithImage:[_imageView image]] autorelease];
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
    TGAquaPhotoTransition *motion = [[[TGAquaPhotoTransition alloc] initWithWindow:window imageView:imageView policyView:policyView source:source context:context] autorelease];
    objc_setAssociatedObject(window, &TGPhotoTransitionKey, motion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [motion open];
}
BOOL TGAquaPhotoTransitionShouldClose(NSWindow *window) {
    TGAquaPhotoTransition *motion = objc_getAssociatedObject(window, &TGPhotoTransitionKey);
    return !motion || [motion shouldClose];
}
