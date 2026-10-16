#import "TGWindowFramePersistence.h"
#include <math.h>

static BOOL TGFrameIsUsable(NSRect frame) {
    return isfinite(frame.origin.x) && isfinite(frame.origin.y) &&
        isfinite(frame.size.width) && isfinite(frame.size.height) &&
        frame.size.width > 0 && frame.size.height > 0;
}

NSRect TGWindowFrameConstrainedToScreens(NSRect frame, NSSize minimumSize, NSArray *visibleFrames) {
    if (!TGFrameIsUsable(frame)) return NSZeroRect;
    NSRect screen = NSZeroRect;
    CGFloat bestArea = -1;
    double bestDistance = HUGE_VAL;
    for (NSValue *value in visibleFrames) {
        NSRect candidate = [value rectValue];
        if (!TGFrameIsUsable(candidate)) continue;
        NSRect intersection = NSIntersectionRect(frame, candidate);
        CGFloat area = NSIsEmptyRect(intersection) ? 0 : NSWidth(intersection) * NSHeight(intersection);
        double dx = NSMidX(frame) - NSMidX(candidate), dy = NSMidY(frame) - NSMidY(candidate);
        double distance = dx * dx + dy * dy;
        if (area > bestArea || (area == bestArea && distance < bestDistance)) {
            screen = candidate; bestArea = area; bestDistance = distance;
        }
    }
    if (NSIsEmptyRect(screen)) return NSZeroRect;
    CGFloat minWidth = isfinite(minimumSize.width) ? MAX(1, minimumSize.width) : 1;
    CGFloat minHeight = isfinite(minimumSize.height) ? MAX(1, minimumSize.height) : 1;
    frame.size.width = MIN(NSWidth(screen), MAX(minWidth, NSWidth(frame)));
    frame.size.height = MIN(NSHeight(screen), MAX(minHeight, NSHeight(frame)));
    frame.origin.x = MAX(NSMinX(screen), MIN(NSMaxX(screen) - NSWidth(frame), NSMinX(frame)));
    frame.origin.y = MAX(NSMinY(screen), MIN(NSMaxY(screen) - NSHeight(frame), NSMinY(frame)));
    return frame;
}

static NSArray *TGCurrentVisibleScreens(void) {
    NSMutableArray *frames = [NSMutableArray array];
    for (NSScreen *screen in [NSScreen screens]) [frames addObject:[NSValue valueWithRect:[screen visibleFrame]]];
    return frames;
}

@implementation TGWindowFramePersistence
- (id)initWithWindow:(NSWindow *)window designIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _window = [window retain];
        _defaultsKey = [[NSString stringWithFormat:@"TGMainWindowFrame.%@.v1", identifier ? identifier : @"classic"] copy];
        id saved = [[NSUserDefaults standardUserDefaults] objectForKey:_defaultsKey];
        if ([saved isKindOfClass:[NSArray class]] && [saved count] == 4) {
            BOOL valid = YES;
            for (id number in saved) if (![number isKindOfClass:[NSNumber class]]) valid = NO;
            if (valid) {
                NSRect frame = NSMakeRect([[saved objectAtIndex:0] doubleValue], [[saved objectAtIndex:1] doubleValue],
                    [[saved objectAtIndex:2] doubleValue], [[saved objectAtIndex:3] doubleValue]);
                frame = TGWindowFrameConstrainedToScreens(frame, [window minSize], TGCurrentVisibleScreens());
                if (!NSIsEmptyRect(frame)) [window setFrame:frame display:NO];
            }
        }
        _preferredFrame = [window frame];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(windowWillMove:) name:NSWindowWillMoveNotification object:window];
        [center addObserver:self selector:@selector(windowDidMove:) name:NSWindowDidMoveNotification object:window];
        [center addObserver:self selector:@selector(windowWillStartLiveResize:) name:NSWindowWillStartLiveResizeNotification object:window];
        [center addObserver:self selector:@selector(windowDidEndLiveResize:) name:NSWindowDidEndLiveResizeNotification object:window];
    }
    return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_window release];
    [_defaultsKey release];
    [super dealloc];
}
- (void)beginProgrammaticChanges { _programmaticDepth++; _userMoving = NO; }
- (void)endProgrammaticChanges { if (_programmaticDepth) _programmaticDepth--; }
- (void)windowWillMove:(NSNotification *)notification {
    (void)notification;
    NSEvent *event = [NSApp currentEvent];
    _userMoving = !_programmaticDepth && [event window] == _window &&
        ([event type] == NSLeftMouseDown || [event type] == NSLeftMouseDragged);
    if (_userMoving) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finishUserMove) object:nil];
        // Default-mode delivery occurs after AppKit leaves title-bar tracking.
        [self performSelector:@selector(finishUserMove) withObject:nil afterDelay:0];
    }
}
- (void)saveUserFrame:(NSRect)frame {
    if (_programmaticDepth || ![_window isVisible] || [_window isMiniaturized] ||
        ([_window styleMask] & NSFullScreenWindowMask) || !TGFrameIsUsable(frame)) return;
    _preferredFrame = frame;
    NSArray *numbers = [NSArray arrayWithObjects:[NSNumber numberWithDouble:NSMinX(frame)],
        [NSNumber numberWithDouble:NSMinY(frame)], [NSNumber numberWithDouble:NSWidth(frame)],
        [NSNumber numberWithDouble:NSHeight(frame)], nil];
    [[NSUserDefaults standardUserDefaults] setObject:numbers forKey:_defaultsKey];
}
- (void)windowDidMove:(NSNotification *)notification {
    (void)notification;
    NSEvent *event = [NSApp currentEvent];
    if (_userMoving && [event window] == _window &&
        ([event type] == NSLeftMouseDown || [event type] == NSLeftMouseDragged || [event type] == NSLeftMouseUp)) [self saveUserFrame:[_window frame]];
    else _userMoving = NO;
}
- (void)finishUserMove {
    if (_userMoving) [self saveUserFrame:[_window frame]];
    _userMoving = NO;
}
- (void)windowWillStartLiveResize:(NSNotification *)notification {
    (void)notification;
    _userResizing = !_programmaticDepth;
    _liveResizeStartFrame = [_window frame];
}
- (void)windowDidEndLiveResize:(NSNotification *)notification {
    (void)notification;
    if (_userResizing) {
        NSRect frame = [_window frame];
        // A previous drawer accommodation must not become a saved user move.
        frame.origin.x = NSMinX(_preferredFrame) + NSMinX(frame) - NSMinX(_liveResizeStartFrame);
        frame.origin.y = NSMinY(_preferredFrame) + NSMinY(frame) - NSMinY(_liveResizeStartFrame);
        [self saveUserFrame:frame];
    }
    _userResizing = NO;
}
@end
