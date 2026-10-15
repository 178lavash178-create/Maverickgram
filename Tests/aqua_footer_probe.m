#import <Cocoa/Cocoa.h>
#import "TGMessageItem.h"
#import "TGMessageLayoutSupport.h"
#import "TGChatDisplayPreferences.h"
#import "TGTheme.h"
#import "TGThemeContrast.h"
#import "TGIconAssets.h"
#import "TGInterfaceDesign.h"
#import "TGReactionChipLayout.h"
#include <math.h>

// Unrelated media dependencies; the receipt renderer, theme gradients and
// approved icon asset loader are all production implementations.
NSString * const TGInlineMediaKindGIF = @"gif";
NSString * const TGInlineMediaKindVideo = @"video";
NSString * const TGInlineMediaKindWebM = @"webm";
NSString * const TGInlineMediaKindTGS = @"tgs";
NSString * const TGInlineMediaIdentifierKey = @"identifier";
NSString * const TGInlineMediaPathKey = @"path";
NSString * const TGInlineMediaFrameKey = @"frame";
NSString * const TGInlineMediaKindKey = @"kind";
NSString * const TGInlineMediaPlaybackDiagnosticNotification = @"TGInlineMediaPlaybackDiagnosticNotification";
NSString * const TGInlineMediaPlaybackDiagnosticMessageKey = @"message";
NSImage *TGImageWithCorrectOrientationFromFile(NSString *path) { (void)path; return nil; }
NSImage *TGImageThumbnailFromFile(NSString *path, NSUInteger size) { (void)path; (void)size; return nil; }
NSImage *TGMediaCachedThumbnailFromFile(NSString *path, NSUInteger size) { (void)path; (void)size; return nil; }
NSImage *TGImageThumbnailFromData(NSData *data, NSUInteger size) { (void)data; (void)size; return nil; }
NSImage *TGCustomEmojiCachedImageForEntity(NSDictionary *entity, NSUInteger size) { (void)entity; (void)size; return nil; }
void TGCustomEmojiRequestImageForEntity(NSDictionary *entity, NSUInteger size) { (void)entity; (void)size; }

static NSUInteger checks;
static void Require(BOOL value, NSString *message) {
    checks++;
    if (!value) { fprintf(stderr,"Aqua footer failed: %s\n",[message UTF8String]); exit(1); }
}
static void CheckFooter(TGMessageItem *item, CGFloat width, BOOL flipped) {
    CGFloat height=TGMessageReactionFooterHeight(item,width);
    NSRect band=NSMakeRect(8,12,width,height);
    NSRect time=TGMessageReactionTimeRect(item,band,flipped);
    Require(!NSIsEmptyRect(time),@"settled footer must contain timestamp");
    NSRect metadata=time; metadata.size.width+=TGOutgoingStatusDotsWidthForItem(item)+(TGOutgoingStatusDotsWidthForItem(item)>0 ? 5.0 : 0.0);
    Require(NSContainsRect(band,metadata),@"timestamp plus unchanged check slot stays inside footer");
    NSArray *chips=TGReactionChipLayoutForItem(item,TGMessageReactionContentWidth(item,width));
    for(NSDictionary *entry in chips) {
        NSRect local=[[entry objectForKey:@"frame"] rectValue];
        NSRect chip=NSMakeRect(NSMinX(band)+NSMinX(local),flipped ? NSMinY(band)+2+NSMinY(local) : NSMaxY(band)-2-NSMaxY(local),NSWidth(local),NSHeight(local));
        Require(NSContainsRect(band,chip),@"every wrapped chip fits footer");
        Require(!NSIntersectsRect(chip,metadata),@"chip cannot overlap time/checks, including last row");
    }
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:600 pixelsHigh:800 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    TGDrawReactionChipsForItem(item,NSMakeRect(NSMinX(band),NSMinY(band),TGMessageReactionContentWidth(item,width),height),flipped);
    TGDrawOutgoingStatusDotsForItem(item,time,flipped);
    [NSGraphicsContext restoreGraphicsState];
}
int main(int argc,const char **argv) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    BOOL aqua=argc>1 && strcmp(argv[1],"aqua")==0;
    [[NSUserDefaults standardUserDefaults] setObject:aqua ? @"aqua" : @"classic" forKey:TGInterfaceDesignDefaultsKey];
    Require(TGInterfaceDesignIsAqua()==aqua,@"production design gate selects requested process mode");
    TGSetChatMessagesAsBlocksEnabled(NO);
    for(NSNumber *outgoing in [NSArray arrayWithObjects:@NO,@YES,nil]) {
        TGMessageItem *item=[[[TGMessageItem alloc] initWithChatID:@1 messageID:@2 date:@1720000000 outgoing:[outgoing boolValue] preview:@"Hi"] autorelease];
        [item setContentType:@"messageText"];
        for(NSNumber *level in [NSArray arrayWithObjects:@0,@1,@2,@3,nil]) {
            TGSetChatMessageTextSizeLevel([level integerValue]);
            [item setReactionSummary:nil];
            Require(TGMessageUsesInlineMetadataForItem(item,420,NO),@"plain short text remains compact");
            [item setReactionSummary:@"❤️ 1"];
            Require(TGMessageUsesInlineMetadataForItem(item,420,NO)==aqua,@"only Aqua puts one short reaction beside text");
            NSRect bubble=TGMessageBubbleRectForItem(item,NSMakeRect(0,0,640,1000),NO);
            if(aqua) for(NSNumber *flip in [NSArray arrayWithObjects:@NO,@YES,nil]) {
                NSRect body=TGMessageInlineTextRectForItem(item,bubble,[flip boolValue]);
                NSRect chip=TGMessageInlineReactionRectForItem(item,bubble,[flip boolValue]);
                NSRect time=TGMessageInlineTimeRectForItem(item,bubble,[flip boolValue]);
                NSRect metadata=time;metadata.size.width+=TGOutgoingStatusDotsWidthForItem(item)+(TGOutgoingStatusDotsWidthForItem(item)>0 ? 5.0 : 0.0);
                Require(NSContainsRect(bubble,body)&&NSContainsRect(bubble,chip)&&NSContainsRect(bubble,metadata),@"compact row contains body/chip/complete metadata");
                Require(!NSIntersectsRect(body,chip)&&!NSIntersectsRect(chip,metadata)&&!NSIntersectsRect(body,metadata),@"compact row parts are disjoint");
                Require(NSHeight(bubble)<=50,@"single reaction preserves compact row height");
            }
            Require(!TGMessageUsesInlineMetadataForItem(item,80,NO),@"narrow width forces lower footer");
            for(NSString *summary in [NSArray arrayWithObjects:@"❤️ 9999999999",@"❤️ 1  👍 2",@"❤️ 99999  👍 888888  😁 77  🔥 1234567890  🎉 1",nil]) {
                [item setReactionSummary:summary];
                Require(!TGMessageUsesInlineMetadataForItem(item,420,NO),@"wide count/multiple reactions always lower footer");
                for(NSNumber *width in [NSArray arrayWithObjects:@120,@160,@300,nil]) for(NSNumber *flip in [NSArray arrayWithObjects:@NO,@YES,nil]) CheckFooter(item,[width doubleValue],[flip boolValue]);
            }
            [item setReactionSummary:@"❤️ 1"];
            [item setContentType:@"messagePhoto"];
            Require(!TGMessageUsesInlineMetadataForItem(item,420,NO),@"media caption never incorrectly enters text-only compact mode");
            NSRect mediaBubble=TGMessageBubbleRectForItem(item,NSMakeRect(0,0,400,1000),NO);
            CGFloat footer=TGReactionBandHeightForMessageItemWidth(item,NSWidth(mediaBubble));
            Require(NSHeight(mediaBubble)>footer+20,@"media bubble reserves body and footer independently");
            [item setContentType:@"messageText"];
        }
        TGSetChatMessagesAsBlocksEnabled(YES);
        Require(!TGMessageUsesInlineMetadataForItem(item,420,NO),@"block rows retain block layout");
        CheckFooter(item,160,YES);
        TGSetChatMessagesAsBlocksEnabled(NO);
        [item setReactionSummary:@"❤️ 1  👍 2  🔥 3"];
        [item setReactionAnimationDisplaySummary:[item reactionSummary]];
        [item setReactionAnimationChangesHeight:YES];
        [item setReactionAnimationRemoving:NO];
        for(NSNumber *progress in [NSArray arrayWithObjects:@0,@0.1,@0.3,@0.5,@1,nil]) {
            [item setReactionAnimationProgress:[progress doubleValue]];
            CGFloat height=TGMessageReactionFooterHeight(item,120);
            NSRect band=NSMakeRect(0,0,120,height), time=TGMessageReactionTimeRect(item,band,YES);
            Require(NSIsEmptyRect(time)||NSContainsRect(band,time),@"animated metadata stays hidden until its row fits");
        }
    }
    printf("Aqua footer probe %s: %lu checks PASS\n",aqua ? "aqua" : "classic",(unsigned long)checks);
    [pool drain];return 0;
}
