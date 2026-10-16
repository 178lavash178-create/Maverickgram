#import <Cocoa/Cocoa.h>

/* A photo remains the existing, full quality zoomable preview. Only its brief
 * presentation uses a temporary, mouse-transparent image window. */
@protocol TGAquaPhotoTransitionSource <NSObject>
- (NSRect)aquaPhotoPreviewSourceScreenRectForContext:(NSDictionary *)context;
@end

NSRect TGAquaPhotoVisibleScreenRect(NSView *view, NSRect rect);
NSRect TGAquaPhotoAspectFillRect(NSSize imageSize, NSRect bounds);
BOOL TGAquaPhotoTransitionIsStaticPhoto(NSDictionary *mediaItem);
BOOL TGAquaMediaTransitionSupportsThumbnail(NSDictionary *mediaItem);
NSRect TGAquaPhotoIntersectedVisibleScreenRect(NSView *view, NSRect rect);
void TGAquaPhotoTransitionOpen(NSWindow *window, NSImageView *imageView,
                              NSView *sourcePolicyView, id<TGAquaPhotoTransitionSource> source,
                              NSDictionary *context);
void TGAquaMediaTransitionOpen(NSWindow *window, NSView *destinationView, NSImage *poster,
                              NSView *sourcePolicyView, id<TGAquaPhotoTransitionSource> source,
                              NSDictionary *context, BOOL circular);
BOOL TGAquaPhotoTransitionShouldClose(NSWindow *window);
void TGAquaPhotoTransitionCancel(NSWindow *window);
void TGAquaPhotoTransitionClear(NSWindow *window);
