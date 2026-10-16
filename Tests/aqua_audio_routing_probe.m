/* Compiled by aqua_audio_routing_probe.py with actual owner methods injected. */
#import <Cocoa/Cocoa.h>
#import "TGAquaAudioPlayerView.h"
#import "TGAquaShellViews.h"
#include <assert.h>
#include <math.h>

@implementation TGAquaMetalView
@synthesize dividerX=_dividerX;
@end
@implementation TGNavigationButtonCell
@synthesize badgeText=_badgeText,iconOnly=_iconOnly;
- (void)dealloc { [_badgeText release]; [super dealloc]; }
@end
static NSString *DrawnIcon;
void TGAquaDrawButtonInPath(NSBezierPath *path, NSRect rect, BOOL highlighted, BOOL accented, BOOL enabled, BOOL flipped) { (void)path; (void)rect; (void)highlighted; (void)accented; (void)enabled; (void)flipped; }
NSColor *TGColorFromHex(NSUInteger value) { (void)value; return [NSColor blackColor]; }
void TGDrawTemplateIconAsset(NSString *name, NSRect frame, NSColor *ink, CGFloat alpha, BOOL flipped) { (void)frame; (void)ink; (void)alpha; (void)flipped; DrawnIcon=name; }
__PRODUCTION_UTILITY_CELL__
BOOL TGInterfaceAnimationsEnabledForView(NSView *view) { (void)view; return NO; }
NSString *TGLoc(NSString *key) { return key; }
NSImage *TGIconAssetImageNamed(NSString *name) { (void)name; return nil; }
NSData *TGMediaItemMiniThumbnailData(NSDictionary *item) { (void)item; return nil; }
@interface TGMessageItem : NSObject
- (NSNumber *)chatID;
@end
@implementation TGMessageItem
- (NSNumber *)chatID { return nil; }
@end
TGMessageItem *TGNextSequentialAudioMessageItem(NSArray *items, TGMessageItem *source) { (void)items; (void)source; return nil; }
static NSDictionary *TGMediaCenterFirstMediaDictionaryForItem(TGMessageItem *item) { (void)item; return nil; }

@interface AudioRouting : NSObject {
    TGAquaAudioPlayerView *_aquaAudioPlayerView;
    NSWindow *_mediaPlaybackWindow;
    NSView *_mediaPlaybackPlayPauseButton;
    NSTextField *_mediaPlaybackTitleField;
    NSButton *_aquaAudioNextButton;
    NSView *_mediaPlaybackProgressSlider, *_mediaPlaybackTimeField, *_mediaPlaybackRatePopUpButton, *_aquaAudioCloseButton;
    NSArray *_messageItems;
    TGMessageItem *_mediaPlaybackSourceMessageItem;
    NSNumber *_selectedChatID;
    NSWindow *_mainWindow;
    NSView *_aquaToolbarView;
}
@property(nonatomic,retain) TGAquaAudioPlayerView *aquaAudioPlayerView;
@property(nonatomic,retain) NSWindow *mediaPlaybackWindow;
@property(nonatomic,retain) NSView *mediaPlaybackPlayPauseButton;
@property(nonatomic,retain) NSTextField *mediaPlaybackTitleField;
@property(nonatomic,retain) NSButton *aquaAudioNextButton;
@property(nonatomic,retain) NSView *mediaPlaybackProgressSlider, *mediaPlaybackTimeField, *mediaPlaybackRatePopUpButton, *aquaAudioCloseButton;
@property(nonatomic,retain) NSArray *messageItems;
@property(nonatomic,retain) TGMessageItem *mediaPlaybackSourceMessageItem;
@property(nonatomic,retain) NSNumber *selectedChatID;
@property(nonatomic,retain) NSView *aquaToolbarView;
@end
@implementation AudioRouting
@synthesize aquaAudioPlayerView=_aquaAudioPlayerView,mediaPlaybackWindow=_mediaPlaybackWindow;
@synthesize mediaPlaybackPlayPauseButton=_mediaPlaybackPlayPauseButton,aquaAudioNextButton=_aquaAudioNextButton,mediaPlaybackTitleField=_mediaPlaybackTitleField;
@synthesize mediaPlaybackProgressSlider=_mediaPlaybackProgressSlider,mediaPlaybackTimeField=_mediaPlaybackTimeField,mediaPlaybackRatePopUpButton=_mediaPlaybackRatePopUpButton,aquaAudioCloseButton=_aquaAudioCloseButton;
@synthesize messageItems=_messageItems,mediaPlaybackSourceMessageItem=_mediaPlaybackSourceMessageItem,selectedChatID=_selectedChatID;
@synthesize aquaToolbarView=_aquaToolbarView;
- (NSWindow *)window {
    if (!_mainWindow) {
        _mainWindow=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,980,600) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
        [_mainWindow setReleasedWhenClosed:NO];
    }
    return _mainWindow;
}
- (void)layoutContentView { [self layoutAquaAudioPlayerForContentBounds:NSMakeRect(0,0,980,600)]; }
- (void)aquaAudioPlayerPresentationChanged:(id)sender { (void)sender; [self layoutContentView]; }
__PRODUCTION_AUDIO_METHODS__
- (void)dealloc {
    [_aquaAudioPlayerView setLayoutTarget:nil];
    [_aquaAudioPlayerView release]; [_mediaPlaybackWindow release];
    [_mediaPlaybackPlayPauseButton release]; [_aquaAudioNextButton release]; [_mediaPlaybackTitleField release];
    [_mediaPlaybackProgressSlider release]; [_mediaPlaybackTimeField release]; [_mediaPlaybackRatePopUpButton release]; [_aquaAudioCloseButton release];
    [_messageItems release]; [_mediaPlaybackSourceMessageItem release]; [_selectedChatID release];
    [_aquaToolbarView release]; [_mainWindow close]; [_mainWindow release]; [super dealloc];
}
@end

int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    AudioRouting *owner=[[[AudioRouting alloc] init] autorelease];
    owner.mediaPlaybackWindow=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,520,360) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [owner.mediaPlaybackWindow setReleasedWhenClosed:NO];
    owner.mediaPlaybackPlayPauseButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    owner.mediaPlaybackTitleField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    owner.mediaPlaybackProgressSlider=[[[NSSlider alloc] initWithFrame:NSZeroRect] autorelease];
    owner.mediaPlaybackTimeField=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    owner.mediaPlaybackRatePopUpButton=[[[NSPopUpButton alloc] initWithFrame:NSZeroRect] autorelease];
    [owner presentAquaAudioPlayer];
    NSArray *common=[NSArray arrayWithObjects:owner.mediaPlaybackPlayPauseButton,owner.mediaPlaybackTitleField,owner.mediaPlaybackProgressSlider,owner.mediaPlaybackTimeField,owner.mediaPlaybackRatePopUpButton,nil];
    NSArray *all=[NSArray arrayWithObjects:owner.mediaPlaybackPlayPauseButton,owner.aquaAudioNextButton,owner.mediaPlaybackTitleField,owner.mediaPlaybackProgressSlider,owner.mediaPlaybackTimeField,owner.mediaPlaybackRatePopUpButton,owner.aquaAudioCloseButton,nil];
    for(NSView *view in all) [[owner.aquaAudioPlayerView surface] addSubview:view];
    [owner.aquaAudioPlayerView setPresented:YES animated:NO];
    NSUInteger checks=0;
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:40 pixelsHigh:40 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    NSArray *iconButtons=[NSArray arrayWithObjects:owner.aquaAudioNextButton,owner.aquaAudioCloseButton,nil];
    NSArray *iconNames=[NSArray arrayWithObjects:@"next",@"cross",nil];
    for(NSUInteger i=0;i<2;i++) {
        NSButton *button=[iconButtons objectAtIndex:i];
        TGAquaUtilityButtonCell *cell=[button cell];
        assert([cell isKindOfClass:[TGAquaUtilityButtonCell class]] && [cell iconOnly]); checks++;
        assert([[cell iconAssetName] isEqual:[iconNames objectAtIndex:i]]); checks++;
        for(NSUInteger state=0;state<2;state++) {
            [cell setState:state ? NSOnState : NSOffState];
            DrawnIcon=nil; [cell drawWithFrame:NSMakeRect(0,0,38,34) inView:button];
            assert([DrawnIcon isEqual:[iconNames objectAtIndex:i]]); checks++;
        }
    }
    [NSGraphicsContext restoreGraphicsState];
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
