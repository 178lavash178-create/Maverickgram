#import <Cocoa/Cocoa.h>
#import "TGMessageViewersWindowController.h"
#import "TGLocationPickerWindowController.h"
#import "TGLocationSearchService.h"
#import "TGLocationStaticMapView.h"
#import "TGStatusViewComponents.h"
#import "TGStatusViewCells.h"
#import "TGLocalization.h"
#import "TGInterfaceDesign.h"
#import "TGAquaAppearance.h"
#import "TGPrivacyPermissions.h"
#import "TGMediaImageLoader.h"
#include <stdio.h>
#include <string.h>
// Network, location permission and image I/O are disabled; production controllers,
// surfaces, row construction, map transforms and controls are compiled unchanged.
@implementation TGUtilityWindowView @end
@implementation TGUtilityPanelView @end
@implementation TGGroupedCardView
@synthesize drawsInterior = _drawsInterior;
@end
@implementation TGLocationSearchService
- (BOOL)isAvailable { return NO; }
- (void)cancel { }
- (void)searchForQuery:(NSString *)q centerLatitude:(double)a centerLongitude:(double)b completion:(TGLocationSearchCompletion)c {(void)q;(void)a;(void)b;if(c)c([NSArray array],nil);}
@end
@implementation TGPrivacyPermissions
+ (BOOL)requestLocationPermission { return NO; }
@end
NSImage *TGMediaCachedThumbnailFromFile(NSString *p,NSUInteger n) {(void)p;(void)n;return nil;}
TGMediaImageLoadToken *TGLoadImageThumbnailFromFileAsync(NSString *p,NSUInteger n,TGMediaImageLoadCompletion c) {(void)p;(void)n;(void)c;return nil;}
@interface TGLocationPickerWindowController (Probe)
- (void)buildViews;
- (void)prepareForClosing;
- (void)reloadMapThumbnail;
- (void)mapCoordinateChosen:(NSDictionary *)coordinate;
@end
@interface OfflinePicker : TGLocationPickerWindowController @end
@implementation OfflinePicker
- (void)buildViews { [self setValue:@NO forKey:@"mapServicesAvailable"]; [super buildViews]; }
- (void)reloadMapThumbnail { }
@end
static NSUInteger checks=0;
static void Require(BOOL value,const char *reason) {checks++;if(!value){fprintf(stderr,"Readers/location: %s\n",reason);exit(1);}}
static void CheckRoot(NSView *root) {
 for(NSView *child in [root subviews]) {
  if([child isHidden] || NSIsEmptyRect([child frame]))continue;
  Require(NSContainsRect([root bounds],[child frame]),"visible control contained in window");
  if([child isKindOfClass:[NSButton class]]) {
   NSButton *b=(NSButton *)child;
   Require([b target] && [b action],"real button keeps target/action");
   CGFloat width=[[b title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]].width;
   Require(width+16<=NSWidth([b frame]),"localized action label fits");
  }
 }
 NSSize size=[root bounds].size;NSImage *raster=[[[NSImage alloc] initWithSize:size] autorelease];
 [raster lockFocus];[root drawRect:[root bounds]];[raster unlockFocus];
 Require([[raster TIFFRepresentation] length]>0,"production material renders");
}
int main(int argc,const char **argv) {
 NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
 BOOL aqua=argc>1 && strcmp(argv[1],"aqua")==0;
 [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
 [NSApplication sharedApplication];
 for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
  TGSetLanguageCode(language);
  TGMessageViewersWindowController *readers=[[[TGMessageViewersWindowController alloc] initWithMessagePreview:@"Synthetic multiline preview\nwith more text"] autorelease];
  NSView *root=[[readers window] contentView];CheckRoot(root);
  Require([root isKindOfClass:[TGAquaUtilityWindowView class]]==aqua,"only Aqua uses shared rail surface");
  Require(NSWidth([root bounds])==(aqua?360:420),"compact Aqua panel and Classic size retained");
  NSMutableArray *summaries=[NSMutableArray array];
  for(NSUInteger i=0;i<80;i++)[summaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Long synthetic viewer name for truncation",@"display_name",@1700000000,@"view_date",@"❤️",@"reaction_display",nil]];
  [readers showViewerSummaries:summaries];
  NSView *doc=[readers valueForKey:@"contentView"];NSScrollView *scroll=[readers valueForKey:@"scrollView"];
  Require([[doc subviews] count]==80,"complete readers list preserved");
  if(aqua)Require(NSMaxY([[scroll contentView] bounds])>=NSHeight([doc bounds])-1,"readers starts with first row at top");
  for(NSView *row in [doc subviews]) {
   NSTextField *name=nil,*reaction=nil,*time=nil;
   for(NSView *child in [row subviews])if([child isKindOfClass:[NSTextField class]]) {
    Require(NSContainsRect([row bounds],[child frame]),"row text fits");NSString *t=[(NSTextField *)child stringValue];
    if([t hasPrefix:@"Long"])name=(id)child;else if([t isEqual:@"❤️"])reaction=(id)child;else time=(id)child;
   }
   Require(name&&reaction&&time,"readers name/reaction/read time retained");
   if(aqua)Require(NSMaxX([name frame])<NSMinX([reaction frame]),"long name never covers reaction");
   if(aqua)Require(NSMaxY([time frame])<=NSMinY([name frame]),"read time has its own aligned second line");
  }
  [readers showErrorMessage:@"Synthetic error spanning the content safely"];
  Require([[doc subviews] count]==1,"error replaces prior rows");
  [readers showViewerSummaries:[NSArray array]];Require([[doc subviews] count]==1,"empty state replaces rows");
  NSWindow *parent=[[[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,400,300) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];[parent setReleasedWhenClosed:NO];
  [readers showNearRect:NSMakeRect(330,100,60,40) ofView:[parent contentView]];
  if(aqua)Require(NSContainsRect([[parent screen] visibleFrame],[[readers window] frame]),"anchored panel stays on screen");
  [[readers window] close];[parent close];
  OfflinePicker *picker=[[[OfflinePicker alloc] initWithClient:nil] autorelease];NSView *pickerRoot=[[picker window] contentView];CheckRoot(pickerRoot);
  Require([pickerRoot isKindOfClass:[TGAquaUtilityWindowView class]]==aqua,"map Aqua/Classic presentation separated");
  TGLocationStaticMapView *map=[picker valueForKey:@"mapImageView"];
  if(aqua) {
   Require(NSWidth([map frame])==640 && NSHeight([map frame])>=350,"map owns full content width");
   Require(![[picker valueForKey:@"searchField"] isEnabled] && ![[picker valueForKey:@"currentLocationButton"] isEnabled],"unavailable OS services are safely disabled");
  }
  [picker mapCoordinateChosen:[NSDictionary dictionaryWithObjectsAndKeys:@12.345,@"latitude",@67.89,@"longitude",@15,@"zoom",nil]];
  Require([[[picker valueForKey:@"statusField"] stringValue] rangeOfString:@"12.345"].location!=NSNotFound,"map selection updates coordinate summary");
  [picker prepareForClosing];Require([[picker valueForKey:@"closing"] boolValue],"closing invalidates map work");[[picker window] close];
 }
 printf("Readers/location %s: %lu production control/layout/state checks PASS\n",aqua?"Aqua":"Classic",(unsigned long)checks);
 [pool drain];return 0;
}
