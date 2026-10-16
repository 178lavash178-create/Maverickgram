#import <Cocoa/Cocoa.h>
#import "TGAquaShellViews.h"
#import "TGAquaAppearance.h"
#import "TGInterfaceDesign.h"
#import "TGTheme.h"
#import "TGThemeContrast.h"
#import "TGIconAssets.h"
#include <math.h>
// Capture real approved-asset rendering while suppressing it in a reference
// render. Text-cell images are independently compared with the same bare cell.
#define TGDrawTemplateIconAsset TGProductionDrawTemplateIconAsset
#import "../Sources/UI/TGIconAssets.m"
#undef TGDrawTemplateIconAsset
static BOOL SuppressIcons=NO;
void TGDrawTemplateIconAsset(NSString *name,NSRect rect,NSColor *ink,CGFloat alpha,BOOL flipped) {
    if(!SuppressIcons) TGProductionDrawTemplateIconAsset(name,rect,ink,alpha,flipped);
}
@interface ForegroundView : NSView { BOOL _flipped; }
@property(nonatomic,assign,getter=isFlipped) BOOL flipped;
@end
@implementation ForegroundView
@synthesize flipped=_flipped;
- (BOOL)isFlipped { return _flipped; }
@end
static NSBitmapImageRep *Render(NSButtonCell *cell,ForegroundView *view,BOOL suppress) {
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:160 pixelsHigh:36 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    [[NSColor whiteColor] set];NSRectFill([view bounds]);
    SuppressIcons=suppress;NSImage *image=[[cell image] retain];
    if(suppress) [cell setImage:nil];
    [cell drawWithFrame:[view bounds] inView:view];
    if(suppress) [cell setImage:image];[image release];SuppressIcons=NO;
    [NSGraphicsContext restoreGraphicsState];return bitmap;
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:@"aqua" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
    if(!TGIconAssetImageNamed(@"attach")) { fprintf(stderr,"Approved Icons required in probe bundle\n");return 2; }
    NSUInteger checks=0,failures=0;CGFloat minimumEnabled=21,minimumDisabled=21;
    for(NSUInteger kind=0;kind<3;kind++) for(NSUInteger enabled=0;enabled<2;enabled++) for(NSUInteger selected=0;selected<2;selected++) for(NSUInteger pressed=0;pressed<2;pressed++) for(NSUInteger flip=0;flip<2;flip++) {
        ForegroundView *view=[[[ForegroundView alloc] initWithFrame:NSMakeRect(0,0,160,36)] autorelease];view.flipped=flip;
        NSButtonCell *cell=kind==0 ? (NSButtonCell *)[[[TGAquaUtilityButtonCell alloc] initTextCell:@""] autorelease] : (NSButtonCell *)[[[TGAquaTextButtonCell alloc] initTextCell:@""] autorelease];
        if(kind==0) { [(TGAquaUtilityButtonCell *)cell setIconOnly:YES];[(TGAquaUtilityButtonCell *)cell setIconAssetName:@"attach"]; }
        else {
            NSImage *template=[[TGIconAssetImageNamed(kind==1 ? @"attach" : @"history") copy] autorelease];
            [template setTemplate:YES];[cell setImage:template];
        }
        [cell setEnabled:enabled];[cell setState:selected ? NSOnState : NSOffState];[cell setHighlighted:pressed];
        NSBitmapImageRep *background=Render(cell,view,YES),*actual=Render(cell,view,NO);
        CGFloat maximum=1;NSUInteger visible=0;
        for(NSInteger y=6;y<30;y++) for(NSInteger x=60;x<100;x++) {
            CGFloat ratio=TGThemeContrastRatio([actual colorAtX:x y:y],[background colorAtX:x y:y]);
            maximum=MAX(maximum,ratio);if(ratio>=(enabled ? 4.3 : 3.0)) visible++;
        }
        if(enabled) minimumEnabled=MIN(minimumEnabled,maximum);else minimumDisabled=MIN(minimumDisabled,maximum);
        checks++;
        if(visible<4) { fprintf(stderr,"FAIL Aqua %s enabled%lu selected%lu pressed%lu flip%lu: maxcontrast%.2f visiblepixels%lu\n",kind==0 ? "utility" : "approved text icon",(unsigned long)enabled,(unsigned long)selected,(unsigned long)pressed,(unsigned long)flip,(double)maximum,(unsigned long)visible);failures++; }
    }
    // A full-color existing wallpaper is deliberately not a template. Its
    // opaque image pixels must remain unchanged when the button turns blue.
    NSString *photoPath=[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"Sources/Resources/Wallpapers/wallpaper-botanical.png"];
    NSImage *photo=[[[NSImage alloc] initWithContentsOfFile:photoPath] autorelease];
    if(!photo || [photo isTemplate]) { fprintf(stderr,"Existing full-color wallpaper fixture required\n");return 2; }
    TGAquaTextButtonCell *colorCell=[[[TGAquaTextButtonCell alloc] initTextCell:@""] autorelease];[colorCell setImage:photo];
    ForegroundView *view=[[[ForegroundView alloc] initWithFrame:NSMakeRect(0,0,160,36)] autorelease];
    NSBitmapImageRep *silver=Render(colorCell,view,NO);[colorCell setState:NSOnState];NSBitmapImageRep *blue=Render(colorCell,view,NO);
    CGFloat maximumColorChange=0;
    for(NSInteger y=12;y<24;y++) for(NSInteger x=71;x<83;x++) {
        NSColor *a=[[silver colorAtX:x y:y] colorUsingColorSpaceName:NSCalibratedRGBColorSpace],*b=[[blue colorAtX:x y:y] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        maximumColorChange=MAX(maximumColorChange,MAX(fabs([a redComponent]-[b redComponent]),MAX(fabs([a greenComponent]-[b greenComponent]),fabs([a blueComponent]-[b blueComponent]))));
    }
    checks++;
    if(maximumColorChange>2.0/255.0) { fprintf(stderr,"FAIL non-template full-color image was recolored by selection: %.4f\n",maximumColorChange);failures++; }
    printf("Aqua control foreground: %lu actual icon-state rasters, enabled min%.2f disabled min%.2f, %lu failures\n",(unsigned long)checks,(double)minimumEnabled,(double)minimumDisabled,(unsigned long)failures);
    [pool drain];return failures ? 1 : 0;
}
