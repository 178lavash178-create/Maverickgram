#import "TGIconAssets.h"
#include <math.h>
#include <string.h>

static NSMutableDictionary *TGIconAssetSourceCache(void) {
    static NSMutableDictionary *cache = nil;
    if (!cache) {
        cache = [[NSMutableDictionary alloc] init];
    }
    return cache;
}

static NSMutableDictionary *TGIconAssetRenderedCache(void) {
    static NSMutableDictionary *cache = nil;
    if (!cache) {
        cache = [[NSMutableDictionary alloc] init];
    }
    return cache;
}

static NSString *TGIconAssetCacheKey(NSString *name, NSSize size, NSColor *color, CGFloat alpha) {
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat colorAlpha = 0.0;
    if (color) {
        NSColor *rgb = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        if (rgb) {
            [rgb getRed:&red green:&green blue:&blue alpha:&colorAlpha];
        }
    }
    return [NSString stringWithFormat:@"%@|%.1fx%.1f|%.3f,%.3f,%.3f,%.3f|%.3f",
            name, size.width, size.height, red, green, blue, colorAlpha, alpha];
}

static NSString *TGIconAssetPathForName(NSString *name) {
    if ([name length] == 0) {
        return nil;
    }
    NSBundle *bundle = [NSBundle mainBundle];
    // Older NSBundle implementations do not resolve a slash-containing resource
    // name. Supply the folder separately for the Aqua toolbar's nested assets.
    NSString *resource=[name lastPathComponent];
    NSString *directory=[name stringByDeletingLastPathComponent];
    NSString *iconDirectory=[directory length] ? [@"Icons" stringByAppendingPathComponent:directory] : @"Icons";
    NSString *path = [bundle pathForResource:resource ofType:@"png" inDirectory:iconDirectory];
    if ([path length] == 0) {
        path = [bundle pathForResource:name ofType:@"png"];
    }
    return path;
}

NSImage *TGIconAssetImageNamed(NSString *name) {
    if ([name length] == 0) {
        return nil;
    }
    NSMutableDictionary *cache = TGIconAssetSourceCache();
    NSImage *cached = [cache objectForKey:name];
    if (cached) {
        return cached;
    }
    NSString *path = TGIconAssetPathForName(name);
    if ([path length] == 0) {
        return nil;
    }
    NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
    if (!image) {
        return nil;
    }
    [cache setObject:image forKey:name];
    return image;
}

NSImage *TGTemplateIconAssetImage(NSString *name, NSSize size, NSColor *color, CGFloat alpha) {
    NSImage *source = TGIconAssetImageNamed(name);
    if (!source || size.width <= 0.0 || size.height <= 0.0) {
        return nil;
    }

    NSSize sourceSize = [source size];
    if (sourceSize.width <= 0.0 || sourceSize.height <= 0.0) {
        return nil;
    }

    NSString *cacheKey = TGIconAssetCacheKey(name, size, color, alpha);
    NSImage *cached = [TGIconAssetRenderedCache() objectForKey:cacheKey];
    if (cached) {
        return cached;
    }

    NSImage *tinted = [[[NSImage alloc] initWithSize:size] autorelease];
    [tinted lockFocus];
    NSRect targetRect = NSMakeRect(0.0, 0.0, size.width, size.height);
    [source drawInRect:targetRect
              fromRect:NSZeroRect
             operation:NSCompositeSourceOver
              fraction:1.0
        respectFlipped:NO
                 hints:nil];
    if (color) {
        [[color colorWithAlphaComponent:alpha] set];
        NSRectFillUsingOperation(targetRect, NSCompositeSourceIn);
    }
    [tinted unlockFocus];
    [TGIconAssetRenderedCache() setObject:tinted forKey:cacheKey];
    return tinted;
}

void TGDrawTemplateIconAsset(NSString *name, NSRect rect, NSColor *color, CGFloat alpha, BOOL flipped) {
    if (NSIsEmptyRect(rect)) {
        return;
    }
    NSImage *tinted = TGTemplateIconAssetImage(name, rect.size, color, alpha);
    if (!tinted) {
        return;
    }
    [tinted drawInRect:rect
              fromRect:NSZeroRect
             operation:NSCompositeSourceOver
              fraction:(color ? 1.0 : alpha)
        respectFlipped:flipped
                 hints:nil];
}

// Preserve the approved image's alpha silhouette. An inward edge is derived
// from that mask; neither the asset bounds nor the glyph shape is expanded.
static CGFloat TGIconMaskAlpha(NSBitmapImageRep *mask, NSInteger x, NSInteger y) {
    if (x < 0 || y < 0 || x >= [mask pixelsWide] || y >= [mask pixelsHigh]) { return 0.0; }
    NSUInteger pixel[4]; [mask getPixel:pixel atX:x y:y];
    return pixel[3] / 255.0;
}

NSImage *TGOutlinedTemplateIconAssetImage(NSString *name, NSSize size, NSColor *fill, NSColor *outline, CGFloat width) {
    if (!outline || width <= 0.0) { return TGTemplateIconAssetImage(name, size, fill, 1.0); }
    NSImage *source = TGIconAssetImageNamed(name);
    if (!source || size.width <= 0.0 || size.height <= 0.0) { return nil; }
    static NSCache *cache = nil;
    if (!cache) { cache = [[NSCache alloc] init]; [cache setCountLimit:128]; }
    NSString *key = [NSString stringWithFormat:@"%@|%@|%.2f", TGIconAssetCacheKey(name,size,fill,1.0), TGIconAssetCacheKey(name,size,outline,1.0), width];
    NSImage *cached = [cache objectForKey:key];
    if (cached) { return cached; }
    const CGFloat scale = 4.0;
    NSInteger pixelsWide = (NSInteger)ceil(size.width * scale), pixelsHigh = (NSInteger)ceil(size.height * scale);
    NSBitmapImageRep *mask = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:pixelsWide pixelsHigh:pixelsHigh bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    NSBitmapImageRep *result = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:pixelsWide pixelsHigh:pixelsHigh bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    if (!mask || !result) { return TGTemplateIconAssetImage(name,size,fill,1.0); }
    memset([mask bitmapData],0,[mask bytesPerRow]*pixelsHigh);
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:mask]];
    [source drawInRect:NSMakeRect(0,0,pixelsWide,pixelsHigh) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:nil];
    [NSGraphicsContext restoreGraphicsState];
    NSColor *fillRGB = [fill colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor *edgeRGB = [outline colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat radius = MIN(width * scale, MIN(pixelsWide,pixelsHigh));
    NSInteger nearOffset = (NSInteger)floor(radius), farOffset = (NSInteger)ceil(radius);
    CGFloat fraction = radius - nearOffset;
    NSInteger x,y,dx,dy;
    for (y=0;y<pixelsHigh;y++) for (x=0;x<pixelsWide;x++) {
        CGFloat alpha = TGIconMaskAlpha(mask,x,y), inner = alpha;
        for (dy=-1;dy<=1;dy++) for (dx=-1;dx<=1;dx++) {
            if (dx==0 && dy==0) { continue; }
            CGFloat nearAlpha = TGIconMaskAlpha(mask,x+dx*nearOffset,y+dy*nearOffset);
            CGFloat farAlpha = TGIconMaskAlpha(mask,x+dx*farOffset,y+dy*farOffset);
            inner = MIN(inner,nearAlpha*(1.0-fraction)+farAlpha*fraction);
        }
        CGFloat amount = alpha > 0.0 ? inner/alpha : 0.0;
        NSColor *pixel = [NSColor colorWithCalibratedRed:[fillRGB redComponent]*amount+[edgeRGB redComponent]*(1.0-amount)
            green:[fillRGB greenComponent]*amount+[edgeRGB greenComponent]*(1.0-amount)
            blue:[fillRGB blueComponent]*amount+[edgeRGB blueComponent]*(1.0-amount) alpha:alpha];
        [result setColor:pixel atX:x y:y];
    }
    [result setSize:size];
    NSImage *image = [[[NSImage alloc] initWithSize:size] autorelease];
    [image addRepresentation:result];
    [cache setObject:image forKey:key];
    return image;
}

void TGDrawOutlinedTemplateIconAsset(NSString *name, NSRect rect, NSColor *fill, NSColor *outline, CGFloat width, BOOL flipped) {
    if (NSIsEmptyRect(rect)) { return; }
    NSImage *image = TGOutlinedTemplateIconAssetImage(name,rect.size,fill,outline,width);
    [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:flipped hints:nil];
}
