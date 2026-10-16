#import "TGDownloadCompactPopover.h"
#import "TGDownloadManagerPresentation.h"
#import "TGLocalization.h"
#import "TGIconAssets.h"
#import "TGAquaAppearance.h"
#import "TGAquaShellViews.h"
#import "TGTheme.h"
#import "TGAnimationSupport.h"

@interface TGDownloadCompactButton : NSButton {
    NSString *_identifier, *_queueAction;
}
@property(nonatomic,copy) NSString *identifier, *queueAction;
@end
@implementation TGDownloadCompactButton
@synthesize identifier=_identifier,queueAction=_queueAction;
- (void)dealloc {[_identifier release];[_queueAction release];[super dealloc];}
@end
@interface TGDownloadCompactBody : NSView
@end
@implementation TGDownloadCompactBody
- (BOOL)isFlipped {return YES;}
- (void)drawRect:(NSRect)dirty {
    (void)dirty;[[NSColor whiteColor] set];NSRectFill([self bounds]);
    NSRect header=NSMakeRect(0,0,NSWidth([self bounds]),38),footer=NSMakeRect(0,NSHeight([self bounds])-48,NSWidth([self bounds]),48);
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:header],header,TGThemeSurfaceHeader,YES);
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:footer],footer,TGThemeSurfaceHeader,YES);
}
@end
@interface TGDownloadCompactPopover ()
- (void)rebuildContent;
- (void)rowAction:(TGDownloadCompactButton *)sender;
- (void)showAll:(id)sender;
@end
@implementation TGDownloadCompactPopover
- (id)initWithTarget:(id<TGDownloadCompactPopoverTarget>)target {
    self=[super init];if(self){_target=target;_items=[[NSArray alloc] init];}return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];[_popover setDelegate:nil];[_popover close];
    [_popover release];[_contentController release];[_items release];[_anchor release];[super dealloc];
}
- (NSTextField *)label:(NSString *)text font:(NSFont *)font frame:(NSRect)frame detail:(BOOL)detail {
    NSTextField *field=[[[NSTextField alloc] initWithFrame:frame] autorelease];
    [field setStringValue:text?text:@""];[field setEditable:NO];[field setSelectable:NO];[field setBezeled:NO];[field setDrawsBackground:NO];[field setFont:font];
    [field setTextColor:detail?TGClassicCardMutedInkColor():TGClassicCardInkColor()];[[field cell] setLineBreakMode:NSLineBreakByTruncatingTail];[field setToolTip:text];return field;
}
- (TGDownloadCompactButton *)button:(NSString *)title asset:(NSString *)asset action:(NSString *)action identifier:(NSString *)identifier frame:(NSRect)frame {
    TGDownloadCompactButton *button=[[[TGDownloadCompactButton alloc] initWithFrame:frame] autorelease];
    if(asset){TGAquaUtilityButtonCell *cell=[[[TGAquaUtilityButtonCell alloc] initTextCell:@""] autorelease];[cell setIconOnly:YES];[cell setIconAssetName:asset];[button setCell:cell];}
    else [button setCell:[[[TGSecondaryTextButtonCell alloc] initTextCell:title] autorelease]];
    [button setTitle:asset?@"":title];[button setToolTip:title];[button setBordered:NO];[button setButtonType:NSMomentaryPushInButton];
    button.identifier=identifier;button.queueAction=action;[button setTarget:self];[button setAction:@selector(rowAction:)];return button;
}
- (void)reloadWithItems:(NSArray *)items {
    [_items release];_items=[items copy];
    if([_popover isShown]) [self rebuildContent];
}
- (void)rebuildContent {
    NSMutableArray *visible=[NSMutableArray array];
    // Active transfers first; every record remains accessible in All Downloads.
    for(NSUInteger pass=0;pass<2;pass++) for(NSDictionary *item in _items){
        BOOL active=[[item objectForKey:@"can_cancel"] boolValue];
        if(active!=(pass==0) || [visible count]>=4) continue;[visible addObject:item];
    }
    CGFloat width=430,height=38+MAX(1,[visible count])*84+48;
    TGDownloadCompactBody *body=[[[TGDownloadCompactBody alloc] initWithFrame:NSMakeRect(0,0,width,height)] autorelease];
    NSTextField *heading=[self label:TGLoc(@"downloads.compact.title") font:[NSFont boldSystemFontOfSize:14] frame:NSMakeRect(14,9,width-28,22) detail:NO];[heading setAlignment:NSCenterTextAlignment];[body addSubview:heading];
    if(![visible count]) [body addSubview:[self label:TGLoc(@"downloads.empty") font:[NSFont systemFontOfSize:12] frame:NSMakeRect(18,68,width-36,20) detail:YES]];
    NSUInteger index=0;
    for(NSDictionary *item in visible){
        CGFloat y=38+index++*84;NSString *identifier=[item objectForKey:@"identifier"],*state=[item objectForKey:@"state"];
        BOOL paused=[state isEqual:@"paused"],progress=paused||[state isEqual:@"downloading"]||[state isEqual:@"queued"];
        BOOL retry=[state isEqual:@"failed"]||[state isEqual:@"cancelled"];
        NSString *path=[item objectForKey:@"saved_path"];
        NSImageView *icon=[[[NSImageView alloc] initWithFrame:NSMakeRect(14,y+20,30,36)] autorelease];[icon setImage:TGIconAssetImageNamed(@"document")];[icon setImageScaling:NSImageScaleProportionallyUpOrDown];[body addSubview:icon];
        CGFloat titleWidth=progress?width-138:width-80;
        [body addSubview:[self label:[item objectForKey:@"file_name"] font:[NSFont systemFontOfSize:12] frame:NSMakeRect(56,y+12,titleWidth,18) detail:NO]];
        long long total=[[item objectForKey:@"total_bytes"] longLongValue],downloaded=[[item objectForKey:@"downloaded_bytes"] longLongValue];
        NSString *detail=TGLoc([@"downloads.state." stringByAppendingString:[state length]?state:@"failed"]);
        if(progress){
            NSProgressIndicator *bar=[[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(58,y+34,width-146,12)] autorelease];[bar setStyle:NSProgressIndicatorBarStyle];[bar setControlSize:NSSmallControlSize];[bar setIndeterminate:NO];[bar setMinValue:0];[bar setMaxValue:1];[bar setDoubleValue:total>0?MAX(0,MIN(1,(double)downloaded/total)):0];[body addSubview:bar];
            detail=total>0?[NSString stringWithFormat:@"%@ / %@",TGDownloadManagerByteCount(downloaded),TGDownloadManagerByteCount(total)]:detail;
            TGDownloadCompactButton *pause=[self button:TGLoc(paused?@"downloads.resume":@"downloads.pause") asset:paused?@"play":@"pause" action:paused?@"resume":@"pause" identifier:identifier frame:NSMakeRect(width-76,y+25,28,28)];
            [pause setEnabled:[[item objectForKey:paused?@"can_resume":@"can_pause"] boolValue]];[body addSubview:pause];
            TGDownloadCompactButton *cancel=[self button:TGLoc(@"downloads.cancel") asset:@"cross" action:@"cancel" identifier:identifier frame:NSMakeRect(width-40,y+25,28,28)];[cancel setEnabled:[[item objectForKey:@"can_cancel"] boolValue]];[body addSubview:cancel];
        } else if([path length]||retry) {
            NSString *title=TGLoc(retry?@"downloads.retry":@"downloads.reveal");
            CGFloat actionWidth=MIN(190,ceil([title sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]].width)+28);
            [body addSubview:[self button:title asset:nil action:retry?@"retry":@"reveal" identifier:identifier frame:NSMakeRect(width-actionWidth-14,y+42,actionWidth,28)]];
            titleWidth=width-actionWidth-84;
        }
        [body addSubview:[self label:detail font:[NSFont systemFontOfSize:10.5] frame:NSMakeRect(56,y+(progress?52:40),MAX(70,titleWidth),17) detail:YES]];
    }
    NSString *all=TGLoc(@"downloads.all");CGFloat allWidth=MAX(180,ceil([all sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]].width)+32);
    NSButton *allButton=[[[NSButton alloc] initWithFrame:NSMakeRect((width-allWidth)/2,height-39,allWidth,30)] autorelease];[allButton setCell:[[[TGSecondaryTextButtonCell alloc] initTextCell:all] autorelease]];[allButton setTitle:all];[allButton setTarget:self];[allButton setAction:@selector(showAll:)];[body addSubview:allButton];
    [_contentController setView:body];[_popover setContentSize:NSMakeSize(width,height)];
}
- (BOOL)toggleRelativeToView:(NSView *)anchor {
    if([_popover isShown]){[self close];return YES;}
    if(!anchor || ![[anchor window] isVisible] || [[anchor window] isMiniaturized])return NO;
    if(!_popover){_popover=[[NSPopover alloc] init];[_popover setBehavior:NSPopoverBehaviorTransient];[_popover setDelegate:self];_contentController=[[NSViewController alloc] initWithNibName:nil bundle:nil];[_popover setContentViewController:_contentController];}
    [_popover setAnimates:TGInterfaceAnimationsEnabledForView(anchor)];
    [_anchor release];_anchor=[anchor retain];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentClosed:) name:NSWindowWillCloseNotification object:[anchor window]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentClosed:) name:NSWindowWillMiniaturizeNotification object:[anchor window]];
    [self rebuildContent];[_popover showRelativeToRect:[anchor bounds] ofView:anchor preferredEdge:NSMinYEdge];return YES;
}
- (void)popoverDidClose:(NSNotification *)notification {(void)notification;if([_popover isShown])return;[[NSNotificationCenter defaultCenter] removeObserver:self];[_anchor release];_anchor=nil;}
- (void)parentClosed:(NSNotification *)notification {(void)notification;[self close];}
- (void)close {[_popover close];}
- (void)rowAction:(TGDownloadCompactButton *)sender {[_target compactDownloadPerformAction:sender.queueAction identifier:sender.identifier];}
- (void)showAll:(id)sender {(void)sender;[self close];[_target compactDownloadShowAll];}
@end
