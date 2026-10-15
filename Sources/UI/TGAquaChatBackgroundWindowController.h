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
    NSArray *_textureButtons;
    NSArray *_wallpaperButtons;
    NSMutableDictionary *_modeChoices;
    NSSegmentedControl *_modeControl;
    NSView *_colorPane;
    NSView *_texturePane;
    NSView *_imagePane;
    NSPopUpButton *_scopePopUp;
    NSTextField *_scopeHint;
    NSTextField *_imageNameField;
    NSButton *_inheritButton;
    NSView *_previewView;
}
- (id)initWithAccountID:(NSNumber *)accountID chatID:(NSNumber *)chatID chatTitle:(NSString *)chatTitle;
@end
