#import "TGAquaAudioPlayerView.h"
#import "TGAquaShellViews.h"
#import "TGAnimationSupport.h"

NSRect TGAquaAudioPlayerFrame(NSRect bounds) {
    return NSMakeRect(NSMinX(bounds), MAX(NSMinY(bounds), NSMaxY(bounds)-102.0), MAX(0,NSWidth(bounds)),48.0);
}
NSArray *TGAquaAudioPlayerControlFrames(CGFloat width) {
    CGFloat end=MAX(260.0,width)-10.0;
    CGFloat closeX=end-28.0, rateX=closeX-70.0, timeX=rateX-110.0;
    CGFloat start=102.0;
    return [NSArray arrayWithObjects:
        [NSValue valueWithRect:NSMakeRect(10,7,34,34)],
        [NSValue valueWithRect:NSMakeRect(50,7,38,34)],
        [NSValue valueWithRect:NSMakeRect(start,27,MAX(0,timeX-start-8),17)],
        [NSValue valueWithRect:NSMakeRect(start,5,MAX(0,timeX-start-8),20)],
        [NSValue valueWithRect:NSMakeRect(timeX,16,106,18)],
        [NSValue valueWithRect:NSMakeRect(rateX,10,62,28)],
        [NSValue valueWithRect:NSMakeRect(closeX,10,28,28)],nil];
}
@implementation TGAquaAudioPlayerView
@synthesize layoutTarget=_layoutTarget, layoutAction=_layoutAction;
- (NSView *)surface { return _surface; }
- (id)initWithFrame:(NSRect)frame {
    if ((self=[super initWithFrame:frame])) {
        _surface=[[TGAquaMetalView alloc] initWithFrame:[self bounds]];
        [_surface setAutoresizingMask:NSViewWidthSizable];
        [self addSubview:_surface]; [self setHidden:YES];
    }
    return self;
}
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    (void)oldSize; [self cancelAnimation]; [_surface setFrame:[self bounds]]; [self setHidden:!_presented];
}
- (void)cancelAnimation { [_reveal setDelegate:nil]; [_reveal stopAnimation]; [_reveal release]; _reveal=nil; }
- (void)finishPresentation {
    [self cancelAnimation]; [_surface setFrame:[self bounds]]; [self setHidden:!_presented];
    if (_layoutTarget && _layoutAction && [_layoutTarget respondsToSelector:_layoutAction]) [_layoutTarget performSelector:_layoutAction withObject:self];
}
- (void)setPresented:(BOOL)presented animated:(BOOL)animated {
    if (_presented==presented && (![self isHidden])==presented && !_reveal) return;
    [self cancelAnimation]; _presented=presented;
    BOOL animate=animated && [[self window] isVisible] && TGInterfaceAnimationsEnabledForView(self);
    [self setHidden:NO];
    NSRect end=[self bounds], start=end;
    if (presented) start.origin.y+=NSHeight(end); else end.origin.y+=NSHeight(end);
    [_surface setFrame:start];
    if (!animate) { [self finishPresentation]; return; }
    NSDictionary *motion=[NSDictionary dictionaryWithObjectsAndKeys:_surface,NSViewAnimationTargetKey,[NSValue valueWithRect:start],NSViewAnimationStartFrameKey,[NSValue valueWithRect:end],NSViewAnimationEndFrameKey,nil];
    _reveal=[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:motion]];
    [_reveal setDuration:0.20]; [_reveal setAnimationCurve:NSAnimationEaseOut]; [_reveal setAnimationBlockingMode:NSAnimationNonblocking]; [_reveal setDelegate:self]; [_reveal startAnimation];
}
- (void)animationDidEnd:(NSAnimation *)animation { if (animation==_reveal) [self finishPresentation]; }
- (void)dealloc { _layoutTarget=nil; [self cancelAnimation]; [_surface release]; [super dealloc]; }
@end
