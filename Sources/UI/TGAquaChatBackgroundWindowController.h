#import <Cocoa/Cocoa.h>

// Local Aqua wallpaper preferences. A valid account/chat pair enables the
// additional per-chat scope; otherwise the window edits the common wallpaper.
@interface TGAquaChatBackgroundWindowController : NSWindowController <NSWindowDelegate> {
    NSNumber *_accountID;
    NSNumber *_chatID;
    NSString *_chatTitle;
    NSMutableDictionary *_drafts;
    NSMutableSet *_changedScopes;
    NSMutableArray *_importedConfigurations;
    NSArray *_colorButtons;
    NSArray *_texturePresets;
    NSPopUpButton *_scopePopUp;
    NSPopUpButton *_texturePopUp;
    NSTextField *_scopeHint;
    NSTextField *_imageNameField;
    NSButton *_inheritButton;
    NSView *_previewView;
}
- (id)initWithAccountID:(NSNumber *)accountID chatID:(NSNumber *)chatID chatTitle:(NSString *)chatTitle;
@end
