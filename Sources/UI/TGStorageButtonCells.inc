// Storage controls share the same measured button materials as the main shell.
@interface TGStoragePrimaryButtonCell : NSButtonCell
@end

@implementation TGStoragePrimaryButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 0.5, 0.5);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:10.0 yRadius:10.0];
    TGDrawReadableButtonSurface(path, buttonRect, TGButtonSurfaceEnamel, highlighted, NO, enabled, [controlView isFlipped]);

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
                                TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, NO, enabled), NSForegroundColorAttributeName,
                                nil];
    NSString *title = [self title] ? [self title] : @"";
    NSSize size = [title sizeWithAttributes:attributes];
    NSRect titleRect = NSMakeRect(NSMidX(cellFrame) - (size.width / 2.0),
                                  NSMidY(cellFrame) - (size.height / 2.0) - 1.0,
                                  size.width,
                                  size.height);
    [title drawInRect:titleRect withAttributes:attributes];
}

@end

@interface TGStorageRefreshButtonCell : NSButtonCell
@end

@implementation TGStorageRefreshButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 0.5, 0.5);
    NSBezierPath *buttonPath = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:8.0 yRadius:8.0];
    TGDrawReadableButtonSurface(buttonPath, buttonRect, TGButtonSurfaceEnamel, highlighted, NO, enabled, [controlView isFlipped]);

    NSRect iconRect = NSMakeRect(NSMidX(buttonRect) - 9.0,
                                 NSMidY(buttonRect) - 9.0,
                                 18.0,
                                 18.0);
    TGDrawTemplateIconAsset(@"refresh",
                            iconRect,
                            TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, NO, enabled),
                            1.0,
                            [controlView isFlipped]);
}

@end

