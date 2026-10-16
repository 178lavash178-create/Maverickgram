#import "TGAquaMediaViewerView.h"
#import "TGAquaShellViews.h"
#import "TGIconAssets.h"
#import "TGLocalization.h"
#include <math.h>

TGAquaMediaViewerGeometry TGAquaMediaViewerFrames(NSRect bounds, TGAquaMediaViewerKind kind) {
    TGAquaMediaViewerGeometry g;
    memset(&g,0,sizeof(g));
    CGFloat w=MAX(0,NSWidth(bounds)),h=MAX(0,NSHeight(bounds));
    CGFloat footer=kind==TGAquaMediaViewerPhoto ? 46.0 : 70.0;
    g.header=NSMakeRect(0,MAX(0,h-54),w,54);
    g.footer=NSMakeRect(0,0,w,footer);
    g.stage=NSMakeRect(12,footer+10,MAX(0,w-24),MAX(0,h-footer-74));
    g.viewport=NSMakeRect(NSMinX(g.stage)+8,NSMinY(g.stage)+8,MAX(0,NSWidth(g.stage)-16),MAX(0,NSHeight(g.stage)-16));
    if (kind==TGAquaMediaViewerVideoNote) {
        CGFloat side=MAX(0,MIN(NSWidth(g.viewport),NSHeight(g.viewport)));
        g.viewport=NSMakeRect(floor(NSMidX(g.viewport)-side/2),floor(NSMidY(g.viewport)-side/2),side,side);
    }
    CGFloat center=floor(w/2);
    g.zoomOut=NSMakeRect(center-100,11,34,32);
    g.fit=NSMakeRect(center-56,11,112,32);
    g.zoomIn=NSMakeRect(center+66,11,34,32);
    g.playPause=NSMakeRect(16,18,36,36);
    g.progress=NSMakeRect(66,36,MAX(0,w-158),20);
    g.time=NSMakeRect(68,12,MAX(0,w-164),18);
    g.rate=NSMakeRect(MAX(0,w-80),24,64,28);
    if (kind==TGAquaMediaViewerPhoto) {
        g.header=NSMakeRect(0,MAX(0,h-40),w,40);
        g.stage=NSMakeRect(0,footer,w,MAX(0,h-footer-40));
        g.viewport=NSMakeRect(12,footer+8,MAX(0,w-24),MAX(0,h-footer-56));
        g.zoomOut=NSMakeRect(center-78,9,28,28);
        g.fit=NSMakeRect(center-40,9,80,28);
        g.zoomIn=NSMakeRect(center+50,9,28,28);
    }
    return g;
}

@implementation TGAquaMediaControlCell
@synthesize iconAssetName=_iconAssetName,hovered=_hovered;
- (void)dealloc { [_iconAssetName release];[super dealloc]; }
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    BOOL enabled=[self isEnabled],pressed=[self isHighlighted];
    if (enabled && (_hovered || pressed)) {
        [[NSColor colorWithCalibratedWhite:1 alpha:pressed ? 0.22 : 0.10] set];
        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame,1,1) xRadius:5 yRadius:5] fill];
    }
    NSColor *ink=[NSColor colorWithCalibratedWhite:enabled ? (pressed ? 1.0 : 0.90) : 0.48 alpha:1];
    if ([_iconAssetName length]) {
        TGDrawTemplateIconAsset(_iconAssetName,NSMakeRect(floor(NSMidX(frame)-9),floor(NSMidY(frame)-9),18,18),ink,1,[view isFlipped]);
    } else {
        NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12],NSFontAttributeName,ink,NSForegroundColorAttributeName,nil];
        NSString *text=[self title] ? [self title] : @"";NSSize size=[text sizeWithAttributes:attrs];
        [text drawInRect:NSMakeRect(floor(NSMidX(frame)-size.width/2),floor(NSMidY(frame)-size.height/2),size.width,size.height) withAttributes:attrs];
    }
}
@end
@implementation TGAquaMediaControlButton
- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (_mediaTrackingArea) {[self removeTrackingArea:_mediaTrackingArea];[_mediaTrackingArea release];}
    _mediaTrackingArea=[[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInKeyWindow|NSTrackingInVisibleRect owner:self userInfo:nil];
    [self addTrackingArea:_mediaTrackingArea];
}
- (void)mouseEntered:(NSEvent *)event { (void)event;if([[self cell] isKindOfClass:[TGAquaMediaControlCell class]])[(TGAquaMediaControlCell *)[self cell] setHovered:YES];[self setNeedsDisplay:YES]; }
- (void)mouseExited:(NSEvent *)event { (void)event;if([[self cell] isKindOfClass:[TGAquaMediaControlCell class]])[(TGAquaMediaControlCell *)[self cell] setHovered:NO];[self setNeedsDisplay:YES]; }
- (void)dealloc {if(_mediaTrackingArea)[self removeTrackingArea:_mediaTrackingArea];[_mediaTrackingArea release];[super dealloc];}
@end

@interface TGAquaMediaChromeView : TGAquaMetalView { BOOL _dark; }
@property(nonatomic,assign) BOOL dark;
@end
@implementation TGAquaMediaChromeView
@synthesize dark=_dark;
- (void)setDark:(BOOL)dark { _dark=dark;[self setNeedsDisplay:YES]; }
- (void)drawRect:(NSRect)dirty {if(_dark) {[[NSColor blackColor] set];NSRectFill([self bounds]);}else[super drawRect:dirty];}
@end

@implementation TGAquaMediaImageClipView
- (NSPoint)constrainScrollPoint:(NSPoint)point {
    NSPoint result=[super constrainScrollPoint:point];
    NSSize document=[[self documentView] frame].size, viewport=[self bounds].size;
    if (document.width<viewport.width) result.x=-floor((viewport.width-document.width)/2);
    if (document.height<viewport.height) result.y=-floor((viewport.height-document.height)/2);
    return result;
}
- (void)scrollToPoint:(NSPoint)point { [super scrollToPoint:[self constrainScrollPoint:point]]; }
@end

@interface TGAquaMediaGalleryStage : NSView { BOOL _dark; }
@property(nonatomic,assign) BOOL dark;
@end
@implementation TGAquaMediaGalleryStage
@synthesize dark=_dark;
- (void)setDark:(BOOL)dark { _dark=dark;[self setNeedsDisplay:YES]; }
- (BOOL)isOpaque { return YES; }
- (void)drawRect:(NSRect)dirty {
    (void)dirty;
    if (_dark) {[[NSColor blackColor] set];NSRectFill([self bounds]);return;}
    [[NSColor colorWithCalibratedRed:0.90 green:0.93 blue:0.95 alpha:1] set]; NSRectFill([self bounds]);
    NSRect card=NSInsetRect([self bounds],1,1);
    NSBezierPath *path=[NSBezierPath bezierPathWithRoundedRect:card xRadius:7 yRadius:7];
    [[NSColor whiteColor] set]; [path fill];
    [[NSColor colorWithCalibratedWhite:0.66 alpha:1] set]; [path setLineWidth:1]; [path stroke];
}
@end

static NSTextField *TGMediaViewerLabel(NSFont *font) {
    NSTextField *field=[[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
    [field setEditable:NO]; [field setSelectable:NO]; [field setBordered:NO]; [field setDrawsBackground:NO];
    [field setFont:font]; [field setTextColor:[NSColor colorWithCalibratedWhite:0.18 alpha:1]];
    [[field cell] setLineBreakMode:NSLineBreakByTruncatingMiddle]; return field;
}
@implementation TGAquaMediaViewerView
@synthesize kind=_kind;
- (NSView *)stageView { return _stageView; }
- (NSView *)footerView { return _footerView; }
- (id)initWithFrame:(NSRect)frame {
    if ((self=[super initWithFrame:frame])) {
        _headerView=[[TGAquaMediaChromeView alloc] initWithFrame:NSZeroRect]; [self addSubview:_headerView];
        _footerView=[[TGAquaMediaChromeView alloc] initWithFrame:NSZeroRect]; [self addSubview:_footerView];
        _stageView=[[TGAquaMediaGalleryStage alloc] initWithFrame:NSZeroRect]; [self addSubview:_stageView];
        _typeImageView=[[NSImageView alloc] initWithFrame:NSZeroRect]; [_typeImageView setImageScaling:NSImageScaleProportionallyUpOrDown]; [_headerView addSubview:_typeImageView];
        _titleField=[TGMediaViewerLabel([NSFont boldSystemFontOfSize:13]) retain]; [_headerView addSubview:_titleField];
        _detailField=[TGMediaViewerLabel([NSFont systemFontOfSize:11]) retain]; [_detailField setTextColor:[NSColor colorWithCalibratedWhite:0.38 alpha:1]]; [_headerView addSubview:_detailField];
        _closeButton=[[TGAquaMediaControlButton alloc] initWithFrame:NSZeroRect];
        TGAquaUtilityButtonCell *cell=[[[TGAquaUtilityButtonCell alloc] initTextCell:@""] autorelease];
        [cell setIconOnly:YES]; [cell setIconAssetName:@"cross"]; [_closeButton setCell:cell]; [_closeButton setBordered:NO]; [_closeButton setToolTip:TGLoc(@"close")]; [_headerView addSubview:_closeButton];
        [self setKind:TGAquaMediaViewerPhoto];
    }
    return self;
}
- (void)dealloc {
    [_closeButton setTarget:nil]; [_headerView release]; [_footerView release]; [_stageView release];
    [_typeImageView release]; [_titleField release]; [_detailField release]; [_closeButton release]; [super dealloc];
}
- (BOOL)isOpaque { return YES; }
- (void)drawRect:(NSRect)dirty { (void)dirty; [(_kind==TGAquaMediaViewerPhoto ? [NSColor blackColor] : [NSColor colorWithCalibratedRed:0.90 green:0.93 blue:0.95 alpha:1]) set]; NSRectFill([self bounds]); }
- (void)setKind:(TGAquaMediaViewerKind)kind {
    _kind=kind; [_typeImageView setImage:TGIconAssetImageNamed(kind==TGAquaMediaViewerPhoto ? @"image" : @"video")];
    BOOL photo=kind==TGAquaMediaViewerPhoto;
    [(TGAquaMediaChromeView *)_headerView setDark:photo];[(TGAquaMediaChromeView *)_footerView setDark:photo];
    [(TGAquaMediaGalleryStage *)_stageView setDark:photo];
    [_typeImageView setHidden:photo];[_titleField setHidden:photo];[_detailField setHidden:photo];
    id closeTarget=[_closeButton target]; SEL closeAction=[_closeButton action];
    if (photo && ![[_closeButton cell] isKindOfClass:[TGAquaMediaControlCell class]]) {
        TGAquaMediaControlCell *cell=[[[TGAquaMediaControlCell alloc] initTextCell:@""] autorelease];[cell setIconAssetName:@"cross"];[_closeButton setCell:cell];
    } else if (!photo && ![[_closeButton cell] isKindOfClass:[TGAquaUtilityButtonCell class]]) {
        TGAquaUtilityButtonCell *cell=[[[TGAquaUtilityButtonCell alloc] initTextCell:@""] autorelease];[cell setIconOnly:YES];[cell setIconAssetName:@"cross"];[_closeButton setCell:cell];
    }
    [_closeButton setTarget:closeTarget]; [_closeButton setAction:closeAction];
    [_closeButton setBordered:NO]; [_closeButton setFocusRingType:NSFocusRingTypeNone];
    [self resizeSubviewsWithOldSize:NSZeroSize];
}
- (void)setMediaTitle:(NSString *)title detail:(NSString *)detail {
    [_titleField setStringValue:title ? title : @""]; [_titleField setToolTip:title];
    [_detailField setStringValue:detail ? detail : @""]; [_detailField setToolTip:detail];
}
- (void)setCloseTarget:(id)target action:(SEL)action { [_closeButton setTarget:target]; [_closeButton setAction:action]; }
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    (void)oldSize; TGAquaMediaViewerGeometry g=TGAquaMediaViewerFrames([self bounds],_kind);
    [_headerView setFrame:g.header]; [_footerView setFrame:g.footer]; [_stageView setFrame:g.stage];
    CGFloat w=NSWidth(g.header);
    [_typeImageView setFrame:NSMakeRect(16,13,28,28)];
    [_titleField setFrame:NSMakeRect(56,29,MAX(0,w-110),18)];
    [_detailField setFrame:NSMakeRect(56,10,MAX(0,w-110),16)];
    [_closeButton setFrame:NSMakeRect(MAX(0,w-42),_kind==TGAquaMediaViewerPhoto ? 5 : 12,30,30)];
}
@end
