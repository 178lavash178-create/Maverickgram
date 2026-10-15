#import <Cocoa/Cocoa.h>
#import "TGStatusButtonCells.h"

typedef struct {
    NSRect folders;
    NSRect divider;
    NSRect chatHeader;
    NSRect chats;
} TGAquaSourceListGeometry;
TGAquaSourceListGeometry TGAquaSourceListFrames(NSRect sidebar, CGFloat footerTop, CGFloat preferredFolderHeight, BOOL collapsed);

@interface TGAquaMetalView : NSView
@end
@interface TGAquaTextButtonCell : TGNavigationButtonCell {
    BOOL _accented;
}
@property(nonatomic, assign) BOOL accented;
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
