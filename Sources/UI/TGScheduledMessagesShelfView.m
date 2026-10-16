#import "TGScheduledMessagesShelfView.h"
#import "TGLocalization.h"
#import "TGTheme.h"
#import "TGAquaAppearance.h"
#import "TGAquaShellViews.h"
#import "TGAnimationSupport.h"

@interface TGScheduledShelfButton : NSButton { NSNumber *_messageID;NSString *_queueAction; }
@property(nonatomic,retain) NSNumber *messageID;
@property(nonatomic,copy) NSString *queueAction;
@end
@implementation TGScheduledShelfButton
@synthesize messageID=_messageID,queueAction=_queueAction;
- (void)dealloc {[_messageID release];[_queueAction release];[super dealloc];}
@end
@interface TGScheduledShelfDocument : NSView
@end
@implementation TGScheduledShelfDocument
- (BOOL)isFlipped {return YES;}
@end
@interface TGScheduledShelfRow : TGScheduledShelfDocument
@end
@implementation TGScheduledShelfRow
- (void)drawRect:(NSRect)dirty {(void)dirty;NSBezierPath *path=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds],0.5,0.5) xRadius:5 yRadius:5];[[NSColor whiteColor] set];[path fill];[TGClassicPanelStrokeColor() set];[path stroke];}
@end
@interface TGScheduledMessagesShelfView ()
- (void)rebuild;
- (void)rowAction:(TGScheduledShelfButton *)sender;
@end
@implementation TGScheduledMessagesShelfView
@synthesize target=_target;
- (id)initWithFrame:(NSRect)frame {self=[super initWithFrame:frame];if(self){_messages=[[NSArray alloc] init];[self rebuild];}return self;}
- (void)dealloc {TGCancelViewVisibilityAnimation(self);[_messages release];[_status release];[_scroll release];[super dealloc];}
- (void)presentAnimated:(BOOL)animated {
    TGCancelViewVisibilityAnimation(self);
    if(animated && ![self isHidden]) [self setHidden:YES];
    if(animated) TGSetViewVisibleAnimated(self,YES);
    else {[self setHidden:NO];[self setAlphaValue:1.0];}
}
- (void)hideImmediately {TGCancelViewVisibilityAnimation(self);[self setHidden:YES];[self setAlphaValue:1.0];}
- (void)viewWillMoveToSuperview:(NSView *)newSuperview {if(!newSuperview)[self hideImmediately];[super viewWillMoveToSuperview:newSuperview];}
- (void)setFrame:(NSRect)frame {if(!NSEqualRects(frame,[self frame]))TGCancelViewVisibilityAnimation(self);[super setFrame:frame];}
- (BOOL)isFlipped {return YES;}
- (void)drawRect:(NSRect)dirty {
    (void)dirty;NSRect bounds=[self bounds];[[NSColor colorWithCalibratedWhite:0.94 alpha:1] set];NSRectFill(bounds);
    NSRect header=NSMakeRect(0,0,NSWidth(bounds),34);TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:header],header,TGThemeSurfaceHeader,YES);
}
- (void)setFrameSize:(NSSize)size {if(!NSEqualSizes(size,[self frame].size))TGCancelViewVisibilityAnimation(self);[super setFrameSize:size];[self rebuild];}
- (NSTextField *)label:(NSString *)text frame:(NSRect)frame date:(BOOL)date {
    NSTextField *field=[[[NSTextField alloc] initWithFrame:frame] autorelease];[field setStringValue:text?text:@""];[field setFont:[NSFont systemFontOfSize:12]];[field setTextColor:date?TGClassicLinkColor():TGClassicCardInkColor()];[field setEditable:NO];[field setSelectable:NO];[field setBezeled:NO];[field setDrawsBackground:NO];[[field cell] setLineBreakMode:NSLineBreakByTruncatingTail];[field setToolTip:text];return field;
}
- (TGScheduledShelfButton *)button:(NSString *)key action:(NSString *)action message:(NSDictionary *)message frame:(NSRect)frame {
    NSString *title=TGLoc(key);TGScheduledShelfButton *button=[[[TGScheduledShelfButton alloc] initWithFrame:frame] autorelease];
    [button setCell:[[[TGSecondaryTextButtonCell alloc] initTextCell:title] autorelease]];[button setTitle:title];[button setToolTip:title];[button setTarget:self];[button setAction:@selector(rowAction:)];[button setBordered:NO];[button setButtonType:NSMomentaryPushInButton];button.messageID=[message objectForKey:@"message_id"];button.queueAction=action;[button setEnabled:!_loading];return button;
}
- (NSString *)dateText:(NSDictionary *)message {
    if([[message objectForKey:@"send_when_online"] boolValue])return TGLoc(@"scheduled.whenOnline");
    NSNumber *date=[message objectForKey:@"send_date"];if([date integerValue]<=0)return TGLoc(@"scheduled.unknownTime");
    NSDateFormatter *format=[[[NSDateFormatter alloc] init] autorelease];[format setDateStyle:NSDateFormatterMediumStyle];[format setTimeStyle:NSDateFormatterShortStyle];return [format stringFromDate:[NSDate dateWithTimeIntervalSince1970:[date integerValue]]];
}
- (void)updateWithMessages:(NSArray *)messages status:(NSString *)status loading:(BOOL)loading {
    [_messages release];_messages=[messages copy];[_status release];_status=[status copy];_loading=loading;[self rebuild];
}
- (void)rebuild {
    NSPoint origin=_scroll?[[_scroll contentView] bounds].origin:NSZeroPoint;
    for(NSView *view in [[[self subviews] copy] autorelease])[view removeFromSuperview];[_scroll release];_scroll=nil;
    CGFloat width=MAX(0,NSWidth([self bounds])),height=MAX(0,NSHeight([self bounds]));
    NSString *heading=[NSString stringWithFormat:@"%@ · %lu",TGLoc(@"scheduled.shelf.title"),(unsigned long)[_messages count]];
    NSTextField *title=[self label:heading frame:NSMakeRect(12,8,MAX(0,width-54),20) date:NO];[title setFont:[NSFont boldSystemFontOfSize:12]];[self addSubview:title];
    NSButton *close=[[[NSButton alloc] initWithFrame:NSMakeRect(MAX(0,width-34),3,28,28)] autorelease];TGAquaUtilityButtonCell *closeCell=[[[TGAquaUtilityButtonCell alloc] initTextCell:@""] autorelease];[closeCell setIconOnly:YES];[closeCell setIconAssetName:@"cross"];[close setCell:closeCell];[close setBordered:NO];[close setToolTip:TGLoc(@"close")];[close setTarget:self];[close setAction:@selector(closeShelf:)];[self addSubview:close];
    _scroll=[[NSScrollView alloc] initWithFrame:NSMakeRect(8,40,MAX(0,width-16),MAX(0,height-62))];[_scroll setHasVerticalScroller:YES];[_scroll setAutohidesScrollers:YES];[_scroll setBorderType:NSNoBorder];[_scroll setDrawsBackground:NO];
    CGFloat rowWidth=MAX(0,NSWidth([[_scroll contentView] bounds]));
    TGScheduledShelfDocument *document=[[[TGScheduledShelfDocument alloc] initWithFrame:NSMakeRect(0,0,rowWidth,MAX(NSHeight([_scroll bounds]),[_messages count]*84.0))] autorelease];
    NSUInteger index=0;
    for(NSDictionary *message in _messages){
        TGScheduledShelfRow *row=[[[TGScheduledShelfRow alloc] initWithFrame:NSMakeRect(0,index++*84,rowWidth,76)] autorelease];[document addSubview:row];
        BOOL wide=rowWidth>=660;CGFloat textWidth=rowWidth-28;
        if(wide){
            NSArray *keys=[NSArray arrayWithObjects:@"message.edit",@"scheduled.reschedule",@"scheduled.sendNow",@"contacts.actions",nil];NSArray *actions=[NSArray arrayWithObjects:@"edit",@"reschedule",@"send",@"menu",nil];CGFloat x=rowWidth-12;
            for(NSInteger i=3;i>=0;i--){NSString *key=[keys objectAtIndex:(NSUInteger)i];CGFloat w=ceil([TGLoc(key) sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]].width)+24;x-=w;
                TGScheduledShelfButton *button=[self button:key action:[actions objectAtIndex:(NSUInteger)i] message:message frame:NSMakeRect(x,24,w,30)];if(i==0)[button setEnabled:!_loading&&[[message objectForKey:@"editable_text"] isKindOfClass:[NSString class]]];[row addSubview:button];x-=6;
            }textWidth=MAX(40,x-12);
        }else{
            CGFloat actionWidth=ceil([TGLoc(@"contacts.actions") sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]].width)+28;
            [row addSubview:[self button:@"contacts.actions" action:@"menu" message:message frame:NSMakeRect(MAX(0,rowWidth-actionWidth-10),25,actionWidth,30)]];textWidth=MAX(0,rowWidth-actionWidth-36);
        }
        [row addSubview:[self label:[self dateText:message] frame:NSMakeRect(12,13,textWidth,19) date:YES]];
        [row addSubview:[self label:[message objectForKey:@"preview"] frame:NSMakeRect(12,39,textWidth,21) date:NO]];
    }
    [_scroll setDocumentView:document];[self addSubview:_scroll];origin.y=MAX(0,MIN(origin.y,NSHeight([document frame])-NSHeight([[_scroll contentView] bounds])));[[_scroll contentView] scrollToPoint:origin];[_scroll reflectScrolledClipView:[_scroll contentView]];
    NSTextField *status=[self label:[_status length]?_status:([_messages count]?@"":TGLoc(@"scheduled.empty")) frame:NSMakeRect(12,MAX(0,height-19),MAX(0,width-24),16) date:NO];[status setFont:[NSFont systemFontOfSize:10]];[status setTextColor:TGClassicMutedInkColor()];[self addSubview:status];[self setNeedsDisplay:YES];
}
- (void)closeShelf:(id)sender {(void)sender;[_target scheduledShelfRequestClose];}
- (void)rowAction:(TGScheduledShelfButton *)sender {
    if(_loading)return;
    if(![sender.queueAction isEqual:@"menu"]){[_target scheduledShelfPerformAction:sender.queueAction messageID:sender.messageID];return;}
    NSMenu *menu=[[[NSMenu alloc] initWithTitle:@""] autorelease];[menu setAutoenablesItems:NO];NSArray *keys=[NSArray arrayWithObjects:@"message.edit",@"scheduled.reschedule",@"scheduled.sendNow",@"scheduled.whenOnline",@"delete",nil];NSArray *actions=[NSArray arrayWithObjects:@"edit",@"reschedule",@"send",@"online",@"delete",nil];
    NSDictionary *message=nil;for(NSDictionary *candidate in _messages)if([[candidate objectForKey:@"message_id"] isEqual:sender.messageID]){message=candidate;break;}
    for(NSUInteger i=0;i<[keys count];i++){NSMenuItem *item=[[[NSMenuItem alloc] initWithTitle:TGLoc([keys objectAtIndex:i]) action:@selector(menuAction:) keyEquivalent:@""] autorelease];[item setTarget:self];[item setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:sender.messageID,@"message_id",[actions objectAtIndex:i],@"action",nil]];[item setEnabled:i!=0||[[message objectForKey:@"editable_text"] isKindOfClass:[NSString class]]];[menu addItem:item];}
    [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0,NSHeight([sender bounds])) inView:sender];
}
- (void)menuAction:(NSMenuItem *)sender {NSDictionary *info=[sender representedObject];if(!_loading)[_target scheduledShelfPerformAction:[info objectForKey:@"action"] messageID:[info objectForKey:@"message_id"]];}
@end
