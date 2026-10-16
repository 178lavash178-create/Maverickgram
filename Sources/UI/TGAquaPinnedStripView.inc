// Retains the existing pinned-message carousel; this only changes its material.
@interface TGAquaPinnedStripView : TGGroupedCardView
@end
@implementation TGAquaPinnedStripView
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSRect rect=[self bounds];
    TGAquaDrawSurfaceInPath([NSBezierPath bezierPathWithRect:rect],rect,TGThemeSurfaceHeader,[self isFlipped]);
    [TGClassicPanelStrokeColor() set];
    NSFrameRectWithWidth(NSInsetRect(rect,0.5,0.5),1);
    TGDrawTemplateIconAsset(@"bookmark",NSMakeRect(11,floor(NSMidY(rect)-9),18,18),TGColorFromHex(0x2672A5),1,[self isFlipped]);
}
@end
