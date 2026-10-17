#import "TGWindowEventObserver.h"

@implementation TGWindowEventObserver
- (id)initWithWindow:(NSWindow *)window names:(NSArray *)notificationNames target:(id)target action:(SEL)action {
    self=[super init];
    if (self) {
        _window=[window retain]; _target=target; _action=action;
        if (!window || !target || !action) { [self release]; return nil; }
        NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
        for (NSString *name in notificationNames) [center addObserver:self selector:@selector(windowEvent:) name:name object:window];
    }
    return self;
}
- (void)windowEvent:(NSNotification *)notification {
    /* Closing a popover can invalidate and release this observer inside its
     * callback. Keep the forwarding frame alive until that callback returns. */
    [self retain];
    id target=_target; SEL action=_action;
    if (target && action && [target respondsToSelector:action]) [target performSelector:action withObject:notification];
    [self release];
}
- (void)invalidate {
    _target=nil; _action=NULL;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_window release]; _window=nil;
}
- (void)dealloc { [self invalidate]; [super dealloc]; }
@end
