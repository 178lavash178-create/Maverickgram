#import <Cocoa/Cocoa.h>

// Paint on the viewport, not the scrolling document: wallpaper stays stationary
// and also covers the unused space in short/empty conversations.
@interface TGAquaChatBackgroundClipView : NSClipView {
    NSNumber *_backgroundAccountID;
    NSNumber *_backgroundChatID;
}
- (void)setBackgroundAccountID:(NSNumber *)accountID chatID:(NSNumber *)chatID;
@end
