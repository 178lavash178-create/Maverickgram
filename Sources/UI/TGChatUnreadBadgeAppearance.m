#import "TGChatUnreadBadgeAppearance.h"
#import "TGTheme.h"
#include <math.h>

static CGFloat TGUnreadBadgeLuminance(NSColor *color) {
    NSColor *rgb = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat channels[] = {[rgb redComponent], [rgb greenComponent], [rgb blueComponent]};
    NSUInteger index;
    for (index = 0; index < 3; index++) {
        channels[index] = channels[index] <= 0.04045 ? channels[index] / 12.92 :
            pow((channels[index] + 0.055) / 1.055, 2.4);
    }
    return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
}

NSColor *TGChatUnreadBadgeFillColor(BOOL selected, BOOL muted) {
    if (muted) {
        NSColor *row = selected ? TGClassicSelectedRowColor() : TGClassicTablePaperColor();
        return [NSColor colorWithCalibratedWhite:(TGUnreadBadgeLuminance(row) > 0.179 ? 0.78 : 0.36)
                                          alpha:1.0];
    }
    return selected ? TGClassicSelectedRowTextColor() : TGClassicHeaderBottomColor();
}

NSColor *TGChatUnreadBadgeTextColor(BOOL selected, BOOL muted) {
    NSColor *preferred = selected ? TGClassicSelectedRowColor() : TGClassicNavigationTextColor(1.0);
    CGFloat fill = TGUnreadBadgeLuminance(TGChatUnreadBadgeFillColor(selected, muted));
    CGFloat ink = TGUnreadBadgeLuminance(preferred);
    if (!muted && (MAX(fill, ink) + 0.05) / (MIN(fill, ink) + 0.05) >= 4.5) {
        return preferred;
    }
    return fill > 0.179 ? [NSColor blackColor] : [NSColor whiteColor];
}
