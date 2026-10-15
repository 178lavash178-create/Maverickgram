// Sample the real material, including gradients and patterns, once per theme.
// Header gradients that cross both light and dark ranges receive a small veil
// only when no single ink can remain readable across their full text area.
static NSArray *TGThemeSurfaceSamples(TGThemeSurfaceRole role) {
    static NSCache *cache = nil;
    if (!cache) { cache = [[NSCache alloc] init]; [cache setCountLimit:224]; }
    NSString *key = [NSString stringWithFormat:@"%@:%d:%ld", TGCurrentThemeIdentifier(), TGInterfaceDesignIsAqua(), (long)role];
    NSArray *samples = [cache objectForKey:key];
    if (samples) { return samples; }
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:256 pixelsHigh:128
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    NSRect rect = NSMakeRect(0,0,256,128);
    [TGClassicTablePaperColor() set]; NSRectFill(rect);
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
    switch (role) {
        case TGThemeSurfaceRecessed: TGThemeDrawOriginalRecessed(path, rect, NO); break;
        case TGThemeSurfaceWindow: TGThemeDrawOriginalWindowBackground(rect, NO); break;
        case TGThemeSurfaceHeader: TGThemeDrawOriginalHeaderBackground(rect, NO); break;
        case TGThemeSurfaceCard: TGThemeDrawOriginalCard(path, rect, NO); break;
        case TGThemeSurfacePanel: TGThemeDrawOriginalPanel(path, rect, NO); break;
        case TGThemeSurfaceRail: TGThemeDrawOriginalRail(path, rect, NO); break;
        case TGThemeSurfaceOutgoing: TGThemeDrawOriginalBubble(path, rect, YES, NO); break;
        case TGThemeSurfaceIncoming: TGThemeDrawOriginalBubble(path, rect, NO, NO); break;
        default: break;
    }
    [NSGraphicsContext restoreGraphicsState];
    // Scan byte data rather than allocating thousands of NSColors on the first
    // paint of a theme. The opaque calibrated RGB bitmap has RGBA byte order.
    static CGFloat linear[256];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSUInteger i;
        for (i=0;i<256;i++) { CGFloat c=(CGFloat)i/255.0; linear[i]=c<=0.04045?c/12.92:pow((c+0.055)/1.055,2.4); }
    });
    CGFloat low = 1.0, high = 0.0;
    NSInteger x,y,lowX=3,lowY=3,highX=3,highY=3;
    unsigned char *bytes=[bitmap bitmapData];
    NSInteger stride=[bitmap bytesPerRow];
    for (y=3;y<125;y++) { for (x=3;x<253;x++) {
        unsigned char *pixel=bytes+y*stride+x*4;
        CGFloat value=linear[pixel[0]]*0.2126+linear[pixel[1]]*0.7152+linear[pixel[2]]*0.0722;
        if (value < low) { low=value;lowX=x;lowY=y; }
        if (value > high) { high=value;highX=x;highY=y; }
    } }
    NSArray *result = [NSArray arrayWithObjects:[bitmap colorAtX:lowX y:lowY],[bitmap colorAtX:highX y:highY],nil];
    [cache setObject:result forKey:key];
    return result;
}

static NSColor *TGThemeSurfaceVeil(TGThemeSurfaceRole role) {
    static NSCache *cache = nil;
    if (!cache) { cache = [[NSCache alloc] init]; [cache setCountLimit:224]; }
    NSString *key = [NSString stringWithFormat:@"%@:%d:%ld", TGCurrentThemeIdentifier(), TGInterfaceDesignIsAqua(), (long)role];
    NSColor *veil = [cache objectForKey:key];
    if (veil) { return veil; }
    NSArray *samples = TGThemeSurfaceSamples(role);
    CGFloat black = TGThemeMinimumContrast([NSColor blackColor], samples);
    CGFloat white = TGThemeMinimumContrast([NSColor whiteColor], samples);
    CGFloat endpoint = black >= white ? 1.0 : 0.0;
    NSColor *ink = endpoint > 0 ? [NSColor blackColor] : [NSColor whiteColor];
    NSUInteger step;
    for (step=0;step<=20;step++) {
        veil = [NSColor colorWithCalibratedWhite:endpoint alpha:(CGFloat)step/20.0];
        CGFloat score = 21.0;
        for (NSColor *sample in samples) { score = MIN(score, TGThemeContrastRatio(ink,TGThemeCompositeColor(veil,sample))); }
        if (score >= (role == TGThemeSurfaceWindow ? 6.0 : 5.2)) { break; }
    }
    [cache setObject:veil forKey:key];
    return veil;
}

NSColor *TGThemeSurfaceInkColor(NSColor *preferred, TGThemeSurfaceRole role, CGFloat minimum) {
    static NSCache *cache = nil;
    if (!cache) { cache = [[NSCache alloc] init]; [cache setCountLimit:512]; }
    NSString *key = [NSString stringWithFormat:@"%@:%d:%ld:%@:%g",TGCurrentThemeIdentifier(),TGInterfaceDesignIsAqua(),(long)role,preferred,(double)minimum];
    NSColor *ink = [cache objectForKey:key];
    if (ink) { return ink; }
    NSArray *samples = TGThemeSurfaceSamples(role);
    if (role != TGThemeSurfaceTable) {
        NSMutableArray *corrected = [NSMutableArray arrayWithCapacity:[samples count]];
        NSColor *veil = TGThemeSurfaceVeil(role);
        for (NSColor *sample in samples) { [corrected addObject:TGThemeCompositeColor(veil,sample)]; }
        samples = corrected;
    }
    ink = TGThemeReadableInkOnSurfaces(preferred,samples,minimum + (role == TGThemeSurfaceWindow ? 1.0 : 0.4));
    [cache setObject:ink forKey:key];
    return ink;
}

void TGThemeDrawHeaderBackgroundInRect(NSRect rect, BOOL flipped) {
    TGThemeDrawOriginalHeaderBackground(rect,flipped);
    [TGThemeSurfaceVeil(TGThemeSurfaceHeader) set]; NSRectFillUsingOperation(rect,NSCompositeSourceOver);
}

static void TGThemeDrawSurfaceVeil(NSBezierPath *path, TGThemeSurfaceRole role) {
    [NSGraphicsContext saveGraphicsState];
    [path addClip];
    [TGThemeSurfaceVeil(role) set]; NSRectFillUsingOperation([path bounds],NSCompositeSourceOver);
    [NSGraphicsContext restoreGraphicsState];
}
void TGThemeDrawPanelBackgroundInPath(NSBezierPath *path, NSRect rect, BOOL flipped) {
    TGThemeDrawOriginalPanel(path,rect,flipped); TGThemeDrawSurfaceVeil(path,TGThemeSurfacePanel);
}
void TGThemeDrawRailBackgroundInPath(NSBezierPath *path, NSRect rect, BOOL flipped) {
    TGThemeDrawOriginalRail(path,rect,flipped); TGThemeDrawSurfaceVeil(path,TGThemeSurfaceRail);
}
void TGThemeDrawGroupedCardInPath(NSBezierPath *path, NSRect rect, BOOL flipped) {
    TGThemeDrawOriginalCard(path,rect,flipped); TGThemeDrawSurfaceVeil(path,TGThemeSurfaceCard);
}
void TGThemeDrawMessageBubbleInPath(NSBezierPath *path, NSRect rect, BOOL outgoing, BOOL flipped) {
    TGThemeDrawOriginalBubble(path,rect,outgoing,flipped);
    TGThemeDrawSurfaceVeil(path,outgoing?TGThemeSurfaceOutgoing:TGThemeSurfaceIncoming);
}

void TGThemeDrawWindowBackgroundInRect(NSRect rect, BOOL flipped) {
    TGThemeDrawOriginalWindowBackground(rect,flipped);
    [TGThemeSurfaceVeil(TGThemeSurfaceWindow) set]; NSRectFillUsingOperation(rect,NSCompositeSourceOver);
}

void TGThemeDrawRecessedBackgroundInPath(NSBezierPath *path, NSRect rect, BOOL flipped) {
    TGThemeDrawOriginalRecessed(path,rect,flipped); TGThemeDrawSurfaceVeil(path,TGThemeSurfaceRecessed);
}
