#import "TGMediaImageLoader.h"
#import "TGWebPDecoder.h"
#import <ImageIO/ImageIO.h>
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>

NSString * const TGMediaImageLoaderCacheDidClearNotification = @"TGMediaImageLoaderCacheDidClearNotification";

@interface TGMediaImageLoadToken ()
@property (nonatomic, assign, getter=isCancelled) BOOL cancelled;
@property (nonatomic, copy) TGMediaImageLoadCompletion completion;
- (id)initWithCompletion:(TGMediaImageLoadCompletion)completion;
- (void)finishWithImage:(NSImage *)image;
@end

@implementation TGMediaImageLoadToken

@synthesize cancelled = _cancelled;
@synthesize completion = _completion;

- (id)initWithCompletion:(TGMediaImageLoadCompletion)completion {
    self = [super init];
    if (self) {
        self.completion = completion;
    }
    return self;
}

- (void)dealloc {
    [_completion release];
    [super dealloc];
}

- (void)cancel {
    @synchronized(self) {
        _cancelled = YES;
        self.completion = nil;
    }
}

- (BOOL)isCancelled {
    @synchronized(self) {
        return _cancelled;
    }
}

- (void)finishWithImage:(NSImage *)image {
    TGMediaImageLoadCompletion completion = nil;
    @synchronized(self) {
        if (!_cancelled && _completion) {
            completion = [_completion copy];
        }
        self.completion = nil;
    }
    if (completion) {
        completion(image);
        [completion release];
    }
}

@end

static NSCache *TGMediaImageCache(void) {
    static NSCache *cache = nil;
    @synchronized([NSImage class]) {
        if (!cache) {
            cache = [[NSCache alloc] init];
            [cache setCountLimit:160];
            [cache setTotalCostLimit:(64 * 1024 * 1024)];
        }
    }
    return cache;
}

static NSString *TGMediaFileCacheKey(NSString *path,
                                     NSString *kind,
                                     NSUInteger maximumPixelSize) {
    if (![path isKindOfClass:[NSString class]] || [path length] == 0) {
        return nil;
    }
    NSString *resolvedPath = [path stringByStandardizingPath];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:resolvedPath error:NULL];
    NSNumber *fileSize = [attributes objectForKey:NSFileSize];
    NSDate *modificationDate = [attributes objectForKey:NSFileModificationDate];
    NSNumber *fileNumber = [attributes objectForKey:NSFileSystemFileNumber];
    return [NSString stringWithFormat:@"%@:%lu:%@:%@:%@:%0.6f",
            ([kind length] > 0 ? kind : @"file"),
            (unsigned long)maximumPixelSize,
            resolvedPath,
            (fileNumber ?: @0),
            (fileSize ?: @0),
            ([modificationDate isKindOfClass:[NSDate class]] ? [modificationDate timeIntervalSince1970] : 0.0)];
}

static NSImage *TGMediaCachedImage(NSString *cacheKey) {
    if ([cacheKey length] == 0) {
        return nil;
    }
    NSImage *image = [TGMediaImageCache() objectForKey:cacheKey];
    return [[image retain] autorelease];
}

static NSImage *TGMediaCacheImage(NSImage *image, NSString *cacheKey) {
    if (image && [cacheKey length] > 0) {
        NSSize imageSize = [image size];
        NSUInteger cost = 1;
        if (imageSize.width > 0.0 && imageSize.height > 0.0) {
            cost = (NSUInteger)MAX(1.0, imageSize.width * imageSize.height * 4.0);
        }
        [TGMediaImageCache() setObject:image forKey:cacheKey cost:cost];
    }
    return image;
}

static NSImage *TGMediaThumbnailFromImageSource(CGImageSourceRef source,
                                                 NSUInteger maximumPixelSize) {
    if (!source || maximumPixelSize == 0) {
        return nil;
    }

    NSDictionary *thumbnailOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                      (id)kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways,
                                      (id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform,
                                      (id)kCFBooleanFalse, kCGImageSourceShouldCacheImmediately,
                                      [NSNumber numberWithUnsignedInteger:maximumPixelSize], kCGImageSourceThumbnailMaxPixelSize,
                                      nil];
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source,
                                                              0,
                                                              (CFDictionaryRef)thumbnailOptions);
    if (!imageRef) {
        return nil;
    }

    NSSize size = NSMakeSize((CGFloat)CGImageGetWidth(imageRef),
                             (CGFloat)CGImageGetHeight(imageRef));
    NSImage *image = [[[NSImage alloc] initWithCGImage:imageRef size:size] autorelease];
    CGImageRelease(imageRef);
    return image;
}

NSImage *TGImageThumbnailFromFile(NSString *path, NSUInteger maximumPixelSize) {
    if (![path isKindOfClass:[NSString class]] || [path length] == 0 || maximumPixelSize == 0) {
        return nil;
    }

    NSString *resolvedPath = [path stringByStandardizingPath];
    if ([resolvedPath length] == 0) {
        return nil;
    }
    NSString *cacheKey = TGMediaFileCacheKey(resolvedPath, @"file-thumbnail", maximumPixelSize);
    NSImage *cachedImage = TGMediaCachedImage(cacheKey);
    if (cachedImage) {
        return cachedImage;
    }

    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                     (CFStringRef)resolvedPath,
                                                     kCFURLPOSIXPathStyle,
                                                     false);
    CGImageSourceRef source = fileURL ? CGImageSourceCreateWithURL(fileURL, NULL) : nil;
    if (fileURL) {
        CFRelease(fileURL);
    }
    if (!source) {
        return TGMediaCacheImage(TGWebPImageFromFile(resolvedPath), cacheKey);
    }

    NSImage *image = TGMediaThumbnailFromImageSource(source, maximumPixelSize);
    CFRelease(source);
    if (!image) {
        image = TGWebPImageFromFile(resolvedPath);
    }
    return TGMediaCacheImage(image, cacheKey);
}

NSImage *TGMediaCachedThumbnailFromFile(NSString *path, NSUInteger maximumPixelSize) {
    if (maximumPixelSize == 0) {
        return nil;
    }
    return TGMediaCachedImage(TGMediaFileCacheKey(path, @"file-thumbnail", maximumPixelSize));
}

TGMediaImageLoadToken *TGLoadImageThumbnailFromFileAsync(NSString *path,
                                                         NSUInteger maximumPixelSize,
                                                         TGMediaImageLoadCompletion completion) {
    if (![path isKindOfClass:[NSString class]] || [path length] == 0 ||
        maximumPixelSize == 0 || !completion) {
        return nil;
    }

    TGMediaImageLoadToken *token = [[[TGMediaImageLoadToken alloc] initWithCompletion:completion] autorelease];
    NSString *pathCopy = [path copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSImage *image = nil;
        if (![token isCancelled]) {
            image = [TGImageThumbnailFromFile(pathCopy, maximumPixelSize) retain];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [token finishWithImage:image];
        });
        [image release];
        [pool drain];
    });
    [pathCopy release];
    return token;
}

static NSString *TGMediaDataCacheKey(NSData *data, NSUInteger maximumPixelSize) {
    // NSData.hash is a bucket hint, not content identity: equal-sized images
    // with different pixels can have the same hash and must not share a preview.
    CC_SHA256_CTX context;
    CC_SHA256_Init(&context);
    const unsigned char *bytes = [data bytes];
    NSUInteger remaining = [data length];
    while (remaining > 0) {
        CC_LONG length = (CC_LONG)MIN(remaining, (NSUInteger)(1024 * 1024));
        CC_SHA256_Update(&context, bytes, length);
        bytes += length;
        remaining -= length;
    }
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &context);
    static const char digits[] = "0123456789abcdef";
    char hex[CC_SHA256_DIGEST_LENGTH * 2 + 1];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        hex[index * 2] = digits[digest[index] >> 4];
        hex[index * 2 + 1] = digits[digest[index] & 15];
    }
    hex[CC_SHA256_DIGEST_LENGTH * 2] = '\0';
    return [NSString stringWithFormat:@"data-thumbnail:%lu:%s", (unsigned long)maximumPixelSize, hex];
}

NSImage *TGImageThumbnailFromData(NSData *data, NSUInteger maximumPixelSize) {
    if (![data isKindOfClass:[NSData class]] || [data length] == 0 || maximumPixelSize == 0) {
        return nil;
    }

    NSString *cacheKey = TGMediaDataCacheKey(data, maximumPixelSize);
    NSImage *cachedImage = TGMediaCachedImage(cacheKey);
    if (cachedImage) {
        return cachedImage;
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    NSImage *image = nil;
    if (source) {
        image = TGMediaThumbnailFromImageSource(source, maximumPixelSize);
        CFRelease(source);
    }
    if (!image) {
        image = [[[NSImage alloc] initWithData:data] autorelease];
    }
    return TGMediaCacheImage(image, cacheKey);
}

void TGMediaImageLoaderSetCacheLimitBytes(NSUInteger bytes) {
    NSCache *cache = TGMediaImageCache();
    NSUInteger limit = bytes > 0 ? bytes : (64 * 1024 * 1024);
    [cache setTotalCostLimit:limit];
    [cache setCountLimit:(limit < (128 * 1024 * 1024)) ? 80 : 160];
}

void TGMediaImageLoaderClearCache(void) {
    [TGMediaImageCache() removeAllObjects];
    void (^notify)(void) = ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:TGMediaImageLoaderCacheDidClearNotification
                          object:nil];
    };
    if ([NSThread isMainThread]) {
        notify();
    } else {
        dispatch_async(dispatch_get_main_queue(), notify);
    }
}

NSImage *TGImageWithCorrectOrientationFromFile(NSString *path) {
    if (![path isKindOfClass:[NSString class]] || [path length] == 0) {
        return nil;
    }

    NSString *resolvedPath = [path stringByStandardizingPath];
    if (![resolvedPath length]) {
        return nil;
    }
    NSString *cacheKey = TGMediaFileCacheKey(resolvedPath, @"file-oriented", 2200);
    NSImage *cachedImage = TGMediaCachedImage(cacheKey);
    if (cachedImage) {
        return cachedImage;
    }

    CGImageSourceRef source = nil;
    CGImageRef imageRef = nil;
    NSDictionary *properties = nil;
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                     (CFStringRef)resolvedPath,
                                                     kCFURLPOSIXPathStyle,
                                                     false);
    if (fileURL) {
        source = CGImageSourceCreateWithURL(fileURL, NULL);
        CFRelease(fileURL);
    }
    if (!source) {
        return TGMediaCacheImage(TGWebPImageFromFile(resolvedPath), cacheKey);
    }

    properties = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    NSUInteger sourceWidth = 0;
    NSUInteger sourceHeight = 0;
    if ([properties isKindOfClass:[NSDictionary class]]) {
        id widthObject = [properties objectForKey:(NSString *)kCGImagePropertyPixelWidth];
        id heightObject = [properties objectForKey:(NSString *)kCGImagePropertyPixelHeight];
        if ([widthObject respondsToSelector:@selector(unsignedIntegerValue)]) {
            sourceWidth = [widthObject unsignedIntegerValue];
        }
        if ([heightObject respondsToSelector:@selector(unsignedIntegerValue)]) {
            sourceHeight = [heightObject unsignedIntegerValue];
        }
    }

    NSUInteger maxSourceSide = MAX(sourceWidth, sourceHeight);
    NSUInteger decodeMaxSide = 2200;
    if (maxSourceSide > decodeMaxSide) {
        NSDictionary *thumbnailOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                          (id)kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways,
                                          (id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform,
                                          (id)kCFBooleanFalse, kCGImageSourceShouldCacheImmediately,
                                          [NSNumber numberWithUnsignedInteger:decodeMaxSide], kCGImageSourceThumbnailMaxPixelSize,
                                          nil];
        imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (CFDictionaryRef)thumbnailOptions);
    } else {
        NSDictionary *imageOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                      (id)kCFBooleanFalse, kCGImageSourceShouldCacheImmediately,
                                      nil];
        imageRef = CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)imageOptions);
    }
    if (!imageRef) {
        if (properties) {
            CFRelease(properties);
        }
        CFRelease(source);
        return TGMediaCacheImage(TGWebPImageFromFile(resolvedPath), cacheKey);
    }

    NSUInteger orientation = 1;
    if ([properties isKindOfClass:[NSDictionary class]]) {
        id orientationObject = [properties objectForKey:(NSString *)kCGImagePropertyOrientation];
        if ([orientationObject respondsToSelector:@selector(integerValue)]) {
            NSUInteger value = (NSUInteger)[orientationObject integerValue];
            if (value >= 1 && value <= 8) {
                orientation = value;
            }
        }
    }
    if (properties) {
        CFRelease(properties);
    }

    if (orientation > 1 && maxSourceSide <= decodeMaxSide) {
        CGFloat imageWidth = (CGFloat)CGImageGetWidth(imageRef);
        CGFloat imageHeight = (CGFloat)CGImageGetHeight(imageRef);
        NSInteger maxPixelSize = (NSInteger)MAX(imageWidth, imageHeight);
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 (id)kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways,
                                 (id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform,
                                 [NSNumber numberWithInteger:maxPixelSize], kCGImageSourceThumbnailMaxPixelSize,
                                 nil];
        CGImageRef transformed = CGImageSourceCreateThumbnailAtIndex(source, 0, (CFDictionaryRef)options);
        if (transformed) {
            CGImageRelease(imageRef);
            imageRef = transformed;
        }
    }

    NSSize size = NSMakeSize((CGFloat)CGImageGetWidth(imageRef), (CGFloat)CGImageGetHeight(imageRef));
    NSImage *image = [[[NSImage alloc] initWithCGImage:imageRef size:size] autorelease];
    CGImageRelease(imageRef);
    CFRelease(source);
    return TGMediaCacheImage(image, cacheKey);
}

/* Keep expensive full-photo work serialized on legacy Macs. Cancelled queued
 * requests cost only a token check, and repeated photos reuse the same cache. */
static dispatch_queue_t TGOrientedPreviewQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ queue = dispatch_queue_create("org.telegraphica.oriented-preview", DISPATCH_QUEUE_SERIAL); });
    return queue;
}
static char TGPreparedPreviewImageKey;

static NSImage *TGPrepareOrientedPreviewImage(NSImage *image) {
    if (!image || objc_getAssociatedObject(image, &TGPreparedPreviewImageKey)) return image;
    CGImageRef source = [image CGImageForProposedRect:NULL context:nil hints:nil];
    if (!source) return image;
    size_t width = CGImageGetWidth(source), height = CGImageGetHeight(source);
    // ImageIO previews are already capped at2200. A larger WebP fallback is
    // already a decoded bitmap; avoid duplicating that exceptional allocation.
    if (!width || !height || width > 2200 || height > 2200) return image;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4,
        space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    if (!context) return image;
    // Force lazy ImageIO decompression before the first main-thread draw.
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, CGRectMake(0,0,width,height), source);
    CGImageRef bitmap = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    if (!bitmap) return image;
    NSImage *prepared = [[[NSImage alloc] initWithCGImage:bitmap size:[image size]] autorelease];
    CGImageRelease(bitmap);
    if (prepared) objc_setAssociatedObject(prepared, &TGPreparedPreviewImageKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return prepared ? prepared : image;
}

TGMediaImageLoadToken *TGLoadOrientedImageFromFileAsync(NSString *path,
                                                       TGMediaImageLoadCompletion completion) {
    if (![path isKindOfClass:[NSString class]] || ![path length] || !completion) return nil;
    TGMediaImageLoadToken *token = [[[TGMediaImageLoadToken alloc] initWithCompletion:completion] autorelease];
    NSString *pathCopy = [path copy];
    dispatch_async(TGOrientedPreviewQueue(), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSImage *image = nil;
        if (![token isCancelled]) {
            NSString *cacheKey = TGMediaFileCacheKey(pathCopy, @"file-oriented", 2200);
            image = TGPrepareOrientedPreviewImage(TGImageWithCorrectOrientationFromFile(pathCopy));
            TGMediaCacheImage(image, cacheKey);
        }
        // Dispatch copies/retains captured objects before this pool drains.
        dispatch_async(dispatch_get_main_queue(), ^{ [token finishWithImage:image]; });
        [pool drain];
    });
    [pathCopy release];
    return token;
}
