#import <Cocoa/Cocoa.h>

extern NSString * const TGAquaFolderDrawerPlacementDidChangeNotification;

typedef struct {
    BOOL canShow;
    NSRectEdge edge;
    NSSize contentSize;
} TGAquaFolderDrawerGeometry;
// Includes native drawer trim and an eight-point screen-edge safety margin.
TGAquaFolderDrawerGeometry TGAquaFolderDrawerPlacement(NSRect parentFrame, NSRect visibleFrame,
    CGFloat parentContentHeight, NSUInteger folderCount, BOOL fullScreen);

// The same scroll view/buttons move between this host and the inline source list.
// Targets, tags, represented folder data and selection remain owned by the caller.
@interface TGAquaFolderDrawer : NSObject <NSDrawerDelegate> {
    NSWindow *_parentWindow;
    NSDrawer *_drawer;
    NSView *_contentView;
    NSScrollView *_folderScrollView;
    NSTextField *_titleField;
    NSButton *_editButton;
    NSArray *_folderButtons;
    BOOL _requestedVisible;
    BOOL _layoutInProgress;
    BOOL _hasPlacement;
    BOOL _lastCanShow;
}
@property(nonatomic, readonly) NSDrawer *drawer;
@property(nonatomic, readonly) NSView *contentView;
@property(nonatomic, readonly) NSScrollView *folderScrollView;
- (id)initWithParentWindow:(NSWindow *)parentWindow folderScrollView:(NSScrollView *)scrollView
    editTarget:(id)target editAction:(SEL)action;
- (void)setFolderButtons:(NSArray *)buttons;
- (void)refreshLocalization;
- (void)layout;
- (BOOL)canShowExternally;
- (void)setVisible:(BOOL)visible;
- (BOOL)isOpen;
- (void)attachFolderScrollView;
// Close and remove from this host; the caller then adds it back to its main view.
- (void)detachFolderScrollView;
@end
