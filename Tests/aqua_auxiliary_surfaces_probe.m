// Reuse only deterministic download records/base-container adapters. Production
// controller actions, button cells, view material drawing and layouts are real.
#define main TGUnusedDownloadFixtureMain
#import "download_manager_presentation_probe.m"
#undef main
#import "TGDownloadProgressWindowController.h"
#import "TGMessageViewersWindowController.h"
#import "TGInterfaceDesign.h"
#import "TGAquaAppearance.h"
#import "TGDialogPresentation.h"
#import "TGStatusButtonCells.h"
#import "../Sources/Media/TGMediaImageLoader.h"
#include <string.h>

NSImage *TGMediaCachedThumbnailFromFile(NSString *path,NSUInteger size) { (void)path;(void)size;return nil; }
TGMediaImageLoadToken *TGLoadImageThumbnailFromFileAsync(NSString *path,NSUInteger size,TGMediaImageLoadCompletion completion) { (void)path;(void)size;(void)completion;return nil; }
@interface TGDownloadProgressWindowController (AquaProbe)
- (void)refresh;
- (void)layoutProgressContent;
@end
static NSBitmapImageRep *PaintAuxiliaryView(NSView *view) {
    NSRect bounds=[view bounds];
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:NSWidth(bounds) pixelsHigh:NSHeight(bounds) bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *context=[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext setCurrentContext:context];
    [[NSColor magentaColor] set];NSRectFill(bounds);[view drawRect:bounds];
    [NSGraphicsContext restoreGraphicsState];return bitmap;
}
static void CheckAuxiliaryLabelFrame(NSTextField *label,NSBitmapImageRep *bitmap,NSRect bounds,NSRect frame) {
    Require(NSContainsRect(bounds,frame),"auxiliary label wholly fits its material");
    // Physical bitmap origin is at the visual top; these roots are unflipped.
    CGFloat x[]={NSMinX(frame)+3,NSMidX(frame),NSMaxX(frame)-3};
    for(NSUInteger index=0;index<3;index++) {
        NSColor *pixel=[bitmap colorAtX:x[index] y:NSHeight(bounds)-NSMidY(frame)];
        Require([pixel alphaComponent]>0.99,"auxiliary label backing is opaque");
        if(Contrast([label textColor],pixel)<4.40) fprintf(stderr,"Auxiliary contrast %.3f label=%s ink=%s surface=%s\n",Contrast([label textColor],pixel),[[label stringValue] UTF8String],[[[label textColor] description] UTF8String],[[pixel description] UTF8String]);
        Require(Contrast([label textColor],pixel)>=4.40,"actual auxiliary label contrasts with its rendered material");
    }
}
static void CheckAuxiliaryLabel(NSTextField *label,NSBitmapImageRep *bitmap,NSRect bounds) { CheckAuxiliaryLabelFrame(label,bitmap,bounds,[label frame]); }
static void CheckAuxiliaryButton(NSButton *button,NSRect bounds) {
    Require(NSContainsRect(bounds,[button frame]),"progress button fits panel");
    CGFloat width=[ [button title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]].width;
    if(width+20>NSWidth([button frame])) fprintf(stderr,"Progress title clipped: %s requires%.1f available%.1f\n",[[button title] UTF8String],width+20,NSWidth([button frame]));
    Require(width+20<=NSWidth([button frame]),"localized progress title fits actual secondary-cell font and padding");
    Require([[button cell] isKindOfClass:[TGSecondaryTextButtonCell class]],"Aqua progress reuses real shared silver cell");
    Require([button target]!=nil && [button action]!=NULL,"restyled progress button preserves real target/action");
    NSImage *image=[[[NSImage alloc] initWithSize:[button bounds].size] autorelease];
    [image lockFocus];[[button cell] drawWithFrame:[button bounds] inView:button];[image unlockFocus];
    Require([[image TIFFRepresentation] length]>0,"real localized progress button draws");
}
int main(int argc,const char **argv) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    BOOL aqua=(argc>1 && strcmp(argv[1],"aqua")==0);
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:[NSDictionary dictionaryWithObject:aqua?@"aqua":@"classic" forKey:TGInterfaceDesignDefaultsKey] forName:NSArgumentDomain];
    [NSApplication sharedApplication];Require(TGInterfaceDesignIsAqua()==aqua,"requested design mode latched");
    Require([[NSBundle mainBundle] pathForResource:@"black-Linen" ofType:@"png" inDirectory:@"Textures"]!=nil && [[NSBundle mainBundle] pathForResource:@"brushed_alu" ofType:@"png" inDirectory:@"Textures"]!=nil,"probe includes real approved linen and silver materials");
    SetRecords([NSArray arrayWithObject:Record(@"downloading")]);
    TGDownloadManagerWindowController *manager=[[[TGDownloadManagerWindowController alloc] init] autorelease];
    TGDownloadProgressWindowController *progress=[[[TGDownloadProgressWindowController alloc] initWithDownloadManager:[TGDownloadManager sharedManager]] autorelease];
    TGMessageViewersWindowController *viewers=[[[TGMessageViewersWindowController alloc] initWithMessagePreview:@"Synthetic preview"] autorelease];
    NSUInteger layouts=0,buttons=0,rasters=0;
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
        TGSetLanguageCode(language);[manager refreshPresentation];[progress refresh];
        NSView *root=TGUtilityWindowContentView([manager window]);
        Require(aqua ? [root isKindOfClass:[TGAquaUtilityWindowView class]] : [root isKindOfClass:[TGDownloadManagerBackgroundView class]],"manager owns the design-specific shared material root");
        NSBitmapImageRep *body=PaintAuxiliaryView(root);rasters++;
        Require([[body colorAtX:3 y:3] alphaComponent]>0.99,"manager window material fills corners");
        NSView *header=[manager valueForKey:@"headerView"],*footer=[manager valueForKey:@"footerView"];
        NSBitmapImageRep *head=PaintAuxiliaryView(header),*foot=PaintAuxiliaryView(footer);rasters+=2;
        Require([[head colorAtX:20 y:20] alphaComponent]>0.99 && [[foot colorAtX:20 y:20] alphaComponent]>0.99,"manager chrome opaque");
        if(aqua) {
            for(NSString *key in [NSArray arrayWithObjects:@"titleField",@"subtitleField",nil]) {
                NSTextField *label=[manager valueForKey:key];CheckAuxiliaryLabelFrame(label,head,[header bounds],[header convertRect:[label bounds] fromView:label]);
            }
            NSTextField *status=[manager valueForKey:@"statusField"];CheckAuxiliaryLabelFrame(status,foot,[footer bounds],[footer convertRect:[status bounds] fromView:status]);
        }
        for(NSUInteger collapsed=0;collapsed<2;collapsed++) {
            [progress setValue:[NSNumber numberWithBool:collapsed] forKey:@"collapsed"];
            for(NSUInteger width=300;width<=340;width+=40) {
                [[progress window] setContentSize:NSMakeSize(width,collapsed?94:148)];[progress layoutProgressContent];
                NSView *panel=[[progress window] contentView];
                if(aqua) {
                    NSBitmapImageRep *pixels=PaintAuxiliaryView(panel);rasters++;
                    CheckAuxiliaryLabel([progress valueForKey:@"nameField"],pixels,[panel bounds]);
                    CheckAuxiliaryLabel([progress valueForKey:@"statusField"],pixels,[panel bounds]);
                    if(!collapsed) CheckAuxiliaryLabel([progress valueForKey:@"bytesField"],pixels,[panel bounds]);
                    for(NSString *key in [NSArray arrayWithObjects:@"pauseButton",@"cancelButton",@"collapseButton",@"downloadsButton",nil]) {
                        NSButton *button=[progress valueForKey:key];if([button isHidden]) continue;
                        CheckAuxiliaryButton(button,[panel bounds]);buttons++;
                    }
                } else Require(![[[progress valueForKey:@"pauseButton"] cell] isKindOfClass:[TGSecondaryTextButtonCell class]],"Classic retains native progress controls");
                layouts++;
            }
        }
    }
    NSView *viewerRoot=[[viewers window] contentView];
    if(aqua) {
        Require(![viewerRoot wantsLayer],"Aqua viewers no longer uses hardcoded blue CALayer");
        NSBitmapImageRep *pixels=PaintAuxiliaryView(viewerRoot);rasters++;
        CheckAuxiliaryLabel([viewers valueForKey:@"titleField"],pixels,[viewerRoot bounds]);
        CheckAuxiliaryLabel([viewers valueForKey:@"subtitleField"],pixels,[viewerRoot bounds]);
    } else Require([viewerRoot wantsLayer],"Classic viewer backing preserved");
    [viewers showViewerSummaries:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"A sufficiently long synthetic viewer name",@"display_name",@"❤️",@"reaction_display",@1700000000,@"view_date",nil]]];
    NSView *document=[viewers valueForKey:@"contentView"],*row=[[document subviews] objectAtIndex:0];
    if(aqua) {
        NSTextField *name=nil,*reaction=nil;
        for(NSView *view in [row subviews]) if([view isKindOfClass:[NSTextField class]]) {
            if([[(NSTextField *)view stringValue] isEqual:@"❤️"]) reaction=(NSTextField *)view;
            else if([[(NSTextField *)view stringValue] hasPrefix:@"A sufficiently"]) name=(NSTextField *)view;
        }
        Require(name && reaction && NSMaxX([name frame])<NSMinX([reaction frame]),"viewer name reserves space for existing reaction");
    }
    [viewers showErrorMessage:@"Synthetic error"];[viewers showViewerSummaries:[NSArray array]];
    [progress invalidate];[[manager window] close];[[viewers window] close];
    SetRecords([NSArray array]);
    printf("Auxiliary %s surfaces: %lu real localized layouts,%lu real button rasters,%lu material rasters; downloads/progress/viewers routes and Classic preservation PASS.\n",aqua?"Aqua":"Classic",(unsigned long)layouts,(unsigned long)buttons,(unsigned long)rasters);
    [pool drain];return 0;
}
