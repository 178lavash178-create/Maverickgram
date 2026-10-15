#import <Cocoa/Cocoa.h>
#import "TGChatUnreadBadgeAppearance.h"
#import "TGTheme.h"
#include <math.h>

static double luminance(NSColor *color) {
    NSColor *rgb = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    double channels[] = {[rgb redComponent], [rgb greenComponent], [rgb blueComponent]};
    NSUInteger i;
    for (i = 0; i < 3; i++) {
        channels[i] = channels[i] <= 0.04045 ? channels[i] / 12.92 : pow((channels[i] + 0.055) / 1.055, 2.4);
    }
    return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
}

int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    double minimum = 21.0;
    for (NSString *theme in TGThemeIdentifiers()) {
        TGSetActiveThemeIdentifier(theme);
        NSUInteger selected, muted;
        for (selected = 0; selected < 2; selected++) {
            for (muted = 0; muted < 2; muted++) {
                NSColor *fill = TGChatUnreadBadgeFillColor(selected != 0, muted != 0);
                NSColor *text = TGChatUnreadBadgeTextColor(selected != 0, muted != 0);
                double a = luminance(fill), b = luminance(text);
                double ratio = (MAX(a, b) + 0.05) / (MIN(a, b) + 0.05);
                minimum = MIN(minimum, ratio);
                if (ratio < 4.5) {
                    fprintf(stderr, "Unread badge contrast failed for %s selected=%lu muted=%lu: %.2f\n",
                            [theme UTF8String], (unsigned long)selected, (unsigned long)muted, ratio);
                    return 1;
                }
                if (muted) {
                    NSColor *rgb = [fill colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
                    if (fabs([rgb redComponent] - [rgb greenComponent]) > 0.001 ||
                        fabs([rgb greenComponent] - [rgb blueComponent]) > 0.001) { return 2; }
                }
            }
        }
    }
    printf("Unread badge probe passed: %lu themes, selected/unselected and muted/unmuted; minimum %.2f:1.\n",
           (unsigned long)[TGThemeIdentifiers() count], minimum);
    [pool drain];
    return 0;
}
