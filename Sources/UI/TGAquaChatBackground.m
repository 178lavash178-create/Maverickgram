#import "TGAquaChatBackground.h"
#import <ImageIO/ImageIO.h>
#include <math.h>

NSString * const TGAquaChatBackgroundDidChangeNotification = @"TGAquaChatBackgroundDidChangeNotification";
static NSString * const TGBackgroundDefaultsKey = @"TGAquaChatBackgroundsV1";

static NSError *TGBackgroundError(NSString *text) {
    return [NSError errorWithDomain:@"TGAquaChatBackground" code:1 userInfo:[NSDictionary dictionaryWithObject:text forKey:NSLocalizedDescriptionKey]];
}

NSRect TGAquaChatBackgroundCoverRect(NSSize image, NSRect viewport) {
    if (!isfinite(image.width) || !isfinite(image.height) || image.width <= 0 || image.height <= 0 ||
        !isfinite(viewport.origin.x) || !isfinite(viewport.origin.y) ||
        !isfinite(viewport.size.width) || !isfinite(viewport.size.height) || NSIsEmptyRect(viewport)) return NSZeroRect;
    CGFloat scale = MAX(NSWidth(viewport)/image.width, NSHeight(viewport)/image.height);
    NSSize size = NSMakeSize(image.width*scale,image.height*scale);
    return NSMakeRect(NSMidX(viewport)-size.width/2,NSMidY(viewport)-size.height/2,size.width,size.height);
}

static BOOL TGBackgroundImageNameValid(id value) {
    if (![value isKindOfClass:[NSString class]] || [value length] < 5 || [value length] > 80 ||
        ![[value pathExtension] isEqualToString:@"png"] || ![[value lastPathComponent] isEqual:value]) return NO;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-."];
    return [value rangeOfCharacterFromSet:[allowed invertedSet]].location == NSNotFound;
}

static NSDictionary *TGBackgroundNormalizedConfiguration(id value) {
    if (![value isKindOfClass:[NSDictionary class]]) return nil;
    NSString *kind = [value objectForKey:@"kind"];
    if ([kind isEqual:@"image"]) {
        NSString *name = [value objectForKey:@"image"];
        return TGBackgroundImageNameValid(name) ? [NSDictionary dictionaryWithObjectsAndKeys:@"image",@"kind",name,@"image",nil] : nil;
    }
    NSString *color = [value objectForKey:@"color"];
    if (![color isKindOfClass:[NSString class]] || [color length] != 6 ||
        [color rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"] invertedSet]].location != NSNotFound) return nil;
    if ([kind isEqual:@"color"]) return [NSDictionary dictionaryWithObjectsAndKeys:@"color",@"kind",[color uppercaseString],@"color",nil];
    NSString *texture = [value objectForKey:@"texture"];
    if (![kind isEqual:@"texture"] || ![[NSArray arrayWithObjects:@"black-Linen",@"brushed_alu",@"brushed",nil] containsObject:texture]) return nil;
    id rawOpacity = [value objectForKey:@"opacity"];
    CGFloat opacity = [rawOpacity isKindOfClass:[NSNumber class]] ? [rawOpacity doubleValue] : 0.12;
    if (!isfinite(opacity)) return nil;
    return [NSDictionary dictionaryWithObjectsAndKeys:@"texture",@"kind",[color uppercaseString],@"color",texture,@"texture",
        [NSNumber numberWithDouble:MAX(0,MIN(1,opacity))],@"opacity",nil];
}

static NSString *TGBackgroundScope(NSNumber *account, NSNumber *chat) {
    if (!account && !chat) return @"common";
    if (![account isKindOfClass:[NSNumber class]] || ![chat isKindOfClass:[NSNumber class]] || [account longLongValue] <= 0 || [chat longLongValue] == 0) return nil;
    return [NSString stringWithFormat:@"%lld:%lld",[account longLongValue],[chat longLongValue]];
}

static NSImage *TGBackgroundLoadBoundedImage(NSURL *url) {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:NULL];
    if (![[attributes objectForKey:NSFileType] isEqual:NSFileTypeRegular] ||
        [[attributes objectForKey:NSFileSize] unsignedLongLongValue] == 0 ||
        [[attributes objectForKey:NSFileSize] unsignedLongLongValue] > 32ULL*1024*1024) return nil;
    CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url,NULL);
    if (!source) return nil;
    NSDictionary *properties = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
    double width = [[properties objectForKey:(id)kCGImagePropertyPixelWidth] doubleValue];
    double height = [[properties objectForKey:(id)kCGImagePropertyPixelHeight] doubleValue];
    [properties release];
    if (!isfinite(width) || !isfinite(height) || width < 1 || height < 1 || width > 30000 || height > 30000 || width*height > 100000000) {
        CFRelease(source); return nil;
    }
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
        (id)kCFBooleanTrue,(id)kCGImageSourceCreateThumbnailFromImageAlways,
        (id)kCFBooleanTrue,(id)kCGImageSourceCreateThumbnailWithTransform,
        [NSNumber numberWithInt:3072],(id)kCGImageSourceThumbnailMaxPixelSize,nil];
    CGImageRef decoded = CGImageSourceCreateThumbnailAtIndex(source,0,(CFDictionaryRef)options);
    CFRelease(source);
    if (!decoded) return nil;
    NSImage *image = [[[NSImage alloc] initWithCGImage:decoded size:NSMakeSize(CGImageGetWidth(decoded),CGImageGetHeight(decoded))] autorelease];
    CGImageRelease(decoded);
    return image;
}

@implementation TGAquaChatBackgroundStore
+ (TGAquaChatBackgroundStore *)sharedStore {
    static TGAquaChatBackgroundStore *store = nil;
    @synchronized(self) {
        if (!store) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES);
            NSString *base = [paths count] ? [paths objectAtIndex:0] : [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support"];
            store = [[self alloc] initWithDefaults:[NSUserDefaults standardUserDefaults] rootDirectory:[base stringByAppendingPathComponent:@"Telegraphica/AquaBackgrounds"]];
        }
    }
    return store;
}
+ (NSArray *)presets {
    static NSArray *presets = nil;
    if (!presets) {
        NSMutableArray *result = [NSMutableArray array];
        NSArray *colors = [NSArray arrayWithObjects:@"E7EEF4",@"F7F6F2",@"E5EDF5",@"E5EDE6",@"F3E9DC",@"EDE7F3",@"F4E6E9",@"D5DCE4",nil];
        NSArray *ru = [NSArray arrayWithObjects:@"Ледяной",@"Слоновая кость",@"Небесный",@"Шалфей",@"Песочный",@"Лаванда",@"Розовый",@"Серебряный",nil];
        NSArray *en = [NSArray arrayWithObjects:@"Ice",@"Ivory",@"Sky",@"Sage",@"Sand",@"Lavender",@"Rose",@"Silver",nil];
        for (NSUInteger i=0;i<[colors count];i++) [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithFormat:@"color-%lu",(unsigned long)i],@"id",[ru objectAtIndex:i],@"title_ru",[ru objectAtIndex:i],@"title_be",[en objectAtIndex:i],@"title_en",@"color",@"kind",[colors objectAtIndex:i],@"color",nil]];
        NSArray *textures = [NSArray arrayWithObjects:@"black-Linen",@"brushed_alu",@"brushed",nil];
        NSArray *textureRU = [NSArray arrayWithObjects:@"Светлый лён",@"Алюминий",@"Белый металл",nil];
        NSArray *textureEN = [NSArray arrayWithObjects:@"Light linen",@"Aluminium",@"White brushed",nil];
        for (NSUInteger i=0;i<[textures count];i++) [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithFormat:@"texture-%lu",(unsigned long)i],@"id",[textureRU objectAtIndex:i],@"title_ru",[textureRU objectAtIndex:i],@"title_be",[textureEN objectAtIndex:i],@"title_en",@"texture",@"kind",@"E7EEF4",@"color",[textures objectAtIndex:i],@"texture",[NSNumber numberWithDouble:i==0 ? 0.08 : 0.32],@"opacity",nil]];
        presets = [result copy];
    }
    return presets;
}
+ (NSDictionary *)configurationForPresetIdentifier:(NSString *)identifier {
    for (NSDictionary *preset in [self presets]) if ([[preset objectForKey:@"id"] isEqual:identifier]) return TGBackgroundNormalizedConfiguration(preset);
    return nil;
}
+ (NSDictionary *)defaultConfiguration { return [self configurationForPresetIdentifier:@"texture-0"]; }
- (id)initWithDefaults:(NSUserDefaults *)defaults rootDirectory:(NSString *)directory {
    self = [super init];
    if (self) {
        _defaults = [defaults retain]; _rootDirectory = [directory copy];
        _imageCache = [[NSCache alloc] init]; [_imageCache setCountLimit:8]; [_imageCache setTotalCostLimit:64*1024*1024];
        _storedConfigurations = [[NSMutableDictionary alloc] init];
        id saved = [_defaults objectForKey:TGBackgroundDefaultsKey];
        if ([saved isKindOfClass:[NSDictionary class]]) {
            for (id key in saved) {
                if (![key isKindOfClass:[NSString class]]) continue;
                NSArray *parts = [key componentsSeparatedByString:@":"];
                BOOL valid = [key isEqual:@"common"] || ([parts count]==2 && [key isEqual:TGBackgroundScope([NSNumber numberWithLongLong:[[parts objectAtIndex:0] longLongValue]],[NSNumber numberWithLongLong:[[parts objectAtIndex:1] longLongValue]])]);
                NSDictionary *config = TGBackgroundNormalizedConfiguration([saved objectForKey:key]);
                if (valid && config) [_storedConfigurations setObject:config forKey:key];
            }
        }
    }
    return self;
}
- (void)dealloc { [_defaults release]; [_rootDirectory release]; [_storedConfigurations release]; [_imageCache release]; [super dealloc]; }
- (NSDictionary *)overrideConfigurationForAccountID:(NSNumber *)account chatID:(NSNumber *)chat {
    NSString *scope = TGBackgroundScope(account,chat);
    return scope ? [_storedConfigurations objectForKey:scope] : nil;
}
- (NSDictionary *)effectiveConfigurationForAccountID:(NSNumber *)account chatID:(NSNumber *)chat {
    NSDictionary *override = [self overrideConfigurationForAccountID:account chatID:chat];
    return override ? override : ([_storedConfigurations objectForKey:@"common"] ? [_storedConfigurations objectForKey:@"common"] : [[self class] defaultConfiguration]);
}
- (BOOL)setConfiguration:(NSDictionary *)configuration forAccountID:(NSNumber *)account chatID:(NSNumber *)chat error:(NSError **)error {
    NSString *scope = TGBackgroundScope(account,chat);
    NSDictionary *normalized = configuration ? TGBackgroundNormalizedConfiguration(configuration) : nil;
    if (!scope || (configuration && !normalized)) { if (error) *error=TGBackgroundError(@"Invalid background or account/chat scope."); return NO; }
    if ([[normalized objectForKey:@"kind"] isEqual:@"image"] && !TGBackgroundLoadBoundedImage([NSURL fileURLWithPath:[_rootDirectory stringByAppendingPathComponent:[normalized objectForKey:@"image"]]])) {
        if (error) *error=TGBackgroundError(@"The local background image is missing or unreadable."); return NO;
    }
    NSDictionary *previous = [[_storedConfigurations objectForKey:scope] retain];
    if (normalized) [_storedConfigurations setObject:normalized forKey:scope]; else [_storedConfigurations removeObjectForKey:scope];
    [_defaults setObject:[NSDictionary dictionaryWithDictionary:_storedConfigurations] forKey:TGBackgroundDefaultsKey]; [_defaults synchronize];
    [self discardImportedConfiguration:previous];
    [previous release];
    [[NSNotificationCenter defaultCenter] postNotificationName:TGAquaChatBackgroundDidChangeNotification object:self];
    return YES;
}
- (NSDictionary *)importImageAtURL:(NSURL *)url error:(NSError **)error {
    NSImage *image = [url isFileURL] ? TGBackgroundLoadBoundedImage(url) : nil;
    if (!image) { if(error)*error=TGBackgroundError(@"Choose a valid image up to 32 MB and 100 megapixels."); return nil; }
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager createDirectoryAtPath:_rootDirectory withIntermediateDirectories:YES attributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0700] forKey:NSFilePosixPermissions] error:error]) return nil;
    NSArray *files = [manager contentsOfDirectoryAtPath:_rootDirectory error:NULL];
    // A cancelled chooser must not create an unbounded local image archive.
    NSUInteger imageCount=0; unsigned long long total=0;
    for (NSString *file in files) if (TGBackgroundImageNameValid(file)) {
        NSDictionary *attrs=[manager attributesOfItemAtPath:[_rootDirectory stringByAppendingPathComponent:file] error:NULL];
        total += [[attrs objectForKey:NSFileSize] unsignedLongLongValue]; imageCount++;
    }
    if (imageCount>=64 || total>256ULL*1024*1024) { if(error)*error=TGBackgroundError(@"The local background image library is full."); return nil; }
    CFUUIDRef uuid=CFUUIDCreate(NULL); NSString *identifier=(NSString *)CFUUIDCreateString(NULL,uuid); CFRelease(uuid);
    NSString *name=[identifier stringByAppendingPathExtension:@"png"]; [identifier release];
    NSURL *destination=[NSURL fileURLWithPath:[_rootDirectory stringByAppendingPathComponent:name]];
    CGImageRef cgImage=[image CGImageForProposedRect:NULL context:nil hints:nil];
    CGImageDestinationRef writer=CGImageDestinationCreateWithURL((CFURLRef)destination,CFSTR("public.png"),1,NULL);
    BOOL written=NO;
    if(writer) { CGImageDestinationAddImage(writer,cgImage,NULL); written=CGImageDestinationFinalize(writer); CFRelease(writer); }
    if(!written) { [manager removeItemAtURL:destination error:NULL]; if(error)*error=TGBackgroundError(@"Could not save the local background image."); return nil; }
    [manager setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0600] forKey:NSFilePosixPermissions] ofItemAtPath:[destination path] error:NULL];
    return [NSDictionary dictionaryWithObjectsAndKeys:@"image",@"kind",name,@"image",nil];
}
- (void)discardImportedConfiguration:(NSDictionary *)configuration {
    NSDictionary *normalized=TGBackgroundNormalizedConfiguration(configuration);
    NSString *name=[normalized objectForKey:@"image"];
    if(!name) return;
    for(NSDictionary *saved in [_storedConfigurations allValues]) if([[saved objectForKey:@"image"] isEqual:name]) return;
    NSString *path=[_rootDirectory stringByAppendingPathComponent:name];
    [_imageCache removeObjectForKey:path];
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}
- (void)drawConfiguration:(NSDictionary *)configuration clipRect:(NSRect)clip viewportRect:(NSRect)viewport flipped:(BOOL)flipped {
    if(NSIsEmptyRect(clip) || NSIsEmptyRect(viewport)) return;
    NSDictionary *config=TGBackgroundNormalizedConfiguration(configuration);
    if(!config) config=[[self class] defaultConfiguration];
    [NSGraphicsContext saveGraphicsState]; NSRectClip(NSIntersectionRect(clip,viewport));
    unsigned int rgb=0xE7EEF4; NSString *hex=[config objectForKey:@"color"];
    if(hex) [[NSScanner scannerWithString:hex] scanHexInt:&rgb];
    [[NSColor colorWithCalibratedRed:((rgb>>16)&255)/255.0 green:((rgb>>8)&255)/255.0 blue:(rgb&255)/255.0 alpha:1] set]; NSRectFill(viewport);
    NSString *kind=[config objectForKey:@"kind"];
    if([kind isEqual:@"image"]) {
        NSString *path=[_rootDirectory stringByAppendingPathComponent:[config objectForKey:@"image"]];
        id cached=[_imageCache objectForKey:path];
        NSImage *image=[cached isKindOfClass:[NSImage class]] ? cached : nil;
        if(!cached) { image=TGBackgroundLoadBoundedImage([NSURL fileURLWithPath:path]); [_imageCache setObject:image ? (id)image : (id)[NSNull null] forKey:path cost:image ? (NSUInteger)([image size].width*[image size].height*4) : 1]; }
        if(image) [image drawInRect:TGAquaChatBackgroundCoverRect([image size],viewport) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:flipped hints:nil];
    } else if([kind isEqual:@"texture"]) {
        NSString *texture=[config objectForKey:@"texture"];
        NSString *key=[@"texture:" stringByAppendingString:texture]; id cached=[_imageCache objectForKey:key];
        NSImage *image=[cached isKindOfClass:[NSImage class]] ? cached : nil;
        if(!cached) { NSString *path=[[NSBundle mainBundle] pathForResource:texture ofType:@"png" inDirectory:@"Textures"]; image=path ? [[[NSImage alloc] initWithContentsOfFile:path] autorelease] : nil; [_imageCache setObject:image ? (id)image : (id)[NSNull null] forKey:key cost:image ? (NSUInteger)([image size].width*[image size].height*4) : 1]; }
        if(image) {
            // Pattern phase is device-based. The clip already translates its document
            // bounds into viewport coordinates; adding that origin scrolls the tile.
            [[NSGraphicsContext currentContext] setPatternPhase:NSZeroPoint];
            CGContextSetAlpha((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],[[config objectForKey:@"opacity"] doubleValue]);
            [[NSColor colorWithPatternImage:image] set];
            NSRectFillUsingOperation(viewport,NSCompositeSourceOver);
        }
    }
    [NSGraphicsContext restoreGraphicsState];
}
- (void)drawBackgroundInClipRect:(NSRect)clip viewportRect:(NSRect)viewport flipped:(BOOL)flipped accountID:(NSNumber *)account chatID:(NSNumber *)chat {
    [self drawConfiguration:[self effectiveConfigurationForAccountID:account chatID:chat] clipRect:clip viewportRect:viewport flipped:flipped];
}
@end
