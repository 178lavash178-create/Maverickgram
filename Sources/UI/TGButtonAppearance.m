#import "TGButtonAppearance.h"
#import "TGTheme.h"
#include <math.h>

typedef struct { CGFloat red, green, blue; } TGButtonSample;

static CGFloat TGButtonRGBLuminance(CGFloat r, CGFloat g, CGFloat b) {
    CGFloat c[] = {r, g, b};
    NSUInteger i;
    for (i = 0; i < 3; i++) { c[i] = c[i] <= 0.04045 ? c[i] / 12.92 : pow((c[i] + 0.055) / 1.055, 2.4); }
    return c[0] * 0.2126 + c[1] * 0.7152 + c[2] * 0.0722;
}

static void TGDrawOriginalButtonSurface(NSBezierPath *path, NSRect rect, TGButtonSurfaceStyle style,
                                        BOOL highlighted, BOOL selected, BOOL enabled, BOOL flipped) {
    [TGClassicPanelBottomColor() set];
    [path fill];
    CGFloat alpha = enabled ? 1.0 : 0.46;
    if (style == TGButtonSurfaceEnamel || (style == TGButtonSurfaceSticker && TGThemeIsSkeuomorphicBlue())) {
        TGThemeDrawEnamelButtonInPath(path, rect, highlighted, selected, enabled, flipped);
    } else if (style == TGButtonSurfaceSecondary) {
        NSColor *color = highlighted ? TGClassicSelectedRowColor() : TGClassicTablePaperColor();
        [[color colorWithAlphaComponent:enabled ? 1.0 : 0.58] set];
        [path fill];
    } else if (style == TGButtonSurfaceSettings) {
        if (TGThemeIsSkeuomorphicBlue()) { TGThemeDrawRecessedBackgroundInPath(path, rect, flipped); }
        else { [(highlighted ? TGClassicTableHeaderColor() : TGClassicTablePaperColor()) set]; [path fill]; }
    } else {
        NSColor *top = (highlighted || selected) ? TGClassicNavigationHighlightedColor(alpha) : TGClassicTablePaperColor();
        NSColor *bottom = selected ? TGClassicNavigationSelectedColor(alpha) : (highlighted ? TGClassicNavigationNormalColor(alpha) : TGClassicPanelBottomColor());
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:top endingColor:bottom] autorelease];
        [gradient drawInBezierPath:path angle:90.0];
    }
}

static CGFloat TGButtonMinimumContrast(NSColor *ink, NSData *samples, CGFloat overlayWhite, CGFloat overlayAlpha) {
    NSColor *rgb = [ink colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat foreground = TGButtonRGBLuminance([rgb redComponent], [rgb greenComponent], [rgb blueComponent]), minimum = 21.0;
    const TGButtonSample *colors = [samples bytes];
    NSUInteger index, count = [samples length] / sizeof(TGButtonSample);
    for (index = 0; index < count; index++) {
        CGFloat background = TGButtonRGBLuminance(colors[index].red * (1.0 - overlayAlpha) + overlayWhite * overlayAlpha,
                                                  colors[index].green * (1.0 - overlayAlpha) + overlayWhite * overlayAlpha,
                                                  colors[index].blue * (1.0 - overlayAlpha) + overlayWhite * overlayAlpha);
        minimum = MIN(minimum, (MAX(foreground, background) + 0.05) / (MIN(foreground, background) + 0.05));
    }
    return minimum;
}

static NSArray *TGButtonAppearance(TGButtonSurfaceStyle style, BOOL highlighted, BOOL selected, BOOL enabled) {
    static NSCache *cache = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [[NSCache alloc] init]; [cache setCountLimit:256]; });
    NSString *key = [NSString stringWithFormat:@"%@|%lu|%d|%d|%d", TGCurrentThemeIdentifier(), (unsigned long)style, highlighted, selected, enabled];
    NSArray *appearance = [cache objectForKey:key];
    if (appearance) { return appearance; }

    // Measure the real material, including its pattern and disabled compositing,
    // once per theme/state. A single palette token cannot describe these gradients.
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:128 pixelsHigh:128
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    NSRect bounds = NSMakeRect(0.0, 0.0, 128.0, 128.0);
    TGDrawOriginalButtonSurface([NSBezierPath bezierPathWithRect:bounds], bounds, style, highlighted, selected, enabled, NO);
    [NSGraphicsContext restoreGraphicsState];
    NSMutableData *samples = [NSMutableData data];
    NSInteger x, y;
    const unsigned char *bytes = [bitmap bitmapData];
    NSInteger stride = [bitmap bytesPerRow];
    // Cover a complete 128-point texture tile, not only the button center.
    // Exclude the one-pixel bevel, on which no label or icon is placed.
    for (y = 3; y < 125; y += 2) {
        for (x = 3; x < 125; x += 2) {
            const unsigned char *pixel = bytes + y * stride + x * 4;
            TGButtonSample sample = {pixel[0] / 255.0, pixel[1] / 255.0, pixel[2] / 255.0};
            [samples appendBytes:&sample length:sizeof(sample)];
        }
    }
    CGFloat target = enabled ? 5.4 : 4.1; // Margin for texture phase, size and 8-bit raster rounding.
    NSColor *preferred = style == TGButtonSurfaceEnamel
        ? (selected ? TGClassicNavigationTextColor(1.0) : TGClassicNavigationMutedTextColor(1.0))
        : (highlighted ? TGClassicSelectedRowTextColor() : TGClassicCardInkColor());
    if (!enabled) { preferred = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0]; }
    NSColor *ink = preferred;
    NSColor *overlay = [NSColor clearColor];
    if (TGButtonMinimumContrast(ink, samples, 0.0, 0.0) < target) {
        NSColor *black = [NSColor blackColor], *white = [NSColor whiteColor];
        CGFloat blackContrast = TGButtonMinimumContrast(black, samples, 0.0, 0.0);
        CGFloat whiteContrast = TGButtonMinimumContrast(white, samples, 0.0, 0.0);
        ink = blackContrast >= whiteContrast ? black : white;
        if (MAX(blackContrast, whiteContrast) < target) {
            // A wide gradient can defeat either foreground. Preserve its hue and
            // texture, narrowing only the luminance range required for legibility.
            NSUInteger step;
            for (step = 1; step <= 20; step++) {
                CGFloat amount = (CGFloat)step / 20.0;
                if (TGButtonMinimumContrast(black, samples, 1.0, amount) >= target) {
                    ink = black; overlay = [white colorWithAlphaComponent:amount]; break;
                }
                if (TGButtonMinimumContrast(white, samples, 0.0, amount) >= target) {
                    ink = white; overlay = [black colorWithAlphaComponent:amount]; break;
                }
            }
        }
        if (!enabled) {
            // Disabled controls remain readable, but visibly quieter than enabled.
            CGFloat endpoint = [ink isEqual:black] ? 0.0 : 1.0;
            NSColor *rgb = [overlay colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            NSUInteger step;
            for (step = 0; step <= 20; step++) {
                NSColor *candidate = [NSColor colorWithCalibratedWhite:0.5 + (endpoint - 0.5) * step / 20.0 alpha:1.0];
                if (TGButtonMinimumContrast(candidate, samples, [rgb redComponent], [rgb alphaComponent]) >= target) { ink = candidate; break; }
            }
        }
    }
    appearance = [NSArray arrayWithObjects:ink, overlay, nil];
    [cache setObject:appearance forKey:key];
    return appearance;
}

NSColor *TGButtonForegroundColor(TGButtonSurfaceStyle style, BOOL highlighted, BOOL selected, BOOL enabled) {
    return [TGButtonAppearance(style, highlighted, selected, enabled) objectAtIndex:0];
}

void TGDrawReadableButtonSurface(NSBezierPath *path, NSRect rect, TGButtonSurfaceStyle style,
                                 BOOL highlighted, BOOL selected, BOOL enabled, BOOL flipped) {
    TGDrawOriginalButtonSurface(path, rect, style, highlighted, selected, enabled, flipped);
    NSColor *overlay = [TGButtonAppearance(style, highlighted, selected, enabled) objectAtIndex:1];
    if ([overlay alphaComponent] > 0.0) { [overlay set]; [path fill]; }
}

void TGDrawButtonTemplateImage(NSImage *image, NSRect rect, NSColor *color, BOOL flipped) {
    if (!image || NSIsEmptyRect(rect)) { return; }
    // Transparency layer confines SourceIn to this approved image, never to the
    // button or previously rendered content beneath it.
    [NSGraphicsContext saveGraphicsState];
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextBeginTransparencyLayer(context, NULL);
    [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:flipped hints:nil];
    [color set];
    NSRectFillUsingOperation(rect, NSCompositeSourceIn);
    CGContextEndTransparencyLayer(context);
    [NSGraphicsContext restoreGraphicsState];
}
