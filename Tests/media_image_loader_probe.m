#import <Cocoa/Cocoa.h>
#import "TGMediaImageLoader.h"
#import "TGMessageThumbnailPrefetcher.h"
#import "TGMessageItem.h"
#import "TGWebPDecoder.h"
#include <stdio.h>
#include <math.h>

BOOL TGDataHasWebPHeader(NSData *data) {
    (void)data;
    return NO;
}

NSImage *TGWebPImageFromData(NSData *data) {
    (void)data;
    return nil;
}

NSImage *TGWebPImageFromFile(NSString *path) {
    (void)path;
    return nil;
}

// Force a legitimate hash collision independent of Foundation's OS-specific
// sampling algorithm. The production decoder still receives real bitmap bytes.
@interface TGCollidingImageData : NSData {
    NSData *_contents;
}
- (id)initWithContents:(NSData *)contents;
@end
@implementation TGCollidingImageData
- (id)initWithContents:(NSData *)contents {
    self = [super init];
    if (self) { _contents = [contents copy]; }
    return self;
}
- (const void *)bytes { return [_contents bytes]; }
- (NSUInteger)length { return [_contents length]; }
- (NSUInteger)hash { return 12345; }
- (void)dealloc { [_contents release]; [super dealloc]; }
@end

static NSData *TGCollisionBitmap(BOOL blueCenter) {
    const unsigned char header[54] = {'B','M',0x36,0x30,0,0,0,0,0,0,54,0,0,0,
        40,0,0,0,64,0,0,0,64,0,0,0,1,0,24,0};
    NSMutableData *data = [NSMutableData dataWithBytes:header length:sizeof(header)];
    for (NSUInteger y = 0; y < 64; y++) {
        for (NSUInteger x = 0; x < 64; x++) {
            BOOL blue = blueCenter && x >= 8 && x < 56 && y >= 8 && y < 56;
            unsigned char pixel[3] = {blue ? 255 : 0, 0, blue ? 0 : 255};
            [data appendBytes:pixel length:sizeof(pixel)];
        }
    }
    return [[[TGCollidingImageData alloc] initWithContents:data] autorelease];
}

static BOOL TGCheckDataCacheIdentity(void) {
    NSData *red = TGCollisionBitmap(NO), *blue = TGCollisionBitmap(YES);
    NSImage *redImage = TGImageThumbnailFromData(red, 16);
    NSImage *blueImage = TGImageThumbnailFromData(blue, 16);
    NSBitmapImageRep *redPixels = [NSBitmapImageRep imageRepWithData:[redImage TIFFRepresentation]];
    NSBitmapImageRep *bluePixels = [NSBitmapImageRep imageRepWithData:[blueImage TIFFRepresentation]];
    NSColor *redCenter = [[redPixels colorAtX:8 y:8] colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    NSColor *blueCenter = [[bluePixels colorAtX:8 y:8] colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if ([red length] != [blue length] || [red hash] != [blue hash] || !redImage || !blueImage ||
        redImage == blueImage || [redCenter redComponent] < 0.9 || [blueCenter blueComponent] < 0.9) {
        fprintf(stderr, "different image bytes with equal length/hash reused the wrong thumbnail\n");
        return NO;
    }
    NSData *sameBytes = [NSData dataWithBytes:[blue bytes] length:[blue length]];
    NSImage *smaller = TGImageThumbnailFromData(sameBytes, 8);
    if (TGImageThumbnailFromData(sameBytes, 16) != blueImage || smaller == blueImage ||
        !NSEqualSizes([smaller size], NSMakeSize(8, 8))) {
        fprintf(stderr, "data thumbnail cache failed byte identity or pixel-size separation\n");
        return NO;
    }
    return YES;
}

static BOOL TGWritePNG(NSString *path, NSInteger width, NSInteger height, NSColor *color) {
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL
                      pixelsWide:width
                      pixelsHigh:height
                   bitsPerSample:8
                 samplesPerPixel:4
                        hasAlpha:YES
                        isPlanar:NO
                  colorSpaceName:NSCalibratedRGBColorSpace
                     bytesPerRow:0
                    bitsPerPixel:0] autorelease];
    if (!bitmap) {
        return NO;
    }
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    [color setFill];
    NSRectFill(NSMakeRect(0, 0, width, height));
    [NSGraphicsContext restoreGraphicsState];
    NSData *data = [bitmap representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
    return [data writeToFile:path atomically:YES];
}

static BOOL TGSizeMatches(NSImage *image, CGFloat width, CGFloat height) {
    NSSize size = [image size];
    return image && fabs(size.width - width) < 0.5 && fabs(size.height - height) < 0.5;
}

int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int result = 0;
    if (!TGCheckDataCacheIdentity()) { result = 13; }
    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:
                           [NSString stringWithFormat:@"telegraphica-image-loader-%u", arc4random()]];
    NSString *path = [directory stringByAppendingPathComponent:@"fixture.png"];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];

    if (!TGWritePNG(path, 32, 16, [NSColor redColor])) {
        result = 2;
    }
    NSImage *thumbnail = (result == 0) ? TGImageThumbnailFromFile(path, 16) : nil;
    if (result == 0 && !TGSizeMatches(thumbnail, 16, 8)) {
        fprintf(stderr, "thumbnail downsample failed\n");
        result = 3;
    }
    if (result == 0 && !TGMediaCachedThumbnailFromFile(path, 16)) {
        fprintf(stderr, "thumbnail cache lookup failed\n");
        result = 4;
    }

    if (result == 0 && !TGWritePNG(path, 16, 32, [NSColor blueColor])) {
        result = 5;
    }
    if (result == 0 && TGMediaCachedThumbnailFromFile(path, 16)) {
        fprintf(stderr, "changed source reused a stale cache entry\n");
        result = 6;
    }

    __block BOOL completed = NO;
    __block BOOL callbackWasOnMainThread = NO;
    __block NSSize asyncSize = NSZeroSize;
    if (result == 0) {
        TGMediaImageLoadToken *token = TGLoadImageThumbnailFromFileAsync(path, 16, ^(NSImage *image) {
            completed = YES;
            callbackWasOnMainThread = [NSThread isMainThread];
            asyncSize = [image size];
        });
        if (!token) {
            result = 7;
        }
    }
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:3.0];
    while (result == 0 && !completed && [deadline timeIntervalSinceNow] > 0.0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    }
    if (result == 0 && (!completed || !callbackWasOnMainThread ||
                        fabs(asyncSize.width - 8.0) >= 0.5 || fabs(asyncSize.height - 16.0) >= 0.5)) {
        fprintf(stderr, "async thumbnail completion failed\n");
        result = 8;
    }

    NSString *avatarPath = [directory stringByAppendingPathComponent:@"avatar.png"];
    NSString *mediaPath = [directory stringByAppendingPathComponent:@"media.png"];
    NSString *previewPath = [directory stringByAppendingPathComponent:@"preview.png"];
    if (result == 0 &&
        (!TGWritePNG(avatarPath, 24, 24, [NSColor greenColor]) ||
         !TGWritePNG(mediaPath, 80, 40, [NSColor orangeColor]) ||
         !TGWritePNG(previewPath, 40, 80, [NSColor purpleColor]))) {
        result = 9;
    }
    __block NSUInteger prefetchCompletionCount = 0;
    TGMessageThumbnailPrefetcher *prefetcher = nil;
    TGMessageItem *messageItem = nil;
    if (result == 0) {
        prefetcher = [[[TGMessageThumbnailPrefetcher alloc] init] autorelease];
        messageItem = [[[TGMessageItem alloc] initWithChatID:@1
                                                  messageID:@2
                                                       date:@3
                                                   outgoing:NO
                                                    preview:@"Photo"] autorelease];
        [messageItem setSenderAvatarLocalPath:avatarPath];
        [messageItem setContentType:@"messagePhoto"];
        [messageItem setMediaItems:[NSArray arrayWithObject:
                                    [NSDictionary dictionaryWithObject:mediaPath forKey:@"local_path"]]];
        [messageItem setLinkPreviewInfo:
                     [NSDictionary dictionaryWithObject:
                      [NSDictionary dictionaryWithObject:previewPath forKey:@"local_path"]
                                                 forKey:@"media"]];
        [prefetcher prefetchMessageItem:messageItem completion:^{
            prefetchCompletionCount += 1;
        }];
    }
    deadline = [NSDate dateWithTimeIntervalSinceNow:3.0];
    while (result == 0 && prefetchCompletionCount < 3 && [deadline timeIntervalSinceNow] > 0.0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    }
    if (result == 0 && (prefetchCompletionCount != 3 ||
                        !TGMediaCachedThumbnailFromFile(avatarPath, 128) ||
                        !TGMediaCachedThumbnailFromFile(mediaPath, 768) ||
                        !TGMediaCachedThumbnailFromFile(previewPath, 768))) {
        fprintf(stderr, "message thumbnail prefetch failed\n");
        result = 10;
    }
    if (result == 0) {
        [prefetcher prefetchMessageItem:messageItem completion:^{
            prefetchCompletionCount += 1;
        }];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        if (prefetchCompletionCount != 3) {
            fprintf(stderr, "completed message thumbnails were scheduled twice\n");
            result = 11;
        }
    }

    if (result == 0) {
        TGMediaImageLoaderClearCache();
        [prefetcher prefetchPath:avatarPath maximumPixelSize:128 completion:^{
            prefetchCompletionCount += 1;
        }];
        deadline = [NSDate dateWithTimeIntervalSinceNow:3.0];
        while (prefetchCompletionCount < 4 && [deadline timeIntervalSinceNow] > 0.0) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        }
        if (prefetchCompletionCount != 4) {
            fprintf(stderr, "cache clear did not invalidate completed prefetch keys\n");
            result = 12;
        }
    }

    TGMediaImageLoaderClearCache();
    [[NSFileManager defaultManager] removeItemAtPath:directory error:NULL];
    if (result == 0) {
        fprintf(stdout, "Media image loader probe passed.\n");
    }
    [pool drain];
    return result;
}
