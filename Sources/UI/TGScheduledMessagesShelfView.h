#import <Cocoa/Cocoa.h>

@protocol TGScheduledMessagesShelfTarget <NSObject>
- (void)scheduledShelfPerformAction:(NSString *)action messageID:(NSNumber *)messageID;
- (void)scheduledShelfRequestClose;
@end

@interface TGScheduledMessagesShelfView : NSView {
    id<TGScheduledMessagesShelfTarget> _target;
    NSArray *_messages;
    NSString *_status;
    BOOL _loading;
    NSScrollView *_scroll;
}
@property(nonatomic,assign) id<TGScheduledMessagesShelfTarget> target;
- (void)updateWithMessages:(NSArray *)messages status:(NSString *)status loading:(BOOL)loading;
- (void)presentAnimated:(BOOL)animated;
- (void)hideImmediately;
@end
