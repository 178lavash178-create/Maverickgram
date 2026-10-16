#import "TGKeyboardInputSupport.h"

@implementation TGEscapeCloseWindow

- (void)cancelOperation:(id)sender {
    /* A window delegate may clear its final owner while handling windowWillClose:. */
    [self retain];
    [self performClose:sender];
    [self release];
}

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    NSUInteger shortcutModifiers = NSCommandKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSShiftKeyMask;
    if ([event type] == NSKeyDown &&
        [[event charactersIgnoringModifiers] isEqualToString:@"\033"] &&
        ([event modifierFlags] & shortcutModifiers) == 0) {
        [self cancelOperation:self];
        return YES;
    }
    return [super performKeyEquivalent:event];
}

@end

@implementation TGInlineSearchResultsTableView
- (void)keyDown:(NSEvent *)event {
    NSUInteger modifiers=[event modifierFlags] & (NSCommandKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSShiftKeyMask);
    NSString *characters=[event charactersIgnoringModifiers];
    unichar key=[characters length]==1 ? [characters characterAtIndex:0] : 0;
    SEL action=NULL;
    if(modifiers==0 && (key=='\r' || key=='\n' || key==3)) action=@selector(activateSearchResult:);
    else if(modifiers==0 && key==27) action=@selector(closeSearchPanel:);
    if(action && [[self target] respondsToSelector:action]) {
        if(action==@selector(activateSearchResult:) && [self selectedRow]<0 && [self numberOfRows]>0) {
            [self selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
            [self scrollRowToVisible:0];
        }
        [self retain];[[self target] performSelector:action withObject:self];[self release];return;
    }
    if((modifiers==0 || modifiers==NSShiftKeyMask) && (key=='\t' || key==NSBackTabCharacter) && [self nextKeyView]) {
        [[self window] makeFirstResponder:[self nextKeyView]];return;
    }
    [super keyDown:event];
}
@end

TGComposerKeyboardCommand TGComposerCommandForSelector(SEL selector, NSUInteger modifierFlags) {
    if (selector == @selector(insertLineBreak:) ||
        selector == @selector(insertNewlineIgnoringFieldEditor:)) {
        return TGComposerKeyboardCommandLineBreak;
    }
    if (selector == @selector(insertNewline:)) {
        return ((modifierFlags & NSShiftKeyMask) != 0)
            ? TGComposerKeyboardCommandLineBreak
            : TGComposerKeyboardCommandSend;
    }
    return TGComposerKeyboardCommandUnhandled;
}

BOOL TGComposerInsertLineBreak(NSTextView *fieldEditor) {
    if (!fieldEditor || ![fieldEditor isEditable] || [fieldEditor hasMarkedText]) {
        return NO;
    }
    /* insertNewline: ends editing in an NSTextField's shared field editor.
       Text insertion bypasses that command routing, preserving the selection,
       normal change notifications, undo, and the active editing session. */
    [fieldEditor insertText:@"\n" replacementRange:[fieldEditor selectedRange]];
    return YES;
}
