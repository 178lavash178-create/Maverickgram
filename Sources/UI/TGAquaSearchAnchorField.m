#import "TGAquaSearchAnchorField.h"
@implementation TGAquaSearchAnchorField
- (void)activateAttachedSearch:(id)sender {
    (void)sender;
    if ([self isEnabled] && [[self window] isVisible] && ![self isHiddenOrHasHiddenAncestor])
        [NSApp sendAction:[self action] to:[self target] from:self];
}
- (void)mouseDown:(NSEvent *)event { (void)event;[self activateAttachedSearch:self]; }
/* AppKit restores focus here when the transient popover closes. Do not
 * interpret that restoration as a request to reopen it. Keyboard activation
 * keeps the native search-field action (Return) and the existing Cmd-K route. */
@end
