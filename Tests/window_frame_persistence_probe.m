#import <Cocoa/Cocoa.h>
#import "TGWindowFramePersistence.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#import <objc/runtime.h>

static void Require(BOOL condition, const char *message) {
    if (!condition) { fprintf(stderr,"Window frame: %s\n",message); exit(1); }
}
/* Window/screen doubles keep this lifecycle test independent of WindowServer. */
@interface TGFrameProbeWindow : NSObject {
    NSRect _frame;
}
- (NSRect)frame;
@end
@implementation TGFrameProbeWindow
- (id)init { self=[super init]; if(self) _frame=NSMakeRect(100,100,980,700); return self; }
- (NSRect)frame { return _frame; }
- (NSSize)minSize { return NSMakeSize(760,620); }
- (void)setFrame:(NSRect)frame display:(BOOL)display { (void)display; _frame=frame; }
- (void)setFrameOrigin:(NSPoint)origin { _frame.origin=origin; }
- (BOOL)isVisible { return YES; }
- (BOOL)isMiniaturized { return NO; }
- (NSUInteger)styleMask { return NSTitledWindowMask|NSResizableWindowMask; }
- (NSRect)visibleFrame { return NSMakeRect(0,24,1440,854); }
@end
static id TGFrameCurrentEvent;
static NSArray *TGFrameProbeScreens;
@interface TGFrameProbeEvent : NSObject {
    NSWindow *_window;
}
- (id)initWithWindow:(NSWindow *)window;
@end
@implementation TGFrameProbeEvent
- (id)initWithWindow:(NSWindow *)window { self=[super init]; if(self) _window=window; return self; }
- (NSWindow *)window { return _window; }
- (NSEventType)type { return NSLeftMouseDragged; }
- (id)currentEvent { return TGFrameCurrentEvent; }
@end
static id TGFrameScreens(id self, SEL selector) { (void)self; (void)selector; return TGFrameProbeScreens; }
static void Post(NSString *name, NSWindow *window) { [[NSNotificationCenter defaultCenter] postNotificationName:name object:window]; }
static void CheckPersistence(void) {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSString *aqua=@"TGMainWindowFrame.aqua-probe.v1", *classic=@"TGMainWindowFrame.classic-probe.v1";
    [defaults removeObjectForKey:aqua];[defaults removeObjectForKey:classic];
    NSWindow *window=(NSWindow *)[[[TGFrameProbeWindow alloc] init] autorelease];
    TGFrameProbeScreens=[NSArray arrayWithObject:window];
    Method method=class_getClassMethod([NSScreen class],@selector(screens));
    IMP original=method_getImplementation(method);method_setImplementation(method,(IMP)TGFrameScreens);
    TGWindowFramePersistence *keeper=[[TGWindowFramePersistence alloc] initWithWindow:window designIdentifier:@"aqua-probe"];
    NSRect chosen=NSMakeRect(120,80,900,680);
    Post(NSWindowWillStartLiveResizeNotification,window);[window setFrame:chosen display:NO];
    Require([defaults objectForKey:aqua]==nil,"programmatic layout cannot create preferred geometry");
    Post(NSWindowDidEndLiveResizeNotification,window);
    NSArray *saved=[[defaults objectForKey:aqua] copy];Require([saved count]==4,"user live resize persists frame");
    [keeper beginProgrammaticChanges];[keeper beginProgrammaticChanges];
    [window setFrameOrigin:NSMakePoint(240,80)];Post(NSWindowDidEndLiveResizeNotification,window);
    [keeper endProgrammaticChanges];Post(NSWindowDidEndLiveResizeNotification,window);
    Require([[defaults objectForKey:aqua] isEqual:saved],"nested automatic drawer/layout changes cannot replace user frame");
    [keeper endProgrammaticChanges];
    Post(NSWindowWillStartLiveResizeNotification,window);
    NSRect resized=[window frame];resized.size.width=940;[window setFrame:resized display:NO];
    Post(NSWindowDidEndLiveResizeNotification,window);
    NSArray *resizedSaved=[defaults objectForKey:aqua];
    Require([[resizedSaved objectAtIndex:0] doubleValue]==chosen.origin.x && [[resizedSaved objectAtIndex:2] doubleValue]==940,
        "user resize preserves preferred origin after automatic drawer accommodation");
    chosen.size.width=940;
    [keeper release];
    keeper=[[TGWindowFramePersistence alloc] initWithWindow:window designIdentifier:@"aqua-probe"];
    Require(NSEqualRects([window frame],chosen),"recreated helper restores persisted geometry to current display");
    TGWindowFramePersistence *separate=[[TGWindowFramePersistence alloc] initWithWindow:window designIdentifier:@"classic-probe"];
    Require([defaults objectForKey:classic]==nil,"Classic and Aqua preference keys stay independent");[separate release];
    NSApplication *previousApplication=NSApp;
    TGFrameCurrentEvent=[[[TGFrameProbeEvent alloc] initWithWindow:window] autorelease];
    NSApp=(NSApplication *)TGFrameCurrentEvent;
    Post(NSWindowWillMoveNotification,window);[window setFrameOrigin:NSMakePoint(140,95)];Post(NSWindowDidMoveNotification,window);
    NSApp=previousApplication;TGFrameCurrentEvent=nil;
    Require(![[defaults objectForKey:aqua] isEqual:saved],"deliberate title-bar drag persists new position");
    [keeper release];[saved release];
    [defaults setObject:[NSArray arrayWithObjects:@"bad",@0,@900,@680,nil] forKey:aqua];
    chosen=[window frame];keeper=[[TGWindowFramePersistence alloc] initWithWindow:window designIdentifier:@"aqua-probe"];
    Require(NSEqualRects([window frame],chosen),"corrupt saved preference leaves current frame alone");[keeper release];
    method_setImplementation(method,original);TGFrameProbeScreens=nil;
    [defaults removeObjectForKey:aqua];[defaults removeObjectForKey:classic];
    printf("Window persistence: restore, drag, live resize, mode isolation, corrupt preferences and nested automatic-change suppression PASS (window/screen doubles).\n");
}
int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *screens = [NSArray arrayWithObjects:
        [NSValue valueWithRect:NSMakeRect(-1280, 40, 1280, 760)],
        [NSValue valueWithRect:NSMakeRect(0, 24, 1440, 854)], nil];
    NSSize minimum = NSMakeSize(760, 620);
    NSUInteger cases = 0;
    for (NSInteger x = -2400; x <= 2400; x += 300) {
        for (NSInteger y = -800; y <= 1600; y += 200) {
            NSRect frame = TGWindowFrameConstrainedToScreens(NSMakeRect(x,y,980,722), minimum, screens);
            BOOL contained = NO;
            for (NSValue *value in screens) if (NSContainsRect([value rectValue],frame)) contained = YES;
            Require(contained,"restored title bar and whole frame fit a current visible screen");
            Require(frame.size.width >= minimum.width && frame.size.height >= minimum.height,"ordinary screens respect minimum frame size");
            cases++;
        }
    }
    NSRect saved = NSMakeRect(-1100,60,980,722);
    Require(NSEqualRects(saved,TGWindowFrameConstrainedToScreens(saved,minimum,screens)),"valid negative-origin display placement stays unchanged"); cases++;
    NSArray *small = [NSArray arrayWithObject:[NSValue valueWithRect:NSMakeRect(0,20,640,460)]];
    NSRect fitted = TGWindowFrameConstrainedToScreens(NSMakeRect(1800,-900,5000,2000),minimum,small);
    Require(NSEqualRects(fitted,[[small objectAtIndex:0] rectValue]),"smaller displays take precedence over an impossible minimum"); cases++;
    Require(NSIsEmptyRect(TGWindowFrameConstrainedToScreens(saved,minimum,[NSArray array])),"no display does not invent a placement"); cases++;
    Require(NSIsEmptyRect(TGWindowFrameConstrainedToScreens(NSMakeRect(NAN,0,980,700),minimum,screens)),"nonfinite preferences rejected"); cases++;
    Require(NSIsEmptyRect(TGWindowFrameConstrainedToScreens(NSMakeRect(0,0,0,700),minimum,screens)),"zero-size preferences rejected"); cases++;
    fitted = TGWindowFrameConstrainedToScreens(NSMakeRect(100,100,200,200),minimum,screens);
    Require(NSEqualSizes(fitted.size,minimum),"stored dimensions below new app minimum grow safely"); cases++;
    printf("Window geometry: %lu current-display, disconnected-display, minimum and malformed-frame cases PASS.\n",(unsigned long)cases);
    CheckPersistence();
    [pool drain]; return 0;
}
