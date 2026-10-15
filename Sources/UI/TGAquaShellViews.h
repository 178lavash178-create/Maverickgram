#import <Cocoa/Cocoa.h>
#import "TGStatusButtonCells.h"

typedef struct {
    NSRect folders;
    NSRect divider;
    NSRect chatHeader;
    NSRect chats;
} TGAquaSourceListGeometry;
// folderCount is the actual 32pt rows, including the built-in folder entries.
// The footer follows the live composer only when that composer is visible.
CGFloat TGAquaFooterHeight(BOOL composerVisible, NSRect composerInputFrame);
CGFloat TGAquaFooterControlY(BOOL composerVisible, NSRect attachFrame);

TGAquaSourceListGeometry TGAquaSourceListFrames(NSRect sidebar, CGFloat footerTop, CGFloat preferredFolderHeight, NSUInteger folderCount, BOOL collapsed);

@interface TGAquaMetalView : NSView {
    CGFloat _dividerX;
}
@property(nonatomic, assign) CGFloat dividerX;
@end
@interface TGAquaUtilityButtonCell : TGNavigationButtonCell
@end
@interface TGAquaTextButtonCell : TGNavigationButtonCell {
    BOOL _accented;
}
@property(nonatomic, assign) BOOL accented;
@end
@interface TGAquaSectionButtonCell : NSButtonCell
@end
@interface TGAquaFolderButtonCell : TGNavigationButtonCell
@end
@interface TGAquaFolderDivider : NSView {
    id _target;
    SEL _action;
    CGFloat _dragDelta;
    CGFloat _initialY;
}
@property(nonatomic, assign) id target;
@property(nonatomic, assign) SEL action;
@property(nonatomic, readonly) CGFloat dragDelta;
@end
