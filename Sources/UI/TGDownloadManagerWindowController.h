#import <Cocoa/Cocoa.h>

@interface TGDownloadManagerWindowController : NSWindowController

- (void)reloadDownloads;
- (void)refreshPresentation;
- (BOOL)toggleCompactPopoverRelativeToView:(NSView *)anchor;
- (void)closeCompactPopover;

@end
