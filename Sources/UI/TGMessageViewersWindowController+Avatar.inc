// Reader rows reuse the same identity rendering as chats, including initials
// while an avatar is unavailable or its asynchronous thumbnail is still loading.
@interface TGMessageViewerAvatarView : NSImageView {
    NSString *_displayName;
}
@property (nonatomic, copy) NSString *displayName;
@end

@implementation TGMessageViewerAvatarView
@synthesize displayName=_displayName;
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    TGDrawAvatarImageInRect([self image],self.displayName,NSInsetRect([self bounds],0.5,0.5),NO,[self isFlipped]);
}
- (void)dealloc { [_displayName release];[super dealloc]; }
@end
