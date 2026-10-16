#import <Cocoa/Cocoa.h>
#import "TGAquaFolderPresentation.h"
#import "TGLocalization.h"
#include <assert.h>

@interface FolderPreferenceObserver : NSObject {
    NSUInteger _count;
    BOOL _lastValue;
}
@property(nonatomic, readonly) NSUInteger count;
@property(nonatomic, readonly) BOOL lastValue;
- (void)changed:(NSNotification *)notification;
@end
@implementation FolderPreferenceObserver
@synthesize count = _count, lastValue = _lastValue;
- (void)changed:(NSNotification *)notification {
    _count++;
    _lastValue = [[[notification userInfo] objectForKey:@"usesDrawer"] boolValue];
}
@end

static void AssertContained(NSRect inner,NSRect outer) {
    assert(NSMinX(inner)>=0 && NSMinY(inner)>=0 && NSMaxX(inner)<=NSWidth(outer) && NSMaxY(inner)<=NSHeight(outer));
}
int main(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id oldPreference = [[defaults objectForKey:TGAquaFolderPresentationDefaultsKey] retain];
    NSString *oldLanguage = [TGLanguageCode() copy];
    [defaults removeObjectForKey:TGAquaFolderPresentationDefaultsKey];
    assert(TGAquaFoldersUseDrawer());
    [defaults setObject:@"invalid" forKey:TGAquaFolderPresentationDefaultsKey];
    assert(TGAquaFoldersUseDrawer());
    [defaults removeObjectForKey:TGAquaFolderPresentationDefaultsKey];
    FolderPreferenceObserver *observer = [[[FolderPreferenceObserver alloc] init] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(changed:) name:TGAquaFolderPresentationDidChangeNotification object:nil];
    TGAquaFolderPresentationSettingsView *view = [[[TGAquaFolderPresentationSettingsView alloc] initWithFrame:NSMakeRect(0,0,[TGAquaFolderPresentationSettingsView minimumWidth],28)] autorelease];
    NSPopUpButton *popup = [view valueForKey:@"popUpButton"];
    NSTextField *label = [view valueForKey:@"label"];
    NSUInteger layouts = 0, titles = 0;
    for (NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
        TGSetLanguageCode(language); [view refreshAppearance];
        assert(![[label stringValue] hasPrefix:@"aqua."] && [[label stringValue] length]>0);
        assert([popup numberOfItems]==2 && [popup indexOfSelectedItem]==0);
        CGFloat widths[] = {[TGAquaFolderPresentationSettingsView minimumWidth],440,720};
        for (NSUInteger width=0;width<3;width++) {
            [view setFrameSize:NSMakeSize(widths[width],28)];
            AssertContained([label frame],[view bounds]); AssertContained([popup frame],[view bounds]);
            assert(NSWidth([popup frame])>=230);
            assert([[label stringValue] sizeWithAttributes:[NSDictionary dictionaryWithObject:[label font] forKey:NSFontAttributeName]].width<=NSWidth([label frame]));
            for (NSInteger option=0;option<2;option++) {
                [popup selectItemAtIndex:option];
                NSRect titleRect=[[popup cell] titleRectForBounds:[popup bounds]];
                NSSize title=[[popup titleOfSelectedItem] sizeWithAttributes:[NSDictionary dictionaryWithObject:[popup font] forKey:NSFontAttributeName]];
                assert(![[popup titleOfSelectedItem] hasPrefix:@"aqua."]);
                assert(title.width<=NSWidth(titleRect) && title.height<=NSHeight(titleRect));
                AssertContained(titleRect,[popup bounds]); titles++;
            }
            [view refreshAppearance]; layouts++;
        }
    }
    assert([observer count]==0);
    TGAquaSetFoldersUseDrawer(NO);
    assert(!TGAquaFoldersUseDrawer() && [observer count]==1 && ![observer lastValue]);
    assert([popup indexOfSelectedItem]==1);
    assert([[defaults objectForKey:TGAquaFolderPresentationDefaultsKey] isKindOfClass:[NSNumber class]]);
    TGAquaSetFoldersUseDrawer(NO); assert([observer count]==1);
    [popup selectItemAtIndex:0]; [popup sendAction:[popup action] to:[popup target]];
    assert(TGAquaFoldersUseDrawer() && [observer count]==2 && [observer lastValue]);
    TGAquaSetFoldersUseDrawer(YES); assert([observer count]==2);
    [popup selectItemAtIndex:1]; [popup sendAction:[popup action] to:[popup target]];
    assert(!TGAquaFoldersUseDrawer() && [observer count]==3 && ![observer lastValue]);
    [defaults synchronize]; assert(![[defaults objectForKey:TGAquaFolderPresentationDefaultsKey] boolValue]);
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    if (oldPreference) [defaults setObject:oldPreference forKey:TGAquaFolderPresentationDefaultsKey];
    else [defaults removeObjectForKey:TGAquaFolderPresentationDefaultsKey];
    TGSetLanguageCode(oldLanguage); [oldLanguage release]; [oldPreference release];
    printf("Aqua folder preference: default/corrupt fallback, persistent live changes, no-op notifications; %lu localized settings layouts/%lu full popup titles PASS.\n",(unsigned long)layouts,(unsigned long)titles);
    [pool drain]; return 0;
}
