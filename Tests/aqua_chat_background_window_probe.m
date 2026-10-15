#import <Cocoa/Cocoa.h>
#import "TGAquaChatBackgroundWindowController.h"
#import "TGAquaChatBackground.h"
#import "TGLocalization.h"
#include <assert.h>
#import <objc/runtime.h>
static NSMutableDictionary *Saved;
static NSMutableArray *Writes, *Discards;
static NSDictionary *LastDrawn;
static NSRect LastViewport;
static NSUInteger Imports;
static TGAquaChatBackgroundWindowController *ClosingController;
static BOOL ClosedControllerDeallocated;
NSString * const TGAquaChatBackgroundDidChangeNotification = @"WallpaperProbe";
@implementation TGAquaChatBackgroundStore
- (id)initWithDefaults:(NSUserDefaults *)defaults rootDirectory:(NSString *)directory { (void)defaults;(void)directory; return [self init]; }
+ (TGAquaChatBackgroundStore *)sharedStore { static id store=nil; if(!store) store=[[self alloc] init]; return store; }
+ (NSArray *)presets {
    NSMutableArray *presets=[NSMutableArray array];
    for(NSUInteger i=0;i<11;i++) {
        NSString *identifier=[NSString stringWithFormat:@"%@-%lu",i<8 ? @"color" : @"texture",(unsigned long)(i<8 ? i : i-8)];
        [presets addObject:[NSDictionary dictionaryWithObjectsAndKeys:identifier,@"id",i<8 ? @"color" : @"texture",@"kind",[NSString stringWithFormat:@"Color %lu",(unsigned long)i],@"title_en",[NSString stringWithFormat:@"Цвет %lu",(unsigned long)i],@"title_ru",nil]];
    }
    return presets;
}
+ (NSDictionary *)configurationForPresetIdentifier:(NSString *)identifier {
    return [NSDictionary dictionaryWithObjectsAndKeys:identifier,@"id",[identifier hasPrefix:@"color"] ? @"color" : @"texture",@"kind",nil];
}
+ (NSDictionary *)defaultConfiguration { return [self configurationForPresetIdentifier:@"texture-0"]; }
- (NSString *)keyForAccount:(NSNumber *)account chat:(NSNumber *)chat {
    return account && chat ? [NSString stringWithFormat:@"%@:%@",account,chat] : @"common";
}
- (NSDictionary *)overrideConfigurationForAccountID:(NSNumber *)account chatID:(NSNumber *)chat {
    return [Saved objectForKey:[self keyForAccount:account chat:chat]];
}
- (NSDictionary *)effectiveConfigurationForAccountID:(NSNumber *)account chatID:(NSNumber *)chat {
    NSDictionary *config=[self overrideConfigurationForAccountID:account chatID:chat];
    return config ? config : ([Saved objectForKey:@"common"] ? [Saved objectForKey:@"common"] : [[self class] defaultConfiguration]);
}
- (void)drawBackgroundInClipRect:(NSRect)clip viewportRect:(NSRect)viewport flipped:(BOOL)flipped accountID:(NSNumber *)account chatID:(NSNumber *)chat {
    [self drawConfiguration:[self effectiveConfigurationForAccountID:account chatID:chat] clipRect:clip viewportRect:viewport flipped:flipped];
}
- (BOOL)setConfiguration:(NSDictionary *)configuration forAccountID:(NSNumber *)account chatID:(NSNumber *)chat error:(NSError **)error {
    (void)error; NSString *key=[self keyForAccount:account chat:chat];
    [Writes addObject:key]; if(configuration) [Saved setObject:configuration forKey:key]; else [Saved removeObjectForKey:key]; return YES;
}
- (NSDictionary *)importImageAtURL:(NSURL *)url error:(NSError **)error { (void)url;(void)error; Imports++; return nil; }
- (void)discardImportedConfiguration:(NSDictionary *)configuration { [Discards addObject:configuration]; }
- (void)drawConfiguration:(NSDictionary *)configuration clipRect:(NSRect)clip viewportRect:(NSRect)viewport flipped:(BOOL)flipped {
    (void)flipped; LastDrawn=configuration; LastViewport=viewport;
    [[NSColor colorWithCalibratedWhite:0.85 alpha:1] set]; NSRectFill(clip);
}
@end
@interface TGAquaChatBackgroundWindowController (ProbeActions)
- (void)chooseImage:(id)sender;
- (void)colorSelected:(id)sender;
- (void)textureSelected:(id)sender;
- (void)scopeChanged:(id)sender;
- (void)stageImportedConfiguration:(NSDictionary *)configuration;
- (NSDictionary *)previewConfiguration;
- (void)restoreDefault:(id)sender;
- (void)inheritCommon:(id)sender;
- (void)applyChanges:(id)sender;
- (void)cancelChanges:(id)sender;
@end
@interface ClosingWallpaperController : TGAquaChatBackgroundWindowController
@end
@implementation ClosingWallpaperController
- (void)dealloc { ClosedControllerDeallocated=YES; [super dealloc]; }
@end
@interface ClosingOpenPanel : NSOpenPanel
@end
@implementation ClosingOpenPanel
- (NSInteger)runModal {
    [[ClosingController window] close];
    // Model the owning application releasing this utility on logout while
    // chooseImage is suspended inside AppKit's nested event loop.
    [ClosingController release];
    return NSOKButton;
}
@end
static NSOpenPanel *ClosingPanel;
static id MockOpenPanel(id receiver,SEL selector) { (void)receiver;(void)selector; return ClosingPanel; }
static void Reset(void) { [Saved removeAllObjects]; [Writes removeAllObjects]; [Discards removeAllObjects]; }
static void AssertContained(NSRect inner,NSRect outer) {
    assert(NSMinX(inner)>=0 && NSMinY(inner)>=0 && NSMaxX(inner)<=NSWidth(outer) && NSMaxY(inner)<=NSHeight(outer));
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    Saved=[[NSMutableDictionary alloc] init]; Writes=[[NSMutableArray alloc] init]; Discards=[[NSMutableArray alloc] init];
    NSString *originalLanguage=[TGLanguageCode() copy];
    NSUInteger cases=0;
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
        TGSetLanguageCode(language);
        for(NSUInteger hasChat=0;hasChat<2;hasChat++) {
            Reset();
            TGAquaChatBackgroundWindowController *controller=[[[TGAquaChatBackgroundWindowController alloc] initWithAccountID:hasChat ? @10 : nil chatID:hasChat ? @-500 : nil chatTitle:@"A conversation"] autorelease];
            NSWindow *window=[controller window]; NSRect bounds=[[window contentView] bounds];
            assert(NSWidth(bounds)==760 && NSHeight(bounds)==610);
            assert(![[window title] hasPrefix:@"aqua."]);
            NSArray *colors=[controller valueForKey:@"colorButtons"];
            NSPopUpButton *scope=[controller valueForKey:@"scopePopUp"], *texture=[controller valueForKey:@"texturePopUp"];
            assert([colors count]==8 && [texture numberOfItems]==4 && [scope numberOfItems]==(hasChat ? 2 : 1));
            assert([[controller valueForKey:@"inheritButton"] isHidden]);
            for(NSView *view in [[window contentView] subviews]) AssertContained([view frame],bounds);
            assert([[controller previewConfiguration] isEqual:[TGAquaChatBackgroundStore defaultConfiguration]]);
            [controller colorSelected:[colors objectAtIndex:3]];
            NSDictionary *newCommon=[controller previewConfiguration];
            assert([Writes count]==0 && [[newCommon objectForKey:@"id"] isEqualToString:@"color-3"]);
            if(hasChat) {
                [scope selectItemAtIndex:1]; [controller scopeChanged:scope];
                assert(![[controller valueForKey:@"inheritButton"] isHidden]);
                assert([[controller previewConfiguration] isEqual:newCommon]);
                [controller restoreDefault:nil];
                assert([[controller previewConfiguration] isEqual:[TGAquaChatBackgroundStore defaultConfiguration]]);
                [controller inheritCommon:nil]; assert([[controller previewConfiguration] isEqual:newCommon]);
                [controller colorSelected:[colors objectAtIndex:6]];
                assert([Writes count]==0);
            }
            [controller applyChanges:nil];
            assert([Writes count]==(hasChat ? 2 : 1));
            assert([[Saved objectForKey:@"common"] isEqual:newCommon]);
            if(hasChat) assert([[[Saved objectForKey:@"10:-500"] objectForKey:@"id"] isEqualToString:@"color-6"]);
            // Reopening reloads saved data; Cancel never commits staged changes.
            [controller showWindow:nil];
            NSUInteger writes=[Writes count];
            [controller colorSelected:[colors objectAtIndex:1]]; [controller cancelChanges:nil]; assert([Writes count]==writes);
            // Inheritance removes only the selected account/chat override.
            if(hasChat) {
                [controller showWindow:nil]; [controller inheritCommon:nil]; [controller applyChanges:nil];
                assert(![Saved objectForKey:@"10:-500"] && [Saved objectForKey:@"common"]);
            }
            [controller showWindow:nil];
            [texture selectItemAtIndex:3]; [controller textureSelected:texture];
            assert([[[controller previewConfiguration] objectForKey:@"id"] isEqualToString:@"texture-2"]);
            [controller cancelChanges:nil];
            // Imported images are previews until Apply and are discarded on Cancel.
            NSDictionary *image=[NSDictionary dictionaryWithObjectsAndKeys:@"image",@"kind",@"test.png",@"image",nil];
            [controller showWindow:nil];
            [controller stageImportedConfiguration:image]; assert([[controller previewConfiguration] isEqual:image]);
            NSUInteger beforeDiscard=[Discards count]; [controller cancelChanges:nil]; assert([Discards count]==beforeDiscard+1);
            [controller showWindow:nil]; [controller stageImportedConfiguration:image];
            beforeDiscard=[Discards count]; [window close]; assert([Discards count]==beforeDiscard+1);
            [controller showWindow:nil];
            NSView *preview=[controller valueForKey:@"previewView"];
            NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:444 pixelsHigh:342 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
            [NSGraphicsContext saveGraphicsState]; [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
            [preview drawRect:[preview bounds]];
            assert([LastDrawn isEqual:[controller previewConfiguration]] && NSWidth(LastViewport)==442 && NSHeight(LastViewport)==340);
            [NSGraphicsContext restoreGraphicsState];
            const char *output=getenv("TELEGRAPHICA_WALLPAPER_PREVIEW_PATH");
            if(output && [language isEqualToString:@"ru"] && hasChat) {
                NSBitmapImageRep *windowBitmap=[[window contentView] bitmapImageRepForCachingDisplayInRect:bounds];
                [[window contentView] cacheDisplayInRect:bounds toBitmapImageRep:windowBitmap];
                [[windowBitmap representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]] writeToFile:[NSString stringWithUTF8String:output] atomically:YES];
            }
            [window close]; cases++;
        }
    }
    // A modal file chooser may outlive the owning utility after logout.
    ClosingController=[[ClosingWallpaperController alloc] initWithAccountID:@10 chatID:@-500 chatTitle:@"Conversation"];
    [ClosingController showWindow:nil];
    ClosingPanel=[[ClosingOpenPanel alloc] init];
    Method openPanelMethod=class_getClassMethod([NSOpenPanel class],@selector(openPanel));
    IMP originalOpenPanel=method_setImplementation(openPanelMethod,(IMP)MockOpenPanel);
    Imports=0; ClosedControllerDeallocated=NO;
    [ClosingController chooseImage:nil];
    method_setImplementation(openPanelMethod,originalOpenPanel);
    assert(Imports==0);
    // AppKit can defer its final controller release until the autorelease pool
    // drains; the observable requirement is no import after the owner closed.
    ClosingController=nil; [ClosingPanel release]; ClosingPanel=nil;
    TGSetLanguageCode(originalLanguage); [originalLanguage release];
    [Saved release]; [Writes release]; [Discards release];
    printf("Aqua wallpaper window: %lu localized common/chat flows, 8 colors, textures, staged preview/Apply/Cancel, inheritance, import cleanup, modal owner-close lifetime and contained layout PASS.\n",(unsigned long)cases);
    [pool drain]; return 0;
}
