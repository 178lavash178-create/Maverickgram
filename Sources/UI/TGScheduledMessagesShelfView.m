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
- (void)drawRect:(NSRect)dirty {
    (void)dirty; NSBezierPath *path=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds],0.5,0.5) xRadius:9 yRadius:9];
    NSGradient *fill=[[[NSGradient alloc] initWithStartingColor:TGColorFromHex(0xF7FCFF) endingColor:TGColorFromHex(0xE1F0FA)] autorelease];
    [fill drawInBezierPath:path angle:90]; [TGColorFromHex(0xB9CBD7) set]; [path stroke];
}
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
    (void)dirty;NSRect bounds=[self bounds];[TGColorFromHex(0xF5F8FA) set];NSRectFill(bounds);
    NSRect header=NSMakeRect(0,0,NSWidth(bounds),34);TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:header],header,TGThemeSurfaceHeader,YES);
    [TGClassicPanelStrokeColor() set]; NSRectFill(NSMakeRect(0,33,NSWidth(bounds),1));
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
    if(![_messages count]) {
        NSString *text=[_status length] ? _status : (_loading ? TGLoc(@"scheduled.loading") : TGLoc(@"scheduled.empty"));
        NSTextField *empty=[self label:text frame:NSMakeRect(16,MAX(40,34+(height-34-44)/2),MAX(0,width-32),44) date:NO];
        [empty setAlignment:NSCenterTextAlignment]; [empty setFont:[NSFont systemFontOfSize:13]];
        [[empty cell] setWraps:YES]; [[empty cell] setUsesSingleLineMode:NO];
        [empty setTextColor:TGClassicMutedInkColor()]; [self addSubview:empty];
        [self setNeedsDisplay:YES]; return;
    }
    BOOL showStatus=[_status length]>0;
    CGFloat statusHeight=showStatus ? 22 : 0;
    _scroll=[[NSScrollView alloc] initWithFrame:NSMakeRect(12,44,MAX(0,width-24),MAX(0,height-54-statusHeight))];
    [_scroll setHasVerticalScroller:YES]; [_scroll setAutohidesScrollers:YES];
    [_scroll setBorderType:NSNoBorder]; [_scroll setDrawsBackground:NO];
    CGFloat rowWidth=MAX(0,NSWidth([[_scroll contentView] bounds])-2);
    TGScheduledShelfDocument *document=[[[TGScheduledShelfDocument alloc] initWithFrame:NSMakeRect(0,0,rowWidth,1)] autorelease];
    CGFloat y=0;
    for(NSDictionary *message in _messages) {
        NSString *preview=[message objectForKey:@"preview"]; if(![preview isKindOfClass:[NSString class]]) preview=@"";
        CGFloat textWidth=MAX(0,rowWidth-28);
        NSDictionary *attributes=[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:13] forKey:NSFontAttributeName];
        CGFloat bodyHeight=MIN(54,MAX(20,ceil([preview boundingRectWithSize:NSMakeSize(MAX(1,textWidth),1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes].size.height)));
        CGFloat rowHeight=bodyHeight+50;
        TGScheduledShelfRow *row=[[[TGScheduledShelfRow alloc] initWithFrame:NSMakeRect(0,y,rowWidth,rowHeight)] autorelease];
        [document addSubview:row]; y+=rowHeight+10;
        CGFloat actionWidth=MIN(MAX(0,rowWidth-24),ceil([TGLoc(@"contacts.actions") sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]].width)+24);
        [row addSubview:[self button:@"contacts.actions" action:@"menu" message:message frame:NSMakeRect(MAX(0,rowWidth-actionWidth-10),6,actionWidth,28)]];
        NSTextField *date=[self label:[self dateText:message] frame:NSMakeRect(12,11,MAX(0,rowWidth-actionWidth-34),19) date:YES];
        [date setFont:[NSFont boldSystemFontOfSize:11]]; [row addSubview:date];
        NSTextField *body=[self label:preview frame:NSMakeRect(12,36,textWidth,bodyHeight) date:NO];
        [body setFont:[NSFont systemFontOfSize:13]]; [[body cell] setWraps:YES]; [[body cell] setUsesSingleLineMode:NO];
        [[body cell] setLineBreakMode:NSLineBreakByWordWrapping]; [row addSubview:body];
    }
    [document setFrameSize:NSMakeSize(rowWidth,MAX(NSHeight([_scroll bounds]),y))];
    [_scroll setDocumentView:document]; [self addSubview:_scroll];
    origin.y=MAX(0,MIN(origin.y,NSHeight([document frame])-NSHeight([[_scroll contentView] bounds])));
    [[_scroll contentView] scrollToPoint:origin]; [_scroll reflectScrolledClipView:[_scroll contentView]];
    if(showStatus) {
        NSTextField *status=[self label:_status frame:NSMakeRect(12,MAX(0,height-20),MAX(0,width-24),16) date:NO];
        [status setFont:[NSFont systemFontOfSize:10]]; [status setTextColor:TGClassicMutedInkColor()]; [self addSubview:status];
    }
    [self setNeedsDisplay:YES];
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
