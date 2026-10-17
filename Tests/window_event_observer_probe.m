#import <Cocoa/Cocoa.h>
#import "TGWindowEventObserver.h"
#import "TGAquaShellViews.h"
#include <assert.h>

/* Actual NSWindow delegate registration, actual resize delivery and legacy
 * autoresizing masks: closing a temporary presentation must not sever the
 * window's layout callbacks. No client/account or outgoing action exists. */
@interface WindowEventOwner : NSObject <NSWindowDelegate> {
    NSWindow *_window; TGWindowEventObserver *_observer;
    NSView *_calls,*_workshop,*_chats,*_input,*_pin,*_table;
    NSUInteger _resizes,_moves,_closes,_temporaryEvents;
}
@property(nonatomic,retain) NSWindow *window;
@property(nonatomic,retain) TGWindowEventObserver *observer;
@property(nonatomic,readonly) NSUInteger resizes,moves,closes,temporaryEvents;
- (void)layout;
- (void)checkGeometry;
@end
@implementation WindowEventOwner
@synthesize window=_window,observer=_observer,resizes=_resizes,moves=_moves,closes=_closes,temporaryEvents=_temporaryEvents;
- (id)init {
    if ((self=[super init])) {
        _window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,980,650) styleMask:NSTitledWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
        [_window setReleasedWhenClosed:NO];[_window setDelegate:self];
        NSView *root=[_window contentView]; [root setAutoresizesSubviews:YES];
        _calls=[[NSView alloc] initWithFrame:NSZeroRect];[_calls setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];[root addSubview:_calls];
        _workshop=[[NSView alloc] initWithFrame:NSZeroRect];[_workshop setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];[root addSubview:_workshop];
        _chats=[[NSView alloc] initWithFrame:NSZeroRect];[_chats setAutoresizingMask:NSViewWidthSizable|NSViewMaxYMargin];[root addSubview:_chats];
        _table=[[NSView alloc] initWithFrame:NSZeroRect];[_table setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];[_chats addSubview:_table];
        _pin=[[NSView alloc] initWithFrame:NSZeroRect];[_pin setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];[root addSubview:_pin];
        _input=[[NSView alloc] initWithFrame:NSZeroRect];[_input setAutoresizingMask:NSViewWidthSizable|NSViewMaxYMargin];[root addSubview:_input];
        [self layout];
    }
    return self;
}
- (void)layout {
    NSSize size=[[_window contentView] bounds].size;
    TGAquaToolbarGeometry toolbar=TGAquaToolbarFrames(size.width,size.height);
    [_calls setFrame:toolbar.sections[2]];[_workshop setFrame:toolbar.sections[3]];
    TGAquaSourceListGeometry list=TGAquaSourceListFrames(NSMakeRect(0,0,292,size.height-64),0,210,9,YES);
    [_chats setFrame:list.chats];[_table setFrame:[_chats bounds]];
    [_pin setFrame:NSMakeRect(306,size.height-160,size.width-314,48)];
    [_input setFrame:NSMakeRect(400,14,MAX(0,size.width-620),30)];
}
- (void)checkGeometry {
    NSSize size=[[_window contentView] bounds].size;
    TGAquaToolbarGeometry toolbar=TGAquaToolbarFrames(size.width,size.height);
    assert(NSEqualRects([_calls frame],toolbar.sections[2])&&NSEqualRects([_workshop frame],toolbar.sections[3]));
    assert(!NSIntersectsRect([_calls frame],[_workshop frame]));
    assert(NSWidth([_chats frame])==292&&NSEqualRects([_table frame],[_chats bounds]));
    assert(NSMaxX([_pin frame])==size.width-8&&NSWidth([_input frame])==MAX(0,size.width-620));
    assert([[_window contentView] autoresizesSubviews]); // Classic/legacy mask policy is preserved.
}
- (void)windowDidResize:(NSNotification *)notification {if([notification object]==_window){_resizes++;[self layout];}}
- (void)windowDidMove:(NSNotification *)notification {if([notification object]==_window)_moves++;}
- (void)windowWillClose:(NSNotification *)notification {if([notification object]==_window)_closes++;}
- (void)temporaryEvent:(NSNotification *)notification {
    (void)notification;_temporaryEvents++;
    // Exercise release of the observer from inside its own forwarding frame.
    [_observer invalidate];self.observer=nil;
}
- (void)dealloc {
    [_observer invalidate];[_observer release];[_window setDelegate:nil];[_window close];[_window release];
    [_calls release];[_workshop release];[_chats release];[_table release];[_pin release];[_input release];[super dealloc];
}
@end
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];NSUInteger checks=0;
    NSArray *names=[NSArray arrayWithObjects:NSWindowDidResizeNotification,NSWindowDidMoveNotification,NSWindowWillCloseNotification,nil];
    // Reproduce the exact old failure with a disposable control window.
    WindowEventOwner *broken=[[[WindowEventOwner alloc] init] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:broken selector:@selector(temporaryEvent:) name:NSWindowDidResizeNotification object:broken.window];
    [[NSNotificationCenter defaultCenter] removeObserver:broken name:NSWindowDidResizeNotification object:broken.window];
    NSUInteger before=broken.resizes;[broken.window setContentSize:NSMakeSize(1100,650)];
    assert(broken.resizes==before);checks++; // Removes AppKit's delegate callback too.

    WindowEventOwner *owner=[[[WindowEventOwner alloc] init] autorelease];
    for(NSUInteger cycle=0;cycle<40;cycle++) {
        owner.observer=[[[TGWindowEventObserver alloc] initWithWindow:owner.window names:names target:owner action:@selector(temporaryEvent:)] autorelease];
        [owner.observer invalidate];owner.observer=nil; // Ordinary popover dismissal.
        before=owner.resizes;
        [owner.window setContentSize:NSMakeSize(760+(cycle%7)*113,460+(cycle%4)*71)];
        assert(owner.resizes==before+1);[owner checkGeometry];checks+=7;
        before=owner.moves;[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidMoveNotification object:owner.window];
        assert(owner.moves==before+1);checks++;
        // Dismiss while processing a host event, then immediately reopen.
        owner.observer=[[[TGWindowEventObserver alloc] initWithWindow:owner.window names:names target:owner action:@selector(temporaryEvent:)] autorelease];
        NSUInteger callbacks=owner.temporaryEvents;
        [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidMoveNotification object:owner.window];
        assert(!owner.observer&&owner.temporaryEvents==callbacks+1);checks++;
        before=owner.resizes;[owner.window setContentSize:NSMakeSize(780+(cycle%5)*93,480+(cycle%3)*67)];
        assert(owner.resizes==before+1);[owner checkGeometry];checks+=7;
    }
    before=owner.closes;[owner.window close];assert(owner.closes==before+1);checks++;
    printf("Window event observers: %lu real NSWindow delegate, repeated dismissal/resize/move/close, legacy-mask geometry and reentrant invalidation checks PASS\n",(unsigned long)checks);
    [pool drain];return 0;
}
