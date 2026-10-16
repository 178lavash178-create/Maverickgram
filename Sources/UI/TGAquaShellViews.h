#import <Cocoa/Cocoa.h>
#import "TGStatusButtonCells.h"

typedef struct {
    NSRect folders;
    NSRect divider;
    NSRect chatHeader;
    NSRect chats;
} TGAquaSourceListGeometry;
// folderCount is the actual 32pt rows, including the built-in folder entries.
// The footer belongs only to the conversation composer; other pages use the full height.
// Only a visible multiline composer may enlarge the base height.
CGFloat TGAquaFooterBaseHeight(void);
CGFloat TGAquaFooterHeight(BOOL composerVisible, NSRect composerInputFrame);
CGFloat TGAquaFooterControlY(BOOL composerVisible, NSRect attachFrame);

typedef struct {
    NSRect back;
    NSRect title;
    NSRect compose;
    NSRect search;
    NSRect refresh;
} TGAquaChatHeaderGeometry;
TGAquaChatHeaderGeometry TGAquaChatHeaderFrames(NSRect header, BOOL forum);
typedef struct {
    CGFloat buttonY;
    CGFloat avatarY;
    CGFloat titleY;
    CGFloat subtitleY;
} TGAquaConversationHeaderVerticalGeometry;
TGAquaConversationHeaderVerticalGeometry TGAquaConversationHeaderVerticalFrames(NSRect header, BOOL subtitle);
NSRect TGAquaToolbarSectionFrame(CGFloat windowWidth, CGFloat windowHeight, NSUInteger index);

TGAquaSourceListGeometry TGAquaSourceListFrames(NSRect sidebar, CGFloat footerTop, CGFloat preferredFolderHeight, NSUInteger folderCount, BOOL collapsed);

@interface TGAquaMetalView : NSView {
    CGFloat _dividerX;
}
@property(nonatomic, assign) CGFloat dividerX;
@end
@interface TGAquaUtilityButtonCell : TGNavigationButtonCell {
    NSString *_iconAssetName;
}
@property(nonatomic, copy) NSString *iconAssetName;
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

// Compact chrome keeps full-size hit targets and returns space to the transcript.
CGFloat TGAquaToolbarHeight(void);
typedef struct { NSRect query, close, scope, filter, advanced, status, results, navigation; CGFloat height; } TGAquaSearchGeometry;
TGAquaSearchGeometry TGAquaSearchFrames(NSRect available, BOOL hidesScope, BOOL hasResults);
