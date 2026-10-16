#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "TGAquaMediaViewerView.h"
#import "TGAquaShellViews.h"
#import "TGStatusViewComponents.h"
#import "TGStatusViewCells.h"
#import "TGKeyboardInputSupport.h"
#include <assert.h>
static BOOL Aqua;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
NSString *TGLoc(NSString *key) { return key; }
NSImage *TGIconAssetImageNamed(NSString *name) { (void)name; return nil; }
NSColor *TGClassicCardInkColor(void) { return [NSColor blackColor]; }
NSArray *TGMediaPlaybackSupportedRates(void) { return [NSArray arrayWithObjects:@1.0,@1.5,@2.0,nil]; }
double TGMediaPlaybackPreferredRate(BOOL audio) { (void)audio; return 1; }
@implementation TGAquaMetalView
@synthesize dividerX=_dividerX;
@end
@implementation TGNavigationButtonCell
@synthesize badgeText=_badgeText,iconOnly=_iconOnly;
- (void)dealloc { [_badgeText release]; [super dealloc]; }
@end
@implementation TGAquaUtilityButtonCell
@synthesize iconAssetName=_iconAssetName;
- (void)dealloc { [_iconAssetName release]; [super dealloc]; }
@end
@implementation TGAquaTextButtonCell
@synthesize accented=_accented;
@end
@implementation TGUtilityWindowView
@end
@implementation TGUtilityPanelView
@end
@implementation TGGroupedCardView
@synthesize drawsInterior=_drawsInterior;
@end
@implementation TGScrollSurfaceView
@synthesize drawsInterior=_drawsInterior;
@end
@implementation TGMediaPreviewScrollView
@synthesize magnificationTarget=_magnificationTarget;
@end
@implementation TGMediaPreviewImageView
@synthesize magnificationTarget=_magnificationTarget;
@end
@implementation TGHeaderIconButtonCell
@end
@implementation TGMediaPlaybackButtonCell
@end
@implementation TGEscapeCloseWindow
@end
@interface ViewerRouting : NSObject <NSWindowDelegate,TGMediaPreviewMagnificationTarget> {
__FIELDS__
}
__PROPERTIES__
@end
@implementation ViewerRouting
__SYNTHESIS__
- (NSTextField *)labelWithFrame:(NSRect)frame text:(NSString *)text font:(NSFont *)font { NSTextField *field=[[[NSTextField alloc] initWithFrame:frame] autorelease];[field setStringValue:text];[field setFont:font];return field; }
- (void)applyMutedLabelStyle:(id)view { (void)view; }
- (void)applyUtilityButtonStyle:(id)view { (void)view; }
- (NSButton *)modalCloseButtonWithFrame:(NSRect)frame { return [[[NSButton alloc] initWithFrame:frame] autorelease]; }
- (void)selectMediaPlaybackRate:(double)rate { (void)rate; }
- (void)mediaPreviewView:(id)sender didMagnifyBy:(NSNumber *)value { (void)sender; (void)value; }
- (void)tearDownClosedMediaPreviewWindow:(NSWindow *)window { if(window==self.mediaPreviewWindow) self.mediaPreviewWindow=nil; }
__PRODUCTION_METHODS__
- (void)dealloc {
 [_mediaPlaybackWindow setDelegate:nil];[_mediaPlaybackWindow close];[_mediaPreviewWindow setDelegate:nil];[_mediaPreviewWindow close];
__RELEASE__
 [super dealloc];
}
@end
int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];NSUInteger checks=0;
 for(NSUInteger mode=0;mode<2;mode++) {
  Aqua=mode;ViewerRouting *owner=[[[ViewerRouting alloc] init] autorelease];[owner ensureMediaPreviewWindow];[owner ensureMediaPlaybackWindow];
  assert([[[owner mediaPreviewWindow] contentView] isKindOfClass:[TGAquaMediaViewerView class]]==Aqua);checks++;
  assert([[[owner mediaPlaybackWindow] contentView] isKindOfClass:[TGAquaMediaViewerView class]]==Aqua);checks++;
  if(Aqua) {
   assert([(TGAquaUtilityButtonCell *)[owner.mediaPreviewZoomOutButton cell] iconOnly]);assert([(TGAquaUtilityButtonCell *)[owner.mediaPreviewZoomInButton cell] iconOnly]);checks+=2;
   assert([[(TGAquaUtilityButtonCell *)[owner.mediaPreviewZoomOutButton cell] iconAssetName] isEqual:@"remove-ellipse"]);checks++;
   assert([[owner.mediaPreviewScrollView contentView] isKindOfClass:[TGAquaMediaImageClipView class]]);checks++;
   [owner.mediaPreviewImageView setFrame:NSMakeRect(0,0,100,80)];
   [[owner.mediaPreviewScrollView contentView] scrollToPoint:NSZeroPoint];
   NSRect centered=[[owner.mediaPreviewScrollView contentView] bounds];
   assert(fabs(NSMidX(centered)-50)<=0.5 && fabs(NSMidY(centered)-40)<=0.5);checks++;
   NSUInteger closes=0;
   for(NSView *header in [[[owner mediaPreviewWindow] contentView] subviews]) for(NSView *child in [header subviews]) {
    if([child isKindOfClass:[NSButton class]] && [[(NSButton *)child cell] isKindOfClass:[TGAquaUtilityButtonCell class]]) {
     TGAquaUtilityButtonCell *cell=[(NSButton *)child cell];
     assert([cell iconOnly] && [[cell iconAssetName] isEqual:@"cross"]);checks++;
     assert([(NSButton *)child target]==owner && [(NSButton *)child action]==@selector(closeAquaMediaViewer:));checks++;
     closes++;
    }
   }
   assert(closes==1);checks++;
  }
  CGFloat widths[]={420,640,900},heights[]={340,500,700};
  for(NSUInteger i=0;i<3;i++) for(NSUInteger j=0;j<3;j++) {
   [owner.mediaPreviewWindow setContentSize:NSMakeSize(widths[i],heights[j])];[owner layoutMediaPreviewWindowControls];
   if(Aqua) {
    NSRect bounds=[[owner.mediaPreviewWindow contentView] bounds];TGAquaMediaViewerGeometry g=TGAquaMediaViewerFrames(bounds,TGAquaMediaViewerPhoto);
    assert(NSEqualRects([owner.mediaPreviewScrollView frame],g.viewport));checks++;
    assert(NSContainsRect(bounds,g.viewport)&&!NSIntersectsRect(g.header,g.viewport)&&!NSIntersectsRect(g.footer,g.viewport));checks++;
    assert(NSEqualRects([owner.mediaPreviewFitButton frame],g.fit));checks++;
   } else { assert(NSMinX([owner.mediaPreviewScrollView frame])==30);checks++; }
   for(NSUInteger circle=0;circle<2;circle++) {
    owner.mediaPlaybackVideoNote=circle;[owner layoutMediaPlaybackWindowForAudioOnly:NO title:@"Movie"];
    [owner.mediaPlaybackWindow setContentSize:NSMakeSize(widths[i],heights[j])];[owner layoutMediaPlaybackChromeForAudioOnly:NO];
    if(Aqua) {
     NSRect bounds=[[owner.mediaPlaybackWindow contentView] bounds];TGAquaMediaViewerGeometry g=TGAquaMediaViewerFrames(bounds,circle ? TGAquaMediaViewerVideoNote : TGAquaMediaViewerVideo);
     assert(NSEqualRects([owner.mediaPlaybackContainerView frame],g.viewport));checks++;
     assert(NSEqualRects([owner.mediaPlaybackPlayPauseButton frame],g.playPause));checks++;
     assert(NSEqualRects([owner.mediaPlaybackProgressSlider frame],g.progress));checks++;
     assert([owner.mediaPlaybackCloseButton isHidden]&&[owner.mediaPlaybackTitleField isHidden]);checks++;
     assert(!NSIntersectsRect(g.header,g.viewport)&&!NSIntersectsRect(g.footer,g.viewport));checks++;
     assert([[owner.mediaPlaybackContainerView layer] masksToBounds]);checks++;
     if(circle) { assert(NSWidth(g.viewport)==NSHeight(g.viewport));assert([[owner.mediaPlaybackContainerView layer] cornerRadius]==NSWidth(g.viewport)/2);checks+=2; }
     else { assert([[owner.mediaPlaybackContainerView layer] cornerRadius]==3);checks++; }
    } else { assert(NSMinX([owner.mediaPlaybackPlayPauseButton frame])==24);checks++; }
   }
  }
 }
 printf("PASS: %lu actual media viewer constructor/layout checks for Aqua photo/video/circle and preserved Classic\n",(unsigned long)checks);
 [pool drain];return 0;
}
