#import <Cocoa/Cocoa.h>
#import "TGAquaPhotoTransition.h"
#include <assert.h>
#include <math.h>
#import <objc/runtime.h>

NSString * const TGResourcePolicyDidChangeNotification = @"ProbePolicyChanged";
static BOOL Animations = YES;
static NSUInteger TransitionInitializations;
typedef id (*TGTransitionInitIMP)(id,SEL,NSWindow *,NSView *,NSImage *,NSView *,id,NSDictionary *,BOOL,BOOL);
static TGTransitionInitIMP OriginalTransitionInit;
static id CountTransitionInit(id self,SEL selector,NSWindow *window,NSView *imageView,NSImage *image,
    NSView *policyView,id source,NSDictionary *context,BOOL returns,BOOL circular) {
    TransitionInitializations++;
    return OriginalTransitionInit(self,selector,window,imageView,image,policyView,source,context,returns,circular);
}
BOOL TGInterfaceAnimationsEnabledForView(NSView *view) { return Animations && [[view window] isVisible]; }
NSString *TGMediaItemContentType(NSDictionary *item) { return [item objectForKey:@"content_type"]; }
NSNumber *TGMediaItemFullFileID(NSDictionary *item) { return [item objectForKey:@"full_file_id"]; }
BOOL TGInterfaceDesignIsAqua(void) { return YES; }

@interface TGMessageItem : NSObject {
    NSNumber *_messageID;
    NSArray *_entries;
}
@property(nonatomic,retain) NSNumber *messageID;
@property(nonatomic,retain) NSArray *entries;
@end
@implementation TGMessageItem
@synthesize messageID=_messageID, entries=_entries;
- (void)dealloc { [_messageID release]; [_entries release]; [super dealloc]; }
@end

/* Run the production resolver, with synthetic model/table geometry. Native
 * window and visible-rect conversion still use actual AppKit views. */
@interface PhotoController : NSObject {
    id _client;
    NSNumber *_profileUserID, *_selectedChatID, *_selectedMessageThreadID;
    NSString *_selectedMessageTopicKind, *_currentAuthState, *_activeSection;
    NSArray *_messageItems;
    NSView *_messageTableView, *_mediaCenterResultsView;
    NSWindow *_mediaPreviewWindow;
    NSWindow *_mediaPlaybackWindow;
    NSScrollView *_mediaPreviewScrollView;
    NSImageView *_mediaPreviewImageView;
    NSButton *_mediaPreviewZoomOutButton;
    CGFloat _mediaPreviewZoomScale,_mediaPreviewMinimumZoomScale;
    BOOL _mediaCenterVisible, _chatNavigationClosed;
    NSUInteger _mediaCenterGeneration, _mediaPreviewRequestGeneration;
}
@property(nonatomic,retain) id client;
@property(nonatomic,retain) NSNumber *profileUserID, *selectedChatID, *selectedMessageThreadID;
@property(nonatomic,copy) NSString *selectedMessageTopicKind, *currentAuthState, *activeSection;
@property(nonatomic,retain) NSArray *messageItems;
@property(nonatomic,retain) NSView *messageTableView, *mediaCenterResultsView;
@property(nonatomic,retain) NSWindow *mediaPreviewWindow;
@property(nonatomic,retain) NSWindow *mediaPlaybackWindow;
@property(nonatomic,retain) NSScrollView *mediaPreviewScrollView;
@property(nonatomic,retain) NSImageView *mediaPreviewImageView;
@property(nonatomic,retain) NSButton *mediaPreviewZoomOutButton;
@property(nonatomic,assign) CGFloat mediaPreviewZoomScale,mediaPreviewMinimumZoomScale;
@property(nonatomic,assign) BOOL mediaCenterVisible, chatNavigationClosed;
@property(nonatomic,assign) NSUInteger mediaCenterGeneration, mediaPreviewRequestGeneration;
- (NSRect)messageBubbleCellFrameForRow:(NSInteger)row;
- (NSArray *)mediaLayoutEntriesForItem:(TGMessageItem *)item inCellFrame:(NSRect)frame;
@end
@implementation PhotoController
@synthesize client=_client,profileUserID=_profileUserID,selectedChatID=_selectedChatID,selectedMessageThreadID=_selectedMessageThreadID;
@synthesize selectedMessageTopicKind=_selectedMessageTopicKind,currentAuthState=_currentAuthState,messageItems=_messageItems;
@synthesize messageTableView=_messageTableView,mediaCenterResultsView=_mediaCenterResultsView,mediaPreviewWindow=_mediaPreviewWindow;
@synthesize mediaPlaybackWindow=_mediaPlaybackWindow;
@synthesize mediaPreviewScrollView=_mediaPreviewScrollView,mediaPreviewImageView=_mediaPreviewImageView,mediaPreviewZoomOutButton=_mediaPreviewZoomOutButton;
@synthesize mediaPreviewZoomScale=_mediaPreviewZoomScale,mediaPreviewMinimumZoomScale=_mediaPreviewMinimumZoomScale;
@synthesize mediaCenterVisible=_mediaCenterVisible,mediaCenterGeneration=_mediaCenterGeneration,mediaPreviewRequestGeneration=_mediaPreviewRequestGeneration;
@synthesize activeSection=_activeSection,chatNavigationClosed=_chatNavigationClosed;
- (NSRect)messageBubbleCellFrameForRow:(NSInteger)row { (void)row; return NSMakeRect(0,0,200,200); }
- (NSArray *)mediaLayoutEntriesForItem:(TGMessageItem *)item inCellFrame:(NSRect)frame { (void)frame; return [item entries]; }
/* Gallery navigation is exercised by aqua_photo_gallery_probe; this probe
 * isolates the transition resolver and zoom path. */
- (void)prepareAquaPhotoGalleryForMessage:(TGMessageItem *)item mediaItem:(NSDictionary *)media gridSender:(id)sender { (void)item;(void)media;(void)sender; }
- (void)clearAquaPhotoGallery {}
// The static-image worker has its own cancellation/generation probe.
- (void)cancelMediaPreviewImageLoad {}
#include "TGStatusWindowController+AquaPhotoPreview.inc"
#include "TGStatusWindowController+MediaPreviewZoom.inc"
- (void)dealloc {
    [self invalidateAquaPhotoPreview];
    [_client release]; [_profileUserID release]; [_selectedChatID release]; [_selectedMessageThreadID release];
    [_selectedMessageTopicKind release]; [_currentAuthState release]; [_messageItems release]; [_activeSection release];
    [_messageTableView release]; [_mediaCenterResultsView release]; [_mediaPreviewWindow release]; [_mediaPlaybackWindow release];
    [_mediaPreviewScrollView release]; [_mediaPreviewImageView release]; [_mediaPreviewZoomOutButton release];
    [super dealloc];
}
@end

@interface PhotoSource : NSObject <TGAquaPhotoTransitionSource, NSWindowDelegate> {
@public NSRect sourceRect; NSUInteger resolutions; NSWindow *preview;
}
@end
@implementation PhotoSource
- (NSRect)aquaPhotoPreviewSourceScreenRectForContext:(NSDictionary *)context {
    assert([[context objectForKey:@"identity"] isEqual:@"photo"]); resolutions++; return sourceRect;
}
- (BOOL)windowShouldClose:(id)sender { return TGAquaPhotoTransitionShouldClose(sender); }
- (void)windowWillClose:(NSNotification *)notification { TGAquaPhotoTransitionClear([notification object]); }
@end

static void Spin(void) {
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:0.36];
    while ([end timeIntervalSinceNow] > 0.0)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
}
static NSWindow *Window(NSRect rect) {
    NSWindow *window = [[[NSWindow alloc] initWithContentRect:rect styleMask:NSTitledWindowMask|NSClosableWindowMask
                                                    backing:NSBackingStoreBuffered defer:NO] autorelease];
    [window setReleasedWhenClosed:NO]; [window orderFront:nil]; return window;
}
static NSUInteger ImageWindows(NSWindow *source, NSWindow *preview) {
    NSUInteger count = 0;
    for (NSWindow *window in [NSApp windows])
        if (window != source && window != preview && [window isVisible] && [window ignoresMouseEvents]) count++;
    return count;
}
int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    NSUInteger geometries = 0;
    CGFloat sizes[] = {1, 32, 128, 1000, 4000};
    for (NSUInteger i=0;i<5;i++) for (NSUInteger j=0;j<5;j++) {
        NSSize size=NSMakeSize(sizes[i],sizes[j]);
        NSRect bounds=NSMakeRect(7,11,123,87);
        NSRect rect=TGAquaPhotoAspectFillRect(size,bounds);
        assert(NSContainsRect(NSInsetRect(rect,-0.001,-0.001),bounds));
        assert(fabs(NSMidX(rect)-NSMidX(bounds))<0.001 && fabs(NSMidY(rect)-NSMidY(bounds))<0.001);
        assert(fabs(NSWidth(rect)/NSHeight(rect)-size.width/size.height)<0.001); geometries++;
    }
    assert(NSIsEmptyRect(TGAquaPhotoAspectFillRect(NSZeroSize,NSMakeRect(0,0,20,20))));
    NSArray *kinds=[NSArray arrayWithObjects:@"messagePhoto",@"messageAnimation",@"messageVideo",@"messageSticker",@"messageDocument",nil];
    for (NSString *kind in kinds)
        assert(TGAquaPhotoTransitionIsStaticPhoto([NSDictionary dictionaryWithObject:kind forKey:@"content_type"]) == [kind isEqualToString:@"messagePhoto"]);
    assert(!TGAquaPhotoTransitionIsStaticPhoto(nil));
    NSRect screen=[[NSScreen mainScreen] visibleFrame];
    NSWindow *source=Window(NSMakeRect(NSMinX(screen)+20,NSMinY(screen)+30,220,220));
    NSView *anchor=[source contentView];
    NSRect thumb=NSMakeRect(12,18,80,60);
    NSRect sourceRect=TGAquaPhotoVisibleScreenRect(anchor,thumb);
    assert(!NSIsEmptyRect(sourceRect));
    [anchor setHidden:YES]; assert(NSIsEmptyRect(TGAquaPhotoVisibleScreenRect(anchor,thumb))); [anchor setHidden:NO];
    assert(NSIsEmptyRect(TGAquaPhotoVisibleScreenRect(anchor,NSMakeRect(-10,0,40,40))));
    assert(!NSIsEmptyRect(TGAquaPhotoIntersectedVisibleScreenRect(anchor,NSMakeRect(-10,0,40,40))));
    assert(NSIsEmptyRect(TGAquaPhotoIntersectedVisibleScreenRect(anchor,NSMakeRect(-39,0,40,40))));
    PhotoController *controller=[[[PhotoController alloc] init] autorelease];
    controller.client=[[[NSObject alloc] init] autorelease]; controller.profileUserID=@10; controller.selectedChatID=@20;
    controller.currentAuthState=@"ready"; controller.messageTableView=anchor;
    TGMessageItem *album=[[[TGMessageItem alloc] init] autorelease]; album.messageID=@30;
    NSDictionary *first=[NSDictionary dictionaryWithObjectsAndKeys:@"messagePhoto",@"content_type",@41,@"full_file_id",nil];
    NSDictionary *second=[NSDictionary dictionaryWithObjectsAndKeys:@"messagePhoto",@"content_type",@42,@"full_file_id",nil];
    album.entries=[NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:first,@"media_item",[NSValue valueWithRect:NSMakeRect(12,18,60,60)],@"frame",nil],
        [NSDictionary dictionaryWithObjectsAndKeys:second,@"media_item",[NSValue valueWithRect:NSMakeRect(88,18,70,60)],@"frame",nil],nil];
    controller.messageItems=[NSArray arrayWithObject:album];
    [controller prepareAquaPhotoPreviewForMessage:album mediaItem:second gridSender:nil];
    NSDictionary *albumContext=[[controller aquaPhotoPreviewSourceContext] retain];
    NSRect secondRect=[controller aquaPhotoPreviewSourceScreenRectForContext:albumContext];
    assert(NSEqualRects(secondRect,TGAquaPhotoVisibleScreenRect(anchor,NSMakeRect(88,18,70,60))));
    controller.selectedChatID=@21; assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:albumContext])); controller.selectedChatID=@20;
    controller.selectedMessageThreadID=@2; assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:albumContext])); controller.selectedMessageThreadID=nil;
    controller.selectedMessageTopicKind=@"other"; assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:albumContext])); controller.selectedMessageTopicKind=nil;
    controller.profileUserID=@11; assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:albumContext])); controller.profileUserID=@10;
    id previousClient=[[controller client] retain]; controller.client=[[[NSObject alloc] init] autorelease];
    assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:albumContext])); controller.client=previousClient; [previousClient release];
    controller.currentAuthState=@"closed"; assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:albumContext])); controller.currentAuthState=@"ready";
    controller.activeSection=@"settings"; assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:albumContext])); controller.activeSection=nil;
    controller.chatNavigationClosed=YES; assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:albumContext])); controller.chatNavigationClosed=NO;
    album.entries=[NSArray arrayWithObject:[album.entries objectAtIndex:0]];
    assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:albumContext])); /* album tile removed */
    [albumContext release];
    NSView *grid=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,210,210)] autorelease]; [anchor addSubview:grid];
    controller.mediaCenterResultsView=grid; controller.mediaCenterVisible=YES;
    NSView *tile=[[[NSView alloc] initWithFrame:NSMakeRect(10,10,170,150)] autorelease]; [grid addSubview:tile];
    NSImageView *gridImage=[[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,160,100)] autorelease];
    [gridImage setImage:[[[NSImage alloc] initWithSize:NSMakeSize(80,80)] autorelease]]; [tile addSubview:gridImage];
    NSButton *gridSender=[[[NSButton alloc] initWithFrame:[tile bounds]] autorelease]; [tile addSubview:gridSender];
    [controller prepareAquaPhotoPreviewForMessage:album mediaItem:second gridSender:gridSender];
    NSDictionary *gridContext=[[controller aquaPhotoPreviewSourceContext] retain];
    assert(NSEqualRects([controller aquaPhotoPreviewSourceScreenRectForContext:gridContext],TGAquaPhotoVisibleScreenRect(gridImage,NSMakeRect(30,0,100,100))));
    controller.mediaCenterGeneration++; assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:gridContext])); controller.mediaCenterGeneration--;
    [gridImage removeFromSuperview]; assert(NSIsEmptyRect([controller aquaPhotoPreviewSourceScreenRectForContext:gridContext]));
    [gridContext release]; [grid removeFromSuperview]; controller.mediaCenterVisible=NO;
    /* Pick a genuine floating-point ceil overshoot for the native viewport:
     * scroller trim differs by SDK. Test the production fit, not a copied
     * formula pretending to be the application. */
    NSWindow *fitWindow=Window(NSMakeRect(NSMinX(screen)+30,NSMinY(screen)+40,420,340));
    NSScrollView *fitScroll=[[[NSScrollView alloc] initWithFrame:NSMakeRect(10,10,400,300)] autorelease];
    [fitScroll setBorderType:NSNoBorder]; [fitScroll setHasHorizontalScroller:YES]; [fitScroll setHasVerticalScroller:YES];
    [fitScroll setScrollerStyle:NSScrollerStyleLegacy]; [[fitWindow contentView] addSubview:fitScroll];
    NSImageView *fitImage=[[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,100,100)] autorelease];
    [fitScroll setDocumentView:fitImage]; [fitScroll tile];
    CGFloat viewportHeight=NSHeight([[fitScroll contentView] bounds]),badHeight=0;
    for(NSUInteger candidate=400;candidate<4000;candidate++) {
        volatile CGFloat scale=viewportHeight/(CGFloat)candidate;
        if(ceil((CGFloat)candidate*scale)>viewportHeight) { badHeight=candidate; break; }
    }
    assert(badHeight>0);
    [fitImage setImage:[[[NSImage alloc] initWithSize:NSMakeSize(128,badHeight)] autorelease]];
    controller.mediaPreviewScrollView=fitScroll; controller.mediaPreviewImageView=fitImage;
    controller.mediaPreviewZoomOutButton=[[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [controller fitMediaPreview:nil];
    assert(NSHeight([fitImage frame])<=NSHeight([[fitScroll contentView] bounds]));
    assert(!NSIsEmptyRect(TGAquaPhotoVisibleScreenRect(fitImage,[fitImage bounds])));
    CGFloat fitted=controller.mediaPreviewZoomScale;
    [controller zoomInMediaPreview:nil]; assert(controller.mediaPreviewZoomScale>fitted);
    [controller fitMediaPreview:nil]; assert(controller.mediaPreviewZoomScale==fitted);
    [fitWindow close];
    NSWindow *preview=Window(NSMakeRect(NSMinX(screen)+260,NSMinY(screen)+40,240,220));
    NSImageView *image=[[[NSImageView alloc] initWithFrame:NSMakeRect(10,10,200,150)] autorelease];
    NSImage *picture=[[[NSImage alloc] initWithSize:NSMakeSize(800,600)] autorelease];
    [image setImage:picture]; [[preview contentView] addSubview:image];
    PhotoSource *target=[[[PhotoSource alloc] init] autorelease]; target->sourceRect=sourceRect; target->preview=preview; [preview setDelegate:target];
    NSDictionary *context=[NSDictionary dictionaryWithObject:@"photo" forKey:@"identity"];
    NSUInteger before=ImageWindows(source,preview);
    TGAquaPhotoTransitionOpen(preview,image,anchor,target,context);
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResizeNotification object:preview];
    assert([preview alphaValue]==0.0 && ImageWindows(source,preview)==before+1); /* unchanged first-show notification does not kill reveal */
    assert([preview alphaValue]==0.0 && ImageWindows(source,preview)==before+1);
    Spin(); assert([preview alphaValue]==1.0 && [preview isVisible] && ImageWindows(source,preview)==before);
    assert([image image]==picture && NSEqualSizes([picture size],NSMakeSize(800,600)));
    /* Closing re-resolves identity/geometry, does not use opening coordinates. */
    target->sourceRect.origin.x+=30;
    assert(!TGAquaPhotoTransitionShouldClose(preview)); assert(target->resolutions==2);
    Spin(); assert(![preview isVisible] && [preview alphaValue]==1.0 && ImageWindows(source,preview)==before);
    [preview orderFront:nil]; target->sourceRect=NSZeroRect;
    TGAquaPhotoTransitionOpen(preview,image,anchor,target,context);
    assert([preview alphaValue]==0.0 && ImageWindows(source,preview)==before);
    Spin(); assert([preview alphaValue]==1.0); /* unavailable source -> fade */
    target->sourceRect=sourceRect;
    [image setFrame:NSMakeRect(-50,-30,600,450)];
    TGAquaPhotoTransitionOpen(preview,image,anchor,target,context);
    assert(ImageWindows(source,preview)==before); /* zoom/pan crop stays intact, dissolve */
    TGAquaPhotoTransitionCancel(preview);
    assert(NSEqualRects([image frame],NSMakeRect(-50,-30,600,450)) && [image image]==picture);
    [image setFrame:NSMakeRect(10,10,200,150)];
    TGAquaPhotoTransitionOpen(preview,image,anchor,target,context);
    NSRect moved=[preview frame]; moved.origin.x+=10; [preview setFrame:moved display:NO];
    assert([preview alphaValue]==1.0 && ImageWindows(source,preview)==before);
    target->sourceRect=sourceRect;
    TGAquaPhotoTransitionOpen(preview,image,anchor,target,context);
    Animations=NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:TGResourcePolicyDidChangeNotification object:nil];
    assert([preview alphaValue]==1.0 && ImageWindows(source,preview)==before);
    Method initializer=class_getInstanceMethod(NSClassFromString(@"TGAquaPhotoTransition"),@selector(initWithWindow:imageView:image:policyView:source:context:returns:circular:));
    assert(initializer);OriginalTransitionInit=(TGTransitionInitIMP)method_getImplementation(initializer);
    method_setImplementation(initializer,(IMP)CountTransitionInit);
    NSUInteger suppressedResolutions=target->resolutions, suppressedInitializations=TransitionInitializations;
    TGAquaPhotoTransitionOpen(preview,image,anchor,target,context);
    assert([preview alphaValue]==1.0 && TGAquaPhotoTransitionShouldClose(preview));
    assert(target->resolutions==suppressedResolutions && ImageWindows(source,preview)==before);
    TGAquaMediaTransitionOpen(preview,image,picture,anchor,target,context,YES);
    assert(target->resolutions==suppressedResolutions && TGAquaPhotoTransitionShouldClose(preview));
    assert(TransitionInitializations==suppressedInitializations); /* zero motion owners/observers/timers admitted */
    method_setImplementation(initializer,(IMP)OriginalTransitionInit);
    Animations=YES;
    TGAquaMediaTransitionOpen(preview,image,picture,anchor,target,context,YES);
    assert(ImageWindows(source,preview)==before+1); Spin();
    assert([preview isVisible] && [preview alphaValue]==1.0);
    assert(!TGAquaPhotoTransitionShouldClose(preview));
    assert(ImageWindows(source,preview)==before); /* video closes in place, without stale poster jump */
    Spin(); assert(![preview isVisible]); [preview orderFront:nil];
    TGAquaPhotoTransitionOpen(preview,image,anchor,target,context);
    TGAquaPhotoTransitionOpen(preview,image,anchor,target,context);
    assert(ImageWindows(source,preview)==before+1); /* replacement owns one animation */
    [source close]; assert([preview alphaValue]==1.0 && ImageWindows(source,preview)==before);
    TGAquaPhotoTransitionClear(preview); TGAquaPhotoTransitionClear(preview);
    assert(TGAquaPhotoTransitionShouldClose(preview)); [preview setDelegate:nil]; [preview close];
    printf("Aqua photo transition: %lu aspect geometries, static-photo filtering, visible source, expand/reverse/fade/cancel/policy/lifecycle PASS\n", (unsigned long)geometries);
    [pool drain]; return 0;
}
