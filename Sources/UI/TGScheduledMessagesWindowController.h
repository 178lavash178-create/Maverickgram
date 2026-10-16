#import <Cocoa/Cocoa.h>

@class TGTDLibClient;

@interface TGScheduledMessagesWindowController : NSWindowController

- (id)initWithClient:(TGTDLibClient *)client
              chatID:(NSNumber *)chatID
               title:(NSString *)title;
- (void)reloadMessages;
- (NSView *)embeddedShelfView;
- (CGFloat)preferredEmbeddedShelfHeight;
- (void)setEmbeddedParentWindow:(NSWindow *)window;
- (void)setShelfCloseTarget:(id)target action:(SEL)action;
- (void)invalidateEmbeddedShelf;
- (void)presentEmbeddedShelfAnimated:(BOOL)animated;
- (void)hideEmbeddedShelfImmediately;
- (BOOL)matchesClient:(TGTDLibClient *)client chatID:(NSNumber *)chatID;

@end
