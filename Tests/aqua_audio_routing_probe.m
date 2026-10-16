/* Compiled by aqua_audio_routing_probe.py with actual owner methods injected. */
#import <Cocoa/Cocoa.h>
#import "TGAquaAudioPlayerView.h"
#import "TGAquaShellViews.h"
#include <assert.h>

@implementation TGAquaMetalView
@synthesize dividerX=_dividerX;
@end
BOOL TGInterfaceAnimationsEnabledForView(NSView *view) { (void)view; return NO; }
@interface TGMessageItem : NSObject
- (NSNumber *)chatID;
@end
@implementation TGMessageItem
- (NSNumber *)chatID { return nil; }
@end
TGMessageItem *TGNextSequentialAudioMessageItem(NSArray *items, TGMessageItem *source) { (void)items; (void)source; return nil; }

@interface AudioRouting : NSObject {
    TGAquaAudioPlayerView *_aquaAudioPlayerView;
    NSWindow *_mediaPlaybackWindow;
    NSView *_mediaPlaybackPlayPauseButton, *_mediaPlaybackTitleField;
    NSButton *_aquaAudioNextButton;
    NSView *_mediaPlaybackProgressSlider, *_mediaPlaybackTimeField, *_mediaPlaybackRatePopUpButton, *_aquaAudioCloseButton;
    NSArray *_messageItems;
    TGMessageItem *_mediaPlaybackSourceMessageItem;
    NSNumber *_selectedChatID;
}
@property(nonatomic,retain) TGAquaAudioPlayerView *aquaAudioPlayerView;
@property(nonatomic,retain) NSWindow *mediaPlaybackWindow;
@property(nonatomic,retain) NSView *mediaPlaybackPlayPauseButton, *mediaPlaybackTitleField;
@property(nonatomic,retain) NSButton *aquaAudioNextButton;
@property(nonatomic,retain) NSView *mediaPlaybackProgressSlider, *mediaPlaybackTimeField, *mediaPlaybackRatePopUpButton, *aquaAudioCloseButton;
@property(nonatomic,retain) NSArray *messageItems;
@property(nonatomic,retain) TGMessageItem *mediaPlaybackSourceMessageItem;
@property(nonatomic,retain) NSNumber *selectedChatID;
@end
@implementation AudioRouting
@synthesize aquaAudioPlayerView=_aquaAudioPlayerView,mediaPlaybackWindow=_mediaPlaybackWindow;
@synthesize mediaPlaybackPlayPauseButton=_mediaPlaybackPlayPauseButton,aquaAudioNextButton=_aquaAudioNextButton,mediaPlaybackTitleField=_mediaPlaybackTitleField;
@synthesize mediaPlaybackProgressSlider=_mediaPlaybackProgressSlider,mediaPlaybackTimeField=_mediaPlaybackTimeField,mediaPlaybackRatePopUpButton=_mediaPlaybackRatePopUpButton,aquaAudioCloseButton=_aquaAudioCloseButton;
@synthesize messageItems=_messageItems,mediaPlaybackSourceMessageItem=_mediaPlaybackSourceMessageItem,selectedChatID=_selectedChatID;
- (void)layoutContentView { [self layoutAquaAudioPlayerForContentBounds:NSMakeRect(0,0,980,600)]; }
__PRODUCTION_AUDIO_METHODS__
- (void)dealloc {
    [_aquaAudioPlayerView release]; [_mediaPlaybackWindow release];
    [_mediaPlaybackPlayPauseButton release]; [_aquaAudioNextButton release]; [_mediaPlaybackTitleField release];
    [_mediaPlaybackProgressSlider release]; [_mediaPlaybackTimeField release]; [_mediaPlaybackRatePopUpButton release]; [_aquaAudioCloseButton release];
    [_messageItems release]; [_mediaPlaybackSourceMessageItem release]; [_selectedChatID release]; [super dealloc];
}
@end

int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    AudioRouting *owner=[[[AudioRouting alloc] init] autorelease];
    owner.aquaAudioPlayerView=[[[TGAquaAudioPlayerView alloc] initWithFrame:NSMakeRect(0,0,980,48)] autorelease];
    owner.mediaPlaybackWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,520,360) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [owner.mediaPlaybackWindow setReleasedWhenClosed:NO];
    owner.mediaPlaybackPlayPauseButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    owner.aquaAudioNextButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    owner.mediaPlaybackTitleField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    owner.mediaPlaybackProgressSlider=[[[NSSlider alloc] initWithFrame:NSZeroRect] autorelease];
    owner.mediaPlaybackTimeField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    owner.mediaPlaybackRatePopUpButton=[[[NSPopUpButton alloc] initWithFrame:NSZeroRect] autorelease];
    owner.aquaAudioCloseButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    NSArray *common=[NSArray arrayWithObjects:owner.mediaPlaybackPlayPauseButton,owner.mediaPlaybackTitleField,owner.mediaPlaybackProgressSlider,owner.mediaPlaybackTimeField,owner.mediaPlaybackRatePopUpButton,nil];
    NSArray *all=[NSArray arrayWithObjects:owner.mediaPlaybackPlayPauseButton,owner.aquaAudioNextButton,owner.mediaPlaybackTitleField,owner.mediaPlaybackProgressSlider,owner.mediaPlaybackTimeField,owner.mediaPlaybackRatePopUpButton,owner.aquaAudioCloseButton,nil];
    for(NSView *view in all) [[owner.aquaAudioPlayerView surface] addSubview:view];
    [owner.aquaAudioPlayerView setPresented:YES animated:NO];
    NSUInteger checks=0;
    for(NSUInteger cycle=0;cycle<3;cycle++) {
        CGFloat widths[]={760,980,1440};
        for(NSUInteger i=0;i<3;i++) {
            NSRect bounds=NSMakeRect(0,0,widths[i],600);
            [owner layoutAquaAudioPlayerForContentBounds:bounds];
            assert(NSEqualRects([owner.aquaAudioPlayerView frame],TGAquaAudioPlayerFrame(bounds))); checks++;
            NSArray *expected=TGAquaAudioPlayerControlFrames(widths[i]);
            for(NSUInteger index=0;index<[all count];index++) {
                NSView *view=[all objectAtIndex:index];
                assert([view superview]==[owner.aquaAudioPlayerView surface]);
                assert(NSEqualRects([view frame],[[expected objectAtIndex:index] rectValue])); checks+=2;
            }
        }
        /* Actual controller detach moves shared controls back to the separate
         * playback window, which will next host a video. */
        [owner detachAquaAudioPlayerAnimated:NO];
        assert([owner.aquaAudioPlayerView isHidden]); checks++;
        NSMutableArray *videoFrames=[NSMutableArray array];
        NSUInteger index=0;
        for(NSView *view in common) {
            assert([view superview]==[owner.mediaPlaybackWindow contentView]); checks++;
            NSRect frame=NSMakeRect(24+index*80,18,60,24);
            [view setFrame:frame]; [view setAutoresizingMask:NSViewMaxYMargin];
            [videoFrames addObject:[NSValue valueWithRect:frame]]; index++;
        }
        for(NSUInteger i=0;i<3;i++) {
            [owner layoutAquaAudioPlayerForContentBounds:NSMakeRect(0,0,widths[i],600)];
            index=0;
            for(NSView *view in common) {
                assert([view superview]==[owner.mediaPlaybackWindow contentView]);
                assert(NSEqualRects([view frame],[[videoFrames objectAtIndex:index++] rectValue]));
                assert([view autoresizingMask]==NSViewMaxYMargin); checks+=3;
            }
        }
        for(NSView *view in common) { [view removeFromSuperview]; [[owner.aquaAudioPlayerView surface] addSubview:view]; }
        [owner.aquaAudioPlayerView setPresented:YES animated:NO];
        [owner layoutContentView];
        assert([owner.mediaPlaybackPlayPauseButton superview]==[owner.aquaAudioPlayerView surface]); checks++;
    }
    [owner.mediaPlaybackWindow close];
    printf("PASS: %lu actual audio controller layout/ownership checks across inline audio, detached video, main-window resize and audio return\n",(unsigned long)checks);
    [pool drain]; return 0;
}
