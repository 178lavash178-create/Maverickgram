#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "TGTheme.h"
#import "TGThemeContrast.h"
#import "TGThemeTextField.h"
#import "TGIconAssets.h"
#import "../Sources/Core/TGChatItem.h"
#include "../Sources/UI/TGProfileEditWindowController+Fields.inc"
#import "TGDownloadProgressWindowController.h"
#import "TGStatusButtonCells.h"
#import "../Sources/Workshop/UI/TGWorkshopModuleCardView.h"
#import "../Sources/Workshop/UI/TGWorkshopSurfaceView.h"
#import "../Sources/Workshop/UI/TGWorkshopButtonCell.h"

NSString * const TGDownloadManagerDidChangeNotification = @"TGDownloadManagerDidChangeNotification";
NSString *TGLoc(NSString *key) { return key; }
NSString *TGLanguageCode(void) { return @"en"; }
BOOL TGVersionStringIsNewer(NSString *a, NSString *b) { (void)a; (void)b; return NO; }
void TGDrawAvatarInRect(NSString *path, NSString *title, NSRect rect, BOOL selected, BOOL flipped) {
    (void)path; (void)title; (void)rect; (void)selected; (void)flipped;
}
@interface TGRepresentedObjectCell : NSCell
@property(retain) id representedObject;
@end
@implementation TGRepresentedObjectCell
@synthesize representedObject=_representedObject;
- (void)dealloc { [_representedObject release]; [super dealloc]; }
@end
// Native progress buttons are exercised with their real cells by the focused
// Aqua auxiliary-view probe; this probe verifies the passive label surfaces.
@implementation TGSecondaryTextButtonCell
@end
#include "../Sources/UI/TGPrivacyWindowController+BlockedSenderCell.inc"
#include "../Sources/UI/TGChatFolderManagementWindowController+Cells.inc"
@interface SwitchProbe : NSObject
@property(nonatomic,retain) NSButton *previewButton;
@end
@implementation SwitchProbe
@synthesize previewButton=_previewButton;
- (void)dealloc { [_previewButton release]; [super dealloc]; }
#include "../Sources/UI/TGNotificationSettingsWindowController+Theme.inc"
@end
@interface DownloadProbeManager : NSObject
- (NSArray *)itemsSnapshot;
@end
@implementation DownloadProbeManager
- (NSArray *)itemsSnapshot { return [NSArray array]; }
@end
static NSMutableArray *DrawnTextInks;
@interface NSString (ContrastCapture)
- (void)tgProbeDrawInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes;
@end
@implementation NSString (ContrastCapture)
- (void)tgProbeDrawInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes {
    NSColor *ink=[attributes objectForKey:NSForegroundColorAttributeName];
    if (DrawnTextInks && ink) { [DrawnTextInks addObject:ink]; }
    [self tgProbeDrawInRect:rect withAttributes:attributes];
}
@end
static void Require(BOOL value, NSString *label) { if (!value) { fprintf(stderr, "Utility contrast failed: %s / %s\n", [TGCurrentThemeIdentifier() UTF8String], [label UTF8String]); exit(1); } }
static NSBitmapImageRep *Render(NSSize size, void (^drawing)(void)) {
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:(NSInteger)size.width pixelsHigh:(NSInteger)size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    [[NSColor whiteColor] setFill]; NSRectFill(NSMakeRect(0,0,size.width,size.height));
    drawing(); [[NSGraphicsContext currentContext] flushGraphics];
    [NSGraphicsContext restoreGraphicsState]; return bitmap;
}
static void CheckInk(NSColor *ink, NSBitmapImageRep *surface, NSArray *points, NSString *label) {
    for (NSValue *pointValue in points) {
        NSPoint p=[pointValue pointValue];
        NSColor *background=[surface colorAtX:(NSInteger)p.x y:(NSInteger)p.y];
        CGFloat ratio=TGThemeContrastRatio(ink,background);
        if (ratio<4.45) { fprintf(stderr,"  point %.0f,%.0f ratio %.3f ink=%s surface=%s\n",p.x,p.y,ratio,[[ink description] UTF8String],[[background description] UTF8String]); }
        Require(ratio>=4.45,label);
    }
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init]; [NSApplication sharedApplication];
    method_exchangeImplementations(class_getInstanceMethod([NSString class],@selector(drawInRect:withAttributes:)),class_getInstanceMethod([NSString class],@selector(tgProbeDrawInRect:withAttributes:)));
    NSArray *points=[NSArray arrayWithObjects:[NSValue valueWithPoint:NSMakePoint(250,12)],[NSValue valueWithPoint:NSMakePoint(250,56)],[NSValue valueWithPoint:NSMakePoint(250,100)],nil];
    TGWorkshopModuleCardView *card=[[[TGWorkshopModuleCardView alloc] initWithFrame:NSMakeRect(0,0,560,116)] autorelease];
    DownloadProbeManager *manager=[[[DownloadProbeManager alloc] init] autorelease];
    TGDownloadProgressWindowController *progress=[[[TGDownloadProgressWindowController alloc] initWithDownloadManager:(id)manager] autorelease];
    TGBlockedSenderCell *blocked=[[[TGBlockedSenderCell alloc] initTextCell:@""] autorelease];
    [blocked setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Sender",@"title",@"detail",@"username",nil]];
    NSView *view=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,400,48)] autorelease];
    SwitchProbe *switchProbe=[[[SwitchProbe alloc] init] autorelease];
    switchProbe.previewButton=[[[NSButton alloc] initWithFrame:NSMakeRect(0,0,260,22)] autorelease];
    [switchProbe.previewButton setButtonType:NSSwitchButton]; [switchProbe.previewButton setTitle:@"Show preview"];
    TGChatFolderListCell *folder=[[[TGChatFolderListCell alloc] initTextCell:@""] autorelease];
    [folder setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Family",@"title",@YES,@"is_shareable",nil]];
    TGChatFolderChatCell *chat=[[[TGChatFolderChatCell alloc] initTextCell:@""] autorelease];
    [chat setRepresentedObject:[[[TGChatItem alloc] initWithChatID:@1 title:@"Friend" typeSummary:@"Private chat" unreadCount:@0] autorelease]];
    TGThemeTextField *utilityLabel=(id)TGProfileEditLabel(@"Profile",NSMakeRect(0,0,240,24));
    NSTextField *profileInput=TGProfileEditInput(NSMakeRect(0,0,240,28));
    [profileInput setStringValue:@"A readable profile"];
    TGThemeSwitchButton *folderSwitch=[[[TGThemeSwitchButton alloc] initWithFrame:NSMakeRect(0,0,240,22)] autorelease];
    [folderSwitch setTitle:@"Include contacts"];
    for (NSString *theme in TGThemeIdentifiers()) {
        TGSetActiveThemeIdentifier(theme);
        [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
        NSColor *beforeDraw=[[[utilityLabel textColor] retain] autorelease];
        [utilityLabel refreshThemeInk];
        Require([beforeDraw isEqual:[utilityLabel textColor]],@"open utility label refreshes through theme notification before drawing");
        [progress performSelector:@selector(refresh)];
        NSColor *panel=[[progress window] backgroundColor];
        NSBitmapImageRep *panelImage=Render(NSMakeSize(340,148),^{ [panel setFill]; NSRectFill(NSMakeRect(0,0,340,148)); });
        for (NSString *key in [NSArray arrayWithObjects:@"nameField",@"statusField",@"bytesField",nil]) {
            CheckInk([[progress valueForKey:key] textColor],panelImage,points,[NSString stringWithFormat:@"download %@",key]);
        }
        for (NSUInteger error=0;error<2;error++) {
            [card configureWithInstalledRecord:nil busy:NO progress:0 errorMessage:error ? @"Download failed" : nil]; [card refreshTheme];
            NSBitmapImageRep *cardImage=Render(NSMakeSize(560,116),^{ [card drawRect:[card bounds]]; });
            for (NSString *key in [NSArray arrayWithObjects:@"nameField",@"descriptionField",@"detailsField",@"statusField",nil]) {
                CheckInk([[card valueForKey:key] textColor],cardImage,points,[NSString stringWithFormat:@"Workshop %@ error=%lu",key,(unsigned long)error]);
            }
        }
        for (NSCell *folderCell in [NSArray arrayWithObjects:folder,chat,nil]) {
            for (NSUInteger selected=0;selected<2;selected++) {
                [folderCell setHighlighted:selected]; DrawnTextInks=[NSMutableArray array];
                NSBitmapImageRep *row=Render(NSMakeSize(400,48),^{ [folderCell drawInteriorWithFrame:[view bounds] inView:view]; });
                Require([DrawnTextInks count]==2,@"folder row captured both actual text runs");
                for (NSColor *ink in DrawnTextInks) { CheckInk(ink,row,[NSArray arrayWithObject:[NSValue valueWithPoint:NSMakePoint(390,24)]],@"folder/chat row actual selected surface"); }
                DrawnTextInks=nil;
            }
        }
        for (NSUInteger selected=0;selected<2;selected++) {
            [blocked setHighlighted:selected]; DrawnTextInks=[NSMutableArray array];
            NSBitmapImageRep *row=Render(NSMakeSize(400,48),^{ [blocked drawInteriorWithFrame:[view bounds] inView:view]; });
            Require([DrawnTextInks count]==2,@"blocked row captured both production text runs");
            for (NSColor *ink in DrawnTextInks) { CheckInk(ink,row,[NSArray arrayWithObject:[NSValue valueWithPoint:NSMakePoint(390,24)]],@"blocked row actual surface"); }
            DrawnTextInks=nil;
        }
        for (NSUInteger selected=0;selected<2;selected++) {
            for (NSUInteger pressed=0;pressed<2;pressed++) {
                TGWorkshopSegmentButtonCell *button=[[[TGWorkshopSegmentButtonCell alloc] initTextCell:@"Catalog"] autorelease];
                [button setState:selected ? NSOnState : NSOffState]; [button setHighlighted:pressed];
                DrawnTextInks=[NSMutableArray array];
                NSBitmapImageRep *buttonImage=Render(NSMakeSize(140,38),^{ [button drawWithFrame:NSMakeRect(0,0,140,38) inView:view]; });
                Require([DrawnTextInks count]>0,@"Workshop segment captured actual title ink");
                NSArray *buttonPoints=[NSArray arrayWithObjects:[NSValue valueWithPoint:NSMakePoint(10,6)],[NSValue valueWithPoint:NSMakePoint(10,19)],[NSValue valueWithPoint:NSMakePoint(10,31)],nil];
                CheckInk([DrawnTextInks lastObject],buttonImage,buttonPoints,@"Workshop segment normal/selected/pressed");
                CheckInk(TGWorkshopCreamColor(),buttonImage,buttonPoints,@"Workshop icon ink on segment surface");
                DrawnTextInks=nil;
            }
        }
        [switchProbe refreshPreviewTheme:nil];
        NSColor *switchInk=[[switchProbe.previewButton attributedTitle] attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL];
        NSBitmapImageRep *grouped=Render(NSMakeSize(560,116),^{
            NSBezierPath *path=[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0,0,560,116) xRadius:8 yRadius:8];
            TGThemeDrawGroupedCardInPath(path,NSMakeRect(0,0,560,116),NO);
        });
        CheckInk(switchInk,grouped,points,@"notification preview checkbox over rendered grouped card");
        [folderSwitch refreshThemeInk];
        NSColor *folderSwitchInk=[[folderSwitch attributedTitle] attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL];
        CheckInk(folderSwitchInk,grouped,points,@"folder/privacy checkbox over rendered card");
        // Reuse the same labels and native field across all themes: no window reopening.
        for (NSUInteger roleIndex=0;roleIndex<3;roleIndex++) {
            TGThemeSurfaceRole role=roleIndex==0 ? TGThemeSurfaceCard : (roleIndex==1 ? TGThemeSurfaceWindow : TGThemeSurfacePanel);
            NSBitmapImageRep *labelSurface=Render(NSMakeSize(560,450),^{
                NSRect rect=NSMakeRect(0,0,560,450);
                NSBezierPath *path=[NSBezierPath bezierPathWithRect:rect];
                if (role==TGThemeSurfaceWindow) { TGThemeDrawWindowBackgroundInRect(rect,NO); }
                else if (role==TGThemeSurfacePanel) { TGThemeDrawPanelBackgroundInPath(path,rect,NO); }
                else { TGThemeDrawGroupedCardInPath(path,rect,NO); }
            });
            NSMutableArray *labelPoints=[NSMutableArray array];
            for (NSInteger y=10;y<440;y+=10) { for (NSInteger x=10;x<550;x+=20) {
                [labelPoints addObject:[NSValue valueWithPoint:NSMakePoint(x,y)]];
            } }
            for (NSUInteger inkKind=0;inkKind<3;inkKind++) {
                [utilityLabel setThemeSurface:role]; [utilityLabel setDetailInk:inkKind==1]; [utilityLabel setErrorInk:inkKind==2];
                [utilityLabel refreshThemeInk];
                CheckInk([utilityLabel textColor],labelSurface,labelPoints,[NSString stringWithFormat:@"existing utility label role=%lu ink=%lu",(unsigned long)role,(unsigned long)inkKind]);
            }
        }
        NSBitmapImageRep *nativeInput=Render(NSMakeSize(240,28),^{ [profileInput drawRect:[profileInput bounds]]; });
        CheckInk([profileInput textColor],nativeInput,[NSArray arrayWithObject:[NSValue valueWithPoint:NSMakePoint(220,14)]],@"ProfileEdit native input actual white background");
    }
    [progress invalidate];
    puts("Utility surface contrast passed for every theme: floating downloads, actual Workshop gradients, blocked/folder rows, notification/folder/privacy checkboxes, live utility labels and ProfileEdit fields.");
    [pool drain]; return 0;
}
