#import <Cocoa/Cocoa.h>

typedef void (^TGMediaImageLoadCompletion)(NSImage *image);

extern NSString * const TGMediaImageLoaderCacheDidClearNotification;

@interface TGMediaImageLoadToken : NSObject

- (void)cancel;
- (BOOL)isCancelled;

@end

NSImage *TGImageWithCorrectOrientationFromFile(NSString *path);
NSImage *TGImageThumbnailFromFile(NSString *path, NSUInteger maximumPixelSize);
NSImage *TGImageThumbnailFromData(NSData *data, NSUInteger maximumPixelSize);
NSImage *TGMediaCachedThumbnailFromFile(NSString *path, NSUInteger maximumPixelSize);
TGMediaImageLoadToken *TGLoadImageThumbnailFromFileAsync(NSString *path,
                                                         NSUInteger maximumPixelSize,
                                                         TGMediaImageLoadCompletion completion);
/* Static gallery previews: serial off-main decode and RGBA preparation, using
 * the same bounded, file-signature-aware cache as synchronous oriented images.
 * Completion is always asynchronous on main; cancellation suppresses delivery
 * and skips queued work that has not started. */
TGMediaImageLoadToken *TGLoadOrientedImageFromFileAsync(NSString *path,
                                                       TGMediaImageLoadCompletion completion);
void TGMediaImageLoaderSetCacheLimitBytes(NSUInteger bytes);
void TGMediaImageLoaderClearCache(void);
