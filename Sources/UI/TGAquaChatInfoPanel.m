#import "TGAquaChatInfoPanel.h"
#import "TGAquaShellViews.h"
#import "TGAnimationSupport.h"
#import "TGLocalization.h"
#import "TGStatusViewComponents.h"
#include <math.h>

TGAquaChatInfoGeometry TGAquaChatInfoFrames(NSRect conversation, BOOL visible) {
    TGAquaChatInfoGeometry result = {conversation, NSZeroRect, NO};
    if (!visible || NSIsEmptyRect(conversation) || !isfinite(NSWidth(conversation)) || !isfinite(NSHeight(conversation))) return result;
    if (NSWidth(conversation) >= 700.0) {
        result.panel = NSMakeRect(NSMaxX(conversation) - 320.0, NSMinY(conversation), 320.0, NSHeight(conversation));
        result.conversation.size.width = NSWidth(conversation) - 326.0;
    } else {
        result.panel = conversation;
        result.replacesConversation = YES;
    }
    return result;
}

@interface TGAquaChatInfoDocument : NSView
@end
@implementation TGAquaChatInfoDocument
- (BOOL)isFlipped { return YES; }
- (BOOL)isOpaque { return YES; }
- (void)drawRect:(NSRect)rect { [[NSColor colorWithCalibratedWhite:0.98 alpha:1.0] set]; NSRectFill(rect); }
@end

static NSTextField *TGChatInfoLabel(NSFont *font, BOOL wraps) {
    NSTextField *field = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [field setEditable:NO]; [field setSelectable:YES]; [field setBezeled:NO]; [field setDrawsBackground:NO];
    [field setFont:font]; [field setTextColor:[NSColor colorWithCalibratedWhite:0.19 alpha:1.0]];
    [[field cell] setWraps:wraps];
    [[field cell] setLineBreakMode:wraps ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail];
    return field;
}
static NSString *TGChatInfoString(id object) { return [object isKindOfClass:[NSString class]] ? object : @""; }

@implementation TGAquaChatInfoPanel
@synthesize target = _target, closing = _closing;
- (BOOL)acceptsFirstResponder { return YES; }
- (void)cancelOperation:(id)sender { [self closePressed:sender]; }
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    _sheetView = [[TGAquaMetalView alloc] initWithFrame:[self bounds]];
    [self addSubview:_sheetView];
    _headingField = [TGChatInfoLabel([NSFont boldSystemFontOfSize:12.0], NO) retain];
    [_headingField setSelectable:NO]; [_sheetView addSubview:_headingField];
    _closeButton = [[NSButton alloc] initWithFrame:NSZeroRect];
    [_closeButton setCell:[[[TGAquaTextButtonCell alloc] initTextCell:@""] autorelease]];
    [_closeButton setTarget:self]; [_closeButton setAction:@selector(closePressed:)]; [_sheetView addSubview:_closeButton];
    _scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    [_scrollView setBorderType:NSNoBorder]; [_scrollView setHasVerticalScroller:YES]; [_scrollView setAutohidesScrollers:YES];
    _documentView = [[TGAquaChatInfoDocument alloc] initWithFrame:NSZeroRect];
    [_scrollView setDocumentView:_documentView]; [_sheetView addSubview:_scrollView];
    _avatarView = [[TGProfileAvatarView alloc] initWithFrame:NSZeroRect]; [_documentView addSubview:_avatarView];
    _nameField = [TGChatInfoLabel([NSFont boldSystemFontOfSize:18.0], YES) retain];
    [_nameField setAlignment:NSCenterTextAlignment]; [_documentView addSubview:_nameField];
    _subtitleField = [TGChatInfoLabel([NSFont systemFontOfSize:11.0], YES) retain];
    [_subtitleField setAlignment:NSCenterTextAlignment]; [_subtitleField setTextColor:[NSColor colorWithCalibratedWhite:0.40 alpha:1.0]];
    [_documentView addSubview:_subtitleField];
    _detailsField = [TGChatInfoLabel([NSFont systemFontOfSize:12.0], YES) retain]; [_documentView addSubview:_detailsField];
    NSMutableArray *buttons = [NSMutableArray array];
    for (NSInteger index=0;index<5;index++) {
        NSButton *button = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
        [button setCell:[[[TGAquaTextButtonCell alloc] initTextCell:@""] autorelease]];
        [button setTag:index]; [button setTarget:self]; [button setAction:@selector(actionPressed:)];
        [_documentView addSubview:button]; [buttons addObject:button];
    }
    _actionButtons = [buttons copy];
    [self setHidden:YES];
    [self showSummary:[NSDictionary dictionary] loading:NO error:nil];
    return self;
}
- (void)dealloc {
    _target = nil; [self hideImmediately];
    [_sheetView release]; [_scrollView release]; [_documentView release]; [_avatarView release];
    [_headingField release]; [_nameField release]; [_subtitleField release]; [_detailsField release];
    [_closeButton release]; [_actionButtons release]; [_summary release];
    [super dealloc];
}
- (void)showSummary:(NSDictionary *)summary loading:(BOOL)loading error:(NSString *)errorMessage {
    [_summary release]; _summary = [summary copy];
    NSDictionary *profile = [[summary objectForKey:@"profile"] isKindOfClass:[NSDictionary class]] ? [summary objectForKey:@"profile"] : nil;
    NSString *title = TGChatInfoString([summary objectForKey:@"title"]);
    if (![title length]) title = TGChatInfoString([profile objectForKey:@"display_name"]);
    [_headingField setStringValue:TGLoc(@"profile.title")]; [_closeButton setTitle:TGLoc(@"close")]; [_closeButton setToolTip:TGLoc(@"close")];
    [_nameField setStringValue:title]; [_nameField setToolTip:title];
    [(TGProfileAvatarView *)_avatarView setDisplayName:title];
    NSString *avatar = TGChatInfoString([profile objectForKey:@"avatar_local_path"]);
    if (![avatar length]) avatar = TGChatInfoString([summary objectForKey:@"avatar_local_path"]);
    [(TGProfileAvatarView *)_avatarView setAvatarLocalPath:avatar];
    NSString *kind = TGChatInfoString([summary objectForKey:@"kind"]);
    if (![kind length]) kind = @"unknown";
    NSString *subtitle = TGLoc([@"chat.kind." stringByAppendingString:kind]);
    if ([summary objectForKey:@"member_count"]) subtitle = [NSString stringWithFormat:TGLoc(@"chat.info.summaryWithMembers"), subtitle, (long)[[summary objectForKey:@"member_count"] integerValue]];
    if ([[profile objectForKey:@"is_online"] boolValue]) subtitle = TGLoc(@"contacts.online");
    if (loading) subtitle = TGLoc(@"contacts.profileLoading");
    else if ([errorMessage length]) subtitle = TGLoc(@"contacts.profileError");
    [_subtitleField setStringValue:subtitle];
    NSMutableArray *details = [NSMutableArray array];
    NSString *username = TGChatInfoString([profile objectForKey:@"username"]);
    NSDictionary *usernames = [[summary objectForKey:@"usernames"] isKindOfClass:[NSDictionary class]] ? [summary objectForKey:@"usernames"] : nil;
    NSArray *activeNames = [[usernames objectForKey:@"active_usernames"] isKindOfClass:[NSArray class]] ? [usernames objectForKey:@"active_usernames"] : nil;
    if (![username length] && [activeNames count]) username = TGChatInfoString([activeNames objectAtIndex:0]);
    if ([username length]) [details addObject:[NSString stringWithFormat:@"%@\n@%@",TGLoc(@"profile.username"),username]];
    NSString *phone = TGChatInfoString([profile objectForKey:@"phone_number"]);
    if ([phone length]) [details addObject:[NSString stringWithFormat:@"%@\n%@",TGLoc(@"profile.phone"),phone]];
    NSString *bio = TGChatInfoString([profile objectForKey:@"bio"]);
    if (![bio length]) bio = TGChatInfoString([summary objectForKey:@"description"]);
    if ([bio length]) [details addObject:[NSString stringWithFormat:@"%@\n%@",TGLoc(@"profile.about"),bio]];
    [_detailsField setStringValue:[details componentsJoinedByString:@"\n\n"]];
    NSArray *keys = [NSArray arrayWithObjects:@"media.center.tab.media",@"media.center.tab.files",@"media.center.tab.links",@"media.center.tab.music",@"chat.info.title",nil];
    for (NSUInteger i=0;i<[_actionButtons count];i++) {
        NSButton *button = [_actionButtons objectAtIndex:i]; NSString *text = TGLoc([keys objectAtIndex:i]);
        [button setTitle:text]; [button setToolTip:text];
    }
    [self resizeSubviewsWithOldSize:NSZeroSize];
}
- (CGFloat)heightForField:(NSTextField *)field width:(CGFloat)width minimum:(CGFloat)minimum {
    NSSize size = [[field cell] cellSizeForBounds:NSMakeRect(0,0,width,100000.0)];
    return MAX(minimum,ceil(size.height)+4.0);
}
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    (void)oldSize;
    CGFloat width = MAX(0.0,NSWidth([self bounds])), height=MAX(0.0,NSHeight([self bounds]));
    [_sheetView setFrameSize:NSMakeSize(width,height)];
    CGFloat closeWidth = MIN(MAX(64.0,ceil([[_closeButton title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:12] forKey:NSFontAttributeName]].width)+24.0),MAX(0,width-20));
    [_closeButton setFrame:NSMakeRect(MAX(8,width-closeWidth-10),MAX(0,height-36),closeWidth,26)];
    [_headingField setFrame:NSMakeRect(14,MAX(0,height-30),MAX(0,width-closeWidth-38),18)];
    [_scrollView setFrame:NSMakeRect(1,1,MAX(0,width-2),MAX(0,height-44))]; [_scrollView tile];
    CGFloat docWidth = NSWidth([[_scrollView contentView] bounds]);
    CGFloat textWidth = MAX(0,docWidth-36), y=20;
    [_avatarView setFrame:NSMakeRect(MAX(0,floor((docWidth-88)/2)),y,88,88)]; y+=100;
    CGFloat nameHeight = [self heightForField:_nameField width:textWidth minimum:24];
    [_nameField setFrame:NSMakeRect(18,y,textWidth,nameHeight)]; y+=nameHeight+4;
    CGFloat subtitleHeight = [self heightForField:_subtitleField width:textWidth minimum:18];
    [_subtitleField setFrame:NSMakeRect(18,y,textWidth,subtitleHeight)]; y+=subtitleHeight+20;
    CGFloat detailHeight = [[_detailsField stringValue] length] ? [self heightForField:_detailsField width:textWidth minimum:20] : 0;
    [_detailsField setFrame:NSMakeRect(18,y,textWidth,detailHeight)]; y+=detailHeight+(detailHeight>0?20:0);
    for (NSButton *button in _actionButtons) { [button setFrame:NSMakeRect(18,y,textWidth,30)]; y+=38; }
    [_documentView setFrameSize:NSMakeSize(docWidth,MAX(NSHeight([[_scrollView contentView] bounds]),y+14))];
}
- (void)stopAnimation {
    [_animation setDelegate:nil]; [_animation stopAnimation]; [_animation release]; _animation=nil;
}
- (void)presentInFrame:(NSRect)frame animated:(BOOL)animated {
    BOOL wasHidden = [self isHidden], wasClosing = _closing;
    BOOL changed = !NSEqualRects(frame,_settledFrame);
    if (!wasHidden && !wasClosing && !changed) return;
    [self stopAnimation]; _closing=NO; _settledFrame=frame;
    [self setFrame:frame]; [self setHidden:NO];
    NSRect destination=[self bounds]; [_sheetView setFrame:destination];
    if (!animated || !wasHidden || !TGInterfaceAnimationsEnabledForView(self)) return;
    NSRect start=NSOffsetRect(destination,NSWidth(destination),0); [_sheetView setFrame:start];
    NSDictionary *description=[NSDictionary dictionaryWithObjectsAndKeys:_sheetView,NSViewAnimationTargetKey,[NSValue valueWithRect:start],NSViewAnimationStartFrameKey,[NSValue valueWithRect:destination],NSViewAnimationEndFrameKey,nil];
    _animation=[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:description]];
    [_animation setDuration:0.20]; [_animation setFrameRate:30]; [_animation setAnimationCurve:NSAnimationEaseInOut];
    [_animation setAnimationBlockingMode:NSAnimationNonblocking]; [_animation setDelegate:self]; [_animation startAnimation];
}
- (void)closeAnimated:(BOOL)animated {
    if (_closing) return;
    [self stopAnimation]; _closing=YES;
    if ([self isHidden] || !animated || !TGInterfaceAnimationsEnabledForView(self)) { [self finishAnimation]; return; }
    NSRect start=[self bounds], end=NSOffsetRect(start,NSWidth(start),0); [_sheetView setFrame:start];
    NSDictionary *description=[NSDictionary dictionaryWithObjectsAndKeys:_sheetView,NSViewAnimationTargetKey,[NSValue valueWithRect:start],NSViewAnimationStartFrameKey,[NSValue valueWithRect:end],NSViewAnimationEndFrameKey,nil];
    _animation=[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:description]];
    [_animation setDuration:0.18]; [_animation setFrameRate:30]; [_animation setAnimationCurve:NSAnimationEaseInOut];
    [_animation setAnimationBlockingMode:NSAnimationNonblocking]; [_animation setDelegate:self]; [_animation startAnimation];
}
- (void)hideImmediately { [self stopAnimation]; _closing=NO; [self setHidden:YES]; [_sheetView setFrame:[self bounds]]; }
- (void)animationDidEnd:(NSAnimation *)animation {
    if (animation != _animation) return;
    [self finishAnimation];
}
- (void)finishAnimation {
    BOOL closed=_closing; [self stopAnimation]; _closing=NO;
    [_sheetView setFrame:[self bounds]];
    if (closed) {
        [self setHidden:YES];
        if ([_target respondsToSelector:@selector(aquaChatInfoPanelDidClose:)]) [_target performSelector:@selector(aquaChatInfoPanelDidClose:) withObject:self];
    }
}
- (void)closePressed:(id)sender { if ([_target respondsToSelector:@selector(closeAquaChatInfo:)]) [_target performSelector:@selector(closeAquaChatInfo:) withObject:sender]; }
- (void)actionPressed:(id)sender {
    SEL action = [sender tag]==4 ? @selector(openAquaChatInfoDetails:) : @selector(openAquaChatInfoMedia:);
    if ([_target respondsToSelector:action]) [_target performSelector:action withObject:sender];
}
@end
