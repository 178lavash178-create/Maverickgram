#import <Cocoa/Cocoa.h>

// One shared strip hosts the existing player controls; playback stays with its owner.
NSRect TGAquaAudioPlayerFrame(NSRect bounds);
NSArray *TGAquaAudioPlayerControlFrames(CGFloat width);
@interface TGAquaAudioPlayerView : NSView <NSAnimationDelegate> {
    NSView *_surface;
    NSViewAnimation *_reveal;
    BOOL _presented;
    id _layoutTarget;
    SEL _layoutAction;
}
@property(nonatomic, readonly) NSView *surface;
@property(nonatomic, assign) id layoutTarget;
@property(nonatomic, assign) SEL layoutAction;
- (void)setPresented:(BOOL)presented animated:(BOOL)animated;
- (void)cancelAnimation;
@end
