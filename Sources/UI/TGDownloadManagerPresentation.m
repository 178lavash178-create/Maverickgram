#import "TGDownloadManagerPresentation.h"
#import "TGIconAssets.h"
#import "TGLocalization.h"
#import "TGTheme.h"
#import "TGInterfaceDesign.h"
#import "TGChatListSelectionAppearance.h"
#import "TGAquaAppearance.h"
#include <math.h>

NSString *TGDownloadManagerByteCount(long long bytes) {
    bytes = MAX(0LL, bytes);
    Class formatter = NSClassFromString(@"NSByteCountFormatter");
    if ([formatter respondsToSelector:@selector(stringFromByteCount:countStyle:)]) {
        return [formatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleBinary];
    }
    // Keep the same 1024-based units if a legacy runtime lacks the formatter.
    const char *units[] = {"B", "KB", "MB", "GB", "TB", "PB", "EB"};
    double value = (double)bytes;
    NSUInteger unit = 0;
    while (value >= 1024.0 && unit < 6) { value /= 1024.0; unit++; }
    return unit == 0 ? [NSString stringWithFormat:@"%lld B", bytes] :
                      [NSString stringWithFormat:@"%.1f %s", value, units[unit]];
}

static CGFloat TGDownloadButtonWidth(NSString *key, BOOL primary) {
    NSFont *font = primary ? [NSFont boldSystemFontOfSize:13.0] : [NSFont boldSystemFontOfSize:12.0];
    return ceil([TGLoc(key) sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width)
        + (primary ? 32.0 : 28.0);
}

TGDownloadManagerLayout TGDownloadManagerLayoutForSize(NSSize size) {
    CGFloat width = MAX(620.0, size.width), height = MAX(460.0, size.height);
    TGDownloadManagerLayout f;
    if (TGInterfaceDesignIsAqua()) {
        // Only the list grows. Two measured action rows retain every command
        // at the minimum width without enclosing them in another card.
        f.header=NSMakeRect(0,height-52,width,52);
        f.title=NSMakeRect(24,height-26,width-48,18);
        f.subtitle=NSMakeRect(24,height-44,width-48,14);
        f.footer=NSMakeRect(0,0,width,104);
        f.surface=NSMakeRect(0,104,width,height-156);
        f.list=NSInsetRect(f.surface,16,12);
        CGFloat pause=MAX(112,MAX(TGDownloadButtonWidth(@"downloads.pause",YES),TGDownloadButtonWidth(@"downloads.resume",YES)));
        CGFloat cancel=MAX(100,TGDownloadButtonWidth(@"downloads.cancel",NO));
        CGFloat retry=MAX(112,TGDownloadButtonWidth(@"downloads.retry",NO));
        CGFloat reveal=MAX(140,TGDownloadButtonWidth(@"downloads.reveal",NO));
        CGFloat clear=MAX(160,TGDownloadButtonWidth(@"downloads.clear",NO));
        f.pause=NSMakeRect(24,60,pause,28);
        f.cancel=NSMakeRect(NSMaxX(f.pause)+8,60,cancel,28);
        f.retry=NSMakeRect(NSMaxX(f.cancel)+8,60,retry,28);
        f.clear=NSMakeRect(width-24-clear,16,clear,28);
        f.reveal=NSMakeRect(NSMinX(f.clear)-8-reveal,16,reveal,28);
        f.summary=NSMakeRect(24,21,NSMinX(f.reveal)-40,18);
        f.empty=NSMakeRect(32,NSMidY(f.list)-12,width-64,24);
        return f;
    }
    f.header = NSMakeRect(24, height - 78, width - 48, 58);
    f.title = NSMakeRect(40, height - 50, width - 80, 26);
    f.subtitle = NSMakeRect(40, height - 72, width - 80, 18);
    f.surface = NSMakeRect(24, 136, width - 48, height - 222);
    f.list = NSInsetRect(f.surface, 8, 8);
    f.footer = NSMakeRect(24, 20, width - 48, 104);
    CGFloat pause = MAX(112.0, MAX(TGDownloadButtonWidth(@"downloads.pause", YES), TGDownloadButtonWidth(@"downloads.resume", YES)));
    CGFloat cancel = MAX(100.0, TGDownloadButtonWidth(@"downloads.cancel", NO));
    CGFloat retry = MAX(112.0, TGDownloadButtonWidth(@"downloads.retry", NO));
    CGFloat reveal = MAX(140.0, TGDownloadButtonWidth(@"downloads.reveal", NO));
    CGFloat clear = MAX(160.0, TGDownloadButtonWidth(@"downloads.clear", NO));
    f.pause = NSMakeRect(40, 80, pause, 32);
    f.cancel = NSMakeRect(NSMaxX(f.pause) + 12, 80, cancel, 32);
    f.retry = NSMakeRect(NSMaxX(f.cancel) + 12, 80, retry, 32);
    f.clear = NSMakeRect(width - 40 - clear, 32, clear, 32);
    f.reveal = NSMakeRect(NSMinX(f.clear) - 12 - reveal, 32, reveal, 32);
    f.summary = NSMakeRect(40, 39, NSMinX(f.reveal) - 56, 18);
    f.empty = NSMakeRect(NSMinX(f.list) + 16, NSMidY(f.list) - 12, NSWidth(f.list) - 32, 24);
    return f;
}

static double TGDownloadLuminance(NSColor *color) {
    NSColor *rgb = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if (!rgb) { return 0.0; }
    double values[] = {[rgb redComponent], [rgb greenComponent], [rgb blueComponent]};
    for (NSUInteger i = 0; i < 3; i++) { values[i] = values[i] <= 0.04045 ? values[i] / 12.92 : pow((values[i] + 0.055) / 1.055, 2.4); }
    return 0.2126 * values[0] + 0.7152 * values[1] + 0.0722 * values[2];
}

NSColor *TGDownloadManagerReadableInk(NSColor *preferred, NSColor *background) {
    if (TGInterfaceDesignIsAqua() && [background isEqual:TGClassicTablePaperColor()]) {
        // The same detail ink appears on white rows and the silver toolbars.
        return TGThemeReadableInk(TGThemeSurfaceInkColor(preferred,TGThemeSurfaceHeader,5.4),background,4.5);
    }
    double a = TGDownloadLuminance(preferred), b = TGDownloadLuminance(background);
    if ((MAX(a, b) + 0.05) / (MIN(a, b) + 0.05) >= 4.5) { return preferred; }
    return b >= 0.179 ? [NSColor blackColor] : [NSColor whiteColor];
}

@implementation TGDownloadListCell
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    if(TGInterfaceDesignIsAqua()) frame.size.width=MAX(0,MIN(NSMaxX(frame),NSMaxX([view bounds]))-NSMinX(frame));
    NSDictionary *item = [self.representedObject isKindOfClass:[NSDictionary class]] ? self.representedObject : nil;
    if (!item) { return; }
    [NSGraphicsContext saveGraphicsState];
    [NSBezierPath clipRect:frame];
    BOOL selected = [self isHighlighted];
    NSRect row = NSInsetRect(frame, 2, 2);
    NSColor *paper = selected ? TGListSelectionBackground() : TGClassicTablePaperColor();
    [paper set];
    [[NSBezierPath bezierPathWithRoundedRect:row xRadius:(selected ? 6 : 0) yRadius:(selected ? 6 : 0)] fill];
    NSColor *ink = TGDownloadManagerReadableInk(selected ? TGListSelectionForeground() : TGClassicCardInkColor(), paper);
    NSColor *detailInk = TGDownloadManagerReadableInk(selected ? ink : TGClassicCardMutedInkColor(), paper);
    CGFloat iconY = [view isFlipped] ? NSMinY(row) + 12 : NSMaxY(row) - 36;
    NSRect icon = NSMakeRect(NSMinX(row) + 12, iconY, 24, 24);
    TGDrawTemplateIconAsset(@"document", icon, ink, 1, [view isFlipped]);
    CGFloat x = NSMaxX(icon) + 12, w = MAX(0, NSMaxX(row) - x - 14);
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [style setLineBreakMode:NSLineBreakByTruncatingMiddle];
    NSDictionary *title = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:13], NSFontAttributeName,
        ink, NSForegroundColorAttributeName, style, NSParagraphStyleAttributeName, nil];
    NSDictionary *detail = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11], NSFontAttributeName,
        detailInk, NSForegroundColorAttributeName, style, NSParagraphStyleAttributeName, nil];
    CGFloat titleY = [view isFlipped] ? NSMinY(row) + 8 : NSMaxY(row) - 26;
    CGFloat detailY = [view isFlipped] ? NSMinY(row) + 30 : NSMaxY(row) - 46;
    [[item objectForKey:@"title"] drawInRect:NSMakeRect(x, titleY, w, 18) withAttributes:title];
    [[item objectForKey:@"detail"] drawInRect:NSMakeRect(x, detailY, w, 16) withAttributes:detail];
    if ([[item objectForKey:@"show_progress"] boolValue]) {
        CGFloat barY = [view isFlipped] ? NSMinY(row) + 55 : NSMaxY(row) - 59;
        NSRect bar = NSMakeRect(x, barY, w, 4);
        [[ink colorWithAlphaComponent:0.15] set];
        [[NSBezierPath bezierPathWithRoundedRect:bar xRadius:2 yRadius:2] fill];
        CGFloat fraction = MAX(0.0, MIN(1.0, [[item objectForKey:@"progress"] doubleValue]));
        if (fraction > 0 && w > 0) {
            NSRect fill = bar; fill.size.width = MAX(2, floor(w * fraction));
            [ink set]; [[NSBezierPath bezierPathWithRoundedRect:fill xRadius:2 yRadius:2] fill];
        }
    }
    [NSGraphicsContext restoreGraphicsState];
}
@end

@implementation TGDownloadManagerSurfaceView
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSBezierPath *surface = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 0.5, 0.5) xRadius:8 yRadius:8];
    if (TGInterfaceDesignIsAqua()) {
        TGAquaDrawSurfaceInPath(surface,[self bounds],TGThemeSurfaceHeader,[self isFlipped]);
        [TGClassicPanelStrokeColor() set];[surface setLineWidth:1];[surface stroke];
        return;
    }
    [TGClassicTablePaperColor() set]; [surface fill];
    [[TGDownloadManagerReadableInk(TGClassicCardInkColor(), TGClassicTablePaperColor()) colorWithAlphaComponent:0.15] set];
    [surface setLineWidth:1]; [surface stroke];
}
@end

@implementation TGDownloadManagerBackgroundView
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    if (TGInterfaceDesignIsAqua()) TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:[self bounds]],[self bounds],TGThemeSurfaceRail,[self isFlipped]);
    else TGThemeDrawWindowBackgroundInRect([self bounds],[self isFlipped]);
}
@end
