#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "TGAquaMediaViewerView.h"
#import "TGAquaShellViews.h"
#import "TGIconAssets.h"
#import "TGStatusViewComponents.h"
#import "TGStatusViewCells.h"
#import "TGKeyboardInputSupport.h"
#include <assert.h>
static BOOL Aqua;
static NSUInteger PreviousCount,NextCount;
BOOL TGInterfaceDesignIsAqua(void) { return Aqua; }
NSString *TGLoc(NSString *key) { return [key isEqual:@"media.viewer.fit"] ? @"Сброс" : key; }
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
- (void)previousAquaPhoto:(id)sender { (void)sender; PreviousCount++; }
- (void)nextAquaPhoto:(id)sender { (void)sender; NextCount++; }
- (void)mediaPreviewView:(id)sender didMagnifyBy:(NSNumber *)value { (void)sender; (void)value; }
- (void)tearDownClosedMediaPreviewWindow:(NSWindow *)window { if(window==self.mediaPreviewWindow) self.mediaPreviewWindow=nil; }
__PRODUCTION_METHODS__
- (void)dealloc {
 [_mediaPlaybackWindow setDelegate:nil];[_mediaPlaybackWindow close];[_mediaPreviewWindow setDelegate:nil];[_mediaPreviewWindow close];
__RELEASE__
 [super dealloc];
}
@end

static NSBitmapImageRep *DrawControl(NSButton *button,NSUInteger scale,BOOL flipped) {
 NSRect frame=NSMakeRect(0,0,NSWidth([button frame]),NSHeight([button frame]));
 NSInteger width=NSWidth(frame)*scale,height=NSHeight(frame)*scale;
 NSBitmapImageRep *rep=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
 [NSGraphicsContext saveGraphicsState];NSGraphicsContext *context=[NSGraphicsContext graphicsContextWithBitmapImageRep:rep];[NSGraphicsContext setCurrentContext:context];
 [[NSColor blackColor] set];NSRectFill(NSMakeRect(0,0,width,height));
 NSAffineTransform *transform=[NSAffineTransform transform];if(flipped)[transform translateXBy:0 yBy:height];[transform scaleXBy:scale yBy:flipped ? -(CGFloat)scale : scale];[transform concat];
 [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[context graphicsPort] flipped:flipped]];
 [[button cell] drawWithFrame:frame inView:button];[NSGraphicsContext restoreGraphicsState];return rep;
}
static NSUInteger Brightness(NSBitmapImageRep *rep,NSInteger x,NSInteger y) {
 NSColor *c=[[rep colorAtX:x y:y] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];return lround([c redComponent]*255);
}
static NSUInteger CheckDarkPhoto(ViewerRouting *owner) {
 NSUInteger checks=0;
 NSMutableArray *controls=[NSMutableArray arrayWithObjects:owner.mediaPreviewZoomOutButton,owner.mediaPreviewFitButton,owner.mediaPreviewZoomInButton,nil];
 for(NSView *header in [[owner.mediaPreviewWindow contentView] subviews])for(NSView *child in [header subviews])if([child isKindOfClass:[TGAquaMediaControlButton class]])[controls addObject:child];
 assert([controls count]==7);checks++;
 NSEvent *entered=[NSEvent enterExitEventWithType:NSMouseEntered location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:0 trackingNumber:0 userData:NULL];
 NSEvent *exited=[NSEvent enterExitEventWithType:NSMouseExited location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:0 trackingNumber:0 userData:NULL];
 for(NSButton *button in controls) {
  [button setEnabled:YES];
  TGAquaMediaControlCell *cell=(id)[button cell];assert([cell isKindOfClass:[TGAquaMediaControlCell class]]);checks++;
  if([[cell iconAssetName] length]) {assert(TGIconAssetImageNamed([cell iconAssetName])!=nil);checks++;}
  [button updateTrackingAreas];[button mouseEntered:entered];assert([cell hovered]);[button mouseExited:exited];assert(![cell hovered]);checks+=2;
  for(NSUInteger scale=1;scale<=2;scale++)for(NSUInteger flipped=0;flipped<2;flipped++) {
   [cell setHovered:NO];[cell setHighlighted:NO];NSBitmapImageRep *normal=DrawControl(button,scale,flipped);
   assert(Brightness(normal,4*scale,14*scale)==0);checks++;
   NSUInteger bright=0;for(NSInteger y=0;y<[normal pixelsHigh];y++)for(NSInteger x=0;x<[normal pixelsWide];x++)if(Brightness(normal,x,y)>150)bright++;
   assert(bright>8*scale);checks++;
   [cell setHovered:YES];NSBitmapImageRep *hover=DrawControl(button,scale,flipped);
   [cell setHighlighted:YES];NSBitmapImageRep *pressed=DrawControl(button,scale,flipped);
   assert(Brightness(hover,4*scale,14*scale)>15 && Brightness(pressed,4*scale,14*scale)>Brightness(hover,4*scale,14*scale)+15);checks++;
   [cell setEnabled:NO];NSBitmapImageRep *disabled=DrawControl(button,scale,flipped);NSUInteger visible=0;
   for(NSInteger y=0;y<[disabled pixelsHigh];y++)for(NSInteger x=0;x<[disabled pixelsWide];x++)if(Brightness(disabled,x,y)>100)visible++;
   assert(visible>5*scale && Brightness(disabled,4*scale,14*scale)==0);checks++;[cell setEnabled:YES];
  }
  [cell setHovered:NO];[cell setHighlighted:NO];
 }
 NSView *view=[owner.mediaPreviewWindow contentView];[owner.mediaPreviewWindow setContentSize:NSMakeSize(640,500)];[owner layoutMediaPreviewWindowControls];
 NSBitmapImageRep *raster=[view bitmapImageRepForCachingDisplayInRect:[view bounds]];[view cacheDisplayInRect:[view bounds] toBitmapImageRep:raster];
 for(NSValue *point in [NSArray arrayWithObjects:[NSValue valueWithPoint:NSMakePoint(2,2)],[NSValue valueWithPoint:NSMakePoint(2,250)],[NSValue valueWithPoint:NSMakePoint(2,490)],nil]) {
  NSPoint p=[point pointValue];assert(Brightness(raster,p.x,p.y)<4);checks++;
 }
 const char *output=getenv("TG_MEDIA_VIEWER_PNG");if(output) {
  NSImage *sample=[[[NSImage alloc] initWithSize:NSMakeSize(320,220)] autorelease];[sample lockFocus];
  [[NSColor colorWithCalibratedRed:0.30 green:0.48 blue:0.62 alpha:1] set];NSRectFill(NSMakeRect(0,0,320,220));
  [[NSColor colorWithCalibratedRed:0.76 green:0.83 blue:0.86 alpha:1] set];NSRectFill(NSMakeRect(0,0,320,70));[sample unlockFocus];
  [owner.mediaPreviewImageView setImage:sample];[owner.mediaPreviewImageView setFrame:NSMakeRect(0,0,320,220)];[[owner.mediaPreviewScrollView contentView] scrollToPoint:NSZeroPoint];
  [view cacheDisplayInRect:[view bounds] toBitmapImageRep:raster];[[raster representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:[NSString stringWithUTF8String:output] atomically:YES];
 }
 return checks;
}

int main(void) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];NSUInteger checks=0;
 for(NSUInteger mode=0;mode<2;mode++) {
  Aqua=mode;ViewerRouting *owner=[[[ViewerRouting alloc] init] autorelease];[owner ensureMediaPreviewWindow];[owner ensureMediaPlaybackWindow];
  assert([[[owner mediaPreviewWindow] contentView] isKindOfClass:[TGAquaMediaViewerView class]]==Aqua);checks++;
  assert([[[owner mediaPlaybackWindow] contentView] isKindOfClass:[TGAquaMediaViewerView class]]==Aqua);checks++;
  if(Aqua) {
   assert([[owner.mediaPreviewZoomOutButton cell] isKindOfClass:[TGAquaMediaControlCell class]]);assert([[owner.mediaPreviewZoomInButton cell] isKindOfClass:[TGAquaMediaControlCell class]]);checks+=2;
   assert([owner.mediaPreviewZoomOutButton isKindOfClass:[TGAquaMediaControlButton class]]);assert([owner.mediaPreviewFitButton isKindOfClass:[TGAquaMediaControlButton class]]);checks+=2;
   assert([owner.mediaPreviewZoomOutButton action]==@selector(zoomOutMediaPreview:) && [owner.mediaPreviewFitButton action]==@selector(fitMediaPreview:) && [owner.mediaPreviewZoomInButton action]==@selector(zoomInMediaPreview:));checks++;
   assert([[owner.mediaPreviewFitButton title] isEqual:@"Сброс"] && ![owner.mediaPreviewFitButton isBordered]);checks++;
   assert([[(TGAquaMediaControlCell *)[owner.mediaPreviewZoomOutButton cell] iconAssetName] isEqual:@"remove-ellipse"]);checks++;
   assert([[owner.mediaPreviewScrollView contentView] isKindOfClass:[TGAquaMediaImageClipView class]]);checks++;
   [owner.mediaPreviewImageView setFrame:NSMakeRect(0,0,100,80)];
   [[owner.mediaPreviewScrollView contentView] scrollToPoint:NSZeroPoint];
   NSRect centered=[[owner.mediaPreviewScrollView contentView] bounds];
   assert(fabs(NSMidX(centered)-50)<=0.5 && fabs(NSMidY(centered)-40)<=0.5);checks++;
   NSUInteger closes=0;
   for(NSView *header in [[[owner mediaPreviewWindow] contentView] subviews]) for(NSView *child in [header subviews]) {
    if([child isKindOfClass:[NSButton class]] && [[(NSButton *)child cell] isKindOfClass:[TGAquaMediaControlCell class]] && [[(TGAquaMediaControlCell *)[(NSButton *)child cell] iconAssetName] isEqual:@"cross"]) {
     TGAquaMediaControlCell *cell=[(NSButton *)child cell];
     assert([[cell iconAssetName] isEqual:@"cross"] && ![(NSButton *)child isBordered]);checks++;
     assert([(NSButton *)child target]==owner && [(NSButton *)child action]==@selector(closeAquaMediaViewer:));checks++;
     closes++;
    }
   }
   assert(closes==1);checks++;
   assert([owner.mediaPreviewWindow isKindOfClass:[TGAquaPhotoGalleryWindow class]]);checks++;
   assert(([owner.mediaPreviewWindow collectionBehavior]&NSWindowCollectionBehaviorFullScreenPrimary)!=0);checks++;
   TGAquaMediaViewerView *viewer=(TGAquaMediaViewerView *)[owner.mediaPreviewWindow contentView];
   NSButton *previous=nil,*next=nil,*fullscreen=nil;NSTextField *counter=nil;
   for(NSView *header in [viewer subviews]) for(NSView *child in [header subviews]) {
    if([child isKindOfClass:[NSButton class]]) {
     NSButton *button=(NSButton *)child;
     if([button action]==@selector(previousAquaPhoto:))previous=button;
     if([button action]==@selector(nextAquaPhoto:))next=button;
     if([button action]==@selector(toggleAquaPhotoFullscreen:))fullscreen=button;
    } else if([child isKindOfClass:[NSTextField class]] && ![child isHidden]) counter=(NSTextField *)child;
   }
   assert(previous && next && fullscreen && counter);checks++;
   assert([(TGAquaMediaControlCell *)[previous cell] mirrored] && ![(TGAquaMediaControlCell *)[next cell] mirrored]);checks++;
   [viewer setGalleryIndex:2 count:12];assert([[counter stringValue] isEqual:@"3 / 12"] && [previous isEnabled] && [next isEnabled]);checks++;
   [viewer setGalleryIndex:0 count:12];assert(![previous isEnabled] && [next isEnabled]);checks++;
   [viewer setGalleryIndex:11 count:12];assert([previous isEnabled] && ![next isEnabled]);checks++;
   [viewer setGalleryIndex:NSNotFound count:0];assert(![previous isEnabled] && ![next isEnabled] && [[counter stringValue] length]==0);checks++;
   for(NSUInteger arrow=0;arrow<2;arrow++) {
    unichar key=arrow ? NSRightArrowFunctionKey : NSLeftArrowFunctionKey;NSString *chars=[NSString stringWithCharacters:&key length:1];
    NSEvent *event=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[owner.mediaPreviewWindow windowNumber] context:nil characters:chars charactersIgnoringModifiers:chars isARepeat:NO keyCode:arrow ? 124 : 123];
    assert([owner.mediaPreviewWindow performKeyEquivalent:event]);checks++;
   }
   assert(PreviousCount==1 && NextCount==1);checks++;
   checks+=CheckDarkPhoto(owner);
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
     NSUInteger closeCount=0;for(NSView *header in [[owner.mediaPlaybackWindow contentView] subviews])for(NSView *child in [header subviews])if([child isKindOfClass:[TGAquaMediaControlButton class]] && ![child isHidden]){assert([(NSButton *)child target]==owner && [(NSButton *)child action]==@selector(closeAquaMediaViewer:));closeCount++;}assert(closeCount==1);checks++;
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
