#import <Cocoa/Cocoa.h>

typedef struct {
    NSRect conversation;
    NSRect panel;
    BOOL replacesConversation;
} TGAquaChatInfoGeometry;

TGAquaChatInfoGeometry TGAquaChatInfoFrames(NSRect conversation, BOOL visible);

/* A read-only conversation profile. Network ownership stays with the host. */
@interface TGAquaChatInfoPanel : NSView <NSAnimationDelegate> {
    NSView *_sheetView;
    NSScrollView *_scrollView;
    NSView *_documentView;
    NSView *_avatarView;
    NSTextField *_headingField;
    NSTextField *_nameField;
    NSTextField *_subtitleField;
    NSTextField *_detailsField;
    NSButton *_closeButton;
    NSArray *_actionButtons;
    NSDictionary *_summary;
    NSViewAnimation *_animation;
    NSRect _settledFrame;
    BOOL _closing;
    id _target;
}
@property(nonatomic, assign) id target;
@property(nonatomic, readonly, getter=isClosing) BOOL closing;
- (void)showSummary:(NSDictionary *)summary loading:(BOOL)loading error:(NSString *)errorMessage;
- (void)presentInFrame:(NSRect)frame animated:(BOOL)animated;
- (void)closeAnimated:(BOOL)animated;
- (void)hideImmediately;
@end
