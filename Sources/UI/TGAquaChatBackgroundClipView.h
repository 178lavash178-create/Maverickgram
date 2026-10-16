#import <Cocoa/Cocoa.h>

@class TGScrollSurfaceView;
// Aqua's wallpaper owns the complete viewport. A legacy reserved scrollbar
// gutter and a rounded plate underneath it expose unrelated white corners.
void TGAquaConfigureTranscriptViewport(NSScrollView *scrollView, TGScrollSurfaceView *surfaceView);

// Paint on the viewport, not the scrolling document: wallpaper stays stationary
// and also covers the unused space in short/empty conversations.
@interface TGAquaChatBackgroundClipView : NSClipView {
    NSNumber *_backgroundAccountID;
    NSNumber *_backgroundChatID;
}
- (void)setBackgroundAccountID:(NSNumber *)accountID chatID:(NSNumber *)chatID;
@end
