#import <Cocoa/Cocoa.h>

/* Image previews must close locally instead of passing Escape to chat navigation. */
@interface TGEscapeCloseWindow : NSWindow
@end

/* Inline results keep Return/Escape local when keyboard focus leaves the query. */
@interface TGInlineSearchResultsTableView : NSTableView
@end

typedef enum {
    TGComposerKeyboardCommandUnhandled = 0,
    TGComposerKeyboardCommandSend,
    TGComposerKeyboardCommandLineBreak
} TGComposerKeyboardCommand;

TGComposerKeyboardCommand TGComposerCommandForSelector(SEL selector, NSUInteger modifierFlags);
BOOL TGComposerInsertLineBreak(NSTextView *fieldEditor);
