#import <Cocoa/Cocoa.h>
#import "TGButtonAppearance.h"
#import "TGStatusButtonCells.h"
#import "TGTheme.h"
#import "TGThemeContrast.h"
#import "TGIconAssets.h"
#import "TGInterfaceDesign.h"
#include <math.h>
#include <string.h>

// Keep the actual asset renderer. Intercept only to capture the icon's bounds
// and render its background without the icon for an independent pixel comparison.
#define TGDrawTemplateIconAsset TGProductionDrawTemplateIconAsset
#import "../Sources/UI/TGIconAssets.m"
#undef TGDrawTemplateIconAsset
#define TGDrawButtonTemplateImage TGProductionDrawButtonTemplateImage
#import "../Sources/UI/TGButtonAppearance.m"
#undef TGDrawButtonTemplateImage
static BOOL SuppressIcons = NO;
static NSMutableArray *IconRects = nil;
void TGDrawTemplateIconAsset(NSString *name, NSRect rect, NSColor *color, CGFloat alpha, BOOL flipped) {
    if (SuppressIcons) { return; }
    [IconRects addObject:[NSValue valueWithRect:rect]];
    TGProductionDrawTemplateIconAsset(name, rect, color, alpha, flipped);
}

void TGDrawButtonTemplateImage(NSImage *image, NSRect rect, NSColor *color, BOOL flipped) {
    if (SuppressIcons) { return; }
    [IconRects addObject:[NSValue valueWithRect:rect]];
    TGProductionDrawButtonTemplateImage(image, rect, color, flipped);
}

#import "../Sources/UI/TGStorageButtonCells.inc"

@interface TGButtonProbeView : NSView { BOOL _flipped; }
@property(nonatomic, assign, getter=isFlipped) BOOL flipped;
@end
@implementation TGButtonProbeView
@synthesize flipped = _flipped;
- (BOOL)isFlipped { return _flipped; }
@end

static NSUInteger checks = 0, failures = 0;
static double worstSurface = 21.0;

static NSBitmapImageRep *Bitmap(NSInteger width, NSInteger height) {
    return [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
}
static void BeginBitmap(NSBitmapImageRep *bitmap, BOOL flipped) {
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext setCurrentContext:context];
    if (flipped) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:0 yBy:[bitmap pixelsHigh]];
        [transform scaleXBy:1 yBy:-1];
        [transform concat];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[context graphicsPort] flipped:YES]];
    }
}
static NSColor *Pixel(NSBitmapImageRep *bitmap, NSInteger x, NSInteger y) {
    return [[bitmap colorAtX:x y:y] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
}

static void CheckCell(NSString *theme, Class cellClass, NSString *title, TGButtonSurfaceStyle style,
                      NSSize size, BOOL selected, BOOL highlighted, BOOL enabled, BOOL flipped, BOOL image) {
    TGButtonProbeView *view = [[[TGButtonProbeView alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)] autorelease];
    [view setFlipped:flipped];
    NSButtonCell *cell = [[[cellClass alloc] initTextCell:title] autorelease];
    [cell setState:selected ? NSOnState : NSOffState];
    [cell setHighlighted:highlighted];
    [cell setEnabled:enabled];
    if (image) { [cell setImage:TGTemplateIconAssetImage(@"history", NSMakeSize(17,17), [NSColor whiteColor], 1.0)]; }
    NSRect bounds = [view bounds];
    NSRect rect = NSInsetRect(bounds, (style == TGButtonSurfaceSecondary || cellClass == [TGPrimaryTextButtonCell class] || cellClass == [TGStoragePrimaryButtonCell class] || cellClass == [TGStorageRefreshButtonCell class]) ? 0.5 : 1.0,
                                      (style == TGButtonSurfaceSecondary || cellClass == [TGPrimaryTextButtonCell class] || cellClass == [TGStoragePrimaryButtonCell class] || cellClass == [TGStorageRefreshButtonCell class]) ? 0.5 : 1.0);
    NSBitmapImageRep *surface = Bitmap(size.width, size.height), *render = Bitmap(size.width, size.height), *withoutIcons = Bitmap(size.width, size.height);
    BeginBitmap(surface, flipped);
    [[NSColor magentaColor] set]; NSRectFill(bounds); // Deliberately unrelated parent.
    TGDrawReadableButtonSurface([NSBezierPath bezierPathWithRoundedRect:rect xRadius:6 yRadius:6], rect,
                               style, highlighted, selected, enabled, flipped);
    [NSGraphicsContext restoreGraphicsState];
    BeginBitmap(withoutIcons, flipped);
    [[NSColor magentaColor] set]; NSRectFill(bounds);
    SuppressIcons = YES;
    [cell drawWithFrame:bounds inView:view];
    SuppressIcons = NO;
    [NSGraphicsContext restoreGraphicsState];
    [IconRects removeAllObjects];
    BeginBitmap(render, flipped);
    [[NSColor magentaColor] set]; NSRectFill(bounds);
    [cell drawWithFrame:bounds inView:view];
    [NSGraphicsContext restoreGraphicsState];
    NSColor *ink = TGButtonForegroundColor(style, highlighted, selected, enabled);
    double minimum = 21.0, maximumGlyph = 1.0, minimumLuminance=1.0, maximumLuminance=0.0;
    NSUInteger strongPixels = 0;
    NSInteger x, y;
    for (y = 5; y < size.height - 5; y++) {
        for (x = 6; x < size.width - 6; x++) {
            // Settings colored icon tile has its own independent ink/surface pair.
            if (style == TGButtonSurfaceSettings && x < 46) { continue; }
            NSColor *background = Pixel(surface, x, y);
            CGFloat luminance=0.2126*[background redComponent]+0.7152*[background greenComponent]+0.0722*[background blueComponent];
            minimumLuminance=MIN(minimumLuminance,luminance);maximumLuminance=MAX(maximumLuminance,luminance);
            double contrast = TGThemeContrastRatio(ink, background);
            minimum = MIN(minimum, contrast);
            double glyphContrast = TGThemeContrastRatio(Pixel(render, x, y), background);
            maximumGlyph = MAX(maximumGlyph, glyphContrast);
            if (glyphContrast >= (enabled ? 3.5 : 2.3)) { strongPixels++; }
        }
    }
    // Count only pixels changed by the real approved icon, excluding the
    // background, border and text. This catches a wrong ink choice in the cell.
    if ([IconRects count] > 0) {
        strongPixels = 0; maximumGlyph = 1.0;
        for (NSValue *value in IconRects) {
            NSRect icon = [value rectValue];
            if (!flipped) { icon.origin.y = size.height - NSMaxY(icon); }
            for (y = MAX(0, floor(NSMinY(icon))); y < MIN(size.height, ceil(NSMaxY(icon))); y++) {
                for (x = MAX(0, floor(NSMinX(icon))); x < MIN(size.width, ceil(NSMaxX(icon))); x++) {
                    double ratio = TGThemeContrastRatio(Pixel(render, x, y), Pixel(withoutIcons, x, y));
                    maximumGlyph = MAX(maximumGlyph, ratio);
                    if (ratio >= (enabled ? 3.5 : 2.3)) { strongPixels++; }
                }
            }
        }
    }
    checks++;
    if (TGInterfaceDesignIsAqua() && style==TGButtonSurfaceSecondary && maximumLuminance-minimumLuminance<0.015) {
        fprintf(stderr,"Aqua secondary button must retain its dimensional silver material, not a flat fill.\n");failures++;
    }
    worstSurface = MIN(worstSurface, minimum);
    if (minimum < (enabled ? 4.45 : 2.95) || strongPixels < 4) {
        fprintf(stderr, "Button %s %s sel=%d press=%d enabled=%d flip=%d: surface %.2f actual glyph max %.2f strong pixels %lu\n",
                [theme UTF8String], [NSStringFromClass(cellClass) UTF8String], selected, highlighted, enabled, flipped,
                minimum, maximumGlyph, (unsigned long)strongPixels);
        failures++;
    }
}

int main(int argc, const char **argv) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL aquaSecondaryOnly=(argc>1 && strcmp(argv[1],"--aqua-secondary")==0);
    BOOL aquaControlsOnly=(argc>1 && strcmp(argv[1],"--aqua-controls")==0);
    if (aquaSecondaryOnly || aquaControlsOnly) [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:@"aqua" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
    if (!TGIconAssetImageNamed(@"chat")) { fprintf(stderr, "Bundle must contain the approved Resources/Icons assets.\n"); return 2; }
    IconRects = [[NSMutableArray alloc] init];
    if (aquaControlsOnly) {
        TGSetActiveThemeIdentifier(TGThemeIdentifierVKBlue);
        for(NSUInteger highlighted=0;highlighted<2;highlighted++) for(NSUInteger enabled=0;enabled<2;enabled++) for(NSUInteger flipped=0;flipped<2;flipped++) {
            CheckCell(@"aqua",[TGPrimaryTextButtonCell class],@"Continue",TGButtonSurfaceEnamel,NSMakeSize(120,32),YES,highlighted,enabled,flipped,NO);
            CheckCell(@"aqua",[TGSecondaryTextButtonCell class],@"Edit profile",TGButtonSurfaceSecondary,NSMakeSize(120,32),NO,highlighted,enabled,flipped,NO);
            CheckCell(@"aqua",[TGHeaderIconButtonCell class],@"search",TGButtonSurfaceEnamel,NSMakeSize(32,32),YES,highlighted,enabled,flipped,NO);
            CheckCell(@"aqua",[TGMediaPlaybackButtonCell class],@"play",TGButtonSurfaceEnamel,NSMakeSize(32,32),YES,highlighted,enabled,flipped,NO);
        }
        printf("Aqua shared controls: %lu actual primary/secondary/header/playback renders, normal/pressed/disabled,both orientations; minimum contrast %.2f,%lu failures.\n",(unsigned long)checks,worstSurface,(unsigned long)failures);
        [IconRects release];[pool drain];return failures?1:0;
    }
    if (aquaSecondaryOnly) {
        TGSetActiveThemeIdentifier(TGThemeIdentifierVKBlue);
        for(NSUInteger highlighted=0;highlighted<2;highlighted++) for(NSUInteger enabled=0;enabled<2;enabled++) for(NSUInteger flipped=0;flipped<2;flipped++) {
            CheckCell(@"aqua",[TGSecondaryTextButtonCell class],@"Edit profile",TGButtonSurfaceSecondary,NSMakeSize(120,32),NO,highlighted,enabled,flipped,NO);
            CheckCell(@"aqua",[TGSecondaryTextButtonCell class],@"Show in Finder",TGButtonSurfaceSecondary,NSMakeSize(220,36),NO,highlighted,enabled,flipped,NO);
        }
        printf("Aqua secondary material: %lu real cell renders, normal/pressed/disabled,both orientations,unchanged title geometry; minimum contrast %.2f,%lu failures.\n",(unsigned long)checks,worstSurface,(unsigned long)failures);
        [IconRects release];[pool drain];return failures?1:0;
    }
    for (NSString *theme in TGThemeIdentifiers()) {
        if (argc > 1 && ![theme isEqualToString:[NSString stringWithUTF8String:argv[1]]]) { continue; }
        NSAutoreleasePool *iteration = [[NSAutoreleasePool alloc] init];
        TGSetActiveThemeIdentifier(theme);
        NSUInteger selected, highlighted, enabled, flipped;
        for (selected = 0; selected < 2; selected++) {
            for (highlighted = 0; highlighted < 2; highlighted++) {
                for (enabled = 0; enabled < 2; enabled++) {
                    for (flipped = 0; flipped < 2; flipped++) {
                        CheckCell(theme, [TGNavigationButtonCell class], @"Chats", TGButtonSurfaceEnamel, NSMakeSize(92,52), selected, highlighted, enabled, flipped, NO);
                        CheckCell(theme, [TGStickerPickerTabButtonCell class], @"Recent", TGButtonSurfaceEnamel, NSMakeSize(116,30), selected, highlighted, enabled, flipped, YES);
                        CheckCell(theme, [TGStickerPickerButtonCell class], @"stickers", TGButtonSurfaceSticker, NSMakeSize(44,44), selected, highlighted, enabled, flipped, NO);
                        if (selected) {
                            CheckCell(theme, [TGSendButtonCell class], @"", TGButtonSurfaceEnamel, NSMakeSize(34,34), YES, highlighted, enabled, flipped, NO);
                            CheckCell(theme, [TGAttachButtonCell class], @"", TGButtonSurfaceEnamel, NSMakeSize(34,34), YES, highlighted, enabled, flipped, NO);
                            CheckCell(theme, [TGComposerSymbolButtonCell class], @"video", TGButtonSurfaceEnamel, NSMakeSize(34,34), YES, highlighted, enabled, flipped, NO);
                            CheckCell(theme, [TGHeaderIconButtonCell class], @"search", TGButtonSurfaceEnamel, NSMakeSize(32,32), YES, highlighted, enabled, flipped, NO);
                            CheckCell(theme, [TGMediaPlaybackButtonCell class], @"play", TGButtonSurfaceEnamel, NSMakeSize(32,32), YES, highlighted, enabled, flipped, NO);
                            CheckCell(theme, [TGPrimaryTextButtonCell class], @"Continue", TGButtonSurfaceEnamel, NSMakeSize(120,32), YES, highlighted, enabled, flipped, NO);
                        } else {
                            CheckCell(theme, [TGStoragePrimaryButtonCell class], @"Clear cache", TGButtonSurfaceEnamel, NSMakeSize(140,36), NO, highlighted, enabled, flipped, NO);
                            CheckCell(theme, [TGStorageRefreshButtonCell class], @"", TGButtonSurfaceEnamel, NSMakeSize(36,36), NO, highlighted, enabled, flipped, NO);
                            CheckCell(theme, [TGDrawerButtonCell class], @"", TGButtonSurfaceEnamel, NSMakeSize(34,34), NO, highlighted, enabled, flipped, NO);
                            CheckCell(theme, [TGSecondaryTextButtonCell class], @"Edit profile", TGButtonSurfaceSecondary, NSMakeSize(120,32), NO, highlighted, enabled, flipped, NO);
                            CheckCell(theme, [TGSettingsListButtonCell class], @"Appearance", TGButtonSurfaceSettings, NSMakeSize(220,48), NO, highlighted, enabled, flipped, NO);
                        }
                    }
                }
            }
        }
        [iteration drain];
    }
    printf("Button appearance: %lu actual cell renders across %lu themes; minimum surface contrast %.2f; %lu failures.\n",
        (unsigned long)checks, (unsigned long)[TGThemeIdentifiers() count], worstSurface, (unsigned long)failures);
    [IconRects release];
    [pool drain];
    return failures ? 1 : 0;
}
