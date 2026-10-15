#import <Cocoa/Cocoa.h>

extern NSString * const TGAquaFolderPresentationDefaultsKey;
extern NSString * const TGAquaFolderPresentationDidChangeNotification;

// Aqua-only preference; callers keep the Classic folder presentation unchanged.
// The experimental Aqua layout starts with an attached drawer by default.
BOOL TGAquaFoldersUseDrawer(void);
// Change on the main thread. A real change posts the notification immediately.
void TGAquaSetFoldersUseDrawer(BOOL useDrawer);

// One settings row: localized label and a native popup. The owner controls its
// visibility (Aqua Settings only); changes apply without restarting the app.
@interface TGAquaFolderPresentationSettingsView : NSView {
    NSTextField *_label;
    NSPopUpButton *_popUpButton;
}
+ (CGFloat)minimumWidth; // 326pt: 88pt label + 8pt gap + 230pt popup.
- (void)refreshAppearance;
@end
