#import <Cocoa/Cocoa.h>

@protocol TGDownloadCompactPopoverTarget <NSObject>
- (void)compactDownloadPerformAction:(NSString *)action identifier:(NSString *)identifier;
- (void)compactDownloadShowAll;
@end

/* One transient native popover. It does not own the manager or start downloads. */
@interface TGDownloadCompactPopover : NSObject <NSPopoverDelegate> {
    id<TGDownloadCompactPopoverTarget> _target;
    NSPopover *_popover;
    NSViewController *_contentController;
    NSArray *_items;
    NSView *_anchor;
}
- (id)initWithTarget:(id<TGDownloadCompactPopoverTarget>)target;
- (BOOL)toggleRelativeToView:(NSView *)anchor;
- (void)reloadWithItems:(NSArray *)items;
- (void)close;
@end
