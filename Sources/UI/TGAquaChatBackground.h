#import <Cocoa/Cocoa.h>

extern NSString * const TGAquaChatBackgroundDidChangeNotification;

// Aspect-fill geometry: preserves the image ratio and crops centrally.
NSRect TGAquaChatBackgroundCoverRect(NSSize imageSize, NSRect viewportRect);

@interface TGAquaChatBackgroundStore : NSObject {
    NSUserDefaults *_defaults;
    NSString *_rootDirectory;
    NSMutableDictionary *_storedConfigurations;
    NSCache *_imageCache;
}
+ (TGAquaChatBackgroundStore *)sharedStore;
// Presets contain id/title_ru/title_en plus the configuration keys below.
+ (NSArray *)presets;
+ (NSDictionary *)defaultConfiguration;
+ (NSDictionary *)configurationForPresetIdentifier:(NSString *)identifier;
// Configuration kinds: color {color:"FFFFFF"}; texture additionally contains
// an approved texture name and opacity:Number; wallpaper contains one bundled
// identifier {wallpaper:"wallpaper-botanical"}. image contains
// image:"opaque-local-filename.png". Import returns the only accepted image form.
- (id)initWithDefaults:(NSUserDefaults *)defaults rootDirectory:(NSString *)directory;
// Common scope is nil/nil. A chat scope requires accountID > 0 and chatID != 0.
// Partial/invalid scopes cannot read or write another account's override.
- (NSDictionary *)effectiveConfigurationForAccountID:(NSNumber *)accountID chatID:(NSNumber *)chatID;
- (NSDictionary *)overrideConfigurationForAccountID:(NSNumber *)accountID chatID:(NSNumber *)chatID;
// nil resets the common background or removes the chat override (inherit).
- (BOOL)setConfiguration:(NSDictionary *)configuration forAccountID:(NSNumber *)accountID chatID:(NSNumber *)chatID error:(NSError **)error;
// Decodes a bounded static preview, normalizes orientation and copies it into
// private Application Support storage. Does not change the selected background.
- (NSDictionary *)importImageAtURL:(NSURL *)url error:(NSError **)error;
// Removes an imported preview only if no saved common/chat choice uses it.
- (void)discardImportedConfiguration:(NSDictionary *)configuration;
- (void)drawConfiguration:(NSDictionary *)configuration clipRect:(NSRect)clipRect viewportRect:(NSRect)viewportRect flipped:(BOOL)flipped;
- (void)drawBackgroundInClipRect:(NSRect)clipRect viewportRect:(NSRect)viewportRect flipped:(BOOL)flipped accountID:(NSNumber *)accountID chatID:(NSNumber *)chatID;
@end
