#import <Cocoa/Cocoa.h>
#import <ImageIO/ImageIO.h>
#import "TGAquaChatBackground.h"
#include <math.h>

static NSUInteger checks = 0;
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr,"Aqua background probe failed: %s\n",message); exit(1); }
}

// An isolated defaults implementation verifies serialized values without ever
// modifying the user's real Telegraphica preferences.
@interface TGBackgroundProbeDefaults : NSUserDefaults {
    NSMutableDictionary *_values;
}
@end
@implementation TGBackgroundProbeDefaults
- (id)init { self=[super init]; if(self) _values=[[NSMutableDictionary alloc] init]; return self; }
- (id)objectForKey:(NSString *)key { return [_values objectForKey:key]; }
- (void)setObject:(id)value forKey:(NSString *)key { [_values setObject:value forKey:key]; }
- (BOOL)synchronize { return YES; }
- (void)dealloc { [_values release]; [super dealloc]; }
@end

@interface TGBackgroundProbeObserver : NSObject { @public NSUInteger count; }
- (void)changed:(NSNotification *)notification;
@end
@implementation TGBackgroundProbeObserver
- (void)changed:(NSNotification *)notification { (void)notification; count++; }
@end

static void WriteImage(NSString *path) {
    unsigned char pixels[]={255,0,0,255, 0,255,0,255, 0,0,255,255};
    CGColorSpaceRef colors=CGColorSpaceCreateDeviceRGB();
    CGContextRef context=CGBitmapContextCreate(pixels,3,1,8,12,colors,(CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGImageRef image=CGBitmapContextCreateImage(context);
    CGImageDestinationRef destination=CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path],CFSTR("public.png"),1,NULL);
    CGImageDestinationAddImage(destination,image,NULL);
    Check(CGImageDestinationFinalize(destination),"write deterministic RGB source image");
    CFRelease(destination); CGImageRelease(image); CGContextRelease(context); CGColorSpaceRelease(colors);
}

static NSBitmapImageRep *Render(TGAquaChatBackgroundStore *store, NSDictionary *configuration, BOOL flipped) {
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:60 pixelsHigh:60 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:240 bitsPerPixel:32] autorelease];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    [store drawConfiguration:configuration clipRect:NSMakeRect(0,0,60,60) viewportRect:NSMakeRect(0,0,60,60) flipped:flipped];
    [NSGraphicsContext restoreGraphicsState];
    return bitmap;
}

int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSString *root=[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    NSFileManager *files=[NSFileManager defaultManager];
    [files createDirectoryAtPath:root withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString *library=[root stringByAppendingPathComponent:@"Imported"];
    TGBackgroundProbeDefaults *defaults=[[[TGBackgroundProbeDefaults alloc] init] autorelease];
    TGAquaChatBackgroundStore *store=[[[TGAquaChatBackgroundStore alloc] initWithDefaults:defaults rootDirectory:library] autorelease];
    TGBackgroundProbeObserver *observer=[[[TGBackgroundProbeObserver alloc] init] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(changed:) name:TGAquaChatBackgroundDidChangeNotification object:store];
    Check([[TGAquaChatBackgroundStore presets] count]==19,"nine colors, five approved textures and five bundled wallpapers");
    NSUInteger colorCount=0,textureCount=0,wallpaperCount=0;
    for(NSDictionary *preset in [TGAquaChatBackgroundStore presets]) {
        Check([[preset objectForKey:@"title_ru"] length]>0 && [[preset objectForKey:@"title_be"] length]>0 && [[preset objectForKey:@"title_en"] length]>0,"preset labels are available in all three languages");
        Check([TGAquaChatBackgroundStore configurationForPresetIdentifier:[preset objectForKey:@"id"]]!=nil,"every preset produces a valid configuration");
        if([[preset objectForKey:@"kind"] isEqual:@"color"]) colorCount++;
        if([[preset objectForKey:@"kind"] isEqual:@"texture"]) textureCount++;
        if([[preset objectForKey:@"kind"] isEqual:@"wallpaper"]) wallpaperCount++;
    }
    Check(colorCount==9 && textureCount==5 && wallpaperCount==5,"each gallery category has its expected content");
    NSDictionary *common=[TGAquaChatBackgroundStore configurationForPresetIdentifier:@"color-3"];
    NSDictionary *specific=[TGAquaChatBackgroundStore configurationForPresetIdentifier:@"color-5"];
    Check([[store effectiveConfigurationForAccountID:nil chatID:nil] isEqual:[TGAquaChatBackgroundStore defaultConfiguration]],"fresh defaults use the standard background");
    Check([[[TGAquaChatBackgroundStore defaultConfiguration] objectForKey:@"kind"] isEqual:@"color"] && [[[TGAquaChatBackgroundStore defaultConfiguration] objectForKey:@"color"] isEqual:@"FFFFFF"],"standard background is pure white without a texture");
    NSColor *white=[[Render(store,[TGAquaChatBackgroundStore defaultConfiguration],NO) colorAtX:30 y:30] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    Check([white redComponent]>0.99 && [white greenComponent]>0.99 && [white blueComponent]>0.99,"standard background renders as white pixels");
    Check([[[TGAquaChatBackgroundStore configurationForPresetIdentifier:@"color-0"] objectForKey:@"color"] isEqual:@"E7EEF4"],"existing color identifiers retain their original color");
    Check([store setConfiguration:common forAccountID:nil chatID:nil error:NULL],"set common background");
    Check([store setConfiguration:specific forAccountID:@1 chatID:@-20 error:NULL],"set account-specific group background");
    Check([[store effectiveConfigurationForAccountID:@1 chatID:@-20] isEqual:specific],"matching chat uses override");
    Check([[store effectiveConfigurationForAccountID:@2 chatID:@-20] isEqual:common],"same chat under another account cannot see override");
    Check([[store effectiveConfigurationForAccountID:nil chatID:@-20] isEqual:common],"unknown account cannot read another account's chat background");
    Check(![store setConfiguration:specific forAccountID:nil chatID:@-20 error:NULL],"reject a chat write without account identity");
    Check(![store setConfiguration:specific forAccountID:@1 chatID:nil error:NULL],"reject partial account scope");
    Check(![store setConfiguration:specific forAccountID:@0 chatID:@-20 error:NULL],"reject invalid account identity");
    Check(observer->count==2,"only accepted changes notify views");
    TGAquaChatBackgroundStore *restored=[[[TGAquaChatBackgroundStore alloc] initWithDefaults:defaults rootDirectory:library] autorelease];
    Check([[restored effectiveConfigurationForAccountID:@1 chatID:@-20] isEqual:specific] && [[restored effectiveConfigurationForAccountID:@2 chatID:@-20] isEqual:common],"serialized state survives store reconstruction with account scope intact");
    Check([store setConfiguration:nil forAccountID:@1 chatID:@-20 error:NULL] && [[store effectiveConfigurationForAccountID:@1 chatID:@-20] isEqual:common],"reset chat inherits common background");
    Check(![store setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:@"image",@"kind",@"../outside.png",@"image",nil] forAccountID:nil chatID:nil error:NULL],"reject image path traversal");
    Check(![store setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:@"color",@"kind",@"red",@"color",nil] forAccountID:nil chatID:nil error:NULL],"reject malformed color");
    Check(![store setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:@"texture",@"kind",@"FFFFFF",@"color",@"../image",@"texture",nil] forAccountID:nil chatID:nil error:NULL],"reject unapproved texture");
    Check(![store setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:@"wallpaper",@"kind",@"../wallpaper-stars",@"wallpaper",nil] forAccountID:nil chatID:nil error:NULL],"bundled wallpaper rejects path traversal");
    Check(![store setConfiguration:[NSDictionary dictionaryWithObjectsAndKeys:@"wallpaper",@"kind",@"not-approved",@"wallpaper",nil] forAccountID:nil chatID:nil error:NULL],"bundled wallpaper rejects unknown identifiers");
    Check(![store setConfiguration:[NSDictionary dictionaryWithObject:@"wallpaper" forKey:@"kind"] forAccountID:nil chatID:nil error:NULL],"bundled wallpaper requires a valid identifier");
    NSDictionary *bundled=[TGAquaChatBackgroundStore configurationForPresetIdentifier:@"wallpaper-stars"];
    Check([store setConfiguration:bundled forAccountID:@2 chatID:@-20 error:NULL],"bundled wallpaper can be saved independently of imported files");
    Check([[store effectiveConfigurationForAccountID:@2 chatID:@-20] isEqual:bundled],"bundled wallpaper retains its stable identifier");
    [store discardImportedConfiguration:bundled];
    Check([[store effectiveConfigurationForAccountID:@2 chatID:@-20] isEqual:bundled],"import cleanup never removes a bundled selection");
    Render(store,bundled,NO); Render(store,bundled,NO);
    NSCache *imageCache=[store valueForKey:@"imageCache"];
    Check([imageCache objectForKey:@"wallpaper:wallpaper-stars"]!=nil,"bundled image or missing-resource fallback is cached");
    Check([imageCache countLimit]<=8 && [imageCache totalCostLimit]<=64*1024*1024,"wallpapers share a bounded image cache");
    BOOL bundledAvailable=NO;
    for(NSString *extension in [NSArray arrayWithObjects:@"png",@"jpg",@"jpeg",nil]) if([[NSBundle mainBundle] pathForResource:@"wallpaper-stars" ofType:extension inDirectory:@"Wallpapers"]) bundledAvailable=YES;
    if(!bundledAvailable) {
        NSColor *missing=[[Render(store,bundled,NO) colorAtX:30 y:30] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        Check([missing redComponent]>0.99 && [missing greenComponent]>0.99 && [missing blueComponent]>0.99,"missing optional bundled artwork falls back to pure white");
    }
    NSString *bad=[root stringByAppendingPathComponent:@"bad.png"];
    [@"not a bitmap" writeToFile:bad atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    Check(![store importImageAtURL:[NSURL fileURLWithPath:bad] error:NULL],"reject malformed image");
    Check(![store importImageAtURL:[NSURL URLWithString:@"https://example.invalid/background.png"] error:NULL],"import never fetches a remote URL");
    NSString *source=[root stringByAppendingPathComponent:@"source.png"]; WriteImage(source);
    NSDictionary *import=[store importImageAtURL:[NSURL fileURLWithPath:source] error:NULL];
    NSString *copied=[library stringByAppendingPathComponent:[import objectForKey:@"image"]];
    Check(import && [files fileExistsAtPath:copied] && ![copied isEqual:source],"import copies a normalized bitmap to dedicated local storage");
    [files removeItemAtPath:source error:NULL];
    Check([store setConfiguration:import forAccountID:@1 chatID:@-20 error:NULL],"removing original image does not break imported background");
    [store discardImportedConfiguration:import];
    Check([files fileExistsAtPath:copied],"discard cannot delete an image used by a saved chat");
    Check([store setConfiguration:import forAccountID:nil chatID:nil error:NULL],"same imported image can serve common and chat backgrounds");
    Check([store setConfiguration:common forAccountID:nil chatID:nil error:NULL] && [files fileExistsAtPath:copied],"replacing common background keeps a shared image used by a chat");
    for(NSUInteger flip=0;flip<2;flip++) {
        NSBitmapImageRep *bitmap=Render(store,import,flip);
        NSColor *middle=[[bitmap colorAtX:30 y:30] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        Check([middle greenComponent]>[middle redComponent] && [middle greenComponent]>[middle blueComponent],"cover preserves the center of a wide RGB source without stretching");
    }
    [store setConfiguration:nil forAccountID:@1 chatID:@-20 error:NULL];
    Check(![files fileExistsAtPath:copied],"reset automatically removes imported image after its last saved reference disappears");
    [store discardImportedConfiguration:import];
    Check(![files fileExistsAtPath:copied],"cancelled/unreferenced import can be removed safely");
    Check(![store setConfiguration:import forAccountID:nil chatID:nil error:NULL],"missing imported files cannot become a selected background");
    // Fresh store must draw a readable fallback when an imported file vanishes.
    NSColor *fallback=[[Render(restored,import,NO) colorAtX:0 y:0] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    Check([fallback redComponent]>0.8 && [fallback greenComponent]>0.8 && [fallback blueComponent]>0.8,"missing local artwork falls back to a bright background");
    NSSize sizes[]={ {300,100},{100,300},{100,100},{1,10000} };
    NSRect viewport=NSMakeRect(50,100,320,240);
    for(NSUInteger i=0;i<4;i++) {
        NSRect cover=TGAquaChatBackgroundCoverRect(sizes[i],viewport);
        Check(NSContainsRect(cover,viewport),"cover fills viewport in portrait and landscape");
        Check(fabs(NSWidth(cover)/NSHeight(cover)-sizes[i].width/sizes[i].height)<0.001,"cover preserves aspect ratio");
        Check(fabs(NSMidX(cover)-NSMidX(viewport))<0.001 && fabs(NSMidY(cover)-NSMidY(viewport))<0.001,"cover crops centrally and preserves viewport origin");
    }
    Check(NSIsEmptyRect(TGAquaChatBackgroundCoverRect(NSZeroSize,viewport)),"invalid source size has no drawing rect");
    Check(NSIsEmptyRect(TGAquaChatBackgroundCoverRect(NSMakeSize(NAN,1),viewport)),"nonfinite source size has no drawing rect");
    Check(NSIsEmptyRect(TGAquaChatBackgroundCoverRect(NSMakeSize(1,1),NSZeroRect)),"empty viewport has no drawing rect");
    // Untrusted persisted data must not create a scope alias or unsafe path.
    NSDictionary *malformed=[NSDictionary dictionaryWithObjectsAndKeys:
        specific,@"1x:-20", specific,@"0:-20", [NSNull null],@"common",
        [NSDictionary dictionaryWithObjectsAndKeys:@"image",@"kind",@"../../outside.png",@"image",nil],@"1:-20",nil];
    [defaults setObject:malformed forKey:@"TGAquaChatBackgroundsV1"];
    TGAquaChatBackgroundStore *sanitized=[[[TGAquaChatBackgroundStore alloc] initWithDefaults:defaults rootDirectory:library] autorelease];
    Check(![sanitized overrideConfigurationForAccountID:@1 chatID:@-20],"malformed persisted scopes and image paths are discarded");
    Check([[sanitized effectiveConfigurationForAccountID:nil chatID:nil] isEqual:[TGAquaChatBackgroundStore defaultConfiguration]],"malformed persisted common configuration restores default");
    NSString *large=[root stringByAppendingPathComponent:@"too-large.png"];
    [files createFileAtPath:large contents:[NSData data] attributes:nil];
    NSFileHandle *handle=[NSFileHandle fileHandleForWritingAtPath:large]; [handle truncateFileAtOffset:33ULL*1024*1024]; [handle closeFile];
    Check(![store importImageAtURL:[NSURL fileURLWithPath:large] error:NULL],"reject oversized input before decoding");
    TGBackgroundProbeDefaults *oldDefaults=[[[TGBackgroundProbeDefaults alloc] init] autorelease];
    NSDictionary *oldLinen=[TGAquaChatBackgroundStore configurationForPresetIdentifier:@"texture-0"];
    [oldDefaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:oldLinen,@"common",oldLinen,@"1:-20",specific,@"2:-20",import,@"3:-20",nil] forKey:@"TGAquaChatBackgroundsV1"];
    TGAquaChatBackgroundStore *migrated=[[[TGAquaChatBackgroundStore alloc] initWithDefaults:oldDefaults rootDirectory:library] autorelease];
    Check([[migrated effectiveConfigurationForAccountID:nil chatID:nil] isEqual:[TGAquaChatBackgroundStore defaultConfiguration]],"old saved common linen default migrates to white");
    Check([[migrated overrideConfigurationForAccountID:@1 chatID:@-20] isEqual:oldLinen],"migration preserves explicitly saved chat linen");
    Check([[migrated overrideConfigurationForAccountID:@2 chatID:@-20] isEqual:specific] && [[migrated overrideConfigurationForAccountID:@3 chatID:@-20] isEqual:import],"migration preserves other chat colors and imported image references");
    Check([[oldDefaults objectForKey:@"TGAquaChatBackgroundDefaultVersion"] integerValue]==2,"new default migration records its completed version");
    [migrated setConfiguration:oldLinen forAccountID:nil chatID:nil error:NULL];
    TGAquaChatBackgroundStore *secondStart=[[[TGAquaChatBackgroundStore alloc] initWithDefaults:oldDefaults rootDirectory:library] autorelease];
    Check([[secondStart effectiveConfigurationForAccountID:nil chatID:nil] isEqual:oldLinen],"migration runs once so a later deliberate linen choice survives restart");
    TGBackgroundProbeDefaults *customDefaults=[[[TGBackgroundProbeDefaults alloc] init] autorelease];
    [customDefaults setObject:[NSDictionary dictionaryWithObject:specific forKey:@"common"] forKey:@"TGAquaChatBackgroundsV1"];
    TGAquaChatBackgroundStore *custom=[[[TGAquaChatBackgroundStore alloc] initWithDefaults:customDefaults rootDirectory:library] autorelease];
    Check([[custom effectiveConfigurationForAccountID:nil chatID:nil] isEqual:specific],"new default migration preserves a custom common color");
    NSMutableDictionary *customLinen=[NSMutableDictionary dictionaryWithDictionary:oldLinen]; [customLinen setObject:@0.09 forKey:@"opacity"];
    TGBackgroundProbeDefaults *tunedDefaults=[[[TGBackgroundProbeDefaults alloc] init] autorelease];
    [tunedDefaults setObject:[NSDictionary dictionaryWithObject:customLinen forKey:@"common"] forKey:@"TGAquaChatBackgroundsV1"];
    TGAquaChatBackgroundStore *tuned=[[[TGAquaChatBackgroundStore alloc] initWithDefaults:tunedDefaults rootDirectory:library] autorelease];
    Check([[tuned effectiveConfigurationForAccountID:nil chatID:nil] isEqual:customLinen],"migration matches exact old common default and preserves a tuned texture");
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    [files removeItemAtPath:root error:NULL];
    printf("Aqua chat background probe passed: %lu checks.\n",(unsigned long)checks);
    [pool drain]; return 0;
}
