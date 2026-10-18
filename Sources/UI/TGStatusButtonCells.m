#import "TGStatusButtonCells.h"
#import "TGIconAssets.h"
#import "TGIconDrawing.h"
#import "TGTheme.h"
#import "TGButtonAppearance.h"
#import "TGInterfaceDesign.h"
#import "TGThemeContrast.h"
#include <math.h>

static CGFloat TGButtonPressedOffset(BOOL highlighted, BOOL flipped) {
    if (!highlighted) {
        return 0.0;
    }
    return flipped ? 1.0 : -1.0;
}

static NSRect TGButtonContentRectWithPressedOffset(NSRect rect,
                                                   BOOL highlighted,
                                                   BOOL flipped) {
    return NSOffsetRect(rect, 0.0, TGButtonPressedOffset(highlighted, flipped));
}

static void TGDrawCenteredTextButtonTitle(NSButtonCell *cell,
                                          NSRect cellFrame,
                                          NSView *controlView,
                                          NSFont *font,
                                          NSColor *textColor,
                                          CGFloat horizontalPadding) {
    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setAlignment:NSCenterTextAlignment];
    [paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                font, NSFontAttributeName,
                                textColor, NSForegroundColorAttributeName,
                                paragraph, NSParagraphStyleAttributeName,
                                nil];
    NSString *title = [cell title] ? [cell title] : @"";
    NSSize titleSize = [title sizeWithAttributes:attributes];
    NSRect titleRect = NSMakeRect(NSMinX(cellFrame) + horizontalPadding,
                                  floor(NSMidY(cellFrame) - (titleSize.height / 2.0)) - 1.0 +
                                      TGButtonPressedOffset([cell isHighlighted], [controlView isFlipped]),
                                  MAX(0.0, NSWidth(cellFrame) - (horizontalPadding * 2.0)),
                                  titleSize.height + 2.0);
    [title drawInRect:titleRect withAttributes:attributes];
}

void TGDrawMutedSpeakerIconInRect(NSRect iconRect, NSColor *color, BOOL flipped) {
    TGDrawTemplateIconAsset(@"sound-off", iconRect, color, 1.0, flipped);
}

static void TGDrawNavigationIcon(NSString *title, NSRect iconRect, NSColor *color, BOOL flipped) {
    [color set];
    if ([title isEqualToString:@"Contacts"] || [title isEqualToString:@"Контакты"] || [title isEqualToString:@"Кантакты"]) {
        TGDrawTemplateIconAsset(@"contacts", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"Calls"] || [title isEqualToString:@"Звонки"] || [title isEqualToString:@"Званкі"]) {
        TGDrawTemplateIconAsset(@"call-receive", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"Chats"] || [title isEqualToString:@"Чаты"]) {
        TGDrawTemplateIconAsset(@"chat", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"Profile"] || [title isEqualToString:@"Профиль"] || [title isEqualToString:@"Профіль"]) {
        TGDrawTemplateIconAsset(@"user", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"Settings"] || [title isEqualToString:@"Настройки"] || [title isEqualToString:@"Налады"]) {
        TGDrawTemplateIconAsset(@"settings", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"All"] || [title isEqualToString:@"All chats"] || [title isEqualToString:@"Все чаты"] || [title isEqualToString:@"Усе чаты"]) {
        TGDrawTemplateIconAsset(@"folder-share", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"Archive"] || [title isEqualToString:@"Архив"] || [title isEqualToString:@"Архіў"]) {
        TGDrawTemplateIconAsset(@"archive", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"Workshop"] || [title isEqualToString:@"Мастерская"] || [title isEqualToString:@"Майстэрня"]) {
        TGDrawTemplateIconAsset(@"workshop", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"Private"] || [title isEqualToString:@"Groups"]) {
        TGDrawTemplateIconAsset(@"folder", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"Logs"]) {
        TGDrawTemplateIconAsset(@"document", iconRect, color, 1.0, flipped);
    } else if ([title isEqualToString:@"About"]) {
        TGDrawTemplateIconAsset(@"info", iconRect, color, 1.0, flipped);
    } else {
        TGDrawTemplateIconAsset(@"folder", iconRect, color, 1.0, flipped);
    }
}

@implementation TGNavigationButtonCell

@synthesize badgeText = _badgeText;
@synthesize iconOnly = _iconOnly;

- (id)copyWithZone:(NSZone *)zone {
    TGNavigationButtonCell *cell = [super copyWithZone:zone];
    [cell setBadgeText:self.badgeText];
    [cell setIconOnly:self.iconOnly];
    return cell;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL selected = ([self state] == NSOnState);
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:6.0 yRadius:6.0];

    TGDrawReadableButtonSurface(path, buttonRect, TGButtonSurfaceEnamel, highlighted, selected, enabled, [controlView isFlipped]);

    NSColor *strokeColor = selected ? TGClassicNavigationSelectedStrokeColor(0.95) : TGClassicNavigationNormalStrokeColor(0.75);
    [strokeColor set];
    [path setLineWidth:1.0];
    [path stroke];

    NSString *title = [self title] ? [self title] : @"";
    NSColor *textColor = TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, selected, enabled);
    BOOL flipped = [controlView isFlipped];
    CGFloat iconSize = 18.0;
    NSRect iconRect = NSMakeRect(floor(NSMidX(cellFrame) - (iconSize / 2.0)),
                                 self.iconOnly ? floor(NSMidY(cellFrame) - (iconSize / 2.0)) :
                                     (flipped ? (NSMinY(cellFrame) + 6.0) : (NSMaxY(cellFrame) - 24.0)),
                                 iconSize,
                                 iconSize);
    TGDrawNavigationIcon(title, iconRect, textColor, flipped);
    if (!self.iconOnly) {
        NSFont *font = selected ? [NSFont boldSystemFontOfSize:11.0] : [NSFont systemFontOfSize:11.0];
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    font, NSFontAttributeName,
                                    textColor, NSForegroundColorAttributeName,
                                    nil];
        NSSize titleSize = [title sizeWithAttributes:attributes];
        CGFloat titleY = flipped ? (NSMaxY(cellFrame) - titleSize.height - 7.0) : (NSMinY(cellFrame) + 7.0);
        NSRect titleRect = NSMakeRect(NSMinX(cellFrame) + floor((NSWidth(cellFrame) - titleSize.width) / 2.0),
                                     titleY,
                                     titleSize.width,
                                     titleSize.height);
        [title drawInRect:titleRect withAttributes:attributes];
    }

    if ([self.badgeText length] > 0) {
        NSFont *badgeFont = [NSFont boldSystemFontOfSize:8.5];
        NSDictionary *badgeAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         badgeFont, NSFontAttributeName,
                                         [NSColor whiteColor], NSForegroundColorAttributeName,
                                         nil];
        NSSize badgeTextSize = [self.badgeText sizeWithAttributes:badgeAttributes];
        CGFloat badgeHeight = 15.0;
        CGFloat badgeWidth = ceil(badgeTextSize.width) + 8.0;
        if (badgeWidth < badgeHeight) {
            badgeWidth = badgeHeight;
        }
        NSRect badgeRect = NSMakeRect(NSMaxX(cellFrame) - badgeWidth - 4.0,
                                     flipped ? (NSMinY(cellFrame) + 3.0) : (NSMaxY(cellFrame) - badgeHeight - 3.0),
                                     badgeWidth,
                                     badgeHeight);
        NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeRect
                                                                  xRadius:(badgeHeight / 2.0)
                                                                  yRadius:(badgeHeight / 2.0)];
        [[NSColor colorWithCalibratedRed:0.820 green:0.180 blue:0.170 alpha:1.0] set];
        [badgePath fill];
        NSRect badgeTextRect = NSMakeRect(NSMinX(badgeRect) + floor((badgeWidth - badgeTextSize.width) / 2.0),
                                         NSMinY(badgeRect) + floor((badgeHeight - badgeTextSize.height) / 2.0) - 0.5,
                                         badgeTextSize.width,
                                         badgeTextSize.height);
        [self.badgeText drawInRect:badgeTextRect withAttributes:badgeAttributes];
    }
}

- (void)dealloc {
    [_badgeText release];
    [super dealloc];
}

@end

@implementation TGDrawerButtonCell

@synthesize backStyle = _backStyle;

- (id)copyWithZone:(NSZone *)zone {
    TGDrawerButtonCell *cell = [super copyWithZone:zone];
    [cell setBackStyle:self.backStyle];
    return cell;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    (void)controlView;
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:6.0 yRadius:6.0];
    TGDrawReadableButtonSurface(path, buttonRect, TGButtonSurfaceEnamel, highlighted, NO, enabled, [controlView isFlipped]);
    [TGClassicNavigationNormalStrokeColor(0.75) set];
    [path setLineWidth:1.0];
    [path stroke];

    NSColor *lineColor = TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, NO, enabled);
    BOOL flipped = [controlView isFlipped];
    NSRect iconRect = NSMakeRect(floor(NSMidX(cellFrame) - 9.0),
                                 floor(NSMidY(cellFrame) - 9.0), 18.0, 18.0);
    TGDrawTemplateIconAsset(self.backStyle ? @"Phosphor/back" : @"Phosphor/list",
                            iconRect, lineColor, 1.0, flipped);
}

@end

@implementation TGSendButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    (void)controlView;
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *buttonPath = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:7.0 yRadius:7.0];
    TGDrawReadableButtonSurface(buttonPath, buttonRect, TGButtonSurfaceEnamel, highlighted, YES, enabled, [controlView isFlipped]);
    [TGClassicPanelStrokeColor() set];
    [buttonPath setLineWidth:1.0];
    [buttonPath stroke];

    NSRect sendRect = TGButtonContentRectWithPressedOffset(NSMakeRect(NSMidX(buttonRect) - 9.0,
                                                                      NSMidY(buttonRect) - 9.0,
                                                                      18.0,
                                                                      18.0),
                                                             highlighted,
                                                             [controlView isFlipped]);
    TGDrawTemplateIconAsset(@"send", sendRect, TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, YES, enabled), 1.0, [controlView isFlipped]);
}

@end

@implementation TGAttachButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    (void)controlView;
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *buttonPath = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:7.0 yRadius:7.0];
    TGDrawReadableButtonSurface(buttonPath, buttonRect, TGButtonSurfaceEnamel, highlighted, YES, enabled, [controlView isFlipped]);
    [TGClassicPanelStrokeColor() set];
    [buttonPath setLineWidth:1.0];
    [buttonPath stroke];

    NSRect iconRect = TGButtonContentRectWithPressedOffset(NSMakeRect(NSMidX(buttonRect) - 10.5,
                                                                      NSMidY(buttonRect) - 10.5,
                                                                      21.0,
                                                                      21.0),
                                                             highlighted,
                                                             [controlView isFlipped]);
    TGDrawTemplateIconAsset(@"attach", iconRect, TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, YES, enabled), 1.0, [controlView isFlipped]);
}

@end

@implementation TGComposerSymbolButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *buttonPath = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:7.0 yRadius:7.0];
    TGDrawReadableButtonSurface(buttonPath, buttonRect, TGButtonSurfaceEnamel, highlighted, YES, enabled, [controlView isFlipped]);
    [TGClassicPanelStrokeColor() set];
    [buttonPath setLineWidth:1.0];
    [buttonPath stroke];

    NSString *title = [self title] ? [self title] : @"";
    BOOL flipped = [controlView isFlipped];
    NSColor *iconColor = TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, YES, enabled);
    [iconColor set];
    if ([title isEqualToString:@"mic"]) {
        NSRect micRect = TGButtonContentRectWithPressedOffset(NSMakeRect(NSMidX(buttonRect) - 11.0,
                                                                         NSMidY(buttonRect) - 11.0,
                                                                         22.0,
                                                                         22.0),
                                                                highlighted,
                                                                flipped);
        TGDrawTemplateIconAsset(@"microphone", micRect, iconColor, 1.0, flipped);
        return;
    }
    if ([title isEqualToString:@"video"] || [title isEqualToString:@"video-off"]) {
        NSRect videoRect = TGButtonContentRectWithPressedOffset(NSMakeRect(NSMidX(buttonRect) - 11.0,
                                                                           NSMidY(buttonRect) - 11.0,
                                                                           22.0,
                                                                           22.0),
                                                                  highlighted,
                                                                  flipped);
        TGDrawTemplateIconAsset(title, videoRect, iconColor, 1.0, flipped);
        return;
    }
    if ([title isEqualToString:@"☺"] || [title isEqualToString:@"stickers"]) {
        NSRect smileRect = TGButtonContentRectWithPressedOffset(NSMakeRect(NSMidX(buttonRect) - 12.0,
                                                                           NSMidY(buttonRect) - 12.0,
                                                                           24.0,
                                                                           24.0),
                                                                  highlighted,
                                                                  flipped);
        TGDrawTemplateIconAsset(@"emoji-smile", smileRect, iconColor, 1.0, flipped);
        return;
    }

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont boldSystemFontOfSize:18.0], NSFontAttributeName,
                                iconColor, NSForegroundColorAttributeName,
                                nil];
    NSString *symbol = ([title length] > 0) ? title : @"☺";
    NSSize size = [symbol sizeWithAttributes:attributes];
    NSRect symbolRect = TGButtonContentRectWithPressedOffset(NSMakeRect(NSMidX(buttonRect) - floor(size.width / 2.0),
                                                                        NSMidY(buttonRect) - floor(size.height / 2.0) - 1.0,
                                                                        size.width + 2.0,
                                                                        size.height + 2.0),
                                                               highlighted,
                                                               flipped);
    [symbol drawInRect:symbolRect withAttributes:attributes];
}

@end

@implementation TGHeaderIconButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    (void)controlView;
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    // Header controls perform momentary actions. A blue idle surface made them
    // indistinguishable from the persistent selection in the source list.
    BOOL aqua = TGInterfaceDesignIsAqua();
    TGButtonSurfaceStyle surface = aqua ? TGButtonSurfaceSecondary : TGButtonSurfaceEnamel;
    BOOL selected = !aqua;
    NSColor *ink = TGButtonForegroundColor(surface, highlighted, selected, enabled);
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *buttonPath = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:5.0 yRadius:5.0];
    TGDrawReadableButtonSurface(buttonPath, buttonRect, surface, highlighted, selected, enabled, [controlView isFlipped]);
    [TGClassicTableGridColor() set];
    [buttonPath setLineWidth:1.0];
    [buttonPath stroke];

    NSString *title = [self title] ? [self title] : @"";
    NSString *assetName = nil;
    if ([title isEqualToString:@"↻"]) {
        assetName = @"refresh";
    } else if ([title isEqualToString:@"+"]) {
        assetName = @"plus";
    } else if ([title isEqualToString:@"↑"]) {
        assetName = @"upload";
    } else if ([title isEqualToString:@"search"]) {
        assetName = @"search";
    } else if ([title isEqualToString:@"jump-newest"]) {
        assetName = @"arrow-down";
    } else if ([title isEqualToString:@"zoom-in"]) {
        assetName = @"add-ellipse";
    } else if ([title isEqualToString:@"zoom-out"]) {
        assetName = @"remove-ellipse";
    } else if ([title isEqualToString:@"media"] || [title isEqualToString:@"media-center"]) {
        assetName = @"image";
    } else if ([title hasPrefix:@"Phosphor/"]) {
        assetName = title;
    } else if (aqua && [title isEqualToString:@"‹"]) {
        assetName = @"Phosphor/back";
    }
    if ([assetName length] > 0) {
        CGFloat side = aqua ? 20.0 : 18.0;
        NSRect iconRect = NSMakeRect(floor(NSMidX(buttonRect) - side / 2.0),
                                     floor(NSMidY(buttonRect) - side / 2.0), side, side);
        TGDrawTemplateIconAsset(assetName, iconRect, ink, 1.0, [controlView isFlipped]);
        return;
    }
    if ([controlView isKindOfClass:[NSButton class]]) {
        NSImage *image = [(NSButton *)controlView image];
        if (image) {
            NSSize imageSize = [image size];
            if (imageSize.width <= 0.0 || imageSize.height <= 0.0) {
                imageSize = NSMakeSize(18.0, 18.0);
            }
            CGFloat side = aqua ? 20.0 : 18.0;
            NSRect iconRect = NSMakeRect(NSMidX(buttonRect) - (side / 2.0),
                                         NSMidY(buttonRect) - (side / 2.0),
                                         side,
                                         side);
            TGDrawButtonTemplateImage(image, iconRect, ink, [controlView isFlipped]);
            return;
        }
    }
    NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraph setAlignment:NSCenterTextAlignment];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont boldSystemFontOfSize:16.0], NSFontAttributeName,
                                ink, NSForegroundColorAttributeName,
                                paragraph, NSParagraphStyleAttributeName,
                                nil];
    NSSize titleSize = [title sizeWithAttributes:attributes];
    NSRect titleRect = NSMakeRect(NSMinX(buttonRect),
                                  NSMinY(buttonRect) + floor((NSHeight(buttonRect) - titleSize.height) / 2.0),
                                  NSWidth(buttonRect),
                                  titleSize.height + 2.0);
    [title drawInRect:titleRect withAttributes:attributes];
}

@end

@implementation TGPrimaryTextButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 0.5, 0.5);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:9.0 yRadius:9.0];
    TGDrawReadableButtonSurface(path,
                                 buttonRect,
                                 TGButtonSurfaceEnamel,
                                 highlighted,
                                 YES,
                                 enabled,
                                 [controlView isFlipped]);
    [TGClassicNavigationSelectedStrokeColor(enabled ? 1.0 : 0.40) set];
    [path setLineWidth:(enabled ? 1.25 : 1.0)];
    [path stroke];

    TGDrawCenteredTextButtonTitle(self,
                                  cellFrame,
                                  controlView,
                                  [NSFont boldSystemFontOfSize:13.0],
                                  TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, YES, enabled),
                                  12.0);
}

@end

@implementation TGSecondaryTextButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 0.5, 0.5);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:9.0 yRadius:9.0];
    TGDrawReadableButtonSurface(path, buttonRect, TGButtonSurfaceSecondary, highlighted, NO, enabled, [controlView isFlipped]);
    [(enabled ? TGClassicTableGridColor() : [TGClassicTableGridColor() colorWithAlphaComponent:0.48]) set];
    [path setLineWidth:1.0];
    [path stroke];

    NSColor *textColor = TGButtonForegroundColor(TGButtonSurfaceSecondary, highlighted, NO, enabled);
    TGDrawCenteredTextButtonTitle(self,
                                  cellFrame,
                                  controlView,
                                  [NSFont boldSystemFontOfSize:12.0],
                                  textColor,
                                  10.0);
}

@end

@implementation TGMediaZoomButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    BOOL flipped = [controlView isFlipped];
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *buttonPath = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:5.0 yRadius:5.0];
    TGDrawReadableButtonSurface(buttonPath, buttonRect, TGButtonSurfaceEnamel, highlighted, YES, enabled, [controlView isFlipped]);
    [TGClassicTableGridColor() set];
    [buttonPath setLineWidth:1.0];
    [buttonPath stroke];

    NSColor *iconColor = TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, YES, enabled);
    [iconColor set];
    CGFloat circleSide = 11.0;
    CGFloat visualYOffset = flipped ? -2.0 : 2.0;
    NSRect lensRect = NSMakeRect(NSMidX(buttonRect) - 7.0,
                                 NSMidY(buttonRect) - 4.0 + visualYOffset,
                                 circleSide,
                                 circleSide);
    NSBezierPath *lensPath = [NSBezierPath bezierPathWithOvalInRect:lensRect];
    [lensPath setLineWidth:1.5];
    [lensPath stroke];

    NSBezierPath *handlePath = [NSBezierPath bezierPath];
    [handlePath setLineWidth:1.8];
    CGFloat handleStartY = flipped ? (NSMaxY(lensRect) - 1.5) : (NSMinY(lensRect) + 1.5);
    CGFloat handleEndY = flipped ? (NSMaxY(lensRect) + 5.0) : (NSMinY(lensRect) - 5.0);
    [handlePath moveToPoint:NSMakePoint(NSMaxX(lensRect) - 1.5, handleStartY)];
    [handlePath lineToPoint:NSMakePoint(NSMaxX(lensRect) + 5.0, handleEndY)];
    [handlePath stroke];

    NSBezierPath *minusPath = [NSBezierPath bezierPath];
    [minusPath setLineWidth:1.5];
    [minusPath moveToPoint:NSMakePoint(NSMinX(lensRect) + 3.0, NSMidY(lensRect))];
    [minusPath lineToPoint:NSMakePoint(NSMaxX(lensRect) - 3.0, NSMidY(lensRect))];
    [minusPath stroke];

    if ([[self title] isEqualToString:@"zoom-in"]) {
        NSBezierPath *plusPath = [NSBezierPath bezierPath];
        [plusPath setLineWidth:1.5];
        [plusPath moveToPoint:NSMakePoint(NSMidX(lensRect), NSMinY(lensRect) + 3.0)];
        [plusPath lineToPoint:NSMakePoint(NSMidX(lensRect), NSMaxY(lensRect) - 3.0)];
        [plusPath stroke];
    }
}

@end

@implementation TGMediaPlaybackButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    (void)controlView;
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *buttonPath = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:6.0 yRadius:6.0];
    TGDrawReadableButtonSurface(buttonPath, buttonRect, TGButtonSurfaceEnamel, highlighted, YES, enabled, [controlView isFlipped]);
    [TGClassicTableGridColor() set];
    [buttonPath setLineWidth:1.0];
    [buttonPath stroke];

    NSColor *iconColor = TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, YES, enabled);
    [iconColor set];
    BOOL pauseIcon = [[[self title] lowercaseString] isEqualToString:@"pause"];
    NSRect iconRect = NSMakeRect(NSMidX(buttonRect) - 8.0,
                                 NSMidY(buttonRect) - 8.0,
                                 16.0,
                                 16.0);
    TGDrawTemplateIconAsset((pauseIcon ? @"pause" : @"play"), iconRect, iconColor, 1.0, [controlView isFlipped]);
}

@end

@implementation TGSettingsListButtonCell

- (NSColor *)accentColorForTitle:(NSString *)title alpha:(CGFloat)alpha {
    if ([title isEqualToString:@"Appearance"]) {
        return [NSColor colorWithCalibratedRed:0.180 green:0.600 blue:0.860 alpha:alpha];
    }
    if ([title isEqualToString:@"Diagnostic Logs"]) {
        return [NSColor colorWithCalibratedRed:0.520 green:0.540 blue:0.590 alpha:alpha];
    }
    return [NSColor colorWithCalibratedRed:0.950 green:0.520 blue:0.160 alpha:alpha];
}

- (NSString *)glyphForTitle:(NSString *)title {
    if ([title isEqualToString:@"Appearance"]) {
        return @"A";
    }
    if ([title isEqualToString:@"Diagnostic Logs"]) {
        return @"L";
    }
    return @"i";
}

- (NSString *)iconNameForTitle:(NSString *)title {
    if ([title isEqualToString:@"Appearance"]) {
        return @"image";
    }
    if ([title isEqualToString:@"Diagnostic Logs"]) {
        return @"document";
    }
    return @"info";
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    (void)controlView;
    BOOL highlighted = [self isHighlighted];
    BOOL enabled = [self isEnabled];
    NSRect rowRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *rowPath = [NSBezierPath bezierPathWithRoundedRect:rowRect xRadius:9.0 yRadius:9.0];
    TGDrawReadableButtonSurface(rowPath, rowRect, TGButtonSurfaceSettings, highlighted, NO, enabled, [controlView isFlipped]);
    [TGClassicPanelStrokeColor() set];
    [rowPath setLineWidth:1.0];
    [rowPath stroke];

    NSString *title = [self title] ? [self title] : @"";
    NSRect iconRect = NSMakeRect(NSMinX(rowRect) + 11.0, NSMidY(rowRect) - 12.0, 24.0, 24.0);
    NSBezierPath *iconPath = [NSBezierPath bezierPathWithRoundedRect:iconRect xRadius:5.0 yRadius:5.0];
    NSColor *accent = [self accentColorForTitle:title alpha:1.0];
    [accent set];
    [iconPath fill];

    NSRect rowIconRect = NSInsetRect(iconRect, 4.0, 4.0);
    TGDrawTemplateIconAsset([self iconNameForTitle:title],
                            rowIconRect,
                            TGThemeReadableInk([NSColor whiteColor], accent, enabled ? 4.5 : 3.0),
                            1.0,
                            [controlView isFlipped]);

    NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSFont systemFontOfSize:14.0], NSFontAttributeName,
                                     TGButtonForegroundColor(TGButtonSurfaceSettings, highlighted, NO, enabled), NSForegroundColorAttributeName,
                                     nil];
    NSRect titleRect = NSMakeRect(NSMinX(rowRect) + 48.0,
                                  NSMidY(rowRect) - 9.0,
                                  NSWidth(rowRect) - 82.0,
                                  18.0);
    [title drawInRect:titleRect withAttributes:titleAttributes];

    NSDictionary *chevronAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSFont systemFontOfSize:18.0], NSFontAttributeName,
                                       TGButtonForegroundColor(TGButtonSurfaceSettings, highlighted, NO, enabled), NSForegroundColorAttributeName,
                                       nil];
    [@">" drawAtPoint:NSMakePoint(NSMaxX(rowRect) - 24.0, NSMidY(rowRect) - 12.0)
       withAttributes:chevronAttributes];
}

@end

@implementation TGStickerPickerButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    (void)controlView;
    BOOL highlighted = [self isHighlighted];
    BOOL selected = ([self state] == NSOnState);
    BOOL enabled = [self isEnabled];
    CGFloat alpha = enabled ? 1.0 : 0.52;
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *buttonPath = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:5.0 yRadius:5.0];

    TGDrawReadableButtonSurface(buttonPath, buttonRect, TGButtonSurfaceSticker, highlighted, selected, enabled, [controlView isFlipped]);
    [TGClassicPanelStrokeColor() set];
    [buttonPath setLineWidth:1.0];
    [buttonPath stroke];

    NSRect contentRect = NSInsetRect(buttonRect, 5.0, 5.0);
    NSImage *image = [self image];
    if (image) {
        NSSize imageSize = [image size];
        if (imageSize.width > 0.0 && imageSize.height > 0.0 && !NSIsEmptyRect(contentRect)) {
            CGFloat scale = MIN(NSWidth(contentRect) / imageSize.width,
                                NSHeight(contentRect) / imageSize.height);
            if (scale > 1.0) {
                scale = 1.0;
            }
            NSSize drawSize = NSMakeSize(floor(imageSize.width * scale),
                                         floor(imageSize.height * scale));
            NSRect drawRect = NSMakeRect(NSMidX(contentRect) - floor(drawSize.width / 2.0),
                                         NSMidY(contentRect) - floor(drawSize.height / 2.0),
                                         drawSize.width,
                                         drawSize.height);
            NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:contentRect xRadius:4.0 yRadius:4.0];
            [NSGraphicsContext saveGraphicsState];
            [clipPath addClip];
            [image drawInRect:drawRect
                     fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height)
                    operation:NSCompositeSourceOver
                     fraction:alpha
               respectFlipped:YES
                        hints:nil];
            [NSGraphicsContext restoreGraphicsState];
        }
    } else {
        NSString *title = [self title];
        if ([title length] == 0) {
            title = @"?";
        }
        if ([title isEqualToString:@"☺"] || [title isEqualToString:@"stickers"]) {
            NSRect iconRect = NSMakeRect(NSMidX(contentRect) - 12.0,
                                         NSMidY(contentRect) - 12.0,
                                         24.0,
                                         24.0);
            TGDrawTemplateIconAsset(@"emoji-smile",
                                    iconRect,
                                    TGButtonForegroundColor(TGButtonSurfaceSticker, highlighted, selected, enabled),
                                    1.0,
                                    [controlView isFlipped]);
            return;
        }
        NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraph setAlignment:NSCenterTextAlignment];
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSFont systemFontOfSize:30.0], NSFontAttributeName,
                                    TGButtonForegroundColor(TGButtonSurfaceSticker, highlighted, selected, enabled), NSForegroundColorAttributeName,
                                    paragraph, NSParagraphStyleAttributeName,
                                    nil];
        NSSize titleSize = [title sizeWithAttributes:attributes];
        NSRect titleRect = NSMakeRect(NSMinX(contentRect),
                                      NSMidY(contentRect) - floor(titleSize.height / 2.0) - 1.0,
                                      NSWidth(contentRect),
                                      titleSize.height + 2.0);
        [title drawInRect:titleRect withAttributes:attributes];
    }
}

@end

@implementation TGStickerPickerTabButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL highlighted = [self isHighlighted];
    BOOL selected = ([self state] == NSOnState);
    BOOL enabled = [self isEnabled];
    NSRect buttonRect = NSInsetRect(cellFrame, 1.0, 1.0);
    NSBezierPath *buttonPath = [NSBezierPath bezierPathWithRoundedRect:buttonRect xRadius:7.0 yRadius:7.0];
    TGDrawReadableButtonSurface(buttonPath, buttonRect, TGButtonSurfaceEnamel, highlighted, selected, enabled, [controlView isFlipped]);
    [TGClassicNavigationNormalStrokeColor(0.78) set];
    [buttonPath setLineWidth:1.0];
    [buttonPath stroke];

    NSString *title = [self title] ? [self title] : @"";
    NSImage *image = [self image];
    BOOL imageOnly = ([title length] == 0);
    CGFloat iconSide = imageOnly ? 17.0 : 14.0;
    NSRect iconRect = NSMakeRect(NSMidX(buttonRect) - floor(iconSide / 2.0),
                                 NSMidY(buttonRect) - floor(iconSide / 2.0),
                                 iconSide,
                                 iconSide);
    if (!imageOnly) {
        iconRect.origin.x = NSMinX(buttonRect) + 8.0;
    }
    if (image) {
        TGDrawButtonTemplateImage(image, iconRect, TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, selected, enabled), [controlView isFlipped]);
    }

    if (!imageOnly) {
        NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraph setAlignment:NSCenterTextAlignment];
        [paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSFont boldSystemFontOfSize:11.0], NSFontAttributeName,
                                    TGButtonForegroundColor(TGButtonSurfaceEnamel, highlighted, selected, enabled), NSForegroundColorAttributeName,
                                    paragraph, NSParagraphStyleAttributeName,
                                    nil];
        CGFloat titleLeft = image ? (NSMaxX(iconRect) + 5.0) : (NSMinX(buttonRect) + 8.0);
        CGFloat titleRightInset = 8.0;
        NSRect titleRect = NSMakeRect(titleLeft,
                                      NSMidY(buttonRect) - 8.0,
                                      MAX(8.0, NSMaxX(buttonRect) - titleLeft - titleRightInset),
                                      17.0);
        [title drawInRect:titleRect withAttributes:attributes];
    }
}

@end
