// Kept with TGTheme's translation unit so every existing theme consumer shares
// the same contrast rules without adding a new linkage dependency.
#include <math.h>
#import "TGThemeContrast.h"

NSColor *TGThemeCompositeColor(NSColor *foreground, NSColor *background) {
    NSColor *fg = [foreground colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor *bg = [background colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if (!fg) { fg = [NSColor blackColor]; }
    if (!bg) { bg = [NSColor whiteColor]; }
    CGFloat a = [fg alphaComponent];
    return [NSColor colorWithCalibratedRed:[fg redComponent]*a+[bg redComponent]*(1-a)
        green:[fg greenComponent]*a+[bg greenComponent]*(1-a)
        blue:[fg blueComponent]*a+[bg blueComponent]*(1-a) alpha:1.0];
}

static CGFloat TGThemeContrastLuminance(NSColor *color) {
    NSColor *rgb = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat c[] = {[rgb redComponent], [rgb greenComponent], [rgb blueComponent]};
    NSUInteger i;
    for (i=0; i<3; i++) { c[i] = c[i] <= 0.04045 ? c[i]/12.92 : pow((c[i]+0.055)/1.055, 2.4); }
    return c[0]*0.2126+c[1]*0.7152+c[2]*0.0722;
}

CGFloat TGThemeContrastRatio(NSColor *ink, NSColor *surface) {
    CGFloat a = TGThemeContrastLuminance(TGThemeCompositeColor(ink, surface));
    CGFloat b = TGThemeContrastLuminance(surface);
    return (MAX(a,b)+0.05)/(MIN(a,b)+0.05);
}

static CGFloat TGThemeMinimumContrast(NSColor *ink, NSArray *surfaces) {
    CGFloat result = 21.0;
    for (NSColor *surface in surfaces) { result = MIN(result, TGThemeContrastRatio(ink, surface)); }
    return result;
}

NSColor *TGThemeReadableInkOnSurfaces(NSColor *preferred, NSArray *surfaces, CGFloat minimum) {
    if (![surfaces count]) { return preferred; }
    NSColor *rgb = [preferred colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if (!rgb) { rgb = [NSColor blackColor]; }
    rgb = [rgb colorWithAlphaComponent:1.0];
    CGFloat blackScore = TGThemeMinimumContrast([NSColor blackColor], surfaces);
    CGFloat whiteScore = TGThemeMinimumContrast([NSColor whiteColor], surfaces);
    CGFloat endpoint = blackScore >= whiteScore ? 0.0 : 1.0;
    NSUInteger step;
    for (step=0; step<=40; step++) {
        CGFloat mix = (CGFloat)step/40.0;
        NSColor *candidate = [NSColor colorWithCalibratedRed:[rgb redComponent]*(1-mix)+endpoint*mix
            green:[rgb greenComponent]*(1-mix)+endpoint*mix blue:[rgb blueComponent]*(1-mix)+endpoint*mix alpha:1.0];
        if (TGThemeMinimumContrast(candidate,surfaces) >= minimum || step==40) { return candidate; }
    }
    return rgb;
}

NSColor *TGThemeReadableInk(NSColor *preferred, NSColor *surface, CGFloat minimum) {
    return TGThemeReadableInkOnSurfaces(preferred, [NSArray arrayWithObject:surface], minimum);
}
