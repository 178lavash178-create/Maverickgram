#import <Cocoa/Cocoa.h>

/* A photo remains the existing, full quality zoomable preview. Only its brief
 * presentation uses a temporary, mouse-transparent image window. */
@protocol TGAquaPhotoTransitionSource <NSObject>
- (NSRect)aquaPhotoPreviewSourceScreenRectForContext:(NSDictionary *)context;
@end

NSRect TGAquaPhotoVisibleScreenRect(NSView *view, NSRect rect);
NSRect TGAquaPhotoAspectFillRect(NSSize imageSize, NSRect bounds);
BOOL TGAquaPhotoTransitionIsStaticPhoto(NSDictionary *mediaItem);
void TGAquaPhotoTransitionOpen(NSWindow *window, NSImageView *imageView,
                              NSView *sourcePolicyView, id<TGAquaPhotoTransitionSource> source,
                              NSDictionary *context);
BOOL TGAquaPhotoTransitionShouldClose(NSWindow *window);
void TGAquaPhotoTransitionCancel(NSWindow *window);
void TGAquaPhotoTransitionClear(NSWindow *window);
