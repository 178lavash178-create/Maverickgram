#include <unistd.h>
#import <Cocoa/Cocoa.h>
#import "TGAquaAudioPlayerView.h"
#import "TGAquaShellViews.h"
#include <math.h>

// Isolate the production strip's geometry/lifecycle from texture rendering.
// The real material is covered by the existing Aqua surface raster probe.
@implementation TGAquaMetalView
@synthesize dividerX = _dividerX;
@end
static BOOL AnimationEnabled = YES;
BOOL TGInterfaceAnimationsEnabledForView(NSView *view) { (void)view; return AnimationEnabled; }
static NSUInteger Checks = 0;
static void Check(BOOL value, const char *detail) { Checks++; if(!value) { fprintf(stderr,"FAIL: %s\n",detail);exit(2); } }
static void Spin(NSTimeInterval interval) {
    NSDate *end=[NSDate dateWithTimeIntervalSinceNow:interval];
    while([end timeIntervalSinceNow]>0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}
@interface TGAudioProbeTarget : NSObject { @public NSUInteger layouts; }
- (void)layout:(id)sender;
@end
@implementation TGAudioProbeTarget
- (void)layout:(id)sender { (void)sender;layouts++; }
@end
int main(void) {
    alarm(30);
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];[NSApp finishLaunching];
    CGFloat widths[]={760,800,856,980,1024,1280,1440,1920};
    for(NSUInteger i=0;i<sizeof(widths)/sizeof(widths[0]);i++) {
        NSRect bounds=NSMakeRect(10,20,widths[i],600);
        NSRect strip=TGAquaAudioPlayerFrame(bounds);
        Check(NSMinX(strip)==10 && NSWidth(strip)==widths[i] && NSHeight(strip)==48,"strip occupies one 48pt full-width row");
        Check(NSMaxY(strip)==NSMaxY(bounds)-54,"strip sits directly below 54pt toolbar");
        NSArray *frames=TGAquaAudioPlayerControlFrames(widths[i]);
        Check([frames count]==7,"all playback controls have frames");
        for(NSUInteger index=0;index<[frames count];index++) {
            NSRect frame=[[frames objectAtIndex:index] rectValue];
            Check(NSMinX(frame)>=0 && NSMinY(frame)>=0 && NSMaxX(frame)<=widths[i] && NSMaxY(frame)<=48,"every control stays inside strip");
            Check(NSWidth(frame)>0 && NSHeight(frame)>0,"every control has a positive usable size");
            for(NSUInteger other=index+1;other<[frames count];other++)
                Check(!NSIntersectsRect(frame,[[frames objectAtIndex:other] rectValue]),"playback controls never overlap");
        }
    }
    NSWindow *window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,760,600) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [window setReleasedWhenClosed:NO];
    TGAquaAudioPlayerView *view=[[[TGAquaAudioPlayerView alloc] initWithFrame:TGAquaAudioPlayerFrame([[window contentView] bounds])] autorelease];
    [[window contentView] addSubview:view];
    TGAudioProbeTarget *target=[[[TGAudioProbeTarget alloc] init] autorelease];[view setLayoutTarget:target];[view setLayoutAction:@selector(layout:)];
    Check([view isHidden],"new strip starts hidden");
    [view setPresented:YES animated:YES];
    Check(![view isHidden] && NSEqualRects([[view surface] frame],[view bounds]),"hidden-window presentation completes synchronously");
    [view setPresented:NO animated:NO];Check([view isHidden],"immediate dismissal hides strip");
    [window makeKeyAndOrderFront:nil];
    AnimationEnabled=NO;[view setPresented:YES animated:YES];
    Check(![view isHidden] && NSEqualRects([[view surface] frame],[view bounds]),"disabled animations use final geometry immediately");
    [view setPresented:NO animated:NO];
    AnimationEnabled=YES;[view setPresented:YES animated:YES];
    Check(![view isHidden],"animated strip participates in layout during reveal");
    Spin(0.4);
    Check(![view isHidden] && NSEqualRects([[view surface] frame],[view bounds]),"reveal ends in exact final geometry");
    NSUInteger completed=target->layouts;[view setPresented:YES animated:YES];
    Check(target->layouts==completed,"repeating visible state does not restart animation");
    [view setPresented:NO animated:YES];Spin(0.4);
    Check([view isHidden] && NSEqualRects([[view surface] frame],[view bounds]),"animated dismissal hides and resets surface");
    [view setPresented:YES animated:YES];[view setPresented:NO animated:NO];Spin(0.4);
    Check([view isHidden],"interrupted reveal cannot reappear after dismissal");
    [view setPresented:YES animated:YES];[view cancelAnimation];[view setPresented:NO animated:NO];Spin(0.3);
    Check([view isHidden],"explicit cancellation leaves no stale completion");
    [view setPresented:YES animated:NO];[view setPresented:NO animated:YES];
    [view setFrameSize:NSMakeSize(980,48)];Spin(0.3);
    Check([view isHidden] && NSEqualRects([[view surface] frame],[view bounds]),"resize during dismissal finishes target hidden state");
    [view setPresented:YES animated:YES];[view setFrameSize:NSMakeSize(760,48)];Spin(0.3);
    Check(![view isHidden] && NSEqualRects([[view surface] frame],[view bounds]),"resize during reveal finishes target visible state");
    [view setLayoutTarget:nil];[window close];
    printf("PASS: %lu production Aqua audio-strip geometry and animation lifecycle checks\n",(unsigned long)Checks);
    alarm(0);[pool drain];return 0;
}
