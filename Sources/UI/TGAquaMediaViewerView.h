#import <Cocoa/Cocoa.h>

typedef enum { TGAquaMediaViewerPhoto, TGAquaMediaViewerVideo, TGAquaMediaViewerVideoNote } TGAquaMediaViewerKind;
typedef struct {
    NSRect header, footer, stage, viewport;
    NSRect zoomOut, fit, zoomIn;
    NSRect playPause, progress, time, rate;
} TGAquaMediaViewerGeometry;
TGAquaMediaViewerGeometry TGAquaMediaViewerFrames(NSRect bounds, TGAquaMediaViewerKind kind);
@interface TGAquaMediaImageClipView : NSClipView
@end

/* One material/structure for photographs, films and circular video notes.
 * Playback and image/zoom ownership remain in their existing controllers. */
@interface TGAquaMediaViewerView : NSView {
    NSView *_headerView, *_footerView, *_stageView;
    NSImageView *_typeImageView;
    NSTextField *_titleField, *_detailField;
    NSButton *_closeButton;
    TGAquaMediaViewerKind _kind;
}
@property(nonatomic, assign) TGAquaMediaViewerKind kind;
@property(nonatomic, readonly) NSView *stageView;
@property(nonatomic, readonly) NSView *footerView;
- (void)setMediaTitle:(NSString *)title detail:(NSString *)detail;
- (void)setCloseTarget:(id)target action:(SEL)action;
@end
