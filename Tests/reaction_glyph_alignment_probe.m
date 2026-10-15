#import <Cocoa/Cocoa.h>
#import "TGReactionChipLayout.h"
#include <math.h>

// The probe draws the production text helper. Only unrelated theme/summary
// dependencies of the complete reaction renderer are substituted here.
NSColor *TGClassicIncomingBubbleBottomColor(void) { return [NSColor whiteColor]; }
NSColor *TGClassicNavigationSelectedColor(CGFloat alpha) { return [[NSColor blueColor] colorWithAlphaComponent:alpha]; }
NSString *TGStringByReplacingUnrenderableEmoji(NSString *text, NSFont *font) { (void)font; return text; }

static BOOL TGLegacyPlacement = NO;
static NSUInteger TGChecks = 0;
static CGFloat TGMaximumError = 0.0;

static BOOL TGCheckGlyph(NSString *text, NSFont *font, BOOL flipped, NSInteger scale, BOOL emoji) {
    NSInteger width = 96 * scale, height = 48 * scale;
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
        pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    memset([bitmap bitmapData], 0, [bitmap bytesPerRow] * height);
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext setCurrentContext:context];
    NSAffineTransform *transform = [NSAffineTransform transform];
    if (flipped) { [transform translateXBy:0.0 yBy:height]; }
    [transform scaleXBy:scale yBy:flipped ? -scale : scale];
    [transform concat];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[context graphicsPort] flipped:flipped]];
    NSRect rect = NSMakeRect(8.0, 8.0, 72.0, 24.0);
    if (TGLegacyPlacement) {
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [NSColor blackColor], NSForegroundColorAttributeName, nil];
        NSSize size = [text sizeWithAttributes:attributes];
        CGFloat y = NSMidY(rect) - floor(size.height / 2.0) + (emoji ? (flipped ? -2.0 : 2.0) : 0.0);
        [text drawInRect:NSMakeRect(NSMinX(rect), y, NSWidth(rect), size.height + 1.0) withAttributes:attributes];
    } else {
        TGDrawReactionTextVerticallyCentered(text, font, [NSColor blackColor], rect, flipped);
    }
    [NSGraphicsContext restoreGraphicsState];
    NSInteger first = height, last = -1;
    NSInteger x, y;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            NSUInteger pixel[4] = {0, 0, 0, 0};
            [bitmap getPixel:pixel atX:x y:y];
            if (pixel[3] >= 32) { first = MIN(first, y); last = MAX(last, y); }
        }
    }
    TGChecks++;
    CGFloat expected = flipped ? NSMidY(rect) : 48.0 - NSMidY(rect);
    CGFloat actual = ((CGFloat)first + (CGFloat)last + 1.0) / (2.0 * scale);
    CGFloat error = fabs(expected - actual);
    TGMaximumError = MAX(TGMaximumError, error);
    CGFloat top = (flipped ? NSMinY(rect) : 48.0 - NSMaxY(rect)) * scale;
    CGFloat bottom = top + NSHeight(rect) * scale;
    if (last < first || error > 1.25 || first < top || last >= bottom || (last - first + 1) < 7 * scale) {
        fprintf(stderr, "Reaction glyph alignment: %s, %s, flipped=%d scale=%ld error=%.2fpt visibleHeight=%.2fpt\n",
            [text UTF8String], [[font fontName] UTF8String], flipped, (long)scale, (double)error, (double)(last - first + 1) / scale);
        return NO;
    }
    return YES;
}

int main(int argc, const char **argv) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    TGLegacyPlacement = argc > 1 && strcmp(argv[1], "--legacy-placement") == 0;
    NSFont *emojiFont = [NSFont fontWithName:@"Apple Color Emoji" size:14.0];
    if (!emojiFont) { emojiFont = [NSFont systemFontOfSize:14.0]; }
    NSArray *glyphs = [NSArray arrayWithObjects:@"👍", @"❤", @"❤️", @"😂", @"🔥", @"😮", @"🎉", @"?", nil];
    BOOL passed = YES;
    NSInteger scale, flip, repeat;
    for (scale = 1; scale <= 2; scale++) {
        for (flip = 0; flip < 2; flip++) {
            // Repeat on the cached metrics path as well as the first render.
            for (repeat = 0; repeat < 2; repeat++) {
                for (NSString *glyph in glyphs) { if (!TGCheckGlyph(glyph, emojiFont, flip != 0, scale, YES)) { passed = NO; } }
                if (!TGCheckGlyph(@"?", [NSFont systemFontOfSize:14.0], flip != 0, scale, YES)) { passed = NO; }
                for (NSString *count in [NSArray arrayWithObjects:@"1", @"20", @"999", nil]) {
                    if (!TGCheckGlyph(count, [NSFont boldSystemFontOfSize:11.0], flip != 0, scale, NO)) { passed = NO; }
                }
            }
        }
    }
    printf("Reaction glyph pixel probe: %lu renders, maximum visible-center error %.2fpt, %s.\n", (unsigned long)TGChecks, (double)TGMaximumError, passed ? "PASS" : "FAIL");
    [pool drain];
    return passed ? 0 : 1;
}
