#import <Cocoa/Cocoa.h>
#import "TGAquaChatInfoPanel.h"
#import "TGAquaShellViews.h"
#import "TGStatusViewComponents.h"
#import "TGLocalization.h"
#include <assert.h>

/* Exercise actual panel, NSViewAnimation and localized text layout. Avatar
   raster/asset policy is covered separately; this double only owns its data. */
static BOOL Animate = NO;
BOOL TGInterfaceAnimationsEnabledForView(NSView *view) { return Animate && [[view window] isVisible]; }
NSColor *TGColorFromHex(NSUInteger hex) { return [NSColor colorWithCalibratedRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1]; }
void TGDrawTemplateIconAsset(NSString *name,NSRect rect,NSColor *ink,CGFloat alpha,BOOL flipped) { (void)name;(void)rect;(void)ink;(void)alpha;(void)flipped; }
@implementation TGNavigationButtonCell
@synthesize badgeText=_badgeText,iconOnly=_iconOnly;
- (void)dealloc { [_badgeText release];[super dealloc]; }
@end
@implementation TGProfileAvatarView
@synthesize displayName=_displayName,avatarLocalPath=_avatarLocalPath;
- (void)dealloc { [_displayName release];[_avatarLocalPath release];[super dealloc]; }
@end
@interface PanelTarget : NSObject { @public NSUInteger closed,media,details; }
@end
@implementation PanelTarget
- (void)closeAquaChatInfo:(TGAquaChatInfoPanel *)sender { (void)sender; }
- (void)aquaChatInfoPanelDidClose:(id)sender { (void)sender;closed++; }
- (void)openAquaChatInfoMedia:(id)sender { media+=(NSUInteger)[sender tag]+1; }
- (void)openAquaChatInfoDetails:(id)sender { (void)sender;details++; }
@end
static void Spin(void) { NSDate *end=[NSDate dateWithTimeIntervalSinceNow:0.35];while([end timeIntervalSinceNow]>0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]; }
static void Contains(NSRect outer, NSRect inner) {
    assert(NSMinX(inner)>=NSMinX(outer)-0.01 && NSMinY(inner)>=NSMinY(outer)-0.01);
    assert(NSMaxX(inner)<=NSMaxX(outer)+0.01 && NSMaxY(inner)<=NSMaxY(outer)+0.01);
}
int main(void) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];[NSApplication sharedApplication];
    NSUInteger cases=0,layouts=0;
    for(CGFloat x=-1000;x<=1000;x+=1000) for(CGFloat width=300;width<=1800;width+=17) for(NSUInteger open=0;open<2;open++) {
        NSRect available=NSMakeRect(x,20,width,560);
        TGAquaChatInfoGeometry geometry=TGAquaChatInfoFrames(available,open);
        if (!open) { assert(NSEqualRects(available,geometry.conversation));assert(NSIsEmptyRect(geometry.panel)); }
        else {
            Contains(available,geometry.panel); assert(NSHeight(geometry.panel)==560);
            if(width>=700) { assert(!geometry.replacesConversation);Contains(available,geometry.conversation);assert(NSWidth(geometry.conversation)>=374);assert(NSMinX(geometry.panel)-NSMaxX(geometry.conversation)==6); }
            else { assert(geometry.replacesConversation);assert(NSEqualRects(available,geometry.panel)); }
        }
        cases++;
    }
    NSWindow *window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1000,650) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [window setReleasedWhenClosed:NO];[window orderFront:nil];
    PanelTarget *target=[[[PanelTarget alloc] init] autorelease];
    TGAquaChatInfoPanel *panel=[[TGAquaChatInfoPanel alloc] initWithFrame:NSZeroRect];[panel setTarget:target];[[window contentView] addSubview:panel];
    NSDictionary *profile=[NSDictionary dictionaryWithObjectsAndKeys:@"Имя пользователя с очень длинной фамилией",@"display_name",@"long_username",@"username",@"1234567890",@"phone_number",@"Длинное описание профиля. Здесь можно прочитать информацию целиком, ничего не обрезая.\nВторая строка описания.",@"bio",nil];
    NSDictionary *summary=[NSDictionary dictionaryWithObjectsAndKeys:profile,@"profile",@"Длинное название группы с обсуждениями, путешествиями и фотографиями",@"title",@"supergroup",@"kind",[NSNumber numberWithInteger:120000],@"member_count",nil];
    NSString *previous=[TGLanguageCode() copy];
    for(NSString *language in [NSArray arrayWithObjects:@"ru",@"en",@"be",nil]) {
        TGSetLanguageCode(language);
        for(CGFloat width=300;width<=620;width+=80) {
            [panel presentInFrame:NSMakeRect(20,20,width,520) animated:NO];[panel showSummary:summary loading:NO error:nil];
            NSView *document=[panel valueForKey:@"documentView"];
            for(NSView *view in [document subviews]) Contains([document bounds],[view frame]);
            NSScrollView *scroll=[panel valueForKey:@"scrollView"];Contains([panel bounds],[scroll frame]);
            NSButton *close=[panel valueForKey:@"closeButton"];Contains([panel bounds],[close frame]);
            assert([panel acceptsFirstResponder]);
            NSTextField *name=[panel valueForKey:@"nameField"],*details=[panel valueForKey:@"detailsField"];
            assert(NSHeight([name frame])>=ceil([[name cell] cellSizeForBounds:NSMakeRect(0,0,NSWidth([name frame]),100000)].height));
            assert(NSHeight([details frame])>=ceil([[details cell] cellSizeForBounds:NSMakeRect(0,0,NSWidth([details frame]),100000)].height));
            NSArray *buttons=[panel valueForKey:@"actionButtons"];
            for(NSButton *button in buttons) {
                assert([[button toolTip] isEqual:[button title]]);
                NSRect title=[[button cell] titleRectForBounds:[button bounds]];
                NSSize text=[[button title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[button font] forKey:NSFontAttributeName]];
                assert(text.width<=NSWidth(title));
            }
            layouts++;
        }
    }
    TGSetLanguageCode(previous);[previous release];
    NSArray *buttons=[panel valueForKey:@"actionButtons"];
    for(NSButton *button in buttons) [button performClick:nil]; assert(target->media==10 && target->details==1);
    [panel closeAnimated:NO];assert([panel isHidden] && target->closed==1 && ![panel isClosing]);
    Animate=YES;
    [panel presentInFrame:NSMakeRect(20,20,320,520) animated:YES];assert(![panel isHidden]);Spin();assert([panel valueForKey:@"animation"]==nil);
    [panel closeAnimated:YES];assert([panel isClosing]);Spin();assert([panel isHidden] && target->closed==2);
    [panel presentInFrame:NSMakeRect(20,20,320,520) animated:YES];[panel closeAnimated:YES];
    [panel presentInFrame:NSMakeRect(20,20,320,520) animated:YES];Spin();assert(![panel isHidden] && ![panel isClosing] && target->closed==2);
    [panel hideImmediately];[panel presentInFrame:NSMakeRect(20,20,320,520) animated:YES];
    [panel presentInFrame:NSMakeRect(20,20,440,520) animated:YES];Spin();assert(NSEqualRects([panel frame],NSMakeRect(20,20,440,520)) && ![panel isHidden]);
    [panel closeAnimated:YES];[panel hideImmediately];Spin();assert([panel isHidden] && target->closed==2);
    [panel setTarget:nil];[panel removeFromSuperview];[panel release];[window close];
    printf("Aqua profile panel: %lu geometry cases, %lu real localized layouts, media actions, immediate/animated close, interrupted open/close/resize, detach PASS.\n",(unsigned long)cases,(unsigned long)layouts);
    [pool drain];return 0;
}
