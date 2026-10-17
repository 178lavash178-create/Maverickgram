#import <Cocoa/Cocoa.h>

/* A distinct observer identity for a temporary presentation. NSWindow itself
 * registers its delegate in NSNotificationCenter; removing the delegate as an
 * observer would also silently disconnect its resize/move/close callbacks. */
@interface TGWindowEventObserver : NSObject {
    NSWindow *_window;
    id _target;
    SEL _action;
}
- (id)initWithWindow:(NSWindow *)window
              names:(NSArray *)notificationNames
             target:(id)target
             action:(SEL)action;
- (void)invalidate;
@end
