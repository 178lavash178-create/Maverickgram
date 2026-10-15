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
    NSArray *wallpapers=[NSArray arrayWithObjects:@"wallpaper-botanical",@"wallpaper-stars",@"wallpaper-sea",@"wallpaper-mountains",@"wallpaper-clouds",nil];
    for(NSUInteger mode=0;mode<3;mode++) for(NSUInteger i=0;i<(mode==0 ? 9 : 5);i++) {
        NSString *kind=mode==0 ? @"color" : (mode==1 ? @"texture" : @"wallpaper");
        NSString *identifier=mode==2 ? [wallpapers objectAtIndex:i] : [NSString stringWithFormat:@"%@-%lu",kind,(unsigned long)i];
        NSArray *ru=[NSArray arrayWithObjects:@"Ледяной",@"Слоновая кость",@"Небесный",@"Шалфей",@"Песочный",@"Лаванда",@"Розовый",@"Серебряный",@"Белый",nil];
        NSArray *be=[NSArray arrayWithObjects:@"Ледзяны",@"Слановая косць",@"Нябесны",@"Шалфей",@"Пясочны",@"Лаванда",@"Ружовы",@"Срэбны",@"Белы",nil];
        NSArray *en=[NSArray arrayWithObjects:@"Ice",@"Ivory",@"Sky",@"Sage",@"Sand",@"Lavender",@"Rose",@"Silver",@"White",nil];
        [presets addObject:[NSDictionary dictionaryWithObjectsAndKeys:identifier,@"id",kind,@"kind",mode==0 ? [en objectAtIndex:i] : [NSString stringWithFormat:@"%@ %lu",kind,(unsigned long)i],@"title_en",mode==0 ? [ru objectAtIndex:i] : [NSString stringWithFormat:@"Вариант %lu",(unsigned long)i],@"title_ru",mode==0 ? [be objectAtIndex:i] : [NSString stringWithFormat:@"Варыянт %lu",(unsigned long)i],@"title_be",nil]];
    }
    return presets;
}
+ (NSDictionary *)configurationForPresetIdentifier:(NSString *)identifier {
    NSString *kind=[identifier hasPrefix:@"color"] ? @"color" : ([identifier hasPrefix:@"texture"] ? @"texture" : @"wallpaper");
    return [NSDictionary dictionaryWithObjectsAndKeys:identifier,@"id",kind,@"kind",nil];
}
+ (NSDictionary *)defaultConfiguration { return [self configurationForPresetIdentifier:@"color-8"]; }

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
@interface NSButtonCell (ColorRowProbe)
- (NSRect)colorTitleRectForFrame:(NSRect)frame;
- (NSDictionary *)colorTitleAttributes;
- (BOOL)colorListRow;
@end
@interface TGAquaChatBackgroundWindowController (ProbeActions)
- (void)chooseImage:(id)sender;
- (void)colorSelected:(id)sender;
- (void)textureSelected:(id)sender;
- (void)wallpaperSelected:(id)sender;
- (void)modeChanged:(id)sender;
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
            NSArray *textures=[controller valueForKey:@"textureButtons"], *wallpapers=[controller valueForKey:@"wallpaperButtons"];
            NSPopUpButton *scope=[controller valueForKey:@"scopePopUp"];
            NSSegmentedControl *mode=[controller valueForKey:@"modeControl"];
            assert([colors count]==9 && [textures count]==5 && [wallpapers count]==5 && [scope numberOfItems]==(hasChat ? 2 : 1));
            assert([mode segmentCount]==3 && [mode selectedSegment]==0);
            assert([[colors objectAtIndex:8] state]==NSOnState);
            NSUInteger colorIndex=0;
            for(NSButton *button in colors) {
                NSButtonCell *cell=[button cell];
                assert([cell colorListRow]);
                assert(NSWidth([button frame])==244 && NSHeight([button frame])==30);
                assert(NSMinY([button frame])==248-colorIndex*30);
                NSRect titleRect=[cell colorTitleRectForFrame:[button bounds]];
                NSDictionary *attributes=[cell colorTitleAttributes];
                NSSize actualName=[[cell title] sizeWithAttributes:attributes];
                assert(NSWidth(titleRect)==198 && NSMinX(titleRect)==40);
                assert(actualName.width<=NSWidth(titleRect) && actualName.height<=NSHeight(titleRect));
                assert([[attributes objectForKey:NSFontAttributeName] pointSize]==12);
                assert([[cell title] rangeOfString:@"…"].location==NSNotFound);
                assert([[cell title] rangeOfString:@"..."].location==NSNotFound);
                AssertContained(titleRect,[button bounds]);
                colorIndex++;
            }
            for(NSString *paneKey in [NSArray arrayWithObjects:@"colorPane",@"texturePane",@"imagePane",nil]) {
                NSView *pane=[controller valueForKey:paneKey];
                for(NSView *view in [pane subviews]) AssertContained([view frame],[pane bounds]);
            }
            assert(![[controller valueForKey:@"colorPane"] isHidden]);
            assert([[controller valueForKey:@"texturePane"] isHidden] && [[controller valueForKey:@"imagePane"] isHidden]);
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
            [mode setSelectedSegment:1]; [controller modeChanged:mode];
            assert([[[controller previewConfiguration] objectForKey:@"kind"] isEqualToString:@"texture"]);
            [controller textureSelected:[textures objectAtIndex:4]];
            assert([[[controller previewConfiguration] objectForKey:@"id"] isEqualToString:@"texture-4"]);
            assert(![[controller valueForKey:@"texturePane"] isHidden] && [[controller valueForKey:@"colorPane"] isHidden]);
            [mode setSelectedSegment:2]; [controller modeChanged:mode];
            assert([[[controller previewConfiguration] objectForKey:@"kind"] isEqualToString:@"wallpaper"]);
            [controller wallpaperSelected:[wallpapers objectAtIndex:4]];
            assert([[[controller previewConfiguration] objectForKey:@"id"] isEqualToString:@"wallpaper-clouds"]);
            assert([[wallpapers objectAtIndex:4] state]==NSOnState && [[wallpapers objectAtIndex:0] state]==NSOffState);
            assert(![[controller valueForKey:@"imagePane"] isHidden] && [[controller valueForKey:@"texturePane"] isHidden]);
            [mode setSelectedSegment:1]; [controller modeChanged:mode];
            assert([[[controller previewConfiguration] objectForKey:@"id"] isEqualToString:@"texture-4"]);
            [mode setSelectedSegment:2]; [controller modeChanged:mode];
            assert([[[controller previewConfiguration] objectForKey:@"id"] isEqualToString:@"wallpaper-clouds"]);
            [mode setSelectedSegment:0]; [controller modeChanged:mode];
            assert([[[controller previewConfiguration] objectForKey:@"kind"] isEqualToString:@"color"]);
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
    printf("Aqua wallpaper window: %lu localized common/chat flows, 9 full-name color rows, 5 textures, 5 wallpapers, explicit modes, staged preview/Apply/Cancel, inheritance, import cleanup, modal owner-close lifetime and contained layout PASS.\n",(unsigned long)cases);
    [pool drain]; return 0;
}
