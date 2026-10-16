#import <Cocoa/Cocoa.h>

/* Frame coordinates, including the title bar; screens are visible-frame NSValues. */
NSRect TGWindowFrameConstrainedToScreens(NSRect frame, NSSize minimumSize, NSArray *visibleFrames);

/* Saves deliberate title-bar drags and live resizes, never incidental layout. */
@interface TGWindowFramePersistence : NSObject {
    NSWindow *_window;
    NSString *_defaultsKey;
    NSUInteger _programmaticDepth;
    BOOL _userMoving;
    BOOL _userResizing;
    NSRect _programmaticStartFrame;
    NSPoint _programmaticOriginOffset;
}
- (id)initWithWindow:(NSWindow *)window designIdentifier:(NSString *)identifier;
- (void)beginProgrammaticChanges;
- (void)endProgrammaticChanges;
@end
