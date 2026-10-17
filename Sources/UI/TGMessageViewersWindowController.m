#import "TGMessageViewersWindowController.h"
#import "TGLocalization.h"
#import "../Media/TGMediaImageLoader.h"
#import "TGInterfaceDesign.h"
#import "TGAquaAppearance.h"
#import "TGTheme.h"
#import "TGThemeContrast.h"
#import "TGStatusViewCells.h"
#import "TGMessageLayoutSupport.h"
#import "TGDialogPresentation.h"

#include "TGMessageViewersWindowController+Avatar.inc"

@interface TGMessageViewersWindowController ()
@property (nonatomic, retain) NSTextField *titleField;
@property (nonatomic, retain) NSTextField *subtitleField;
@property (nonatomic, retain) NSScrollView *scrollView;
@property (nonatomic, retain) NSView *contentView;
@property (nonatomic, copy) NSString *messagePreview;
@property (nonatomic, retain) NSMutableArray *imageLoadTokens;
@end

@implementation TGMessageViewersWindowController

@synthesize titleField = _titleField;
@synthesize subtitleField = _subtitleField;
@synthesize scrollView = _scrollView;
@synthesize contentView = _contentView;
@synthesize messagePreview = _messagePreview;
@synthesize imageLoadTokens = _imageLoadTokens;

- (id)initWithMessagePreview:(NSString *)messagePreview {
    NSRect frame = TGInterfaceDesignIsAqua() ? NSMakeRect(0, 0, 360, 320) : NSMakeRect(0, 0, 420, 340);
    NSWindow *window = [[[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSTitledWindowMask | NSClosableWindowMask)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO] autorelease];
    self = [super initWithWindow:window];
    if (self) {
        self.messagePreview = messagePreview;
        self.imageLoadTokens = [NSMutableArray array];
        [[self window] setTitle:TGLoc(@"message.whoRead")];
        [self buildViews];
        [self showLoading];
    }
    return self;
}

- (void)dealloc {
    [_titleField release];
    [_subtitleField release];
    [_scrollView release];
    [_contentView release];
    [_messagePreview release];
    NSUInteger index = 0;
    for (index = 0; index < [_imageLoadTokens count]; index++) {
        [[_imageLoadTokens objectAtIndex:index] cancel];
    }
    [_imageLoadTokens release];
    [super dealloc];
}

- (NSTextField *)labelWithFrame:(NSRect)frame font:(NSFont *)font color:(NSColor *)color {
    NSTextField *label = [[[NSTextField alloc] initWithFrame:frame] autorelease];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setFont:font];
    [label setTextColor:color];
    [[label cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    return label;
}

- (void)buildViews {
    NSView *root = [[self window] contentView];
    if (TGInterfaceDesignIsAqua()) {
        TGAquaUtilityWindowView *utility = [[[TGAquaUtilityWindowView alloc] initWithFrame:[root bounds]] autorelease];
        utility.headerHeight = 64.0; utility.footerHeight = 0.0;
        root = utility;
        [[self window] setContentView:root];
    } else {
        [root setWantsLayer:YES];
        [[root layer] setBackgroundColor:[[NSColor colorWithCalibratedRed:0.91 green:0.95 blue:0.98 alpha:1.0] CGColor]];
    }

    self.titleField = [self labelWithFrame:TGInterfaceDesignIsAqua()?NSMakeRect(14, 292, 332, 20):NSMakeRect(24, 294, 372, 24)
                                      font:[NSFont boldSystemFontOfSize:TGInterfaceDesignIsAqua()?14.0:18.0]
                                     color:TGInterfaceDesignIsAqua()?TGClassicHeaderTextColor(1):[NSColor colorWithCalibratedWhite:0.08 alpha:1.0]];
    [self.titleField setAlignment:TGInterfaceDesignIsAqua()?NSLeftTextAlignment:NSCenterTextAlignment];
    [self.titleField setStringValue:TGLoc(@"message.viewers.title")];
    [root addSubview:self.titleField];

    self.subtitleField = [self labelWithFrame:TGInterfaceDesignIsAqua()?NSMakeRect(14, 268, 332, 18):NSMakeRect(34, 268, 352, 18)
                                         font:[NSFont systemFontOfSize:12.0]
                                        color:TGInterfaceDesignIsAqua()?TGThemeSurfaceInkColor(TGClassicHeaderDetailTextColor(1),TGThemeSurfaceHeader,5.4):[NSColor colorWithCalibratedWhite:0.35 alpha:1.0]];
    [self.subtitleField setAlignment:TGInterfaceDesignIsAqua()?NSLeftTextAlignment:NSCenterTextAlignment];
    [self.subtitleField setToolTip:self.messagePreview];
    [self.subtitleField setStringValue:([self.messagePreview length] > 0 ? self.messagePreview : TGLoc(@"message"))];
    [root addSubview:self.subtitleField];

    self.scrollView = [[[NSScrollView alloc] initWithFrame:TGInterfaceDesignIsAqua()?NSMakeRect(0, 0, 360, 256):NSMakeRect(24, 24, 372, 232)] autorelease];
    [self.scrollView setHasVerticalScroller:YES];
    [self.scrollView setBorderType:NSNoBorder];
    [self.scrollView setDrawsBackground:NO];
    if (TGInterfaceDesignIsAqua()) {
        [[self.scrollView contentView] setDrawsBackground:NO];
        [self.scrollView setScrollerStyle:NSScrollerStyleOverlay];[self.scrollView setAutohidesScrollers:YES];
    }
    self.contentView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, TGInterfaceDesignIsAqua()?360:352, TGInterfaceDesignIsAqua()?256:232)] autorelease];
    [self.scrollView setDocumentView:self.contentView];
    [root addSubview:self.scrollView];
}

- (void)showNearRect:(NSRect)rect ofView:(NSView *)view {
    NSWindow *parent = [view window];
    if (TGInterfaceDesignIsAqua() && parent && !NSIsEmptyRect(rect)) {
        NSRect anchor = [parent convertRectToScreen:[view convertRect:rect toView:nil]];
        NSScreen *screen=[parent screen] ? [parent screen] : [NSScreen mainScreen];
        NSRect visible = [screen visibleFrame];
        NSRect frame = [[self window] frame];
        CGFloat x = NSMaxX(anchor) + 8.0;
        if (x + NSWidth(frame) > NSMaxX(visible)-8.0) x = NSMinX(anchor)-NSWidth(frame)-8.0;
        x = MAX(NSMinX(visible)+8.0,MIN(x,NSMaxX(visible)-NSWidth(frame)-8.0));
        CGFloat y = MAX(NSMinY(visible)+8.0,MIN(NSMaxY(anchor)-NSHeight(frame),NSMaxY(visible)-NSHeight(frame)-8.0));
        [[self window] setFrameOrigin:NSMakePoint(x,y)];
    } else [[self window] center];
    TGFitUtilityWindowToVisibleScreen([self window]);
    [self showWindow:nil];
    [[self window] makeKeyAndOrderFront:nil];
}

- (void)clearContent {
    NSUInteger tokenIndex = 0;
    for (tokenIndex = 0; tokenIndex < [self.imageLoadTokens count]; tokenIndex++) {
        [[self.imageLoadTokens objectAtIndex:tokenIndex] cancel];
    }
    [self.imageLoadTokens removeAllObjects];
    NSArray *subviews = [[self.contentView subviews] copy];
    NSUInteger index = 0;
    for (index = 0; index < [subviews count]; index++) {
        [[subviews objectAtIndex:index] removeFromSuperview];
    }
    [subviews release];
}

- (void)setSingleMessage:(NSString *)message color:(NSColor *)color {
    [self clearContent];
    [self.contentView setFrame:NSMakeRect(0, 0, TGInterfaceDesignIsAqua()?360:352, TGInterfaceDesignIsAqua()?256:232)];
    NSTextField *label = [self labelWithFrame:TGInterfaceDesignIsAqua()?NSMakeRect(18, 102, 324, 44):NSMakeRect(18, 100, 316, 24)
                                         font:[NSFont systemFontOfSize:13.0]
                                        color:TGInterfaceDesignIsAqua()?TGThemeSurfaceInkColor(color,TGThemeSurfaceCard,4.5):color];
    [label setAlignment:NSCenterTextAlignment];
    if (TGInterfaceDesignIsAqua()) { [[label cell] setWraps:YES]; [[label cell] setUsesSingleLineMode:NO]; [[label cell] setLineBreakMode:NSLineBreakByWordWrapping]; }
    [label setStringValue:([message length] > 0 ? message : TGLoc(@"message.viewers.noData"))];
    [label setToolTip:[label stringValue]];
    [self.contentView addSubview:label];
}

- (void)showLoading {
    [self setSingleMessage:TGLoc(@"message.viewers.loading") color:[NSColor colorWithCalibratedWhite:0.38 alpha:1.0]];
}

- (void)setContentTitle:(NSString *)title windowTitle:(NSString *)windowTitle {
    if ([title length] > 0) {
        [self.titleField setStringValue:title];
    }
    if ([windowTitle length] > 0) {
        [[self window] setTitle:windowTitle];
    }
}

- (void)showErrorMessage:(NSString *)message {
    [self setSingleMessage:([message length] > 0 ? message : TGLoc(@"message.viewers.unavailable"))
                     color:[NSColor colorWithCalibratedRed:0.62 green:0.12 blue:0.10 alpha:1.0]];
}

- (void)showViewerSummaries:(NSArray *)viewerSummaries {
    [self clearContent];
    if ([viewerSummaries count] == 0) {
        [self setSingleMessage:TGLoc(@"message.viewers.empty") color:[NSColor colorWithCalibratedWhite:0.38 alpha:1.0]];
        return;
    }

    BOOL aqua = TGInterfaceDesignIsAqua();
    CGFloat rowHeight = aqua ? 52.0 : 46.0;
    CGFloat width = aqua ? 360.0 : 352.0;
    CGFloat totalHeight = MAX(aqua?256.0:232.0, rowHeight * [viewerSummaries count]);
    [self.contentView setFrame:NSMakeRect(0, 0, width, totalHeight)];

    NSUInteger index = 0;
    for (index = 0; index < [viewerSummaries count]; index++) {
        NSDictionary *summary = [viewerSummaries objectAtIndex:index];
        CGFloat y = totalHeight - ((CGFloat)index + 1.0) * rowHeight;
        NSView *row = [[[NSView alloc] initWithFrame:NSMakeRect(0, y, width, rowHeight)] autorelease];

        NSString *avatarPath = [summary objectForKey:@"avatar_local_path"];
        NSString *displayName = [summary objectForKey:@"display_name"];
        NSString *nameText=[displayName length]>0?displayName:TGLoc(@"message.viewers.unknown");
        Class avatarClass=aqua?[TGMessageViewerAvatarView class]:[NSImageView class];
        NSImageView *avatarView = [[[avatarClass alloc] initWithFrame:aqua?NSMakeRect(14,10,32,32):NSMakeRect(10, 7, 32, 32)] autorelease];
        if(aqua)[(TGMessageViewerAvatarView *)avatarView setDisplayName:nameText];
        if ([avatarPath length] > 0) {
            NSImage *avatar = TGMediaCachedThumbnailFromFile(avatarPath, 64);
            if (avatar) {
                [avatarView setImage:avatar];
            } else {
                __block TGMessageViewersWindowController *controller = self;
                TGMediaImageLoadToken *token = TGLoadImageThumbnailFromFileAsync(avatarPath, 64, ^(NSImage *loadedImage) {
                    if (loadedImage && [avatarView superview] && [[controller window] isVisible]) {
                        [avatarView setImage:loadedImage];
                    }
                });
                if (token) {
                    [self.imageLoadTokens addObject:token];
                }
            }
        }
        [avatarView setImageScaling:NSImageScaleProportionallyUpOrDown];
        [row addSubview:avatarView];

        id viewDate = [summary objectForKey:@"view_date"];
        BOOL hasViewDate=[viewDate respondsToSelector:@selector(integerValue)] && [viewDate integerValue]>0;
        NSTextField *name = [self labelWithFrame:aqua?NSMakeRect(58,hasViewDate?27:17,284,18):NSMakeRect(54, 16, 220, 18)
                                            font:[NSFont boldSystemFontOfSize:13.0]
                                           color:TGInterfaceDesignIsAqua()?TGClassicCardInkColor():[NSColor colorWithCalibratedWhite:0.12 alpha:1.0]];
        [name setStringValue:nameText];
        [name setToolTip:[name stringValue]];
        [row addSubview:name];

        NSString *reactionDisplay = [summary objectForKey:@"reaction_display"];
        if ([reactionDisplay length] > 0) {
            if (TGInterfaceDesignIsAqua()) {
                [name setFrameSize:NSMakeSize(246,18)];
                [name setToolTip:[name stringValue]];
            }
            NSTextField *reaction = [self labelWithFrame:aqua?NSMakeRect(312,14,30,24):NSMakeRect(246, 14, 28, 22)
                                                     font:[NSFont systemFontOfSize:16.0]
                                                    color:TGInterfaceDesignIsAqua()?TGClassicCardInkColor():[NSColor colorWithCalibratedWhite:0.18 alpha:1.0]];
            [reaction setAlignment:NSCenterTextAlignment];
            [reaction setStringValue:reactionDisplay];
            [row addSubview:reaction];
        }

        if (hasViewDate) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[viewDate integerValue]];
            NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
            [formatter setDateStyle:NSDateFormatterNoStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            NSTextField *time = [self labelWithFrame:aqua?NSMakeRect(58,8,242,16):NSMakeRect(278, 16, 62, 18)
                                                font:[NSFont systemFontOfSize:12.0]
                                               color:TGInterfaceDesignIsAqua()?TGClassicCardMutedInkColor():[NSColor colorWithCalibratedWhite:0.50 alpha:1.0]];
            [time setAlignment:aqua?NSLeftTextAlignment:NSRightTextAlignment];
            [time setStringValue:[formatter stringFromDate:date]];
            [row addSubview:time];
        }

        if (index + 1 < [viewerSummaries count]) {
            NSBox *line = [[[NSBox alloc] initWithFrame:aqua?NSMakeRect(58,0,284,1):NSMakeRect(54, 0, 286, 1)] autorelease];
            [line setBoxType:NSBoxSeparator];
            [row addSubview:line];
        }

        [self.contentView addSubview:row];
    }
    if (aqua) {
        [self.contentView scrollPoint:NSMakePoint(0,MAX(0.0,totalHeight-NSHeight([[self.scrollView contentView] bounds])))];
    }
}

@end
