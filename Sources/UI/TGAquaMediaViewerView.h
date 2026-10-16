#import <Cocoa/Cocoa.h>
#import "TGKeyboardInputSupport.h"

typedef enum { TGAquaMediaViewerPhoto, TGAquaMediaViewerVideo, TGAquaMediaViewerVideoNote } TGAquaMediaViewerKind;
typedef struct {
    NSRect header, footer, stage, viewport;
    NSRect zoomOut, fit, zoomIn;
    NSRect playPause, progress, time, rate;
} TGAquaMediaViewerGeometry;
TGAquaMediaViewerGeometry TGAquaMediaViewerFrames(NSRect bounds, TGAquaMediaViewerKind kind);
@interface TGAquaMediaImageClipView : NSClipView
@end

@interface TGAquaMediaControlCell : NSButtonCell {
    NSString *_iconAssetName;
    BOOL _hovered;
    BOOL _mirrored;
}
@property(nonatomic, copy) NSString *iconAssetName;
@property(nonatomic, assign) BOOL hovered;
@property(nonatomic, assign) BOOL mirrored;
@end
@interface TGAquaMediaControlButton : NSButton {
    NSTrackingArea *_mediaTrackingArea;
}
@end

/* Native fullscreen is available throughout the shared 10.8+ lane. The
 * window receives arrow shortcuts before the image/scroll view consumes them. */
@interface TGAquaPhotoGalleryWindow : TGEscapeCloseWindow {
    id _galleryTarget;
}
@property(nonatomic, assign) id galleryTarget;
@end

/* Shared media geometry, with a dark borderless gallery for photographs.
 * Playback and image/zoom ownership remain in their existing controllers. */
@interface TGAquaMediaViewerView : NSView {
    NSView *_headerView, *_footerView, *_stageView;
    NSImageView *_typeImageView;
    NSTextField *_titleField, *_detailField;
    NSButton *_closeButton, *_previousButton, *_nextButton, *_fullscreenButton;
    NSTextField *_counterField;
    TGAquaMediaViewerKind _kind;
}
@property(nonatomic, assign) TGAquaMediaViewerKind kind;
@property(nonatomic, readonly) NSView *stageView;
@property(nonatomic, readonly) NSView *footerView;
- (void)setMediaTitle:(NSString *)title detail:(NSString *)detail;
- (void)setCloseTarget:(id)target action:(SEL)action;
- (void)setGalleryTarget:(id)target;
- (void)setGalleryIndex:(NSUInteger)index count:(NSUInteger)count;
@end
