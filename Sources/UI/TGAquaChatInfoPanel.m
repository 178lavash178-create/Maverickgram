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
@synthesize target = _target, closing = _closing, mediaHostView = _mediaHostView, selectedMediaTab = _selectedMediaTab;
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
    _avatarView = [[TGProfileAvatarView alloc] initWithFrame:NSZeroRect]; [_sheetView addSubview:_avatarView];
    _nameField = [TGChatInfoLabel([NSFont boldSystemFontOfSize:18.0], YES) retain];
    [_nameField setAlignment:NSLeftTextAlignment]; [_sheetView addSubview:_nameField];
    _subtitleField = [TGChatInfoLabel([NSFont systemFontOfSize:11.0], YES) retain];
    [_subtitleField setAlignment:NSLeftTextAlignment]; [_subtitleField setTextColor:[NSColor colorWithCalibratedWhite:0.40 alpha:1.0]];
    [_sheetView addSubview:_subtitleField];
    _detailsField = [TGChatInfoLabel([NSFont systemFontOfSize:12.0], YES) retain]; [_documentView addSubview:_detailsField];
    _mediaHostView = [[NSView alloc] initWithFrame:NSZeroRect]; [_sheetView addSubview:_mediaHostView];
    _tabScrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    [_tabScrollView setBorderType:NSNoBorder]; [_tabScrollView setHasHorizontalScroller:YES];
    /* Overlay scrollers preserve horizontal access without a permanent grey gutter. */
    [_tabScrollView setScrollerStyle:NSScrollerStyleOverlay];
    [_tabScrollView setAutohidesScrollers:YES]; [_tabScrollView setDrawsBackground:NO];
    [[_tabScrollView contentView] setDrawsBackground:NO];
    _tabDocumentView = [[NSView alloc] initWithFrame:NSZeroRect];
    [_tabScrollView setDocumentView:_tabDocumentView]; [_sheetView addSubview:_tabScrollView];
    _categoryPopUp = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    [_categoryPopUp setFont:[NSFont systemFontOfSize:12]];
    [_categoryPopUp setTarget:self]; [_categoryPopUp setAction:@selector(categoryChanged:)];
    [_sheetView addSubview:_categoryPopUp];
    NSMutableArray *buttons = [NSMutableArray array];
    for (NSInteger index=-1;index<8;index++) {
        NSButton *button = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
        [button setCell:[[[TGAquaTextButtonCell alloc] initTextCell:@""] autorelease]];
        [button setButtonType:NSToggleButton]; [button setFont:[NSFont systemFontOfSize:12]];
        [button setTag:index]; [button setTarget:self]; [button setAction:@selector(actionPressed:)];
        [_tabDocumentView addSubview:button]; [buttons addObject:button];
        [_categoryPopUp addItemWithTitle:[NSString stringWithFormat:@"%ld",(long)index]];
        [[_categoryPopUp lastItem] setTag:index];
    }
    _actionButtons = [buttons copy]; _selectedMediaTab=-1;
    _detailsButton = [[NSButton alloc] initWithFrame:NSZeroRect];
    [_detailsButton setCell:[[[TGAquaTextButtonCell alloc] initTextCell:@""] autorelease]];
    [_detailsButton setButtonType:NSMomentaryPushInButton];
    [_detailsButton setTarget:self]; [_detailsButton setAction:@selector(detailsPressed:)];
    [_documentView addSubview:_detailsButton];
    [self setHidden:YES];
    [self showSummary:[NSDictionary dictionary] loading:NO error:nil];
    return self;
}
- (void)dealloc {
    _target = nil; [self hideImmediately];
    [_sheetView release]; [_scrollView release]; [_documentView release]; [_avatarView release];
    [_headingField release]; [_nameField release]; [_subtitleField release]; [_detailsField release];
    [_closeButton release]; [_actionButtons release]; [_summary release];
    [_tabScrollView release]; [_tabDocumentView release]; [_categoryPopUp release]; [_mediaHostView release]; [_detailsButton release];
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
    NSArray *keys = [NSArray arrayWithObjects:@"chat.info.title",@"media.center.tab.media",@"media.center.tab.files",@"media.center.tab.links",@"media.center.tab.music",@"media.center.tab.voice",@"media.center.tab.gif",@"media.center.tab.polls",@"media.center.tab.groups",nil];
    [_detailsButton setTitle:TGLoc(@"aqua.profile.manage")];
    NSDictionary *status = [[summary objectForKey:@"self_status"] isKindOfClass:[NSDictionary class]] ? [summary objectForKey:@"self_status"] : nil;
    NSDictionary *rights = [[status objectForKey:@"rights"] isKindOfClass:[NSDictionary class]] ? [status objectForKey:@"rights"] : status;
    BOOL group = [kind isEqual:@"basic_group"] || [kind isEqual:@"supergroup"] || [kind isEqual:@"channel"];
    BOOL permitted = [[summary objectForKey:@"can_manage_members"] boolValue] || [[summary objectForKey:@"can_invite_members"] boolValue] ||
        [[status objectForKey:@"@type"] isEqual:@"chatMemberStatusCreator"] ||
        ([[status objectForKey:@"@type"] isEqual:@"chatMemberStatusAdministrator"] &&
         ([[rights objectForKey:@"can_change_info"] boolValue] || [[rights objectForKey:@"can_manage_topics"] boolValue]));
    BOOL secret=[kind isEqual:@"secret"];
    BOOL bot=[kind isEqual:@"private"] && [[profile objectForKey:@"is_bot"] boolValue];
    BOOL showDetails=(group && permitted) || secret || bot;
    [_detailsButton setTitle:TGLoc(secret ? @"chat.kind.secret" : (bot ? @"bot.window.title" : @"aqua.profile.manage"))];
    [_detailsButton setHidden:(!showDetails || loading)];
    [_detailsButton setEnabled:(showDetails && !loading)];
    for (NSUInteger i=0;i<[_actionButtons count];i++) {
        NSButton *button = [_actionButtons objectAtIndex:i]; NSString *text = TGLoc([keys objectAtIndex:i]);
        [button setTitle:text]; [button setToolTip:text];
        [[_categoryPopUp itemAtIndex:i] setTitle:text];
    }
    [self resizeSubviewsWithOldSize:NSZeroSize];
}
- (CGFloat)heightForField:(NSTextField *)field width:(CGFloat)width minimum:(CGFloat)minimum {
    NSSize size = [[field cell] cellSizeForBounds:NSMakeRect(0,0,width,100000.0)];
    return MAX(minimum,ceil(size.height)+4.0);
}
- (void)setSelectedMediaTab:(NSInteger)tab {
    _selectedMediaTab=MAX(-1,MIN(7,tab));
    for (NSButton *button in _actionButtons) [button setState:([button tag]==_selectedMediaTab ? NSOnState : NSOffState)];
    [_categoryPopUp selectItemWithTag:_selectedMediaTab];
    [_scrollView setHidden:(_selectedMediaTab>=0)]; [_mediaHostView setHidden:(_selectedMediaTab<0)];
    [self resizeSubviewsWithOldSize:NSZeroSize];
    for (NSButton *button in _actionButtons) if ([button tag]==_selectedMediaTab) [button scrollRectToVisible:[button bounds]];
}
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    (void)oldSize;
    CGFloat width=MAX(0,NSWidth([self bounds])), height=MAX(0,NSHeight([self bounds]));
    [_sheetView setFrameSize:NSMakeSize(width,height)];
    CGFloat closeWidth=MIN(MAX(64,ceil([[_closeButton title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:12] forKey:NSFontAttributeName]].width)+24),MAX(0,width-20));
    [_closeButton setFrame:NSMakeRect(MAX(8,width-closeWidth-10),MAX(0,height-36),closeWidth,26)];
    [_headingField setFrame:NSMakeRect(14,MAX(0,height-30),MAX(0,width-closeWidth-38),18)];
    CGFloat nameWidth=MAX(0,width-108), nameHeight=[self heightForField:_nameField width:nameWidth minimum:24];
    CGFloat subtitleHeight=[self heightForField:_subtitleField width:nameWidth minimum:18];
    CGFloat identityHeight=MAX(88,nameHeight+subtitleHeight+24);
    CGFloat identityTop=height-44;
    [_avatarView setFrame:NSMakeRect(18,MAX(0,identityTop-70),56,56)];
    [_nameField setFrame:NSMakeRect(88,MAX(0,identityTop-14-nameHeight),nameWidth,nameHeight)];
    [_subtitleField setFrame:NSMakeRect(88,MAX(0,identityTop-18-nameHeight-subtitleHeight),nameWidth,subtitleHeight)];
    CGFloat tabsTop=MAX(0,identityTop-identityHeight), tabsHeight=MIN(38,tabsTop);
    [_tabScrollView setFrame:NSMakeRect(12,tabsTop-tabsHeight,MAX(0,width-24),tabsHeight)];
    CGFloat x=0;
    for (NSButton *button in _actionButtons) {
        CGFloat buttonWidth=MAX(68,ceil([[button title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:12] forKey:NSFontAttributeName]].width)+24);
        [button setFrame:NSMakeRect(x,0,buttonWidth,30)]; x+=buttonWidth+6;
        [button setState:([button tag]==_selectedMediaTab ? NSOnState : NSOffState)];
    }
    [_tabDocumentView setFrameSize:NSMakeSize(MAX(x-6,NSWidth([[_tabScrollView contentView] bounds])),30)];
    [_tabScrollView tile];
    // The complete category name and all destinations remain visible on narrow
    // layouts; a partially hidden horizontal strip is unnecessary here.
    BOOL tabsFit=x-6<=MAX(0,width-24);
    [_tabScrollView setHidden:!tabsFit]; [_categoryPopUp setHidden:tabsFit];
    [_categoryPopUp setFrame:NSMakeRect(12,tabsTop-tabsHeight+4,MAX(0,width-24),MIN(28,MAX(0,tabsHeight-4)))];
    [_categoryPopUp selectItemWithTag:_selectedMediaTab];
    NSRect body=NSMakeRect(1,1,MAX(0,width-2),MAX(0,tabsTop-tabsHeight-5));
    [_scrollView setFrame:body]; [_scrollView tile]; [_mediaHostView setFrame:body];
    [_scrollView setHidden:(_selectedMediaTab>=0)]; [_mediaHostView setHidden:(_selectedMediaTab<0)];
    CGFloat docWidth=NSWidth([[_scrollView contentView] bounds]), textWidth=MAX(0,docWidth-36), y=18;
    CGFloat detailHeight=[[_detailsField stringValue] length] ? [self heightForField:_detailsField width:textWidth minimum:20] : 0;
    [_detailsField setFrame:NSMakeRect(18,y,textWidth,detailHeight)]; y+=detailHeight+20;
    [_detailsButton setFrame:NSMakeRect(18,y,textWidth,[_detailsButton isHidden] ? 0 : 30)];
    if (![_detailsButton isHidden]) y+=44;
    [_documentView setFrameSize:NSMakeSize(docWidth,MAX(NSHeight([[_scrollView contentView] bounds]),y))];
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
    if ([_target respondsToSelector:@selector(openAquaChatInfoMedia:)]) [_target performSelector:@selector(openAquaChatInfoMedia:) withObject:sender];
}
- (void)categoryChanged:(id)sender {
    (void)sender;
    [self actionPressed:[_categoryPopUp selectedItem]];
}
- (void)detailsPressed:(id)sender {
    if ([_detailsButton isHidden] || ![_detailsButton isEnabled]) return;
    if ([_target respondsToSelector:@selector(openAquaChatInfoDetails:)]) [_target performSelector:@selector(openAquaChatInfoDetails:) withObject:sender];
}
@end
