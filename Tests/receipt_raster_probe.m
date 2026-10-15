#import <Cocoa/Cocoa.h>
#import "TGMessageItem.h"
#import "TGMessageLayoutSupport.h"
#import "TGChatDisplayPreferences.h"
#import "TGTheme.h"
#import "TGThemeContrast.h"
#import "TGIconAssets.h"
#include <math.h>

// Unrelated media dependencies; the receipt renderer, theme gradients and
// approved icon asset loader are all production implementations.
NSString * const TGInlineMediaKindGIF = @"gif";
NSString * const TGInlineMediaKindVideo = @"video";
NSString * const TGInlineMediaKindWebM = @"webm";
NSString * const TGInlineMediaKindTGS = @"tgs";
NSString * const TGInlineMediaIdentifierKey = @"identifier";
NSString * const TGInlineMediaPathKey = @"path";
NSString * const TGInlineMediaFrameKey = @"frame";
NSString * const TGInlineMediaKindKey = @"kind";
NSString * const TGInlineMediaPlaybackDiagnosticNotification = @"TGInlineMediaPlaybackDiagnosticNotification";
NSString * const TGInlineMediaPlaybackDiagnosticMessageKey = @"message";
NSImage *TGImageWithCorrectOrientationFromFile(NSString *path) { (void)path; return nil; }
NSImage *TGImageThumbnailFromFile(NSString *path, NSUInteger size) { (void)path; (void)size; return nil; }
NSImage *TGMediaCachedThumbnailFromFile(NSString *path, NSUInteger size) { (void)path; (void)size; return nil; }
NSImage *TGImageThumbnailFromData(NSData *data, NSUInteger size) { (void)data; (void)size; return nil; }
NSImage *TGCustomEmojiCachedImageForEntity(NSDictionary *entity, NSUInteger size) { (void)entity; (void)size; return nil; }
void TGCustomEmojiRequestImageForEntity(NSDictionary *entity, NSUInteger size) { (void)entity; (void)size; }

static NSBitmapImageRep *TGRenderReceipt(TGMessageItem *item, BOOL flipped, NSInteger scale, BOOL includeReceipt) {
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
        pixelsWide:176 * scale pixelsHigh:52 * scale bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    memset([bitmap bitmapData], 0, [bitmap bytesPerRow] * [bitmap pixelsHigh]);
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext setCurrentContext:context];
    NSAffineTransform *transform = [NSAffineTransform transform];
    if (flipped) { [transform translateXBy:0.0 yBy:52.0 * scale]; }
    [transform scaleXBy:scale yBy:flipped ? -scale : scale];
    [transform concat];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:[context graphicsPort] flipped:flipped]];
    [TGClassicTablePaperColor() set]; NSRectFill(NSMakeRect(0, 0, 176, 52));
    NSRect bubble = NSMakeRect(8, 8, 154, 36);
    if (TGChatMessagesAsBlocksEnabled()) {
        [TGMessageMetadataSurfaceColor(item, flipped) set]; NSRectFill(bubble);
    } else {
        TGThemeDrawMessageBubbleInPath([NSBezierPath bezierPathWithRoundedRect:bubble xRadius:12 yRadius:12], bubble, YES, flipped);
    }
    [@"Текст" drawInRect:NSMakeRect(20, 17, 65, 18) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont systemFontOfSize:12], NSFontAttributeName, TGClassicInkColor(), NSForegroundColorAttributeName, nil]];
    NSRect time = NSMakeRect(102, 20, 26, 12);
    [@"12:30" drawInRect:time withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont systemFontOfSize:9], NSFontAttributeName, TGMessageMetadataInkColor(item, flipped), NSForegroundColorAttributeName, nil]];
    if (includeReceipt) { TGDrawOutgoingStatusDotsForItem(item, time, flipped); }
    [NSGraphicsContext restoreGraphicsState];
    return bitmap;
}

static CGFloat TGPixelDifference(NSBitmapImageRep *a, NSBitmapImageRep *b, NSInteger x, NSInteger y) {
    NSUInteger p[4], q[4]; [a getPixel:p atX:x y:y]; [b getPixel:q atX:x y:y];
    return MAX(MAX(fabs((CGFloat)p[0] - q[0]), fabs((CGFloat)p[1] - q[1])), fabs((CGFloat)p[2] - q[2])) / 255.0;
}

static BOOL TGInlineReceiptHasFullRaster(TGMessageItem *item) {
    NSAttributedString *suffix = TGOutgoingStatusInlineAttributedStringForItem(item);
    if ([suffix length] < 2) { return NO; }
    NSTextAttachment *attachment = [suffix attribute:NSAttachmentAttributeName atIndex:1 effectiveRange:NULL];
    NSImage *image = [(NSTextAttachmentCell *)[attachment attachmentCell] image];
    NSSize size = [image size];
    if (!image || size.width != 16.0 || size.width != TGOutgoingStatusDotsWidthForItem(item) || size.height != 10.0) { return NO; }
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:(NSInteger)size.width
        pixelsHigh:(NSInteger)size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    memset([bitmap bitmapData], 0, [bitmap bytesPerRow] * [bitmap pixelsHigh]);
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    [image drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    NSUInteger area = 0; NSInteger x, y;
    for (y = 0; y < [bitmap pixelsHigh]; y++) {
        for (x = 0; x < [bitmap pixelsWide]; x++) {
            NSUInteger pixel[4]; [bitmap getPixel:pixel atX:x y:y]; if (pixel[3] > 127) { area++; }
        }
    }
    // The original 10pt approved glyph has roughly half the 14pt raster area.
    return area >= 33;
}

static BOOL TGOutlinedReceiptPreservesMask(void) {
    NSColor *fill=TGColorFromHex(0xE5E7EA), *edge=TGColorFromHex(0x747A83);
    NSImage *image=TGOutlinedTemplateIconAssetImage(@"done-mini",NSMakeSize(10,10),fill,edge,0.5);
    if (!image || !NSEqualSizes([image size],NSMakeSize(10,10)) || image != TGOutlinedTemplateIconAssetImage(@"done-mini",NSMakeSize(10,10),fill,edge,0.5)) return NO;
    NSBitmapImageRep *result=[[image representations] objectAtIndex:0];
    NSBitmapImageRep *mask=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:40 pixelsHigh:40 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    memset([mask bitmapData],0,[mask bytesPerRow]*40);
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:mask]];
    [TGIconAssetImageNamed(@"done-mini") drawInRect:NSMakeRect(0,0,40,40) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:nil];
    [NSGraphicsContext restoreGraphicsState];
    NSUInteger lightPixels=0, edgePixels=0; NSInteger x,y;
    for(y=0;y<40;y++) for(x=0;x<40;x++) {
        NSColor *original=[mask colorAtX:x y:y], *outlined=[result colorAtX:x y:y];
        if(fabs([original alphaComponent]-[outlined alphaComponent]) > 1.1/255.0) return NO;
        if([outlined alphaComponent] > 0.98) {
            if([outlined redComponent] > 0.88 && [outlined blueComponent] > 0.90) lightPixels++;
            if([outlined redComponent] < 0.60 && [outlined blueComponent] < 0.65) edgePixels++;
        }
    }
    printf("Unread mask: unchanged alpha/10pt bounds, %lu light-fill and %lu subtle-edge pixels at4x.\n",(unsigned long)lightPixels,(unsigned long)edgePixels);
    return lightPixels>=10 && edgePixels>=10;
}

int main(int argc, const char **argv) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    TGMessageItem *item = [[[TGMessageItem alloc] initWithChatID:@1 messageID:@2 date:@1 outgoing:YES preview:@"Text"] autorelease];
    NSUInteger samples = 0; CGFloat minimumInk = 10000, minimumChanged = 10000;
    BOOL passed = TGOutlinedReceiptPreservesMask();
    NSMutableArray *comparison = [NSMutableArray array];
    NSMutableArray *comparisonNames = [NSMutableArray array];
    for (NSString *theme in TGThemeIdentifiers()) {
        TGSetActiveThemeIdentifier(theme);
        NSInteger blocks, flip, scale;
        for (blocks = 0; blocks < 2; blocks++) {
            TGSetChatMessagesAsBlocksEnabled(blocks != 0);
            NSInteger state;
            for (state = 0; state < 2; state++) {
                [item setOutgoingRead:state != 0];
                if (!TGInlineReceiptHasFullRaster(item)) {
                    fprintf(stderr, "Inline receipt asset clipped or missing in %s blocks%ld state%ld\n", [theme UTF8String], (long)blocks, (long)state);
                    passed = NO;
                }
            }
            for (flip = 0; flip < 2; flip++) {
                for (scale = 1; scale <= 2; scale++) {
                    [item setOutgoingRead:NO];
                    NSBitmapImageRep *background = TGRenderReceipt(item, flip != 0, scale, NO);
                    NSBitmapImageRep *sent = TGRenderReceipt(item, flip != 0, scale, YES);
                    [item setOutgoingRead:YES];
                    NSBitmapImageRep *read = TGRenderReceipt(item, flip != 0, scale, YES);
                    CGFloat ink = 0, readInk = 0, changed = 0, firstCheck = 0, secondCheck = 0;
                    BOOL unchangedFirstRegion = YES; NSInteger x, y;
                    for (y = 12 * scale; y < 40 * scale; y++) {
                        for (x = 132 * scale; x < 162 * scale; x++) {
                            if (TGThemeContrastRatio([sent colorAtX:x y:y],[background colorAtX:x y:y]) >= 1.6) {
                                CGFloat area = 1.0 / (scale * scale);
                                ink += area;
                                if (x < 138 * scale) { firstCheck += area; }
                                if (x >= 142 * scale) { secondCheck += area; }
                            }
                            if (TGPixelDifference(read, background, x, y) > 0.15) { readInk += 1.0 / (scale * scale); }
                            if (TGPixelDifference(sent, read, x, y) > 0.15) {
                                changed += 1.0 / (scale * scale);
                                // Only the second original10pt image (x138..148)
                                // may change, including its overlap with the first.
                                if (x < 138 * scale || x >= 148 * scale) unchangedFirstRegion = NO;
                            }
                        }
                    }
                    minimumInk = MIN(minimumInk, ink); minimumChanged = MIN(minimumChanged, changed); samples++;
                    if (ink < 8.0 || readInk < 33.0 || changed < 12.0 || firstCheck < 2.0 || secondCheck < 2.0 || !unchangedFirstRegion) {
                        fprintf(stderr, "Receipt raster visibility %s blocks%ld flip%ld scale%ld: ink%.2f changed%.2f first%.2f second%.2f\n", [theme UTF8String], (long)blocks, (long)flip, (long)scale, (double)ink, (double)changed, (double)firstCheck, (double)secondCheck);
                        passed = NO;
                    }
                    if (!blocks && flip && scale == 1 && ([theme isEqualToString:TGThemeIdentifierVKBlue] || [theme isEqualToString:TGThemeIdentifierVisualNotebook] || [theme isEqualToString:TGThemeIdentifierVisualSpaceTerminal] || [theme isEqualToString:TGThemeIdentifierMidnightGraphite])) {
                        [comparison addObject:sent]; [comparison addObject:read];
                        [comparisonNames addObject:theme];
                    }
                }
            }
        }
    }
    if (argc > 1 && [comparison count] == 8) {
        NSImage *sheet = [[[NSImage alloc] initWithSize:NSMakeSize(352, 264)] autorelease];
        [sheet lockFocus]; [[NSColor whiteColor] set]; NSRectFill(NSMakeRect(0,0,352,264)); NSUInteger i;
        for (i = 0; i < 8; i++) {
            NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(176, 52)] autorelease];
            [image addRepresentation:[comparison objectAtIndex:i]];
            [image drawInRect:NSMakeRect((i % 2) * 176, (3 - i / 2) * 66, 176, 52) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        }
        for (i=0;i<[comparisonNames count];i++) {
            [[comparisonNames objectAtIndex:i] drawAtPoint:NSMakePoint(8,(3-i)*66+53) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:8],NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]];
        }
        [sheet unlockFocus];
        NSBitmapImageRep *render = [NSBitmapImageRep imageRepWithData:[sheet TIFFRepresentation]];
        [[render representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:[NSString stringWithUTF8String:argv[1]] atomically:YES];
    }
    printf("Receipt raster probe: %lu actual asset/theme renders, minimum unread edge/fill ink %.2fpx², minimum second-check-only change %.2fpx², %s.\n", (unsigned long)samples, (double)minimumInk, (double)minimumChanged, passed ? "PASS" : "FAIL");
    [pool drain]; return passed ? 0 : 1;
}
