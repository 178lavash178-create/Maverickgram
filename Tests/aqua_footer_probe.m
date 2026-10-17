#import <Cocoa/Cocoa.h>
#import "TGMessageItem.h"
#import "TGMessageLayoutSupport.h"
#import "TGChatDisplayPreferences.h"
#import "TGTheme.h"
#import "TGThemeContrast.h"
#import "TGIconAssets.h"
#import "TGInterfaceDesign.h"
#import "TGLocalization.h"
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
    NSRect reply=TGMessageReplyIndicatorRectForTimeRect(item,time);
    if (!NSIsEmptyRect(reply)) metadata=NSUnionRect(metadata,reply);
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

static void CheckReactionsBelowBodyAcrossThemes(void) {
    // These are the same measured text and footer rectangles used by the cell.
    // Exercise geometry without changing receipt assets, paint or chip colors.
    NSString *originalTheme=[[TGCurrentThemeIdentifier() copy] autorelease];
    for(NSString *theme in TGThemeIdentifiers()) {
        NSAutoreleasePool *iteration=[[NSAutoreleasePool alloc] init];
        TGSetActiveThemeIdentifier(theme);
        for(NSNumber *level in [NSArray arrayWithObjects:@0,@3,nil]) {
            TGSetChatMessageTextSizeLevel([level integerValue]);
            for(NSNumber *outgoing in [NSArray arrayWithObjects:@NO,@YES,nil]) {
                for(NSString *text in [NSArray arrayWithObjects:@"Hi",@"مرحبا بالعالم",@"A long message that wraps onto several lines at narrow widths and must keep reactions below the complete message text.",nil]) {
                    TGMessageItem *item=[[[TGMessageItem alloc] initWithChatID:@1 messageID:@2 date:@1720000000 outgoing:[outgoing boolValue] preview:text] autorelease];
                    [item setContentType:@"messageText"];
                    for(NSString *summary in [NSArray arrayWithObjects:@"❤️ 1",@"❤️ 9999999999",@"❤️ 1  👍 22  🔥 333  🎉 4444",nil]) {
                        [item setReactionSummary:summary];
                        for(NSNumber *width in [NSArray arrayWithObjects:@240,@400,@640,nil]) {
                            CGFloat available=[width doubleValue],maximum=TGMaximumBubbleWidthForItem(item,available);
                            Require(!TGMessageUsesInlineMetadataForItem(item,maximum,NO),@"every theme rejects inline reactions, including short and RTL text");
                            NSRect bubble=TGMessageBubbleRectForItem(item,NSMakeRect(0,0,available,1000),NO);
                            CGFloat footer=TGReactionBandHeightForMessageItemWidth(item,NSWidth(bubble));
                            NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:TGChatMessageBodyFont(),NSFontAttributeName,TGMessageTextParagraphStyle(),NSParagraphStyleAttributeName,nil];
                            NSAttributedString *bodyText=TGAttributedMessageStringForItem(item,TGDisplayTextForMessageItem(item),attributes);
                            CGFloat textHeight=ceil(NSHeight([bodyText boundingRectWithSize:NSMakeSize(maximum-24,12000) options:NSStringDrawingUsesLineFragmentOrigin]));
                            for(NSNumber *flip in [NSArray arrayWithObjects:@NO,@YES,nil]) {
                                BOOL flipped=[flip boolValue];
                                NSRect body=NSMakeRect(NSMinX(bubble)+12,flipped?NSMinY(bubble)+9:NSMaxY(bubble)-9-textHeight,NSWidth(bubble)-24,textHeight+2);
                                NSRect band=NSMakeRect(NSMinX(bubble)+10,flipped?NSMaxY(bubble)-footer:NSMinY(bubble),NSWidth(bubble)-20,footer);
                                Require(NSContainsRect(bubble,body)&&NSContainsRect(bubble,band),@"message and lower reaction band remain in bubble");
                                Require(flipped?NSMaxY(body)<NSMinY(band):NSMaxY(band)<NSMinY(body),@"reaction band is strictly below complete text, never on its baseline");
                                Require(NSIsEmptyRect(TGMessageInlineReactionRectForItem(item,bubble,flipped)),@"obsolete inline route supplies no drawable reaction rectangle");
                                NSRect time=TGMessageReactionTimeRect(item,band,flipped),metadata=time;
                                CGFloat status=TGOutgoingStatusDotsWidthForItem(item);metadata.size.width+=status+(status>0?5:0);
                                Require(!NSIsEmptyRect(time)&&NSContainsRect(band,metadata),@"time and unchanged delivery-check width stay in lower footer");
                                Require(fabs(NSMaxX(metadata)-(NSMaxX(band)-2))<0.01,@"time/check unit remains anchored at bottom-right edge");
                                for(NSDictionary *entry in TGReactionChipLayoutForItem(item,TGMessageReactionContentWidth(item,NSWidth(band)))) {
                                    NSRect local=[[entry objectForKey:@"frame"] rectValue];
                                    NSRect chip=NSMakeRect(NSMinX(band)+NSMinX(local),flipped?NSMinY(band)+2+NSMinY(local):NSMaxY(band)-2-NSMaxY(local),NSWidth(local),NSHeight(local));
                                    Require(NSContainsRect(band,chip)&&!NSIntersectsRect(chip,body)&&!NSIntersectsRect(chip,metadata),@"wrapped reaction chips never overlap message, timestamp or checks");
                                }
                            }
                        }
                    }
                }
            }
        }
        [iteration drain];
    }
    TGSetActiveThemeIdentifier(originalTheme);
    TGSetChatMessageTextSizeLevel(TGChatMessageTextSizeNormal);
}

static void CheckCommentPresentation(void) {
    for (NSNumber *outgoing in [NSArray arrayWithObjects:@NO,@YES,nil]) {
        TGMessageItem *item=[[[TGMessageItem alloc] initWithChatID:@1 messageID:@2 date:@1720000000 outgoing:[outgoing boolValue] preview:@"Thanks"] autorelease];
        [item setContentType:@"messageText"];
        [item setCanGetMessageThread:YES];
        for (NSInteger level=0;level<=3;level++) {
            TGSetChatMessageTextSizeLevel(level);
            for (id count in [NSArray arrayWithObjects:[NSNull null],@0,@1,@5,@10000,nil]) {
                [item setMessageThreadReplyCount:count==[NSNull null] ? nil : count];
                BOOL hasReplies=count!=[NSNull null] && [count integerValue]>0;
                Require(TGMessageItemHasCommentThread(item),@"ordinary group retains context-menu thread capability even without replies");
                Require(!TGMessageItemShowsCommentBar(item),@"ordinary groups never draw a clickable channel discussion bar");
                Require(TGMessageCommentBarHeightForItem(item)==0,@"ordinary groups reserve no channel discussion height");
                Require((TGMessageReplyIndicatorWidthForItem(item)>0)==hasReplies,@"only a positive group reply count reserves passive metadata");
                for (NSNumber *available in [NSArray arrayWithObjects:@280,@400,@640,nil]) {
                    [item setReactionSummary:nil];
                    NSRect bubble=TGMessageBubbleRectForItem(item,NSMakeRect(0,0,[available doubleValue],1000),NO);
                    BOOL inlineMetadata=TGMessageUsesInlineMetadataForItem(item,NSWidth(bubble),NO);
                    if ([available doubleValue]>=640) Require(inlineMetadata,@"short group messages keep compact text and metadata when the measured unit fits");
                    if (!inlineMetadata) continue;
                    for (NSNumber *flip in [NSArray arrayWithObjects:@NO,@YES,nil]) {
                        BOOL flipped=[flip boolValue];
                        NSRect body=TGMessageInlineTextRectForItem(item,bubble,flipped);
                        NSRect time=TGMessageInlineTimeRectForItem(item,bubble,flipped);
                        NSRect indicator=TGMessageReplyIndicatorRectForTimeRect(item,time);
                        NSRect status=time;
                        status.size.width+=TGOutgoingStatusDotsWidthForItem(item)+(TGOutgoingStatusDotsWidthForItem(item)>0?5.0:0.0);
                        Require(NSContainsRect(bubble,body)&&NSContainsRect(bubble,status),@"group text, time and delivery checks remain inside compact bubble");
                        Require(NSIsEmptyRect(TGMessageCommentBarRectForItem(item,bubble,flipped)),@"ordinary group has no clickable discussion hit target");
                        Require(NSIsEmptyRect(indicator)!=hasReplies,@"zero/nil counts have no visible passive indicator");
                        if (hasReplies) {
                            Require(NSContainsRect(bubble,indicator),@"passive reply icon/count remain inside the bubble");
                            Require(!NSIntersectsRect(body,indicator)&&!NSIntersectsRect(indicator,status),@"passive reply indicator is separate from text, time and checks");
                            Require(fabs(NSMinX(time)-NSMaxX(indicator)-7.0)<0.01,@"reply icon/count sit immediately before time with a fixed gap");
                            Require(fabs(NSMidY(indicator)-NSMidY(time))<0.01,@"passive count and timestamp share a baseline band in both coordinate systems");
                        }
                    }
                }
                for (NSString *reactions in [NSArray arrayWithObjects:@"❤️ 1",@"❤️ 11  👍 5  🔥 10000",nil]) {
                    [item setReactionSummary:reactions];
                    for (NSNumber *width in [NSArray arrayWithObjects:@160,@240,@360,nil])
                        for (NSNumber *flip in [NSArray arrayWithObjects:@NO,@YES,nil])
                            CheckFooter(item,[width doubleValue],[flip boolValue]);
                }
            }
            [item setReactionSummary:nil];
            [item setChannelPost:YES];
            for (NSNumber *count in [NSArray arrayWithObjects:@0,@5,nil]) {
                [item setMessageThreadReplyCount:count];
                Require(TGMessageItemShowsCommentBar(item),@"channel posts retain actionable discussions for zero and positive reply counts");
                Require(TGMessageReplyIndicatorWidthForItem(item)==0,@"channel discussion does not duplicate a group reply indicator");
                NSRect bubble=TGMessageBubbleRectForItem(item,NSMakeRect(0,0,400,1000),NO);
                Require(!TGMessageUsesInlineMetadataForItem(item,NSWidth(bubble),NO),@"channel discussions keep a separate action row");
                for (NSNumber *flip in [NSArray arrayWithObjects:@NO,@YES,nil]) {
                    BOOL flipped=[flip boolValue];
                    NSRect bar=TGMessageCommentBarRectForItem(item,bubble,flipped);
                    NSRect body=TGMessageContentRectByRemovingFooter(bubble,TGMessageCommentBarHeightForItem(item),flipped);
                    Require(!NSIsEmptyRect(bar)&&NSContainsRect(bubble,bar),@"channel discussion control remains visible and contained");
                    Require(!NSIntersectsRect(NSInsetRect(body,0,4),bar),@"channel discussion action stays outside message body");
                }
            }
            [item setChannelPost:NO];
        }
    }
    TGSetChatMessageTextSizeLevel(TGChatMessageTextSizeNormal);
}
static void CheckFooterIndicators(void) {
    TGMessageItem *item=[[[TGMessageItem alloc] initWithChatID:@1 messageID:@2 date:@1720000000 outgoing:YES preview:@"Pinned body must remain completely free of footer flags."] autorelease];
    [item setContentType:@"messageText"];
    Require(TGMessageFooterIndicatorsWidthForItem(item)==0,@"unknown viewer count creates no artificial zero");
    [item setMessageViewCount:@0];
    Require(TGMessageFooterIndicatorsWidthForItem(item)==0,@"zero channel aggregate is not invented group readership");
    [item setMessageViewerCount:@0];
    Require(TGMessageFooterIndicatorsWidthForItem(item)>0,@"confirmed zero group viewers remain visible");
    [item setMessageViewerCount:nil];
    for(NSString *theme in TGThemeIdentifiers()) {
        TGSetActiveThemeIdentifier(theme);
        for(NSNumber *value in [NSArray arrayWithObjects:@1,@27,@9999999999LL,nil]) {
            [item setMessageViewCount:value];[item setPinned:YES];[item setMessageThreadReplyCount:@99];
            Require(TGMessageFooterIndicatorsWidthForItem(item)>TGMessageReplyIndicatorWidthForItem(item)+16,@"count, pin and replies each reserve width");
            for(NSNumber *flip in [NSArray arrayWithObjects:@NO,@YES,nil]) {
                NSRect bubble=TGMessageBubbleRectForItem(item,NSMakeRect(0,0,640,1000),NO);
                NSRect time=NSMakeRect(NSMaxX(bubble)-80,NSMaxY(bubble)-22,50,14);
                NSRect indicators=TGMessageFooterIndicatorsRectForTimeRect(item,time);
                Require(NSContainsRect(bubble,indicators)&&NSMaxX(indicators)==NSMinX(time),@"pin/views/replies fit beside time, never over text");
                [item setReactionSummary:@"❤️ 1  👍 99"];
                CGFloat h=TGMessageReactionFooterHeight(item,280);
                NSRect band=NSMakeRect(0,0,280,h);NSRect reactionTime=TGMessageReactionTimeRect(item,band,[flip boolValue]);
                NSRect all=NSUnionRect(reactionTime,TGMessageFooterIndicatorsRectForTimeRect(item,reactionTime));
                all.size.width+=TGOutgoingStatusDotsWidthForItem(item)+5;
                Require(!NSIsEmptyRect(reactionTime)&&NSContainsRect(band,all),@"reaction footer reserves complete pin/views/replies/time/checks unit");
                [item setReactionSummary:nil];
            }
        }
    }
    [item setPinned:NO]; [item setMessageThreadReplyCount:nil]; [item setMessageViewCount:nil];
    [item setReactionSummary:@"❤️ 1  👍 1"];
    BOOL countForcesWrap=NO;
    for (CGFloat width=160;width<=420;width+=1) {
        [item setMessageViewerCount:nil]; CGFloat without=TGMessageReactionFooterHeight(item,width);
        [item setMessageViewerCount:@3]; CGFloat with=TGMessageReactionFooterHeight(item,width);
        if (with>without+1) { countForcesWrap=YES; break; }
    }
    Require(countForcesWrap,@"restoring a cached readership count can force a genuine production footer wrap and needs row-height invalidation");
    TGSetActiveThemeIdentifier(@"vk-blue");
}

static void CheckNarrowMetadataFooters(void) {
    TGSetChatMessagesAsBlocksEnabled(NO);
    BOOL exercisedWrap=NO,exercisedWiderBubble=NO;
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {
        TGSetLanguageCode(language);
        for(NSInteger level=0;level<4;level++) {
            TGSetChatMessageTextSizeLevel(level);
            for(NSNumber *width in [NSArray arrayWithObjects:@220,@240,@296,nil])
            for(NSUInteger media=0;media<3;media++) for(NSUInteger reactions=0;reactions<2;reactions++)
            for(NSUInteger outgoing=0;outgoing<2;outgoing++) for(NSUInteger flip=0;flip<2;flip++) {
                TGMessageItem *item=[[[TGMessageItem alloc] initWithChatID:@-42 messageID:@2 date:@1720000000 outgoing:outgoing preview:@"Hi"] autorelease];
                item.contentType=media?@"messagePhoto":@"messageText";item.pinned=YES;
                item.messageViewerCount=@3;item.messageThreadReplyCount=@99;
                if(media){item.mediaWidth=@640;item.mediaHeight=@480;item.messageViewCount=@2147483647;}
                if(media==2)item.mediaItems=[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@2,@"message_id",@640,@"width",@480,@"height",nil],[NSDictionary dictionaryWithObjectsAndKeys:@3,@"message_id",@480,@"width",@640,@"height",nil],nil];
                if(reactions)item.reactionSummary=@"❤️ 1  👍 99";
                CGFloat cellWidth=[width doubleValue];NSRect cell=NSMakeRect(0,0,cellWidth,1600);
                NSRect bubble=TGMessageBubbleRectForItem(item,cell,NO);
                Require(NSMinX(bubble)>=14 && NSMaxX(bubble)<=cellWidth-14,@"narrow metadata host preserves real side gutters");
                Require(NSHeight(bubble)+10<=TGMessageBubbleHeightForItem(item,cellWidth,NO)+.1,@"table height reserves full widened/wrapped footer geometry");
                if(NSWidth(bubble)>TGMaximumBubbleWidthForItem(item,cellWidth)+.1)exercisedWiderBubble=YES;
                CGFloat innerWidth=NSWidth(bubble)-24;
                NSString *time=TGShortTimeStringFromDateValue(item.date);NSSize size=[time sizeWithAttributes:[NSDictionary dictionaryWithObject:TGChatMessageMetaFont() forKey:NSFontAttributeName]];
                CGFloat status=TGOutgoingStatusDotsWidthForItem(item),h=MAX(12,ceil(size.height)+2);
                NSRect timeRect=NSMakeRect(NSMaxX(bubble)-size.width-status-(status>0?5:0)-12,flip?NSMaxY(bubble)-h-4:NSMinY(bubble)+4,size.width,h);
                NSRect footerHost=bubble;
                if(reactions){CGFloat bandHeight=TGMessageReactionFooterHeight(item,NSWidth(bubble)-20);footerHost=NSMakeRect(NSMinX(bubble)+10,flip?NSMaxY(bubble)-bandHeight:NSMinY(bubble),NSWidth(bubble)-20,bandHeight);innerWidth=NSWidth(footerHost);timeRect=TGMessageReactionTimeRect(item,footerHost,flip);}
                Require(!NSIsEmptyRect(timeRect),@"settled narrow footer retains timestamp with reactions and photo albums");
                NSRect indicators=TGMessageFooterIndicatorsRectInWidth(item,timeRect,innerWidth,flip);
                NSRect receipt=timeRect;receipt.size.width+=status+(status>0?5:0);NSRect all=NSUnionRect(receipt,indicators);
                if(!NSContainsRect(footerHost,all))fprintf(stderr,"narrow %s level%ld width%.0f media%lu reactions%lu out%lu flip%lu bubble%s host%s time%s indicators%s\n",[language UTF8String],(long)level,cellWidth,(unsigned long)media,(unsigned long)reactions,(unsigned long)outgoing,(unsigned long)flip,[NSStringFromRect(bubble) UTF8String],[NSStringFromRect(footerHost) UTF8String],[NSStringFromRect(timeRect) UTF8String],[NSStringFromRect(indicators) UTF8String]);
                Require(NSContainsRect(footerHost,all),@"pin/views/replies/time/checks stay inside actual narrow footer at every text size");
                NSRect pin=NSMakeRect(NSMinX(timeRect)-16,NSMinY(timeRect),16,NSHeight(timeRect));
                Require(NSContainsRect(footerHost,pin),@"pin remains next to timestamp on final line even when counts wrap");
                if(TGMessageFooterWrappedHeightForItem(item,innerWidth)>0){exercisedWrap=YES;Require(NSHeight(indicators)>h,@"physically narrow footer has a real reserved second metadata line");}
            }
        }
    }
    Require(exercisedWrap && exercisedWiderBubble,@"production cases exercise physical wrapping and gutter-safe width beyond decorative body cap");
    TGSetChatMessageTextSizeLevel(0);
}

int main(int argc,const char **argv) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    BOOL aqua=argc>1 && strcmp(argv[1],"aqua")==0;
    [[NSUserDefaults standardUserDefaults] setObject:aqua ? @"aqua" : @"classic" forKey:TGInterfaceDesignDefaultsKey];
    Require(TGInterfaceDesignIsAqua()==aqua,@"production design gate selects requested process mode");
    TGSetChatMessagesAsBlocksEnabled(NO);
    CheckReactionsBelowBodyAcrossThemes();
    CheckCommentPresentation();
    CheckNarrowMetadataFooters();
    NSString *originalLanguage=[[TGLanguageCode() copy] autorelease];
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"be",@"en",nil]) {TGSetLanguageCode(language);CheckFooterIndicators();}
    TGSetLanguageCode(originalLanguage);
    for(NSNumber *outgoing in [NSArray arrayWithObjects:@NO,@YES,nil]) {
        TGMessageItem *item=[[[TGMessageItem alloc] initWithChatID:@1 messageID:@2 date:@1720000000 outgoing:[outgoing boolValue] preview:@"Hi"] autorelease];
        [item setContentType:@"messageText"];
        for(NSNumber *level in [NSArray arrayWithObjects:@0,@1,@2,@3,nil]) {
            TGSetChatMessageTextSizeLevel([level integerValue]);
            [item setReactionSummary:nil];
            Require(TGMessageUsesInlineMetadataForItem(item,420,NO),@"plain short text remains compact");
            [item setReactionSummary:@"❤️ 1"];
            Require(!TGMessageUsesInlineMetadataForItem(item,420,NO),@"even one short reaction always uses the lower footer in every design");
            NSRect bubble=TGMessageBubbleRectForItem(item,NSMakeRect(0,0,640,1000),NO);
            for(NSNumber *flip in [NSArray arrayWithObjects:@NO,@YES,nil]) {
                Require(NSIsEmptyRect(TGMessageInlineReactionRectForItem(item,bubble,[flip boolValue])),@"legacy inline reaction geometry never shares the text baseline");
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
            Require(!TGMessageUsesInlineMetadataForItem(item,420,NO),@"animated reaction insertion never restores inline metadata");
            CGFloat height=TGMessageReactionFooterHeight(item,120);
            NSRect band=NSMakeRect(0,0,120,height), time=TGMessageReactionTimeRect(item,band,YES);
            Require(NSIsEmptyRect(time)||NSContainsRect(band,time),@"animated metadata stays hidden until its row fits");
        }
        [item setReactionSummary:nil];
        [item setReactionAnimationDisplaySummary:@"❤️ 1"];
        [item setReactionAnimationRemoving:YES];
        for(NSNumber *progress in [NSArray arrayWithObjects:@0,@0.5,@1,nil]) {
            [item setReactionAnimationProgress:[progress doubleValue]];
            Require(!TGMessageUsesInlineMetadataForItem(item,420,NO),@"departing single reaction remains below text until animation state clears");
        }
    }
    printf("Aqua footer probe %s: %lu checks PASS\n",aqua ? "aqua" : "classic",(unsigned long)checks);
    [pool drain];return 0;
}
