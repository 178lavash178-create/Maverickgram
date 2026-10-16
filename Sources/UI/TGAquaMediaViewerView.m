#import "TGAquaMediaViewerView.h"
#import "TGAquaShellViews.h"
#import "TGIconAssets.h"
#import "TGLocalization.h"
#include <math.h>

TGAquaMediaViewerGeometry TGAquaMediaViewerFrames(NSRect bounds, TGAquaMediaViewerKind kind) {
    TGAquaMediaViewerGeometry g;
    memset(&g,0,sizeof(g));
    CGFloat w=MAX(0,NSWidth(bounds)),h=MAX(0,NSHeight(bounds));
    CGFloat footer=kind==TGAquaMediaViewerPhoto ? 54.0 : 70.0;
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
    return g;
}

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

@interface TGAquaMediaGalleryStage : NSView
@end
@implementation TGAquaMediaGalleryStage
- (BOOL)isOpaque { return YES; }
- (void)drawRect:(NSRect)dirty {
    (void)dirty;
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
        _headerView=[[TGAquaMetalView alloc] initWithFrame:NSZeroRect]; [self addSubview:_headerView];
        _footerView=[[TGAquaMetalView alloc] initWithFrame:NSZeroRect]; [self addSubview:_footerView];
        _stageView=[[TGAquaMediaGalleryStage alloc] initWithFrame:NSZeroRect]; [self addSubview:_stageView];
        _typeImageView=[[NSImageView alloc] initWithFrame:NSZeroRect]; [_typeImageView setImageScaling:NSImageScaleProportionallyUpOrDown]; [_headerView addSubview:_typeImageView];
        _titleField=[TGMediaViewerLabel([NSFont boldSystemFontOfSize:13]) retain]; [_headerView addSubview:_titleField];
        _detailField=[TGMediaViewerLabel([NSFont systemFontOfSize:11]) retain]; [_detailField setTextColor:[NSColor colorWithCalibratedWhite:0.38 alpha:1]]; [_headerView addSubview:_detailField];
        _closeButton=[[NSButton alloc] initWithFrame:NSZeroRect];
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
- (void)drawRect:(NSRect)dirty { (void)dirty; [[NSColor colorWithCalibratedRed:0.90 green:0.93 blue:0.95 alpha:1] set]; NSRectFill([self bounds]); }
- (void)setKind:(TGAquaMediaViewerKind)kind {
    _kind=kind; [_typeImageView setImage:TGIconAssetImageNamed(kind==TGAquaMediaViewerPhoto ? @"image" : @"video")];
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
    [_closeButton setFrame:NSMakeRect(MAX(0,w-46),12,30,30)];
}
@end
